package com.mavric.health.identity;
import java.time.*;
import org.springframework.beans.factory.annotation.Autowired;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerAccountLifecycleStore;
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
    public record Register(@NotBlank @Size(max=160) String name,@NotBlank @Email @Size(max=254) String email,@NotBlank String password,@Pattern(regexp="DOCTOR|CLINIC|HOSPITAL|VETERINARY|DENTAL|SPECIALTY_CENTER") String kind,@Pattern(regexp="HUMAN|ANIMAL") String domain,@Size(max=160) String organizationName,@Size(max=63) String slug,String planId,String specialtyCode,boolean acceptTerms,
        @tools.jackson.databind.annotation.JsonDeserialize(using=RucRequests.Text.class) String ruc) {
        public Register(String name,String email,String password,String kind,String domain,String organizationName,String slug,String planId,String specialtyCode,boolean acceptTerms){this(name,email,password,kind,domain,organizationName,slug,planId,specialtyCode,acceptTerms,null);}
        @Override public String toString(){return "Registration[redacted]";}
    }
    private final SqlServerAccountLifecycleStore sqlServer;private final Sql sql;private final IdentityService identity;private final Settings settings;private final PasswordEncoder passwords;
    private final java.util.concurrent.ConcurrentHashMap<String,Long> rate=new java.util.concurrent.ConcurrentHashMap<>();
    @Autowired public AccountLifecycleService(Sql sql,IdentityService identity,Settings settings,PasswordEncoder passwords) {this.sqlServer=null;this.sql=sql;this.identity=identity;this.settings=settings;this.passwords=passwords;}
    public AccountLifecycleService(SqlServerAccountLifecycleStore store,IdentityService identity,Settings settings,PasswordEncoder passwords) {this.sqlServer=Objects.requireNonNull(store);this.sql=null;this.identity=identity;this.settings=settings;this.passwords=passwords;}
    private static ApiException unavailable() {return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private Map<String,Object> sqlOptions(TenantRef tenant) {
        var request=validatedRequest(tenant);
        return tenant!=null?Map.of("portal",true):sqlServer.options(request);
    }
    private jakarta.servlet.http.HttpServletRequest validatedRequest(TenantRef tenant) {
        var request=TraceContext.REQUEST.get();
        if(request==null) throw unavailable();
        Object host=request.getAttribute("health.tenant");
        if(host!=null && !(host instanceof TenantRef)) throw unavailable();
        if(!Objects.equals(host,tenant)) throw ApiException.forbidden();
        return request;
    }
    public void rate(String address,String operation) {long now=System.currentTimeMillis();if(rate.size()>10000) rate.entrySet().removeIf(e->e.getValue()<now);if(rate.size()>10000) throw new ApiException(429,"RATE_LIMIT","Intenta más tarde.");String key=Checks.hash(address+operation);Long previous=rate.putIfAbsent(key,now+5000);if(previous!=null && previous>now) throw new ApiException(429,"RATE_LIMIT","Espera unos segundos antes de volver a intentarlo.");rate.put(key,now+5000);}
    public Map<String,Object> options(TenantRef tenant) {if(sqlServer!=null) return sqlOptions(tenant);if(tenant!=null) return Map.of("portal",true);return Map.of("plans",sql.rows("SELECT p.id,p.name,v.kinds,v.domains,v.included_branches,v.included_professionals,v.included_specialties,v.base_minor FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.status='PUBLISHED' ORDER BY v.base_minor"),"specialties",sql.rows("SELECT code,name,domain,dental FROM specialties ORDER BY name"));}
    @Transactional public void register(Register p,TenantRef tenant) {
        if(sqlServer!=null) {registerSql(p,tenant);return;}
        if(tenant==null)throw unavailable();
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
        if(sqlServer!=null) {requestSql(email,tenant,purpose);return;}
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
    @Transactional public void redeem(String token,String password,TenantRef tenant,String purpose) {if(sqlServer!=null) {redeemSql(token,password,tenant,purpose);return;}if(token==null || !token.matches("[A-Za-z0-9_-]{43}")) throw ApiException.invalid("Enlace no válido.");if(purpose.equals("RESET")) Checks.password(password);sql.call("sp_identity_redeem",Checks.hash(token),tenant==null?null:tenant.id(),purpose,purpose.equals("RESET")?passwords.encode(password):null);}
    private void registerSql(Register input,TenantRef tenant) {
        var request=validatedRequest(tenant);
        var authentication=org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if(request.getAttribute("health.actor")!=null || authentication!=null && authentication.getPrincipal() instanceof Actor) throw ApiException.forbidden();
        if(input==null || input.name()==null || input.name().isBlank() || input.name().length()>160
                || input.email()==null || input.email().isBlank() || input.email().length()>254) throw ApiException.invalid("Datos de cuenta no validos.");
        Checks.password(input.password());
        if(!input.acceptTerms()) throw ApiException.invalid("Confirma las condiciones de creacion de cuenta.");
        if(tenant==null)com.mavric.health.shared.Ruc.require(input.ruc());
        var organization=tenant==null?new SqlServerAccountLifecycleStore.RegistrationOrganization(input.organizationName(),input.slug(),input.kind(),input.domain(),input.planId(),input.specialtyCode(),input.ruc()):null;
        String email=input.email().trim().toLowerCase(Locale.ROOT);
        sqlServer.required(()-> {
            if(sqlServer.emailExists(request,email)) return null;
            var plan=tenant==null?sqlServer.registrationPlan(request,organization.planId()):null;
            String user=identity.createForRegistration(new IdentityService.UserInput(input.name().trim(),email,input.password(),tenant==null && "DOCTOR".equals(organization.kind())?organization.domain():null,null));
            try {if(user==null || !UUID.fromString(user).toString().equals(user)) throw unavailable();}
            catch(IllegalArgumentException malformed) {throw unavailable();}
            sqlServer.pending(request,user);
            if(tenant!=null) {
                sqlServer.portalRegister(request,user);
                issueSql(request,user,tenant,"VERIFY");
            } else {
                var created=sqlServer.createRegistrationTenant(request,Checks.id(),Checks.id(),user,organization,plan);
                issueSql(request,user,null,"VERIFY",created);
            }
            return null;
        });
    }
    private static void validPurpose(String purpose) {if(!"VERIFY".equals(purpose) && !"RESET".equals(purpose)) throw ApiException.invalid("Solicitud no valida.");}
    private void requestSql(String email,TenantRef tenant,String purpose) {
        var request=validatedRequest(tenant);validPurpose(purpose);
        if(email==null || email.isBlank() || email.length()>254) throw ApiException.invalid("Correo no valido.");
        String normalized=email.trim().toLowerCase(Locale.ROOT);
        sqlServer.required(()-> {
            var found=sqlServer.lookup(request,normalized);
            if(found.isEmpty()) return null;
            var account=found.get();
            if(tenant==null?account.platformRole()==null:!sqlServer.membership(request,account.id())) return null;
            if("RESET".equals(purpose) && !account.emailVerified()) return null;
            issueSql(request,account.id(),tenant,purpose);return null;
        });
    }
    private void issueSql(jakarta.servlet.http.HttpServletRequest request,String user,TenantRef tenant,String purpose) {
        issueSql(request,user,tenant,purpose,null);
    }
    private void issueSql(jakarta.servlet.http.HttpServletRequest request,String user,TenantRef tenant,String purpose,SqlServerAccountLifecycleStore.CreatedTenant created) {
        byte[] random=new byte[32];new SecureRandom().nextBytes(random);String token=Base64.getUrlEncoder().withoutPadding().encodeToString(random);
        String origin=created!=null?settings.tenantUrl(created.slug()):tenant==null?settings.publicOrigin():settings.tenantUrl(tenant.slug());
        String link=origin+(purpose.equals("VERIFY")?"/verificar/":"/restablecer/")+"#token="+token;
        String subject=purpose.equals("RESET")?"Recupera tu acceso a Health Project":"Verifica tu cuenta de Health Project";
        String body="Health Project\n\n"+(purpose.equals("RESET")?"Restablece tu contrase\u00f1a":"Confirma tu correo")+":\n"+link+"\n\nEl enlace es de un solo uso. Si no solicitaste este mensaje, puedes ignorarlo.\nMavric Technologies \u00b7 https://mavrictec.com";
        var expiry=Instant.now().plusSeconds(purpose.equals("RESET")?1800:86400).truncatedTo(java.time.temporal.ChronoUnit.MICROS);
        if(created==null) sqlServer.issue(request,Checks.hash(token),user,purpose,expiry,Checks.id(),subject,body);
        else sqlServer.issueRegistration(request,Checks.hash(token),user,expiry,Checks.id(),subject,body,created);
    }
    private void redeemSql(String token,String password,TenantRef tenant,String purpose) {
        var request=validatedRequest(tenant);validPurpose(purpose);
        if(token==null || !token.matches("[A-Za-z0-9_-]{43}")) throw ApiException.invalid("Enlace no valido.");
        if("RESET".equals(purpose)) Checks.password(password);
        String encoded="RESET".equals(purpose)?passwords.encode(password):null;
        sqlServer.redeem(request,Checks.hash(token),purpose,encoded);
    }

}
