package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;

/** Unwired support reads. Executor and REQUIRED manager must share the runtime datasource.
 * Default isolation does not promise a consistent snapshot or real authorization proof. */
public final class SqlServerSupportStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerSupportStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T> T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException error){throw SqlServerErrors.map(error);}}
 private static SqlServerContext context(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");
  if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor))throw ApiException.forbidden();
  if(!Objects.equals(actor.tenantId(),host==null?null:((TenantRef)host).id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();
  if(host==null && Collections.disjoint(actor.roles(),List.of("SAD","SOP")))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  if(!canonical(c.actorId()) || c.tenantId()!=null && !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return c;
 }
 public List<Map<String,Object>> list(HttpServletRequest request){return within(()->{
  var c=context(request);var rows=sets(executor.execute(SqlServerProcedure.SUPPORT_LIST,c),1).getFirst();
  if(rows.size()>(c.tenantId()==null?200:100))throw SqlServerErrors.database();return rows.stream().map(row->ticket(row,c)).toList();
 });}
 public Map<String,Object> detail(HttpServletRequest request,String id){return within(()->{
  var c=context(request);Checks.id(id);var rs=sets(executor.execute(SqlServerProcedure.SUPPORT_DETAIL,c,id),2);
  return detail(rs,c,id);
 });}
 private static Map<String,Object> detail(List<List<Map<String,Object>>> rs,SqlServerContext c,String id){
  if(rs.getFirst().size()>1)throw SqlServerErrors.database();if(rs.getFirst().isEmpty())throw ApiException.missing();
  var ticket=ticket(rs.getFirst().getFirst(),c);if(!id.equals(ticket.get("id")))throw SqlServerErrors.database();
  var result=new LinkedHashMap<>(ticket);result.put("comments",rs.get(1).stream().map(SqlServerSupportStore::comment).toList());return Collections.unmodifiableMap(result);
 }
 /** Validates trusted request attributes before the controller rate limiter; create repeats this inside REQUIRED. */
 public static void validatePublicRequest(HttpServletRequest request){publicContext(request);}
 private static SqlServerContext publicContext(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant"),value=request.getAttribute("health.actor");
  if(host!=null && !(host instanceof TenantRef) || value!=null && !(value instanceof Actor))throw SqlServerErrors.database();
  if(value instanceof Actor actor && !Objects.equals(actor.tenantId(),host==null?null:((TenantRef)host).id()))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  if(c.tenantId()!=null && !canonical(c.tenantId()) || c.actorId()!=null && (!canonical(c.actorId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}")))throw SqlServerErrors.database();return c;
 }
 public Map<String,Object> create(HttpServletRequest request,String email,String subject,String message,String priority){return within(()->{
  var c=publicContext(request);
  if(!validText(email,254) || !validText(subject,180) || !validText(message,4000) || priority==null || !Set.of("LOW","NORMAL","HIGH","URGENT").contains(priority))throw SqlServerErrors.invalid();
  String id=Checks.id(),reference="MVT-"+UUID.randomUUID().toString().substring(0,12).toUpperCase(Locale.ROOT);
  String json=new tools.jackson.databind.ObjectMapper().writeValueAsString(Map.of("email",email,"subject",subject,"message",message,"priority",priority));
  var result=executor.execute(SqlServerProcedure.SUPPORT_CREATE,c,id,reference,json);
  if(result==null || !result.resultSets().isEmpty())throw SqlServerErrors.database();
  return Map.of("reference",reference,"status","OPEN","message","Solicitud registrada. Conserva tu referencia.","provider","Mavric Technologies","website","https://mavrictec.com");
 });}
 public Map<String,Object> step(HttpServletRequest request,String id,int revision,String status,String priority,String message){return within(()->{
  var c=context(request);Checks.id(id);
  if(revision<1 || status==null || !Set.of("OPEN","IN_PROGRESS","WAITING_USER","RESOLVED","CLOSED").contains(status) || priority==null || !Set.of("LOW","NORMAL","HIGH","URGENT").contains(priority) || message!=null && message.length()>4000)throw SqlServerErrors.invalid();
  return detail(sets(executor.execute(SqlServerProcedure.SUPPORT_STEP,c,id,revision,status,priority,Checks.id(),message),2),c,id);
 });}
 private static boolean validText(String value,int max){return value!=null && !value.isBlank() && value.length()<=max;}
 private static List<List<Map<String,Object>>> sets(SqlServerExecutor.Result result,int count){if(result==null || result.resultSets().size()!=count)throw SqlServerErrors.database();return result.resultSets();}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key){if(!(field(row,key) instanceof String value))throw SqlServerErrors.database();return value;}
 private static String id(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String s) || !canonical(s))throw SqlServerErrors.database();return s;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException e){return false;}}
 private static String timestamp(Map<String,Object> row,String key){String value=text(row,key);try{if(!value.endsWith("Z") || java.time.Instant.parse(value).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException error){throw SqlServerErrors.database();}return value;}
 private static Map<String,Object> ticket(Map<String,Object> row,SqlServerContext c){
  var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));String tenant=id(row,"tenantId",true),actor=id(row,"actorId",true);
  if(c.tenantId()!=null && (!c.tenantId().equals(tenant) || !c.actorId().equals(actor)))throw SqlServerErrors.database();out.put("tenantId",tenant);out.put("actorId",actor);
  for(String key:List.of("reference","email","subject","message"))out.put(key,text(row,key));
  String status=text(row,"status"),priority=text(row,"priority");
  if(!Set.of("OPEN","IN_PROGRESS","WAITING_USER","RESOLVED","CLOSED").contains(status) || !Set.of("LOW","NORMAL","HIGH","URGENT").contains(priority) || !(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();
  out.put("status",status);out.put("priority",priority);out.put("revision",revision);out.put("createdAt",timestamp(row,"createdAt"));out.put("updatedAt",timestamp(row,"updatedAt"));return Collections.unmodifiableMap(out);
 }
 private static Map<String,Object> comment(Map<String,Object> row){return Map.of("id",id(row,"id",false),"message",text(row,"message"),"createdAt",timestamp(row,"createdAt"),"actorName",text(row,"actorName"));}
 @Override public String toString(){return "SqlServerSupportStore[redacted]";}
}
