package com.mavric.health.identity;

import java.util.*;
import jakarta.servlet.http.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.mock.web.*;
import org.springframework.security.core.context.SecurityContextHolder;
import com.mavric.health.persistence.sqlserver.SqlServerSecurityStore;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Actual servlet filters, simulated HTTP/SQL/store. No real application, browser, JDBC or persistence. */
class SqlServerFiltersTest {
    private static final String TENANT="00000000-0000-4000-8000-000000000010";
    private static final String USER="00000000-0000-4000-8000-000000000020";
    private static final String TOKEN="s".repeat(43),CSRF="c".repeat(64);
    private static final TenantRef REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"));
    private final List<Fixture> fixtures=new ArrayList<>();
    private final ObjectMapper mapper=new ObjectMapper();

    final class Fixture {
        final Sql sql=mock(Sql.class);
        final SqlServerSecurityStore store=mock(SqlServerSecurityStore.class);
        final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/patients");
        final MockHttpServletResponse response=new MockHttpServletResponse();
        final HostFilter host;
        final SessionFilter sessionFilter;
        final boolean legacy;
        Optional<Map<String,Object>> session=Optional.of(sessionRow(TENANT,null));
        Optional<Map<String,Object>> membership=Optional.of(Map.of("userId",USER,"roles",List.of("ADM"),"status","ACTIVE"));
        Map<String,Object> state=Map.of("mode","OPEN","message","Ready");
        boolean missingTenant;
        ApiException resolveFailure,touchFailure;
        int chained,touched;
        Runnable downstream=()->{};
        Fixture(boolean legacy) {
            this.legacy=legacy;fixtures.add(this);
            request.setServerName("clinic.health.localhost");request.setAttribute("health.tenant",REF);
            request.setAttribute("health.requestId","00000000-0000-4000-8000-000000000030");
            request.addHeader("Authorization","Bearer "+TOKEN);
            when(store.tenantBySlug(any(),anyString())).thenAnswer(inv->missingTenant?Optional.empty():Optional.of(tenantRow()));
            when(store.resolveSession(any(),anyString())).thenAnswer(inv->{if(resolveFailure!=null)throw resolveFailure;return session;});
            when(store.activeMembership(any(),anyString())).thenAnswer(inv->membership);
            when(store.applicationStatus(any())).thenAnswer(inv->state);
            doAnswer(inv->{touch();return null;}).when(store).touchSession(any());
            when(sql.optional(anyString(),any(Object[].class))).thenAnswer(inv-> {
                if(inv.<String>getArgument(0).contains("auth_sessions")) {
                    if(resolveFailure!=null)throw resolveFailure;return session;
                }
                return membership;
            });
            when(sql.one(anyString(),any(Object[].class))).thenAnswer(inv-> {
                if(inv.<String>getArgument(0).contains("application_state"))return state;
                if(missingTenant)throw ApiException.missing();return tenantRow();
            });
            when(sql.strings(any())).thenAnswer(inv-> {
                Object value=inv.getArgument(0);if(!(value instanceof List<?> values))return List.of();
                return values.stream().map(Object::toString).toList();
            });
            doAnswer(inv->{touch();return null;}).when(sql).call(anyString(),any(Object[].class));
            Settings settings=new Settings("health.localhost","http://health.localhost",8,null);
            Errors errors=new Errors(mapper);
            host=legacy?new HostFilter(settings,sql,errors):new HostFilter(settings,store,errors);
            sessionFilter=legacy?new SessionFilter(sql,errors):new SessionFilter(store,errors);
        }
        void touch() {
            assertNotNull(request.getAttribute("health.actor"));
            assertNull(SecurityContextHolder.getContext().getAuthentication(),"Authenticate only AFTER successful touch");
            touched++;if(touchFailure!=null)throw touchFailure;
        }
        void run() throws Exception {
            sessionFilter.doFilter(request,response,(req,res)->{chained++;downstream.run();});
        }
        void runHost() throws Exception {
            host.doFilter(request,response,(req,res)->{chained++;downstream.run();});
        }
        void cookie(String value) { request.removeHeader("Authorization");request.setCookies(new Cookie("health_session",value)); }
        void error(int status,String code) throws Exception {
            assertEquals(status,response.getStatus());assertEquals(0,chained);
            Map<?,?> body=mapper.readValue(response.getContentAsString(),Map.class);
            assertEquals(code,body.get("title"));assertEquals(status,body.get("status"));
            assertEquals(request.getAttribute("health.requestId"),body.get("requestId"));
            assertFalse(response.getContentAsString().contains(TOKEN));assertFalse(response.getContentAsString().contains(CSRF));
            assertFalse(response.getContentAsString().contains(Checks.hash(TOKEN)));
            assertNull(SecurityContextHolder.getContext().getAuthentication());
            assertNull(request.getAttribute("health.actor"));
        }
    }

