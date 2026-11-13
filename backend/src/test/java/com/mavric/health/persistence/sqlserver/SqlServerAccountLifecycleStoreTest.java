package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.sql.SQLException;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.shared.ApiException;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

/** Executor doubles and modeled transactions; no database connection or snapshot guarantee. */
class SqlServerAccountLifecycleStoreTest {
    static final String ID="aa000000-0000-4000-8000-000000000001";
    static Map<String,Object> plan() {return new LinkedHashMap<>(Map.of("id",ID,"name","Cl\u00ednica \u4e2d\ud83e\uddb7","kinds",new ArrayList<>(List.of("CUSTOM")),"domains",List.of("HUMAN"),"includedBranches",1,"includedProfessionals",2,"includedSpecialties",3,"baseMinor",Long.MAX_VALUE));}
    static Map<String,Object> specialty() {return new LinkedHashMap<>(Map.of("code","x","name","\u00c1rea","domain","HUMAN","dental",true));}
    static SqlServerExecutor.Result result(List<Map<String,Object>> rows) {return new SqlServerExecutor.Result(List.of(rows),List.of(0));}
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);
    final ModelTransactionManager manager=new ModelTransactionManager();
    final SqlServerAccountLifecycleStore store=new SqlServerAccountLifecycleStore(executor,manager);
    final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/public/registration");
    final List<SqlServerProcedure> calls=new ArrayList<>();
    final Deque<SqlServerExecutor.Result> results=new ArrayDeque<>();
    SqlServerAccountLifecycleStoreTest() {
        when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
            assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
            calls.add(inv.getArgument(0));
            SqlServerContext c=inv.getArgument(1);assertEquals(SqlServerContext.Scope.REQUEST,c.scope());assertNull(c.actorId());assertNull(c.tenantId());
            assertEquals(0,((Object[])inv.getRawArguments()[2]).length);
            return results.removeFirst();
        });
    }
    void valid() {results.add(result(List.of(plan())));results.add(result(List.of(specialty())));}
    @AfterEach void cleanup() {TraceContext.REQUEST.remove();TransactionSynchronizationManager.clear();}
    static void safe(Runnable work) {var e=assertThrows(ApiException.class,work::run);assertEquals(500,e.status);assertEquals("DATABASE_ERROR",e.code);assertNull(e.getCause());assertFalse(e.toString().contains("secret"));}
    @Test void twoReadsExactOrderImmutableSafeProjectionNoPrecisionLoss() {
        var p=plan();p.put("passwordHash","secret");var s=specialty();s.put("tokenHash","secret");
        results.add(result(List.of(p)));results.add(result(List.of(s)));
        var out=store.options(request);assertEquals(List.of(SqlServerProcedure.REGISTRATION_PLANS,SqlServerProcedure.REGISTRATION_SPECIALTIES),calls);
        var plans=(List<Map<String,Object>>)out.get("plans");var mapped=plans.getFirst();assertEquals(8,mapped.size());assertEquals(Long.MAX_VALUE,mapped.get("baseMinor"));assertEquals(p.get("name"),mapped.get("name"));
        assertFalse(out.toString().contains("secret"));assertThrows(UnsupportedOperationException.class,()->out.clear());assertThrows(UnsupportedOperationException.class,()->plans.clear());assertThrows(UnsupportedOperationException.class,()->mapped.clear());
        assertThrows(UnsupportedOperationException.class,()->((List<?>)mapped.get("kinds")).clear());((List<?>)p.get("kinds")).clear();assertEquals(List.of("CUSTOM"),mapped.get("kinds"));
        assertEquals(List.of("begin:0","commit"),manager.events);
    }
    @Test void emptyAndLargerThan241CatalogPreserveOrder() {
        results.add(result(List.of()));results.add(result(List.of()));assertEquals(Map.of("plans",List.of(),"specialties",List.of()),store.options(request));
        var rows=new ArrayList<Map<String,Object>>();for(int i=0;i<300;i++){var p=plan();p.put("name","row"+i);rows.add(p);}
        results.add(result(rows));results.add(result(List.of()));var out=(List<Map<String,Object>>)store.options(request).get("plans");assertEquals(300,out.size());assertEquals("row299",out.getLast().get("name"));
    }
    @Test void malformedPlansRollbackWithoutSecondCall() {
        for(String key:plan().keySet()) for(Object bad:Arrays.asList(null,Boolean.TRUE,0.5)) {
            var p=plan();p.put(key,bad);results.add(result(List.of(p)));safe(()->store.options(request));assertEquals("rollback",manager.events.getLast());
        }
        for(Object bad:List.of(0,-1,1L)) {var p=plan();p.put("includedBranches",bad);results.add(result(List.of(p)));safe(()->store.options(request));}
        for(Object bad:List.of(-1L,1,1.0)) {var p=plan();p.put("baseMinor",bad);results.add(result(List.of(p)));safe(()->store.options(request));}
        for(Object bad:List.of(ID.toUpperCase(Locale.ROOT),"1-1-1-1-1")) {var p=plan();p.put("id",bad);results.add(result(List.of(p)));safe(()->store.options(request));}
        var p=plan();p.put("kinds",Arrays.asList("ok",null));results.add(result(List.of(p)));safe(()->store.options(request));
        var missing=plan();missing.remove("name");results.add(result(List.of(missing)));safe(()->store.options(request));
        assertFalse(calls.contains(SqlServerProcedure.REGISTRATION_SPECIALTIES));
    }
    @Test void malformedSpecialtiesAndResultsetCountRollback() {
        for(String key:specialty().keySet()) for(Object bad:Arrays.asList(null,1)) {var s=specialty();s.put(key,bad);results.add(result(List.of(plan())));results.add(result(List.of(s)));safe(()->store.options(request));assertEquals("rollback",manager.events.getLast());}
        for(var sets:List.<List<List<Map<String,Object>>>>of(List.of(),List.of(List.of(),List.of()))) {results.add(new SqlServerExecutor.Result(sets,List.of()));safe(()->store.options(request));}
    }
    @Test void hostGuardInsideTransactionNeverExecutor() {
        safe(()->store.options(null));request.setAttribute("health.tenant","forged");safe(()->store.options(request));
        request.setAttribute("health.tenant",new TenantRef(ID,"x","x","CLINIC","HUMAN","ACTIVE",List.of()));safe(()->store.options(request));verifyNoInteractions(executor);assertEquals(3,Collections.frequency(manager.events,"rollback"));
    }
    @Test void joinedRequiredRollbackAndCommitFailure() {
        valid();assertThrows(RuntimeException.class,()->manager.outer(()->{store.options(request);assertEquals(List.of("begin:0"),manager.events);throw new RuntimeException("synthetic outer failure");}));assertEquals(0,Collections.frequency(manager.events,"commit"));assertEquals("rollback",manager.events.getLast());
        valid();manager.failCommit=true;safe(()->store.options(request));
    }
    @Test void secondCallFailureCannotReturnPartialSuccessAndNoRetry() {
        doAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());if(inv.getArgument(0)==SqlServerProcedure.REGISTRATION_SPECIALTIES)throw new RuntimeException(new SQLException("secret",null,229));return result(List.of(plan()));}).when(executor).execute(any(),any(),any(Object[].class));
        safe(()->store.options(request));assertEquals("rollback",manager.events.getLast());verify(executor,times(2)).execute(any(),any(),any(Object[].class));
    }
    @Test void serverConflictsRemainSafe() {
        doThrow(new RuntimeException(new SQLException("secret",null,51003))).when(executor).execute(any(),any(),any(Object[].class));
        assertEquals(409,assertThrows(ApiException.class,()->store.options(request)).status);assertEquals("rollback",manager.events.getLast());
    }
    static final String HASH="a".repeat(64);
    void identityExecutor() {reset(executor);when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());var c=inv.<SqlServerContext>getArgument(1);assertEquals(SqlServerContext.Scope.IDENTITY,c.scope());calls.add(inv.getArgument(0));return results.removeFirst();});}
    Map<String,Object> account(){var row=new LinkedHashMap<String,Object>();row.put("id",ID);row.put("email","qa@example.test");row.put("emailVerified",true);row.put("platformRole",null);return row;}
    void writeResult(){results.add(new SqlServerExecutor.Result(List.of(),List.of(0)));}
    @Test void identityFourDescriptorsAndExactArguments(){identityExecutor();results.add(result(List.of(account())));assertEquals("Account[redacted]",store.lookup(request,"qa@example.test").orElseThrow().toString());request.setAttribute("health.tenant",new TenantRef(ID,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of()));results.add(result(List.of(Map.of("userId",ID,"status","INVITED"))));assertTrue(store.membership(request,ID));writeResult();var expiry=java.time.Instant.now();store.issue(request,HASH,ID,"VERIFY",expiry,ID,"subject","body");writeResult();store.redeem(request,HASH,"VERIFY",null);
      verify(executor).execute(eq(SqlServerProcedure.IDENTITY_MEMBERSHIP),any(),eq(ID),eq(ID),eq(false));verify(executor).execute(eq(SqlServerProcedure.IDENTITY_ISSUE),any(),eq(HASH),eq(ID),eq("VERIFY"),eq(expiry),eq(ID),eq("subject"),eq("body"),isNull());verify(executor).execute(eq(SqlServerProcedure.IDENTITY_REDEEM),any(),eq(HASH),eq("VERIFY"),isNull());assertEquals(4,calls.size());}
    @Test void lookupAndMembershipCardinalityTypesAndEmpty(){identityExecutor();results.add(result(List.of()));assertTrue(store.lookup(request,"qa@example.test").isEmpty());
      for(String key:account().keySet()){var row=account();row.remove(key);results.add(result(List.of(row)));safe(()->store.lookup(request,"qa@example.test"));}
      for(var replacement:List.of(Map.entry("id","BAD"),Map.entry("email",1),Map.entry("emailVerified",1),Map.entry("platformRole","ADM"))){var row=account();row.put(replacement.getKey(),replacement.getValue());results.add(result(List.of(row)));safe(()->store.lookup(request,"qa@example.test"));}
      results.add(result(List.of(account(),account())));safe(()->store.lookup(request,"qa@example.test"));
      request.setAttribute("health.tenant",new TenantRef(ID,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of()));results.add(result(List.of()));assertFalse(store.membership(request,ID));
      for(var row:List.<Map<String,Object>>of(Map.of(),Map.of("userId",ID,"status","INACTIVE"),Map.of("userId","other","status","ACTIVE"),Map.of("userId",ID,"status",1))){results.add(result(List.of(row)));safe(()->store.membership(request,ID));assertEquals("rollback",manager.events.getLast());}
    }
    @Test void directIdentityParametersRejectedBeforeExecutor(){identityExecutor();var expiry=java.time.Instant.now();for(String hash:Arrays.asList(null,"bad")){assertEquals(400,assertThrows(ApiException.class,()->store.issue(request,hash,ID,"VERIFY",expiry,ID,"s","b")).status);assertEquals(400,assertThrows(ApiException.class,()->store.redeem(request,hash,"VERIFY",null)).status);}
      for(String purpose:Arrays.asList(null,"OTHER")){assertEquals(400,assertThrows(ApiException.class,()->store.issue(request,HASH,ID,purpose,expiry,ID,"s","b")).status);}
      assertEquals(400,assertThrows(ApiException.class,()->store.issue(request,HASH,ID,"VERIFY",null,ID,"s","b")).status);
      assertEquals(400,assertThrows(ApiException.class,()->store.issue(request,HASH,ID,"VERIFY",expiry,ID,"x".repeat(201),"b")).status);
      assertEquals(400,assertThrows(ApiException.class,()->store.issue(request,HASH,ID,"VERIFY",expiry,ID,"s"," ")).status);
      for(String password:Arrays.asList(null,"","x".repeat(101)))assertEquals(400,assertThrows(ApiException.class,()->store.redeem(request,HASH,"RESET",password)).status);
      assertEquals(400,assertThrows(ApiException.class,()->store.redeem(request,HASH,"VERIFY","hash")).status);assertEquals(403,assertThrows(ApiException.class,()->store.membership(request,ID)).status);verifyNoInteractions(executor);
    }
    @Test void identityWritesRejectUnexpectedRsAndJoinRequired(){identityExecutor();results.add(result(List.of()));safe(()->store.redeem(request,HASH,"VERIFY",null));results.add(result(List.of()));safe(()->store.issue(request,HASH,ID,"VERIFY",java.time.Instant.now(),ID,"s","b"));
      writeResult();assertThrows(RuntimeException.class,()->store.required(()->{store.redeem(request,HASH,"RESET","encoded");throw new RuntimeException("synthetic");}));assertEquals("rollback",manager.events.getLast());
      writeResult();manager.failCommit=true;safe(()->store.redeem(request,HASH,"VERIFY",null));
    }

    @Test void registrationEmailExistsAndMandatoryWritesUseExactContracts(){identityExecutor();results.add(result(List.of()));assertFalse(store.emailExists(request,"qa@example.test"));results.add(result(List.of(Map.of("id",ID))));assertTrue(store.emailExists(request,"qa@example.test"));
      request.setAttribute("health.tenant",new TenantRef(ID,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of()));writeResult();writeResult();store.required(()->{store.pending(request,ID);store.portalRegister(request,ID);return null;});
      verify(executor).execute(eq(SqlServerProcedure.IDENTITY_PENDING),any(),eq(ID));verify(executor).execute(eq(SqlServerProcedure.PORTAL_REGISTER),any(),eq(ID));assertEquals("commit",manager.events.getLast());
    }
    @Test void mandatoryWithoutTransactionAndAuthenticatedRegistrationNeverReachExecutor(){identityExecutor();safe(()->store.pending(request,ID));safe(()->store.portalRegister(request,ID));request.setAttribute("health.actor","forged");assertEquals(403,assertThrows(ApiException.class,()->store.emailExists(request,"qa@example.test")).status);assertEquals(403,assertThrows(ApiException.class,()->store.required(()->{store.pending(request,ID);return null;})).status);verifyNoInteractions(executor);}
    @Test void registrationMalformedResultsAndParametersRollBack(){identityExecutor();for(var row:List.<Map<String,Object>>of(Map.of(),Map.of("id",1),Map.of("id","bad"))){results.add(result(List.of(row)));safe(()->store.emailExists(request,"qa@example.test"));}
      results.add(result(List.of(Map.of("id",ID),Map.of("id",ID))));safe(()->store.emailExists(request,"qa@example.test"));
      results.add(new SqlServerExecutor.Result(List.of(),List.of()));safe(()->store.emailExists(request,"qa@example.test"));
      results.add(result(List.of()));safe(()->store.required(()->{store.pending(request,ID);return null;}));
      assertEquals(403,assertThrows(ApiException.class,()->store.required(()->{store.portalRegister(request,ID);return null;})).status);
      for(String email:Arrays.asList(null," ","x".repeat(255)))assertEquals(400,assertThrows(ApiException.class,()->store.emailExists(request,email)).status);
      assertEquals(400,assertThrows(ApiException.class,()->store.required(()->{store.pending(request,"bad");return null;})).status);assertEquals("rollback",manager.events.getLast());
    }

    static final String TARGET="dd000000-0000-4000-8000-000000000001";
    SqlServerAccountLifecycleStore.RegistrationOrganization organization(){return new SqlServerAccountLifecycleStore.RegistrationOrganization("Synthetic","new-clinic","CLINIC","HUMAN",ID,"PROFILE","00000000001");}
    @Test void platformPlanExactMappingAndMissingCorruptRows(){identityExecutor();results.add(result(List.of(Map.of("id",ID,"includedBranches",1,"includedProfessionals",2,"includedSpecialties",3))));assertEquals(2,store.registrationPlan(request,ID).includedProfessionals());
      results.add(result(List.of()));assertEquals(404,assertThrows(ApiException.class,()->store.registrationPlan(request,ID)).status);
      for(var value:List.of(0,1L,"1")){results.add(result(List.of(Map.of("id",ID,"includedBranches",value,"includedProfessionals",2,"includedSpecialties",3))));safe(()->store.registrationPlan(request,ID));}
      results.add(result(List.of(Map.of("id",TARGET,"includedBranches",1,"includedProfessionals",2,"includedSpecialties",3))));safe(()->store.registrationPlan(request,ID));
    }
    @Test void platformMandatoryNoTransactionOrTenantActorNeverExecutor(){identityExecutor();var plan=new SqlServerAccountLifecycleStore.RegistrationPlan(ID,1,2,3);var created=new SqlServerAccountLifecycleStore.CreatedTenant(TARGET,"new-clinic","CLINIC","HUMAN","TRIAL");safe(()->store.createRegistrationTenant(request,TARGET,ID,ID,organization(),plan));safe(()->store.issueRegistration(request,HASH,ID,java.time.Instant.now(),ID,"s","b",created));
      request.setAttribute("health.tenant",new TenantRef(ID,"x","x","CLINIC","HUMAN","ACTIVE",List.of()));assertEquals(403,assertThrows(ApiException.class,()->store.registrationPlan(request,ID)).status);assertEquals(403,assertThrows(ApiException.class,()->store.required(()->store.createRegistrationTenant(request,TARGET,ID,ID,organization(),plan))).status);request.removeAttribute("health.tenant");request.setAttribute("health.actor","forged");assertEquals(403,assertThrows(ApiException.class,()->store.registrationPlan(request,ID)).status);verifyNoInteractions(executor);
    }
    @Test void platformCreatedResultAndRegistrationIssueRequireExactShape(){identityExecutor();var plan=new SqlServerAccountLifecycleStore.RegistrationPlan(ID,1,2,3);
      var valid=Map.<String,Object>of("id",TARGET,"tenantId",TARGET,"slug","new-clinic","kind","CLINIC","domain","HUMAN","status","TRIAL","ruc","00000000001","revision",1);
      for(String key:valid.keySet()){var invalid=new LinkedHashMap<>(valid);invalid.put(key,"wrong");results.add(result(List.of(invalid)));safe(()->store.required(()->store.createRegistrationTenant(request,TARGET,ID,ID,organization(),plan)));}
      results.add(result(List.of(valid)));writeResult();store.required(()->{var created=store.createRegistrationTenant(request,TARGET,ID,ID,organization(),plan);store.issueRegistration(request,HASH,ID,java.time.Instant.now(),ID,"subject","body",created);return null;});verify(executor).execute(eq(SqlServerProcedure.IDENTITY_ISSUE),any(),eq(HASH),eq(ID),eq("VERIFY"),any(),eq(ID),eq("subject"),eq("body"),eq(TARGET));
      results.add(result(List.of()));safe(()->store.required(()->{store.issueRegistration(request,HASH,ID,java.time.Instant.now(),ID,"s","b",new SqlServerAccountLifecycleStore.CreatedTenant(TARGET,"new-clinic","CLINIC","HUMAN","TRIAL"));return null;}));
    }

}
