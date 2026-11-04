package com.mavric.health.identity;

import java.time.*;
import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.TransactionSystemException;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore.*;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStoreTest.ModelTransactionManager;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** Service behavior only: store/encoder/access doubles and simulated Spring transactions, no DB/app/login HTTP. */
class IdentityServiceSqlServerTest {
    private static final String ID="00000000-0000-4000-8000-000000000001",TENANT="00000000-0000-4000-8000-000000000002";
    private static final String EMAIL="qa@example.test",PASSWORD="Synthetic-Password-123",HASH="synthetic-password-hash";
    private static final Instant STORED_EXPIRY=Instant.parse("2030-11-04T12:34:56.123456Z");
    private static final TenantRef REF=new TenantRef(TENANT,"Synthetic","clinic","CLINIC","HUMAN","ACTIVE",List.of("CORE"));
    private static final Settings SETTINGS=new Settings("health.localhost","http://health.localhost",8,null);
    private final List<Fixture> fixtures=new ArrayList<>();

    final class Fixture {
        final SqlServerIdentityStore store=mock(SqlServerIdentityStore.class);
        final Access access=mock(Access.class);
        final PasswordEncoder encoder=mock(PasswordEncoder.class);
        final ModelTransactionManager manager=new ModelTransactionManager();
        final MockHttpServletRequest request=new MockHttpServletRequest("POST","/api/auth/login");
        final IdentityService service=new IdentityService(store,access,encoder,SETTINGS);
        Optional<Credentials> credentials=Optional.of(credentials(null,false,true));
        Optional<Membership> membership=Optional.of(new Membership(ID,List.of("ADM")));
        final List<String> order=new ArrayList<>();
        ApiException credentialFailure,saveFailure,failedFailure;
        String savedHash;
        Instant requestedExpiry;
        Fixture() {
            fixtures.add(this);request.setAttribute("health.tenant",REF);TraceContext.REQUEST.set(request);
            when(store.required(any())).thenAnswer(inv->manager.outer(()->inv.<Supplier<?>>getArgument(0).get()));
            when(store.credentials(any(),any())).thenAnswer(inv-> {
                assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
                order.add("credentials");if(credentialFailure!=null)throw credentialFailure;return credentials;
            });
            when(store.membership(any(),any())).thenAnswer(inv->{order.add("membership");return membership;});
            when(store.saveSession(any(),any(),any(),any())).thenAnswer(inv-> {
                assertTrue(TransactionSynchronizationManager.isActualTransactionActive());
                assertNull(request.getAttribute("health.actor"),"No candidate before persistence/commit");
                assertNull(SecurityContextHolder.getContext().getAuthentication());
                savedHash=inv.getArgument(1);requestedExpiry=inv.getArgument(3);order.add("save");
                if(saveFailure!=null)throw saveFailure;
                return new SavedSession("b".repeat(64),STORED_EXPIRY);
            });
            doAnswer(inv->{order.add("accept");return null;}).when(store).acceptInvitation(any(),any());
            doAnswer(inv->{order.add("failed");if(failedFailure!=null)throw failedFailure;return null;}).when(store).failed(any(),nullable(String.class));
            when(store.passwordHash(any())).thenReturn("stored-own-hash");
            when(encoder.matches(any(),any())).thenAnswer(inv->PASSWORD.equals(inv.getArgument(0)));
            when(encoder.encode(any())).thenReturn("encoded-hash");
        }
        void signed(String role) {
            Actor actor=new Actor(ID,"Synthetic",EMAIL,TENANT,List.of(role),"a".repeat(64));
            request.setAttribute("health.actor",actor);when(access.actor()).thenReturn(actor);
        }
        Map<String,Object> login() { return service.login(EMAIL,PASSWORD,REF,"127.0.0.1"); }
        void noSessionWriteOrActor() {
            verify(store,never()).saveSession(any(),any(),any(),any());
            assertNull(request.getAttribute("health.actor"));assertNull(SecurityContextHolder.getContext().getAuthentication());
        }
    }
    private static Credentials credentials(String platform,boolean locked,boolean verified) {
        return new Credentials(ID,"Synthetic",EMAIL,HASH,platform,verified,locked,locked?Instant.now().plusSeconds(900):null);
    }
    private static IdentityService.UserInput input(String password) {
        return new IdentityService.UserInput("  Synthetic  "," QA@EXAMPLE.TEST ",password,"HUMAN",null);
    }
    @AfterEach void cleanup() {
        try { TraceContext.REQUEST.remove(); }
        finally { SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear(); }
    }

