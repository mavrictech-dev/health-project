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

/** Unwired SAD catalog and tenant operations. Executor and REQUIRED manager must share the runtime datasource. */
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
 public Map<String,Object> savePlan(HttpServletRequest request,String id,com.mavric.health.saas.domain.Requests.Plan input){return within(()->{
  var c=context(request);boolean create=id==null;String target=create?Checks.id():Checks.id(id);validatePlan(input);
  var payload=new LinkedHashMap<String,Object>();payload.put("name",input.name());payload.put("description",input.description());payload.put("status",input.status());payload.put("baseMinor",input.baseMinor());payload.put("branchMinor",input.branchMinor());payload.put("professionalMinor",input.professionalMinor());payload.put("includedBranches",input.includedBranches());payload.put("includedProfessionals",input.includedProfessionals());payload.put("includedSpecialties",input.includedSpecialties());payload.put("maxBranches",input.maxBranches());payload.put("maxProfessionals",input.maxProfessionals());payload.put("maxSpecialties",input.maxSpecialties());payload.put("annualDiscount",input.annualDiscount());payload.put("kinds",input.kinds());payload.put("domains",input.domains());payload.put("modules",input.modules());
  String json=new tools.jackson.databind.ObjectMapper().writeValueAsString(payload);var rows=read(executor.execute(SqlServerProcedure.SAAS_PLAN_SAVE,c,target,json,create),1,SqlServerPlatformStore::plan);if(rows.size()!=1)throw SqlServerErrors.database();return matching(rows.getFirst(),target);
 });}
 private static void validatePlan(com.mavric.health.saas.domain.Requests.Plan p){
  if(p==null || p.name()==null || p.name().isBlank() || p.name().length()>100 || p.description()==null || p.description().length()>500 || p.status()==null || !Set.of("DRAFT","PUBLISHED","ARCHIVED").contains(p.status()) || p.baseMinor()<0 || p.baseMinor()>1000000000000L || p.branchMinor()<0 || p.branchMinor()>1000000000000L || p.professionalMinor()<0 || p.professionalMinor()>1000000000000L || p.includedBranches()<1 || p.includedProfessionals()<1 || p.includedSpecialties()<1 || p.maxBranches()<p.includedBranches() || p.maxBranches()>10000 || p.maxProfessionals()<p.includedProfessionals() || p.maxProfessionals()>100000 || p.maxSpecialties()<p.includedSpecialties() || p.maxSpecialties()>241 || p.annualDiscount()<0 || p.annualDiscount()>60)throw SqlServerErrors.invalid();
  if(!validSet(p.kinds(),PlatformService.KINDS) || !validSet(p.domains(),Set.of("HUMAN","ANIMAL")) || !validSet(p.modules(),PlatformService.MODULES) || !p.modules().contains("CORE") || p.kinds().contains("DOCTOR") && p.includedProfessionals()!=1)throw SqlServerErrors.invalid();
 }
 private static boolean validSet(Set<?> values,Set<String> allowed){return values!=null && !values.isEmpty() && values.stream().allMatch(v->v instanceof String text && allowed.contains(text));}
 /** Trusted server supplier; administrative IdentityService.create joins this REQUIRED unit. */
 public Map<String,Object> createUser(HttpServletRequest request,Supplier<String> createIdentity){return within(()->{
  var c=context(request);if(createIdentity==null)throw SqlServerErrors.database();String id=createIdentity.get();if(!canonical(id))throw SqlServerErrors.database();
  var rows=read(executor.execute(SqlServerProcedure.PLATFORM_USERS,c,id,1),1,SqlServerPlatformStore::user);if(rows.isEmpty())throw ApiException.missing();var row=matching(rows.getFirst(),id);var result=new LinkedHashMap<>(row);result.remove("active");return Collections.unmodifiableMap(result);
 });}
 /** Administrative owner creation and Settings callback are trusted server operations in this REQUIRED unit. */
 public Map<String,Object> createTenant(HttpServletRequest request,com.mavric.health.saas.domain.Requests.Tenant input,Supplier<String> newOwner,java.util.function.Function<Map<String,Object>,Map<String,Object>> augment){return within(()->{
  var c=context(request);validateTenant(input);if(augment==null)throw SqlServerErrors.database();String owner;
  if(input.ownerUserId()!=null){var users=read(executor.execute(SqlServerProcedure.PLATFORM_USERS,c,input.ownerUserId(),1),1,SqlServerPlatformStore::user);if(users.isEmpty())throw ApiException.missing();var u=matching(users.getFirst(),input.ownerUserId());if(!Boolean.TRUE.equals(u.get("active")))throw ApiException.missing();owner=input.ownerUserId();}
  else{if(newOwner==null)throw SqlServerErrors.database();owner=newOwner.get();if(!canonical(owner))throw SqlServerErrors.database();}
  String tenant=Checks.id(),branch=Checks.id();var sub=input.subscription();var payload=new LinkedHashMap<String,Object>();payload.put("name",input.name());payload.put("slug",input.slug());payload.put("kind",input.kind());payload.put("domain",input.domain());payload.put("timezone",input.timezone());payload.put("branchName",input.branchName());payload.put("address",input.address());payload.put("specialties",input.specialties());payload.put("subscription",Map.of("planId",sub.planId(),"cycle",sub.cycle(),"branchQuota",sub.branchQuota(),"professionalQuota",sub.professionalQuota(),"specialtyQuota",sub.specialtyQuota()));
  String json=new tools.jackson.databind.ObjectMapper().writeValueAsString(payload);var rows=read(executor.execute(SqlServerProcedure.SAAS_TENANT_CREATE,c,tenant,branch,owner,json),1,SqlServerPlatformStore::tenantRow);if(rows.size()!=1)throw SqlServerErrors.database();var row=matching(rows.getFirst(),tenant);if(!owner.equals(row.get("ownerUserId")))throw SqlServerErrors.database();var result=augment.apply(row);if(result==null)throw SqlServerErrors.database();return Collections.unmodifiableMap(new LinkedHashMap<>(result));
 });}
 private static void validateTenant(com.mavric.health.saas.domain.Requests.Tenant p){
  if(p==null || p.name()==null || p.name().isBlank() || p.name().length()>160 || p.kind()==null || !PlatformService.KINDS.contains(p.kind()) || p.domain()==null || !Set.of("HUMAN","ANIMAL").contains(p.domain()) || p.timezone()==null || p.timezone().length()>64 || p.branchName()==null || p.branchName().isBlank() || p.branchName().length()>160 || p.address()==null || p.address().length()>300 || (p.ownerUserId()==null)==(p.owner()==null))throw SqlServerErrors.invalid();
  com.mavric.health.tenancy.DomainRules.slug(p.slug());try{java.time.ZoneId.of(p.timezone());}catch(java.time.DateTimeException invalid){throw SqlServerErrors.invalid();}
  if(p.kind().equals("VETERINARY")?!p.domain().equals("ANIMAL"):!p.kind().equals("DOCTOR")&&!p.domain().equals("HUMAN"))throw SqlServerErrors.invalid();if(p.ownerUserId()!=null)Checks.id(p.ownerUserId());
  if(p.specialties()==null || p.specialties().isEmpty() || p.specialties().size()>241)throw SqlServerErrors.invalid();for(Object value:p.specialties())if(!(value instanceof String code) || code.isBlank() || code.length()>100)throw SqlServerErrors.invalid();
  var sub=p.subscription();if(sub==null || sub.cycle()==null || !Set.of("MONTHLY","YEARLY").contains(sub.cycle()) || sub.branchQuota()<1 || sub.professionalQuota()<1 || sub.specialtyQuota()<1)throw SqlServerErrors.invalid();Checks.id(sub.planId());
 }
 public Map<String,Object> pay(HttpServletRequest request,String tenantId,String invoiceId){return within(()->{
  var c=context(request);Checks.id(tenantId);Checks.id(invoiceId);var rows=read(executor.execute(SqlServerProcedure.SAAS_INVOICE_PAY,c,tenantId,invoiceId),1,SqlServerPlatformStore::invoice);if(rows.size()!=1)throw SqlServerErrors.database();var row=matching(rows.getFirst(),invoiceId);if(!tenantId.equals(row.get("tenantId")))throw SqlServerErrors.database();return row;
 });}
 private static Map<String,Object> invoice(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));out.put("tenantId",id(row,"tenantId",false));out.put("amountMinor",amount(row,"amountMinor"));String currency=text(row,"currency",false),cycle=text(row,"cycle",false),status=text(row,"status",false);if(currency.length()!=3 || cycle.length()>10 || !Set.of("PENDING","PAID").contains(status))throw SqlServerErrors.database();out.put("currency",currency);out.put("cycle",cycle);out.put("status",status);out.put("createdAt",timestamp(row));String paid=text(row,"paidAt",true);if(paid!=null)try{if(!paid.endsWith("Z") || java.time.Instant.parse(paid).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException invalid){throw SqlServerErrors.database();}out.put("paidAt",paid);return Collections.unmodifiableMap(out);}
 public List<Map<String,Object>> tenants(HttpServletRequest request,int limit){return within(()->{var c=context(request);int size=Checks.limit(limit);return read(executor.execute(SqlServerProcedure.PLATFORM_TENANTS,c,null,size),size,SqlServerPlatformStore::tenantRow);});}
 public Map<String,Object> tenant(HttpServletRequest request,String id){return within(()->{
  var c=context(request);Checks.id(id);var rows=read(executor.execute(SqlServerProcedure.PLATFORM_TENANTS,c,id,1),1,SqlServerPlatformStore::tenantRow);
  if(rows.isEmpty())throw ApiException.missing();return matching(rows.getFirst(),id);
 });}
 /** Trusted server callback only, for Settings URL augmentation before the status transaction commits. */
 public Map<String,Object> status(HttpServletRequest request,String id,String status,String reason,java.util.function.Function<Map<String,Object>,Map<String,Object>> augment){return within(()->{
  var c=context(request);Checks.id(id);
  if(status==null || !Set.of("TRIAL","ACTIVE","SUSPENDED","CANCELLED").contains(status) || reason==null || reason.isBlank() || reason.length()>500)throw SqlServerErrors.invalid();
  if(augment==null)throw SqlServerErrors.database();
  var rows=read(executor.execute(SqlServerProcedure.SAAS_TENANT_STATUS,c,id,status,reason),1,SqlServerPlatformStore::tenantRow);
  if(rows.size()!=1)throw SqlServerErrors.database();var row=matching(rows.getFirst(),id);var result=augment.apply(row);
  if(result==null)throw SqlServerErrors.database();return Collections.unmodifiableMap(new LinkedHashMap<>(result));
 });}
 private static Map<String,Object> matching(Map<String,Object> row,String id){if(!id.equals(row.get("id")))throw SqlServerErrors.database();return row;}
 private static Map<String,Object> tenantRow(Map<String,Object> row){
  var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","ownerUserId","planId"))out.put(key,id(row,key,false));
  for(String key:List.of("name","ownerName","ownerEmail","planName"))out.put(key,text(row,key,false));
  String slug=text(row,"slug",false),kind=text(row,"kind",false),domain=text(row,"domain",false),status=text(row,"status",false),timezone=text(row,"timezone",false),renewal=text(row,"renewalDate",false);
  try{com.mavric.health.tenancy.DomainRules.slug(slug);java.time.ZoneId.of(timezone);if(!renewal.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}") || !java.time.LocalDate.parse(renewal).toString().equals(renewal) || java.time.LocalDate.parse(renewal).getYear()<1)throw SqlServerErrors.database();}catch(RuntimeException invalid){throw SqlServerErrors.database();}
  if(!PlatformService.KINDS.contains(kind) || !Set.of("HUMAN","ANIMAL").contains(domain) || !Set.of("TRIAL","ACTIVE","SUSPENDED","CANCELLED").contains(status))throw SqlServerErrors.database();
  if(kind.equals("VETERINARY")?!domain.equals("ANIMAL"):!kind.equals("DOCTOR")&&!domain.equals("HUMAN"))throw SqlServerErrors.database();
  out.put("slug",slug);out.put("kind",kind);out.put("domain",domain);out.put("status",status);out.put("timezone",timezone);out.put("renewalDate",renewal);out.put("createdAt",timestamp(row));
  String cycle=text(row,"cycle",false);if(!Set.of("MONTHLY","YEARLY").contains(cycle))throw SqlServerErrors.database();out.put("cycle",cycle);
  for(String key:List.of("planVersion","branchQuota","professionalQuota","specialtyQuota","includedBranches","includedProfessionals"))out.put(key,integer(row,key,1));
  int discount=integer(row,"annualDiscount",0);if(discount>60)throw SqlServerErrors.database();out.put("annualDiscount",discount);
  for(String key:List.of("baseMinor","branchMinor","professionalMinor","branchesUsed","professionalsUsed","specialtiesUsed"))out.put(key,amount(row,key));
  var modules=strings(row,"modules",PlatformService.MODULES);if(!modules.contains("CORE"))throw SqlServerErrors.database();out.put("modules",modules);return Collections.unmodifiableMap(out);
 }
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
