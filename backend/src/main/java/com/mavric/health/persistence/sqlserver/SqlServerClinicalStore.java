package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.math.*;
import java.time.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import tools.jackson.databind.ObjectMapper;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
import com.mavric.health.clinical.domain.Requests.*;
/** Explicit, unwired adapter. Executor/REQUIRED manager must use the same runtime datasource;
 * mapper must be the configured Spring mapper. Templates do not establish durable guarantees. */
public final class SqlServerClinicalStore {
 private static final Set<String> READ=Set.of("PRO","ASI","AUD"),KINDS=Set.of("EVALUATION","OBSERVATION","ANNOTATION","ORDER","PRESCRIPTION");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;private final ObjectMapper mapper;
 public SqlServerClinicalStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));this.mapper=Objects.requireNonNull(mapper);}
 /** Server orchestration keeps prior audited read, validation and mutation in one REQUIRED unit. */
 public <T>T required(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest req,Set<String> roles,boolean write){
  if(req==null)throw SqlServerErrors.database();Object host=req.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(req.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(req,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();
  if(write){if(!Set.of("TRIAL","ACTIVE").contains(Objects.toString(tenant.status(),"")))throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones est\u00e1n suspendidas.");if(tenant.modules()==null || !tenant.modules().contains("CORE"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");}return c;
 }
 public Map<String,Object> get(HttpServletRequest req,String id){return required(()->{var c=context(req,READ,false);Checks.id(id);return visit(executor.execute(SqlServerProcedure.ENCOUNTER_GET,c,id),c.tenantId(),id,true);});}
 public Map<String,Object> start(HttpServletRequest req,Start p){return required(()->{
  var c=context(req,Set.of("PRO"),true);if(p==null)throw SqlServerErrors.invalid();Checks.id(p.patientId());Checks.id(p.branchId());if(p.specialtyCode()==null || !p.specialtyCode().matches("[-A-Za-z0-9_:]{1,100}"))throw SqlServerErrors.invalid();
  String id=Checks.id();var row=visit(executor.execute(SqlServerProcedure.ENCOUNTER_START,c,id,mapper.writeValueAsString(p)),c.tenantId(),id,false);
  if(!p.patientId().equals(row.get("patientId")) || !p.branchId().equals(row.get("branchId")) || !p.specialtyCode().equals(row.get("specialtyCode")) || !c.actorId().equals(row.get("professionalId")) || !"ACTIVE".equals(row.get("status")) || !Integer.valueOf(1).equals(row.get("revision")) || !"".equals(row.get("note")))throw SqlServerErrors.database();return row;
 });}
 public Map<String,Object> note(HttpServletRequest req,String id,Note p,boolean finalize){return required(()->{
  var c=context(req,Set.of("PRO"),true);Checks.id(id);if(p==null || p.expectedRevision()<1 || p.note()==null || p.note().length()>100000)throw SqlServerErrors.invalid();if(finalize && p.note().isBlank())throw ApiException.invalid("Registra el resumen de la visita antes de finalizar.");
  var row=visit(executor.execute(SqlServerProcedure.ENCOUNTER_NOTE,c,id,p.expectedRevision(),p.note(),finalize),c.tenantId(),id,false);
  if(!p.note().equals(row.get("note")) || ((Integer)row.get("revision")).longValue()!=(long)p.expectedRevision()+1 || !c.actorId().equals(row.get("professionalId")) || finalize&&!"FINALIZED".equals(row.get("status")))throw SqlServerErrors.database();return row;
 });}
 public Map<String,Object> payload(Map<String,Object> value){if(value==null)throw SqlServerErrors.invalid();@SuppressWarnings("unchecked") var copy=(Map<String,Object>)json(value,true,0,Collections.newSetFromMap(new IdentityHashMap<>()));return copy;}
 public Map<String,Object> entry(HttpServletRequest req,String encounter,Entry p){return required(()->{
  var roles=p!=null && "OBSERVATION".equals(p.kind())?Set.of("PRO","ASI"):Set.of("PRO");var c=context(req,roles,true);Checks.id(encounter);if(p==null || p.kind()==null || !KINDS.contains(p.kind()))throw SqlServerErrors.invalid();
  var body=payload(p.payload());Checks.json(body,mapper);if(p.kind().equals("ANNOTATION") && Set.of("HUMAN_DENTAL","VET_DENTAL","PERIODONTAL","ENDO","ORTHODONTIC","PROSTHETIC").contains(Objects.toString(body.get("component"),"")) && !((TenantRef)req.getAttribute("health.tenant")).modules().contains("DENTAL"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  String id=Checks.id();var result=executor.execute(SqlServerProcedure.CLINICAL_ENTRY_ADD,c,id,encounter,p.kind(),mapper.writeValueAsString(body));if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()!=1)throw SqlServerErrors.database();
  var row=entryRow(result.resultSets().getFirst().getFirst(),c.tenantId(),encounter);if(!id.equals(row.get("id")) || !c.actorId().equals(row.get("actorId")) || !p.kind().equals(row.get("kind")))throw SqlServerErrors.database();return row;
 });}
 private static Map<String,Object> visit(SqlServerExecutor.Result result,String tenant,String id,boolean missing){
  if(result==null || result.resultSets().size()!=2)throw SqlServerErrors.database();var roots=result.resultSets().getFirst();if(roots.isEmpty() && missing)throw ApiException.missing();if(roots.size()!=1)throw SqlServerErrors.database();var root=encounter(roots.getFirst(),tenant);if(!id.equals(root.get("id")))throw SqlServerErrors.database();
  var entries=new ArrayList<Map<String,Object>>();var ids=new HashSet<String>();for(var value:result.resultSets().get(1)){var item=entryRow(value,tenant,id);if(!ids.add((String)item.get("id")))throw SqlServerErrors.database();entries.add(item);}root.put("entries",Collections.unmodifiableList(entries));return Collections.unmodifiableMap(root);
 }
 private static LinkedHashMap<String,Object> encounter(Map<String,Object> row,String tenant){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId","branchId","professionalId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")))throw SqlServerErrors.database();out.put("specialtyCode",text(row,"specialtyCode",false));String status=text(row,"status",false);if(!Set.of("ACTIVE","PENDING","FINALIZED").contains(status))throw SqlServerErrors.database();out.put("status",status);out.put("note",text(row,"note",false));out.put("revision",integer(row,"revision"));out.put("profileSnapshot",output(field(row,"profileSnapshot")));out.put("createdAt",time(row,"createdAt",false));String finalized=time(row,"finalizedAt",true),active=text(row,"activePatient",true);if(active!=null && (!canonical(active) || !active.equals(out.get("patientId"))))throw SqlServerErrors.database();if(status.equals("FINALIZED")?active!=null:!Objects.equals(active,out.get("patientId")))throw SqlServerErrors.database();out.put("finalizedAt",finalized);out.put("activePatient",active);return out;}
 private static Map<String,Object> entryRow(Map<String,Object> row,String tenant,String encounter){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","encounterId","actorId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")) || !encounter.equals(out.get("encounterId")))throw SqlServerErrors.database();String kind=text(row,"kind",false);if(!KINDS.contains(kind))throw SqlServerErrors.database();out.put("kind",kind);out.put("payload",output(field(row,"payload")));out.put("profileSnapshot",output(field(row,"profileSnapshot")));out.put("createdAt",time(row,"createdAt",false));return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key){String value=text(row,key,false);if(!canonical(value))throw SqlServerErrors.database();return value;}
 private static Integer integer(Map<String,Object> row,String key){if(!(field(row,key) instanceof Integer n) || n<1)throw SqlServerErrors.database();return n;}
 private static String time(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null)try{Instant parsed=Instant.parse(value);if(!value.endsWith("Z") || parsed.getNano()%1000!=0 || parsed.isBefore(Instant.parse("0001-01-01T00:00:00Z")) || parsed.isAfter(Instant.parse("9999-12-31T23:59:59.999999Z")))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}return value;}
 private static Object output(Object value){return json(value,false,0,Collections.newSetFromMap(new IdentityHashMap<>()));}
 private static ApiException badJson(boolean input){return input?SqlServerErrors.invalid():SqlServerErrors.database();}
 private static Object json(Object value,boolean input,int depth,Set<Object> ancestors){
  if(input && depth>30)throw badJson(true);if(value==null || value instanceof String || value instanceof Boolean || value instanceof Byte || value instanceof Short || value instanceof Integer || value instanceof Long || value instanceof BigInteger || value instanceof BigDecimal)return value;
  if(value instanceof Double n && Double.isFinite(n) || value instanceof Float floating && Float.isFinite(floating))return value;
  if(!(value instanceof Map<?,?>) && !(value instanceof Collection<?>) || !ancestors.add(value))throw badJson(input);
  try{if(value instanceof Collection<?> list){var copy=new ArrayList<Object>();for(Object item:list)copy.add(json(item,input,depth+1,ancestors));return Collections.unmodifiableList(copy);}var copy=new LinkedHashMap<String,Object>();((Map<?,?>)value).forEach((key,item)->{if(!(key instanceof String name))throw badJson(input);copy.put(name,json(item,input,depth+1,ancestors));});return Collections.unmodifiableMap(copy);}finally{ancestors.remove(value);}
 }
 @Override public String toString(){return "SqlServerClinicalStore[redacted]";}
}
