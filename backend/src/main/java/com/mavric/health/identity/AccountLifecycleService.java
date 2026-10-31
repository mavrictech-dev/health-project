package com.mavric.health.identity;
import java.time.*;
import java.util.*;
import java.security.SecureRandom;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import jakarta.validation.constraints.*;
@Service
public class AccountLifecycleService {
    public record Register(@NotBlank @Size(max=160) String name,@NotBlank @Email @Size(max=254) String email,@NotBlank String password,@Pattern(regexp="DOCTOR|CLINIC|HOSPITAL|VETERINARY|DENTAL|SPECIALTY_CENTER") String kind,@Pattern(regexp="HUMAN|ANIMAL") String domain,@Size(max=160) String organizationName,@Size(max=63) String slug,String planId,String specialtyCode,boolean acceptTerms) {}
    private final Sql sql;private final IdentityService identity;private final Settings settings;private final PasswordEncoder passwords;
    private final java.util.concurrent.ConcurrentHashMap<String,Long> rate=new java.util.concurrent.ConcurrentHashMap<>();
    public AccountLifecycleService(Sql sql,IdentityService identity,Settings settings,PasswordEncoder passwords) {this.sql=sql;this.identity=identity;this.settings=settings;this.passwords=passwords;}
    public void rate(String address,String operation) {long now=System.currentTimeMillis();if(rate.size()>10000) rate.entrySet().removeIf(e->e.getValue()<now);if(rate.size()>10000) throw new ApiException(429,"RATE_LIMIT","Intenta más tarde.");String key=Checks.hash(address+operation);Long previous=rate.putIfAbsent(key,now+5000);if(previous!=null && previous>now) throw new ApiException(429,"RATE_LIMIT","Espera unos segundos antes de volver a intentarlo.");rate.put(key,now+5000);}
    public Map<String,Object> options(TenantRef tenant) {if(tenant!=null) return Map.of("portal",true);return Map.of("plans",sql.rows("SELECT p.id,p.name,v.kinds,v.domains,v.included_branches,v.included_professionals,v.included_specialties,v.base_minor FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.status='PUBLISHED' ORDER BY v.base_minor"),"specialties",sql.rows("SELECT code,name,domain,dental FROM specialties ORDER BY name"));}
    @Transactional public void register(Register p,TenantRef tenant) {
        Checks.password(p.password());if(!p.acceptTerms()) throw ApiException.invalid("Confirma las condiciones de creación de cuenta.");
        if(sql.optional("SELECT id FROM users WHERE email=?",p.email().trim().toLowerCase(Locale.ROOT)).isPresent()) return;
        String u=identity.create(new IdentityService.UserInput(p.name(),p.email(),p.password(),tenant==null && "DOCTOR".equals(p.kind())?p.domain():null,null));String target=tenant==null?null:tenant.id();
        sql.call("sp_identity_pending",u);
        if(tenant!=null) sql.call("sp_portal_register",tenant.id(),u);
        else {
            if(p.kind()==null || p.domain()==null || p.organizationName()==null || p.organizationName().isBlank()) throw ApiException.invalid("Completa el tipo y nombre de tu espacio.");DomainRules.slug(p.slug());
            if((p.kind().equals("VETERINARY") && !p.domain().equals("ANIMAL")) || (!Set.of("DOCTOR","VETERINARY").contains(p.kind()) && !p.domain().equals("HUMAN"))) throw ApiException.invalid("Ámbito incompatible con el tipo de cliente.");
            var plan=sql.one("SELECT p.id,v.included_branches,v.included_professionals,v.included_specialties FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.id=? AND p.status='PUBLISHED'",Checks.id(p.planId()));
            target=Checks.id();Map<String,Object> data=Map.of("name",p.organizationName(),"slug",p.slug(),"kind",p.kind(),"domain",p.domain(),"timezone","America/Lima","branchName","Sede principal","address","","specialties",List.of(Objects.toString(p.specialtyCode(),"")),"subscription",Map.of("planId",p.planId(),"cycle","MONTHLY","branchQuota",plan.get("includedBranches"),"professionalQuota",plan.get("includedProfessionals"),"specialtyQuota",plan.get("includedSpecialties")));
            sql.call("sp_tenant_create",target,Checks.id(),u,u,sql.json(data));tenant=new TenantRef(target,p.organizationName(),p.slug(),p.kind(),p.domain(),"TRIAL",List.of());
        }
        issue(u,p.email(),tenant,"VERIFY");
    }
    @Transactional public void request(String email,TenantRef tenant,String purpose) {
        var user=sql.optional("SELECT id,email,email_verified,platform_role FROM users WHERE email=? AND active",email.trim().toLowerCase(Locale.ROOT));if(user.isEmpty()) return;String u=user.get().get("id").toString();
        if(tenant==null && user.get().get("platformRole")==null || tenant!=null && sql.optional("SELECT user_id FROM memberships WHERE tenant_id=? AND user_id=? AND status<>'INACTIVE'",tenant.id(),u).isEmpty()) return;
        if(purpose.equals("RESET") && !Boolean.TRUE.equals(user.get().get("emailVerified"))) return;
        issue(u,user.get().get("email").toString(),tenant,purpose);
    }
    private void issue(String u,String email,TenantRef tenant,String purpose) {
        byte[] random=new byte[32];new SecureRandom().nextBytes(random);String token=Base64.getUrlEncoder().withoutPadding().encodeToString(random);
        String origin=tenant==null?settings.publicOrigin():settings.tenantUrl(tenant.slug());String link=origin+(purpose.equals("VERIFY")?"/verificar/":"/restablecer/")+"#token="+token;
        sql.call("sp_identity_issue",Checks.hash(token),u,tenant==null?null:tenant.id(),purpose,Instant.now().plusSeconds(purpose.equals("RESET")?1800:86400),Checks.id(),email,purpose.equals("RESET")?"Recupera tu acceso a Health Project":"Verifica tu cuenta de Health Project","Health Project\n\n"+(purpose.equals("RESET")?"Restablece tu contraseña":"Confirma tu correo")+":\n"+link+"\n\nEl enlace es de un solo uso. Si no solicitaste este mensaje, puedes ignorarlo.\nMavric Technologies · https://mavrictec.com");
    }
    @Transactional public void redeem(String token,String password,TenantRef tenant,String purpose) {if(token==null || !token.matches("[A-Za-z0-9_-]{43}")) throw ApiException.invalid("Enlace no válido.");if(purpose.equals("RESET")) Checks.password(password);sql.call("sp_identity_redeem",Checks.hash(token),tenant==null?null:tenant.id(),purpose,purpose.equals("RESET")?passwords.encode(password):null);}
}
