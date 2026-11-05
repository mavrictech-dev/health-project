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
 /** Readiness-only operation, with server WORKER authority and no sampling side effects. */
 public void ready(){within(()->{
  var context=new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.WORKER);
  var row=one(executor.execute(SqlServerProcedure.HEALTH_READY,context));
  if(!(row.get("ready") instanceof Integer value) || value!=1)throw SqlServerErrors.database();
  return null;
 });}
 public Map<String,Object> status(HttpServletRequest request){return within(()->{
  if(request==null)throw SqlServerErrors.database();var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  return application(context);
 });}
 private Map<String,Object> application(SqlServerContext context){
  var row=one(executor.execute(SqlServerProcedure.APPLICATION_STATUS,context));
  if(!(row.get("mode") instanceof String mode) || !Set.of("OPEN","READ_ONLY","MAINTENANCE").contains(mode) || !(row.get("message") instanceof String message) || !(row.get("revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();
  return Map.of("mode",mode,"message",message,"revision",revision,"status",mode.equals("OPEN")?"OPERATIONAL":"RESTRICTED");
 }
 private static SqlServerContext authorized(HttpServletRequest request,boolean write){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");
  if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof com.mavric.health.identity.Actor actor))throw com.mavric.health.shared.ApiException.forbidden();
  if(!Objects.equals(actor.tenantId(),host==null?null:((com.mavric.health.tenancy.TenantRef)host).id()))throw com.mavric.health.shared.ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();
  if(write?(host!=null || !actor.roles().contains("SAD")):Collections.disjoint(actor.roles(),host==null?List.of("SAD","SOP"):List.of("ADM","AUD")))throw com.mavric.health.shared.ApiException.forbidden();
  var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  if(!canonical(context.actorId()) || context.tenantId()!=null && !canonical(context.tenantId()) || context.tokenHash()==null || !context.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return context;
 }
 public Map<String,Object> details(HttpServletRequest request){return within(()->{
  var context=authorized(request,false);var out=new LinkedHashMap<String,Object>();out.put("application",application(context));
  long start=System.nanoTime();var ready=one(executor.execute(SqlServerProcedure.HEALTH_READY,context));long latency=(System.nanoTime()-start)/1_000_000;
  if(!(ready.get("ready") instanceof Integer value) || value!=1)throw SqlServerErrors.database();
  out.put("database",Map.of("status","UP","latencyMs",latency));
  if(context.tenantId()==null){out.put("samples",rows(executor.execute(SqlServerProcedure.MONITOR_SAMPLES,context),120,SqlServerMonitorStore::sampleRow));out.put("mail",rows(executor.execute(SqlServerProcedure.MONITOR_MAIL,context),Integer.MAX_VALUE,SqlServerMonitorStore::mailRow));}
  else out.put("samples",List.of());
  out.put("requests",rows(executor.execute(SqlServerProcedure.MONITOR_REQUESTS,context),Integer.MAX_VALUE,SqlServerMonitorStore::requestRow));
  if(context.tenantId()==null)out.put("migrations",rows(executor.execute(SqlServerProcedure.MONITOR_MIGRATIONS,context),20,SqlServerMonitorStore::migrationRow));
  return Collections.unmodifiableMap(out);
 });}
 public Map<String,Object> mode(HttpServletRequest request,int revision,String mode,String message){return within(()->{
  var context=authorized(request,true);
  if(revision<1 || mode==null || !Set.of("OPEN","READ_ONLY","MAINTENANCE").contains(mode) || message==null || message.isBlank() || message.length()>300)throw SqlServerErrors.invalid();
  var result=executor.execute(SqlServerProcedure.APPLICATION_MODE,context,revision,mode,message);
  if(result==null || !result.resultSets().isEmpty())throw SqlServerErrors.database();return application(context);
 });}
 private static List<Map<String,Object>> rows(SqlServerExecutor.Result result,int max,java.util.function.Function<Map<String,Object>,Map<String,Object>> mapper){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(mapper).toList();}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key){if(!(field(row,key) instanceof String value))throw SqlServerErrors.database();return value;}
 private static Long number(Map<String,Object> row,String key){if(!(field(row,key) instanceof Long value) || value<0)throw SqlServerErrors.database();return value;}
 private static String timestamp(Map<String,Object> row,String key){String value=text(row,key);try{if(!value.endsWith("Z") || java.time.Instant.parse(value).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException error){throw SqlServerErrors.database();}return value;}
 private static Map<String,Object> sampleRow(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();Long id=number(row,"id");if(id==0)throw SqlServerErrors.database();out.put("id",id);String instance=text(row,"instanceId");if(!canonical(instance))throw SqlServerErrors.database();out.put("instanceId",instance);out.put("dbStatus",text(row,"dbStatus"));for(String key:List.of("dbLatencyMs","memoryUsed","memoryMax","uptimeMs"))out.put(key,number(row,key));out.put("createdAt",timestamp(row,"createdAt"));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> mailRow(Map<String,Object> row){return Map.of("status",text(row,"status"),"total",number(row,"total"));}
 private static Map<String,Object> requestRow(Map<String,Object> row){if(!(field(row,"statusGroup") instanceof Integer group))throw SqlServerErrors.database();return Map.of("statusGroup",group,"total",number(row,"total"),"averageMs",number(row,"averageMs"));}
 private static Map<String,Object> migrationRow(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();Object version=field(row,"version");if(version!=null && !(version instanceof String))throw SqlServerErrors.database();out.put("version",version);out.put("description",text(row,"description"));out.put("installedOn",timestamp(row,"installedOn"));if(!(field(row,"success") instanceof Boolean success))throw SqlServerErrors.database();out.put("success",success);return Collections.unmodifiableMap(out);}
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
