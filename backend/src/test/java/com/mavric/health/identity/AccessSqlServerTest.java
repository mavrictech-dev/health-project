package com.mavric.health.identity;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerAccessStore;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.TenantRef;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Real Access / request / SecurityContext, store and legacy SQL doubles. No backend, HTTP or DB integration. */
class AccessSqlServerTest {
    private static final String USER="00000000-0000-4000-8000-000000000001",TENANT="00000000-0000-4000-8000-000000000002";
    private static final String BRANCH="aa000000-0000-4000-8000-000000000003",PATIENT="bb000000-0000-4000-8000-000000000004";
    private static final String HASH="a".repeat(64);
    private static final TenantRef REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"));
    private final List<Fixture> fixtures=new ArrayList<>();
    final class Fixture {
        final Sql sql=mock(Sql.class);
        final SqlServerAccessStore store=mock(SqlServerAccessStore.class);
        final MockHttpServletRequest request=new MockHttpServletRequest("GET","/api/patients");
        final Access access;
        final boolean legacy;
        boolean available=true,branchExists=true,assignment=true;
        Actor actor;
        Fixture(boolean legacy,String role) {
            this.legacy=legacy;fixtures.add(this);request.setAttribute("health.tenant",REF);
            actor=new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of(role),HASH);setActor(actor);
            access=legacy?new Access(request,sql):new Access(request,store);
            when(store.branch(any(),any())).thenAnswer(inv->available);
            when(store.link(any(),any(),any())).thenAnswer(inv->available);
            when(sql.one(anyString(),any(Object[].class))).thenAnswer(inv-> {
                if(!branchExists)throw ApiException.missing();return Map.of("id",BRANCH);
            });
            when(sql.optional(anyString(),any(Object[].class))).thenAnswer(inv-> {
                if(inv.<String>getArgument(0).contains("membership_branches"))
                    return assignment?Optional.of(Map.of("branchId",BRANCH)):Optional.empty();
                return available?Optional.of(Map.of("patientId",PATIENT)):Optional.empty();
            });
        }
        void setActor(Actor value) { actor=value;request.setAttribute("health.actor",value);authenticate(value); }
    }
    private static void authenticate(Actor actor) {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(actor,null,
                actor.roles().stream().map(SimpleGrantedAuthority::new).toList()));
    }
    @AfterEach void cleanup() {
        try {
            for(Fixture f:fixtures) {
                if(f.legacy)verifyNoInteractions(f.store);
                else verifyNoInteractions(f.sql);
            }
        } finally { SecurityContextHolder.clearContext();TraceContext.REQUEST.remove();TransactionSynchronizationManager.clear(); }
    }

    @Test void sqlBranchAndLinkUseInjectedRequestAndAdmStillConsultsStore() {
        Fixture f=new Fixture(false,"ADM");
        f.access.branch(BRANCH);f.access.link(PATIENT,"DOCUMENTS");
        verify(f.store).branch(f.request,BRANCH);verify(f.store).link(f.request,PATIENT,"DOCUMENTS");
        assertSame(f.actor,f.access.actor());assertEquals(TENANT,f.access.tenantId());
        verify(f.store,times(1)).branch(any(),any());
    }

    @Test void unavailableSqlResourcesUniformlyReturn404WithoutRevealingCause() {
        for(String role:List.of("ADM","PRO","PAC","RES")) {
            Fixture f=new Fixture(false,role);f.available=false;
            for(Runnable action:List.<Runnable>of(()->f.access.branch(BRANCH),()->f.access.link(PATIENT,"DOCUMENTS"))) {
                ApiException error=assertThrows(ApiException.class,action::run);
                assertEquals(404,error.status);assertEquals("NOT_FOUND",error.code);
            }
        }
    }

    @Test void missingOrNonActorPrincipalIs401BeforeAnyStoreCall() {
        Fixture f=new Fixture(false,"ADM");SecurityContextHolder.clearContext();
        assertEquals(401,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);
        assertEquals(401,assertThrows(ApiException.class,()->f.access.link(PATIENT,"DOCUMENTS")).status);
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken("notActor",null,List.of()));
        assertEquals(401,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);verifyNoInteractions(f.store);
    }

    @Test void healthActorMustMatchEveryPrincipalFieldBeforeStore() {
        for(Object attribute:Arrays.asList(null,"forged",
                new Actor("other","Synthetic","qa@example.test",TENANT,List.of("ADM"),HASH),
                new Actor(USER,"Other","qa@example.test",TENANT,List.of("ADM"),HASH),
                new Actor(USER,"Synthetic","other@example.test",TENANT,List.of("ADM"),HASH),
                new Actor(USER,"Synthetic","qa@example.test","other",List.of("ADM"),HASH),
                new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of("PRO"),HASH),
                new Actor(USER,"Synthetic","qa@example.test",TENANT,List.of("ADM"),"b".repeat(64)))) {
            Fixture f=new Fixture(false,"ADM");
            if(attribute==null)f.request.removeAttribute("health.actor");else f.request.setAttribute("health.actor",attribute);
            assertEquals(403,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);
            assertEquals(403,assertThrows(ApiException.class,()->f.access.link(PATIENT,"BILLING")).status);verifyNoInteractions(f.store);
        }
    }

    @Test void missingForeignMalformedTenantAndPlatformAre403BeforeStore() {
        for(Object host:Arrays.asList(null,"forged",new TenantRef("foreign","Other","other","CLINIC","HUMAN","ACTIVE",List.of()))) {
            Fixture f=new Fixture(false,"ADM");
            if(host==null)f.request.removeAttribute("health.tenant");else f.request.setAttribute("health.tenant",host);
            assertEquals(403,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);
            assertEquals(403,assertThrows(ApiException.class,()->f.access.link(PATIENT,"DOCUMENTS")).status);verifyNoInteractions(f.store);
        }
        for(String role:List.of("SAD","SOP")) {
            Fixture f=new Fixture(false,"ADM");f.request.removeAttribute("health.tenant");
            f.setActor(new Actor(USER,"Synthetic","qa@example.test",null,List.of(role),HASH));
            assertEquals(403,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);
            assertEquals(403,assertThrows(ApiException.class,()->f.access.link(PATIENT,"APPOINTMENTS")).status);verifyNoInteractions(f.store);
        }
    }

    @Test void unrelatedTraceRequestAndForgedHttpAuthorityCannotReplaceInjectedAuthority() {
        Fixture f=new Fixture(false,"ADM");
        MockHttpServletRequest wrong=new MockHttpServletRequest();wrong.setAttribute("health.actor","forged");TraceContext.REQUEST.set(wrong);
        f.request.addHeader("X-Tenant-Id","forged");f.request.addHeader("X-Actor-Id","forged");
        f.request.addHeader("X-Roles","SAD");f.request.addHeader("X-Scope","BOOTSTRAP");
        f.request.addParameter("tenantId","forged");f.request.addParameter("userId","forged");
        f.request.setContent("{\"actorId\":\"forged\",\"tenantId\":\"forged\"}".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        f.access.branch(BRANCH);f.access.link(PATIENT,"DOCUMENTS");
        verify(f.store).branch(same(f.request),eq(BRANCH));verify(f.store).link(same(f.request),eq(PATIENT),eq("DOCUMENTS"));
        f.request.removeAttribute("health.actor");wrong.setAttribute("health.actor",f.actor);
        assertEquals(403,assertThrows(ApiException.class,()->f.access.branch(BRANCH)).status);
        verify(f.store,times(1)).branch(any(),any());
    }

    @Test void invalidIdsOrScopesFailBeforeStoreWhileValidOpaqueScopesPassUnchanged() {
        for(String id:Arrays.asList(null,"","1-1-1-1-1",BRANCH.toUpperCase(Locale.ROOT),"not-id")) {
            Fixture f=new Fixture(false,"ADM");
            assertEquals(400,assertThrows(ApiException.class,()->f.access.branch(id)).status);
            assertEquals(400,assertThrows(ApiException.class,()->f.access.link(id,"DOCUMENTS")).status);verifyNoInteractions(f.store);
        }
        for(String scope:Arrays.asList(null,""," \n\t","x".repeat(81),"\ud83e\uddb7".repeat(41))) {
            Fixture f=new Fixture(false,"ADM");
            assertEquals(400,assertThrows(ApiException.class,()->f.access.link(PATIENT,scope)).status);verifyNoInteractions(f.store);
        }
        for(String scope:List.of("DOCUMENTS","APPOINTMENTS","BILLING","documents"," Custom.Mixed ","\ud83e\uddb7".repeat(40))) {
            Fixture f=new Fixture(false,"ADM");f.access.link(PATIENT,scope);verify(f.store).link(f.request,PATIENT,scope);
        }
    }

    @Test void sqlErrorsArePreservedWithoutFallbackRetryOrSuccess() {
        for(int status:new int[]{403,404,409,500}) {
            Fixture f=new Fixture(false,"ADM");ApiException error=new ApiException(status,"SAFE_ERROR","Operacion rechazada.");
            doThrow(error).when(f.store).branch(any(),any());doThrow(error).when(f.store).link(any(),any(),any());
            assertSame(error,assertThrows(ApiException.class,()->f.access.branch(BRANCH)));
            assertSame(error,assertThrows(ApiException.class,()->f.access.link(PATIENT,"DOCUMENTS")));
            verify(f.store,times(1)).branch(any(),any());verify(f.store,times(1)).link(any(),any(),any());
        }
    }

    @Test void legacyConstructorRetainsOriginalBranch404AndAssignment403AndLink404() {
        Fixture missing=new Fixture(true,"PRO");missing.branchExists=false;
        assertEquals(404,assertThrows(ApiException.class,()->missing.access.branch(BRANCH)).status);
        Fixture unassigned=new Fixture(true,"PRO");unassigned.assignment=false;
        assertEquals(403,assertThrows(ApiException.class,()->unassigned.access.branch(BRANCH)).status);
        Fixture admin=new Fixture(true,"ADM");admin.assignment=false;admin.access.branch(BRANCH);
        verify(admin.sql,never()).optional(anyString(),any(Object[].class));
        Fixture link=new Fixture(true,"PAC");link.available=false;
        assertEquals(404,assertThrows(ApiException.class,()->link.access.link(PATIENT,"DOCUMENTS")).status);
        Fixture success=new Fixture(true,"PRO");success.access.branch(BRANCH);success.access.link(PATIENT,"BILLING");
        verify(success.sql,times(1)).one(anyString(),any(Object[].class));
        verify(success.sql,times(2)).optional(anyString(),any(Object[].class));
    }

    @ParameterizedTest @ValueSource(booleans={false,true})
    void allOtherPublicPermissionMethodsKeepExistingBehaviorWithoutStoreCalls(boolean legacy) {
        Fixture f=new Fixture(legacy,"ADM");
        assertSame(f.actor,f.access.actor());assertSame(REF,f.access.tenant());assertEquals(USER,f.access.userId());assertEquals(TENANT,f.access.tenantId());
        f.access.roles("ADM");f.access.write("CORE","ADM");f.access.module("CORE");
        assertEquals(403,assertThrows(ApiException.class,()->f.access.roles("PRO")).status);
        assertEquals("MODULE_NOT_INCLUDED",assertThrows(ApiException.class,()->f.access.module("FINANCE")).code);
        f.request.setAttribute("health.tenant",new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","SUSPENDED",List.of("CORE")));
        assertEquals("SUSPENDED",assertThrows(ApiException.class,()->f.access.write("CORE","ADM")).code);
        f.request.setAttribute("health.tenant",REF);f.request.removeAttribute("health.actor");
        assertSame(f.actor,f.access.actor());f.access.module("CORE"); // These existing methods are deliberately outside this conversion.
        f.request.removeAttribute("health.tenant");f.setActor(new Actor(USER,"Synthetic","qa@example.test",null,List.of("SAD"),HASH));f.access.platform();
        f.setActor(new Actor(USER,"Synthetic","qa@example.test",null,List.of("SOP"),HASH));
        assertEquals(403,assertThrows(ApiException.class,f.access::platform).status);
        verifyNoInteractions(f.store,f.sql);
    }

    @Test void minimalSpringContextSelectsAutowiredLegacyConstructorWithoutSqlServerStoreOrDatasource() {
        Fixture f=new Fixture(true,"ADM");
        try(AnnotationConfigApplicationContext context=new AnnotationConfigApplicationContext()) {
            context.registerBean(HttpServletRequest.class,()->f.request);context.registerBean(Sql.class,()->f.sql);
            context.registerBean(Access.class);context.refresh();
            context.getBean(Access.class).branch(BRANCH);verify(f.sql).one(anyString(),any(Object[].class));
            assertEquals(0,context.getBeanNamesForType(SqlServerAccessStore.class).length);
            assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);
        }
    }
}
