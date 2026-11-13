package com.mavric.health.persistence.sqlserver;

import java.time.Instant;
import java.util.*;
import java.util.function.Supplier;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.*;
import org.springframework.transaction.support.*;
import com.mavric.health.identity.Actor;
import com.mavric.health.shared.ApiException;
import com.mavric.health.tenancy.TenantRef;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Templates/synchronizations are real; the manager and executor model NO database or durability. */
public class SqlServerIdentityStoreTest {
    private static final String ID="00000000-0000-4000-8000-000000000001",TENANT="00000000-0000-4000-8000-000000000002";
    private static final String HASH="a".repeat(64);
    private static final Instant EXPIRY=Instant.parse("2026-11-04T12:00:00.123456Z");

    /** Single-threaded transaction model for both suites: Spring drives propagation and callbacks.
     *  No Connection, resource suspension, persistence, commit or rollback is performed against a DB. */
    public static final class ModelTransactionManager extends AbstractPlatformTransactionManager {
        private static final class State { boolean active=true,rollbackOnly; }
        private static final class Handle implements SmartTransactionObject {
            State state;
            Handle(State state) { this.state=state; }
            @Override public boolean isRollbackOnly() { return state!=null && state.rollbackOnly; }
        }
        private State current;
        public final List<String> events=new ArrayList<>();
        public boolean failCommit;
        @Override protected Object doGetTransaction() { return new Handle(current); }
        @Override protected boolean isExistingTransaction(Object tx) {
            State state=((Handle)tx).state;return state!=null && state.active;
        }
        @Override protected void doBegin(Object tx,TransactionDefinition definition) {
            Handle handle=(Handle)tx;handle.state=new State();current=handle.state;
            events.add("begin:"+definition.getPropagationBehavior());
        }
        @Override protected Object doSuspend(Object tx) {
            Handle handle=(Handle)tx;State saved=handle.state;handle.state=null;current=null;events.add("suspend");return saved;
        }
        @Override protected void doResume(Object tx,Object saved) {
            current=(State)saved;if(tx instanceof Handle handle)handle.state=current;events.add("resume");
        }
        @Override protected void doCommit(DefaultTransactionStatus status) {
            events.add("commit");
            if(failCommit) { failCommit=false;throw new TransactionSystemException("private commit failure"); }
            ((Handle)status.getTransaction()).state.active=false;
        }
        @Override protected void doRollback(DefaultTransactionStatus status) {
            events.add("rollback");((Handle)status.getTransaction()).state.active=false;
        }
        @Override protected void doSetRollbackOnly(DefaultTransactionStatus status) {
            ((Handle)status.getTransaction()).state.rollbackOnly=true;events.add("rollbackOnly");
        }
        @Override protected void doCleanupAfterCompletion(Object tx) {
            if(current==((Handle)tx).state)current=null;
        }
        public <T> T outer(Supplier<T> action) {
            return new TransactionTemplate(this).execute(status->action.get());
        }
    }

