package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.math.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Unwired tenant reads. REQUIRED manager and executor must share the future runtime datasource. */
public final class SqlServerOrganizationStore {
 private static final Set<String> ROLES=Set.of("ADM","REC","PRO","ASI","DIA","FAR","CAJ","ALM","PAC","RES","AUD");
 private static final Set<String> KINDS=Set.of("DOCTOR","CLINIC","HOSPITAL","VETERINARY","DENTAL","SPECIALTY_CENTER");
 private static final Set<String> MODULES=Set.of("CORE","PORTAL","DENTAL","DIAGNOSTICS","PHARMACY","FINANCE","INVENTORY","HOSPITAL","SURGERY","ADVANCED","VET_POPULATION","REPORTS");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerOrganizationStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException error){throw SqlServerErrors.map(error);}}
 private static SqlServerContext context(HttpServletRequest request,boolean admin){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(admin && !actor.roles().contains("ADM"))throw ApiException.forbidden();var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return c;
 }
 public List<Map<String,Object>> lookup(HttpServletRequest request,String email){return within(()->{var c=context(request,true);if(email==null || email.length()>254)throw SqlServerErrors.invalid();return read(executor.execute(SqlServerProcedure.ORGANIZATION_LOOKUP,c,email.toLowerCase(Locale.ROOT)),SqlServerOrganizationStore::identity);});}
 public List<Map<String,Object>> directory(HttpServletRequest request){return within(()->read(executor.execute(SqlServerProcedure.ORGANIZATION_DIRECTORY,context(request,false)),SqlServerOrganizationStore::branch));}
 public List<Map<String,Object>> professionals(HttpServletRequest request,String branch){return within(()->{var c=context(request,false);if(branch!=null)Checks.id(branch);return read(executor.execute(SqlServerProcedure.ORGANIZATION_PROFESSIONALS,c,branch),SqlServerOrganizationStore::professional);});}
 public List<Map<String,Object>> catalog(HttpServletRequest request){return within(()->{var c=context(request,false);var tenant=(TenantRef)request.getAttribute("health.tenant");return read(executor.execute(SqlServerProcedure.ORGANIZATION_CATALOG,c),row->specialty(row,tenant));});}
 public List<Map<String,Object>> availablePlans(HttpServletRequest request){return within(()->{var c=context(request,true);var tenant=(TenantRef)request.getAttribute("health.tenant");return read(executor.execute(SqlServerProcedure.ORGANIZATION_PLANS,c),row->{var mapped=plan(row);if(!mapped.get("status").equals("PUBLISHED") || !((List<?>)mapped.get("kinds")).contains(tenant.kind()) || !((List<?>)mapped.get("domains")).contains(tenant.domain()))throw SqlServerErrors.database();return mapped;});});}
 private static List<Map<String,Object>> read(SqlServerExecutor.Result result,java.util.function.Function<Map<String,Object>,Map<String,Object>> mapper){if(result==null || result.resultSets().size()!=1)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(mapper).toList();}
 private static Map<String,Object> identity(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));for(String key:List.of("name","email"))out.put(key,text(row,key,false));for(String key:List.of("clinicalDomain","credential"))out.put(key,text(row,key,true));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> branch(Map<String,Object> row){if(!bool(row,"active"))throw SqlServerErrors.database();return Map.of("id",id(row,"id",false),"name",text(row,"name",false),"address",text(row,"address",false),"external",bool(row,"external"),"active",true);}
 private static Map<String,Object> professional(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));out.put("name",text(row,"name",false));out.put("clinicalDomain",text(row,"clinicalDomain",true));out.put("credential",text(row,"credential",true));var roles=strings(row,"roles",ROLES);if(!roles.contains("PRO"))throw SqlServerErrors.database();out.put("roles",roles);return Collections.unmodifiableMap(out);}
 private static Map<String,Object> specialty(Map<String,Object> row,TenantRef tenant){String domain=text(row,"domain",false);Boolean dental=bool(row,"dental");Object profile=field(row,"profile");if(!domain.equals(tenant.domain()) || tenant.kind().equals("DENTAL")&&!dental || !(profile instanceof Map<?,?>))throw SqlServerErrors.database();return Map.of("code",text(row,"code",false),"name",text(row,"name",false),"domain",domain,"dental",dental,"profile",json(profile));}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object v=field(row,key);if(v==null && nullable)return null;if(!(v instanceof String value))throw SqlServerErrors.database();return value;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException e){return false;}}
 private static String id(Map<String,Object> row,String key,boolean nullable){String v=text(row,key,nullable);if(v!=null && !canonical(v))throw SqlServerErrors.database();return v;}
 private static Integer integer(Map<String,Object> row,String key,int min){if(!(field(row,key) instanceof Integer value) || value<min)throw SqlServerErrors.database();return value;}
 private static Long amount(Map<String,Object> row,String key){if(!(field(row,key) instanceof Long value) || value<0)throw SqlServerErrors.database();return value;}
 private static String timestamp(Map<String,Object> row){String v=text(row,"createdAt",false);try{if(!v.endsWith("Z") || java.time.Instant.parse(v).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException e){throw SqlServerErrors.database();}return v;}
 private static Boolean bool(Map<String,Object> row,String key){if(!(field(row,key) instanceof Boolean value))throw SqlServerErrors.database();return value;}
 private static List<String> strings(Map<String,Object> row,String key,Set<String> allowed){if(!(field(row,key) instanceof List<?> list) || list.isEmpty())throw SqlServerErrors.database();List<String> result=new ArrayList<>();Set<String> unique=new HashSet<>();for(Object v:list){if(!(v instanceof String value) || !allowed.contains(value) || !unique.add(value))throw SqlServerErrors.database();result.add(value);}return List.copyOf(result);}
 private static Map<String,Object> plan(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();String id=id(row,"id",false),plan=id(row,"planId",false);int current=integer(row,"currentVersion",1),version=integer(row,"version",1);if(!id.equals(plan)||current!=version)throw SqlServerErrors.database();out.put("id",id);out.put("planId",plan);out.put("currentVersion",current);out.put("version",version);for(String key:List.of("name","description"))out.put(key,text(row,key,false));String status=text(row,"status",false);if(!Set.of("DRAFT","PUBLISHED","ARCHIVED").contains(status))throw SqlServerErrors.database();out.put("status",status);for(String key:List.of("baseMinor","branchMinor","professionalMinor"))out.put(key,amount(row,key));for(String suffix:List.of("Branches","Professionals","Specialties")){int included=integer(row,"included"+suffix,1),max=integer(row,"max"+suffix,1);if(max<included)throw SqlServerErrors.database();out.put("included"+suffix,included);out.put("max"+suffix,max);}int discount=integer(row,"annualDiscount",0);if(discount>60)throw SqlServerErrors.database();out.put("annualDiscount",discount);var kinds=strings(row,"kinds",KINDS);var modules=strings(row,"modules",MODULES);if(!modules.contains("CORE") || kinds.contains("DOCTOR") && !out.get("includedProfessionals").equals(1))throw SqlServerErrors.database();out.put("kinds",kinds);out.put("domains",strings(row,"domains",Set.of("HUMAN","ANIMAL")));out.put("modules",modules);out.put("createdAt",timestamp(row));return Collections.unmodifiableMap(out);}
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
 @Override public String toString(){return "SqlServerOrganizationStore[redacted]";}
}
