package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.ApiException;
/** Explicit read adapter, no bean. Executor and REQUIRED manager must share the future runtime datasource.
 * V6 owns membership/module visibility and occupancy; this adapter never queries branches or recalculates occupancy. */
public final class SqlServerHospitalStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerHospitalStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);this.transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request,Set<String> roles){var context=authority(request,roles);var tenant=(TenantRef)request.getAttribute("health.tenant");if(tenant.modules()==null || !tenant.modules().contains("HOSPITAL"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");return context;}
 private static SqlServerContext authority(HttpServletRequest req,Set<String> roles){if(req==null)throw SqlServerErrors.database();Object host=req.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();if(!(req.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();var c=SqlServerRequestContexts.from(req,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();return c;}

 public List<Map<String,Object>> resources(HttpServletRequest request){return within(()->{var c=context(request,Set.of("ADM","PRO","ASI","AUD"));return rows(executor.execute(SqlServerProcedure.HOSPITAL_RESOURCES,c)).stream().map(row->resource(row,c.tenantId())).toList();});}
 public List<Map<String,Object>> admissions(HttpServletRequest request){return within(()->{var c=context(request,Set.of("PRO","ASI","AUD"));return rows(executor.execute(SqlServerProcedure.HOSPITAL_ADMISSIONS,c)).stream().map(row->admission(row,c.tenantId())).toList();});}
 private static List<Map<String,Object>> rows(SqlServerExecutor.Result result){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>200)throw SqlServerErrors.database();return result.resultSets().getFirst();}
 private static Map<String,Object> resource(Map<String,Object> row,String tenant){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","branchId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")))throw SqlServerErrors.database();out.put("name",text(row,"name",100));String kind=text(row,"kind",4);if(!Set.of("BED","CAGE").contains(kind))throw SqlServerErrors.database();out.put("kind",kind);out.put("active",bit(row,"active"));out.put("occupied",bit(row,"occupied"));return Collections.unmodifiableMap(out);}
 private static Map<String,Object> admission(Map<String,Object> row,String tenant){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId","resourceId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")))throw SqlServerErrors.database();String status=text(row,"status",10);if(!Set.of("ADMITTED","DISCHARGED").contains(status))throw SqlServerErrors.database();out.put("status",status);out.put("reason",text(row,"reason",1000));if(!(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();out.put("revision",revision);out.put("admittedAt",time(row,"admittedAt",false));out.put("dischargedAt",time(row,"dischargedAt",true));out.put("occupiedResource",nullableId(row,"occupiedResource"));out.put("admittedPatient",nullableId(row,"admittedPatient"));boolean admitted=status.equals("ADMITTED");if(!Objects.equals(out.get("occupiedResource"),admitted?out.get("resourceId"):null) || !Objects.equals(out.get("admittedPatient"),admitted?out.get("patientId"):null))throw SqlServerErrors.database();return Collections.unmodifiableMap(out);}
 private static Boolean bit(Map<String,Object> row,String key){if(!(field(row,key) instanceof Boolean value))throw SqlServerErrors.database();return value;}
 private static String nullableId(Map<String,Object> row,String key){Object value=field(row,key);if(value==null)return null;if(!(value instanceof String id) || !canonical(id))throw SqlServerErrors.database();return id;}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,int max){if(!(field(row,key) instanceof String value) || value.length()>max)throw SqlServerErrors.database();return value;}
 private static boolean canonical(String value){if(value==null)return false;try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key){String value=text(row,key,36);if(!canonical(value))throw SqlServerErrors.database();return value;}
 private static String time(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();try{Instant time=Instant.parse(text);if(!text.endsWith("Z") || time.getNano()%1000!=0 || time.isBefore(Instant.parse("0001-01-01T00:00:00Z")) || time.isAfter(Instant.parse("9999-12-31T23:59:59.999999Z")))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}return text;}
 @Override public String toString(){return "SqlServerHospitalStore[redacted]";}
}
