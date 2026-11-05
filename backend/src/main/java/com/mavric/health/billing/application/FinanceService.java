package com.mavric.health.billing.application;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.billing.domain.Requests.*;
@Service
public class FinanceService {
    private final com.mavric.health.persistence.sqlserver.SqlServerFinanceStore store;
    private final Sql sql;private final Access access;
    @org.springframework.beans.factory.annotation.Autowired
    public FinanceService(Sql sql,Access access) { this.sql=sql;this.access=access;this.store=null; }
    public FinanceService(com.mavric.health.persistence.sqlserver.SqlServerFinanceStore store,Access access){this.store=java.util.Objects.requireNonNull(store);this.sql=null;this.access=access;}
    private jakarta.servlet.http.HttpServletRequest request(boolean write){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || java.util.Collections.disjoint(actor.roles(),write?java.util.List.of("CAJ"):java.util.List.of("CAJ","AUD")))throw ApiException.forbidden();
        if(write)access.write("FINANCE","CAJ");else {access.roles("CAJ","AUD");access.module("FINANCE");}return req;
    }
    public Object balance(String id) { if(store!=null)return store.balance(request(false),id); access.roles("CAJ","AUD"); access.module("FINANCE"); sql.one("SELECT id FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); return sql.one("SELECT COALESCE(SUM(IF(kind='PAYMENT',-amount_minor,amount_minor)),0) balance_minor,'PEN' currency FROM finance_movements WHERE tenant_id=? AND patient_id=?",access.tenantId(),id); }
    public Object movements(String id) { if(store!=null)return store.movements(request(false),id); balance(id); return sql.rows("SELECT * FROM finance_movements WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id); }
    @Transactional public Object post(Post p,String key) { if(store!=null)return store.post(request(true),p,key); access.write("FINANCE","CAJ"); sql.call("sp_finance_post",access.tenantId(),Checks.id(),access.userId(),sql.json(p),Idempotency.key(key),Checks.hash(sql.json(p))); return sql.one("SELECT * FROM finance_movements WHERE tenant_id=? AND request_key=?",access.tenantId(),key); }
}
