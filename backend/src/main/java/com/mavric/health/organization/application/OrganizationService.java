package com.mavric.health.organization.application;

import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.*;
import com.mavric.health.shared.*;
import com.mavric.health.organization.domain.Requests.*;
import com.mavric.health.saas.domain.Requests.Subscription;

@Service
public class OrganizationService {
    private static final Set<String> ROLES=Set.of("ADM","REC","PRO","ASI","DIA","FAR","CAJ","ALM","PAC","RES","AUD");
    private final Access access; private final Sql sql; private final IdentityService identities;
    public OrganizationService(Access access,Sql sql,IdentityService identities) { this.access=access; this.sql=sql; this.identities=identities; }
    private String target(String id) { if(id==null) { access.roles("ADM"); return access.tenantId(); } access.platform(); return sql.one("SELECT id FROM tenants WHERE id=?",Checks.id(id)).get("id").toString(); }
    public Map<String,Object> configuration(String id) {
        String t=target(id); Map<String,Object> data=new LinkedHashMap<>(sql.one("SELECT t.id,t.name,t.slug,t.domain,t.kind,t.status,t.timezone,s.*,p.name plan_name,v.* FROM tenants t JOIN subscriptions s ON s.tenant_id=t.id JOIN plans p ON p.id=s.plan_id JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.id=?",t));
        data.put("branches",sql.rows("SELECT * FROM branches WHERE tenant_id=? ORDER BY name",t));
        data.put("areas",sql.rows("SELECT * FROM areas WHERE tenant_id=? ORDER BY name",t));
        data.put("specialties",sql.rows("SELECT a.* FROM specialties a JOIN tenant_specialties s ON s.specialty_code=a.code WHERE s.tenant_id=? ORDER BY a.name",t));
        data.put("members",sql.rows("SELECT u.id,u.name,u.email,u.clinical_domain,u.credential,m.roles,m.status,m.owner FROM memberships m JOIN users u ON u.id=m.user_id WHERE m.tenant_id=? ORDER BY u.name",t).stream().map(m->{m.put("branches",sql.rows("SELECT branch_id FROM membership_branches WHERE tenant_id=? AND user_id=?",t,m.get("id")).stream().map(r->r.get("branchId")).toList()); m.put("specialties",sql.rows("SELECT specialty_code FROM membership_specialties WHERE tenant_id=? AND user_id=?",t,m.get("id")).stream().map(r->r.get("specialtyCode")).toList());return m;}).toList());
        data.put("invoices",sql.rows("SELECT * FROM saas_invoices WHERE tenant_id=? ORDER BY created_at DESC",t));
        return data;
    }
    @Transactional public Map<String,Object> subscription(String tenant,Subscription input) { String t=target(tenant); sql.call("sp_subscription_change",t,access.userId(),Checks.id(),sql.json(input)); return configuration(tenant); }
    @Transactional public Map<String,Object> branch(String tenant,String id,Branch input) { String t=target(tenant); if(id==null) id=Checks.id(); else sql.one("SELECT id FROM branches WHERE tenant_id=? AND id=?",t,Checks.id(id)); sql.call("sp_branch_save",t,id,access.userId(),sql.json(input)); return sql.one("SELECT * FROM branches WHERE tenant_id=? AND id=?",t,id); }
    @Transactional public Map<String,Object> area(String tenant,String id,Area input) { String t=target(tenant); if(id==null) id=Checks.id(); else sql.one("SELECT id FROM areas WHERE tenant_id=? AND id=?",t,Checks.id(id)); sql.call("sp_area_save",t,id,access.userId(),sql.json(input)); return sql.one("SELECT * FROM areas WHERE tenant_id=? AND id=?",t,id); }
    @Transactional public Map<String,Object> specialties(String tenant,Specialties input) { String t=target(tenant); sql.call("sp_specialties_save",t,access.userId(),sql.json(input.specialties())); return configuration(tenant); }
    @Transactional public Map<String,Object> member(String tenant,Member input) {
        String t=target(tenant); if(!ROLES.containsAll(input.roles())) throw ApiException.invalid("Roles no permitidos dentro de un cliente.");
        if((input.userId()==null)==(input.user()==null)) throw ApiException.invalid("Selecciona una identidad existente o crea una cuenta.");
        String u=input.userId()==null?identities.create(input.user()):sql.one("SELECT id FROM users WHERE id=? AND active",Checks.id(input.userId())).get("id").toString();
        sql.call("sp_member_save",t,u,access.userId(),sql.json(Map.of("roles",input.roles(),"status",input.status(),"branches",input.branches(),"specialties",input.specialties()))); return sql.one("SELECT u.id,u.name,u.email,u.clinical_domain,m.roles,m.status,m.owner FROM memberships m JOIN users u ON u.id=m.user_id WHERE m.tenant_id=? AND m.user_id=?",t,u);
    }
    public List<Map<String,Object>> lookup(String email) { target(null); return sql.rows("SELECT id,name,email,clinical_domain,credential FROM users WHERE email=? AND active",email.toLowerCase(Locale.ROOT)); }
    public List<Map<String,Object>> directory() { access.tenant(); return sql.rows("SELECT id,name,address,external,active FROM branches WHERE tenant_id=? AND active ORDER BY name",access.tenantId()); }
    public List<Map<String,Object>> professionals(String branch) { access.tenant(); if(branch!=null) access.branch(branch); return sql.rows("SELECT u.id,u.name,u.clinical_domain,u.credential,m.roles FROM memberships m JOIN users u ON u.id=m.user_id WHERE m.tenant_id=? AND m.status='ACTIVE' AND JSON_CONTAINS(m.roles,'\"PRO\"') AND (? IS NULL OR EXISTS(SELECT 1 FROM membership_branches b WHERE b.tenant_id=m.tenant_id AND b.user_id=m.user_id AND b.branch_id=?)) ORDER BY u.name",access.tenantId(),branch,branch); }
    public List<Map<String,Object>> catalog() { access.tenant(); return sql.rows("SELECT * FROM specialties WHERE domain=? AND (?<>'DENTAL' OR dental) ORDER BY name",access.tenant().domain(),access.tenant().kind()); }
    public List<Map<String,Object>> availablePlans() { access.roles("ADM"); return sql.rows("SELECT p.*,v.* FROM plans p JOIN plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.status='PUBLISHED' AND JSON_CONTAINS(v.kinds,JSON_QUOTE(?)) AND JSON_CONTAINS(v.domains,JSON_QUOTE(?)) ORDER BY p.name",access.tenant().kind(),access.tenant().domain()); }
}
