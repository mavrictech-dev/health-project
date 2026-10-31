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
    private final Sql sql; private final Access access; private final ObjectMapper mapper;
    public PatientService(Sql sql,Access access,ObjectMapper mapper) { this.sql=sql;this.access=access;this.mapper=mapper; }
    public List<Map<String,Object>> list(String query,int limit,int offset) { access.roles("ADM","REC","PRO","ASI","AUD"); return sql.rows("SELECT * FROM patients WHERE tenant_id=? AND (name LIKE ? OR identifier LIKE ?) ORDER BY name LIMIT ? OFFSET ?",access.tenantId(),"%"+query+"%","%"+query+"%",Checks.limit(limit),Math.max(0,offset)); }
    public Map<String,Object> get(String id) { access.roles("ADM","REC","PRO","ASI","AUD"); return sql.one("SELECT * FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); }
    @Transactional public Map<String,Object> save(String id,Patient input,int expected) { access.write("CORE","ADM","REC","PRO"); Checks.json(input.contact(),mapper); if(id==null) id=Checks.id(); else get(id); sql.call("sp_patient_save",access.tenantId(),id,access.userId(),sql.json(input),expected); return get(id); }
    @Transactional public Map<String,Object> link(String id,Link input) { access.write("PORTAL","ADM","REC"); if(!Set.of("APPOINTMENTS","DOCUMENTS","BILLING").containsAll(input.scopes())) throw ApiException.invalid("Alcances de vínculo no válidos."); sql.call("sp_patient_link",access.tenantId(),Checks.id(id),Checks.id(input.userId()),access.userId(),sql.json(input)); return sql.one("SELECT * FROM patient_links WHERE tenant_id=? AND patient_id=? AND user_id=?",access.tenantId(),id,input.userId()); }
    @Transactional public Map<String,Object> history(String id) { access.roles("PRO","ASI","AUD"); get(id); Map<String,Object> out=new LinkedHashMap<>(); out.put("patientId",id); out.put("encounters",sql.rows("SELECT * FROM encounters WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id)); out.put("entries",sql.rows("SELECT c.* FROM clinical_entries c JOIN encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=? AND e.patient_id=? ORDER BY c.created_at DESC LIMIT 1000",access.tenantId(),id)); out.put("documents",sql.rows("SELECT * FROM documents WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id)); sql.call("sp_audit",access.tenantId(),access.userId(),"PATIENT_HISTORY_READ",id,sql.json(Map.of())); out.put("limits",Map.of("encounters",200,"entries",1000,"documents",200)); return out; }
}
