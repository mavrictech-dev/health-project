package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import java.util.function.Supplier;
import java.util.function.Consumer;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.scheduling.domain.Requests.*;
import com.mavric.health.scheduling.domain.AppointmentStates;
import com.mavric.health.scheduling.application.SchedulingService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Unwired appointment persistence. Executor and REQUIRED manager must share the future runtime datasource. */
public final class SqlServerSchedulingStore {
 private static final Instant MIN=Instant.parse("0001-01-01T00:00:00Z"),MAX=Instant.parse("9999-12-31T23:59:59.999999Z");
 private static final Set<String> ROLES=Set.of("REC","PRO","ASI","AUD"),STATES=Set.of("REQUESTED","RESERVED","CONFIRMED","WAITING","CALLED","IN_CARE","COMPLETED","CANCELLED","WITHDRAWN");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;private final ObjectMapper mapper;
 /** Read/change compatibility constructor; reserve requires the configured Spring mapper overload. */
 public SqlServerSchedulingStore(SqlServerExecutor executor,PlatformTransactionManager manager){this(executor,manager,null);}
 public SqlServerSchedulingStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));this.mapper=mapper;}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request){return context(request,ROLES);}
 private static SqlServerContext context(HttpServletRequest request,Set<String> roles){if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return c;}
 public List<Map<String,Object>> list(HttpServletRequest request,Instant from,Instant to,String branch){return within(()->{var c=context(request);if(!valid(from) || !valid(to) || !to.isAfter(from) || Duration.between(from,to).toDays()>93)throw SqlServerErrors.invalid();if(branch!=null)Checks.id(branch);var rows=read(executor.execute(SqlServerProcedure.APPOINTMENTS_LIST,c,from,to,branch),c.tenantId(),200);for(var row:rows){Instant starts=Instant.parse((String)row.get("startsAt"));if(starts.isBefore(from) || !starts.isBefore(to) || branch!=null&&!branch.equals(row.get("branchId")))throw SqlServerErrors.database();}return rows;});}
 public Map<String,Object> get(HttpServletRequest request,String id){return within(()->{var c=context(request);Checks.id(id);var rows=read(executor.execute(SqlServerProcedure.APPOINTMENT_GET,c,id),c.tenantId(),1);if(rows.isEmpty())throw ApiException.missing();var row=rows.getFirst();if(!id.equals(row.get("id")))throw SqlServerErrors.database();return row;});}
 private static SqlServerContext writeContext(HttpServletRequest request,boolean portal){
  var c=context(request,portal?Set.of("PAC","RES"):Set.of("REC","PRO"));var tenant=(TenantRef)request.getAttribute("health.tenant");
  if(!List.of("TRIAL","ACTIVE").contains(tenant.status()))throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones est\u00e1n suspendidas.");
  for(String module:portal?List.of("CORE","PORTAL"):List.of("CORE"))if(tenant.modules()==null || !tenant.modules().contains(module))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");return c;
 }
 public Map<String,Object> reserve(HttpServletRequest request,Reserve p,String key,boolean portal){return within(()->{
  var c=writeContext(request,portal);if(p==null)throw SqlServerErrors.invalid();
  Checks.id(p.patientId());Checks.id(p.branchId());Checks.id(p.professionalId());
  if(p.specialtyCode()==null || !p.specialtyCode().matches("[-A-Za-z0-9_:]{1,100}") || p.service()==null || p.service().isBlank() || p.service().length()>160 || p.note()==null || p.note().length()>1000 || !(portal?Set.of("REQUESTED"):Set.of("REQUESTED","RESERVED")).contains(Objects.toString(p.status(),"")))throw SqlServerErrors.invalid();
  schedule(p.startsAt(),p.endsAt());if(p.startsAt().isBefore(Instant.now().minusSeconds(60)))throw ApiException.invalid("Selecciona un horario futuro.");
  String requestKey=Idempotency.key(key);if(mapper==null)throw SqlServerErrors.database();
  // This must use the SAME configured mapper as legacy Sql.json(p), not the formatted body.
  String hash=Checks.hash(mapper.writeValueAsString(p));
  var body=new LinkedHashMap<String,Object>();body.put("patientId",p.patientId());body.put("branchId",p.branchId());body.put("professionalId",p.professionalId());body.put("specialtyCode",p.specialtyCode());body.put("startsAt",utc(p.startsAt()));body.put("endsAt",utc(p.endsAt()));body.put("status",p.status());body.put("service",p.service());body.put("note",p.note());
  String generatedId=Checks.id();var row=mutationOne(executor.execute(SqlServerProcedure.APPOINTMENT_RESERVE,c,generatedId,mapper.writeValueAsString(body),requestKey,hash,portal),c.tenantId());
  if(!requestKey.equals(row.get("requestKey")) || !hash.equals(row.get("requestHash")))throw SqlServerErrors.database();
  if(generatedId.equals(row.get("id")) && (!p.status().equals(row.get("status")) || !micros(p.startsAt()).equals(Instant.parse((String)row.get("startsAt"))) || !micros(p.endsAt()).equals(Instant.parse((String)row.get("endsAt")))))throw SqlServerErrors.database();
  // A replay may have another id and may already have changed status/time after its first reserve.
  for(String field:List.of("patientId","branchId","professionalId","specialtyCode","service","note"))if(!Objects.equals(body.get(field),row.get(field)))throw SqlServerErrors.database();
  return row;
 });}
 public Map<String,Object> change(HttpServletRequest request,String id,Change p){return change(request,id,p,branch->{});}
 /** Server-only branch guard preserves legacy ordering; SP revalidates assignment under locks. */
 public Map<String,Object> change(HttpServletRequest request,String id,Change p,Consumer<String> branchGuard){return within(()->{
  var c=writeContext(request,false);Checks.id(id);if(p==null || p.expectedRevision()<1 || p.status()==null || !Set.of("RESERVED","CONFIRMED","WAITING","CALLED","IN_CARE","COMPLETED","CANCELLED","WITHDRAWN").contains(p.status()))throw SqlServerErrors.invalid();
  var current=one(executor.execute(SqlServerProcedure.APPOINTMENT_GET,c,id),c.tenantId());if(!id.equals(current.get("id")))throw SqlServerErrors.database();
  Objects.requireNonNull(branchGuard).accept((String)current.get("branchId"));AppointmentStates.check((String)current.get("status"),p.status());
  boolean reschedule=p.startsAt()!=null || p.endsAt()!=null;
  if(reschedule){schedule(p.startsAt(),p.endsAt());if(!p.status().equals("RESERVED") || p.startsAt().isBefore(Instant.now()))throw ApiException.invalid("Reprograma una reserva a un horario futuro.");}
  var row=mutationOne(executor.execute(SqlServerProcedure.APPOINTMENT_CHANGE,c,id,p.expectedRevision(),p.status(),p.startsAt(),p.endsAt()),c.tenantId());
  if(!id.equals(row.get("id")) || !p.status().equals(row.get("status")) || ((Integer)row.get("revision")).longValue()!=(long)p.expectedRevision()+1)throw SqlServerErrors.database();
  for(String field:List.of("patientId","branchId","professionalId","specialtyCode","service","note","requestKey","requestHash"))if(!Objects.equals(current.get(field),row.get(field)))throw SqlServerErrors.database();
  if(!Instant.parse((String)row.get("startsAt")).equals(reschedule?micros(p.startsAt()):Instant.parse((String)current.get("startsAt"))) || !Instant.parse((String)row.get("endsAt")).equals(reschedule?micros(p.endsAt()):Instant.parse((String)current.get("endsAt"))))throw SqlServerErrors.database();return row;
 });}
 private static Map<String,Object> mutationOne(SqlServerExecutor.Result result,String tenant){var rows=read(result,tenant,1);if(rows.size()!=1)throw SqlServerErrors.database();return rows.getFirst();}
 private static Map<String,Object> one(SqlServerExecutor.Result result,String tenant){var rows=read(result,tenant,1);if(rows.isEmpty())throw ApiException.missing();return rows.getFirst();}
 private static void schedule(Instant start,Instant end){SchedulingService.times(start,end);if(!valid(micros(start)) || !valid(micros(end)))throw SqlServerErrors.invalid();}
 private static Instant micros(Instant value){return value.truncatedTo(java.time.temporal.ChronoUnit.MICROS);}
 private static String utc(Instant value){return java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSSSSS").withZone(ZoneOffset.UTC).format(value);}
 private static List<Map<String,Object>> read(SqlServerExecutor.Result result,String tenant,int max){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(row->appointment(row,tenant)).toList();}
 private static Map<String,Object> appointment(Map<String,Object> row,String tenant){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId","branchId","professionalId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")))throw SqlServerErrors.database();out.put("specialtyCode",text(row,"specialtyCode"));String start=text(row,"startsAt"),end=text(row,"endsAt");Instant starts=time(start),ends=time(end);if(!ends.isAfter(starts))throw SqlServerErrors.database();out.put("startsAt",start);out.put("endsAt",end);String status=text(row,"status");if(!STATES.contains(status))throw SqlServerErrors.database();out.put("status",status);out.put("service",text(row,"service"));out.put("note",text(row,"note"));if(!(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();out.put("revision",revision);out.put("requestKey",text(row,"requestKey"));String hash=text(row,"requestHash");if(!hash.matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();out.put("requestHash",hash);return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(!row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key){if(!(field(row,key) instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key){String value=text(row,key);if(!canonical(value))throw SqlServerErrors.database();return value;}
 private static boolean valid(Instant value){return value!=null && value.getNano()%1000==0 && !value.isBefore(MIN) && !value.isAfter(MAX);}
 private static Instant time(String value){try{Instant result=Instant.parse(value);if(!value.endsWith("Z") || !valid(result))throw SqlServerErrors.database();return result;}catch(java.time.DateTimeException invalid){throw SqlServerErrors.database();}}
 @Override public String toString(){return "SqlServerSchedulingStore[redacted]";}
}
