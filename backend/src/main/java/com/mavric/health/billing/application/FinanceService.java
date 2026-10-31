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
    private final Sql sql;private final Access access;
    public FinanceService(Sql sql,Access access) { this.sql=sql;this.access=access; }
    public Object balance(String id) { access.roles("CAJ","AUD"); access.module("FINANCE"); sql.one("SELECT id FROM patients WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); return sql.one("SELECT COALESCE(SUM(IF(kind='PAYMENT',-amount_minor,amount_minor)),0) balance_minor,'PEN' currency FROM finance_movements WHERE tenant_id=? AND patient_id=?",access.tenantId(),id); }
    public Object movements(String id) { balance(id); return sql.rows("SELECT * FROM finance_movements WHERE tenant_id=? AND patient_id=? ORDER BY created_at DESC LIMIT 200",access.tenantId(),id); }
    @Transactional public Object post(Post p,String key) { access.write("FINANCE","CAJ"); sql.call("sp_finance_post",access.tenantId(),Checks.id(),access.userId(),sql.json(p),Idempotency.key(key),Checks.hash(sql.json(p))); return sql.one("SELECT * FROM finance_movements WHERE tenant_id=? AND request_key=?",access.tenantId(),key); }
}