    @Test void loginReturnsExactBearerShapeStoredExpiryAndRandomTokenWithoutCredentialOrCsrfExposure() {
        Fixture f=new Fixture();Instant before=Instant.now();
        Map<String,Object> response=f.service.login(" QA@EXAMPLE.TEST ",PASSWORD,REF,"127.0.0.1");
        assertEquals(Set.of("accessToken","tokenType","expiresAt","user"),response.keySet());
        assertEquals("Bearer",response.get("tokenType"));assertEquals(STORED_EXPIRY.toString(),response.get("expiresAt"));
        String token=(String)response.get("accessToken");assertTrue(token.matches("[A-Za-z0-9_-]{43}"));
        assertEquals(32,Base64.getUrlDecoder().decode(token).length);assertEquals(Checks.hash(token),f.savedHash);
        assertTrue(f.requestedExpiry.isAfter(before.plusSeconds(8*3600-1)));assertTrue(f.requestedExpiry.isBefore(Instant.now().plusSeconds(8*3600+1)));
        Map<?,?> user=(Map<?,?>)response.get("user");
        assertEquals(Map.of("id",ID,"name","Synthetic","email",EMAIL,"roles",List.of("ADM")),user);
        String serialized=new ObjectMapper().writeValueAsString(response);
        for(String secret:List.of(HASH,"csrfToken","passwordHash","lockedUntil","bbbbbbbb"))assertFalse(serialized.contains(secret));
        verify(f.store).credentials(f.request,EMAIL);verify(f.encoder).matches(PASSWORD,HASH);
        Actor actor=(Actor)f.request.getAttribute("health.actor");
        assertEquals(f.savedHash,actor.tokenHash());assertEquals(TENANT,actor.tenantId());assertNull(SecurityContextHolder.getContext().getAuthentication());
        assertEquals(List.of("begin:0","commit"),f.manager.events);
    }

    @Test void generatedSessionTokensAreNotReusedAcrossSuccessfulLogins() {
        Fixture f=new Fixture();String first=(String)f.login().get("accessToken");
        String second=(String)f.login().get("accessToken");assertNotEquals(first,second);
    }

    @Test void unknownLockedAndWrongPasswordShare401AndRecordOnlyKnownIdOrNull() {
        for(int mode=0;mode<3;mode++) {
            Fixture f=new Fixture();
            if(mode==0)f.credentials=Optional.empty();
            if(mode==1)f.credentials=Optional.of(credentials(null,true,true));
            final String password=mode==2?"wrong":PASSWORD;
            ApiException error=assertThrows(ApiException.class,()->f.service.login(EMAIL,password,REF,"127.0.0.1"));
            assertEquals(401,error.status);assertEquals("INVALID_CREDENTIALS",error.code);f.noSessionWriteOrActor();
            verify(f.store).failed(f.request,mode==0?null:ID);
            if(mode<2)verify(f.encoder,never()).matches(any(),any());
        }
    }

    @Test void emailUnverifiedIs403OnlyAfterCorrectPasswordAndDoesNotAddFailureCounters() {
        Fixture f=new Fixture();f.credentials=Optional.of(credentials(null,false,false));
        ApiException error=assertThrows(ApiException.class,f::login);assertEquals(403,error.status);assertEquals("EMAIL_UNVERIFIED",error.code);
        verify(f.encoder).matches(PASSWORD,HASH);verify(f.store,never()).failed(any(),nullable(String.class));f.noSessionWriteOrActor();
        Fixture wrong=new Fixture();wrong.credentials=f.credentials;
        assertEquals(401,assertThrows(ApiException.class,()->wrong.service.login(EMAIL,"wrong",REF,"127.0.0.1")).status);
        verify(wrong.store).failed(wrong.request,ID);wrong.noSessionWriteOrActor();
    }

    @Test void missingRequestOrMismatchedHostFailsBeforeAnyStoreCall() {
        Fixture missing=new Fixture();TraceContext.REQUEST.remove();
        assertEquals(500,assertThrows(ApiException.class,missing::login).status);verifyNoInteractions(missing.store);
        Fixture host=new Fixture();
        assertEquals(401,assertThrows(ApiException.class,()->host.service.login(EMAIL,PASSWORD,null,"127.0.0.1")).status);
        verifyNoInteractions(host.store);
        TenantRef other=new TenantRef("00000000-0000-4000-8000-000000000099","Other","other","CLINIC","HUMAN","ACTIVE",List.of());
        assertEquals(401,assertThrows(ApiException.class,()->host.service.accept(EMAIL,PASSWORD,other,"127.0.0.1")).status);
        verifyNoInteractions(host.store);
    }

