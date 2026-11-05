package com.mavric.health.persistence.sqlserver;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

/** Unwired finalization only. Executor and manager must share the runtime datasource.
 * Independent, short trace transaction; never spans downstream processing. */
public final class SqlServerTraceStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate transactions;
    public SqlServerTraceStore(SqlServerExecutor executor,PlatformTransactionManager manager) {
        this.executor=Objects.requireNonNull(executor);
        transactions=new TransactionTemplate(Objects.requireNonNull(manager));
        transactions.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    }
    public void finish(HttpServletRequest request,String serverRequestId,int status,long durationMs) {
        try {
            transactions.execute(tx-> {
                if(request==null || !canonical(serverRequestId) || !serverRequestId.equals(request.getAttribute("health.requestId"))) throw SqlServerErrors.database();
                var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
                if(context.actorId()!=null && !canonical(context.actorId()) || context.tenantId()!=null && !canonical(context.tenantId())
                        || context.tokenHash()!=null && !context.tokenHash().matches("[0-9a-fA-F]{64}")) throw SqlServerErrors.database();
                if(status<100 || status>599 || durationMs<0) throw SqlServerErrors.invalid();
                var result=executor.execute(SqlServerProcedure.REQUEST_FINISH,context,status,durationMs);
                if(result==null || !result.resultSets().isEmpty()) throw SqlServerErrors.database();
                return null;
            });
        } catch(RuntimeException failure) {throw SqlServerErrors.map(failure);}
    }
    private static boolean canonical(String value) {
        if(value==null) return false;
        try {return UUID.fromString(value).toString().equals(value);}
        catch(IllegalArgumentException invalid) {return false;}
    }
    @Override public String toString() {return "SqlServerTraceStore[redacted]";}
}