    record Call(SqlServerProcedure procedure,SqlServerContext context,List<Object> parameters) {}
    final class Fixture {
        final ModelTransactionManager manager=new ModelTransactionManager();
        final SqlServerExecutor executor=mock(SqlServerExecutor.class);
        final SqlServerIdentityStore store=new SqlServerIdentityStore(executor,manager);
        final MockHttpServletRequest request=new MockHttpServletRequest("POST","/api/auth/login");
        final Deque<SqlServerExecutor.Result> results=new ArrayDeque<>();
        final List<Call> calls=new ArrayList<>();
        Fixture() {
            request.setRemoteAddr("127.0.0.1");
            request.setAttribute("health.tenant",new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE")));
            when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv-> {
                assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
                var procedure=inv.<SqlServerProcedure>getArgument(0);
                calls.add(new Call(procedure,inv.getArgument(1),Arrays.asList(((Object[])inv.getRawArguments()[2]).clone())));
                manager.events.add("sp:"+procedure.name());
                return results.removeFirst();
            });
        }
        void actor() { request.setAttribute("health.actor",new Actor(ID,"Synthetic","qa@example.test",TENANT,List.of("ADM"),HASH)); }
        void add(Map<String,Object> row) { results.add(new SqlServerExecutor.Result(List.of(List.of(row)),List.of())); }
        void empty() { results.add(new SqlServerExecutor.Result(List.of(List.of()),List.of())); }
        void noRows() { results.add(new SqlServerExecutor.Result(List.of(),List.of(0))); }
    }
    private static Map<String,Object> credentials() {
        Map<String,Object> row=new LinkedHashMap<>();
        row.put("id",ID);row.put("name","Synthetic");row.put("email","qa@example.test");row.put("passwordHash","synthetic-hash");
        row.put("platformRole",null);row.put("emailVerified",true);row.put("locked",false);row.put("lockedUntil",null);
        return row;
    }
    private static Map<String,Object> member() { return Map.of("userId",ID,"status","ACTIVE","roles",List.of("ADM")); }
    private static Map<String,Object> saved() { return Map.of("csrfToken","b".repeat(64),"expiresAt",EXPIRY.toString()); }
    @AfterEach void clearModelSynchronization() { TransactionSynchronizationManager.clear(); }

    @Test void allNineProceduresHaveExactArgumentsScopesAndOneRequiredUnitPlusIndependentFailure() {
        Fixture f=new Fixture();f.noRows();f.add(credentials());f.add(member());f.add(saved());f.noRows();
        f.add(Map.of("passwordHash","old-hash"));f.noRows();f.noRows();f.noRows();
        f.store.required(()-> {
            f.actor();f.store.create(f.request,ID,"Synthetic","qa@example.test","hash",null,null);
            f.request.removeAttribute("health.actor");
            var credentials=f.store.credentials(f.request,"qa@example.test").orElseThrow();
            assertFalse(credentials.locked());assertNull(credentials.lockedUntil());assertTrue(credentials.emailVerified());
            assertFalse(credentials.toString().contains("hash"));
            assertEquals(List.of("ADM"),f.store.membership(f.request,ID).orElseThrow().roles());
            var saved=f.store.saveSession(f.request,HASH,ID,EXPIRY,"00000000001");
            assertEquals(EXPIRY,saved.expiresAt());assertFalse(saved.toString().contains("bbbb"));
            f.store.acceptInvitation(f.request,ID);
            f.actor();assertEquals("old-hash",f.store.passwordHash(f.request));
            f.store.changePassword(f.request,"new-hash");f.store.revokeSession(f.request);
            f.request.removeAttribute("health.actor");f.store.failed(f.request,null);
            return Boolean.TRUE;
        });
        assertEquals(List.of(SqlServerProcedure.USER_CREATE,SqlServerProcedure.IDENTITY_CREDENTIALS,
                SqlServerProcedure.IDENTITY_MEMBERSHIP,SqlServerProcedure.TENANT_SESSION_SAVE,SqlServerProcedure.INVITATION_ACCEPT,
                SqlServerProcedure.IDENTITY_PASSWORD_HASH,SqlServerProcedure.PASSWORD_CHANGE,
                SqlServerProcedure.SESSION_REVOKE,SqlServerProcedure.LOGIN_FAILURE),f.calls.stream().map(Call::procedure).toList());
        assertEquals(Arrays.asList(ID,"Synthetic","qa@example.test","hash",null,null),f.calls.get(0).parameters());
        assertEquals(List.of("qa@example.test"),f.calls.get(1).parameters());
        assertEquals(List.of(ID,TENANT,true),f.calls.get(2).parameters());
        assertEquals(List.of(HASH,ID,EXPIRY,"00000000001"),f.calls.get(3).parameters());
        assertEquals(List.of(ID),f.calls.get(4).parameters());assertEquals(List.of(),f.calls.get(5).parameters());
        assertEquals(List.of("new-hash"),f.calls.get(6).parameters());
        assertEquals(Collections.singletonList(null),f.calls.get(7).parameters());assertEquals(Collections.singletonList(null),f.calls.get(8).parameters());
        assertEquals(List.of(SqlServerContext.Scope.REQUEST,SqlServerContext.Scope.IDENTITY,SqlServerContext.Scope.IDENTITY,
                SqlServerContext.Scope.IDENTITY,SqlServerContext.Scope.IDENTITY,SqlServerContext.Scope.REQUEST,
                SqlServerContext.Scope.REQUEST,SqlServerContext.Scope.REQUEST,SqlServerContext.Scope.IDENTITY),
                f.calls.stream().map(c->c.context().scope()).toList());
        assertEquals(1,Collections.frequency(f.manager.events,"begin:0"));
        assertEquals(1,Collections.frequency(f.manager.events,"begin:3"));assertEquals(2,Collections.frequency(f.manager.events,"commit"));
        assertTrue(f.manager.events.containsAll(List.of("suspend","resume")));
        assertTrue(f.calls.stream().allMatch(c->TENANT.equals(c.context().tenantId())));
        assertNull(f.calls.get(8).context().actorId());assertNull(f.calls.get(8).context().tokenHash());
    }

