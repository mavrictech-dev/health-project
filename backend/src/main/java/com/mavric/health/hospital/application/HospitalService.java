package com.mavric.health.hospital.application;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.hospital.domain.Requests.*;
@Service
public class HospitalService {
    private final Sql sql;private final Access access;
    public HospitalService(Sql sql,Access access) { this.sql=sql;this.access=access; }
    public Object resources() { access.roles("ADM","PRO","ASI","AUD"); access.module("HOSPITAL"); return sql.rows("SELECT r.*,EXISTS(SELECT 1 FROM admissions a WHERE a.tenant_id=r.tenant_id AND a.resource_id=r.id AND a.status='ADMITTED') occupied FROM hospital_resources r WHERE r.tenant_id=? ORDER BY r.name LIMIT 200",access.tenantId()); }
    @Transactional public Object resource(Resource p) { access.write("HOSPITAL","ADM"); access.branch(p.branchId()); String id=Checks.id(); sql.call("sp_resource_create",access.tenantId(),id,access.userId(),sql.json(p)); return sql.one("SELECT * FROM hospital_resources WHERE tenant_id=? AND id=?",access.tenantId(),id); }
    public Object admissions() { access.roles("PRO","ASI","AUD"); access.module("HOSPITAL"); return sql.rows("SELECT * FROM admissions WHERE tenant_id=? ORDER BY admitted_at DESC LIMIT 200",access.tenantId()); }
    @Transactional public Object admit(Admission p) { access.write("HOSPITAL","PRO","ASI"); var resource=sql.one("SELECT branch_id FROM hospital_resources WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(p.resourceId())); access.branch(resource.get("branchId").toString()); String id=Checks.id(); sql.call("sp_admit",access.tenantId(),id,access.userId(),sql.json(p)); return sql.one("SELECT * FROM admissions WHERE tenant_id=? AND id=?",access.tenantId(),id); }
    @Transactional public Object discharge(String id,int expected) { access.write("HOSPITAL","PRO","ASI"); var stay=sql.one("SELECT r.branch_id FROM admissions a JOIN hospital_resources r ON r.tenant_id=a.tenant_id AND r.id=a.resource_id WHERE a.tenant_id=? AND a.id=?",access.tenantId(),Checks.id(id)); access.branch(stay.get("branchId").toString()); sql.call("sp_discharge",access.tenantId(),id,access.userId(),expected); return sql.one("SELECT * FROM admissions WHERE tenant_id=? AND id=?",access.tenantId(),id); }
}
