package com.mavric.health.documents.application;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.documents.domain.Requests.*;
@Service
public class DocumentService {
    private final Sql sql;private final Access access;
    public DocumentService(Sql sql,Access access) { this.sql=sql;this.access=access; }
    @Transactional public Object list(String patient) { access.roles("PRO","ASI","AUD"); Checks.id(patient); sql.one("SELECT id FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),patient); var rows=sql.rows("SELECT * FROM documents WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),patient); sql.call("sp_audit",access.tenantId(),access.userId(),"DOCUMENT_LIST_READ",patient,sql.json(java.util.Map.of())); return rows; }
    @Transactional public Object get(String id) { access.roles("PRO","ASI","AUD"); var row=sql.one("SELECT * FROM documents WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); sql.call("sp_audit",access.tenantId(),access.userId(),"DOCUMENT_READ",id,sql.json(java.util.Map.of())); return row; }
    @Transactional public Object create(Create p) { access.write("CORE","PRO"); String id=Checks.id(); sql.call("sp_document_create",access.tenantId(),id,access.userId(),sql.json(p)); return get(id); }
    @Transactional public Object change(String id,Change p) { access.write("CORE","PRO"); get(id); if(p.operation().equals("SAVE") && (p.content()==null || p.content().isBlank())) throw ApiException.invalid("Escribe el contenido del borrador."); sql.call("sp_document_change",access.tenantId(),id,access.userId(),p.expectedRevision(),p.operation(),p.content()); return get(id); }
}
