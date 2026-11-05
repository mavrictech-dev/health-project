package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Unwired appointment reads. Executor and REQUIRED manager must share the future runtime datasource. */
public final class SqlServerSchedulingStore {
 private static final Instant MIN=Instant.parse("0001-01-01T00:00:00Z"),MAX=Instant.parse("9999-12-31T23:59:59.999999Z");
 private static final Set<String> ROLES=Set.of("REC","PRO","ASI","AUD"),STATES=Set.of("REQUESTED","RESERVED","CONFIRMED","WAITING","CALLED","IN_CARE","COMPLETED","CANCELLED","WITHDRAWN");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerSchedulingStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request){if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),ROLES))throw ApiException.forbidden();var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[0-9a-fA-F]{64}"))throw SqlServerErrors.database();return c;}
 public List<Map<String,Object>> list(HttpServletRequest request,Instant from,Instant to,String branch){return within(()->{var c=context(request);if(!valid(from) || !valid(to) || !to.isAfter(from) || Duration.between(from,to).toDays()>93)throw SqlServerErrors.invalid();if(branch!=null)Checks.id(branch);var rows=read(executor.execute(SqlServerProcedure.APPOINTMENTS_LIST,c,from,to,branch),c.tenantId(),200);for(var row:rows){Instant starts=Instant.parse((String)row.get("startsAt"));if(starts.isBefore(from) || !starts.isBefore(to) || branch!=null&&!branch.equals(row.get("branchId")))throw SqlServerErrors.database();}return rows;});}
 public Map<String,Object> get(HttpServletRequest request,String id){return within(()->{var c=context(request);Checks.id(id);var rows=read(executor.execute(SqlServerProcedure.APPOINTMENT_GET,c,id),c.tenantId(),1);if(rows.isEmpty())throw ApiException.missing();var row=rows.getFirst();if(!id.equals(row.get("id")))throw SqlServerErrors.database();return row;});}
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
