package com.mavric.health.persistence.sqlserver;

import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.support.TransactionOperations;
import com.mavric.health.tenancy.DomainRules;

/** Unwired security gateway. The caller MUST supply the runtime executor and transaction operations
 *  for the SAME datasource. No transaction spans the downstream HTTP filter chain. */
public final class SqlServerSecurityStore {
    private final SqlServerExecutor executor;
    private final TransactionOperations transactions;

    public SqlServerSecurityStore(SqlServerExecutor executor, TransactionOperations transactions) {
        this.executor=Objects.requireNonNull(executor);
        this.transactions=Objects.requireNonNull(transactions);
    }

    public Optional<Map<String,Object>> tenantBySlug(HttpServletRequest request,String slug) {
        DomainRules.slug(slug);
        return within(()->optional(executor.execute(SqlServerProcedure.TENANT_BY_SLUG,
                SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST),slug)).map(row-> {
            Map<String,Object> result=new LinkedHashMap<>(row);
            for (String key:List.of("id","name","slug","kind","domain","status")) text(row,key,false);
            if(!com.mavric.health.shared.Ruc.valid(text(row,"ruc",false)) || !(row.get("revision") instanceof Integer revision) || revision<1)throw inconsistent();
            if (!slug.equals(row.get("slug"))) throw inconsistent();
            result.put("modules",strings(row.get("modules")));
            return Collections.unmodifiableMap(result);
        }));
    }

    public Optional<Map<String,Object>> resolveSession(HttpServletRequest request,String tokenHash) {
        if (tokenHash==null || !tokenHash.matches("[0-9a-f]{64}")) throw SqlServerErrors.invalid();
        return within(()->optional(executor.execute(SqlServerProcedure.SESSION_RESOLVE,
                SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY),tokenHash)).map(row-> {
            for (String key:List.of("userId","name","email","csrfToken")) text(row,key,false);
            text(row,"tenantId",true);text(row,"platformRole",true);
            return row;
        }));
    }

    public Optional<Map<String,Object>> activeMembership(HttpServletRequest request,String userId) {
        if (userId==null) throw SqlServerErrors.invalid();
        return within(()-> {
            SqlServerContext context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
            if (context.tenantId()==null) throw inconsistent();
            return optional(executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,context,
                    userId,context.tenantId(),true)).map(row-> {
                text(row,"userId",false);text(row,"status",false);
                if (!userId.equals(row.get("userId")) || !"ACTIVE".equals(row.get("status"))) throw inconsistent();
                Map<String,Object> result=new LinkedHashMap<>(row);
                result.put("roles",strings(row.get("roles")));
                return Collections.unmodifiableMap(result);
            });
        });
    }

    public Map<String,Object> applicationStatus(HttpServletRequest request) {
        return within(()-> {
            Map<String,Object> row=optional(executor.execute(SqlServerProcedure.APPLICATION_STATUS,
                    SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST))).orElseThrow(SqlServerSecurityStore::inconsistent);
            text(row,"mode",false);text(row,"message",false);
            return row;
        });
    }

    public void touchSession(HttpServletRequest request) {
        within(()-> {
            SqlServerContext context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
            if (context.actorId()==null || context.tokenHash()==null) throw inconsistent();
            SqlServerExecutor.Result result=executor.execute(SqlServerProcedure.SESSION_TOUCH,context);
            if (result==null || !result.resultSets().isEmpty()) throw inconsistent();
            return Boolean.TRUE;
        });
    }

    private <T> T within(Supplier<T> work) {
        try { return transactions.execute(status->work.get()); }
        catch (RuntimeException error) { throw SqlServerErrors.map(error); }
    }

    private static Optional<Map<String,Object>> optional(SqlServerExecutor.Result result) {
        if (result==null || result.resultSets().size()!=1) throw inconsistent();
        List<Map<String,Object>> rows=result.resultSets().getFirst();
        if (rows.size()>1) throw inconsistent();
        return rows.isEmpty()?Optional.empty():Optional.of(rows.getFirst());
    }

    private static String text(Map<String,Object> row,String key,boolean nullable) {
        if (!row.containsKey(key)) throw inconsistent();
        Object value=row.get(key);
        if (value==null && nullable) return null;
        if (!(value instanceof String text)) throw inconsistent();
        return text;
    }

    private static List<String> strings(Object value) {
        if (!(value instanceof List<?> values)) throw inconsistent();
        List<String> result=new ArrayList<>();
        for (Object item:values) {
            if (!(item instanceof String text)) throw inconsistent();
            result.add(text);
        }
        return List.copyOf(result);
    }

    private static com.mavric.health.shared.ApiException inconsistent() { return SqlServerErrors.database(); }
    @Override public String toString() { return "SqlServerSecurityStore[redacted]"; }
}
