package com.mavric.health.documents.application;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.documents.domain.Requests.*;
@Service
public class DocumentService {
    private final com.mavric.health.persistence.sqlserver.SqlServerDocumentStore store;
    private final Sql sql;private final Access access;
    @org.springframework.beans.factory.annotation.Autowired
    public DocumentService(Sql sql,Access access) { this.sql=sql;this.access=access;this.store=null; }
    public DocumentService(com.mavric.health.persistence.sqlserver.SqlServerDocumentStore store,Access access){this.sql=null;this.store=java.util.Objects.requireNonNull(store);this.access=access;}
    private jakarta.servlet.http.HttpServletRequest request(boolean write){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || java.util.Collections.disjoint(actor.roles(),write?java.util.List.of("PRO"):java.util.List.of("PRO","ASI","AUD")))throw ApiException.forbidden();
        if(write)access.write("CORE","PRO");else access.roles("PRO","ASI","AUD");return req;
    }
    @Transactional public Object list(String patient) { if(store!=null)return store.list(request(false),patient); access.roles("PRO","ASI","AUD"); Checks.id(patient); sql.one("SELECT id FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),patient); var rows=sql.rows("SELECT * FROM documents WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),patient); sql.call("sp_audit",access.tenantId(),access.userId(),"DOCUMENT_LIST_READ",patient,sql.json(java.util.Map.of())); return rows; }
    @Transactional public Object get(String id) { if(store!=null)return store.get(request(false),id); access.roles("PRO","ASI","AUD"); var row=sql.one("SELECT * FROM documents WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); sql.call("sp_audit",access.tenantId(),access.userId(),"DOCUMENT_READ",id,sql.json(java.util.Map.of())); return row; }
    @Transactional public Object create(Create p) { if(store!=null)return store.create(request(true),p); access.write("CORE","PRO"); String id=Checks.id(); sql.call("sp_document_create",access.tenantId(),id,access.userId(),sql.json(p)); return get(id); }
    @Transactional public Object change(String id,Change p) { if(store!=null){var req=request(true);return store.required(()->{access.roles("PRO","ASI","AUD");store.get(req,id);if(p==null)throw ApiException.invalid("Operacion documental requerida.");if("SAVE".equals(p.operation()) && (p.content()==null || p.content().isBlank()))throw ApiException.invalid("Escribe el contenido del borrador.");return store.change(req,id,p);});} access.write("CORE","PRO"); get(id); if(p.operation().equals("SAVE") && (p.content()==null || p.content().isBlank())) throw ApiException.invalid("Escribe el contenido del borrador."); sql.call("sp_document_change",access.tenantId(),id,access.userId(),p.expectedRevision(),p.operation(),p.content()); return get(id); }
}