    @Test void missingCredentialsAndMembershipAreOptionalButOwnHashMissingIs404() {
        Fixture f=new Fixture();f.empty();assertTrue(f.store.credentials(f.request,"qa@example.test").isEmpty());
        f.empty();assertTrue(f.store.membership(f.request,ID).isEmpty());
        f.actor();f.empty();assertEquals(404,assertThrows(ApiException.class,()->f.store.passwordHash(f.request)).status);
        assertEquals("rollback",f.manager.events.getLast());
    }

    @Test void malformedCredentialBitsTextAndUtcAreSecureErrorsInsideRollback() {
        for (Map.Entry<String,Object> field:List.<Map.Entry<String,Object>>of(Map.entry("emailVerified",1),
                Map.entry("locked","false"),Map.entry("passwordHash",42),Map.entry("lockedUntil","private-invalid-date"),
                Map.entry("lockedUntil","2026-11-04T00:00:00.123456789Z"))) {
            Fixture f=new Fixture();Map<String,Object> row=credentials();row.put(field.getKey(),field.getValue());f.add(row);
            safe500(()->f.store.credentials(f.request,"qa@example.test"));assertEquals("rollback",f.manager.events.getLast());
        }
        Fixture missing=new Fixture();var row=credentials();row.remove("name");missing.add(row);
        safe500(()->missing.store.credentials(missing.request,"qa@example.test"));
    }

