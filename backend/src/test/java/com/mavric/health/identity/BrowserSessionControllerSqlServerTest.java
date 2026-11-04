package com.mavric.health.identity;

import java.time.*;
import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.request.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.TransactionSystemException;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Standalone MVC / servlet tests and modeled transactions only: no Boot, browser, JDBC or real login. */
class BrowserSessionControllerSqlServerTest {
    private static final String ID="00000000-0000-4000-8000-000000000001",TENANT="00000000-0000-4000-8000-000000000002";
    private static final String TOKEN="s".repeat(43),HASH=Checks.hash(TOKEN),CSRF="b".repeat(64),OPAQUE="d".repeat(64);
    private static final String EMAIL="qa@example.test",PASSWORD="Synthetic-Password-123";
    private static final Instant EXPIRY=Instant.parse("2030-11-04T12:34:56.123456Z");
    private static final TenantRef REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"));
    private final List<Fixture> fixtures=new ArrayList<>();
    private final ObjectMapper mapper=new ObjectMapper();
    final class Fixture {
        final boolean legacy;
        final IdentityService service=mock(IdentityService.class);
        final Sql sql=mock(Sql.class);
        final SqlServerIdentityStore store=mock(SqlServerIdentityStore.class);
        final Access access=mock(Access.class);
        final Settings settings;
        final BrowserSessionController controller;
        final MockHttpServletRequest request=new MockHttpServletRequest("POST","/api/auth/browser/login");
        final MockHttpServletResponse response=new MockHttpServletResponse();
        TenantRef tenant=REF;
        Actor actor;
        Fixture(boolean legacy,boolean secure) {
            this.legacy=legacy;fixtures.add(this);
            settings=new Settings("health.localhost",(secure?"https":"http")+"://health.localhost",8,null);
            controller=legacy?new BrowserSessionController(service,access,sql,settings):new BrowserSessionController(service,access,store,settings);
            request.setAttribute("health.tenant",tenant);request.setServerName("clinic.health.localhost");TraceContext.REQUEST.set(request);
            when(service.loginBrowser(any(),any(),any(),any())).thenReturn(
                    new IdentityService.BrowserLogin(TOKEN,new IdentityService.BrowserUser(ID,"Synthetic",EMAIL,List.of("ADM")),EXPIRY,CSRF));
            when(service.login(any(),any(),any(),any())).thenReturn(Map.of("accessToken",TOKEN,"tokenType","Bearer",
                    "expiresAt",EXPIRY.toString(),"user",Map.of("id",ID,"name","Synthetic","email",EMAIL,"roles",List.of("ADM"))));
            when(sql.one(anyString(),any(Object[].class))).thenReturn(Map.of("csrfToken",CSRF,"expiresAt",EXPIRY.toString()));
            when(sql.rows(anyString(),any(Object[].class))).thenReturn(List.of(sessionData()));
            when(store.currentSession(any())).thenReturn(new SavedSession(CSRF,EXPIRY));
            when(store.listSessions(any())).thenReturn(List.of(summary()));
        }
        void signed(boolean platform) {
            if(platform) { tenant=null;request.removeAttribute("health.tenant"); }
            actor=new Actor(ID,"Synthetic",EMAIL,tenant==null?null:tenant.id(),List.of(platform?"SAD":"ADM"),HASH);
            request.setAttribute("health.actor",actor);when(access.actor()).thenReturn(actor);when(access.userId()).thenReturn(ID);
        }
        ResultActions http(HttpMethod method,String path) throws Exception {
            MockHttpServletRequestBuilder builder=MockMvcRequestBuilders.request(method,path).with(req-> {
                req.setServerName(tenant==null?"health.localhost":"clinic.health.localhost");
                if(tenant!=null)req.setAttribute("health.tenant",tenant);
                if(actor!=null)req.setAttribute("health.actor",actor);
                req.setAttribute("health.requestId","00000000-0000-4000-8000-000000000003");
                TraceContext.REQUEST.set(req);return req;
            });
            if(method==HttpMethod.POST)builder.contentType(MediaType.APPLICATION_JSON).content(
                    "{\"email\":\""+EMAIL+"\",\"password\":\""+PASSWORD+"\"}");
            Errors errors=new Errors(mapper);
            return MockMvcBuilders.standaloneSetup(controller).setControllerAdvice(new Errors.Advice(errors)).build().perform(builder);
        }
    }
    private static SessionSummary summary() {
        return new SessionSummary(OPAQUE,null,EXPIRY.minusSeconds(100),EXPIRY.minusSeconds(50),EXPIRY,false,"Synthetic","192.0.2.1",true);
    }
    private static Map<String,Object> sessionData() {
        Map<String,Object> row=new LinkedHashMap<>();
        row.put("id",OPAQUE);row.put("tenantId",null);row.put("createdAt",EXPIRY.minusSeconds(100).toString());
        row.put("lastSeenAt",EXPIRY.minusSeconds(50).toString());row.put("expiresAt",EXPIRY.toString());
        row.put("revoked",false);row.put("userAgent","Synthetic");row.put("sourceIp","192.0.2.1");row.put("current",true);
        return row;
    }
    @AfterEach void cleanup() {
        try {
            for(Fixture f:fixtures) {
                if(f.legacy)verifyNoInteractions(f.store);
                else verifyNoInteractions(f.sql);
            }
        } finally {
            TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();
        }
    }
    private Map<?,?> body(MvcResult result) throws Exception { return mapper.readValue(result.getResponse().getContentAsString(),Map.class); }
    private static void flags(String cookie,boolean secure,boolean expired) {
        assertNotNull(cookie);assertTrue(cookie.contains("health_session="));assertTrue(cookie.contains("Path=/api"));
        assertTrue(cookie.contains("HttpOnly"));assertTrue(cookie.contains("SameSite=Strict"));
        assertEquals(secure,cookie.contains("; Secure"));assertTrue(cookie.contains(expired?"Max-Age=0":"Max-Age=28800"));
        assertFalse(cookie.contains("Domain="));
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void bothConstructorsPreserveLoginBodyAndHttpHttpsCookieFlagsWithoutExtraSqlInSqlServer(boolean legacy) throws Exception {
        for(boolean secure:List.of(false,true)) {
            Fixture f=new Fixture(legacy,secure);
            MvcResult result=f.http(HttpMethod.POST,"/api/auth/browser/login").andReturn();
            assertEquals(200,result.getResponse().getStatus());Map<?,?> data=body(result);
            assertEquals(Set.of("user","expiresAt","csrfToken"),data.keySet());assertEquals(CSRF,data.get("csrfToken"));
            assertEquals(EXPIRY.toString(),data.get("expiresAt"));
            assertEquals(Set.of("id","name","email","roles"),((Map<?,?>)data.get("user")).keySet());
            String json=result.getResponse().getContentAsString();
            for(String forbidden:List.of(TOKEN,HASH,"accessToken","tokenType","passwordHash","lockedUntil"))assertFalse(json.contains(forbidden));
            flags(result.getResponse().getHeader("Set-Cookie"),secure,false);
            assertTrue(result.getResponse().getHeader("Set-Cookie").contains(TOKEN));
            if(legacy)verify(f.service).login(eq(EMAIL),eq(PASSWORD),eq(REF),any());
            else {
                verify(f.service).loginBrowser(eq(EMAIL),eq(PASSWORD),eq(REF),any());
                verify(f.service,never()).login(any(),any(),any(),any());verifyNoInteractions(f.store);
            }
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void login401403429500HasNoSuccessCookieOrCredentialBody(boolean legacy) throws Exception {
        for(int status:List.of(401,403,429,500)) {
            Fixture f=new Fixture(legacy,false);ApiException error=new ApiException(status,"SAFE_ERROR","Operacion rechazada.");
            if(legacy)doThrow(error).when(f.service).login(any(),any(),any(),any());
            else doThrow(error).when(f.service).loginBrowser(any(),any(),any(),any());
            var result=f.http(HttpMethod.POST,"/api/auth/browser/login").andReturn();
            assertEquals(status,result.getResponse().getStatus());assertNull(result.getResponse().getHeader("Set-Cookie"));
            assertFalse(result.getResponse().getContentAsString().contains(TOKEN));assertFalse(result.getResponse().getContentAsString().contains(CSRF));
            verifyNoInteractions(f.store,f.sql);
        }
    }

    @Test void legacyCsrfReadFailureAndMalformedTypedResultNeverSetSuccessCookie() {
        Fixture legacy=new Fixture(true,false);doThrow(new ApiException(500,"DATABASE_ERROR","Unavailable")).when(legacy.sql).one(anyString(),any(Object[].class));
        assertThrows(ApiException.class,()->legacy.controller.login(new AuthController.Login(EMAIL,PASSWORD),legacy.request,legacy.response));
        assertNull(legacy.response.getHeader("Set-Cookie"));
        Fixture sql=new Fixture(false,false);doReturn(null).when(sql.service).loginBrowser(any(),any(),any(),any());
        assertThrows(ApiException.class,()->sql.controller.login(new AuthController.Login(EMAIL,PASSWORD),sql.request,sql.response));
        assertNull(sql.response.getHeader("Set-Cookie"));verifyNoInteractions(sql.store);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void currentSessionPreservesTenantNullAndPublicUserShape(boolean legacy) throws Exception {
        for(boolean platform:List.of(false,true)) {
            Fixture f=new Fixture(legacy,false);f.signed(platform);
            var result=f.http(HttpMethod.GET,"/api/auth/browser/session").andReturn();
            assertEquals(200,result.getResponse().getStatus());Map<?,?> data=body(result),user=(Map<?,?>)data.get("user");
            assertEquals(Set.of("user","csrfToken","expiresAt"),data.keySet());
            assertEquals(Set.of("id","name","email","roles","tenantId"),user.keySet());
            assertEquals(platform?null:TENANT,user.get("tenantId"));assertEquals(CSRF,data.get("csrfToken"));
            assertEquals(EXPIRY.toString(),data.get("expiresAt"));assertNull(result.getResponse().getHeader("Set-Cookie"));
            assertFalse(result.getResponse().getContentAsString().contains(HASH));
            if(!legacy)verify(f.store).currentSession(any());
        }
    }

    @Test void sqlCurrentListAndRevokeRequireMatchingTraceActorAndHostBeforeStore() {
        for(int mode=0;mode<3;mode++) {
            Fixture f=new Fixture(false,false);f.signed(false);
            if(mode==0)TraceContext.REQUEST.remove();
            if(mode==1)f.request.removeAttribute("health.actor");
            if(mode==2)f.request.removeAttribute("health.tenant");
            assertThrows(ApiException.class,f.controller::session);
            assertThrows(ApiException.class,f.controller::sessions);
            assertThrows(ApiException.class,()->f.controller.revoke(OPAQUE));verifyNoInteractions(f.store);
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void sessionListHasOnlySafeColumnsAndPreservesEmptyList(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy,false);f.signed(false);
        var response=f.http(HttpMethod.GET,"/api/auth/sessions").andReturn().getResponse();
        assertEquals(200,response.getStatus());
        List<?> rows=mapper.readValue(response.getContentAsString(),List.class);
        assertEquals(sessionData(),rows.getFirst());
        for(String forbidden:List.of(HASH,CSRF,TOKEN,"tokenHash","csrfToken","passwordHash"))assertFalse(response.getContentAsString().contains(forbidden));
        if(legacy)doReturn(List.of()).when(f.sql).rows(anyString(),any(Object[].class));
        else doReturn(List.of()).when(f.store).listSessions(any());
        assertEquals("[]",f.http(HttpMethod.GET,"/api/auth/sessions").andReturn().getResponse().getContentAsString());
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void currentAndListInfrastructureErrorsStaySafeWithoutAnyCookie(boolean legacy) throws Exception {
        Fixture current=new Fixture(legacy,false);current.signed(false);
        ApiException unavailable=new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(legacy)doThrow(unavailable).when(current.sql).one(anyString(),any(Object[].class));
        else doThrow(unavailable).when(current.store).currentSession(any());
        var currentResponse=current.http(HttpMethod.GET,"/api/auth/browser/session").andReturn().getResponse();
        assertEquals(500,currentResponse.getStatus());assertNull(currentResponse.getHeader("Set-Cookie"));
        assertFalse(currentResponse.getContentAsString().contains(HASH));assertFalse(currentResponse.getContentAsString().contains(CSRF));
        Fixture list=new Fixture(legacy,false);list.signed(false);
        if(legacy)doThrow(unavailable).when(list.sql).rows(anyString(),any(Object[].class));
        else doThrow(unavailable).when(list.store).listSessions(any());
        var listResponse=list.http(HttpMethod.GET,"/api/auth/sessions").andReturn().getResponse();
        assertEquals(500,listResponse.getStatus());assertNull(listResponse.getHeader("Set-Cookie"));
        assertFalse(listResponse.getContentAsString().contains(HASH));assertFalse(listResponse.getContentAsString().contains(CSRF));
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void logoutExpiresCookieOnlyAfterSuccessAndRevokeByIdNeverChangesCookie(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy,true);f.signed(false);
        var ended=f.http(HttpMethod.DELETE,"/api/auth/browser/session").andReturn().getResponse();
        assertEquals(200,ended.getStatus());flags(ended.getHeader("Set-Cookie"),true,true);verify(f.service).logout();
        String opaque="A".repeat(64);
        if(legacy)doReturn(Map.of("tokenHash",HASH)).when(f.sql).one(anyString(),any(Object[].class));
        var revoked=f.http(HttpMethod.DELETE,"/api/auth/sessions/"+opaque).andReturn().getResponse();
        assertEquals(200,revoked.getStatus());assertNull(revoked.getHeader("Set-Cookie"));
        if(!legacy)verify(f.store).revokeSession(any(),eq(opaque));
        Fixture fail=new Fixture(legacy,false);fail.signed(false);
        doThrow(new ApiException(500,"DATABASE_ERROR","Unavailable")).when(fail.service).logout();
        var error=fail.http(HttpMethod.DELETE,"/api/auth/browser/session").andReturn().getResponse();
        assertEquals(500,error.getStatus());assertNull(error.getHeader("Set-Cookie"));
    }

    @Test void invalidOpaqueIdsUseRealStore404WithoutExecutorAndUnknownForeign404PassesThrough() throws Exception {
        Fixture f=new Fixture(false,false);f.signed(false);TraceContext.REQUEST.set(f.request);
        SqlServerExecutor executor=mock(SqlServerExecutor.class);
        var store=new SqlServerIdentityStore(executor,new ModelTransactionManager());
        var controller=new BrowserSessionController(f.service,f.access,store,f.settings);
        for(String invalid:List.of(ID,TOKEN,"x","a".repeat(65),"g".repeat(64))) {
            assertEquals(404,assertThrows(ApiException.class,()->controller.revoke(invalid)).status);
        }
        verifyNoInteractions(executor);
        doThrow(ApiException.missing()).when(f.store).revokeSession(any(),anyString());
        var response=f.http(HttpMethod.DELETE,"/api/auth/sessions/"+OPAQUE).andReturn().getResponse();
        assertEquals(404,response.getStatus());assertNull(response.getHeader("Set-Cookie"));verify(f.store).revokeSession(any(),eq(OPAQUE));
    }

    final class Integrated {
        final Fixture f=new Fixture(false,false);
        final ModelTransactionManager manager=new ModelTransactionManager();
        final BrowserSessionController controller;
        Integrated() {
            PasswordEncoder encoder=mock(PasswordEncoder.class);when(encoder.matches(any(),any())).thenReturn(true);
            when(f.store.required(any())).thenAnswer(inv->manager.outer(()->inv.<Supplier<?>>getArgument(0).get()));
            when(f.store.credentials(any(),any())).thenReturn(Optional.of(new Credentials(ID,"Synthetic",EMAIL,"synthetic-hash",null,true,false,null)));
            when(f.store.membership(any(),any())).thenReturn(Optional.of(new Membership(ID,List.of("ADM"))));
            when(f.store.saveSession(any(),any(),any(),any())).thenAnswer(inv-> {
                assertNull(f.response.getHeader("Set-Cookie"));assertNull(f.request.getAttribute("health.actor"));
                return new SavedSession(CSRF,EXPIRY);
            });
            var service=new IdentityService(f.store,f.access,encoder,f.settings);
            controller=new BrowserSessionController(service,f.access,f.store,f.settings);
        }
        Object login() { return controller.login(new AuthController.Login(EMAIL,PASSWORD),f.request,f.response); }
    }

    @Test void realServiceAndControllerWithoutOuterTransactionSetCookieOnlyAfterSaveAndCommit() {
        Integrated unit=new Integrated();Map<?,?> body=(Map<?,?>)unit.login();
        assertEquals(CSRF,body.get("csrfToken"));assertEquals(EXPIRY.toString(),body.get("expiresAt"));
        assertNotNull(unit.f.request.getAttribute("health.actor"));flags(unit.f.response.getHeader("Set-Cookie"),false,false);
        assertEquals(List.of("begin:0","commit"),unit.manager.events);
        verify(unit.f.store,times(1)).saveSession(any(),any(),any(),any());verify(unit.f.store,never()).currentSession(any());
    }

    @Test void cookieAndActorWaitForOuterCommitAndRemainAbsentOnRollbackAndCommitFailure() {
        Integrated success=new Integrated();
        success.manager.outer(()-> {
            success.login();assertNull(success.f.response.getHeader("Set-Cookie"));assertNull(success.f.request.getAttribute("health.actor"));return true;
        });
        assertNotNull(success.f.response.getHeader("Set-Cookie"));assertNotNull(success.f.request.getAttribute("health.actor"));
        Integrated rollback=new Integrated();
        assertThrows(ApiException.class,()->rollback.manager.outer(()-> {
            rollback.login();assertNull(rollback.f.response.getHeader("Set-Cookie"));throw new ApiException(409,"CONFLICT","Later failure");
        }));
        assertNull(rollback.f.response.getHeader("Set-Cookie"));assertNull(rollback.f.request.getAttribute("health.actor"));
        Integrated outerFail=new Integrated();outerFail.manager.failCommit=true;
        assertThrows(TransactionSystemException.class,()->outerFail.manager.outer(outerFail::login));
        assertNull(outerFail.f.response.getHeader("Set-Cookie"));assertNull(outerFail.f.request.getAttribute("health.actor"));
        Integrated ownFail=new Integrated();ownFail.manager.failCommit=true;
        assertEquals(500,assertThrows(ApiException.class,ownFail::login).status);
        assertNull(ownFail.f.response.getHeader("Set-Cookie"));assertNull(ownFail.f.request.getAttribute("health.actor"));
    }

    @Test void logoutCookieAlsoWaitsForOuterCommitAndDoesNotClaimRevocationOnRollback() {
        Fixture f=new Fixture(false,false);f.signed(false);ModelTransactionManager manager=new ModelTransactionManager();
        manager.outer(()->{f.controller.end(f.response);assertNull(f.response.getHeader("Set-Cookie"));return true;});
        flags(f.response.getHeader("Set-Cookie"),false,true);
        Fixture rollback=new Fixture(false,false);rollback.signed(false);
        assertThrows(ApiException.class,()->manager.outer(()-> {
            rollback.controller.end(rollback.response);assertNull(rollback.response.getHeader("Set-Cookie"));throw new ApiException(409,"CONFLICT","Later failure");
        }));
        assertNull(rollback.response.getHeader("Set-Cookie"));
        Fixture failure=new Fixture(false,false);failure.signed(false);manager.failCommit=true;
        assertThrows(TransactionSystemException.class,()->manager.outer(()-> {
            failure.controller.end(failure.response);assertNull(failure.response.getHeader("Set-Cookie"));return true;
        }));
        assertNull(failure.response.getHeader("Set-Cookie"));
    }

    @Test void legacyControllerConstructorRemainsSelectedByMinimalSpringContext() {
        Fixture f=new Fixture(true,false);
        try(AnnotationConfigApplicationContext context=new AnnotationConfigApplicationContext()) {
            context.registerBean(IdentityService.class,()->f.service);context.registerBean(Access.class,()->f.access);
            context.registerBean(Sql.class,()->f.sql);context.registerBean(Settings.class,()->f.settings);
            context.registerBean(BrowserSessionController.class);context.refresh();
            var controller=context.getBean(BrowserSessionController.class);
            controller.login(new AuthController.Login(EMAIL,PASSWORD),f.request,f.response);
            verify(f.service).login(any(),any(),any(),any());verify(f.service,never()).loginBrowser(any(),any(),any(),any());
            assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);
            assertEquals(0,context.getBeanNamesForType(SqlServerIdentityStore.class).length);
        }
    }
}
