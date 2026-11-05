package com.mavric.health.persistence.sqlserver;

import java.util.*;
import java.time.Instant;
import java.math.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;

/** Unwired read gateway. Executor and REQUIRED manager must share the runtime datasource.
 * The default isolation level does not promise a consistent snapshot. */
public final class SqlServerAuditStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerAuditStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T> T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request,boolean tenantOnly){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");
  if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor))throw ApiException.forbidden();
  if(!Objects.equals(actor.tenantId(),host==null?null:((TenantRef)host).id()))throw ApiException.forbidden();
  if(tenantOnly && host==null)throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();
  if(Collections.disjoint(actor.roles(),host==null?List.of("SAD","SOP"):List.of("ADM","AUD")))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
  if(!canonical(c.actorId()) || c.tenantId()!=null && !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();
  return c;
 }
 public List<Map<String,Object>> list(HttpServletRequest request,int limit){return within(()->{var c=context(request,true);int size=Checks.limit(limit);return mapped(sets(executor.execute(SqlServerProcedure.AUDIT_LIST,c,size),1).getFirst(),size,row->audit(row));});}
 public Map<String,Object> events(HttpServletRequest request,String query,String actor,String resource,String requestId,String from,String to,long before,int limit){return within(()->{
  var c=context(request,false);int size=Checks.limit(limit);
  var values=sets(executor.execute(SqlServerProcedure.TRACE_EVENTS,c,search(query,100,true),filterId(actor),search(resource,60,false),filterId(requestId),dateInput(from),dateInput(to),Math.max(0,before),size),1).getFirst();
  var rows=mapped(values,size+1,row->event(row,c));var visible=Collections.unmodifiableList(new ArrayList<>(rows.subList(0,Math.min(size,rows.size()))));
  return Map.of("items",visible,"hasMore",rows.size()>size,"nextCursor",visible.isEmpty()?0L:visible.getLast().get("id"));
 });}
 public List<Map<String,Object>> requests(HttpServletRequest request,int limit,int status,String query){return within(()->{var c=context(request,false);int size=Checks.limit(limit);return mapped(sets(executor.execute(SqlServerProcedure.TRACE_REQUESTS,c,size,Math.max(0,status),search(query,250,false)),1).getFirst(),size,row->requestRow(row,c));});}
 public Map<String,Object> journey(HttpServletRequest request,String id){return within(()->{
  var c=context(request,false);Checks.id(id);var rs=sets(executor.execute(SqlServerProcedure.TRACE_JOURNEY,c,id),2);
  if(rs.getFirst().size()>1)throw SqlServerErrors.database();if(rs.getFirst().isEmpty())throw ApiException.missing();
  var root=requestRow(rs.getFirst().getFirst(),c);if(!id.equals(root.get("id")))throw SqlServerErrors.database();
  var steps=mapped(rs.get(1),201,row->event(row,c));var result=new LinkedHashMap<>(root);result.put("steps",Collections.unmodifiableList(new ArrayList<>(steps.subList(0,Math.min(200,steps.size())))));return Collections.unmodifiableMap(result);
 });}
 private static List<List<Map<String,Object>>> sets(SqlServerExecutor.Result result,int count){if(result==null || result.resultSets().size()!=count)throw SqlServerErrors.database();return result.resultSets();}
 private static List<Map<String,Object>> mapped(List<Map<String,Object>> rows,int max,java.util.function.Function<Map<String,Object>,Map<String,Object>> mapper){if(rows.size()>max)throw SqlServerErrors.database();return rows.stream().map(mapper).toList();}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object v=field(row,key);if(v==null && nullable)return null;if(!(v instanceof String s))throw SqlServerErrors.database();return s;}
 private static String id(Map<String,Object> row,String key,boolean nullable){String v=text(row,key,nullable);if(v!=null && !canonical(v))throw SqlServerErrors.database();return v;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException e){return false;}}
 private static Long positive(Map<String,Object> row){Object v=field(row,"id");if(!(v instanceof Long n) || n<=0)throw SqlServerErrors.database();return n;}
 private static String timestamp(Map<String,Object> row){String v=text(row,"createdAt",false);try{if(!v.endsWith("Z") || Instant.parse(v).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException e){throw SqlServerErrors.database();}return v;}
 private static Map<String,Object> audit(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",positive(row));out.put("actorId",id(row,"actorId",true));out.put("action",text(row,"action",false));out.put("targetId",text(row,"targetId",false));out.put("metadata",json(field(row,"metadata")));out.put("createdAt",timestamp(row));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> event(Map<String,Object> row,SqlServerContext c){var out=new LinkedHashMap<>(audit(row));String tenant=id(row,"tenantId",true);if(c.tenantId()!=null && tenant!=null && !c.tenantId().equals(tenant))throw SqlServerErrors.database();out.put("tenantId",tenant);out.put("requestId",id(row,"requestId",true));for(String key:List.of("method","route","sourceIp","userAgent","resourceType","actorName","actorEmail","tenantName"))out.put(key,text(row,key,true));for(String key:List.of("actorRoles","beforeState","afterState"))out.put(key,json(field(row,key)));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> requestRow(Map<String,Object> row,SqlServerContext c){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));String tenant=id(row,"tenantId",true);if(c.tenantId()!=null && !c.tenantId().equals(tenant))throw SqlServerErrors.database();out.put("tenantId",tenant);out.put("actorId",id(row,"actorId",true));for(String key:List.of("method","route","sourceIp","userAgent"))out.put(key,text(row,key,false));Object status=field(row,"status"),duration=field(row,"durationMs");if(!(status instanceof Integer n) || n<100 || n>599 || !(duration instanceof Long d) || d<0)throw SqlServerErrors.database();out.put("status",status);out.put("durationMs",duration);out.put("createdAt",timestamp(row));out.put("actorName",text(row,"actorName",true));return Collections.unmodifiableMap(out);}
 private static Object json(Object value){return json(value,Collections.newSetFromMap(new IdentityHashMap<>()));}
 private static Object json(Object value,Set<Object> ancestors){
  if(value==null || value instanceof String || value instanceof Boolean || value instanceof Byte || value instanceof Short || value instanceof Integer || value instanceof Long || value instanceof BigInteger || value instanceof BigDecimal)return value;
  if(value instanceof Double d && Double.isFinite(d) || value instanceof Float f && Float.isFinite(f))return value;
  if(!(value instanceof List<?>) && !(value instanceof Map<?,?>) || !ancestors.add(value))throw SqlServerErrors.database();
  try {
   if(value instanceof List<?> list){var copy=new ArrayList<Object>();for(Object item:list)copy.add(json(item,ancestors));return Collections.unmodifiableList(copy);}
   var copy=new LinkedHashMap<String,Object>();((Map<?,?>)value).forEach((key,item)->{if(!(key instanceof String s))throw SqlServerErrors.database();copy.put(s,json(item,ancestors));});return Collections.unmodifiableMap(copy);
  } finally {ancestors.remove(value);}
 }
 private static String search(String value,int max,boolean truncate){if(value==null || value.isBlank())return null;if(value.length()<=max)return value;if(!truncate)throw SqlServerErrors.invalid();int end=max;if(Character.isHighSurrogate(value.charAt(end-1)) && Character.isLowSurrogate(value.charAt(end)))end--;return value.substring(0,end);}
 private static String filterId(String value){if(value==null || value.isBlank())return null;return Checks.id(value);}
 private static Instant dateInput(String value){if(value==null || value.isBlank())return null;try{Instant date=Instant.parse(value);if(date.getNano()%1000!=0)throw SqlServerErrors.invalid();return date;}catch(java.time.DateTimeException e){throw SqlServerErrors.invalid();}}
}
