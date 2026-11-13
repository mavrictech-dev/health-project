package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.core.context.SecurityContextHolder;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import com.mavric.health.persistence.sqlserver.SqlServerAccountLifecycleStore;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
/** Real service with synthetic requests and doubles; no connected HTTP, SQL or mail. */
class AccountLifecycleServiceSqlServerTest {
 final Sql sql=mock(Sql.class);final SqlServerAccountLifecycleStore store=mock(SqlServerAccountLifecycleStore.class);
 final IdentityService identity=mock(IdentityService.class);final PasswordEncoder passwords=mock(PasswordEncoder.class);final Settings settings=mock(Settings.class);
 final AccountLifecycleService service=new AccountLifecycleService(store,identity,settings,passwords);
 static final TenantRef TENANT=new TenantRef("00000000-0000-4000-8000-000000000001","Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of());
 MockHttpServletRequest request(){var r=new MockHttpServletRequest("GET","/api/public/registration");TraceContext.REQUEST.set(r);return r;}
 @AfterEach void cleanup(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();org.springframework.transaction.support.TransactionSynchronizationManager.clear();}
 @Test void platformAndTenantShapesAndNoTenantQuery(){var r=request();var data=Map.<String,Object>of("plans",List.of(),"specialties",List.of());when(store.options(r)).thenReturn(data);assertEquals(data,service.options(null));r.setAttribute("health.tenant",TENANT);assertEquals(Map.of("portal",true),service.options(TENANT));verify(store,times(1)).options(r);verifyNoMoreInteractions(store);verifyNoInteractions(sql,identity,passwords);}
 @Test void missingOrMalformedInternalRequest500(){assertEquals(500,assertThrows(ApiException.class,()->service.options(null)).status);var r=request();r.setAttribute("health.tenant","forged");assertEquals("DATABASE_ERROR",assertThrows(ApiException.class,()->service.options(null)).code);verifyNoInteractions(store);}
 @Test void exactHostMustAgreeIncludingNullAndAllFields(){var r=request();assertEquals(403,assertThrows(ApiException.class,()->service.options(TENANT)).status);r.setAttribute("health.tenant",TENANT);assertEquals(403,assertThrows(ApiException.class,()->service.options(null)).status);var changed=new TenantRef(TENANT.id(),"Changed",TENANT.slug(),TENANT.kind(),TENANT.domain(),TENANT.status(),TENANT.modules());assertEquals(403,assertThrows(ApiException.class,()->service.options(changed)).status);verifyNoInteractions(store);}
 @Test void clientAuthorityIgnoredAndErrorsNeverFallback(){var r=request();r.addHeader("X-Tenant-Id",TENANT.id());r.addParameter("tenantId",TENANT.id());r.setContent("forged body".getBytes());var failure=new ApiException(500,"DATABASE_ERROR","Safe");when(store.options(r)).thenThrow(failure);assertSame(failure,assertThrows(ApiException.class,()->service.options(null)));verify(store,times(1)).options(r);verifyNoInteractions(sql,identity,passwords);}
 @Test void sqlRegisterStillRejectsEvenInvalidInputsBeforeAnyEffect(){for(Runnable work:List.<Runnable>of(()->service.register(null,null))){var e=assertThrows(ApiException.class,work::run);assertEquals(500,e.status);assertEquals("DATABASE_ERROR",e.code);}verifyNoInteractions(store,sql,identity,passwords,settings);}
 @Test void legacyAndRateKeepBehavior(){var legacy=new AccountLifecycleService(sql,identity,settings,passwords);when(sql.rows(anyString(),any(Object[].class))).thenReturn(List.of());assertEquals(Map.of("plans",List.of(),"specialties",List.of()),legacy.options(null));assertEquals(Map.of("portal",true),legacy.options(TENANT));verify(sql,times(2)).rows(anyString(),any(Object[].class));assertEquals(400,assertThrows(ApiException.class,()->legacy.redeem("invalid",null,null,"VERIFY")).status);when(sql.optional(anyString(),any(Object[].class))).thenReturn(Optional.empty());legacy.request("qa@example.test",null,"RESET");verify(sql).optional(anyString(),any(Object[].class));for(var target:List.of(service,legacy)){target.rate("127.0.0.1","options");assertEquals(429,assertThrows(ApiException.class,()->target.rate("127.0.0.1","options")).status);}verifyNoInteractions(store,identity,passwords);}
 @Test void minimalSpringSelectsLegacyWithoutDatasource(){try(var context=new AnnotationConfigApplicationContext()){context.registerBean(Sql.class,()->sql);context.registerBean(IdentityService.class,()->identity);context.registerBean(Settings.class,()->settings);context.registerBean(PasswordEncoder.class,()->passwords);context.registerBean(AccountLifecycleService.class);context.refresh();assertEquals(Map.of("portal",true),context.getBean(AccountLifecycleService.class).options(TENANT));assertEquals(0,context.getBeanNamesForType(SqlServerAccountLifecycleStore.class).length);assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);}}
 static final String USER="aa000000-0000-4000-8000-000000000001",TOKEN="x".repeat(43);
 static class Flow {
  final com.mavric.health.persistence.sqlserver.SqlServerExecutor executor=mock(com.mavric.health.persistence.sqlserver.SqlServerExecutor.class);
  final com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager manager=new com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager();
  final com.mavric.health.persistence.sqlserver.SqlServerAccountLifecycleStore gateway=new com.mavric.health.persistence.sqlserver.SqlServerAccountLifecycleStore(executor,manager);
  final PasswordEncoder encoder=mock(PasswordEncoder.class);
  final IdentityService identities=mock(IdentityService.class);
  final AccountLifecycleService service=new AccountLifecycleService(gateway,identities,new Settings("health.localhost","https://health.localhost",8,null),encoder);
  final List<com.mavric.health.persistence.sqlserver.SqlServerProcedure> calls=new ArrayList<>();final List<List<Object>> args=new ArrayList<>();
  boolean found=true,verified=true,member=true;String role="SAD",status="ACTIVE";RuntimeException issueFailure;
  Flow(){when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
   assertTrue(org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive());
   var sp=inv.<com.mavric.health.persistence.sqlserver.SqlServerProcedure>getArgument(0);var c=inv.<com.mavric.health.persistence.sqlserver.SqlServerContext>getArgument(1);
   assertEquals(com.mavric.health.persistence.sqlserver.SqlServerContext.Scope.IDENTITY,c.scope());calls.add(sp);args.add(Arrays.asList(((Object[])inv.getRawArguments()[2]).clone()));
   if(sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE && issueFailure!=null)throw issueFailure;
   List<Map<String,Object>> rows=List.of();
   if(sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ACCOUNT_LOOKUP && found){var row=new LinkedHashMap<String,Object>();row.put("id",USER);row.put("email","qa@example.test");row.put("emailVerified",verified);row.put("platformRole",role);rows=List.of(row);}
   if(sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_MEMBERSHIP && member) rows=List.of(Map.of("userId",USER,"status",status));
   boolean write=sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE || sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_REDEEM;
   return new com.mavric.health.persistence.sqlserver.SqlServerExecutor.Result(write?List.of():List.of(rows),List.of(0));
  });}
 }
 @Test void eligibleRequestsUseOneTransactionAndServerLinksHashExpiryWithoutPublishingActor(){
  for(String purpose:List.of("VERIFY","RESET"))for(boolean tenant:List.of(false,true)) {
   Flow f=new Flow();var r=request();if(tenant)r.setAttribute("health.tenant",TENANT);f.role=tenant?null:"SOP";f.status="INVITED";
   var before=java.time.Instant.now();f.service.request(" QA@EXAMPLE.TEST ",tenant?TENANT:null,purpose);var after=java.time.Instant.now();
   assertEquals(List.of("qa@example.test"),f.args.getFirst());var issued=f.args.getLast();assertEquals(8,issued.size());assertEquals(USER,issued.get(1));assertEquals(purpose,issued.get(2));assertNull(issued.get(7));
   String body=(String)issued.get(6);String token=body.substring(body.indexOf("#token=")+7).split("\\s")[0];assertTrue(token.matches("[A-Za-z0-9_-]{43}"));assertEquals(Checks.hash(token),issued.getFirst());
   assertTrue(body.contains((tenant?"https://clinic.health.localhost":"https://health.localhost")+(purpose.equals("RESET")?"/restablecer/":"/verificar/")+"#token="));assertFalse(body.contains("?token="));
   long ttl=purpose.equals("RESET")?1800:86400;var expiry=(java.time.Instant)issued.get(3);assertTrue(expiry.isAfter(before.plusSeconds(ttl-1)));assertTrue(expiry.isBefore(after.plusSeconds(ttl+1)));assertEquals(0,expiry.getNano()%1000);assertEquals(issued.get(4),Checks.id((String)issued.get(4)));
   if(tenant)assertEquals(Arrays.asList(USER,TENANT.id(),false),f.args.get(1));assertEquals(List.of("begin:0","commit"),f.manager.events);assertNull(r.getAttribute("health.actor"));verifyNoInteractions(f.encoder,f.identities);
  }
 }
 @Test void ineligibleRequestsReturnNormallyWithoutIssuingOrSecrets(){
  for(int mode=0;mode<5;mode++){Flow f=new Flow();var r=request();TenantRef host=null;
   switch(mode){case 0->f.found=false;case 1->f.role=null;case 2->{host=TENANT;r.setAttribute("health.tenant",host);f.member=false;}case 3->f.verified=false;case 4->{host=TENANT;r.setAttribute("health.tenant",host);f.verified=false;}}
   f.service.request("qa@example.test",host,"RESET");assertFalse(f.calls.contains(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE));verifyNoInteractions(f.encoder,f.identities);
  }
 }
 @Test void verifyAlreadyVerifiedStillIssuesAndReplayOrInfrastructureRemainErrors(){Flow f=new Flow();request();f.service.request("qa@example.test",null,"VERIFY");assertEquals(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE,f.calls.getLast());f.issueFailure=new ApiException(409,"CONFLICT","Safe");assertEquals(409,assertThrows(ApiException.class,()->f.service.request("qa@example.test",null,"VERIFY")).status);assertEquals("rollback",f.manager.events.getLast());f.manager.failCommit=true;f.issueFailure=null;assertEquals(500,assertThrows(ApiException.class,()->f.service.request("qa@example.test",null,"VERIFY")).status);}
 @Test void redeemHashesTokenAndEncodesOnlyResetWithoutSession(){Flow f=new Flow();var r=request();f.service.redeem(TOKEN,null,null,"VERIFY");assertEquals(Arrays.asList(Checks.hash(TOKEN),"VERIFY",null),f.args.getLast());verifyNoInteractions(f.encoder);when(f.encoder.encode("ValidPassword123!")).thenReturn("encoded");f.service.redeem(TOKEN,"ValidPassword123!",null,"RESET");assertEquals(List.of(Checks.hash(TOKEN),"RESET","encoded"),f.args.getLast());assertEquals(List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_REDEEM,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_REDEEM),f.calls);assertNull(r.getAttribute("health.actor"));}
 @Test void invalidInputsAndHostNeverExecute(){Flow f=new Flow();request();for(String purpose:Arrays.asList(null,"","verify","OTHER")){assertEquals(400,assertThrows(ApiException.class,()->f.service.request("qa@example.test",null,purpose)).status);assertEquals(400,assertThrows(ApiException.class,()->f.service.redeem(TOKEN,null,null,purpose)).status);}for(String email:Arrays.asList(null," ","x".repeat(255)))assertEquals(400,assertThrows(ApiException.class,()->f.service.request(email,null,"VERIFY")).status);assertEquals(400,assertThrows(ApiException.class,()->f.service.redeem("bad",null,null,"VERIFY")).status);assertEquals(400,assertThrows(ApiException.class,()->f.service.redeem(TOKEN,"short",null,"RESET")).status);assertEquals(403,assertThrows(ApiException.class,()->f.service.request("qa@example.test",TENANT,"VERIFY")).status);verifyNoInteractions(f.executor,f.encoder);}

 @Test void tenantActiveAndInvitedBothEligibleAndNewLinksUseDistinctSecrets(){
  Flow f=new Flow();var r=request();r.setAttribute("health.tenant",TENANT);f.role=null;
  f.service.request("qa@example.test",TENANT,"VERIFY");var first=f.args.getLast();f.status="INVITED";f.service.request("qa@example.test",TENANT,"VERIFY");var second=f.args.getLast();
  assertNotEquals(first.get(0),second.get(0));assertNotEquals(first.get(4),second.get(4));
  assertEquals(403,assertThrows(ApiException.class,()->f.service.redeem(TOKEN,null,null,"VERIFY")).status);
 }
 @Test void redeemSpInvalidAndInfrastructureArePreservedWithoutRetry(){
  Flow f=new Flow();request();reset(f.executor);
  for(int code:new int[]{51000,51001,51002,51003,229}) {
   doThrow(new RuntimeException(new java.sql.SQLException("private driver data",null,code))).when(f.executor).execute(any(),any(),any(Object[].class));
   var error=assertThrows(ApiException.class,()->f.service.redeem(TOKEN,null,null,"VERIFY"));assertEquals(code==51000?400:code==51001?403:code==51002?404:code==51003?409:500,error.status);assertFalse(error.toString().contains("private"));
  }
  verify(f.executor,times(5)).execute(any(),any(),any(Object[].class));
 }

 static RegisterHolder portalInput(){return new RegisterHolder();}
 static class RegisterHolder {
  final AccountLifecycleService.Register input=new AccountLifecycleService.Register(" Portal Synthetic "," QA@EXAMPLE.TEST ","SyntheticPassword123!","DOCTOR","ANIMAL","Ignored","ignored","ignored","ignored",true);
 }
 static class PortalFlow extends Flow {
  final IdentityService realIdentity=new IdentityService(new com.mavric.health.persistence.sqlserver.SqlServerIdentityStore(executor,manager),mock(Access.class),encoder,new Settings("health.localhost","https://health.localhost",8,null));
  final AccountLifecycleService portal=new AccountLifecycleService(gateway,realIdentity,new Settings("health.localhost","https://health.localhost",8,null),encoder);
  boolean duplicate;com.mavric.health.persistence.sqlserver.SqlServerProcedure failure;String created;
  PortalFlow(){reset(executor);when(encoder.encode("SyntheticPassword123!")).thenReturn("encoded");
   when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
    assertTrue(org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive());
    var sp=inv.<com.mavric.health.persistence.sqlserver.SqlServerProcedure>getArgument(0);var context=inv.<com.mavric.health.persistence.sqlserver.SqlServerContext>getArgument(1);
    assertEquals(com.mavric.health.persistence.sqlserver.SqlServerContext.Scope.IDENTITY,context.scope());assertNull(context.actorId());assertNull(context.tokenHash());assertEquals(TENANT.id(),context.tenantId());
    calls.add(sp);var values=Arrays.asList(((Object[])inv.getRawArguments()[2]).clone());args.add(values);
    if(sp==failure)throw new ApiException(409,"CONFLICT","Safe");
    if(sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.USER_CREATE)created=(String)values.getFirst();
    var rows=duplicate?List.<Map<String,Object>>of(Map.of("id",USER)):List.<Map<String,Object>>of();
    return new com.mavric.health.persistence.sqlserver.SqlServerExecutor.Result(sp==com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_EMAIL_EXISTS?List.of(rows):List.of(),List.of(0));
   });
  }
 }
 @Test void tenantPortalRegistrationUsesRealIdentityMandatoryAndSingleUnit(){
  PortalFlow f=new PortalFlow();var r=request();r.setAttribute("health.tenant",TENANT);
  org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(new org.springframework.security.authentication.AnonymousAuthenticationToken("synthetic","anonymousUser",List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_ANONYMOUS"))));
  f.portal.register(portalInput().input,TENANT);
  assertEquals(List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_EMAIL_EXISTS,com.mavric.health.persistence.sqlserver.SqlServerProcedure.USER_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_PENDING,com.mavric.health.persistence.sqlserver.SqlServerProcedure.PORTAL_REGISTER,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE),f.calls);
  assertEquals(List.of("qa@example.test"),f.args.getFirst());assertEquals(Arrays.asList(f.created,"Portal Synthetic","qa@example.test","encoded",null,null),f.args.get(1));assertEquals(List.of(f.created),f.args.get(2));assertEquals(List.of(f.created),f.args.get(3));assertEquals(f.created,f.args.getLast().get(1));assertNull(f.args.getLast().get(7));assertTrue(((String)f.args.getLast().get(6)).contains("https://clinic.health.localhost/verificar/#token="));
  assertEquals(List.of("begin:0","commit"),f.manager.events);assertNull(r.getAttribute("health.actor"));assertSame(TENANT,r.getAttribute("health.tenant"));verifyNoInteractions(f.identities);
 }
 @Test void duplicateIncludingInactiveNeverCreatesOrEncodes(){PortalFlow f=new PortalFlow();f.duplicate=true;var r=request();r.setAttribute("health.tenant",TENANT);f.portal.register(portalInput().input,TENANT);assertEquals(List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_EMAIL_EXISTS),f.calls);verify(f.encoder,never()).encode(anyString());}
 @Test void registrationRejectsInvalidInputsHostAndActorBeforeAnySp(){PortalFlow f=new PortalFlow();var r=request();r.setAttribute("health.tenant",TENANT);
  assertEquals(400,assertThrows(ApiException.class,()->f.portal.register(null,TENANT)).status);
  for(int mode=0;mode<6;mode++){var p=new AccountLifecycleService.Register(mode==0?null:mode==1?" ":"Synthetic",mode==2?null:mode==3?"x".repeat(255):"qa@example.test",mode==4?"short":"SyntheticPassword123!",null,null,null,null,null,null,mode!=5);assertEquals(400,assertThrows(ApiException.class,()->f.portal.register(p,TENANT)).status);}
  r.setAttribute("health.actor","forged");assertEquals(403,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,TENANT)).status);r.removeAttribute("health.actor");
  var actor=new Actor(USER,"Synthetic","qa@example.test",TENANT.id(),List.of("ADM"),"a".repeat(64));org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(actor,null,List.of()));
  assertEquals(403,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,TENANT)).status);org.springframework.security.core.context.SecurityContextHolder.clearContext();
  assertEquals(403,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,null)).status);verifyNoInteractions(f.executor);verify(f.encoder,never()).encode(anyString());
 }
 @Test void everyRegistrationStageErrorAndCommitFailureNeverPublishesIdentity(){for(var stage:List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.USER_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_PENDING,com.mavric.health.persistence.sqlserver.SqlServerProcedure.PORTAL_REGISTER,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE)){PortalFlow f=new PortalFlow();var r=request();r.setAttribute("health.tenant",TENANT);f.failure=stage;assertEquals(409,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,TENANT)).status);assertEquals(stage,f.calls.getLast());assertEquals("rollback",f.manager.events.getLast());assertNull(r.getAttribute("health.actor"));}
  PortalFlow f=new PortalFlow();var r=request();r.setAttribute("health.tenant",TENANT);f.manager.failCommit=true;assertEquals(500,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,TENANT)).status);assertNull(r.getAttribute("health.actor"));
 }
 @Test void outerRequiredCanRollBackWholeRegistrationAndLegacyIdentityNeverFallsBack(){PortalFlow f=new PortalFlow();var r=request();r.setAttribute("health.tenant",TENANT);assertThrows(RuntimeException.class,()->f.manager.outer(()->{f.portal.register(portalInput().input,TENANT);assertFalse(f.manager.events.contains("commit"));throw new RuntimeException("synthetic cancellation");}));assertEquals("rollback",f.manager.events.getLast());
  var legacyIdentity=new IdentityService(mock(Sql.class),mock(Access.class),mock(PasswordEncoder.class),new Settings("health.localhost","https://health.localhost",8,null),mock(AttemptRecorder.class));
  var mixed=new AccountLifecycleService(f.gateway,legacyIdentity,new Settings("health.localhost","https://health.localhost",8,null),f.encoder);assertEquals(500,assertThrows(ApiException.class,()->mixed.register(portalInput().input,TENANT)).status);
 }

 @Test void animalTenantUsesSamePortalSpWithoutDomainFromFormAndHostMustMatch(){PortalFlow f=new PortalFlow();var r=request();var animal=new TenantRef(TENANT.id(),"Synthetic animal","clinic","VETERINARY","ANIMAL","ACTIVE",List.of());r.setAttribute("health.tenant",animal);assertEquals(403,assertThrows(ApiException.class,()->f.portal.register(portalInput().input,TENANT)).status);assertTrue(f.calls.isEmpty());f.portal.register(portalInput().input,animal);assertNull(f.args.get(1).get(4));assertNull(f.args.get(1).get(5));assertEquals(com.mavric.health.persistence.sqlserver.SqlServerProcedure.PORTAL_REGISTER,f.calls.get(3));}

 static final String PLAN="cc000000-0000-4000-8000-000000000001";
 static AccountLifecycleService.Register platformInput(String kind,String domain){return new AccountLifecycleService.Register(" Synthetic "," QA@EXAMPLE.TEST ","SyntheticPassword123!",kind,domain,"Cl\u00ednica \u4e2d\ud83e\uddb7","new-clinic",PLAN,"PROFILE",true,"00000000001");}
 static class PlatformFlow extends Flow {
  final IdentityService realIdentity=new IdentityService(new com.mavric.health.persistence.sqlserver.SqlServerIdentityStore(executor,manager),mock(Access.class),encoder,new Settings("health.localhost","https://health.localhost",8,null));
  final AccountLifecycleService platform=new AccountLifecycleService(gateway,realIdentity,new Settings("health.localhost","https://health.localhost",8,null),encoder);
  boolean duplicate,missingPlan,badPlan,badCreated;com.mavric.health.persistence.sqlserver.SqlServerProcedure failure;
  final int offeredProfessionals;
  RuntimeException tenantCreationFailure;
  PlatformFlow(){this(4);}
  PlatformFlow(int offeredProfessionals){this.offeredProfessionals=offeredProfessionals;reset(executor);when(encoder.encode("SyntheticPassword123!")).thenReturn("encoded");when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
   assertTrue(org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive());var sp=inv.<com.mavric.health.persistence.sqlserver.SqlServerProcedure>getArgument(0);var c=inv.<com.mavric.health.persistence.sqlserver.SqlServerContext>getArgument(1);assertEquals(com.mavric.health.persistence.sqlserver.SqlServerContext.Scope.IDENTITY,c.scope());assertNull(c.actorId());assertNull(c.tenantId());assertNull(c.tokenHash());calls.add(sp);var values=Arrays.asList(((Object[])inv.getRawArguments()[2]).clone());args.add(values);if(sp==failure)throw new ApiException(409,"CONFLICT","Safe");
   List<Map<String,Object>> rows=List.of();boolean read=false;
   switch(sp){case IDENTITY_EMAIL_EXISTS->{read=true;if(duplicate)rows=List.of(Map.of("id",USER));}
    case REGISTRATION_PLAN->{read=true;if(!missingPlan)rows=List.of(Map.of("id",PLAN,"includedBranches",badPlan?0:2,"includedProfessionals",offeredProfessionals,"includedSpecialties",3));}
    case SAAS_TENANT_CREATE->{read=true;if(tenantCreationFailure!=null)throw tenantCreationFailure;var json=new tools.jackson.databind.ObjectMapper().readTree((String)values.get(3));rows=List.of(Map.of("id",values.get(0),"tenantId",values.get(0),"slug",badCreated?"wrong":json.get("slug").asText(),"kind",json.get("kind").asText(),"domain",json.get("domain").asText(),"status","TRIAL","ruc","00000000001","revision",1));}
    default->{}
   }
   return new com.mavric.health.persistence.sqlserver.SqlServerExecutor.Result(read?List.of(rows):List.of(),List.of(0));
  });}
 }
 @Test void platformSixSpTransactionJsonServerQuotasAndRegistrationLink(){
  for(var types:List.of(List.of("DOCTOR","HUMAN"),List.of("DOCTOR","ANIMAL"),List.of("CLINIC","HUMAN"),List.of("VETERINARY","ANIMAL"))){var f=new PlatformFlow(types.get(0).equals("DOCTOR")?1:4);var r=request();f.platform.register(platformInput(types.get(0),types.get(1)),null);
   assertEquals(List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_EMAIL_EXISTS,com.mavric.health.persistence.sqlserver.SqlServerProcedure.REGISTRATION_PLAN,com.mavric.health.persistence.sqlserver.SqlServerProcedure.USER_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_PENDING,com.mavric.health.persistence.sqlserver.SqlServerProcedure.SAAS_TENANT_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE),f.calls);
   var create=f.args.get(2);assertEquals(types.get(0).equals("DOCTOR")?types.get(1):null,create.get(4));assertNull(create.get(5));var tenant=f.args.get(4);assertEquals(create.get(0),tenant.get(2));assertNotEquals(tenant.get(0),tenant.get(1));
   var json=new tools.jackson.databind.ObjectMapper().readTree((String)tenant.get(3));assertEquals(10,json.size());assertEquals(5,json.get("subscription").size());assertEquals(2,json.at("/subscription/branchQuota").asInt());assertEquals(f.offeredProfessionals,json.at("/subscription/professionalQuota").asInt());assertEquals(3,json.at("/subscription/specialtyQuota").asInt());assertEquals("MONTHLY",json.at("/subscription/cycle").asText());assertEquals("America/Lima",json.get("timezone").asText());assertEquals(platformInput(types.get(0),types.get(1)).organizationName(),json.get("name").asText());assertFalse(json.has("owner"));assertFalse(json.has("password"));
   var issued=f.args.getLast();assertEquals(tenant.get(0),issued.get(7));assertEquals("VERIFY",issued.get(2));assertTrue(((String)issued.get(6)).contains("https://new-clinic.health.localhost/verificar/#token="));assertEquals(0,((java.time.Instant)issued.get(3)).getNano()%1000);assertEquals(List.of("begin:0","commit"),f.manager.events);assertNull(r.getAttribute("health.tenant"));assertNull(r.getAttribute("health.actor"));
  }
 }
 @Test void platformDuplicateAndInvalidFormNeverCreate(){var f=new PlatformFlow();request();f.duplicate=true;f.platform.register(platformInput("CLINIC","HUMAN"),null);assertEquals(List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_EMAIL_EXISTS),f.calls);verify(f.encoder,never()).encode(anyString());
  for(boolean duplicate:List.of(false,true)){f=new PlatformFlow();f.duplicate=duplicate;final var fixture=f;for(var p:List.of(portalInput().input,platformInput("CLINIC","ANIMAL"),platformInput("VETERINARY","HUMAN"),platformInput("OTHER","HUMAN"))){assertEquals(400,assertThrows(ApiException.class,()->fixture.platform.register(p,null)).status);}assertTrue(f.calls.isEmpty());}
 }
 @Test void platformPlanAndCreatedMalformedAbortAndEveryStageErrorRollsBack(){for(int mode=0;mode<3;mode++){var f=new PlatformFlow();request();f.missingPlan=mode==0;f.badPlan=mode==1;f.badCreated=mode==2;assertEquals(mode==0?404:500,assertThrows(ApiException.class,()->f.platform.register(platformInput("CLINIC","HUMAN"),null)).status);assertEquals("rollback",f.manager.events.getLast());assertFalse(f.calls.contains(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE));}
  for(var stage:List.of(com.mavric.health.persistence.sqlserver.SqlServerProcedure.REGISTRATION_PLAN,com.mavric.health.persistence.sqlserver.SqlServerProcedure.USER_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_PENDING,com.mavric.health.persistence.sqlserver.SqlServerProcedure.SAAS_TENANT_CREATE,com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE)){var f=new PlatformFlow();request();f.failure=stage;assertEquals(409,assertThrows(ApiException.class,()->f.platform.register(platformInput("CLINIC","HUMAN"),null)).status);assertEquals(stage,f.calls.getLast());assertEquals("rollback",f.manager.events.getLast());}
 }
 @Test void platformCommitAndOuterCancellationNeverPublishContext(){var f=new PlatformFlow(1);var r=request();f.manager.failCommit=true;assertEquals(500,assertThrows(ApiException.class,()->f.platform.register(platformInput("DOCTOR","HUMAN"),null)).status);assertEquals(f.offeredProfessionals,new tools.jackson.databind.ObjectMapper().readTree((String)f.args.get(4).get(3)).at("/subscription/professionalQuota").asInt());assertNull(r.getAttribute("health.actor"));var outer=new PlatformFlow();assertThrows(RuntimeException.class,()->outer.manager.outer(()->{outer.platform.register(platformInput("CLINIC","HUMAN"),null);assertEquals(outer.offeredProfessionals,new tools.jackson.databind.ObjectMapper().readTree((String)outer.args.get(4).get(3)).at("/subscription/professionalQuota").asInt());assertFalse(outer.manager.events.contains("commit"));throw new RuntimeException("synthetic cancellation");}));assertEquals("rollback",outer.manager.events.getLast());}

 /** Injected V4:174 incompatibility, not a SQL engine or plan-validation simulation. */
 @Test void doctorSelectingClinicOnlyOfferKeepsFourAndPropagatesInjected51000(){
  var f=new PlatformFlow(4);var r=request();
  f.tenantCreationFailure=new RuntimeException(new java.sql.SQLException("HP_INVALID:Plan incompatible",null,51000));
  var error=assertThrows(ApiException.class,()->f.platform.register(platformInput("DOCTOR","HUMAN"),null));
  assertEquals(400,error.status);assertEquals("INVALID",error.code);assertNull(error.getCause());assertFalse(error.getMessage().contains("Plan incompatible"));
  assertEquals(com.mavric.health.persistence.sqlserver.SqlServerProcedure.SAAS_TENANT_CREATE,f.calls.getLast());
  var json=new tools.jackson.databind.ObjectMapper().readTree((String)f.args.getLast().get(3));
  assertEquals("DOCTOR",json.get("kind").asText());assertEquals(4,f.offeredProfessionals);assertEquals(f.offeredProfessionals,json.at("/subscription/professionalQuota").asInt());
  assertFalse(f.calls.contains(com.mavric.health.persistence.sqlserver.SqlServerProcedure.IDENTITY_ISSUE));assertFalse(f.manager.events.contains("commit"));assertEquals("rollback",f.manager.events.getLast());assertNull(r.getAttribute("health.actor"));
 }

}
