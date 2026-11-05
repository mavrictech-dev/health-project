package com.mavric.health.monitor;

import java.util.*;
import java.lang.reflect.Modifier;
import org.junit.jupiter.api.*;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import org.springframework.boot.health.contributor.Status;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.Actor;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

/** Offline explicit indicator/store integration; no health endpoint, driver, pool or server. */
class SqlServerDatabaseHealthIndicatorTest {
    final SqlServerExecutor executor=mock(SqlServerExecutor.class);
    final ModelTransactionManager manager=new ModelTransactionManager();
    final SqlServerMonitorStore store=new SqlServerMonitorStore(executor,manager);
    final SqlServerDatabaseHealthIndicator indicator=new SqlServerDatabaseHealthIndicator(store);

    void ready(){when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{
        assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
        assertEquals(SqlServerProcedure.HEALTH_READY,inv.getArgument(0));
        assertEquals(new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.WORKER),inv.getArgument(1));
        assertEquals(0,((Object[])inv.getRawArguments()[2]).length);
        return new SqlServerExecutor.Result(List.of(List.of(Map.of("ready",1))),List.of());
    });}
    static void health(Health health,Status status){assertEquals(status,health.getStatus());assertTrue(health.getDetails().isEmpty());assertFalse(health.toString().contains("canary"));}
    @AfterEach void clean(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}

    @Test void upOnlyAfterOneSuccessfulReadyAndCommit(){ready();health(indicator.health(),Status.UP);assertEquals(List.of("begin:0","commit"),manager.events);verify(executor,times(1)).execute(eq(SqlServerProcedure.HEALTH_READY),any(),any(Object[].class));verifyNoMoreInteractions(executor);}
    @Test void malformedResultIsDownWithoutDetailsAndNoRetry(){var malformed=List.of(new SqlServerExecutor.Result(List.of(),List.of()),new SqlServerExecutor.Result(List.of(List.of(Map.of("ready",0))),List.of()),new SqlServerExecutor.Result(List.of(List.of(Map.of("ready","1"))),List.of()));for(var result:malformed){reset(executor);when(executor.execute(any(),any(),any(Object[].class))).thenReturn(result);health(assertDoesNotThrow(()->{return indicator.health();}),Status.DOWN);assertEquals("rollback",manager.events.getLast());verify(executor,times(1)).execute(eq(SqlServerProcedure.HEALTH_READY),any(),any(Object[].class));verifyNoMoreInteractions(executor);}reset(executor);when(executor.execute(any(),any(),any(Object[].class))).thenReturn(null);health(indicator.health(),Status.DOWN);}
    @Test void driverAndRuntimeFailuresReturnDownWithoutExceptionData(){for(RuntimeException failure:List.of(new RuntimeException(new java.sql.SQLException("driver password token private-canary",null,229)),new IllegalStateException("private-canary"))){reset(executor);doThrow(failure).when(executor).execute(any(),any(),any(Object[].class));health(assertDoesNotThrow(()->{return indicator.health();}),Status.DOWN);verify(executor,times(1)).execute(eq(SqlServerProcedure.HEALTH_READY),any(),any(Object[].class));verifyNoMoreInteractions(executor);}}
    @Test void failedCommitCannotBecomeUp(){ready();manager.failCommit=true;health(assertDoesNotThrow(()->{return indicator.health();}),Status.DOWN);verify(executor,times(1)).execute(eq(SqlServerProcedure.HEALTH_READY),any(),any(Object[].class));}
    @Test void httpAndSecurityContextAreIgnoredAndNotChanged(){ready();var prior=new MockHttpServletRequest("POST","/private-canary");var actor=new Actor("synthetic","Synthetic","synthetic@example.test",null,List.of("SAD"),"private-canary");prior.setAttribute("health.actor",actor);prior.setAttribute("health.tenant","malformed-private-canary");TraceContext.REQUEST.set(prior);var auth=new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(actor,"private-canary",List.of());SecurityContextHolder.getContext().setAuthentication(auth);health(indicator.health(),Status.UP);assertSame(prior,TraceContext.REQUEST.get());assertSame(actor,prior.getAttribute("health.actor"));assertEquals("malformed-private-canary",prior.getAttribute("health.tenant"));assertSame(auth,SecurityContextHolder.getContext().getAuthentication());}
    @Test void explicitPublicFinalApiHasNoAutomaticComponentOrSchedulerRegistration(){assertThrows(NullPointerException.class,()->new SqlServerDatabaseHealthIndicator(null));assertTrue(Modifier.isPublic(SqlServerDatabaseHealthIndicator.class.getModifiers()));assertTrue(Modifier.isFinal(SqlServerDatabaseHealthIndicator.class.getModifiers()));assertEquals(Object.class,SqlServerDatabaseHealthIndicator.class.getSuperclass());assertTrue(HealthIndicator.class.isAssignableFrom(SqlServerDatabaseHealthIndicator.class));assertEquals(0,SqlServerDatabaseHealthIndicator.class.getAnnotations().length);var candidates=new ClassPathScanningCandidateComponentProvider(true).findCandidateComponents("com.mavric.health.monitor");assertTrue(candidates.stream().anyMatch(bean->MonitorService.class.getName().equals(bean.getBeanClassName())));assertTrue(candidates.stream().noneMatch(bean->SqlServerDatabaseHealthIndicator.class.getName().equals(bean.getBeanClassName())));verifyNoInteractions(executor);}
    @Test void fatalErrorIsNotHiddenAsDownOrSuccessfulProcess(){var failure=new AssertionError("synthetic fatal");doThrow(failure).when(executor).execute(any(),any(),any(Object[].class));assertSame(failure,assertThrows(AssertionError.class,indicator::health));assertEquals("rollback",manager.events.getLast());verify(executor,times(1)).execute(eq(SqlServerProcedure.HEALTH_READY),any(),any(Object[].class));}
}
