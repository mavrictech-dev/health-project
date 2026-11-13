package com.mavric.health.persistence.sqlserver;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.identity.*;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Real transaction templates and modeled executor, never SQL/CAS/concurrency evidence. */
class SqlServerTenantRucStoreTest {
    static final String ID="00000000-0000-4000-8000-000000000001",RUC="00000000001";
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);
    final SqlServerIdentityStoreTest.ModelTransactionManager manager=new SqlServerIdentityStoreTest.ModelTransactionManager();
    final SqlServerIdentityStore identity=new SqlServerIdentityStore(executor,manager);
    final SqlServerPlatformStore platform=new SqlServerPlatformStore(executor,manager);
    final MockHttpServletRequest request=new MockHttpServletRequest("POST","/api/public/tenant-space");
    @AfterEach void clean(){TransactionSynchronizationManager.clear();}
    void row(Map<String,Object> row){doAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());return new SqlServerExecutor.Result(List.of(List.of(row)),List.of());}).when(executor).execute(any(),any(),any(Object[].class));}
    void tenant(){request.setAttribute("health.tenant",new TenantRef(ID,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"),RUC,1));}
    void sad(){request.setAttribute("health.actor",new Actor(ID,"Synthetic","qa@example.test",null,List.of("SAD"),"a".repeat(64)));}
    @Test void publicResolverUsesOnlyRucAndTrustedBaseDomainInIdentityTransaction(){
        row(Map.of("hostname","clinic.health.localhost"));assertEquals("clinic.health.localhost",identity.tenantSpace(request,RUC,"health.localhost"));
        verify(executor).execute(eq(SqlServerProcedure.TENANT_SPACE_RESOLVE),argThat(c->c.tenantId()==null&&c.actorId()==null&&c.scope()==SqlServerContext.Scope.IDENTITY),eq(RUC),eq("health.localhost"));assertEquals(List.of("begin:0","commit"),manager.events);
    }
    @Test void maliciousOrExpandedResolverResultsFailSanitizedAndRollback(){
        for(String host:List.of("evil.example.test","clinic.health.localhost:999","clinic.health.localhost.evil.test","a.b.health.localhost","admin.health.localhost","CLINIC.health.localhost","clinic.health.localhost.")){
            row(Map.of("hostname",host));var error=assertThrows(ApiException.class,()->identity.tenantSpace(request,RUC,"health.localhost"));assertEquals(500,error.status);assertFalse(error.getMessage().contains(host));assertEquals("rollback",manager.events.getLast());
        }
        row(Map.of("hostname","clinic.health.localhost","token","CANARY"));assertEquals(500,assertThrows(ApiException.class,()->identity.tenantSpace(request,RUC,"health.localhost")).status);
    }
    @Test void resolverHostOrMalformedRucNeverReachesExecutor(){
        for(String ruc:Arrays.asList(null,"","0000000000","000000000001","００００００００００１"))assertEquals(400,assertThrows(ApiException.class,()->identity.tenantSpace(request,ruc,"health.localhost")).status);
        tenant();assertEquals(403,assertThrows(ApiException.class,()->identity.tenantSpace(request,RUC,"health.localhost")).status);verifyNoInteractions(executor);
    }
    @Test void loginRucLockUsesHostTenantAndChecksExactIdentitySnapshot(){
        tenant();row(Map.of("id",ID,"ruc",RUC,"revision",2));assertTrue(identity.lockTenantRuc(request,RUC));
        verify(executor).execute(eq(SqlServerProcedure.IDENTITY_TENANT_RUC_LOCK),argThat(c->ID.equals(c.tenantId())&&c.actorId()==null&&c.scope()==SqlServerContext.Scope.IDENTITY),eq(RUC));
        for(var bad:List.of(Map.<String,Object>of("id",ID,"ruc",RUC,"revision",2L),Map.<String,Object>of("id",ID,"ruc","00000000002","revision",2),Map.<String,Object>of("id",ID,"ruc",RUC,"revision",2,"extra","CANARY"))){row(bad);assertEquals(500,assertThrows(ApiException.class,()->identity.lockTenantRuc(request,RUC)).status);}
        when(executor.execute(any(),any(),any(Object[].class))).thenReturn(new SqlServerExecutor.Result(List.of(List.of()),List.of()));assertFalse(identity.lockTenantRuc(request,RUC));
    }
    Map<String,Object> profileRow(){var r=SqlServerPlatformStoreTest.tenantRow();r.put("name","Edited");r.put("ruc","00000000002");r.put("timezone","UTC");r.put("revision",8);return r;}
    RucRequests.Profile profile(){return new RucRequests.Profile("Edited","00000000002","UTC",7);}
    @Test void sadProfileUsesOneCasRpcAndReturnedStableTenantIdentity(){
        sad();var r=profileRow();row(r);String id=(String)r.get("id");var out=platform.profile(request,id,profile());assertEquals(id,out.get("id"));assertEquals(8,out.get("revision"));assertEquals("00000000002",out.get("ruc"));
        verify(executor,times(1)).execute(eq(SqlServerProcedure.TENANT_PROFILE_SAVE),argThat(c->c.scope()==SqlServerContext.Scope.REQUEST&&c.tenantId()==null&&c.roles().equals(List.of("SAD"))),eq(id),argThat(s->s instanceof String text&&text.contains("\"expectedRevision\":7")));assertEquals(List.of("begin:0","commit"),manager.events);
    }
    @Test void profileRejectsSopTenantAuthorityAndInvalidCommandBeforeRpc(){
        sad();request.setAttribute("health.actor",new Actor(ID,"Synthetic","qa@example.test",null,List.of("SOP"),"a".repeat(64)));assertEquals(403,assertThrows(ApiException.class,()->platform.profile(request,ID,profile())).status);
        sad();assertEquals(400,assertThrows(ApiException.class,()->platform.profile(request,ID+"suffix",profile())).status);
        assertEquals(400,assertThrows(ApiException.class,()->platform.profile(request,ID,new RucRequests.Profile("Edited","bad","UTC",1))).status);verifyNoInteractions(executor);
    }
    @Test void staleConflictAndFalseAckNeverBecomeSuccessOrCommit(){
        sad();String id=(String)profileRow().get("id");when(executor.execute(any(),any(),any(Object[].class))).thenThrow(new RuntimeException(new java.sql.SQLException("CANARY",null,51003)));
        assertEquals(409,assertThrows(ApiException.class,()->platform.profile(request,id,profile())).status);assertEquals("rollback",manager.events.getLast());
        var r=profileRow();r.put("revision",7);row(r);assertEquals(500,assertThrows(ApiException.class,()->platform.profile(request,id,profile())).status);assertEquals("rollback",manager.events.getLast());
    }
}
