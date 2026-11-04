package com.mavric.health.persistence.sqlserver;

import java.sql.SQLException;
import java.util.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.Actor;
import com.mavric.health.shared.ApiException;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Real REQUIRED templates + modeled manager/executor: no JDBC, database permissions or persistence. */
class SqlServerAccessStoreTest {
    private static final String USER="00000000-0000-4000-8000-000000000001",TENANT="00000000-0000-4000-8000-000000000002";
    private static final String BRANCH="aa000000-0000-4000-8000-000000000003",PATIENT="bb000000-0000-4000-8000-000000000004";
    private static final String HASH="a".repeat(64),REQUEST="00000000-0000-4000-8000-000000000005";
    private static final TenantRef REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"));
    private static final Actor ACTOR=new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of("ADM"),HASH);

    record Call(SqlServerProcedure procedure,SqlServerContext context,List<Object> parameters) {}
    final class Fixture {
        final SqlServerExecutor executor=mock(SqlServerExecutor.class);
        final ModelTransactionManager manager=new ModelTransactionManager();
        final SqlServerAccessStore store=new SqlServerAccessStore(executor,manager);
        final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/patients");
        final List<Call> calls=new ArrayList<>();
        final Deque<SqlServerExecutor.Result> results=new ArrayDeque<>();
        Fixture() {
            request.setAttribute("health.actor",ACTOR);request.setAttribute("health.tenant",REF);
            request.setAttribute("health.requestId",REQUEST);request.setRemoteAddr("127.0.0.9");request.addHeader("User-Agent","Synthetic agent");
            when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv-> {
                assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
                var procedure=inv.<SqlServerProcedure>getArgument(0);
                manager.events.add("sp:"+procedure.name());
                calls.add(new Call(procedure,inv.getArgument(1),Arrays.asList(((Object[])inv.getRawArguments()[2]).clone())));
                return results.removeFirst();
            });
        }
        void add(Map<String,Object> row) { results.add(new SqlServerExecutor.Result(List.of(List.of(row)),List.of(0))); }
        void empty() { results.add(new SqlServerExecutor.Result(List.of(List.of()),List.of())); }
    }
    private static Map<String,Object> branch() { return Map.of("id",BRANCH,"branchId",BRANCH); }
    private static Map<String,Object> link() { return Map.of("patientId",PATIENT); }
    @AfterEach void cleanup() {
        try { SecurityContextHolder.clearContext();TraceContext.REQUEST.remove(); }
        finally { TransactionSynchronizationManager.clear(); }
    }

    @Test void exactlyTwoDescriptorsUseExplicitBindsAndTrustedRequestContext() {
        Fixture f=new Fixture();f.add(branch());f.add(link());
        assertTrue(f.store.branch(f.request,BRANCH));assertTrue(f.store.link(f.request,PATIENT,"Documents.Custom"));
        assertEquals(List.of(SqlServerProcedure.ACCESS_BRANCH,SqlServerProcedure.ACCESS_PATIENT_LINK),f.calls.stream().map(Call::procedure).toList());
        assertEquals(List.of(BRANCH),f.calls.getFirst().parameters());
        assertEquals(List.of(PATIENT,"Documents.Custom"),f.calls.get(1).parameters());
        for(Call call:f.calls) {
            var context=call.context();assertEquals(SqlServerContext.Scope.REQUEST,context.scope());
            assertEquals(USER,context.actorId());assertEquals(TENANT,context.tenantId());assertEquals(HASH,context.tokenHash());
            assertEquals(List.of("ADM"),context.roles());assertEquals(REQUEST,context.requestId());assertEquals("GET",context.method());
            assertEquals("/api/patients",context.route());assertEquals("127.0.0.9",context.sourceIp());assertEquals("Synthetic agent",context.userAgent());
        }
        assertEquals(List.of("begin:0","sp:ACCESS_BRANCH","commit","begin:0","sp:ACCESS_PATIENT_LINK","commit"),f.manager.events);
        assertEquals("SqlServerAccessStore[redacted]",f.store.toString());
    }

    @Test void zeroRowsMeansUnavailableWithoutGuessingMissingInactiveForeignOrUnassigned() {
        Fixture f=new Fixture();f.empty();f.empty();
        assertFalse(f.store.branch(f.request,BRANCH));assertFalse(f.store.link(f.request,PATIENT,"DOCUMENTS"));
        assertEquals(2,Collections.frequency(f.manager.events,"commit"));assertEquals(2,f.calls.size());
    }

    @Test void joinsExternalRequiredUnitAndDoesNotCommitOrRetryIndependently() {
        Fixture f=new Fixture();f.add(branch());f.add(link());
        assertThrows(ApiException.class,()->f.manager.outer(()-> {
            assertTrue(f.store.branch(f.request,BRANCH));assertTrue(f.store.link(f.request,PATIENT,"BILLING"));
            assertEquals(List.of("begin:0","sp:ACCESS_BRANCH","sp:ACCESS_PATIENT_LINK"),f.manager.events);
            throw new ApiException(409,"CONFLICT","Synthetic later error");
        }));
        assertEquals("rollback",f.manager.events.getLast());assertEquals(0,Collections.frequency(f.manager.events,"commit"));
        assertEquals(2,f.calls.size());
    }

    @Test void directInvocationRejectsMissingMalformedForeignOrPlatformAuthorityBeforeExecutor() {
        for(int mode=0;mode<10;mode++) {
            Fixture f=new Fixture();MockHttpServletRequest request=f.request;
            switch(mode) {
                case 0 -> request=null;
                case 1 -> request.removeAttribute("health.actor");
                case 2 -> request.setAttribute("health.actor","forged");
                case 3 -> request.removeAttribute("health.tenant");
                case 4 -> request.setAttribute("health.tenant","forged");
                case 5 -> request.setAttribute("health.actor",new Actor(USER,"Synthetic","qa@example.test","foreign",List.of("ADM"),HASH));
                case 6 -> request.setAttribute("health.actor",new Actor(USER,"Synthetic","qa@example.test",null,List.of("SAD"),HASH));
                case 7 -> request.setAttribute("health.actor",new Actor(null,"Synthetic","qa@example.test",TENANT,List.of("ADM"),HASH));
                case 8 -> request.setAttribute("health.actor",new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of("ADM"),null));
                case 9 -> { request.removeAttribute("health.tenant");request.setAttribute("health.actor",new Actor(USER,"Synthetic","qa@example.test",null,List.of("SOP"),HASH)); }
            }
            final MockHttpServletRequest invalid=request;
            assertEquals(403,assertThrows(ApiException.class,()->f.store.branch(invalid,BRANCH)).status);
            assertEquals(403,assertThrows(ApiException.class,()->f.store.link(invalid,PATIENT,"DOCUMENTS")).status);
            verifyNoInteractions(f.executor);assertEquals(2,Collections.frequency(f.manager.events,"rollback"));
        }
    }

    @Test void canonicalIdsAndUtf16ScopeBoundsAreCheckedInsideCallbackBeforeExecutor() {
        for(String id:Arrays.asList(null,"","1-1-1-1-1",BRANCH.toUpperCase(Locale.ROOT),"not-an-id")) {
            Fixture f=new Fixture();
            assertEquals(400,assertThrows(ApiException.class,()->f.store.branch(f.request,id)).status);
            assertEquals(400,assertThrows(ApiException.class,()->f.store.link(f.request,id,"DOCUMENTS")).status);
            verifyNoInteractions(f.executor);
        }
        for(String scope:Arrays.asList(null,""," \t\n","\ud83e\uddb7".repeat(41),"x".repeat(81))) {
            Fixture f=new Fixture();
            assertEquals(400,assertThrows(ApiException.class,()->f.store.link(f.request,PATIENT,scope)).status);
            verifyNoInteractions(f.executor);assertEquals("rollback",f.manager.events.getLast());
        }
        for(String scope:List.of("DOCUMENTS","APPOINTMENTS","BILLING"," documents ", "Custom.Mixed", "\ud83e\uddb7".repeat(40))) {
            Fixture f=new Fixture();f.add(link());assertTrue(f.store.link(f.request,PATIENT,scope));
            assertEquals(List.of(PATIENT,scope),f.calls.getFirst().parameters());
        }
    }

    @Test void absentMultipleOrMultirowResultsetsFailClosedAndRollBackMapping() {
        for(var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of(),List.of()),List.of(List.of(branch(),branch())))) {
            Fixture f=new Fixture();f.results.add(new SqlServerExecutor.Result(sets,List.of()));
            safe500(()->f.store.branch(f.request,BRANCH));assertEquals("rollback",f.manager.events.getLast());
        }
        Fixture link=new Fixture();link.results.add(new SqlServerExecutor.Result(List.of(List.of(link(),link())),List.of()));
        safe500(()->link.store.link(link.request,PATIENT,"DOCUMENTS"));
    }

    @Test void branchColumnTypesAndBothIdsMustMatchExactlyAndNeverAuthorizeMalformedData() {
        List<Map<String,Object>> rows=new ArrayList<>(List.of(Map.of(),Map.of("id",BRANCH),Map.of("branchId",BRANCH),
                Map.of("id",1,"branchId",BRANCH),Map.of("id",BRANCH,"branchId",1),
                Map.of("id","other","branchId",BRANCH),Map.of("id",BRANCH,"branchId","other")));
        Map<String,Object> nullValue=new LinkedHashMap<>(branch());nullValue.put("id",null);rows.add(nullValue);
        for(var row:rows) {
            Fixture f=new Fixture();f.add(row);safe500(()->f.store.branch(f.request,BRANCH));
            assertEquals("rollback",f.manager.events.getLast());
        }
        for(var row:List.<Map<String,Object>>of(Map.of(),Map.of("patientId",1),Map.of("patientId","other"))) {
            Fixture f=new Fixture();f.add(row);safe500(()->f.store.link(f.request,PATIENT,"DOCUMENTS"));
        }
    }

    @Test void contextDoesNotUseForgedHeadersBodyOrUnrelatedTraceRequest() {
        Fixture f=new Fixture();f.add(link());
        f.request.addHeader("X-Tenant-Id","forged");f.request.addHeader("X-Actor-Id","forged");f.request.addHeader("X-Roles","SAD");
        f.request.addHeader("X-Scope","BOOTSTRAP");f.request.addHeader("X-Forwarded-For","203.0.113.1");
        f.request.setContent("{\"tenantId\":\"forged\",\"actorId\":\"forged\"}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        TraceContext.REQUEST.set(new MockHttpServletRequest("POST","/wrong"));
        assertTrue(f.store.link(f.request,PATIENT,"DOCUMENTS"));var context=f.calls.getFirst().context();
        assertEquals(TENANT,context.tenantId());assertEquals(USER,context.actorId());assertEquals("127.0.0.9",context.sourceIp());
        assertEquals("/api/patients",context.route());assertEquals(SqlServerContext.Scope.REQUEST,context.scope());
    }

    @Test void sqlErrorsKeepSafeStatusAndInfrastructure500NeverAuthorizesOrRetries() {
        for(int code:new int[]{51001,51002,51003,229,18456}) {
            Fixture f=new Fixture();
            doThrow(new RuntimeException(new SQLException("private hash token params",null,code)))
                    .when(f.executor).execute(any(),any(),any(Object[].class));
            ApiException error=assertThrows(ApiException.class,()->f.store.branch(f.request,BRANCH));
            assertEquals(code==51001?403:code==51002?404:code==51003?409:500,error.status);
            assertFalse(error.toString().contains("private"));assertNull(error.getCause());
            verify(f.executor,times(1)).execute(any(),any(),any(Object[].class));assertEquals("rollback",f.manager.events.getLast());
        }
    }

    @Test void malformedResultInsideJoinedTransactionMarksOuterRollbackAndCommitFailureIsSafe() {
        Fixture mapping=new Fixture();mapping.add(Map.of("id",BRANCH));
        safe500(()->mapping.manager.outer(()->mapping.store.branch(mapping.request,BRANCH)));
        assertTrue(mapping.manager.events.contains("rollbackOnly"));assertEquals("rollback",mapping.manager.events.getLast());
        Fixture commit=new Fixture();commit.add(branch());commit.manager.failCommit=true;
        safe500(()->commit.store.branch(commit.request,BRANCH));assertEquals(1,commit.calls.size());
    }

    private static void safe500(Runnable action) {
        ApiException error=assertThrows(ApiException.class,action::run);
        assertEquals(500,error.status);assertEquals("DATABASE_ERROR",error.code);
        assertFalse(error.toString().contains("private"));assertNull(error.getCause());
    }
}
