package com.mavric.health.portal;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.scheduling.application.SchedulingService;
import com.mavric.health.scheduling.domain.Requests.Reserve;
@Service
public class PortalService {
    private final Sql sql;private final Access access;private final SchedulingService scheduling;
    public PortalService(Sql sql,Access access,SchedulingService scheduling) { this.sql=sql;this.access=access;this.scheduling=scheduling; }
    private void portal() { access.roles("PAC","RES"); access.module("PORTAL"); }
    public Object patients() { portal(); return sql.rows("SELECT p.id,p.name,p.domain,p.birth_date,p.species,l.relationship,l.scopes FROM patients p JOIN patient_links l ON l.tenant_id=p.tenant_id AND l.patient_id=p.id WHERE p.tenant_id=? AND l.user_id=? AND l.active ORDER BY p.name",access.tenantId(),access.userId()); }
    @Transactional public Object documents(String id) { portal(); access.link(Checks.id(id),"DOCUMENTS"); var result=sql.rows("SELECT id,title,type,content,revision,signer_id,signed_at,content_hash,original_id FROM documents WHERE tenant_id=? AND patient_id=? AND published AND NOT withdrawn AND status='SIGNED' ORDER BY signed_at DESC LIMIT 200",access.tenantId(),id); sql.call("sp_audit",access.tenantId(),access.userId(),"PORTAL_DOCUMENTS_READ",id,sql.json(java.util.Map.of())); return result; }
    public Object appointments(String id) { portal(); access.link(Checks.id(id),"APPOINTMENTS"); return sql.rows("SELECT id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,revision FROM appointments WHERE tenant_id=? AND patient_id=? ORDER BY starts_at DESC LIMIT 200",access.tenantId(),id); }
    public Object reserve(Reserve p,String key) { portal(); return scheduling.reserve(p,key,true); }
    public Object balance(String id) { portal(); access.module("FINANCE"); access.link(Checks.id(id),"BILLING"); return sql.one("SELECT COALESCE(SUM(IF(kind='PAYMENT',-amount_minor,amount_minor)),0) balance_minor,'PEN' currency FROM finance_movements WHERE tenant_id=? AND patient_id=?",access.tenantId(),id); }
}
