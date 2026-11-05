package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.math.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.shared.*;
import com.mavric.health.saas.application.PlatformService;

/** Unwired SAD catalog reads. Executor and REQUIRED manager must share the runtime datasource. */
public final class SqlServerPlatformStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerPlatformStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T> T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException error){throw SqlServerErrors.map(error);}}
 private static SqlServerContext context(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");
  if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor) || host!=null || actor.tenantId()!=null)throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(!actor.roles().contains("SAD"))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return c;
 }
 public List<Map<String,Object>> plans(HttpServletRequest request){return within(()->read(executor.execute(SqlServerProcedure.PLATFORM_PLANS,context(request),(Object)null),Integer.MAX_VALUE,SqlServerPlatformStore::plan));}
 public List<Map<String,Object>> users(HttpServletRequest request,int limit){return within(()->{var c=context(request);int size=Checks.limit(limit);return read(executor.execute(SqlServerProcedure.PLATFORM_USERS,c,null,size),size,SqlServerPlatformStore::user);});}
 public List<Map<String,Object>> specialties(HttpServletRequest request,String query){return within(()->{var c=context(request);String value=query==null?"":query;if(value.length()>220)throw SqlServerErrors.invalid();return read(executor.execute(SqlServerProcedure.PLATFORM_SPECIALTIES,c,value),Integer.MAX_VALUE,SqlServerPlatformStore::specialty);});}
 public List<Map<String,Object>> audit(HttpServletRequest request,int limit){return within(()->{var c=context(request);int size=Checks.limit(limit);return read(executor.execute(SqlServerProcedure.PLATFORM_AUDIT,c,size),size,SqlServerPlatformStore::auditRow);});}
 private static List<Map<String,Object>> read(SqlServerExecutor.Result result,int max,java.util.function.Function<Map<String,Object>,Map<String,Object>> mapper){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(mapper).toList();}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object v=field(row,key);if(v==null && nullable)return null;if(!(v instanceof String value))throw SqlServerErrors.database();return value;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException e){return false;}}
 private static String id(Map<String,Object> row,String key,boolean nullable){String v=text(row,key,nullable);if(v!=null && !canonical(v))throw SqlServerErrors.database();return v;}
 private static Integer integer(Map<String,Object> row,String key,int min){if(!(field(row,key) instanceof Integer value) || value<min)throw SqlServerErrors.database();return value;}
 private static Long amount(Map<String,Object> row,String key){if(!(field(row,key) instanceof Long value) || value<0)throw SqlServerErrors.database();return value;}
 private static String timestamp(Map<String,Object> row){String v=text(row,"createdAt",false);try{if(!v.endsWith("Z") || java.time.Instant.parse(v).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException e){throw SqlServerErrors.database();}return v;}
 private static Boolean bool(Map<String,Object> row,String key){if(!(field(row,key) instanceof Boolean value))throw SqlServerErrors.database();return value;}
 private static List<String> strings(Map<String,Object> row,String key,Set<String> allowed){if(!(field(row,key) instanceof List<?> list) || list.isEmpty())throw SqlServerErrors.database();List<String> result=new ArrayList<>();Set<String> unique=new HashSet<>();for(Object v:list){if(!(v instanceof String value) || !allowed.contains(value) || !unique.add(value))throw SqlServerErrors.database();result.add(value);}return List.copyOf(result);}
 private static Map<String,Object> plan(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();String id=id(row,"id",false),plan=id(row,"planId",false);int current=integer(row,"currentVersion",1),version=integer(row,"version",1);if(!id.equals(plan)||current!=version)throw SqlServerErrors.database();out.put("id",id);out.put("planId",plan);out.put("currentVersion",current);out.put("version",version);for(String key:List.of("name","description"))out.put(key,text(row,key,false));String status=text(row,"status",false);if(!Set.of("DRAFT","PUBLISHED","ARCHIVED").contains(status))throw SqlServerErrors.database();out.put("status",status);for(String key:List.of("baseMinor","branchMinor","professionalMinor"))out.put(key,amount(row,key));for(String suffix:List.of("Branches","Professionals","Specialties")){int included=integer(row,"included"+suffix,1),max=integer(row,"max"+suffix,1);if(max<included)throw SqlServerErrors.database();out.put("included"+suffix,included);out.put("max"+suffix,max);}int discount=integer(row,"annualDiscount",0);if(discount>60)throw SqlServerErrors.database();out.put("annualDiscount",discount);var kinds=strings(row,"kinds",PlatformService.KINDS);var modules=strings(row,"modules",PlatformService.MODULES);if(!modules.contains("CORE") || kinds.contains("DOCTOR") && !out.get("includedProfessionals").equals(1))throw SqlServerErrors.database();out.put("kinds",kinds);out.put("domains",strings(row,"domains",Set.of("HUMAN","ANIMAL")));out.put("modules",modules);out.put("createdAt",timestamp(row));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> user(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));out.put("name",text(row,"name",false));out.put("email",text(row,"email",false));out.put("clinicalDomain",text(row,"clinicalDomain",true));out.put("credential",text(row,"credential",true));out.put("active",bool(row,"active"));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> specialty(Map<String,Object> row){Object profile=field(row,"profile");if(!(profile instanceof Map<?,?>))throw SqlServerErrors.database();return Map.of("code",text(row,"code",false),"name",text(row,"name",false),"domain",text(row,"domain",false),"dental",bool(row,"dental"),"profile",json(profile));}
 private static Map<String,Object> auditRow(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();long id=amount(row,"id");if(id==0)throw SqlServerErrors.database();out.put("id",id);out.put("tenantId",id(row,"tenantId",true));out.put("actorId",id(row,"actorId",true));String action=text(row,"action",false);if(!Set.of("TENANT_CREATED","TENANT_STATUS_CHANGED","PLAN_VERSION_CREATED","SUBSCRIPTION_CHANGED","BRANCH_SAVED","AREA_SAVED","MEMBERSHIP_SAVED","SPECIALTIES_CONFIGURED","SAAS_PAYMENT_RECORDED").contains(action))throw SqlServerErrors.database();out.put("action",action);out.put("targetId",text(row,"targetId",false));out.put("metadata",json(field(row,"metadata")));out.put("createdAt",timestamp(row));return Collections.unmodifiableMap(out);}
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
 @Override public String toString(){return "SqlServerPlatformStore[redacted]";}
}
