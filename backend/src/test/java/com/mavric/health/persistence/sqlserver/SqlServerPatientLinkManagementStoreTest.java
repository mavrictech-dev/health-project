package com.mavric.health.persistence.sqlserver;

import java.math.BigDecimal;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.ApiException;
import com.mavric.health.patients.domain.Requests.Link;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

/** Adapter/transaction model only. Canned ACKs do not prove SQL CAS or authorization. */
class SqlServerPatientLinkManagementStoreTest {
    static final String A="aa000000-0000-4000-8000-000000000001",T="bb000000-0000-4000-8000-000000000001",P="cc000000-0000-4000-8000-000000000001",U="dd000000-0000-4000-8000-000000000001";
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);final ModelTransactionManager manager=new ModelTransactionManager();final ObjectMapper mapper=new ObjectMapper();
    final SqlServerPatientStore store=new SqlServerPatientStore(executor,manager,mapper);final MockHttpServletRequest req=new MockHttpServletRequest("PUT","/api/patients/"+P+"/links");
    SqlServerExecutor.Result answer;Object[] args;SqlServerProcedure called;int calls;
    SqlServerPatientLinkManagementStoreTest(){authority("HUMAN",List.of("ADM"),"ACTIVE",List.of("PORTAL"));when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());called=inv.getArgument(0);var c=inv.<SqlServerContext>getArgument(1);assertEquals(SqlServerContext.Scope.REQUEST,c.scope());assertEquals(T,c.tenantId());assertEquals(A,c.requestId());args=((Object[])inv.getRawArguments()[2]).clone();calls++;return answer;});}
    void authority(String domain,List<String> roles,String status,List<String> modules){req.setAttribute("health.requestId",A);req.setAttribute("health.actor",new Actor(A,"Synthetic","qa@example.test",T,roles,"a".repeat(64)));req.setAttribute("health.tenant",new TenantRef(T,"Synthetic","clinic",domain.equals("ANIMAL")?"VETERINARY":"DOCTOR",domain,status,modules));}
    Link set(int revision){return new Link(U,revision,"\u00a0Tutor 🦷 ",true,List.of("BILLING","DOCUMENTS","APPOINTMENTS"));}
    Link off(int revision){return new Link(U,revision,null,false,null);}
    Map<String,Object> ack(boolean active,int revision){return new LinkedHashMap<>(Map.of("tenantId",T,"patientId",P,"userId",U,"active",active,"revision",revision));}
    Map<String,Object> edit(Object scopes){var r=ack(false,7);r.put("userName","");r.put("relationship","");r.put("scopes",scopes);return r;}
    void row(Map<String,Object> row){answer=new SqlServerExecutor.Result(List.of(List.of(row)),List.of());}
    void error(int status,Runnable work){var e=assertThrows(ApiException.class,work::run);assertEquals(status,e.status);assertFalse(e.toString().contains("canary"));if(status==500){assertEquals("DATABASE_ERROR",e.code);assertNull(e.getCause());}}
    @AfterEach void clear(){TransactionSynchronizationManager.clear();}
    @Test void humanAnimalSetWithdrawAndRevisionBindsHaveOneRpcNoReads(){
        for(String domain:List.of("HUMAN","ANIMAL"))for(String role:List.of("ADM","REC")){
            authority(domain,List.of(role),"TRIAL",List.of("PORTAL"));
            for(int revision:List.of(0,1,7)){
                row(ack(true,revision+1));var result=store.link(req,P,set(revision));assertEquals(5,result.size());assertEquals(revision+1,result.get("revision"));assertEquals(SqlServerProcedure.PATIENT_LINK_SAVE,called);assertEquals(2,args.length);assertEquals(P,args[0]);
                var json=mapper.readValue((String)args[1],Map.class);assertEquals(Set.of("userId","expectedRevision","active","relationship","scopes"),json.keySet());assertEquals(set(revision).relationship(),json.get("relationship"));assertEquals(set(revision).scopes(),json.get("scopes"));assertThrows(UnsupportedOperationException.class,result::clear);
            }
            row(ack(false,8));assertEquals(false,store.link(req,P,off(7)).get("active"));assertEquals(Map.of("userId",U,"expectedRevision",7,"active",false),mapper.readValue((String)args[1],Map.class));
            row(edit(null));assertEquals(8,store.linkEdit(req,P,U).size());assertEquals(SqlServerProcedure.PATIENT_LINK_EDIT_GET,called);assertEquals(List.of(P,U),Arrays.asList(args));
        }
        assertEquals(20,calls);
    }
    @Test void exactIdsAndDirectDtoTypesStopBeforeExecutor(){
        for(String id:List.of("bad",P+"suffix",P+" ",P.toUpperCase(Locale.ROOT)," "+P)) {error(400,()->store.link(req,id,set(0)));error(400,()->store.linkEdit(req,id,U));error(400,()->store.linkEdit(req,P,id));error(400,()->store.link(req,P,new Link(id,0,"Tutor",true,List.of("DOCUMENTS"))));}
        for(Link value:Arrays.asList(null,new Link(U,null,null,false,null),new Link(U,-1,null,false,null),new Link(U,0,"Tutor",null,List.of("DOCUMENTS")),new Link(U,1,"",false,null),new Link(U,1,null,false,List.of()),new Link(U,0,"\u00a0\u2000",true,List.of("DOCUMENTS")),new Link(U,0,"x".repeat(81),true,List.of("DOCUMENTS")),new Link(U,0,"Tutor",true,Arrays.asList("DOCUMENTS",null)),new Link(U,0,"Tutor",true,List.of("DOCUMENTS","DOCUMENTS"))))error(400,()->store.link(req,P,value));
        verifyNoInteractions(executor);
    }
    @Test void authorityAndInternalContextAreRecheckedForBoth(){
        for(var roles:List.of(List.of("PRO"),List.of("PAC"),List.of("RES"),List.of("SAD","ADM"),List.of("SOP","REC"),List.of("ADM","PAC"),List.of("REC","RES"))){authority("HUMAN",roles,"ACTIVE",List.of("PORTAL"));error(403,()->store.link(req,P,set(0)));error(403,()->store.linkEdit(req,P,U));}
        authority("HUMAN",List.of("ADM"),"SUSPENDED",List.of("PORTAL"));error(403,()->store.link(req,P,set(0)));error(403,()->store.linkEdit(req,P,U));
        authority("HUMAN",List.of("REC"),"ACTIVE",List.of("CORE"));error(403,()->store.link(req,P,set(0)));error(403,()->store.linkEdit(req,P,U));
        authority("HUMAN",List.of("ADM"),"ACTIVE",List.of("PORTAL"));req.removeAttribute("health.requestId");error(500,()->store.link(req,P,set(0)));error(500,()->store.linkEdit(req,P,U));
        req.setAttribute("health.requestId",A);req.setAttribute("health.actor",new Actor(A,"Synthetic","qa@example.test",P,List.of("ADM"),"a".repeat(64)));error(403,()->store.link(req,P,set(0)));error(403,()->store.linkEdit(req,P,U));
        authority("INVALID",List.of("ADM"),"ACTIVE",List.of("PORTAL"));error(500,()->store.link(req,P,set(0)));error(500,()->store.linkEdit(req,P,U));verifyNoInteractions(executor);
    }
    @Test void contaminatedAckCannotConfirmDraftAndAlwaysRollsBack(){
        var fields=ack(true,1);
        for(String key:fields.keySet()){var r=ack(true,1);r.remove(key);row(r);error(500,()->store.link(req,P,set(0)));assertEquals("rollback",manager.events.getLast());}
        for(var entry:List.of(Map.entry("tenantId",A),Map.entry("patientId",A),Map.entry("userId",A),Map.entry("active",false),Map.entry("active",1),Map.entry("revision",1L),Map.entry("revision",0),Map.entry("revision",2),Map.entry("secret","canary"))){var r=ack(true,1);r.put(entry.getKey(),entry.getValue());row(r);error(500,()->store.link(req,P,set(0)));}
        row(ack(true,Integer.MAX_VALUE));error(500,()->store.link(req,P,set(Integer.MAX_VALUE)));
        for(var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of()),List.of(List.of(ack(true,1),ack(true,1))),List.of(List.of(ack(true,1)),List.of()))){answer=new SqlServerExecutor.Result(sets,List.of());error(500,()->store.link(req,P,set(0)));error(500,()->store.linkEdit(req,P,U));}
        answer=null;error(500,()->store.link(req,P,set(0)));error(500,()->store.linkEdit(req,P,U));
    }
    @Test void editHistoricalJsonIncludesNullScalarObjectAndImmutableCopiesWithoutEligibilityInterpretation(){
        for(Object value:Arrays.asList(null,"UNKNOWN",true,9,new BigDecimal("12345678901234567890.1234"),List.of(),List.of("UNKNOWN","UNKNOWN"),Map.of("historical",Arrays.asList(null,"DOCUMENTS")))){
            row(edit(value));var result=store.linkEdit(req,P,U);assertEquals(8,result.size());assertEquals(value,result.get("scopes"));assertEquals("",result.get("relationship"));assertEquals(false,result.get("active"));assertThrows(UnsupportedOperationException.class,result::clear);
        }
        var children=new ArrayList<Object>(Arrays.asList(null,"UNKNOWN"));var graph=new LinkedHashMap<String,Object>();graph.put("values",children);row(edit(graph));var scopes=(Map<?,?>)store.linkEdit(req,P,U).get("scopes");children.clear();assertEquals(2,((List<?>)scopes.get("values")).size());assertThrows(UnsupportedOperationException.class,scopes::clear);assertThrows(UnsupportedOperationException.class,((List<?>)scopes.get("values"))::clear);
        Object deep="leaf";for(int i=0;i<2000;i++)deep=Map.of("next",deep);row(edit(deep));Object copy=store.linkEdit(req,P,U).get("scopes");for(int i=0;i<2000;i++)copy=((Map<?,?>)copy).get("next");assertEquals("leaf",copy);
    }
    @Test void editRejectsExtraMissingFalseTypesCyclesAndCustomValues(){
        for(String key:edit(null).keySet()){var r=edit(null);r.remove(key);row(r);error(500,()->store.linkEdit(req,P,U));}
        for(var entry:List.of(Map.entry("userName",1),Map.entry("userName","x".repeat(161)),Map.entry("relationship","x".repeat(81)),Map.entry("relationship",1),Map.entry("active",1),Map.entry("revision",0),Map.entry("revision",1L),Map.entry("tenantId",A),Map.entry("userId",A),Map.entry("patientId",A),Map.entry("email","canary"))){var r=edit(null);r.put(entry.getKey(),entry.getValue());row(r);error(500,()->store.linkEdit(req,P,U));}
        var cycle=new HashMap<String,Object>();cycle.put("self",cycle);var badKey=new HashMap<Object,Object>();badKey.put(1,"bad");
        for(Object value:List.of(cycle,badKey,Double.NaN,Double.POSITIVE_INFINITY,new Object())){row(edit(value));error(500,()->store.linkEdit(req,P,U));assertEquals("rollback",manager.events.getLast());}
    }
    @Test void safeFailuresCommitAndOuterRollbackNeverRetryOrReturnEarly(){
        row(ack(true,1));manager.failCommit=true;error(500,()->store.link(req,P,set(0)));row(edit(null));manager.failCommit=true;error(500,()->store.linkEdit(req,P,U));
        row(ack(true,1));assertThrows(RuntimeException.class,()->manager.outer(()->{store.link(req,P,set(0));throw new RuntimeException("cancel");}));assertEquals("rollback",manager.events.getLast());
        row(edit(null));assertThrows(RuntimeException.class,()->manager.outer(()->{store.linkEdit(req,P,U);throw new RuntimeException("cancel");}));assertEquals("rollback",manager.events.getLast());
        int prior=calls;for(var pair:List.of(List.of(51000,400),List.of(51001,403),List.of(51002,404),List.of(51003,409),List.of(51004,403),List.of(51005,409),List.of(1205,409),List.of(547,409),List.of(59999,500))){doThrow(new RuntimeException(new java.sql.SQLException("canary engine",null,pair.getFirst()))).when(executor).execute(any(),any(),any(Object[].class));error(pair.getLast(),()->store.link(req,P,set(0)));error(pair.getLast(),()->store.linkEdit(req,P,U));}
        verify(executor,times(prior+18)).execute(any(),any(),any(Object[].class));
    }
}
