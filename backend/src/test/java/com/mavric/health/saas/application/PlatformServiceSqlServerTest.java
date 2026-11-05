package com.mavric.health.saas.application;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.*;
import com.mavric.health.tenancy.*;
import com.mavric.health.shared.*;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
/** Real service/store/templates with modeled executor/manager, no connected platform authorization. */
class PlatformServiceSqlServerTest {
 static final String ID="aa000000-0000-4000-8000-000000000001";
 final SqlServerExecutor executor=mock(SqlServerExecutor.class);final ModelTransactionManager manager=new ModelTransactionManager();final Access access=mock(Access.class);final IdentityService identities=mock(IdentityService.class);final Settings settings=mock(Settings.class);final Sql sql=mock(Sql.class);final PlatformService service=new PlatformService(new SqlServerPlatformStore(executor,manager),access,identities,settings);final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/platform");
 PlatformServiceSqlServerTest(){when(executor.execute(any(),any(),any(Object[].class))).thenAnswer(inv->{assertTrue(TransactionSynchronizationManager.isActualTransactionActive());return new SqlServerExecutor.Result(List.of(List.of()),List.of());});}
 void actor(String role,boolean tenant){var a=new Actor(ID,"Synthetic","qa@example.test",tenant?ID:null,List.of(role),"a".repeat(64));doReturn(a).when(access).actor();request.setAttribute("health.actor",a);if(tenant)request.setAttribute("health.tenant",new TenantRef(ID,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of()));else request.removeAttribute("health.tenant");TraceContext.REQUEST.set(request);}
 @AfterEach void cleanup(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}
 @Test void sadFourReadsUseRealStoreAndAccessPlatformWithoutSqlIdentityOrSettings(){actor("SAD",false);request.addHeader("X-Roles","SOP");request.addHeader("X-Tenant-Id","forged");request.setContent("forged body".getBytes());assertEquals(List.of(),service.plans());assertEquals(List.of(),service.users(1));assertEquals(List.of(),service.specialties(null));assertEquals(List.of(),service.audit(1));verify(access,times(4)).platform();verify(executor).execute(eq(SqlServerProcedure.PLATFORM_PLANS),any(),isNull());verify(executor).execute(eq(SqlServerProcedure.PLATFORM_USERS),any(),isNull(),eq(1));verify(executor).execute(eq(SqlServerProcedure.PLATFORM_SPECIALTIES),any(),eq(""));verify(executor).execute(eq(SqlServerProcedure.PLATFORM_AUDIT),any(),eq(1));verifyNoInteractions(sql,identities,settings);}
 @Test void requestMissingActorTenantSopAndMalformedAuthorityFailBeforeSp(){assertEquals(500,assertThrows(ApiException.class,service::plans).status);actor("SAD",false);doThrow(new ApiException(401,"UNAUTHENTICATED","Safe")).when(access).actor();assertEquals(401,assertThrows(ApiException.class,service::plans).status);actor("SOP",false);assertEquals(403,assertThrows(ApiException.class,service::plans).status);actor("SAD",true);assertEquals(403,assertThrows(ApiException.class,service::plans).status);actor("SAD",false);request.setAttribute("health.actor","forged");assertEquals(403,assertThrows(ApiException.class,service::plans).status);actor("SAD",false);request.setAttribute("health.tenant","forged");assertEquals(500,assertThrows(ApiException.class,service::plans).status);verifyNoInteractions(executor);verify(access,never()).platform();}
 @Test void sevenRemainingOperationsGuardBeforeAnyCollaboratorOrInput(){for(Runnable work:List.<Runnable>of(()->service.plan(null,null),()->service.tenants(-1),()->service.tenant(null),()->service.createUser(null),()->service.create(null),()->service.status(null,null),()->service.pay(null,null))){var e=assertThrows(ApiException.class,work::run);assertEquals(500,e.status);assertEquals("DATABASE_ERROR",e.code);}verifyNoInteractions(access,identities,settings,sql,executor);}
 @Test void safeDatabaseErrorsNeverFallBack(){actor("SAD",false);doThrow(new RuntimeException(new java.sql.SQLException("private driver",null,51001))).when(executor).execute(any(),any(),any(Object[].class));var e=assertThrows(ApiException.class,service::plans);assertEquals(403,e.status);assertFalse(e.toString().contains("private"));verify(executor,times(1)).execute(any(),any(),any(Object[].class));verifyNoInteractions(sql,identities,settings);}
 @Test void minimalSpringSelectsLegacyWithoutDatasourceOrStore(){when(sql.rows(anyString(),any(Object[].class))).thenReturn(List.of());try(var context=new AnnotationConfigApplicationContext()){context.registerBean(Sql.class,()->sql);context.registerBean(Access.class,()->access);context.registerBean(IdentityService.class,()->identities);context.registerBean(Settings.class,()->settings);context.registerBean(PlatformService.class);context.refresh();assertEquals(List.of(),context.getBean(PlatformService.class).plans());verify(sql).rows(anyString(),any(Object[].class));verify(access).platform();assertEquals(0,context.getBeanNamesForType(SqlServerPlatformStore.class).length);assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);}verifyNoInteractions(executor,identities,settings);}
}
