package com.mavric.health.patients.api;

import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.*;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
import com.mavric.health.patients.application.PatientService;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Standalone MVC routing with real service/store and modeled executor/transactions; no socket or SQL. */
class PatientLinksControllerSqlServerTest {
    static final String ACTOR="aa000000-0000-4000-8000-000000000001",TENANT="bb000000-0000-4000-8000-000000000001",PATIENT="cc000000-0000-4000-8000-000000000001";
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);
    final ModelTransactionManager manager=new ModelTransactionManager();
    final Access access=mock(Access.class);
    final ObjectMapper mapper=new ObjectMapper();
    final PatientService service=new PatientService(new SqlServerPatientStore(executor,manager,mapper),access,mapper);
    Actor actor=new Actor(ACTOR,"Synthetic","private@example.test",TENANT,List.of("ADM"),"a".repeat(64));
    TenantRef tenant=new TenantRef(TENANT,"Synthetic","clinic","DOCTOR","HUMAN","SUSPENDED",List.of());
    Actor requestActor;
    List<Map<String,Object>> rows=List.of();
    final MockMvc mvc;

    PatientLinksControllerSqlServerTest(){
        when(access.actor()).thenAnswer(inv->actor);
        when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
            assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
            assertEquals(SqlServerProcedure.PATIENT_LINKS_LIST,inv.getArgument(0));
            assertEquals(SqlServerContext.Scope.REQUEST,inv.<SqlServerContext>getArgument(1).scope());
            return new SqlServerExecutor.Result(List.of(rows),List.of());
        });
        mvc=MockMvcBuilders.standaloneSetup(new PatientController(service))
                .setControllerAdvice(new Errors.Advice(new Errors(mapper)))
                .addFilter((req,res,chain)->{
                    var request=(jakarta.servlet.http.HttpServletRequest)req;
                    request.setAttribute("health.requestId",ACTOR);
                    request.setAttribute("health.actor",requestActor==null?actor:requestActor);
                    if(tenant!=null)request.setAttribute("health.tenant",tenant);
                    TraceContext.REQUEST.set(request);
                    try{chain.doFilter(req,res);}finally{TraceContext.REQUEST.remove();}
                }).build();
    }
    @AfterEach void cleanup(){TraceContext.REQUEST.remove();TransactionSynchronizationManager.clear();}
    String path(){return "/api/patients/"+PATIENT+"/links";}
    Map<String,Object> row(String user,String name,boolean active){var row=new LinkedHashMap<String,Object>();row.put("tenantId",TENANT);row.put("patientId",PATIENT);row.put("userId",user);row.put("userName",name);row.put("relationship","");row.put("active",active);row.put("scopes",List.of("UNKNOWN","UNKNOWN"));row.put("email","private@example.test");row.put("passwordHash","private");return row;}

    @Test void defaultsEmptyPageAndClampsAreActualMvcParameters() throws Exception {
        assertEquals("[]",mvc.perform(get(path())).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());
        verify(executor).execute(eq(SqlServerProcedure.PATIENT_LINKS_LIST),any(),eq(PATIENT),eq(50),eq(0));
        mvc.perform(get(path()).param("limit","999").param("offset","-4")).andExpect(status().isOk());
        verify(executor).execute(eq(SqlServerProcedure.PATIENT_LINKS_LIST),any(),eq(PATIENT),eq(200),eq(0));
        mvc.perform(get(path()).param("limit","0").param("offset","900")).andExpect(status().isOk());
        verify(executor).execute(eq(SqlServerProcedure.PATIENT_LINKS_LIST),any(),eq(PATIENT),eq(1),eq(900));
        verify(access,never()).write(anyString(),any(String[].class));
    }
    @Test void arrayContainsOnlySevenFieldsPreservingInactiveAndSqlOrder() throws Exception {
        rows=List.of(row(ACTOR,"Zulu",false),row(TENANT,"Alpha",true));
        var response=mvc.perform(get(path())).andExpect(status().isOk()).andReturn().getResponse();
        var json=mapper.readTree(response.getContentAsString());
        assertTrue(json.isArray());assertEquals(2,json.size());
        assertEquals("Zulu",json.get(0).get("userName").asText());assertFalse(json.get(0).get("active").asBoolean());assertTrue(json.get(1).get("active").asBoolean());
        assertEquals(7,json.get(0).size());assertEquals(7,json.get(1).size());
        assertEquals(List.of("UNKNOWN","UNKNOWN"),mapper.convertValue(json.get(0).get("scopes"),List.class));
        assertFalse(response.getContentAsString().contains("private"));
        verify(executor,times(1)).execute(any(),any(),any(Object[].class));
    }
    @Test void malformedNumbersAndUuidReturn400BeforeExecutor() throws Exception {
        for(String key:List.of("limit","offset"))for(String value:List.of("abc","1.5","2147483648"))mvc.perform(get(path()).param(key,value)).andExpect(status().isBadRequest());
        mvc.perform(get("/api/patients/not-a-uuid/links")).andExpect(status().isBadRequest());
        verifyNoInteractions(executor);
    }
    @Test void rolesMixedRolesHostAndActorAreRejectedThroughMvc() throws Exception {
        for(var roles:List.of(List.of("SAD"),List.of("SOP"),List.of("PAC"),List.of("RES"),List.of("PRO"),List.of("ADM","PAC"),List.of("REC","RES"))){actor=new Actor(ACTOR,"Synthetic","private@example.test",TENANT,roles,"a".repeat(64));mvc.perform(get(path())).andExpect(status().isForbidden());}
        actor=new Actor(ACTOR,"Synthetic","private@example.test",TENANT,List.of("REC"),"a".repeat(64));
        requestActor=new Actor(TENANT,"Synthetic","private@example.test",TENANT,List.of("REC"),"a".repeat(64));mvc.perform(get(path())).andExpect(status().isForbidden());requestActor=null;
        tenant=null;mvc.perform(get(path())).andExpect(status().isForbidden());verifyNoInteractions(executor);
    }
    @Test void unauthenticatedAndSpErrorsAreSanitizedAndDoNotFallback() throws Exception {
        doThrow(new ApiException(401,"UNAUTHENTICATED","Safe")).when(access).actor();mvc.perform(get(path())).andExpect(status().isUnauthorized());verifyNoInteractions(executor);
        doReturn(actor).when(access).actor();
        for(var pair:List.of(List.of(51000,400),List.of(51001,403),List.of(51002,404),List.of(51003,409),List.of(59999,500))){
            doThrow(new RuntimeException(new java.sql.SQLException("private engine detail",null,pair.getFirst()))).when(executor).execute(any(),any(),any(Object[].class));
            String body=mvc.perform(get(path())).andExpect(status().is(pair.getLast())).andReturn().getResponse().getContentAsString();assertFalse(body.contains("private"));
        }
    }
    @Test void contaminatedResultAndCommitFailureReturnSafe500() throws Exception {
        var bad=row(ACTOR,"Synthetic",true);bad.put("tenantId",ACTOR);rows=List.of(bad);
        String body=mvc.perform(get(path())).andExpect(status().isInternalServerError()).andReturn().getResponse().getContentAsString();assertTrue(body.contains("DATABASE_ERROR"));assertEquals("rollback",manager.events.getLast());
        rows=List.of();manager.failCommit=true;
        body=mvc.perform(get(path())).andExpect(status().isInternalServerError()).andReturn().getResponse().getContentAsString();assertTrue(body.contains("DATABASE_ERROR"));assertFalse(body.contains("private"));
    }
}
