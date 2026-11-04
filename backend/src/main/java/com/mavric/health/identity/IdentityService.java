package com.mavric.health.identity;

import java.security.SecureRandom;
import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import jakarta.servlet.http.HttpServletRequest;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore;
import com.mavric.health.persistence.sqlserver.SqlServerErrors;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;

@Service
public class IdentityService {
    private final Sql sql; private final Access access; private final PasswordEncoder passwords; private final Settings settings; private final AttemptRecorder attemptsRecorder;
    private final SqlServerIdentityStore identityStore;
    private static final Set<String> TENANT_ROLES=Set.of("ADM","REC","PRO","ASI","DIA","FAR","CAJ","ALM","PAC","RES","AUD");
    private final SecureRandom random=new SecureRandom(); private final ConcurrentHashMap<String,Window> attempts=new ConcurrentHashMap<>();
    private record Window(long start,int count) { }
    @Autowired
    public IdentityService(Sql sql,Access access,PasswordEncoder passwords,Settings settings,AttemptRecorder attemptsRecorder) { this.sql=sql; this.access=access; this.passwords=passwords; this.settings=settings; this.attemptsRecorder=attemptsRecorder;this.identityStore=null; }
    public IdentityService(SqlServerIdentityStore identityStore,Access access,PasswordEncoder passwords,Settings settings) {
        this.sql=null;this.attemptsRecorder=null;this.identityStore=Objects.requireNonNull(identityStore);
        this.access=Objects.requireNonNull(access);this.passwords=Objects.requireNonNull(passwords);this.settings=Objects.requireNonNull(settings);
    }
    public String create(UserInput input) {
        if(identityStore!=null) {
            HttpServletRequest request=signedRequest();
            if(Collections.disjoint(((Actor)request.getAttribute("health.actor")).roles(),List.of("SAD","ADM"))) throw ApiException.forbidden();
            return identityStore.required(()->createSql(request,input,false));
        }
        Checks.password(input.password()); String id=Checks.id();
        sql.call("sp_user_create",id,input.name().trim(),input.email().toLowerCase(Locale.ROOT).trim(),passwords.encode(input.password()),input.domain(),input.credential());
        return id;
    }
    /** Server-only entry for the future complete registration unit. Never selected from HTTP data. */
    public String createForRegistration(UserInput input) {
        if(identityStore==null) throw databaseError();
        HttpServletRequest request=request();
        if(request.getAttribute("health.actor")!=null) throw ApiException.forbidden();
        if(!TransactionSynchronizationManager.isActualTransactionActive()) throw databaseError();
        return createSql(request,input,true); // store enforces MANDATORY, never manufactures an independent TX
    }
    public record UserInput(@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max=160) String name,@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Email @jakarta.validation.constraints.Size(max=254) String email,@jakarta.validation.constraints.NotBlank String password,@jakarta.validation.constraints.Pattern(regexp="HUMAN|ANIMAL") String domain,@jakarta.validation.constraints.Size(max=100) String credential) { }
    /** Internal only: the controller builds an explicit HTTP projection, never serializes this result. */
    public record BrowserUser(String id,String name,String email,List<String> roles) {
        public BrowserUser { roles=List.copyOf(roles); }
        @Override public String toString() { return "BrowserUser[redacted]"; }
    }
    public record BrowserLogin(String token,BrowserUser user,Instant expiresAt,String csrfToken) {
        public BrowserLogin {
            if(token==null || !token.matches("[A-Za-z0-9_-]{43}") || user==null
                    || user.id()==null || user.name()==null || user.email()==null
                    || expiresAt==null || expiresAt.getNano()%1000!=0
                    || csrfToken==null || !csrfToken.matches("[0-9a-fA-F]{64}")) throw databaseError();
        }
        @Override public String toString() { return "BrowserLogin[redacted]"; }
    }
    @Transactional public BrowserLogin loginBrowser(String email,String password,TenantRef tenant,String address) {
        if(identityStore==null) throw databaseError();
        HttpServletRequest request=hostRequest(tenant);
        request.removeAttribute("health.actor");
        try { return identityStore.required(()->loginSql(email,password,tenant,address,request)); }
        catch(RuntimeException error) { request.removeAttribute("health.actor");throw SqlServerErrors.map(error); }
    }
    @Transactional public Map<String,Object> login(String email,String password,TenantRef tenant,String address) {
        if(identityStore!=null) {
            HttpServletRequest request=hostRequest(tenant);
            request.removeAttribute("health.actor");
            try { return identityStore.required(()->bearer(loginSql(email,password,tenant,address,request))); }
            catch(RuntimeException error) { request.removeAttribute("health.actor");throw SqlServerErrors.map(error); }
        }
        limit(Checks.hash(address+":"+(tenant==null?"platform":tenant.id())+":"+email.toLowerCase(Locale.ROOT)));
        var user=sql.optional("SELECT id,name,email,password_hash,platform_role,email_verified,locked_until,locked_until>UTC_TIMESTAMP(6) locked FROM users WHERE email=? AND active",email.toLowerCase(Locale.ROOT).trim());
        if(user.isEmpty() || Boolean.TRUE.equals(user.get().get("locked")) || ((Number) (user.get().get("locked") instanceof Number?user.get().get("locked"):0)).intValue()==1 || !passwords.matches(password,user.get().get("passwordHash").toString())) { attemptsRecorder.failed(user.map(u->u.get("id").toString()).orElse(null),tenant==null?null:tenant.id()); throw rejected(); }
        if(!Boolean.TRUE.equals(user.get().get("emailVerified"))) throw new ApiException(403,"EMAIL_UNVERIFIED","Verifica tu correo antes de iniciar sesión.");
        String id=user.get().get("id").toString(); List<String> roles;
        if(tenant==null) { Object role=user.get().get("platformRole"); if(role==null) throw rejected(); roles=List.of(role.toString()); }
        else roles=sql.strings(sql.optional("SELECT roles FROM memberships WHERE tenant_id=? AND user_id=? AND status='ACTIVE'",tenant.id(),id).orElseThrow(IdentityService::rejected).get("roles"));
        byte[] bytes=new byte[32]; random.nextBytes(bytes); String token=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes); Instant expiry=Instant.now().plus(settings.sessionHours(),java.time.temporal.ChronoUnit.HOURS);
        var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request!=null) request.setAttribute("health.actor",new Actor(id,user.get().get("name").toString(),user.get().get("email").toString(),tenant==null?null:tenant.id(),roles,Checks.hash(token)));
        sql.call("sp_session_save",Checks.hash(token),id,tenant==null?null:tenant.id(),expiry);
        return Map.of("accessToken",token,"tokenType","Bearer","expiresAt",expiry.toString(),"user",Map.of("id",id,"name",user.get().get("name"),"email",user.get().get("email"),"roles",roles));
    }
    @Transactional public void logout() {
        if(identityStore!=null) { identityStore.revokeSession(signedRequest());return; }
        sql.call("sp_session_end",access.actor().tokenHash(),access.userId());
    }
    @Transactional public Map<String,Object> accept(String email,String password,TenantRef tenant,String address) {
        if(identityStore!=null) {
            HttpServletRequest request=hostRequest(tenant);
            if(tenant==null) throw rejected();
            request.removeAttribute("health.actor");
            try {
                return identityStore.required(()-> {
                    limit(Checks.hash(address+":invite:"+tenant.id()+":"+email.toLowerCase(Locale.ROOT)));
                    var user=identityStore.credentials(request,normalized(email)).orElseThrow(IdentityService::rejected);
                    if(!passwords.matches(password,user.passwordHash())) throw rejected();
                    identityStore.acceptInvitation(request,user.id());
                    return bearer(loginSql(email,password,tenant,address,request));
                });
            } catch(RuntimeException error) { request.removeAttribute("health.actor");throw SqlServerErrors.map(error); }
        }
        if(tenant==null) throw rejected();
        limit(Checks.hash(address+":invite:"+tenant.id()+":"+email.toLowerCase(Locale.ROOT)));
        var user=sql.optional("SELECT id,password_hash FROM users WHERE email=? AND active",email.toLowerCase(Locale.ROOT).trim()).orElseThrow(IdentityService::rejected);
        if(!passwords.matches(password,user.get("passwordHash").toString())) throw rejected();
        sql.call("sp_invitation_accept",tenant.id(),user.get("id"));
        return login(email,password,tenant,address);
    }
    @Transactional public void password(String current,String next) {
        if(identityStore!=null) {
            HttpServletRequest request=signedRequest();
            identityStore.required(()-> {
                String hash=identityStore.passwordHash(request);
                if(!passwords.matches(current,hash)) throw rejected();
                Checks.password(next);identityStore.changePassword(request,passwords.encode(next));
                return Boolean.TRUE;
            });
            return;
        }
        var user=sql.one("SELECT password_hash FROM users WHERE id=?",access.userId()); if(!passwords.matches(current,user.get("passwordHash").toString())) throw rejected();
        Checks.password(next); sql.call("sp_password_change",access.userId(),passwords.encode(next));
    }
    private String createSql(HttpServletRequest request,UserInput input,boolean registration) {
        Checks.password(input.password());
        String id=Checks.id(),hash=passwords.encode(input.password());
        if(registration) identityStore.createForRegistration(request,id,input.name().trim(),normalized(input.email()),hash,input.domain(),input.credential());
        else identityStore.create(request,id,input.name().trim(),normalized(input.email()),hash,input.domain(),input.credential());
        return id;
    }
    private BrowserLogin loginSql(String email,String password,TenantRef tenant,String address,HttpServletRequest request) {
        limit(Checks.hash(address+":"+(tenant==null?"platform":tenant.id())+":"+email.toLowerCase(Locale.ROOT)));
        var found=identityStore.credentials(request,normalized(email));
        if(found.isEmpty() || found.get().locked() || !passwords.matches(password,found.get().passwordHash())) {
            identityStore.failed(request,found.map(SqlServerIdentityStore.Credentials::id).orElse(null));
            throw rejected();
        }
        var user=found.get();
        if(!user.emailVerified()) throw new ApiException(403,"EMAIL_UNVERIFIED","Verifica tu correo antes de iniciar sesión.");
        List<String> roles;
        if(tenant==null) {
            if(user.platformRole()==null || !Set.of("SAD","SOP").contains(user.platformRole())) throw rejected();
            roles=List.of(user.platformRole());
        } else {
            if(user.platformRole()!=null) throw rejected();
            roles=identityStore.membership(request,user.id()).orElseThrow(IdentityService::rejected).roles();
            if(roles.isEmpty() || !TENANT_ROLES.containsAll(roles)) throw rejected();
        }
        byte[] bytes=new byte[32];random.nextBytes(bytes);
        String token=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes),hash=Checks.hash(token);
        Instant expiry=Instant.now().plus(settings.sessionHours(),java.time.temporal.ChronoUnit.HOURS);
        var saved=identityStore.saveSession(request,hash,user.id(),expiry);
        BrowserLogin result=new BrowserLogin(token,new BrowserUser(user.id(),user.name(),user.email(),roles),saved.expiresAt(),saved.csrfToken());
        Actor actor=new Actor(user.id(),user.name(),user.email(),tenant==null?null:tenant.id(),roles,hash);
        publishAfterCommit(request,actor);
        return result;
    }
    private static Map<String,Object> bearer(BrowserLogin result) {
        BrowserUser user=result.user();
        return Map.of("accessToken",result.token(),"tokenType","Bearer","expiresAt",result.expiresAt().toString(),
                "user",Map.of("id",user.id(),"name",user.name(),"email",user.email(),"roles",user.roles()));
    }
    private static void publishAfterCommit(HttpServletRequest request,Actor actor) {
        if(!TransactionSynchronizationManager.isActualTransactionActive()
                || !TransactionSynchronizationManager.isSynchronizationActive()) throw databaseError();
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { request.setAttribute("health.actor",actor); }
            @Override public void afterCompletion(int status) {
                if(status!=STATUS_COMMITTED && request.getAttribute("health.actor")==actor) request.removeAttribute("health.actor");
            }
        });
    }
    private static String normalized(String email) { return email.toLowerCase(Locale.ROOT).trim(); }
    private static HttpServletRequest request() {
        HttpServletRequest request=TraceContext.REQUEST.get();
        if(request==null) throw databaseError();
        return request;
    }
    private static HttpServletRequest hostRequest(TenantRef tenant) {
        HttpServletRequest request=request();
        Object host=request.getAttribute("health.tenant");
        if(host!=null && !(host instanceof TenantRef)) throw databaseError();
        if(!Objects.equals(tenant,host)) throw rejected();
        return request;
    }
    private HttpServletRequest signedRequest() {
        HttpServletRequest request=request();
        if(!(request.getAttribute("health.actor") instanceof Actor actor) || !actor.equals(access.actor())) throw ApiException.forbidden();
        return request;
    }
    private static ApiException databaseError() { return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos."); }
    private void limit(String key) {
        long now=System.currentTimeMillis(); if(attempts.size()>10000) { attempts.entrySet().removeIf(e->now-e.getValue().start()>60000); if(attempts.size()>10000) throw new ApiException(429,"RATE_LIMIT","Intenta nuevamente en un minuto."); }
        Window result=attempts.compute(key,(k,v)->v==null || now-v.start()>60000?new Window(now,1):new Window(v.start(),v.count()+1));
        if(result.count()>10) throw new ApiException(429,"RATE_LIMIT","Demasiados intentos. Intenta nuevamente en un minuto.");
    }
    private static ApiException rejected() { return new ApiException(401,"INVALID_CREDENTIALS","La cuenta o el acceso a este espacio no son válidos."); }
}
