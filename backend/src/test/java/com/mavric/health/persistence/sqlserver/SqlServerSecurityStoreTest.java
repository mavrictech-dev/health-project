package com.mavric.health.persistence.sqlserver;

import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.*;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.identity.*;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Real TransactionTemplate + mocked transaction manager/executor. No SQL Server, JDBC connection or app. */
class SqlServerSecurityStoreTest {
    private static final String TENANT="00000000-0000-4000-8000-000000000010";
    private static final String USER="00000000-0000-4000-8000-000000000020";
    private static final String REQUEST="00000000-0000-4000-8000-000000000030";
    private static final String HASH="a".repeat(64);
    private static final TenantRef TENANT_REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"),"00000000001",1);
    private static final Actor ACTOR=new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of("ADM"),HASH);

    record Call(SqlServerProcedure procedure,SqlServerContext context,List<Object> parameters) {}
    final class Fixture {
        final SqlServerExecutor executor=mock(SqlServerExecutor.class);
        final PlatformTransactionManager manager=mock(PlatformTransactionManager.class);
        final TransactionStatus status=mock(TransactionStatus.class);
        final AtomicBoolean active=new AtomicBoolean();
        final List<String> events=new ArrayList<>();
        final List<Call> calls=new ArrayList<>();
        final Deque<SqlServerExecutor.Result> results=new ArrayDeque<>();
        final SqlServerSecurityStore store;
        RuntimeException failure;
        Fixture() {
            when(manager.getTransaction(any())).thenAnswer(inv-> {
                assertFalse(active.getAndSet(true));events.add("begin");return status;
            });
            doAnswer(inv->{assertTrue(active.getAndSet(false));events.add("commit");return null;}).when(manager).commit(status);
            doAnswer(inv->{assertTrue(active.getAndSet(false));events.add("rollback");return null;}).when(manager).rollback(status);
            when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv-> {
                assertTrue(active.get(),"SP must execute inside the callback");
                Object[] parameters=(Object[])inv.getRawArguments()[2];
                calls.add(new Call(inv.getArgument(0),inv.getArgument(1),Arrays.asList(parameters.clone())));
                events.add("sp");
                if(failure!=null)throw failure;
                return results.removeFirst();
            });
            store=new SqlServerSecurityStore(executor,new TransactionTemplate(manager));
        }
        void add(Map<String,Object> row) { results.add(result(List.of(List.of(row)))); }
        void empty() { results.add(result(List.of(List.of()))); }
    }
    private static SqlServerExecutor.Result result(List<List<Map<String,Object>>> sets) {
        return new SqlServerExecutor.Result(sets,List.of(0));
    }
    private static Map<String,Object> tenant() {
        return Map.of("id",TENANT,"name","Synthetic","slug","clinic","kind","CLINIC","domain","HUMAN","status","ACTIVE","modules",List.of("CORE","DOCUMENTS"),"ruc","00000000001","revision",1);
    }
    private static Map<String,Object> session() {
        Map<String,Object> row=new LinkedHashMap<>();
        row.put("userId",USER);row.put("tenantId",TENANT);row.put("name","Synthetic");
        row.put("email","qa@example.test");row.put("platformRole",null);row.put("csrfToken","synthetic-csrf");
        return row;
    }
    private static Map<String,Object> membership() { return Map.of("userId",USER,"status","ACTIVE","roles",List.of("ADM")); }
    private static MockHttpServletRequest request() {
        MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/patients");
        request.setServerName("clinic.health.localhost");request.setRemoteAddr("127.0.0.9");
        request.setAttribute("health.requestId",REQUEST);
        return request;
    }

    @Test void fiveOperationsUseOnlyApprovedDescriptorsExplicitArgumentsAndTrustedContextInShortTransactions() {
        Fixture f=new Fixture();MockHttpServletRequest request=request();
        f.add(tenant());f.add(session());f.add(membership());f.add(Map.of("mode","OPEN","message","Ready"));
        f.results.add(result(List.of()));
        assertEquals(List.of("CORE","DOCUMENTS"),f.store.tenantBySlug(request,"clinic").orElseThrow().get("modules"));
        request.setAttribute("health.tenant",TENANT_REF);
        f.store.resolveSession(request,HASH).orElseThrow();f.store.activeMembership(request,USER).orElseThrow();
        f.store.applicationStatus(request);
        request.setAttribute("health.actor",ACTOR);f.store.touchSession(request);
        assertEquals(List.of(SqlServerProcedure.TENANT_BY_SLUG,SqlServerProcedure.SESSION_RESOLVE,
                SqlServerProcedure.IDENTITY_MEMBERSHIP,SqlServerProcedure.APPLICATION_STATUS,SqlServerProcedure.SESSION_TOUCH),
                f.calls.stream().map(Call::procedure).toList());
        assertEquals(List.of("clinic"),f.calls.get(0).parameters());assertEquals(List.of(HASH),f.calls.get(1).parameters());
        assertEquals(List.of(USER,TENANT,true),f.calls.get(2).parameters());
        assertEquals(List.of(),f.calls.get(3).parameters());assertEquals(List.of(),f.calls.get(4).parameters());
        assertEquals(List.of(SqlServerContext.Scope.REQUEST,SqlServerContext.Scope.IDENTITY,SqlServerContext.Scope.IDENTITY,
                SqlServerContext.Scope.REQUEST,SqlServerContext.Scope.REQUEST),f.calls.stream().map(c->c.context().scope()).toList());
        assertNull(f.calls.getFirst().context().tenantId());
        for(Call call:f.calls.subList(1,4)) {
            assertEquals(TENANT,call.context().tenantId());assertNull(call.context().actorId());
            assertNull(call.context().roles());assertNull(call.context().tokenHash());
        }
        assertEquals(USER,f.calls.get(4).context().actorId());assertEquals(List.of("ADM"),f.calls.get(4).context().roles());
        assertEquals(HASH,f.calls.get(4).context().tokenHash());
        assertEquals(Collections.nCopies(5,List.of("begin","sp","commit")).stream().flatMap(List::stream).toList(),f.events);
        assertFalse(f.active.get());verify(f.manager,never()).rollback(any());
    }

    @Test void forgedHeadersAndBodyCannotChooseActorTenantScopeOrForwardedAddress() throws Exception {
        Fixture f=new Fixture();MockHttpServletRequest request=request();
        request.setAttribute("health.tenant",TENANT_REF);
        request.addHeader("X-Request-Id","forged");request.addHeader("X-Tenant-Id","forged");
        request.addHeader("X-Actor-Id","forged");request.addHeader("X-Roles","SAD");request.addHeader("X-Scope","BOOTSTRAP");
        request.addHeader("X-Forwarded-For","203.0.113.7");request.addHeader("X-Real-IP","203.0.113.8");
        request.setContent("{\"tenantId\":\"forged\",\"actorId\":\"forged\",\"scope\":\"BOOTSTRAP\"}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        f.empty();assertTrue(f.store.resolveSession(request,HASH).isEmpty());
        SqlServerContext context=f.calls.getFirst().context();
        assertEquals(REQUEST,context.requestId());assertEquals(TENANT,context.tenantId());
        assertEquals("127.0.0.9",context.sourceIp());assertNull(context.actorId());assertNull(context.roles());
        assertNull(context.tokenHash());assertEquals(SqlServerContext.Scope.IDENTITY,context.scope());
        assertTrue(new String(request.getInputStream().readAllBytes(),java.nio.charset.StandardCharsets.UTF_8).contains("forged"),
                "Store must leave the body unread");
    }

    @Test void routeAgentAndTrustedTraceAddressUseContractBoundsAndKeepUnicodePairs() {
        Fixture f=new Fixture();MockHttpServletRequest request=request();
        request.setRequestURI("/"+"r".repeat(300));
        request.addHeader("User-Agent","u".repeat(299)+"\ud83e\uddb7"+"extra");
        request.setAttribute("health.sourceIp","192.0.2.1");f.add(Map.of("mode","OPEN","message","Ready"));
        f.store.applicationStatus(request);
        var context=f.calls.getFirst().context();
        assertEquals(250,context.route().length());assertEquals(299,context.userAgent().length());
        assertEquals("192.0.2.1",context.sourceIp());assertEquals("GET",context.method());
        assertEquals("SqlServerContext[redacted]",context.toString());assertFalse(f.store.toString().contains(HASH));
    }

    @Test void emptyLookupIsOptionalButMissingApplicationStateRollsBackInsteadOfInventingOpen() {
        Fixture f=new Fixture();f.empty();assertTrue(f.store.tenantBySlug(request(),"clinic").isEmpty());
        f.empty();assertTrue(f.store.resolveSession(request(),HASH).isEmpty());
        MockHttpServletRequest request=request();request.setAttribute("health.tenant",TENANT_REF);
        f.empty();assertTrue(f.store.activeMembership(request,USER).isEmpty());
        f.empty();assertSafe500(()->f.store.applicationStatus(request));
        assertEquals(List.of("begin","sp","rollback"),f.events.subList(f.events.size()-3,f.events.size()));
    }

    @Test void resultsetArityAndRowCardinalityErrorsRollBackWithinCallback() {
        for (var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of(),List.of()),
                List.of(List.of(tenant(),tenant())))) {
            Fixture f=new Fixture();f.results.add(result(sets));
            assertSafe500(()->f.store.tenantBySlug(request(),"clinic"));
            assertEquals(List.of("begin","sp","rollback"),f.events);assertFalse(f.active.get());
        }
        Fixture f=new Fixture();MockHttpServletRequest request=request();
        request.setAttribute("health.tenant",TENANT_REF);request.setAttribute("health.actor",ACTOR);
        f.empty();assertSafe500(()->f.store.touchSession(request));verify(f.manager).rollback(f.status);
    }

    @Test void malformedFieldsModulesAndRolesAreSecureErrorsAndMappingRollsBack() {
        for (Object modules:List.of("[\"CORE\"]",List.of(1),Map.of("module","CORE"))) {
            Fixture f=new Fixture();Map<String,Object> row=new LinkedHashMap<>(tenant());row.put("modules",modules);f.add(row);
            assertSafe500(()->f.store.tenantBySlug(request(),"clinic"));verify(f.manager).rollback(f.status);
        }
        for (Map<String,Object> row:List.<Map<String,Object>>of(Map.of("roles",List.of("ADM")),
                Map.of("userId",USER,"status","ACTIVE","roles",List.of(5)),
                Map.of("userId",USER,"status","INVITED","roles",List.of("ADM")),
                Map.of("userId","other","status","ACTIVE","roles",List.of("ADM")))) {
            Fixture f=new Fixture();MockHttpServletRequest request=request();request.setAttribute("health.tenant",TENANT_REF);f.add(row);
            assertSafe500(()->f.store.activeMembership(request,USER));verify(f.manager).rollback(f.status);
        }
        Fixture f=new Fixture();f.add(Map.of("userId",USER,"name","Synthetic","email","qa@example.test"));
        assertSafe500(()->f.store.resolveSession(request(),HASH));verify(f.manager).rollback(f.status);
    }

    @Test void contextRejectsInconsistentInternalAttributesWithoutUsingUntrustedFallback() {
        for(String key:List.of("health.actor","health.tenant","health.requestId","health.sourceIp")) {
            Fixture f=new Fixture();MockHttpServletRequest request=request();request.setAttribute(key,5);
            assertSafe500(()->f.store.applicationStatus(request));verifyNoInteractions(f.executor);verify(f.manager).rollback(f.status);
        }
        Fixture f=new Fixture();MockHttpServletRequest request=request();request.setAttribute("health.actor",ACTOR);
        assertSafe500(()->f.store.touchSession(request));verifyNoInteractions(f.executor);
    }

    @Test void malformedApplicationStateAndHostLookupFieldsDoNotEscapeOrBecomeOpenState() {
        for (Map<String,Object> state:List.<Map<String,Object>>of(Map.of("mode",5,"message","private"),
                Map.of("mode","OPEN"),Map.of("message","private"))) {
            Fixture f=new Fixture();f.add(state);
            assertSafe500(()->f.store.applicationStatus(request()));verify(f.manager).rollback(f.status);
        }
        Fixture f=new Fixture();Map<String,Object> row=new LinkedHashMap<>(tenant());row.put("id",5);f.add(row);
        assertSafe500(()->f.store.tenantBySlug(request(),"clinic"));verify(f.manager).rollback(f.status);
    }

    @Test void executorAndTransactionFailuresAreSafeAndNeverRetried() {
        Fixture f=new Fixture();f.failure=new IllegalStateException("private token credentials");
        assertSafe500(()->f.store.applicationStatus(request()));
        assertEquals(List.of("begin","sp","rollback"),f.events);assertEquals(1,f.calls.size());
        Fixture failedBegin=new Fixture();
        when(failedBegin.manager.getTransaction(any())).thenThrow(new IllegalStateException("private datasource"));
        assertSafe500(()->failedBegin.store.applicationStatus(request()));verifyNoInteractions(failedBegin.executor);
    }

    @Test void alreadySafeErrorsArePreservedAndRolledBack() {
        Fixture f=new Fixture();ApiException forbidden=new ApiException(403,"FORBIDDEN","Operacion rechazada.");
        f.failure=forbidden;
        assertSame(forbidden,assertThrows(ApiException.class,()->f.store.applicationStatus(request())));
        verify(f.manager).rollback(f.status);
    }

    @Test void rawTokenAndNullDependenciesFailWithoutDatabaseActivity() {
        Fixture f=new Fixture();
        for(String value:Arrays.asList(null,"x".repeat(43),"A".repeat(64),"x".repeat(64)))
            assertThrows(ApiException.class,()->f.store.resolveSession(request(),value));
        verifyNoInteractions(f.executor,f.manager);
        assertThrows(NullPointerException.class,()->new SqlServerSecurityStore(null,new TransactionTemplate(f.manager)));
        assertThrows(NullPointerException.class,()->new SqlServerSecurityStore(f.executor,null));
    }

    @Test void realFiltersReachDownstreamOnlyAfterAllFiveShortTransactionsHaveFinished() throws Exception {
        Fixture f=new Fixture();MockHttpServletRequest request=request();
        request.setMethod("POST");request.addHeader("Authorization","Bearer "+"s".repeat(43));
        f.add(tenant());f.add(session());f.add(membership());f.add(Map.of("mode","OPEN","message","Ready"));
        f.results.add(result(List.of()));
        var host=new HostFilter(new Settings("health.localhost","http://health.localhost",8,null),f.store,new Errors(new ObjectMapper()));
        var session=new SessionFilter(f.store,new Errors(new ObjectMapper()));
        AtomicBoolean downstream=new AtomicBoolean();
        try {
            host.doFilter(request,new MockHttpServletResponse(),(req,res)->session.doFilter(req,res,(r,s)-> {
                assertFalse(f.active.get());assertEquals(5,f.events.stream().filter("commit"::equals).count());
                assertEquals(USER,((Actor)SecurityContextHolder.getContext().getAuthentication().getPrincipal()).id());
                downstream.set(true);
            }));
            assertTrue(downstream.get());assertEquals(5,f.calls.size());
            assertEquals(Checks.hash("s".repeat(43)),f.calls.get(1).parameters().getFirst());
        } finally { SecurityContextHolder.clearContext(); }
    }

    private static void assertSafe500(Runnable action) {
        ApiException error=assertThrows(ApiException.class,action::run);
        assertEquals(500,error.status);assertEquals("DATABASE_ERROR",error.code);
        assertFalse(error.toString().contains("private"));assertNull(error.getCause());
    }
}
