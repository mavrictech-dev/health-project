package com.mavric.health.patients.application;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.shared.*;
import com.mavric.health.identity.Access;
import com.mavric.health.patients.domain.Requests.*;
import tools.jackson.databind.ObjectMapper;
@Service
public class PatientService {
    private final com.mavric.health.persistence.sqlserver.SqlServerPatientStore store;private final Sql sql; private final Access access; private final ObjectMapper mapper;
    @org.springframework.beans.factory.annotation.Autowired
    public PatientService(Sql sql,Access access,ObjectMapper mapper) { this.sql=sql;this.access=access;this.mapper=mapper;this.store=null; }
    public PatientService(com.mavric.health.persistence.sqlserver.SqlServerPatientStore store,Access access,ObjectMapper mapper){this.sql=null;this.store=Objects.requireNonNull(store);this.access=access;this.mapper=mapper;}
    private static ApiException unavailable(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private jakarta.servlet.http.HttpServletRequest request(boolean write){return write?request("CORE","ADM","REC","PRO"):request(null,"ADM","REC","PRO","ASI","AUD");}
    private jakarta.servlet.http.HttpServletRequest request(String module,String... roles){var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request==null)throw unavailable();var actor=access.actor();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw unavailable();if(!actor.equals(request.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();if(actor.roles()==null)throw unavailable();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),Arrays.asList(roles)))throw ApiException.forbidden();if(module!=null)access.write(module,roles);else access.roles(roles);return request;}

    public List<Map<String,Object>> list(String query,int limit,int offset) {if(store!=null)return store.list(request(false),query,limit,offset); access.roles("ADM","REC","PRO","ASI","AUD"); return sql.rows("SELECT * FROM patients WHERE tenant_id=? AND (name LIKE ? OR identifier LIKE ?) ORDER BY name LIMIT ? OFFSET ?",access.tenantId(),"%"+query+"%","%"+query+"%",Checks.limit(limit),Math.max(0,offset)); }
    public Map<String,Object> get(String id) {if(store!=null)return store.get(request(false),id); access.roles("ADM","REC","PRO","ASI","AUD"); return sql.one("SELECT * FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); }
    public List<Map<String,Object>> links(String id,int limit,int offset) {
        if(store==null)throw unavailable();
        var request=request(null,"ADM","REC");
        var actor=(com.mavric.health.identity.Actor)request.getAttribute("health.actor");
        if(actor.roles().contains("PAC") || actor.roles().contains("RES"))throw ApiException.forbidden();
        return store.links(request,id,limit,offset);
    }
    @Transactional public Map<String,Object> save(String id,Patient input,int expected) {if(store!=null)return store.save(request(true),id,input,expected); access.write("CORE","ADM","REC","PRO"); Checks.json(input.contact(),mapper); if(id==null) id=Checks.id(); else get(id); sql.call("sp_patient_save",access.tenantId(),id,access.userId(),sql.json(input),expected); return get(id); }
    private jakarta.servlet.http.HttpServletRequest managementRequest(){
        var request=request("PORTAL","ADM","REC");
        var actor=(com.mavric.health.identity.Actor)request.getAttribute("health.actor");
        if(actor.roles().contains("PAC") || actor.roles().contains("RES"))throw ApiException.forbidden();
        return request;
    }
    @Transactional public Map<String,Object> link(String id,Link input) {if(store==null)throw unavailable();return store.link(managementRequest(),id,input);}
    @Transactional public Map<String,Object> linkEdit(String id,String userId) {if(store==null)throw unavailable();return store.linkEdit(managementRequest(),id,userId);}
    @Transactional public Map<String,Object> history(String id) {if(store!=null)return store.history(request(null,"PRO","ASI","AUD"),id); access.roles("PRO","ASI","AUD"); get(id); Map<String,Object> out=new LinkedHashMap<>(); out.put("patientId",id); out.put("encounters",sql.rows("SELECT * FROM encounters WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id)); out.put("entries",sql.rows("SELECT c.* FROM clinical_entries c JOIN encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=? AND e.patient_id=? ORDER BY c.created_at DESC LIMIT 1000",access.tenantId(),id)); out.put("documents",sql.rows("SELECT * FROM documents WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id)); sql.call("sp_audit",access.tenantId(),access.userId(),"PATIENT_HISTORY_READ",id,sql.json(Map.of())); out.put("limits",Map.of("encounters",200,"entries",1000,"documents",200)); return out; }
}
