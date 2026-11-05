package com.mavric.health.audit;
import java.util.*;
import java.io.IOException;
import jakarta.servlet.*;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.shared.*;
import com.mavric.health.identity.Actor;
import com.mavric.health.persistence.sqlserver.SqlServerTraceStore;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
/** Servlet doubles and real filter/Errors; no server, DNS, proxy or database. */
class TraceFilterSqlServerTest {
 final Sql sql=mock(Sql.class);final SqlServerTraceStore store=mock(SqlServerTraceStore.class);final Errors errors=new Errors(new ObjectMapper());
 final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/example");final MockHttpServletResponse response=new MockHttpServletResponse();
 TraceFilter filter(boolean legacy){return legacy?new TraceFilter(sql,errors):new TraceFilter(store,errors);}
 @AfterEach void cleanup(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}
 @Test void constructorsPreserveHeadersServerCorrelationFinalStatusAndCleanup() throws Exception {for(boolean legacy:List.of(false,true)){reset(store,sql);request.addHeader("X-Request-Id","forged");request.setAttribute("health.requestId","forged");filter(legacy).doFilter(request,response,(req,res)->{assertSame(request,TraceContext.REQUEST.get());assertFalse(TransactionSynchronizationManager.isActualTransactionActive());response.setStatus(201);});String id=(String)request.getAttribute("health.requestId");assertEquals(id,UUID.fromString(id).toString());assertEquals(id,response.getHeader("X-Request-Id"));assertEquals("no-store",response.getHeader("Cache-Control"));assertNull(TraceContext.REQUEST.get());if(legacy){verify(sql).call(eq("sp_request_finish"),any(Object[].class));verifyNoInteractions(store);}else{verify(store).finish(same(request),eq(id),eq(201),longThat(n->n>=0));verifyNoInteractions(sql);}}}
 @Test void preciseExclusionsAndStatusCodes() throws Exception {for(String path:List.of("/outside","/api/public/status","/api/public/status/")){reset(store);request.setRequestURI(path);filter(false).doFilter(request,response,(req,res)->response.setStatus(404));if(path.equals("/api/public/status/"))verify(store).finish(same(request),anyString(),eq(404),anyLong());else verifyNoInteractions(store);assertNull(TraceContext.REQUEST.get());}}
 @Test void apiExceptionIsWrittenAndFinalized403() throws Exception {filter(false).doFilter(request,response,(req,res)->{throw ApiException.forbidden();});assertEquals(403,response.getStatus());assertTrue(response.getContentAsString().contains("FORBIDDEN"));verify(store).finish(same(request),anyString(),eq(403),anyLong());assertNull(TraceContext.REQUEST.get());}
 @Test void downstreamExceptionsPropagateWith500TraceExactlyOnce() {for(Exception failure:List.of(new ServletException("synthetic"),new IOException("synthetic"),new IllegalStateException("synthetic"))){reset(store);var thrown=assertThrows(Exception.class,()->filter(false).doFilter(request,response,(req,res)->{if(failure instanceof ServletException e)throw e;if(failure instanceof IOException e)throw e;throw (RuntimeException)failure;}));assertSame(failure,thrown);verify(store).finish(same(request),anyString(),eq(500),anyLong());assertNull(TraceContext.REQUEST.get());}}
 @Test void originRulesAndFinalActorAttributes() throws Exception {request.setMethod("POST");request.setServerName("health.localhost");request.addHeader("Origin","https://health.localhost");filter(false).doFilter(request,response,(req,res)->{request.setAttribute("health.actor",new Actor("synthetic","x","qa@example.test",null,List.of("SAD"),"a".repeat(64)));SecurityContextHolder.clearContext();});verify(store).finish(same(request),anyString(),eq(200),anyLong());assertNotNull(request.getAttribute("health.actor"));reset(store);request.removeHeader("Origin");request.addHeader("Origin","https://foreign.test");filter(false).doFilter(request,response,(req,res)->fail("origin must block"));assertEquals(403,response.getStatus());verify(store).finish(same(request),anyString(),eq(403),anyLong());}
 @Test void persistenceFailureKeepsResponseAndSafeLogWithoutThrowable() throws Exception {
  var logger=(ch.qos.logback.classic.Logger)org.slf4j.LoggerFactory.getLogger(TraceFilter.class);var appender=new ch.qos.logback.core.read.ListAppender<ch.qos.logback.classic.spi.ILoggingEvent>();appender.start();logger.addAppender(appender);
  try{doThrow(new RuntimeException("canary driver token cookie body")).when(store).finish(any(),anyString(),anyInt(),anyLong());request.addHeader("Cookie","canary-cookie");request.setContent("canary-body".getBytes());filter(false).doFilter(request,response,(req,res)->{response.setStatus(201);response.getWriter().write("confirmed");});assertEquals(201,response.getStatus());assertEquals("confirmed",response.getContentAsString());assertEquals(1,appender.list.size());var event=appender.list.getFirst();assertEquals("Trace persistence unavailable for request "+request.getAttribute("health.requestId"),event.getFormattedMessage());assertNull(event.getThrowableProxy());assertFalse(event.getFormattedMessage().contains("canary"));assertNull(TraceContext.REQUEST.get());}finally{logger.detachAppender(appender);appender.stop();}
 }
 @Test void persistenceFailureDoesNotHideChainExceptionAndErrorStillCleansThreadLocal(){doThrow(new RuntimeException("canary")).when(store).finish(any(),anyString(),anyInt(),anyLong());var original=new IOException("synthetic original");assertSame(original,assertThrows(IOException.class,()->filter(false).doFilter(request,response,(req,res)->{throw original;})));assertNull(TraceContext.REQUEST.get());reset(store);var error=new AssertionError("synthetic fatal");doThrow(error).when(store).finish(any(),anyString(),anyInt(),anyLong());assertSame(error,assertThrows(AssertionError.class,()->filter(false).doFilter(request,response,(req,res)->{})));assertNull(TraceContext.REQUEST.get());}
 @Test void realStoreCommitFailureAfterChainKeepsResponseAndFinalActor() throws Exception {
  var executor=mock(com.mavric.health.persistence.sqlserver.SqlServerExecutor.class);var manager=new com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager();manager.failCommit=true;
  when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{var context=inv.<com.mavric.health.persistence.sqlserver.SqlServerContext>getArgument(1);assertEquals("aa000000-0000-4000-8000-000000000001",context.actorId());assertTrue(TransactionSynchronizationManager.isActualTransactionActive());return new com.mavric.health.persistence.sqlserver.SqlServerExecutor.Result(List.of(),List.of());});
  new TraceFilter(new SqlServerTraceStore(executor,manager),errors).doFilter(request,response,(req,res)->{assertTrue(manager.events.isEmpty());response.setStatus(201);response.getWriter().write("confirmed");request.setAttribute("health.actor",new Actor("aa000000-0000-4000-8000-000000000001","Synthetic","qa@example.test",null,List.of("SAD"),"a".repeat(64)));SecurityContextHolder.clearContext();});
  assertEquals(201,response.getStatus());assertEquals("confirmed",response.getContentAsString());assertEquals("no-store",response.getHeader("Cache-Control"));assertEquals(List.of("begin:3","commit"),manager.events);verify(executor,times(1)).execute(any(),any(),any(Object[].class));assertNull(TraceContext.REQUEST.get());
 }

}
