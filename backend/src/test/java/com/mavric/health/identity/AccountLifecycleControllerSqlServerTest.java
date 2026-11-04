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
 @Test void registrationRemainsBlockedAndCatalogUnaffected() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.Flow();var mvc=mvc(f);mvc.perform(post("/api/auth/register").contentType("application/json").content("{\"name\":\"Synthetic\",\"email\":\"qa@example.test\",\"password\":\"synthetic-only\",\"acceptTerms\":true}")).andExpect(status().isInternalServerError());assertTrue(f.calls.isEmpty());
 }
 @Test void recoveryCompleteKeepsMessageWithoutCookieOrAuthentication() throws Exception {
  var f=new AccountLifecycleServiceSqlServerTest.Flow();org.mockito.Mockito.when(f.encoder.encode("SyntheticPassword123!")).thenReturn("encoded");
  var response=mvc(f).perform(post("/api/auth/recovery/complete").contentType("application/json").content("{\"token\":\""+AccountLifecycleServiceSqlServerTest.TOKEN+"\",\"password\":\"SyntheticPassword123!\"}")).andExpect(status().isOk()).andExpect(jsonPath("$.message").value("Contrase\u00f1a actualizada. Inicia sesi\u00f3n con tu nueva contrase\u00f1a.")).andReturn().getResponse();assertNull(response.getHeader("Set-Cookie"));assertFalse(response.getContentAsString().contains(AccountLifecycleServiceSqlServerTest.TOKEN));
 }

}