    @Test void cardinalityAndResultsetsCannotBeSilentlyDiscarded() {
        for(var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of(),List.of()),
                List.of(List.of(credentials(),credentials())))) {
            Fixture f=new Fixture();f.results.add(new SqlServerExecutor.Result(sets,List.of()));
            safe500(()->f.store.credentials(f.request,"qa@example.test"));assertEquals("rollback",f.manager.events.getLast());
        }
        Fixture write=new Fixture();write.actor();write.empty();
        safe500(()->write.store.changePassword(write.request,"new-hash"));assertEquals("rollback",write.manager.events.getLast());
    }

    @Test void sessionSaveMustValidateSingleResultCsrfAndStoredExpiryWithoutInventingClientValue() {
        Fixture f=new Fixture();f.add(saved());
        assertEquals(EXPIRY,f.store.saveSession(f.request,HASH,ID,EXPIRY.plusSeconds(10),"00000000001").expiresAt());
        for(Map<String,Object> row:List.<Map<String,Object>>of(Map.of("csrfToken","private","expiresAt",EXPIRY.toString()),
                Map.of("csrfToken","a".repeat(64),"expiresAt",7),Map.of("csrfToken","a".repeat(64),"expiresAt","2026-11-04T00:00:00"),
                Map.of("csrfToken","a".repeat(64),"expiresAt","2026-11-04T00:00:00.000000001Z"))) {
            Fixture bad=new Fixture();bad.add(row);
            safe500(()->bad.store.saveSession(bad.request,HASH,ID,EXPIRY,"00000000001"));assertEquals("rollback",bad.manager.events.getLast());
        }
        Fixture empty=new Fixture();empty.empty();safe500(()->empty.store.saveSession(empty.request,HASH,ID,EXPIRY,"00000000001"));
    }

    @Test void membershipTypesStatusAndIdentityAreValidatedBeforeCommit() {
        for(Map<String,Object> row:List.<Map<String,Object>>of(Map.of("userId",ID,"status","ACTIVE","roles","[\"ADM\"]"),
                Map.of("userId",ID,"status","ACTIVE","roles",List.of(5)),
                Map.of("userId","other","status","ACTIVE","roles",List.of("ADM")),
                Map.of("userId",ID,"status","INVITED","roles",List.of("ADM")))) {
            Fixture f=new Fixture();f.add(row);safe500(()->f.store.membership(f.request,ID));
        }
    }

    @Test void failedAttemptCommitsItsModeledNewTransactionBeforeLoginRollsBack() {
        Fixture f=new Fixture();f.noRows();
        assertThrows(ApiException.class,()->f.store.required(()-> {
            f.store.failed(f.request,ID);throw new ApiException(401,"INVALID_CREDENTIALS","Rejected");
        }));
        assertEquals(List.of("begin:0","suspend","begin:3","sp:LOGIN_FAILURE","commit","resume","rollback"),f.manager.events);
    }

    @Test void acceptThenSaveErrorRollsBackEntireRequiredUnitWithoutPartialCommit() {
        Fixture f=new Fixture();f.noRows();f.empty();
        safe500(()->f.store.required(()-> {
            f.store.acceptInvitation(f.request,ID);return f.store.saveSession(f.request,HASH,ID,EXPIRY,"00000000001");
        }));
        assertEquals(0,Collections.frequency(f.manager.events,"commit"));
        assertEquals(1,Collections.frequency(f.manager.events,"begin:0"));
        assertTrue(f.manager.events.contains("rollbackOnly"));assertEquals("rollback",f.manager.events.getLast());
    }

    @Test void administrativeCreateNeverElevatesAnonymousOrNonAdministrativeActors() {
        Fixture anonymous=new Fixture();
        assertEquals(403,assertThrows(ApiException.class,()->anonymous.store.create(anonymous.request,ID,"Name","qa@example.test","hash",null,null)).status);
        verifyNoInteractions(anonymous.executor);
        Fixture pro=new Fixture();pro.request.setAttribute("health.actor",new Actor(ID,"Synthetic","qa@example.test",TENANT,List.of("PRO"),HASH));
        assertEquals(403,assertThrows(ApiException.class,()->pro.store.create(pro.request,ID,"Name","qa@example.test","hash",null,null)).status);
        verifyNoInteractions(pro.executor);
    }

    @Test void registrationNeedsExistingTransactionAndNoActorAndCannotCommitIndependently() {
        Fixture missing=new Fixture();
        safe500(()->missing.store.createForRegistration(missing.request,ID,"Name","qa@example.test","hash",null,null));
        verifyNoInteractions(missing.executor);assertTrue(missing.manager.events.isEmpty());
        Fixture actor=new Fixture();actor.actor();
        assertThrows(ApiException.class,()->actor.manager.outer(()-> {
            actor.store.createForRegistration(actor.request,ID,"Name","qa@example.test","hash",null,null);return true;
        }));
        verifyNoInteractions(actor.executor);
        Fixture valid=new Fixture();valid.noRows();
        assertThrows(ApiException.class,()->valid.manager.outer(()-> {
            valid.store.createForRegistration(valid.request,ID,"Name","qa@example.test","hash",null,null);
            assertFalse(valid.manager.events.contains("commit"));throw new ApiException(409,"CONFLICT","Synthetic later failure");
        }));
        assertEquals(SqlServerContext.Scope.IDENTITY,valid.calls.getFirst().context().scope());
        assertNull(valid.calls.getFirst().context().actorId());
        assertEquals(List.of("begin:0","sp:USER_CREATE","rollback"),valid.manager.events);
    }

    @Test void missingRequestAndDriverFailuresAreSafeAndNeverRetried() {
        Fixture f=new Fixture();safe500(()->f.store.credentials(null,"qa@example.test"));verifyNoInteractions(f.executor);
        Fixture driver=new Fixture();
        when(driver.executor.execute(any(),any(),any(Object[].class))).thenThrow(new IllegalStateException("private driver"));
        safe500(()->driver.store.credentials(driver.request,"qa@example.test"));verify(driver.executor,times(1)).execute(any(),any(),any(Object[].class));
    }
    private static Map<String,Object> sessionRow() {
        Map<String,Object> row=new LinkedHashMap<>();
        row.put("id","d".repeat(64));row.put("tenantId",null);row.put("createdAt","2026-11-04T01:02:03.123456Z");
        row.put("lastSeenAt","2026-11-04T01:03:03Z");row.put("expiresAt",EXPIRY.toString());
        row.put("revoked",false);row.put("userAgent","Synthetic browser");row.put("sourceIp","192.0.2.1");row.put("current",true);
        return row;
    }

    @Test void currentListAndRevokeUseRequestScopeNoLookupAndUnchangedOpaqueId() {
        Fixture f=new Fixture();f.actor();f.add(saved());f.add(sessionRow());f.noRows();f.noRows();
        assertEquals(EXPIRY,f.store.currentSession(f.request).expiresAt());
        var summaries=f.store.listSessions(f.request);
        assertEquals(1,summaries.size());assertNull(summaries.getFirst().tenantId());
        assertEquals(Instant.parse("2026-11-04T01:02:03.123456Z"),summaries.getFirst().createdAt());
        assertTrue(summaries.getFirst().current());assertFalse(summaries.getFirst().revoked());
        assertThrows(UnsupportedOperationException.class,()->summaries.clear());
        String opaque="A".repeat(64);
        f.store.revokeSession(f.request,opaque);f.store.revokeSession(f.request);
        assertEquals(List.of(SqlServerProcedure.SESSION_CURRENT,SqlServerProcedure.SESSIONS_LIST,
                SqlServerProcedure.SESSION_REVOKE,SqlServerProcedure.SESSION_REVOKE),f.calls.stream().map(Call::procedure).toList());
        assertEquals(List.of(),f.calls.get(0).parameters());assertEquals(List.of(),f.calls.get(1).parameters());
        assertEquals(List.of(opaque),f.calls.get(2).parameters());assertEquals(Collections.singletonList(null),f.calls.get(3).parameters());
        assertTrue(f.calls.stream().allMatch(c->c.context().scope()==SqlServerContext.Scope.REQUEST
                && HASH.equals(c.context().tokenHash()) && ID.equals(c.context().actorId())));
    }

    @Test void sessionListIsSafeProjectionEvenIfSourceContainsExtraSecretColumns() {
        Fixture f=new Fixture();f.actor();var row=sessionRow();
        row.put("tokenHash","private-token-hash");row.put("csrfToken","private-csrf");row.put("passwordHash","private-password");
        f.add(row);var result=f.store.listSessions(f.request);
        String json=new tools.jackson.databind.ObjectMapper().writeValueAsString(result);
        assertFalse(json.contains("private"));assertFalse(json.contains("tokenHash"));assertFalse(json.contains("csrfToken"));assertFalse(json.contains("passwordHash"));
        assertEquals("SessionSummary[redacted]",result.getFirst().toString());
    }

    @Test void emptyListAndExactlyHundredSessionsAreValidButOversizedOrMultipleResultsetsRollBack() {
        Fixture empty=new Fixture();empty.actor();empty.empty();assertEquals(List.of(),empty.store.listSessions(empty.request));
        Fixture hundred=new Fixture();hundred.actor();
        hundred.results.add(new SqlServerExecutor.Result(List.of(Collections.nCopies(100,sessionRow())),List.of(0)));
        assertEquals(100,hundred.store.listSessions(hundred.request).size());
        for (var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of(),List.of()),
                List.of(Collections.nCopies(101,sessionRow())))) {
            Fixture f=new Fixture();f.actor();f.results.add(new SqlServerExecutor.Result(sets,List.of()));
            safe500(()->f.store.listSessions(f.request));assertEquals("rollback",f.manager.events.getLast());
        }
    }

    @Test void malformedSessionDatesBitsNullableTenantAndTextsAreSecureMappingRollbacks() {
        for (Map.Entry<String,Object> field:List.<Map.Entry<String,Object>>of(Map.entry("id","x".repeat(43)),Map.entry("tenantId",5),
                Map.entry("createdAt","private-date"),Map.entry("lastSeenAt","2026-11-04T00:00:00.000000001Z"),
                Map.entry("expiresAt","2026-11-04T00:00:00+01:00"),Map.entry("revoked",0),
                Map.entry("current","true"),Map.entry("userAgent",false),Map.entry("sourceIp",5))) {
            Fixture f=new Fixture();f.actor();var row=sessionRow();row.put(field.getKey(),field.getValue());f.add(row);
            safe500(()->f.store.listSessions(f.request));assertEquals("rollback",f.manager.events.getLast());
        }
    }

    @Test void currentSessionEmptyIs404AndMalformedOrMultipleRowsNeverSucceed() {
        Fixture empty=new Fixture();empty.actor();empty.empty();
        assertEquals(404,assertThrows(ApiException.class,()->empty.store.currentSession(empty.request)).status);
        Fixture duplicate=new Fixture();duplicate.actor();
        duplicate.results.add(new SqlServerExecutor.Result(List.of(List.of(saved(),saved())),List.of()));
        safe500(()->duplicate.store.currentSession(duplicate.request));
        Fixture malformed=new Fixture();malformed.actor();malformed.add(Map.of("csrfToken","private","expiresAt",EXPIRY.toString()));
        safe500(()->malformed.store.currentSession(malformed.request));
    }

    @Test void invalidOpaqueRevokeIdsAre404BeforeExecutorNotBinder400AndValidForeign404IsPreserved() {
        for(String id:Arrays.asList(null,"",ID,"x".repeat(43),"g".repeat(64),"a".repeat(65))) {
            Fixture f=new Fixture();f.actor();
            assertEquals(404,assertThrows(ApiException.class,()->f.store.revokeSession(f.request,id)).status);
            verifyNoInteractions(f.executor);assertEquals("rollback",f.manager.events.getLast());
        }
        Fixture foreign=new Fixture();foreign.actor();ApiException missing=ApiException.missing();
        doThrow(missing).when(foreign.executor).execute(any(),any(),any(Object[].class));
        assertSame(missing,assertThrows(ApiException.class,()->foreign.store.revokeSession(foreign.request,"b".repeat(64))));
        verify(foreign.executor,times(1)).execute(eq(SqlServerProcedure.SESSION_REVOKE),any(),eq("b".repeat(64)));
    }
    private static void safe500(Runnable action) {
        ApiException error=assertThrows(ApiException.class,action::run);
        assertEquals(500,error.status);assertEquals("DATABASE_ERROR",error.code);assertFalse(error.toString().contains("private"));assertNull(error.getCause());
    }
}
