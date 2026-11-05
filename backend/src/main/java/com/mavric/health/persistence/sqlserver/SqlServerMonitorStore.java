package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/** Unwired monitor gateway; executor and REQUIRED manager must share the runtime datasource. */
public final class SqlServerMonitorStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerMonitorStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T> T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException error){throw SqlServerErrors.map(error);}}
 public Map<String,Object> status(HttpServletRequest request){return within(()->{
  if(request==null)throw SqlServerErrors.database();var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  var row=one(executor.execute(SqlServerProcedure.APPLICATION_STATUS,context));
  if(!(row.get("mode") instanceof String mode) || !Set.of("OPEN","READ_ONLY","MAINTENANCE").contains(mode) || !(row.get("message") instanceof String message) || !(row.get("revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();
  return Map.of("mode",mode,"message",message,"revision",revision,"status",mode.equals("OPEN")?"OPERATIONAL":"RESTRICTED");
 });}
 public void sample(String instance,long memoryUsed,long memoryMax,long uptimeMs){within(()->{
  if(!canonical(instance) || memoryUsed<0 || memoryMax<0 || uptimeMs<0)throw SqlServerErrors.invalid();
  var context=new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.WORKER);
  long start=System.nanoTime();var ready=one(executor.execute(SqlServerProcedure.HEALTH_READY,context));long latency=(System.nanoTime()-start)/1_000_000;
  if(!(ready.get("ready") instanceof Integer value) || value!=1)throw SqlServerErrors.database();
  var result=executor.execute(SqlServerProcedure.HEALTH_SAMPLE,context,instance,"UP",latency,memoryUsed,memoryMax,uptimeMs);
  if(result==null || !result.resultSets().isEmpty())throw SqlServerErrors.database();return null;
 });}
 private static Map<String,Object> one(SqlServerExecutor.Result result){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()!=1)throw SqlServerErrors.database();return result.resultSets().getFirst().getFirst();}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException error){return false;}}
 @Override public String toString(){return "SqlServerMonitorStore[redacted]";}
}
