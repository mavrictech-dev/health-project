package com.mavric.health.persistence.sqlserver;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.shared.ApiException;

/** Unwired public catalog. Executor and manager must share the runtime datasource.
 * REQUIRED groups validation and both reads, without promising a snapshot isolation level. */
public final class SqlServerAccountLifecycleStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate transactions;
    public SqlServerAccountLifecycleStore(SqlServerExecutor executor,PlatformTransactionManager manager) {
        this.executor=Objects.requireNonNull(executor);
        transactions=new TransactionTemplate(Objects.requireNonNull(manager));
        transactions.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
    }
    public Map<String,Object> options(HttpServletRequest request) {
        try {
            var result=transactions.execute(status-> {
                if(request==null || request.getAttribute("health.tenant")!=null) throw SqlServerErrors.database();
                var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
                var plans=rows(executor.execute(SqlServerProcedure.REGISTRATION_PLANS,context)).stream().map(SqlServerAccountLifecycleStore::plan).toList();
                var specialties=rows(executor.execute(SqlServerProcedure.REGISTRATION_SPECIALTIES,context)).stream().map(SqlServerAccountLifecycleStore::specialty).toList();
                return Map.<String,Object>of("plans",plans,"specialties",specialties);
            });
            if(result==null) throw SqlServerErrors.database();
            return result;
        } catch(RuntimeException error) {throw SqlServerErrors.map(error);}
    }
    private static List<Map<String,Object>> rows(SqlServerExecutor.Result result) {
        if(result==null || result.resultSets().size()!=1) throw SqlServerErrors.database();
        return result.resultSets().getFirst();
    }
    private static String text(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof String value)) throw SqlServerErrors.database();
        return value;
    }
    private static List<String> strings(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof List<?> values)) throw SqlServerErrors.database();
        List<String> copy=new ArrayList<>();
        for(Object value:values) {if(!(value instanceof String item)) throw SqlServerErrors.database();copy.add(item);}
        return List.copyOf(copy);
    }
    private static Integer quota(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof Integer value) || value<1) throw SqlServerErrors.database();
        return value;
    }
    private static Map<String,Object> plan(Map<String,Object> row) {
        String id=text(row,"id");
        try {if(!UUID.fromString(id).toString().equals(id)) throw SqlServerErrors.database();}
        catch(IllegalArgumentException invalid) {throw SqlServerErrors.database();}
        if(!(row.get("baseMinor") instanceof Long base) || base<0) throw SqlServerErrors.database();
        return Map.of("id",id,"name",text(row,"name"),"kinds",strings(row,"kinds"),"domains",strings(row,"domains"),
                "includedBranches",quota(row,"includedBranches"),"includedProfessionals",quota(row,"includedProfessionals"),
                "includedSpecialties",quota(row,"includedSpecialties"),"baseMinor",base);
    }
    private static Map<String,Object> specialty(Map<String,Object> row) {
        if(!(row.get("dental") instanceof Boolean dental)) throw SqlServerErrors.database();
        return Map.of("code",text(row,"code"),"name",text(row,"name"),"domain",text(row,"domain"),"dental",dental);
    }
    @Override public String toString() {return "SqlServerAccountLifecycleStore[redacted]";}
}
