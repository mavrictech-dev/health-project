package com.mavric.health.identity;

import java.security.SecureRandom;
import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;

@Service
public class IdentityService {
    private final Sql sql; private final Access access; private final PasswordEncoder passwords; private final Settings settings; private final AttemptRecorder attemptsRecorder;
    private final SecureRandom random=new SecureRandom(); private final ConcurrentHashMap<String,Window> attempts=new ConcurrentHashMap<>();
    private record Window(long start,int count) { }
    public IdentityService(Sql sql,Access access,PasswordEncoder passwords,Settings settings,AttemptRecorder attemptsRecorder) { this.sql=sql; this.access=access; this.passwords=passwords; this.settings=settings; this.attemptsRecorder=attemptsRecorder; }
    public String create(UserInput input) {
        Checks.password(input.password()); String id=Checks.id();
        sql.call("sp_user_create",id,input.name().trim(),input.email().toLowerCase(Locale.ROOT).trim(),passwords.encode(input.password()),input.domain(),input.credential());
        return id;
    }
    public record UserInput(@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max=160) String name,@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Email @jakarta.validation.constraints.Size(max=254) String email,@jakarta.validation.constraints.NotBlank String password,@jakarta.validation.constraints.Pattern(regexp="HUMAN|ANIMAL") String domain,@jakarta.validation.constraints.Size(max=100) String credential) { }
    @Transactional public Map<String,Object> login(String email,String password,TenantRef tenant,String address) {
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
    @Transactional public void logout() { sql.call("sp_session_end",access.actor().tokenHash(),access.userId()); }
    @Transactional public Map<String,Object> accept(String email,String password,TenantRef tenant,String address) {
        if(tenant==null) throw rejected();
        limit(Checks.hash(address+":invite:"+tenant.id()+":"+email.toLowerCase(Locale.ROOT)));
        var user=sql.optional("SELECT id,password_hash FROM users WHERE email=? AND active",email.toLowerCase(Locale.ROOT).trim()).orElseThrow(IdentityService::rejected);
        if(!passwords.matches(password,user.get("passwordHash").toString())) throw rejected();
        sql.call("sp_invitation_accept",tenant.id(),user.get("id"));
        return login(email,password,tenant,address);
    }
    @Transactional public void password(String current,String next) {
        var user=sql.one("SELECT password_hash FROM users WHERE id=?",access.userId()); if(!passwords.matches(current,user.get("passwordHash").toString())) throw rejected();
        Checks.password(next); sql.call("sp_password_change",access.userId(),passwords.encode(next));
    }
    private void limit(String key) {
        long now=System.currentTimeMillis(); if(attempts.size()>10000) { attempts.entrySet().removeIf(e->now-e.getValue().start()>60000); if(attempts.size()>10000) throw new ApiException(429,"RATE_LIMIT","Intenta nuevamente en un minuto."); }
        Window result=attempts.compute(key,(k,v)->v==null || now-v.start()>60000?new Window(now,1):new Window(v.start(),v.count()+1));
        if(result.count()>10) throw new ApiException(429,"RATE_LIMIT","Demasiados intentos. Intenta nuevamente en un minuto.");
    }
    private static ApiException rejected() { return new ApiException(401,"INVALID_CREDENTIALS","La cuenta o el acceso a este espacio no son válidos."); }
}