    @Test void incompatibleMembershipAndPlatformRolesCannotCreateSessionOrRecordNewFailureCounter() {
        for(Optional<Membership> membership:List.of(Optional.<Membership>empty(),Optional.of(new Membership(ID,List.of())),
                Optional.of(new Membership(ID,List.of("SAD"))),Optional.of(new Membership(ID,List.of("UNKNOWN"))))) {
            Fixture f=new Fixture();f.membership=membership;
            assertEquals(401,assertThrows(ApiException.class,f::login).status);f.noSessionWriteOrActor();
            verify(f.store,never()).failed(any(),nullable(String.class));
        }
        Fixture platformInTenant=new Fixture();platformInTenant.credentials=Optional.of(credentials("SAD",false,true));
        assertEquals(401,assertThrows(ApiException.class,platformInTenant::login).status);
        verify(platformInTenant.store,never()).membership(any(),any());platformInTenant.noSessionWriteOrActor();
    }

    @Test void platformLoginOnlyAcceptsSadSopWithoutTenantMembership() {
        for(String role:List.of("SAD","SOP")) {
            Fixture f=new Fixture();f.request.removeAttribute("health.tenant");f.credentials=Optional.of(credentials(role,false,true));
            Map<String,Object> result=f.service.login(EMAIL,PASSWORD,null,"127.0.0.1");
            assertEquals(List.of(role),((Map<?,?>)result.get("user")).get("roles"));
            assertNull(((Actor)f.request.getAttribute("health.actor")).tenantId());verify(f.store,never()).membership(any(),any());
        }
        for(String role:Arrays.asList(null,"ADM","UNKNOWN")) {
            Fixture f=new Fixture();f.request.removeAttribute("health.tenant");f.credentials=Optional.of(credentials(role,false,true));
            assertEquals(401,assertThrows(ApiException.class,()->f.service.login(EMAIL,PASSWORD,null,"127.0.0.1")).status);f.noSessionWriteOrActor();
        }
    }

    @Test void tenthFailureIsRecordedAndEleventhIs429BeforeCredentialLookup() {
        Fixture f=new Fixture();f.credentials=Optional.empty();
        for(int i=0;i<10;i++)assertEquals(401,assertThrows(ApiException.class,f::login).status);
        ApiException limit=assertThrows(ApiException.class,f::login);assertEquals(429,limit.status);assertEquals("RATE_LIMIT",limit.code);
        verify(f.store,times(10)).credentials(f.request,EMAIL);verify(f.store,times(10)).failed(f.request,null);f.noSessionWriteOrActor();
    }

    @Test void infrastructureErrorsAreNotDisguisedAsInvalidCredentialsAndNeverRetried() {
        Fixture f=new Fixture();f.credentialFailure=new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        assertEquals(500,assertThrows(ApiException.class,f::login).status);
        verify(f.store,times(1)).credentials(any(),any());verify(f.store,never()).failed(any(),nullable(String.class));f.noSessionWriteOrActor();
        Fixture failedRecorder=new Fixture();failedRecorder.credentials=Optional.empty();
        failedRecorder.failedFailure=f.credentialFailure;
        assertEquals(500,assertThrows(ApiException.class,failedRecorder::login).status);failedRecorder.noSessionWriteOrActor();
    }

    @Test void noCandidateSurvivesSessionSaveOrCommitFailure() {
        Fixture save=new Fixture();save.saveFailure=new ApiException(409,"CONFLICT","Synthetic conflict");
        assertEquals(409,assertThrows(ApiException.class,save::login).status);
        assertNull(save.request.getAttribute("health.actor"));assertEquals(List.of("begin:0","rollback"),save.manager.events);
        Fixture commit=new Fixture();commit.manager.failCommit=true;
        ApiException error=assertThrows(ApiException.class,commit::login);
        assertEquals(500,error.status);assertEquals("DATABASE_ERROR",error.code);assertFalse(error.toString().contains("private"));
        assertNull(commit.request.getAttribute("health.actor"));assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(commit.store,times(1)).saveSession(any(),any(),any(),any());
    }

