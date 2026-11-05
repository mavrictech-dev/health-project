package com.mavric.health.saas.application;

import java.time.ZoneId;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.*;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import com.mavric.health.saas.domain.Requests.*;

@Service
public class PlatformService {
    public static final Set<String> KINDS=Set.of("DOCTOR","CLINIC","HOSPITAL","VETERINARY","DENTAL","SPECIALTY_CENTER");
    public static final Set<String> MODULES=Set.of("CORE","PORTAL","DENTAL","DIAGNOSTICS","PHARMACY","FINANCE","INVENTORY","HOSPITAL","SURGERY","ADVANCED","VET_POPULATION","REPORTS");
    private final com.mavric.health.persistence.sqlserver.SqlServerPlatformStore store;private final Sql sql; private final Access access; private final IdentityService identities; private final Settings settings;
    @org.springframework.beans.factory.annotation.Autowired
    public PlatformService(Sql sql,Access access,IdentityService identities,Settings settings) { this.sql=sql; this.access=access; this.identities=identities; this.settings=settings;this.store=null; }
    public PlatformService(com.mavric.health.persistence.sqlserver.SqlServerPlatformStore store,Access access,IdentityService identities,Settings settings){this.sql=null;this.store=Objects.requireNonNull(store);this.access=access;this.identities=identities;this.settings=settings;}
    private static ApiException unavailable(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private jakarta.servlet.http.HttpServletRequest request(){
        var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request==null)throw unavailable();var actor=access.actor();Object host=request.getAttribute("health.tenant");
        if(host!=null && !(host instanceof TenantRef))throw unavailable();
        if(!actor.equals(request.getAttribute("health.actor")) || host!=null || actor.tenantId()!=null)throw ApiException.forbidden();
        if(actor.roles()==null)throw unavailable();if(!actor.roles().contains("SAD"))throw ApiException.forbidden();access.platform();return request;
    }
    public List<Map<String,Object>> plans() {if(store!=null)return store.plans(request()); access.platform(); return sql.rows("SELECT p.*,v.* FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version ORDER BY p.name"); }
    @Transactional public Map<String,Object> plan(String id,Plan input) {if(store!=null)return store.savePlan(request(),id,input);
        access.platform(); if(id==null) id=Checks.id(); else sql.one("SELECT id FROM plans WHERE id=?",Checks.id(id));
        if(!KINDS.containsAll(input.kinds()) || !Set.of("HUMAN","ANIMAL").containsAll(input.domains()) || !MODULES.containsAll(input.modules()) || !input.modules().contains("CORE")) throw ApiException.invalid("Tipos de cliente, ámbitos o módulos inválidos.");
        if(input.kinds().contains("DOCTOR") && input.includedProfessionals()!=1) throw ApiException.invalid("La oferta para independientes incluye una identidad clínica.");
        sql.call("sp_plan_save",id,access.userId(),sql.json(input)); return sql.one("SELECT p.*,v.* FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.id=?",id);
    }
    public List<Map<String,Object>> tenants(int limit) {if(store!=null)return store.tenants(request(),limit).stream().map(this::sqlDomain).toList(); access.platform(); return sql.rows(TENANT_QUERY+" ORDER BY t.created_at DESC LIMIT ?",Checks.limit(limit)).stream().map(this::domain).toList(); }
    public Map<String,Object> tenant(String id) {if(store!=null)return sqlDomain(store.tenant(request(),id)); access.platform(); return domain(sql.one(TENANT_QUERY+" WHERE t.id=?",Checks.id(id))); }
    public List<Map<String,Object>> users(int limit) {if(store!=null)return store.users(request(),limit); access.platform(); return sql.rows("SELECT id,name,email,clinical_domain,credential,active FROM users ORDER BY name LIMIT ?",Checks.limit(limit)); }
    @Transactional public Map<String,Object> createUser(IdentityService.UserInput input) {if(store!=null){var req=request();if(input==null)throw ApiException.invalid("Identidad requerida.");return store.createUser(req,()->identities.create(input));} access.platform(); String id=identities.create(input); return sql.one("SELECT id,name,email,clinical_domain,credential FROM users WHERE id=?",id); }
    @Transactional public Map<String,Object> create(Tenant input) {if(store!=null)return store.createTenant(request(),input,()->{var user=input.owner();return identities.create(new IdentityService.UserInput(user.name(),user.email(),user.password(),input.kind().equals("DOCTOR")?input.domain():user.domain(),user.credential()));},this::sqlDomain);
        access.platform(); DomainRules.slug(input.slug());
        try { ZoneId.of(input.timezone()); } catch(Exception e) { throw ApiException.invalid("Zona horaria inválida."); }
        if(input.kind().equals("VETERINARY") && !input.domain().equals("ANIMAL") || !Set.of("DOCTOR","VETERINARY").contains(input.kind()) && !input.domain().equals("HUMAN")) throw ApiException.invalid("Tipo y ámbito incompatibles.");
        if((input.ownerUserId()==null)==(input.owner()==null)) throw ApiException.invalid("Selecciona un propietario existente o crea una cuenta.");
        String owner;
        if(input.ownerUserId()!=null) owner=sql.one("SELECT id FROM users WHERE id=? AND active",Checks.id(input.ownerUserId())).get("id").toString();
        else { var user=input.owner(); owner=identities.create(new IdentityService.UserInput(user.name(),user.email(),user.password(),input.kind().equals("DOCTOR")?input.domain():user.domain(),user.credential())); }
        String id=Checks.id(); String branch=Checks.id(); sql.call("sp_tenant_create",id,branch,owner,access.userId(),sql.json(Map.of("name",input.name(),"slug",input.slug(),"kind",input.kind(),"domain",input.domain(),"timezone",input.timezone(),"branchName",input.branchName(),"address",input.address(),"specialties",input.specialties(),"subscription",input.subscription())));
        return domain(sql.one(TENANT_QUERY+" WHERE t.id=?",id));
    }
    @Transactional public Map<String,Object> status(String id,Status input) {if(store!=null){var req=request();if(input==null)throw ApiException.invalid("Estado y motivo requeridos.");return store.status(req,id,input.status(),input.reason(),this::sqlDomain);} access.platform(); sql.call("sp_tenant_status",Checks.id(id),access.userId(),input.status(),input.reason()); return tenant(id); }
    @Transactional public Map<String,Object> pay(String tenantId,String invoiceId) {if(store!=null)return store.pay(request(),tenantId,invoiceId); access.platform(); sql.call("sp_invoice_pay",Checks.id(tenantId),Checks.id(invoiceId),access.userId()); return sql.one("SELECT * FROM saas_invoices WHERE tenant_id=? AND id=?",tenantId,invoiceId); }
    public List<Map<String,Object>> audit(int limit) {if(store!=null)return store.audit(request(),limit); access.platform(); return sql.rows("SELECT a.id,a.tenant_id,a.actor_id,a.action,a.target_id,a.metadata,a.created_at FROM audit_events a WHERE a.action IN ('TENANT_CREATED','TENANT_STATUS_CHANGED','PLAN_VERSION_CREATED','SUBSCRIPTION_CHANGED','BRANCH_SAVED','AREA_SAVED','MEMBERSHIP_SAVED','SPECIALTIES_CONFIGURED','SAAS_PAYMENT_RECORDED') ORDER BY a.id DESC LIMIT ?",Checks.limit(limit)); }
    public List<Map<String,Object>> specialties(String query) {if(store!=null)return store.specialties(request(),query); access.platform(); return sql.rows("SELECT code,name,domain,dental,profile FROM specialties WHERE name LIKE ? ORDER BY name", "%"+query+"%"); }
    private Map<String,Object> sqlDomain(Map<String,Object> row){var result=new LinkedHashMap<String,Object>(row);String slug=(String)row.get("slug");result.put("hostname",settings.hostname(slug));result.put("url",settings.tenantUrl(slug));return Collections.unmodifiableMap(result);}
    private Map<String,Object> domain(Map<String,Object> row) { row.put("hostname",settings.hostname(row.get("slug").toString())); row.put("url",settings.tenantUrl(row.get("slug").toString())); return row; }
    private static final String TENANT_QUERY="SELECT t.*,u.name owner_name,u.email owner_email,s.plan_id,s.plan_version,s.cycle,s.branch_quota,s.professional_quota,s.specialty_quota,s.renewal_date,p.name plan_name,v.modules,v.base_minor,v.branch_minor,v.professional_minor,v.included_branches,v.included_professionals,v.annual_discount,(SELECT COUNT(*) FROM branches b WHERE b.tenant_id=t.id AND b.active AND NOT b.external) branches_used,(SELECT COUNT(*) FROM memberships m WHERE m.tenant_id=t.id AND m.status<>'INACTIVE' AND JSON_CONTAINS(m.roles,'\"PRO\"')) professionals_used,(SELECT COUNT(*) FROM tenant_specialties x WHERE x.tenant_id=t.id) specialties_used FROM tenants t JOIN users u ON u.id=t.owner_user_id JOIN subscriptions s ON s.tenant_id=t.id JOIN plans p ON p.id=s.plan_id JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version";
}