    private static Map<String,Object> tenantRow() {
        return Map.of("id",TENANT,"name","Synthetic","slug","clinic","kind","CLINIC","domain","HUMAN","status","ACTIVE","modules",List.of("CORE","DOCUMENTS"));
    }
    private static Map<String,Object> sessionRow(String tenant,String platformRole) {
        Map<String,Object> row=new LinkedHashMap<>();
        row.put("userId",USER);row.put("tenantId",tenant);row.put("platformRole",platformRole);
        row.put("name","Synthetic");row.put("email","qa@example.test");row.put("csrfToken",CSRF);
        return row;
    }

    @AfterEach void cleanupAndAssertConstructorIsolation() {
        try {
            for(Fixture fixture:fixtures) {
                if(fixture.legacy)verifyNoInteractions(fixture.store);
                else verifyNoInteractions(fixture.sql);
            }
        } finally { SecurityContextHolder.clearContext(); }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void hostPlatformAndAdminHaveNoTenantAndNeverLookup(boolean legacy) throws Exception {
        for(String name:List.of("health.localhost","admin.health.localhost","HEALTH.LOCALHOST.")) {
            Fixture f=new Fixture(legacy);f.request.setServerName(name);f.runHost();
            assertEquals(1,f.chained);assertNull(f.request.getAttribute("health.tenant"));
            verifyNoInteractions(f.sql,f.store);
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void hostTenantUsesActualModulesAndStableRef(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);f.request.setServerName("CLINIC.health.localhost.");f.runHost();
        assertEquals(1,f.chained);
        TenantRef ref=(TenantRef)f.request.getAttribute("health.tenant");
        assertEquals(TENANT,ref.id());assertEquals("clinic",ref.slug());assertEquals(List.of("CORE","DOCUMENTS"),ref.modules());
        if(!legacy)verify(f.store).tenantBySlug(f.request,"clinic");
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void missingTenantAndForeignOrReservedHostsReturn404WithoutChain(boolean legacy) throws Exception {
        Fixture missing=new Fixture(legacy);missing.missingTenant=true;missing.runHost();missing.error(404,"NOT_FOUND");
        for(String host:List.of("foreign.example.test","a.b.health.localhost","api.health.localhost","-bad.health.localhost")) {
            Fixture f=new Fixture(legacy);f.request.setServerName(host);f.runHost();f.error(404,"NOT_FOUND");
            verifyNoInteractions(f.sql,f.store);assertNull(f.request.getAttribute("health.tenant"));
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void bearerEstablishesServerIdentityAndSendsOnlyHashAfterChecks(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);
        f.request.addHeader("X-Tenant-Id","forged");f.request.addHeader("X-Roles","SAD");
        f.request.setContent("{\"actorId\":\"forged\",\"roles\":[\"SAD\"]}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        f.downstream=()-> {
            Actor actor=(Actor)SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            assertEquals(USER,actor.id());assertEquals(TENANT,actor.tenantId());assertEquals(List.of("ADM"),actor.roles());
            assertEquals(Checks.hash(TOKEN),actor.tokenHash());assertNotEquals(TOKEN,actor.tokenHash());
            assertEquals(List.of("ADM"),SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream().map(Object::toString).toList());
        };
        f.run();assertEquals(1,f.chained);assertEquals(1,f.touched);
        if(!legacy) {
            verify(f.store).resolveSession(f.request,Checks.hash(TOKEN));verify(f.store).activeMembership(f.request,USER);
            verify(f.store).touchSession(f.request);verify(f.store,never()).applicationStatus(any());
        } else {
            verify(f.sql).call("sp_session_touch",Checks.hash(TOKEN));
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void platformOnlySadOrSopCanAuthenticateAndNoTenantMembershipIsQueried(boolean legacy) throws Exception {
        for(String role:List.of("SAD","SOP")) {
            Fixture f=new Fixture(legacy);f.request.removeAttribute("health.tenant");f.session=Optional.of(sessionRow(null,role));
            f.run();assertEquals(1,f.chained);assertEquals(List.of(role),((Actor)f.request.getAttribute("health.actor")).roles());
            if(!legacy)verify(f.store,never()).activeMembership(any(),any());
            SecurityContextHolder.clearContext();
        }
        for(String role:Arrays.asList(null,"ADM","PRO","UNKNOWN")) {
            Fixture f=new Fixture(legacy);f.request.removeAttribute("health.tenant");f.session=Optional.of(sessionRow(null,role));
            f.run();f.error(401,"UNAUTHENTICATED");assertEquals(0,f.touched);
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void foreignTenantOrPlatformIdentityAndMissingActiveMembershipNeverAuthenticate(boolean legacy) throws Exception {
        for(Map<String,Object> row:List.of(sessionRow("00000000-0000-4000-8000-000000000011",null),
                sessionRow(null,"SAD"),sessionRow(TENANT,"SOP"))) {
            Fixture f=new Fixture(legacy);f.session=Optional.of(row);f.run();f.error(401,"UNAUTHENTICATED");assertEquals(0,f.touched);
        }
        Fixture noMember=new Fixture(legacy);noMember.membership=Optional.empty();noMember.run();noMember.error(401,"UNAUTHENTICATED");
        Fixture noRoles=new Fixture(legacy);noRoles.membership=Optional.of(Map.of("roles",List.of()));noRoles.run();noRoles.error(401,"UNAUTHENTICATED");
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void absentExpiredOrRevokedSessionLookupReturns401(boolean legacy) throws Exception {
        // SQL owns expiry/revocation filtering; an empty SP result is their observable filter contract.
        Fixture f=new Fixture(legacy);f.session=Optional.empty();f.run();f.error(401,"UNAUTHENTICATED");
        assertEquals(0,f.touched);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void bearerWinsOverCookieAndMalformedOrEmptyCredentialsDoNotReachStore(boolean legacy) throws Exception {
        Fixture valid=new Fixture(legacy);valid.request.setCookies(new Cookie("health_session","wrong"));
        valid.run();assertEquals(1,valid.chained);SecurityContextHolder.clearContext();
        for(String header:List.of("","Basic abc","Bearer short","Bearer "+"x".repeat(44),"Bearer "+"!".repeat(43),"bearer "+TOKEN)) {
            Fixture f=new Fixture(legacy);f.request.removeHeader("Authorization");f.request.addHeader("Authorization",header);
            f.request.setCookies(new Cookie("health_session",TOKEN));f.run();f.error(401,"UNAUTHENTICATED");
            verifyNoInteractions(f.sql,f.store);
        }
        Fixture emptyCookie=new Fixture(legacy);emptyCookie.cookie("");emptyCookie.run();emptyCookie.error(401,"UNAUTHENTICATED");
        verifyNoInteractions(emptyCookie.sql,emptyCookie.store);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void cookieMutationsRequireCsrfAndTouchOnlyAfterOpenState(boolean legacy) throws Exception {
        Fixture good=new Fixture(legacy);good.cookie(TOKEN);good.request.setMethod("POST");good.request.addHeader("X-CSRF-Token",CSRF);
        good.run();assertEquals(1,good.chained);assertEquals(1,good.touched);SecurityContextHolder.clearContext();
        for(String csrf:Arrays.asList(null,"","incorrect")) {
            Fixture f=new Fixture(legacy);f.cookie(TOKEN);f.request.setMethod("PATCH");
            if(csrf!=null)f.request.addHeader("X-CSRF-Token",csrf);
            f.run();f.error(403,"CSRF_INVALID");assertEquals(0,f.touched);
            if(!legacy)verify(f.store,never()).applicationStatus(any());
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void safeCookieMethodsNeedNoCsrfAndBearerMutationKeepsExistingContract(boolean legacy) throws Exception {
        for(String method:List.of("GET","HEAD","OPTIONS")) {
            Fixture f=new Fixture(legacy);f.cookie(TOKEN);f.request.setMethod(method);f.run();
            assertEquals(1,f.chained);assertEquals(1,f.touched);SecurityContextHolder.clearContext();
            if(!legacy)verify(f.store,never()).applicationStatus(any());
        }
        Fixture f=new Fixture(legacy);f.request.setMethod("DELETE");f.run();assertEquals(1,f.chained);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void readonlyStateRetains503AndMessageBeforeTouch(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);f.request.setMethod("PUT");f.state=Map.of("mode","MAINTENANCE","message","Synthetic maintenance");
        f.run();f.error(503,"APPLICATION_READ_ONLY");
        assertTrue(f.response.getContentAsString().contains("Synthetic maintenance"));assertEquals(0,f.touched);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void authAndSupportMutationsAndPlatformDoNotReadTenantApplicationState(boolean legacy) throws Exception {
        for(String path:List.of("/api/auth/logout","/api/support","/api/support/123")) {
            Fixture f=new Fixture(legacy);f.request.setRequestURI(path);f.request.setMethod("POST");
            f.state=Map.of("mode","MAINTENANCE","message","Synthetic maintenance");f.run();
            assertEquals(1,f.chained);if(!legacy)verify(f.store,never()).applicationStatus(any());
            SecurityContextHolder.clearContext();
        }
        Fixture platform=new Fixture(legacy);platform.request.removeAttribute("health.tenant");platform.request.setMethod("POST");
        platform.session=Optional.of(sessionRow(null,"SAD"));platform.run();assertEquals(1,platform.chained);
        if(!legacy)verify(platform.store,never()).applicationStatus(any());
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void loginRegistrationRecoveryAndVerifyBypassPersistenceEvenWithInvalidAuthorization(boolean legacy) throws Exception {
        for(String path:List.of("/api/auth/login","/api/auth/browser/login","/api/auth/register",
                "/api/auth/invitations/accept","/api/auth/recovery/request","/api/auth/verify/redeem")) {
            Fixture f=new Fixture(legacy);f.request.setRequestURI(path);f.request.removeHeader("Authorization");
            f.request.addHeader("Authorization","invalid");f.run();assertEquals(1,f.chained);
            verifyNoInteractions(f.sql,f.store);assertNull(SecurityContextHolder.getContext().getAuthentication());
        }
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void infrastructureFailureStays500AndDoesNotFallBackOrAuthenticate(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);f.resolveFailure=new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        f.run();f.error(500,"DATABASE_ERROR");assertEquals(0,f.touched);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void revocationBetweenLookupAndTouchPreservesSafe403WithoutPartialAuthentication(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);f.touchFailure=new ApiException(403,"FORBIDDEN","Operacion rechazada.");
        f.run();f.error(403,"FORBIDDEN");assertEquals(1,f.touched);
        if(!legacy)verify(f.store,times(1)).touchSession(f.request);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void infrastructureFailureDuringTouchClearsCandidateActorAndNeverAuthenticates(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);
        f.touchFailure=new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        f.run();f.error(500,"DATABASE_ERROR");assertEquals(1,f.touched);
        if(!legacy)verify(f.store,times(1)).touchSession(f.request);
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void downstreamDenialRetainsSuccessfullyValidatedActorForTraceAttribution(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);
        f.downstream=()->{throw new ApiException(403,"FORBIDDEN","Operacion rechazada.");};
        f.run();assertEquals(403,f.response.getStatus());assertEquals(1,f.chained);assertEquals(1,f.touched);
        assertEquals(USER,((Actor)f.request.getAttribute("health.actor")).id());
        assertEquals(USER,((Actor)SecurityContextHolder.getContext().getAuthentication().getPrincipal()).id());
    }

    @Test void sqlServerMalformedModulesAndRolesCannotBecomeUnsafeCastsOrIdentities() throws Exception {
        Fixture host=new Fixture(false);when(host.store.tenantBySlug(any(),any())).thenReturn(Optional.of(
                Map.of("id",TENANT,"name","Synthetic","kind","CLINIC","domain","HUMAN","status","ACTIVE","modules",List.of(3))));
        host.runHost();host.error(500,"DATABASE_ERROR");
        Fixture session=new Fixture(false);session.membership=Optional.of(Map.of("roles",List.of(3)));
        session.run();session.error(500,"DATABASE_ERROR");
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void noCredentialsLeavesDownstreamSecurityToEnforceProtectedRoutesWithoutInventingIdentity(boolean legacy) throws Exception {
        Fixture f=new Fixture(legacy);f.request.removeHeader("Authorization");f.run();
        assertEquals(1,f.chained);assertNull(f.request.getAttribute("health.actor"));assertEquals(0,f.touched);
        verifyNoInteractions(f.sql,f.store);
    }
}
