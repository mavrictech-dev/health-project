package com.mavric.health.persistence.sqlserver;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.shared.*;

/** All card persistence uses the closed, parameterized procedure catalogue. */
public final class SqlServerCardsStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate tx;
    private final ObjectMapper mapper;
    public SqlServerCardsStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=executor;this.tx=new TransactionTemplate(manager);this.mapper=mapper;}
    public List<Map<String,Object>> rows(HttpServletRequest request,SqlServerProcedure procedure,Object...args){
        try {return tx.execute(status->{var result=executor.execute(procedure,SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST),args);if(result.resultSets().size()!=1)throw SqlServerErrors.database();return result.resultSets().getFirst();});}
        catch(RuntimeException e){throw SqlServerErrors.map(e);}
    }
    public Map<String,Object> one(HttpServletRequest request,SqlServerProcedure procedure,Object...args){var rows=rows(request,procedure,args);if(rows.size()!=1)throw SqlServerErrors.database();return rows.getFirst();}
    public String json(Object value){return mapper.writeValueAsString(value);}
}
