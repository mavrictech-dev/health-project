package com.mavric.health.persistence.sqlserver;

import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.shared.ApiException;
import com.mavric.health.shared.Checks;
import com.mavric.health.tenancy.TenantRef;

/** Unwired access gateway. Executor and transaction manager MUST use the SAME runtime datasource.
 *  Availability reveals no distinction between missing, inactive, foreign or unassigned resources. */
public final class SqlServerAccessStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate transactions;

    public SqlServerAccessStore(SqlServerExecutor executor,PlatformTransactionManager manager) {
        this.executor=Objects.requireNonNull(executor);
        transactions=new TransactionTemplate(Objects.requireNonNull(manager));
        transactions.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
    }

    public boolean branch(HttpServletRequest request,String id) {
        return within(()-> {
            SqlServerContext context=context(request);
            Checks.id(id);
            return available(executor.execute(SqlServerProcedure.ACCESS_BRANCH,context,id),id,"id","branchId");
        });
    }

    public boolean link(HttpServletRequest request,String patient,String scope) {
        return within(()-> {
            SqlServerContext context=context(request);
            Checks.id(patient);
            if(scope==null || scope.isBlank() || scope.length()>80) throw ApiException.invalid("Alcance de acceso no valido.");
            return available(executor.execute(SqlServerProcedure.ACCESS_PATIENT_LINK,context,patient,scope),patient,"patientId");
        });
    }

    private boolean within(Supplier<Boolean> work) {
        try {
            Boolean available=transactions.execute(status->work.get());
            if(available==null) throw SqlServerErrors.database();
            return available;
        } catch(RuntimeException error) { throw SqlServerErrors.map(error); }
    }

    private static SqlServerContext context(HttpServletRequest request) {
        if(request==null || !(request.getAttribute("health.actor") instanceof Actor actor)
                || !(request.getAttribute("health.tenant") instanceof TenantRef tenant)
                || actor.id()==null || actor.tokenHash()==null || actor.tenantId()==null
                || !actor.tenantId().equals(tenant.id())) throw ApiException.forbidden();
        return SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
    }

    private static boolean available(SqlServerExecutor.Result result,String expected,String... columns) {
        if(result==null || result.resultSets().size()!=1) throw SqlServerErrors.database();
        List<Map<String,Object>> rows=result.resultSets().getFirst();
        if(rows.size()>1) throw SqlServerErrors.database();
        if(rows.isEmpty()) return false;
        Map<String,Object> row=rows.getFirst();
        for(String column:columns)
            if(!(row.get(column) instanceof String value) || !expected.equals(value)) throw SqlServerErrors.database();
        return true;
    }
    @Override public String toString() { return "SqlServerAccessStore[redacted]"; }
}
