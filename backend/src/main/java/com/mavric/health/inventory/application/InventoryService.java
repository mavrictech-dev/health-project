package com.mavric.health.inventory.application;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.inventory.domain.Requests.*;
@Service
public class InventoryService {
    private final com.mavric.health.persistence.sqlserver.SqlServerInventoryStore store;
    private final Sql sql;private final Access access;
    @org.springframework.beans.factory.annotation.Autowired
    public InventoryService(Sql sql,Access access) { this.sql=sql;this.access=access;this.store=null; }
    public InventoryService(com.mavric.health.persistence.sqlserver.SqlServerInventoryStore store,Sql sql,Access access){this.store=java.util.Objects.requireNonNull(store);this.sql=sql;this.access=access;}
    private jakarta.servlet.http.HttpServletRequest request(String module,String... roles){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || java.util.Collections.disjoint(actor.roles(),java.util.Arrays.asList(roles)))throw ApiException.forbidden();access.roles(roles);access.module(module);return req;
    }
    private jakarta.servlet.http.HttpServletRequest writeRequest(String role){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || !actor.roles().contains(role))throw ApiException.forbidden();access.write("INVENTORY",role);return req;
    }
    public Object lots() { if(store!=null)return store.lots(request("INVENTORY","ALM","FAR","AUD")); access.roles("ALM","FAR","AUD"); access.module("INVENTORY"); return sql.rows("SELECT * FROM stock_lots WHERE tenant_id=? ORDER BY expiry,name LIMIT 200",access.tenantId()); }
    @Transactional public Object lot(Lot p) { if(store!=null)return store.lot(writeRequest("ALM"),p); access.write("INVENTORY","ALM"); access.branch(p.branchId()); String id=Checks.id(); sql.call("sp_stock_lot",access.tenantId(),id,access.userId(),sql.json(p)); return sql.one("SELECT * FROM stock_lots WHERE tenant_id=? AND id=?",access.tenantId(),id); }
    @Transactional public Object move(Move p,String key) { if(store!=null)return store.move(writeRequest(p!=null && "DISPENSE".equals(p.kind())?"FAR":"ALM"),p,key); access.write("INVENTORY",p.kind().equals("DISPENSE")?new String[]{"FAR"}:new String[]{"ALM"}); var lot=sql.one("SELECT * FROM stock_lots WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(p.lotId())); access.branch(lot.get("branchId").toString()); if(p.kind().equals("DISPENSE") && p.prescriptionId()==null) throw ApiException.invalid("Selecciona la prescripción a dispensar."); sql.call("sp_stock_move",access.tenantId(),Checks.id(),access.userId(),sql.json(p),Idempotency.key(key),Checks.hash(sql.json(p))); return sql.one("SELECT * FROM stock_movements WHERE tenant_id=? AND request_key=?",access.tenantId(),key); }
    public Object transfers() { if(store!=null)return store.transfers(request("INVENTORY","ALM","AUD")); access.roles("ALM","AUD"); access.module("INVENTORY"); return sql.rows("SELECT * FROM stock_transfers WHERE tenant_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId()); }
    @Transactional public Object transfer(Transfer p,String key) { access.write("INVENTORY","ALM"); var lot=sql.one("SELECT branch_id FROM stock_lots WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(p.lotId())); access.branch(lot.get("branchId").toString()); access.branch(p.destinationBranchId()); sql.call("sp_transfer_start",access.tenantId(),Checks.id(),access.userId(),sql.json(p),Idempotency.key(key),Checks.hash(sql.json(p))); return sql.one("SELECT * FROM stock_transfers WHERE tenant_id=? AND request_key=?",access.tenantId(),key); }
    @Transactional public Object receive(String id) { access.write("INVENTORY","ALM"); var transfer=sql.one("SELECT * FROM stock_transfers WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); access.branch(transfer.get("destinationBranchId").toString()); sql.call("sp_transfer_receive",access.tenantId(),id,access.userId()); return sql.one("SELECT * FROM stock_transfers WHERE tenant_id=? AND id=?",access.tenantId(),id); }
    public Object prescriptions() { if(store!=null)return store.prescriptions(request("PHARMACY","FAR","PRO","AUD")); access.roles("FAR","PRO","AUD"); access.module("PHARMACY"); return sql.rows("SELECT c.id,c.encounter_id,e.patient_id,e.branch_id,c.payload,c.created_at FROM clinical_entries c JOIN encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=? AND c.kind='PRESCRIPTION' ORDER BY c.created_at DESC LIMIT 200",access.tenantId()); }
}
