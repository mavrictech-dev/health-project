package com.mavric.health.clinical.application;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.clinical.domain.Requests.*;
import tools.jackson.databind.ObjectMapper;
@Service
public class ClinicalService {
    private final Sql sql;private final Access access;private final ObjectMapper mapper;
    public ClinicalService(Sql sql,Access access,ObjectMapper mapper) { this.sql=sql;this.access=access;this.mapper=mapper; }
    @Transactional public Map<String,Object> get(String id) { access.roles("PRO","ASI","AUD"); var row=sql.one("SELECT * FROM encounters WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); row.put("entries",sql.rows("SELECT * FROM clinical_entries WHERE tenant_id=? AND encounter_id=? ORDER BY created_at",access.tenantId(),id)); sql.call("sp_audit",access.tenantId(),access.userId(),"ENCOUNTER_READ",id,sql.json(Map.of())); return row; }
    @Transactional public Map<String,Object> start(Start p) { access.write("CORE","PRO"); access.branch(p.branchId()); String id=Checks.id(); sql.call("sp_encounter_start",access.tenantId(),id,access.userId(),sql.json(p)); return get(id); }
    @Transactional public Map<String,Object> note(String id,Note p,boolean finalize) { access.write("CORE","PRO"); var row=get(id); access.branch(row.get("branchId").toString()); if(finalize && p.note().isBlank()) throw ApiException.invalid("Registra el resumen de la visita antes de finalizar."); sql.call("sp_encounter_save",access.tenantId(),id,access.userId(),p.expectedRevision(),p.note(),finalize); return get(id); }
    @Transactional public Map<String,Object> entry(String encounter,Entry p) {
        access.write("CORE",p.kind().equals("OBSERVATION")?new String[]{"PRO","ASI"}:new String[]{"PRO"}); var visit=get(encounter); access.branch(visit.get("branchId").toString());
        if(!p.kind().equals("OBSERVATION") && !visit.get("professionalId").equals(access.userId())) throw ApiException.forbidden();
        Checks.json(p.payload(),mapper); validate(p,visit);
        String id=Checks.id(); sql.call("sp_clinical_entry",access.tenantId(),id,encounter,access.userId(),p.kind(),sql.json(p.payload())); return sql.one("SELECT * FROM clinical_entries WHERE tenant_id=? AND id=?",access.tenantId(),id);
    }
    private void validate(Entry input,Map<String,Object> visit) {
        Map<?,?> profile=(Map<?,?>)visit.get("profileSnapshot"); Map<String,Object> p=input.payload();
        switch(input.kind()) {
            case "EVALUATION" -> {
                if(!visit.get("specialtyCode").equals(p.get("profileCode")) || !(p.get("values") instanceof Map<?,?> values)) throw ApiException.invalid("La evaluación debe usar el perfil de la atención y un objeto values.");
                for(Object item:(List<?>)profile.get("fields")) {
                    Map<?,?> field=(Map<?,?>)item; Object value=values.get(field.get("id"));
                    if(Boolean.TRUE.equals(field.get("required")) && (value==null || value.toString().isBlank())) throw ApiException.invalid("Falta el campo: "+field.get("label"));
                    if(value!=null && "number".equals(field.get("type")) && !(value instanceof Number)) throw ApiException.invalid("El campo debe ser numérico: "+field.get("label"));
                    if(value!=null && field.get("options") instanceof List<?> options && !options.isEmpty() && !options.contains(value)) throw ApiException.invalid("Opción no válida: "+field.get("label"));
                }
            }
            case "OBSERVATION" -> { required(p,"parameter"); required(p,"unit"); if(!(p.get("value") instanceof Number)) throw ApiException.invalid("La medición requiere un valor numérico."); }
            case "ANNOTATION" -> {
                required(p,"component"); required(p,"structure"); required(p,"condition");
                Set<String> families=new HashSet<>(); ((List<?>)profile.get("componentFamilies")).forEach(f->families.add(f.toString()));
                for(Object item:(List<?>)profile.get("components")) {
                    String component=item.toString();
                    if(component.matches(".*(genogram|pedigree).*")) families.add("GENETICS");
                    else if(component.matches(".*(cephal|occlus).*")) families.add("ORTHODONTIC");
                    else if(component.matches(".*(root|canal).*")) families.add("ENDO");
                    else if(component.contains("periodont")) families.add("PERIODONTAL");
                }
                if(!families.contains(p.get("component"))) throw ApiException.invalid("El componente no corresponde al perfil.");
                if(Set.of("HUMAN_DENTAL","VET_DENTAL","PERIODONTAL","ENDO","ORTHODONTIC","PROSTHETIC").contains(p.get("component"))) access.module("DENTAL");
            }
            case "ORDER" -> { required(p,"type"); required(p,"description"); }
            case "PRESCRIPTION" -> { required(p,"medication"); required(p,"dose"); required(p,"route"); required(p,"frequency"); required(p,"unit"); if(!(p.get("quantity") instanceof Number q) || q.doubleValue()<=0) throw ApiException.invalid("La prescripción necesita una cantidad positiva."); }
            default -> throw ApiException.invalid("Tipo de entrada no válido.");
        }
    }
    private void required(Map<String,Object> p,String key) { if(!(p.get(key) instanceof String text) || text.isBlank() || text.length()>2000) throw ApiException.invalid("Revisa el campo "+key+"."); }
}
