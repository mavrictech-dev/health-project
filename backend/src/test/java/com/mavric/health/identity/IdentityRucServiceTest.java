package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore;
import com.mavric.health.shared.ApiException;
import com.mavric.health.tenancy.TenantRef;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** API/service models only, not real SQL login or authorization. */
class IdentityRucServiceTest {
    static final String RUC="00000000001",EMAIL="qa@example.test",PASSWORD="Synthetic-Password-123";
    @AfterEach void clean(){TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}
    IdentityServiceSqlServerTest.Fixture fixture(){var owner=new IdentityServiceSqlServerTest();return owner.new Fixture();}
    @Test void tenantLoginLocksRucBeforeCredentialMembershipAndSessionInSameUnit(){
        var f=fixture();var tenant=(TenantRef)f.request.getAttribute("health.tenant");var result=f.service.login(RUC,EMAIL,PASSWORD,tenant,"192.0.2.1");
        var order=inOrder(f.store);order.verify(f.store).required(any());order.verify(f.store).lockTenantRuc(f.request,RUC);order.verify(f.store).credentials(f.request,EMAIL);order.verify(f.store).membership(eq(f.request),anyString());order.verify(f.store).saveSession(eq(f.request),anyString(),anyString(),any(),eq(RUC));
        assertTrue(result.containsKey("accessToken"));assertEquals(tenant.id(),((Actor)f.request.getAttribute("health.actor")).tenantId());assertEquals(List.of("begin:0","commit"),f.manager.events);
    }
    @Test void wrongRucIsGenericAndDoesNotReadCredentialsOrCreateSession(){
        var f=fixture();var tenant=(TenantRef)f.request.getAttribute("health.tenant");when(f.store.lockTenantRuc(any(),any())).thenReturn(false);
        var error=assertThrows(ApiException.class,()->f.service.login("00000000002",EMAIL,PASSWORD,tenant,"192.0.2.1"));assertEquals(401,error.status);assertFalse(error.getMessage().contains("RUC"));
        verify(f.store,never()).credentials(any(),any());verify(f.store).failed(f.request,null);verify(f.store,never()).saveSession(any(),any(),any(),any(),any());assertNull(f.request.getAttribute("health.actor"));
    }
    @Test void oldTenantLoginWithoutRucFailsBeforePersistenceAndPlatformRemainsSeparate(){
        var f=fixture();var tenant=(TenantRef)f.request.getAttribute("health.tenant");assertEquals(400,assertThrows(ApiException.class,()->f.service.login(EMAIL,PASSWORD,tenant,"192.0.2.1")).status);verifyNoInteractions(f.store);
        f.request.removeAttribute("health.tenant");assertEquals(401,assertThrows(ApiException.class,()->f.service.login(RUC,EMAIL,PASSWORD,null,"192.0.2.1")).status);verifyNoInteractions(f.store);
        f.credentials=Optional.of(new SqlServerIdentityStore.Credentials("00000000-0000-4000-8000-000000000001","Synthetic",EMAIL,"hash","SAD",true,false,null));
        f.service.login(EMAIL,PASSWORD,null,"192.0.2.1");verify(f.store,never()).lockTenantRuc(any(),any());verify(f.store).saveSession(eq(f.request),anyString(),anyString(),any(),isNull());
    }
    @Test void invitationUsesServerHostRucWithoutChangingInvitationInput(){
        var f=fixture();var tenant=(TenantRef)f.request.getAttribute("health.tenant");f.service.accept(EMAIL,PASSWORD,tenant,"192.0.2.1");verify(f.store).acceptInvitation(eq(f.request),anyString());verify(f.store).lockTenantRuc(f.request,tenant.ruc());
    }
    @Test void centralResolutionHasNoPasswordOrSessionAndRejectsTenantHost(){
        var f=fixture();assertEquals(403,assertThrows(ApiException.class,()->f.service.tenantSpace(RUC,"192.0.2.1")).status);verifyNoInteractions(f.store);
        f.request.removeAttribute("health.tenant");when(f.store.tenantSpace(any(),any(),any())).thenReturn("clinic.health.localhost");assertEquals(Map.of("hostname","clinic.health.localhost"),f.service.tenantSpace(RUC,"192.0.2.1"));verify(f.store).tenantSpace(f.request,RUC,"health.localhost");verify(f.store,never()).credentials(any(),any());verify(f.store,never()).saveSession(any(),any(),any(),any(),any());assertNull(f.request.getAttribute("health.actor"));
    }
    @Test void resolutionRateLimitStopsBeforeFurtherRpc(){
        var f=fixture();f.request.removeAttribute("health.tenant");when(f.store.tenantSpace(any(),any(),any())).thenReturn("clinic.health.localhost");
        for(int i=0;i<10;i++)f.service.tenantSpace(RUC,"192.0.2.1");assertEquals(429,assertThrows(ApiException.class,()->f.service.tenantSpace(RUC,"192.0.2.1")).status);verify(f.store,times(10)).tenantSpace(any(),any(),any());
    }
}
