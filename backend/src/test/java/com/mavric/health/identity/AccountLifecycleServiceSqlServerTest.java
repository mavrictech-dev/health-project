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
 @AfterEach void cleanup(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();}
 @Test void platformAndTenantShapesAndNoTenantQuery(){var r=request();var data=Map.<String,Object>of("plans",List.of(),"specialties",List.of());when(store.options(r)).thenReturn(data);assertEquals(data,service.options(null));r.setAttribute("health.tenant",TENANT);assertEquals(Map.of("portal",true),service.options(TENANT));verify(store,times(1)).options(r);verifyNoMoreInteractions(store);verifyNoInteractions(sql,identity,passwords);}
 @Test void missingOrMalformedInternalRequest500(){assertEquals(500,assertThrows(ApiException.class,()->service.options(null)).status);var r=request();r.setAttribute("health.tenant","forged");assertEquals("DATABASE_ERROR",assertThrows(ApiException.class,()->service.options(null)).code);verifyNoInteractions(store);}
 @Test void exactHostMustAgreeIncludingNullAndAllFields(){var r=request();assertEquals(403,assertThrows(ApiException.class,()->service.options(TENANT)).status);r.setAttribute("health.tenant",TENANT);assertEquals(403,assertThrows(ApiException.class,()->service.options(null)).status);var changed=new TenantRef(TENANT.id(),"Changed",TENANT.slug(),TENANT.kind(),TENANT.domain(),TENANT.status(),TENANT.modules());assertEquals(403,assertThrows(ApiException.class,()->service.options(changed)).status);verifyNoInteractions(store);}
 @Test void clientAuthorityIgnoredAndErrorsNeverFallback(){var r=request();r.addHeader("X-Tenant-Id",TENANT.id());r.addParameter("tenantId",TENANT.id());r.setContent("forged body".getBytes());var failure=new ApiException(500,"DATABASE_ERROR","Safe");when(store.options(r)).thenThrow(failure);assertSame(failure,assertThrows(ApiException.class,()->service.options(null)));verify(store,times(1)).options(r);verifyNoInteractions(sql,identity,passwords);}
 @Test void sqlMutatorsRejectEvenInvalidInputsBeforeAnyEffect(){for(Runnable work:List.<Runnable>of(()->service.register(null,null),()->service.request(null,null,null),()->service.redeem(null,null,null,null))){var e=assertThrows(ApiException.class,work::run);assertEquals(500,e.status);assertEquals("DATABASE_ERROR",e.code);}verifyNoInteractions(store,sql,identity,passwords,settings);}
 @Test void legacyAndRateKeepBehavior(){var legacy=new AccountLifecycleService(sql,identity,settings,passwords);when(sql.rows(anyString(),any(Object[].class))).thenReturn(List.of());assertEquals(Map.of("plans",List.of(),"specialties",List.of()),legacy.options(null));assertEquals(Map.of("portal",true),legacy.options(TENANT));verify(sql,times(2)).rows(anyString(),any(Object[].class));assertEquals(400,assertThrows(ApiException.class,()->legacy.redeem("invalid",null,null,"VERIFY")).status);when(sql.optional(anyString(),any(Object[].class))).thenReturn(Optional.empty());legacy.request("qa@example.test",null,"RESET");verify(sql).optional(anyString(),any(Object[].class));for(var target:List.of(service,legacy)){target.rate("127.0.0.1","options");assertEquals(429,assertThrows(ApiException.class,()->target.rate("127.0.0.1","options")).status);}verifyNoInteractions(store,identity,passwords);}
 @Test void minimalSpringSelectsLegacyWithoutDatasource(){try(var context=new AnnotationConfigApplicationContext()){context.registerBean(Sql.class,()->sql);context.registerBean(IdentityService.class,()->identity);context.registerBean(Settings.class,()->settings);context.registerBean(PasswordEncoder.class,()->passwords);context.registerBean(AccountLifecycleService.class);context.refresh();assertEquals(Map.of("portal",true),context.getBean(AccountLifecycleService.class).options(TENANT));assertEquals(0,context.getBeanNamesForType(SqlServerAccountLifecycleStore.class).length);assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);}}
}
