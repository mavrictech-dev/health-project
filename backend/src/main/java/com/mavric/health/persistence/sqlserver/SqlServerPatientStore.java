package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.math.*;
import java.time.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.patients.domain.Requests.Patient;
import com.mavric.health.shared.*;
/** Unwired tenant-wide patient persistence. Executor/manager must share the runtime datasource; mapper is the existing configured mapper. */
public final class SqlServerPatientStore {
 private static final Set<String> READ=Set.of("ADM","REC","PRO","ASI","AUD"),WRITE=Set.of("ADM","REC","PRO");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;private final ObjectMapper mapper;
 public SqlServerPatientStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));this.mapper=Objects.requireNonNull(mapper);}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request,boolean write){return context(request,write?"CORE":null,write?WRITE:READ);}
 private static SqlServerContext context(HttpServletRequest request,String module,Set<String> roles){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();if(tenant.domain()==null || !Set.of("HUMAN","ANIMAL").contains(tenant.domain()))throw SqlServerErrors.database();
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();
  if(module!=null){if(tenant.status()==null || tenant.modules()==null)throw SqlServerErrors.database();if(!Set.of("TRIAL","ACTIVE").contains(tenant.status()))throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones est\u00e1n suspendidas.");if(!tenant.modules().contains(module))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");}return c;
 }
 public List<Map<String,Object>> list(HttpServletRequest request,String query,int limit,int offset){return within(()->{var c=context(request,false);String value=query==null?"":query;if(value.length()>3998)throw SqlServerErrors.invalid();int size=Checks.limit(limit);return read(executor.execute(SqlServerProcedure.PATIENTS_LIST,c,value,size,Math.max(0,offset)),request,size);});}
 public Map<String,Object> get(HttpServletRequest request,String id){return within(()->{var c=context(request,false);Checks.id(id);var rows=read(executor.execute(SqlServerProcedure.PATIENT_GET,c,id),request,1);if(rows.isEmpty())throw ApiException.missing();return matching(rows.getFirst(),id);});}
 public Map<String,Object> save(HttpServletRequest request,String id,Patient input,int expected){return within(()->{
  var c=context(request,true);if(input==null || id==null&&expected!=0 || id!=null&&expected<1)throw SqlServerErrors.invalid();if(id!=null)Checks.id(id);var tenant=(TenantRef)request.getAttribute("health.tenant");
  if(input.name()==null || input.name().isBlank() || input.name().length()>160 || input.domain()==null || !Set.of("HUMAN","ANIMAL").contains(input.domain()) || !input.domain().equals(tenant.domain()) || input.identifier()==null || input.identifier().isBlank() || input.identifier().length()>100 || input.species()!=null&&input.species().length()>80 || input.domain().equals("ANIMAL")&&(input.species()==null || input.species().isBlank()) || input.contact()==null || input.allergies()==null)throw SqlServerErrors.invalid();
  LocalDate birth=input.birthDate();if(birth!=null && (birth.getYear()<1 || birth.getYear()>9999 || birth.isAfter(LocalDate.now(ZoneOffset.UTC))))throw SqlServerErrors.invalid();var allergies=new ArrayList<String>();for(Object value:input.allergies()){if(!(value instanceof String text) || text.length()>160)throw SqlServerErrors.invalid();allergies.add(text);}
  var contact=json(input.contact(),true,0,Collections.newSetFromMap(new IdentityHashMap<>()));String payload;try{Checks.json(contact,mapper);var body=new LinkedHashMap<String,Object>();body.put("name",input.name());body.put("domain",input.domain());body.put("identifier",input.identifier());body.put("birthDate",birth==null?null:birth.toString());body.put("species",input.species());body.put("contact",contact);body.put("allergies",List.copyOf(allergies));payload=mapper.writeValueAsString(body);}catch(tools.jackson.core.JacksonException invalid){throw SqlServerErrors.invalid();}
  String key=id==null?Checks.id():id;var rows=read(executor.execute(SqlServerProcedure.PATIENT_SAVE,c,key,payload,expected),request,1);if(rows.size()!=1)throw SqlServerErrors.database();return matching(rows.getFirst(),key);
 });}
 /** Administrative read: historical link values are projected, never interpreted as write permissions. */
 public List<Map<String,Object>> links(HttpServletRequest request,String patient,int limit,int offset){return within(()->{
  var c=context(request,null,Set.of("ADM","REC"));
  if(c.roles().contains("PAC") || c.roles().contains("RES"))throw ApiException.forbidden();
  if(!canonical(c.requestId()))throw SqlServerErrors.database();
  Checks.id(patient);int size=Checks.limit(limit);
  var result=executor.execute(SqlServerProcedure.PATIENT_LINKS_LIST,c,patient,size,Math.max(0,offset));
  if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>size)throw SqlServerErrors.database();
  var users=new HashSet<String>();var rows=new ArrayList<Map<String,Object>>();
  for(var row:result.resultSets().getFirst()){
   String tenant=id(row,"tenantId"),key=id(row,"patientId"),user=id(row,"userId");
   if(!c.tenantId().equals(tenant) || !patient.equals(key) || !users.add(user))throw SqlServerErrors.database();
   String name=text(row,"userName",false),relationship=text(row,"relationship",false);
   if(name.length()>160 || relationship.length()>80)throw SqlServerErrors.database();
   boolean active=bool(row,"active");Object raw=field(row,"scopes");
   if(!(raw instanceof List<?> values))throw SqlServerErrors.database();
   var scopes=new ArrayList<String>();for(Object value:values){if(!(value instanceof String scope))throw SqlServerErrors.database();scopes.add(scope);}
   var out=new LinkedHashMap<String,Object>();out.put("tenantId",tenant);out.put("patientId",key);out.put("userId",user);out.put("userName",name);out.put("relationship",relationship);out.put("active",active);out.put("scopes",List.copyOf(scopes));rows.add(Collections.unmodifiableMap(out));
  }
  return List.copyOf(rows);
 });}
 private static SqlServerContext managementContext(HttpServletRequest request){
  var c=context(request,"PORTAL",Set.of("ADM","REC"));
  if(c.roles().contains("PAC") || c.roles().contains("RES"))throw ApiException.forbidden();
  if(!canonical(c.requestId()))throw SqlServerErrors.database();
  return c;
 }
 private static void managementId(String id){if(!com.mavric.health.patients.domain.Requests.linkId(id))throw SqlServerErrors.invalid();}
 private static Map<String,Object> managementRow(SqlServerExecutor.Result result,Set<String> keys){
  if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()!=1)throw SqlServerErrors.database();
  var row=result.resultSets().getFirst().getFirst();
  if(row==null || !row.keySet().equals(keys))throw SqlServerErrors.database();
  return row;
 }
 public Map<String,Object> link(HttpServletRequest request,String patient,com.mavric.health.patients.domain.Requests.Link input){return within(()->{
  var c=managementContext(request);managementId(patient);
  if(input==null || !input.valid())throw SqlServerErrors.invalid();
  var body=new LinkedHashMap<String,Object>();body.put("userId",input.userId());body.put("expectedRevision",input.expectedRevision());body.put("active",input.active());
  if(input.active()){body.put("relationship",input.relationship());body.put("scopes",input.scopes());}
  String payload;try{payload=mapper.writeValueAsString(body);}catch(tools.jackson.core.JacksonException invalid){throw SqlServerErrors.invalid();}
  var row=managementRow(executor.execute(SqlServerProcedure.PATIENT_LINK_SAVE,c,patient,payload),Set.of("tenantId","patientId","userId","active","revision"));
  if(!c.tenantId().equals(id(row,"tenantId")) || !patient.equals(id(row,"patientId")) || !input.userId().equals(id(row,"userId"))
   || !input.active().equals(bool(row,"active")) || (long)integer(row,"revision")!=(long)input.expectedRevision()+1L)throw SqlServerErrors.database();
  return Collections.unmodifiableMap(new LinkedHashMap<>(row));
 });}
 public Map<String,Object> linkEdit(HttpServletRequest request,String patient,String user){return within(()->{
  var c=managementContext(request);managementId(patient);managementId(user);
  var row=managementRow(executor.execute(SqlServerProcedure.PATIENT_LINK_EDIT_GET,c,patient,user),Set.of("tenantId","patientId","userId","userName","relationship","active","scopes","revision"));
  if(!c.tenantId().equals(id(row,"tenantId")) || !patient.equals(id(row,"patientId")) || !user.equals(id(row,"userId"))
   || text(row,"userName",false).length()>160 || text(row,"relationship",false).length()>80)throw SqlServerErrors.database();
  bool(row,"active");integer(row,"revision");
  var out=new LinkedHashMap<>(row);out.put("scopes",linkJson(field(row,"scopes")));
  return Collections.unmodifiableMap(out);
 });}
 /** Iterative, immutable JSON-data copy. Cycles, executable/custom values and nonfinite numbers fail closed. */
 private record LinkJsonCopy(Object value,java.util.function.Consumer<Object> done,boolean complete){}
 private static Object linkJson(Object value){
  var tasks=new ArrayDeque<LinkJsonCopy>();var ancestors=Collections.newSetFromMap(new IdentityHashMap<Object,Boolean>());var root=new Object[1];
  tasks.push(new LinkJsonCopy(value,v->root[0]=v,false));
  while(!tasks.isEmpty()){
   var task=tasks.pop();if(task.complete()){task.done().accept(null);continue;}var source=task.value();
   if(source==null || source instanceof String || source instanceof Boolean || source instanceof Byte || source instanceof Short || source instanceof Integer || source instanceof Long || source instanceof BigInteger || source instanceof BigDecimal
    || source instanceof Double n && Double.isFinite(n) || source instanceof Float f && Float.isFinite(f)){task.done().accept(source);continue;}
   if(!(source instanceof Map<?,?>) && !(source instanceof List<?>) || !ancestors.add(source))throw SqlServerErrors.database();
   if(source instanceof List<?> list){
    var copy=new ArrayList<Object>(Collections.nCopies(list.size(),null));
    tasks.push(new LinkJsonCopy(source,ignored->{ancestors.remove(source);task.done().accept(Collections.unmodifiableList(copy));},true));
    for(int i=list.size()-1;i>=0;i--){int index=i;tasks.push(new LinkJsonCopy(list.get(i),v->copy.set(index,v),false));}
   }else{
    var entries=new ArrayList<>(((Map<?,?>)source).entrySet());var copy=new LinkedHashMap<String,Object>();
    tasks.push(new LinkJsonCopy(source,ignored->{ancestors.remove(source);task.done().accept(Collections.unmodifiableMap(copy));},true));
    for(int i=entries.size()-1;i>=0;i--){var entry=entries.get(i);if(!(entry.getKey() instanceof String key))throw SqlServerErrors.database();tasks.push(new LinkJsonCopy(entry.getValue(),v->copy.put(key,v),false));}
   }
  }
  return root[0];
 }
 public Map<String,Object> history(HttpServletRequest request,String patient){return within(()->{
  var c=context(request,null,Set.of("PRO","ASI","AUD"));Checks.id(patient);var result=executor.execute(SqlServerProcedure.PATIENT_HISTORY,c,patient);if(result==null || result.resultSets().size()!=4)throw SqlServerErrors.database();var sets=result.resultSets();if(sets.get(0).size()>200 || sets.get(1).size()>1000 || sets.get(2).size()>200 || sets.get(3).size()!=1)throw SqlServerErrors.database();var limits=sets.get(3).getFirst();if(!patient.equals(id(limits,"patientId")) || integer(limits,"encountersLimit")!=200 || integer(limits,"entriesLimit")!=1000 || integer(limits,"documentsLimit")!=200)throw SqlServerErrors.database();var encounters=sets.get(0).stream().map(row->encounter(row,c.tenantId(),patient)).toList();var entries=sets.get(1).stream().map(row->entry(row,c.tenantId())).toList();var documents=sets.get(2).stream().map(row->document(row,c.tenantId(),patient)).toList();return Map.of("patientId",patient,"encounters",encounters,"entries",entries,"documents",documents,"limits",Map.of("encounters",200,"entries",1000,"documents",200));
 });}
 private static Map<String,Object> encounter(Map<String,Object> row,String tenant,String patient){same(row,tenant,patient);var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId","branchId","professionalId"))out.put(key,id(row,key));out.put("specialtyCode",text(row,"specialtyCode",false));String status=text(row,"status",false);if(!Set.of("ACTIVE","PENDING","FINALIZED").contains(status))throw SqlServerErrors.database();out.put("status",status);out.put("note",text(row,"note",false));out.put("revision",integer(row,"revision"));out.put("profileSnapshot",outputJson(field(row,"profileSnapshot")));out.put("createdAt",time(row,"createdAt",false));out.put("finalizedAt",time(row,"finalizedAt",true));String active=nullableId(row,"activePatient");if(active!=null && !active.equals(patient))throw SqlServerErrors.database();out.put("activePatient",active);return Collections.unmodifiableMap(out);}
 private static Map<String,Object> entry(Map<String,Object> row,String tenant){if(!tenant.equals(id(row,"tenantId")))throw SqlServerErrors.database();var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","encounterId","actorId"))out.put(key,id(row,key));String kind=text(row,"kind",false);if(!Set.of("EVALUATION","OBSERVATION","ANNOTATION","ORDER","PRESCRIPTION").contains(kind))throw SqlServerErrors.database();out.put("kind",kind);out.put("payload",outputJson(field(row,"payload")));out.put("profileSnapshot",outputJson(field(row,"profileSnapshot")));out.put("createdAt",time(row,"createdAt",false));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> document(Map<String,Object> row,String tenant,String patient){same(row,tenant,patient);var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId"))out.put(key,id(row,key));for(String key:List.of("encounterId","originalId","signerId"))out.put(key,nullableId(row,key));for(String key:List.of("title","type","content"))out.put(key,text(row,key,false));String status=text(row,"status",false);if(!Set.of("DRAFT","SIGNED").contains(status))throw SqlServerErrors.database();out.put("status",status);out.put("revision",integer(row,"revision"));out.put("signedAt",time(row,"signedAt",true));String hash=text(row,"contentHash",true);if(hash!=null && !hash.matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();out.put("contentHash",hash);out.put("published",bool(row,"published"));out.put("withdrawn",bool(row,"withdrawn"));out.put("createdAt",time(row,"createdAt",false));return Collections.unmodifiableMap(out);}
 private static void same(Map<String,Object> row,String tenant,String patient){if(!tenant.equals(id(row,"tenantId")) || !patient.equals(id(row,"patientId")))throw SqlServerErrors.database();}
 private static Object outputJson(Object value){return json(value,false,0,Collections.newSetFromMap(new IdentityHashMap<>()));}
 private static String nullableId(Map<String,Object> row,String key){String value=text(row,key,true);if(value!=null && !canonical(value))throw SqlServerErrors.database();return value;}
 private static Integer integer(Map<String,Object> row,String key){if(!(field(row,key) instanceof Integer value) || value<1)throw SqlServerErrors.database();return value;}
 private static Boolean bool(Map<String,Object> row,String key){if(!(field(row,key) instanceof Boolean value))throw SqlServerErrors.database();return value;}
 private static String time(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null)try{if(!value.endsWith("Z") || Instant.parse(value).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException invalid){throw SqlServerErrors.database();}return value;}
 private static Map<String,Object> matching(Map<String,Object> row,String id){if(!id.equals(row.get("id")))throw SqlServerErrors.database();return row;}
 private static List<Map<String,Object>> read(SqlServerExecutor.Result result,HttpServletRequest request,int max){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();var tenant=(TenantRef)request.getAttribute("health.tenant");return result.resultSets().getFirst().stream().map(row->patient(row,tenant)).toList();}
 private static Map<String,Object> patient(Map<String,Object> row,TenantRef tenant){String id=id(row,"id"),target=id(row,"tenantId"),domain=text(row,"domain",false);if(!target.equals(tenant.id()) || !domain.equals(tenant.domain()))throw SqlServerErrors.database();var out=new LinkedHashMap<String,Object>();out.put("id",id);out.put("tenantId",target);out.put("name",text(row,"name",false));out.put("domain",domain);out.put("identifier",text(row,"identifier",false));String birth=text(row,"birthDate",true);if(birth!=null)date(birth);out.put("birthDate",birth);out.put("species",text(row,"species",true));Object contact=field(row,"contact");if(!(contact instanceof Map<?,?>))throw SqlServerErrors.database();out.put("contact",json(contact,false,0,Collections.newSetFromMap(new IdentityHashMap<>())));Object values=field(row,"allergies");if(!(values instanceof List<?> list))throw SqlServerErrors.database();var allergies=new ArrayList<String>();for(Object value:list){if(!(value instanceof String item))throw SqlServerErrors.database();allergies.add(item);}out.put("allergies",List.copyOf(allergies));if(!(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();out.put("revision",revision);String created=text(row,"createdAt",false);try{if(!created.endsWith("Z") || Instant.parse(created).getNano()%1000!=0)throw SqlServerErrors.database();}catch(java.time.DateTimeException invalid){throw SqlServerErrors.database();}out.put("createdAt",created);return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key){String value=text(row,key,false);if(!canonical(value))throw SqlServerErrors.database();return value;}
 private static void date(String value){try{if(!value.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}") || !LocalDate.parse(value).toString().equals(value) || LocalDate.parse(value).getYear()<1)throw SqlServerErrors.database();}catch(java.time.DateTimeException invalid){throw SqlServerErrors.database();}}
 private static ApiException invalidJson(boolean input){return input?SqlServerErrors.invalid():SqlServerErrors.database();}
 private static Object json(Object value,boolean input,int depth,Set<Object> ancestors){
  if(input && depth>30)throw invalidJson(true);if(value==null || value instanceof String || value instanceof Boolean || value instanceof Byte || value instanceof Short || value instanceof Integer || value instanceof Long || value instanceof BigInteger || value instanceof BigDecimal)return value;if(value instanceof Double decimal && Double.isFinite(decimal) || value instanceof Float floating && Float.isFinite(floating))return value;
  if(!(value instanceof Map<?,?>) && !(value instanceof List<?>) || !ancestors.add(value))throw invalidJson(input);try{if(value instanceof List<?> list){var copy=new ArrayList<Object>();for(Object item:list)copy.add(json(item,input,depth+1,ancestors));return Collections.unmodifiableList(copy);}var copy=new LinkedHashMap<String,Object>();((Map<?,?>)value).forEach((key,item)->{if(!(key instanceof String name))throw invalidJson(input);copy.put(name,json(item,input,depth+1,ancestors));});return Collections.unmodifiableMap(copy);}finally{ancestors.remove(value);}
 }
 @Override public String toString(){return "SqlServerPatientStore[redacted]";}
}
