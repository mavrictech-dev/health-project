package com.mavric.health.patients.application;

import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.*;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
import com.mavric.health.patients.domain.Requests.Link;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

/** Service + adapter models; no authenticated network, JDBC or SQL. */
class PatientLinkManagementServiceSqlServerTest {
    static final String A="aa000000-0000-4000-8000-000000000001",T="bb000000-0000-4000-8000-000000000001",P="cc000000-0000-4000-8000-000000000001",U="dd000000-0000-4000-8000-000000000001";
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);final Access access=mock(Access.class);final Sql legacy=mock(Sql.class);final ObjectMapper mapper=new ObjectMapper();final ModelTransactionManager manager=new ModelTransactionManager();
    final PatientService service=new PatientService(new SqlServerPatientStore(executor,manager,mapper),access,mapper);final MockHttpServletRequest req=new MockHttpServletRequest("PUT","/api/patients/"+P+"/links");
    void actor(List<String> roles,String domain){var a=new Actor(A,"Synthetic","qa@example.test",T,roles,"a".repeat(64));doReturn(a).when(access).actor();req.setAttribute("health.actor",a);req.setAttribute("health.tenant",new TenantRef(T,"Synthetic","clinic",domain.equals("ANIMAL")?"VETERINARY":"DOCTOR",domain,"ACTIVE",List.of("PORTAL")));req.setAttribute("health.requestId",A);TraceContext.REQUEST.set(req);}
    Link off(){return new Link(U,7,null,false,null);}
    @AfterEach void cleanup(){TraceContext.REQUEST.remove();TransactionSynchronizationManager.clear();}
    @Test void bothDomainsUseOnlyTheApprovedRpcAndReturnServerVersions(){
        when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());assertEquals(SqlServerContext.Scope.REQUEST,inv.<SqlServerContext>getArgument(1).scope());var row=new LinkedHashMap<String,Object>(Map.of("tenantId",T,"patientId",P,"userId",U,"active",false,"revision",8));if(inv.getArgument(0)==SqlServerProcedure.PATIENT_LINK_EDIT_GET){row.put("userName","");row.put("relationship","");row.put("scopes",null);}else assertEquals(SqlServerProcedure.PATIENT_LINK_SAVE,inv.getArgument(0));return new SqlServerExecutor.Result(List.of(List.of(row)),List.of());});
        for(String domain:List.of("HUMAN","ANIMAL"))for(String role:List.of("ADM","REC")){actor(List.of(role),domain);assertEquals(8,service.link(P,off()).get("revision"));assertEquals(8,service.linkEdit(P,U).get("revision"));}
        verify(executor,times(4)).execute(eq(SqlServerProcedure.PATIENT_LINK_SAVE),any(),eq(P),anyString());verify(executor,times(4)).execute(eq(SqlServerProcedure.PATIENT_LINK_EDIT_GET),any(),eq(P),eq(U));verify(access,never()).link(anyString(),anyString());verify(access,never()).branch(anyString());verifyNoInteractions(legacy);
    }
    @Test void legacyManagementIsClosedBeforeAnySqlOrFallback(){var service=new PatientService(legacy,access,mapper);assertEquals(500,assertThrows(ApiException.class,()->service.link(P,off())).status);assertEquals(500,assertThrows(ApiException.class,()->service.linkEdit(P,U)).status);verifyNoInteractions(legacy,access,executor);}
    @Test void mixedPortalRolesForeignHostActorAndUnauthenticatedNeverCallExecutor(){
        for(var roles:List.of(List.of("PRO"),List.of("SAD","ADM"),List.of("SOP","REC"),List.of("ADM","PAC"),List.of("REC","RES"))){actor(roles,"HUMAN");assertEquals(403,assertThrows(ApiException.class,()->service.link(P,off())).status);assertEquals(403,assertThrows(ApiException.class,()->service.linkEdit(P,U)).status);}
        actor(List.of("ADM"),"HUMAN");req.setAttribute("health.actor",new Actor(U,"Synthetic","qa@example.test",T,List.of("ADM"),"a".repeat(64)));assertEquals(403,assertThrows(ApiException.class,()->service.link(P,off())).status);assertEquals(403,assertThrows(ApiException.class,()->service.linkEdit(P,U)).status);
        actor(List.of("REC"),"HUMAN");req.setAttribute("health.tenant",new TenantRef(P,"Synthetic","clinic","DOCTOR","HUMAN","ACTIVE",List.of("PORTAL")));assertEquals(403,assertThrows(ApiException.class,()->service.link(P,off())).status);assertEquals(403,assertThrows(ApiException.class,()->service.linkEdit(P,U)).status);
        actor(List.of("ADM"),"HUMAN");doThrow(new ApiException(401,"UNAUTHENTICATED","Safe")).when(access).actor();assertEquals(401,assertThrows(ApiException.class,()->service.link(P,off())).status);assertEquals(401,assertThrows(ApiException.class,()->service.linkEdit(P,U)).status);verifyNoInteractions(executor,legacy);
    }
    @Test void longAndUppercasePathsNeverReachRpcForEitherOperation(){actor(List.of("REC"),"ANIMAL");for(String id:List.of(P+"suffix",P.toUpperCase(Locale.ROOT)," "+P)){assertEquals(400,assertThrows(ApiException.class,()->service.link(id,off())).status);assertEquals(400,assertThrows(ApiException.class,()->service.linkEdit(id,U)).status);assertEquals(400,assertThrows(ApiException.class,()->service.linkEdit(P,id)).status);}verifyNoInteractions(executor,legacy);}
}
