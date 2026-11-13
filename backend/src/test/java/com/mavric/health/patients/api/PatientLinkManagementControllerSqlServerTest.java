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

/** Standalone MockMvc route/decoder/adapter tests. Filters here are doubles, not real auth/CSRF validation. */
class PatientLinkManagementControllerSqlServerTest {
    static final String A="aa000000-0000-4000-8000-000000000001",T="bb000000-0000-4000-8000-000000000001",P="cc000000-0000-4000-8000-000000000001",U="dd000000-0000-4000-8000-000000000001";
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);final ModelTransactionManager manager=new ModelTransactionManager();final Access access=mock(Access.class);final ObjectMapper mapper=new ObjectMapper();final PatientService service=new PatientService(new SqlServerPatientStore(executor,manager,mapper),access,mapper);
    Actor actor=new Actor(A,"Synthetic","qa@example.test",T,List.of("ADM"),"a".repeat(64));TenantRef tenant=new TenantRef(T,"Synthetic","clinic","DOCTOR","HUMAN","ACTIVE",List.of("PORTAL"));
    Object historical;Map<String,Object> override;final MockMvc mvc;
    PatientLinkManagementControllerSqlServerTest(){
        when(access.actor()).thenAnswer(inv->actor);
        when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
            assertTrue(TransactionSynchronizationManager.isActualTransactionActive());Object[] args=(Object[])inv.getRawArguments()[2];assertEquals(P,args[0]);var row=new LinkedHashMap<String,Object>();row.put("tenantId",T);row.put("patientId",P);row.put("userId",U);
            if(inv.getArgument(0)==SqlServerProcedure.PATIENT_LINK_EDIT_GET){assertEquals(U,args[1]);row.put("active",false);row.put("revision",7);row.put("userName","");row.put("relationship","");row.put("scopes",historical);}
            else{assertEquals(SqlServerProcedure.PATIENT_LINK_SAVE,inv.getArgument(0));var body=mapper.readValue((String)args[1],Map.class);row.put("active",body.get("active"));row.put("revision",(Integer)body.get("expectedRevision")+1);}
            return new SqlServerExecutor.Result(List.of(List.of(override==null?row:override)),List.of());
        });
        mvc=MockMvcBuilders.standaloneSetup(new PatientController(service)).setControllerAdvice(new Errors.Advice(new Errors(mapper))).addFilter((req,res,chain)->{var request=(jakarta.servlet.http.HttpServletRequest)req;request.setAttribute("health.requestId",A);request.setAttribute("health.actor",actor);if(tenant!=null)request.setAttribute("health.tenant",tenant);TraceContext.REQUEST.set(request);try{chain.doFilter(req,res);}finally{TraceContext.REQUEST.remove();}}).build();
    }
    String path(){return "/api/patients/"+P+"/links";}
    String body(){return "{\"userId\":\""+U+"\",\"expectedRevision\":0,\"active\":true,\"relationship\":\"Tutor\",\"scopes\":[\"DOCUMENTS\",\"BILLING\"]}";}
    @AfterEach void clear(){TraceContext.REQUEST.remove();TransactionSynchronizationManager.clear();}
    @Test void putReturnsAckFiveAndWithdrawalDoesNotRequireGrantData() throws Exception {
        for(String domain:List.of("HUMAN","ANIMAL")){
            tenant=new TenantRef(T,"Synthetic","clinic",domain.equals("ANIMAL")?"VETERINARY":"DOCTOR",domain,"TRIAL",List.of("PORTAL"));
            var json=mapper.readTree(mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());assertEquals(5,json.size());assertEquals(1,json.get("revision").asInt());assertNull(json.get("scopes"));
            json=mapper.readTree(mvc.perform(put(path()).contentType("application/json").content("{\"userId\":\""+U+"\",\"expectedRevision\":1,\"active\":false}")).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());assertFalse(json.get("active").asBoolean());assertEquals(2,json.get("revision").asInt());assertEquals(5,json.size());
        }
        verify(executor,times(4)).execute(eq(SqlServerProcedure.PATIENT_LINK_SAVE),any(),eq(P),anyString());
    }
    @Test void editGetProjectsEightHistoricalFieldsAndSingleRpc() throws Exception {
        for(Object scopes:Arrays.asList(null,"UNKNOWN",true,7,List.of("UNKNOWN","UNKNOWN"),Map.of("old",Arrays.asList(null,"DOCUMENTS")))){
            historical=scopes;var json=mapper.readTree(mvc.perform(get(path()+"/"+U)).andExpect(status().isOk()).andReturn().getResponse().getContentAsString());assertEquals(8,json.size());assertEquals(7,json.get("revision").asInt());assertEquals(mapper.valueToTree(scopes),json.get("scopes"));assertFalse(json.get("active").asBoolean());
        }
        verify(executor,times(6)).execute(eq(SqlServerProcedure.PATIENT_LINK_EDIT_GET),any(),eq(P),eq(U));
    }
    @Test void duplicateCoercedMissingExtraTrailingAndLexicalTokensAre400WithoutRpc() throws Exception {
        var bad=new ArrayList<String>(List.of("null","{}","[]",body()+" {}",body().replace("\"active\":true","\"active\":true,\"active\":false"),body().replace("\"active\":true","\"Active\":true"),body().replace("\"active\":true,",""),body().replace("[\"DOCUMENTS\",\"BILLING\"]","[\"DOCUMENTS\",\"DOCUMENTS\"]"),body().replace("\"relationship\":\"Tutor\"","\"relationship\":\"\\u00a0\""),body().replace(U,U+"suffix")));
        for(String number:List.of("-0","1.0","1e0","-1","2147483648","null","\"0\"","true"))bad.add(body().replace("\"expectedRevision\":0","\"expectedRevision\":"+number));
        bad.add("{\"userId\":\""+U+"\",\"expectedRevision\":1,\"active\":false,\"scopes\":null}");
        for(String json:bad)mvc.perform(put(path()).contentType("application/json").content(json)).andExpect(status().isBadRequest());verifyNoInteractions(executor);
    }
    @Test void pathSuffixUppercaseAndLongBodyIdsAreRejectedBeforeExecutor() throws Exception {
        for(String id:List.of(P+"suffix",P.toUpperCase(Locale.ROOT),"bad")){
            mvc.perform(put("/api/patients/"+id+"/links").contentType("application/json").content(body())).andExpect(status().isBadRequest());
            mvc.perform(get("/api/patients/"+id+"/links/"+U)).andExpect(status().isBadRequest());mvc.perform(get(path()+"/"+id)).andExpect(status().isBadRequest());
        }
        verifyNoInteractions(executor);
    }
    @Test void managementRolesModuleStatusHostAndSessionDoNotBroadenB() throws Exception {
        for(var roles:List.of(List.of("PRO"),List.of("PAC"),List.of("RES"),List.of("SAD","ADM"),List.of("SOP","REC"),List.of("ADM","PAC"),List.of("REC","RES"))){actor=new Actor(A,"Synthetic","qa@example.test",T,roles,"a".repeat(64));mvc.perform(get(path()+"/"+U)).andExpect(status().isForbidden());mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isForbidden());}
        actor=new Actor(A,"Synthetic","qa@example.test",T,List.of("REC"),"a".repeat(64));
        for(var t:List.of(new TenantRef(T,"Synthetic","clinic","DOCTOR","HUMAN","SUSPENDED",List.of("PORTAL")),new TenantRef(T,"Synthetic","clinic","DOCTOR","HUMAN","ACTIVE",List.of("CORE")),new TenantRef(P,"Synthetic","clinic","DOCTOR","HUMAN","ACTIVE",List.of("PORTAL")))){tenant=t;mvc.perform(get(path()+"/"+U)).andExpect(status().isForbidden());mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isForbidden());}
        tenant=null;mvc.perform(get(path()+"/"+U)).andExpect(status().isForbidden());doThrow(new ApiException(401,"UNAUTHENTICATED","Safe")).when(access).actor();mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isUnauthorized());verifyNoInteractions(executor);
    }
    @Test void vendorErrorsAndCommitFailuresNeverLeakOrReturnAnAck() throws Exception {
        for(var pair:List.of(List.of(51000,400),List.of(51001,403),List.of(51002,404),List.of(51003,409),List.of(51004,403),List.of(51005,409),List.of(1205,409),List.of(59999,500))){doThrow(new RuntimeException(new java.sql.SQLException("canary secret SQL",null,pair.getFirst()))).when(executor).execute(any(),any(),any(Object[].class));for(boolean edit:List.of(false,true)){var response=edit?mvc.perform(get(path()+"/"+U)):mvc.perform(put(path()).contentType("application/json").content(body()));String result=response.andExpect(status().is(pair.getLast())).andReturn().getResponse().getContentAsString();assertFalse(result.contains("canary"));}}
    }
    @Test void falseAckExtraColumnAndCommitFailureAreSafe500() throws Exception {
        override=new LinkedHashMap<>(Map.of("tenantId",T,"patientId",P,"userId",U,"active",true,"revision",2));String response=mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isInternalServerError()).andReturn().getResponse().getContentAsString();assertFalse(response.contains("revision"));assertEquals("rollback",manager.events.getLast());
        override.put("email","canary");response=mvc.perform(get(path()+"/"+U)).andExpect(status().isInternalServerError()).andReturn().getResponse().getContentAsString();assertFalse(response.contains("canary"));
        override=null;manager.failCommit=true;mvc.perform(put(path()).contentType("application/json").content(body())).andExpect(status().isInternalServerError());manager.failCommit=true;mvc.perform(get(path()+"/"+U)).andExpect(status().isInternalServerError());
    }
}
