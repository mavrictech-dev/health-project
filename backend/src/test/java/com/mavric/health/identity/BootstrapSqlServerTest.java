package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.tenancy.Settings;
import com.mavric.health.shared.*;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
/** Runner invoked manually only, real store/templates with modeled dependencies; no Boot or database. */
class BootstrapSqlServerTest {
 static final String ID="aa000000-0000-4000-8000-000000000001",PASSWORD="SyntheticPassword123!";
 final SqlServerExecutor executor=mock(SqlServerExecutor.class);final ModelTransactionManager manager=new ModelTransactionManager();final SqlServerBootstrapStore store=new SqlServerBootstrapStore(executor,manager);final PasswordEncoder encoder=mock(PasswordEncoder.class);final Sql sql=mock(Sql.class);boolean exists;SqlServerProcedure failure;final List<SqlServerProcedure> calls=new ArrayList<>();final List<List<Object>> args=new ArrayList<>();
 BootstrapSqlServerTest(){when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());assertEquals(new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.BOOTSTRAP),inv.getArgument(1));var sp=inv.<SqlServerProcedure>getArgument(0);calls.add(sp);args.add(Arrays.asList(((Object[])inv.getRawArguments()[2]).clone()));if(sp==failure)throw new RuntimeException("canary driver");return new SqlServerExecutor.Result(sp==SqlServerProcedure.BOOTSTRAP_EXISTS?List.of(exists?List.of(Map.of("id",ID)):List.of()):List.of(),List.of());});when(encoder.encode(PASSWORD)).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());return "encoded-only";});}
 Settings settings(Settings.Bootstrap config){return new Settings("health.localhost","https://health.localhost",8,config);}
 Bootstrap runner(String email,String password){return new Bootstrap(store,settings(new Settings.Bootstrap(email,password)),encoder);}
 @AfterEach void cleanup(){com.mavric.health.audit.TraceContext.REQUEST.remove();org.springframework.security.core.context.SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}
 @Test void disabledConfigurationNeverStoreOrEncoder(){new Bootstrap(store,settings(null),encoder).run();runner(null,null).run();runner(" ",null).run();verifyNoInteractions(executor,encoder,sql);}
 @Test void existingAdminDoesNotValidateBadPasswordOrEncode(){exists=true;runner("qa@example.test","short").run();assertEquals(List.of(SqlServerProcedure.BOOTSTRAP_EXISTS),calls);verifyNoInteractions(encoder,sql);}
 @Test void absentAdminCreatesOnceWithHashNotPlaintextAndNoLegacy(){runner("QA@EXAMPLE.TEST",PASSWORD).run();assertEquals(List.of(SqlServerProcedure.BOOTSTRAP_EXISTS,SqlServerProcedure.BOOTSTRAP_CREATE),calls);assertEquals(List.of(),args.getFirst());assertEquals("qa@example.test",args.getLast().get(1));assertEquals("encoded-only",args.getLast().get(2));assertFalse(args.getLast().contains(PASSWORD));verify(encoder,times(1)).encode(PASSWORD);verifyNoInteractions(sql);assertEquals(List.of("begin:0","commit"),manager.events);}
 @Test void invalidPasswordAndEncodeCreateCommitFailureAbortStartup(){assertEquals(400,assertThrows(ApiException.class,()->runner("qa@example.test","short").run()).status);verifyNoInteractions(encoder);assertEquals(List.of(SqlServerProcedure.BOOTSTRAP_EXISTS),calls);doThrow(new RuntimeException("canary encode")).when(encoder).encode(PASSWORD);var e=assertThrows(ApiException.class,()->runner("qa@example.test",PASSWORD).run());assertEquals(500,e.status);assertFalse(e.toString().contains("canary"));doReturn("encoded-only").when(encoder).encode(PASSWORD);failure=SqlServerProcedure.BOOTSTRAP_CREATE;assertEquals(500,assertThrows(ApiException.class,()->runner("qa@example.test",PASSWORD).run()).status);failure=null;manager.failCommit=true;assertEquals(500,assertThrows(ApiException.class,()->runner("qa@example.test",PASSWORD).run()).status);}
 @Test void minimalSpringSelectsLegacyWithoutRunningCommandLineRunner(){try(var context=new AnnotationConfigApplicationContext()){context.registerBean(Sql.class,()->sql);context.registerBean(Settings.class,()->settings(null));context.registerBean(PasswordEncoder.class,()->encoder);context.registerBean(Bootstrap.class);context.refresh();assertTrue(context.getBean(Bootstrap.class) instanceof org.springframework.boot.CommandLineRunner);verifyNoInteractions(sql,encoder,executor);assertEquals(0,context.getBeanNamesForType(SqlServerBootstrapStore.class).length);assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);}when(sql.optional(anyString(),any(Object[].class))).thenReturn(Optional.of(Map.of("id",ID)));new Bootstrap(sql,settings(new Settings.Bootstrap("qa@example.test","short")),encoder).run();verify(sql).optional(anyString(),any(Object[].class));verifyNoInteractions(encoder,executor);}
}
