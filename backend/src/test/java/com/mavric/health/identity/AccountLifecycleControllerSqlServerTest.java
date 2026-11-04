package com.mavric.health.identity;
import org.junit.jupiter.api.*;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.mock.web.MockHttpServletRequest;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.shared.*;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
/** Standalone controller and real service/store, executor and transaction doubles. No server or SMTP. */
class AccountLifecycleControllerSqlServerTest {
 @AfterEach void cleanup(){TraceContext.REQUEST.remove();org.springframework.security.core.context.SecurityContextHolder.clearContext();org.springframework.transaction.support.TransactionSynchronizationManager.clear();}
 MockMvc mvc(AccountLifecycleServiceSqlServerTest.Flow f){TraceContext.REQUEST.set(new MockHttpServletRequest("POST","/api/auth/verify/request"));return MockMvcBuilders.standaloneSetup(new AccountLifecycleController(f.service)).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).build();}
 @Test void requestResponsesDoNotExposeEligibilityOrToken() throws Exception {
  for(String purpose:new String[]{"verify","recovery"}) {String expected=null;for(boolean eligible:new boolean[]{true,false}){var f=new AccountLifecycleServiceSqlServerTest.Flow();f.found=eligible;var response=mvc(f).perform(post("/api/auth/"+purpose+"/request").contentType("application/json").content("{\"email\":\"qa@example.test\"}")).andExpect(status().isOk()).andReturn().getResponse().getContentAsString();if(expected==null)expected=response;else assertEquals(expected,response);assertFalse(response.contains("token"));assertFalse(response.contains("qa@example.test"));}}
 }
 @Test void completeUsesExistingResponsesAndPreservesSafeErrors() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.Flow();var mvc=mvc(f);mvc.perform(post("/api/auth/verify/complete").contentType("application/json").content("{\"token\":\""+AccountLifecycleServiceSqlServerTest.TOKEN+"\"}")).andExpect(status().isOk()).andExpect(jsonPath("$.message").exists());
  mvc.perform(post("/api/auth/verify/complete").contentType("application/json").content("{\"token\":\"bad\"}")).andExpect(status().isBadRequest());
  f.issueFailure=new ApiException(500,"DATABASE_ERROR","Safe");mvc.perform(post("/api/auth/verify/request").contentType("application/json").content("{\"email\":\"qa@example.test\"}")).andExpect(status().isInternalServerError()).andExpect(jsonPath("$.title").value("DATABASE_ERROR"));
 }
 @Test void platformRegistrationRequiresOrganizationBeforeAnySp() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.Flow();var mvc=mvc(f);mvc.perform(post("/api/auth/register").contentType("application/json").content("{\"name\":\"Synthetic\",\"email\":\"qa@example.test\",\"password\":\"synthetic-only\",\"acceptTerms\":true}")).andExpect(status().isBadRequest());assertTrue(f.calls.isEmpty());
 }
 @Test void recoveryCompleteKeepsMessageWithoutCookieOrAuthentication() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.Flow();org.mockito.Mockito.when(f.encoder.encode("SyntheticPassword123!")).thenReturn("encoded");
  var response=mvc(f).perform(post("/api/auth/recovery/complete").contentType("application/json").content("{\"token\":\""+AccountLifecycleServiceSqlServerTest.TOKEN+"\",\"password\":\"SyntheticPassword123!\"}")).andExpect(status().isOk()).andExpect(jsonPath("$.message").value("Contrase\u00f1a actualizada. Inicia sesi\u00f3n con tu nueva contrase\u00f1a.")).andReturn().getResponse();assertNull(response.getHeader("Set-Cookie"));assertFalse(response.getContentAsString().contains(AccountLifecycleServiceSqlServerTest.TOKEN));
 }

 MockMvc portalMvc(AccountLifecycleServiceSqlServerTest.PortalFlow f){return MockMvcBuilders.standaloneSetup(new AccountLifecycleController(f.portal)).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).addFilters((jakarta.servlet.Filter)(req,res,chain)->{var request=(jakarta.servlet.http.HttpServletRequest)req;request.setAttribute("health.tenant",AccountLifecycleServiceSqlServerTest.TENANT);TraceContext.REQUEST.set(request);try{chain.doFilter(req,res);}finally{TraceContext.REQUEST.remove();}}).build();}
 static final String REGISTER="{\"name\":\"Synthetic\",\"email\":\"qa@example.test\",\"password\":\"SyntheticPassword123!\",\"acceptTerms\":true}";
 @Test void tenantRegisterAndDuplicateReturnSame202WithoutSecretsOrCookie() throws Exception {
  String expected=null;for(boolean duplicate:new boolean[]{false,true}){var f=new AccountLifecycleServiceSqlServerTest.PortalFlow();f.duplicate=duplicate;var response=portalMvc(f).perform(post("/api/auth/register").contentType("application/json").content(REGISTER)).andExpect(status().isAccepted()).andReturn().getResponse();String body=response.getContentAsString();if(expected==null)expected=body;else assertEquals(expected,body);assertFalse(body.contains("token"));assertFalse(body.contains("qa@example.test"));assertNull(response.getHeader("Set-Cookie"));assertNull(TraceContext.REQUEST.get());}
 }
 @Test void tenantRegistrationStageErrorIs409NotAcceptedAndBadTerms400() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.PortalFlow();f.failure=com.mavric.health.persistence.sqlserver.SqlServerProcedure.PORTAL_REGISTER;portalMvc(f).perform(post("/api/auth/register").contentType("application/json").content(REGISTER)).andExpect(status().isConflict()).andExpect(jsonPath("$.title").value("CONFLICT"));
  f=new AccountLifecycleServiceSqlServerTest.PortalFlow();portalMvc(f).perform(post("/api/auth/register").contentType("application/json").content(REGISTER.replace("true","false"))).andExpect(status().isBadRequest());assertTrue(f.calls.isEmpty());
 }

 @Test void tenantRegisterActor403AndCommitFailure500NeverReturnCookie() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.PortalFlow();portalMvc(f).perform(post("/api/auth/register").requestAttr("health.actor","forged").contentType("application/json").content(REGISTER)).andExpect(status().isForbidden()).andExpect(header().doesNotExist("Set-Cookie"));assertTrue(f.calls.isEmpty());
  f=new AccountLifecycleServiceSqlServerTest.PortalFlow();f.manager.failCommit=true;portalMvc(f).perform(post("/api/auth/register").contentType("application/json").content(REGISTER)).andExpect(status().isInternalServerError()).andExpect(jsonPath("$.title").value("DATABASE_ERROR")).andExpect(header().doesNotExist("Set-Cookie"));
 }

 MockMvc platformMvc(AccountLifecycleServiceSqlServerTest.PlatformFlow f){return MockMvcBuilders.standaloneSetup(new AccountLifecycleController(f.platform)).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).addFilters((jakarta.servlet.Filter)(req,res,chain)->{TraceContext.REQUEST.set((jakarta.servlet.http.HttpServletRequest)req);try{chain.doFilter(req,res);}finally{TraceContext.REQUEST.remove();}}).build();}
 String organizationBody(){var p=AccountLifecycleServiceSqlServerTest.platformInput("CLINIC","HUMAN");return new ObjectMapper().writeValueAsString(new AccountLifecycleService.Register(p.name(),p.email().trim(),p.password(),p.kind(),p.domain(),p.organizationName(),p.slug(),p.planId(),p.specialtyCode(),p.acceptTerms()));}
 @Test void platformRegistrationAndDuplicate202NoSecretsCookieOrHostMutation() throws Exception {String expected=null;for(boolean duplicate:new boolean[]{false,true}){var f=new AccountLifecycleServiceSqlServerTest.PlatformFlow();f.duplicate=duplicate;var response=platformMvc(f).perform(post("/api/auth/register").contentType("application/json").content(organizationBody())).andExpect(status().isAccepted()).andExpect(header().doesNotExist("Set-Cookie")).andReturn().getResponse();if(expected==null)expected=response.getContentAsString();else assertEquals(expected,response.getContentAsString());assertFalse(response.getContentAsString().contains("token"));assertNull(TraceContext.REQUEST.get());}}
 @Test void platformRegisterPreserves400403404409500() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.PlatformFlow();platformMvc(f).perform(post("/api/auth/register").contentType("application/json").content(REGISTER)).andExpect(status().isBadRequest());assertTrue(f.calls.isEmpty());
  f=new AccountLifecycleServiceSqlServerTest.PlatformFlow();platformMvc(f).perform(post("/api/auth/register").requestAttr("health.actor","forged").contentType("application/json").content(organizationBody())).andExpect(status().isForbidden());assertTrue(f.calls.isEmpty());
  for(int mode=0;mode<3;mode++){f=new AccountLifecycleServiceSqlServerTest.PlatformFlow();f.missingPlan=mode==0;f.failure=mode==1?com.mavric.health.persistence.sqlserver.SqlServerProcedure.SAAS_TENANT_CREATE:null;f.manager.failCommit=mode==2;platformMvc(f).perform(post("/api/auth/register").contentType("application/json").content(organizationBody())).andExpect(status().is(mode==0?404:mode==1?409:500)).andExpect(header().doesNotExist("Set-Cookie"));}
 }

}
