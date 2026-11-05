package com.mavric.health.workflows.application;
import java.util.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.workflows.domain.Requests.*;
@Service
public class WorkflowService {
    private final com.mavric.health.persistence.sqlserver.SqlServerWorkflowStore store;
    private final Sql sql;private final Access access;private final ObjectMapper mapper;
    @org.springframework.beans.factory.annotation.Autowired
    public WorkflowService(Sql sql,Access access,ObjectMapper mapper) { this.sql=sql;this.access=access;this.mapper=mapper;this.store=null; }
    public WorkflowService(com.mavric.health.persistence.sqlserver.SqlServerWorkflowStore store,Sql sql,Access access,ObjectMapper mapper){this.store=Objects.requireNonNull(store);this.sql=sql;this.access=access;this.mapper=mapper;}
    private jakarta.servlet.http.HttpServletRequest request(){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw database();var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw database();
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP"))throw ApiException.forbidden();return req;
    }
    private static ApiException database(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    public Object definitions() { if(store!=null)return store.definitions(request()); access.tenant(); return sql.rows("SELECT * FROM workflow_definitions ORDER BY type").stream().filter(d->access.tenant().modules().contains(d.get("module")) && !Collections.disjoint(sql.strings(d.get("readers")),access.actor().roles())).toList(); }
    private Map<String,Object> definition(String type) { var d=sql.one("SELECT * FROM workflow_definitions WHERE type=?",type); access.module(d.get("module").toString()); return d; }
    public Object list(String type) { if(store!=null)return store.list(request(),type); var d=definition(type); access.roles(sql.strings(d.get("readers")).toArray(String[]::new)); return sql.rows("SELECT * FROM workflow_cases WHERE tenant_id=? AND type=? ORDER BY updated_at DESC LIMIT 200",access.tenantId(),type); }
    public Map<String,Object> get(String id) { if(store!=null)return store.get(request(),id); var row=sql.one("SELECT * FROM workflow_cases WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); var d=definition(row.get("type").toString()); access.roles(sql.strings(d.get("readers")).toArray(String[]::new)); row.put("history",sql.rows("SELECT revision,status,payload,actor_id,created_at FROM workflow_history WHERE tenant_id=? AND case_id=? ORDER BY revision",access.tenantId(),id)); return row; }
    @Transactional public Object create(Create p) { if(store!=null)return store.create(request(),p); var d=definition(p.type()); access.write(d.get("module").toString(),sql.strings(d.get("creators")).toArray(String[]::new)); access.branch(p.branchId()); Checks.json(p.payload(),mapper); String id=Checks.id(); sql.call("sp_workflow_create",access.tenantId(),id,access.userId(),sql.json(p)); return get(id); }
    @Transactional public Object step(String id,Step p) { if(store!=null)return store.step(request(),id,p); var row=get(id); var d=definition(row.get("type").toString()); String[] roles=sql.strings((row.get("status").equals("DRAFT") && p.status().equals("SUBMITTED"))?d.get("creators"):d.get("operators")).toArray(String[]::new); access.write(d.get("module").toString(),roles); access.branch(row.get("branchId").toString()); Checks.json(p.payload(),mapper); sql.call("sp_workflow_step",access.tenantId(),id,access.userId(),p.expectedRevision(),p.status(),sql.json(p.payload())); return get(id); }
}