    @Test void actorPublicationWaitsForOuterTransactionCommitAndDoesNotTreatRequiredJoinAsCommit() {
        Fixture f=new Fixture();
        f.manager.outer(()-> {
            f.login();assertNull(f.request.getAttribute("health.actor"));assertFalse(f.manager.events.contains("commit"));return true;
        });
        assertNotNull(f.request.getAttribute("health.actor"));assertEquals(List.of("begin:0","commit"),f.manager.events);
    }

    @Test void outerRollbackAndOuterCommitFailureNeverPublishActorAfterServiceReturns() {
        Fixture rollback=new Fixture();
        assertThrows(ApiException.class,()->rollback.manager.outer(()-> {
            rollback.login();assertNull(rollback.request.getAttribute("health.actor"));throw new ApiException(409,"CONFLICT","Later failure");
        }));
        assertNull(rollback.request.getAttribute("health.actor"));assertEquals(List.of("begin:0","rollback"),rollback.manager.events);
        Fixture commit=new Fixture();commit.manager.failCommit=true;
        assertThrows(TransactionSystemException.class,()->commit.manager.outer(()-> {commit.login();return true;}));
        assertNull(commit.request.getAttribute("health.actor"));assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test void acceptChecksPasswordBeforeInvitationAndGroupsInvitationAndLoginInOneUnit() {
        Fixture f=new Fixture();Map<String,Object> result=f.service.accept(EMAIL,PASSWORD,REF,"127.0.0.1");
        assertEquals(List.of("credentials","accept","credentials","membership","save"),f.order);
        verify(f.encoder,times(2)).matches(PASSWORD,HASH);assertEquals(List.of("begin:0","commit"),f.manager.events);
        assertNotNull(f.request.getAttribute("health.actor"));assertEquals(STORED_EXPIRY.toString(),result.get("expiresAt"));
    }

    @Test void acceptInitialCredentialRejectionsDoNotAddLoginFailureCountersOrMutations() {
        for(boolean unknown:List.of(false,true)) {
            Fixture f=new Fixture();if(unknown)f.credentials=Optional.empty();
            assertEquals(401,assertThrows(ApiException.class,()->f.service.accept(EMAIL,"wrong",REF,"127.0.0.1")).status);
            verify(f.store,never()).acceptInvitation(any(),any());verify(f.store,never()).failed(any(),nullable(String.class));f.noSessionWriteOrActor();
        }
    }

    @Test void acceptRollsBackWhenLaterLoginEligibilityOrSaveFails() {
        Fixture save=new Fixture();save.saveFailure=new ApiException(409,"CONFLICT","Synthetic save failure");
        assertEquals(409,assertThrows(ApiException.class,()->save.service.accept(EMAIL,PASSWORD,REF,"127.0.0.1")).status);
        verify(save.store).acceptInvitation(save.request,ID);assertNull(save.request.getAttribute("health.actor"));
        assertEquals(List.of("begin:0","rollback"),save.manager.events);
        Fixture eligibility=new Fixture();
        doReturn(Optional.of(credentials(null,false,true)),Optional.of(credentials(null,true,true)))
                .when(eligibility.store).credentials(any(),any());
        assertEquals(401,assertThrows(ApiException.class,()->eligibility.service.accept(EMAIL,PASSWORD,REF,"127.0.0.1")).status);
        verify(eligibility.store).acceptInvitation(eligibility.request,ID);verify(eligibility.store).failed(eligibility.request,ID);
        eligibility.noSessionWriteOrActor();assertEquals(List.of("begin:0","rollback"),eligibility.manager.events);
    }

    @Test void administrativeCreateNormalizesValuesEnforcesPolicyAndReturnsOnlyGeneratedId() {
        Fixture f=new Fixture();f.signed("ADM");String id=f.service.create(input(PASSWORD));
        assertEquals(id,UUID.fromString(id).toString());
        verify(f.store).create(f.request,id,"Synthetic",EMAIL,"encoded-hash","HUMAN",null);
        verify(f.encoder).encode(PASSWORD);verify(f.store,never()).createForRegistration(any(),any(),any(),any(),any(),any(),any());
        Fixture policy=new Fixture();policy.signed("ADM");
        assertEquals(400,assertThrows(ApiException.class,()->policy.service.create(input("short"))).status);
        verify(policy.store,never()).create(any(),any(),any(),any(),any(),any(),any());
        Fixture anonymous=new Fixture();assertEquals(403,assertThrows(ApiException.class,()->anonymous.service.create(input(PASSWORD))).status);
        verifyNoInteractions(anonymous.store);
        Fixture sop=new Fixture();sop.signed("SOP");assertEquals(403,assertThrows(ApiException.class,()->sop.service.create(input(PASSWORD))).status);
        verifyNoInteractions(sop.store);
    }

    @Test void registrationEntryRequiresRequestExternalTransactionAndAbsenceOfActor() {
        Fixture noTx=new Fixture();
        assertEquals(500,assertThrows(ApiException.class,()->noTx.service.createForRegistration(input(PASSWORD))).status);
        verifyNoInteractions(noTx.store,noTx.encoder);
        Fixture actor=new Fixture();actor.signed("ADM");
        assertEquals(403,assertThrows(ApiException.class,()->actor.manager.outer(()->actor.service.createForRegistration(input(PASSWORD)))).status);
        verifyNoInteractions(actor.store);
        Fixture missing=new Fixture();TraceContext.REQUEST.remove();
        assertEquals(500,assertThrows(ApiException.class,()->missing.manager.outer(()->missing.service.createForRegistration(input(PASSWORD)))).status);
        verifyNoInteractions(missing.store);
    }

    @Test void registrationEntryParticipatesInExternalUnitWithoutOwnRequiredOrActorPublication() {
        Fixture f=new Fixture();
        String id=f.manager.outer(()-> {
            String result=f.service.createForRegistration(input(PASSWORD));
            assertFalse(f.manager.events.contains("commit"));assertNull(f.request.getAttribute("health.actor"));return result;
        });
        verify(f.store).createForRegistration(f.request,id,"Synthetic",EMAIL,"encoded-hash","HUMAN",null);
        verify(f.store,never()).required(any());assertEquals(List.of("begin:0","commit"),f.manager.events);
        assertNull(f.request.getAttribute("health.actor"));
    }

    @Test void logoutUsesOwnSessionAndPasswordChecksCurrentAndNextBeforeUpdate() {
        Fixture f=new Fixture();f.signed("ADM");f.service.logout();
        verify(f.store).revokeSession(f.request);
        f.service.password(PASSWORD,"Next-Synthetic-123");
        verify(f.store).passwordHash(f.request);verify(f.encoder).matches(PASSWORD,"stored-own-hash");
        verify(f.encoder).encode("Next-Synthetic-123");verify(f.store).changePassword(f.request,"encoded-hash");
        Fixture wrong=new Fixture();wrong.signed("ADM");
        assertEquals(401,assertThrows(ApiException.class,()->wrong.service.password("wrong","Next-Synthetic-123")).status);
        verify(wrong.store,never()).changePassword(any(),any());verify(wrong.store,never()).failed(any(),nullable(String.class));
        Fixture policy=new Fixture();policy.signed("ADM");
        assertEquals(400,assertThrows(ApiException.class,()->policy.service.password(PASSWORD,"short")).status);
        verify(policy.store,never()).changePassword(any(),any());
    }

    @Test void legacyConstructorIsStillSelectedByMinimalSpringContextAndRegistrationCannotUseIt() {
        Sql sql=mock(Sql.class);Access access=mock(Access.class);AttemptRecorder recorder=mock(AttemptRecorder.class);
        PasswordEncoder encoder=mock(PasswordEncoder.class);when(encoder.encode(any())).thenReturn("legacy-hash");
        try(AnnotationConfigApplicationContext context=new AnnotationConfigApplicationContext()) {
            context.registerBean(Sql.class,()->sql);context.registerBean(Access.class,()->access);
            context.registerBean(AttemptRecorder.class,()->recorder);context.registerBean(PasswordEncoder.class,()->encoder);
            context.registerBean(Settings.class,()->SETTINGS);context.registerBean(IdentityService.class);
            context.refresh();
            IdentityService service=context.getBean(IdentityService.class);
            String id=service.create(input(PASSWORD));
            verify(sql).call("sp_user_create",id,"Synthetic",EMAIL,"legacy-hash","HUMAN",null);
            assertEquals(500,assertThrows(ApiException.class,()->service.createForRegistration(input(PASSWORD))).status);
            assertEquals(0,context.getBeanNamesForType(javax.sql.DataSource.class).length);
            assertEquals(0,context.getBeanNamesForType(SqlServerIdentityStore.class).length);
        }
        verifyNoInteractions(recorder);
    }
}
