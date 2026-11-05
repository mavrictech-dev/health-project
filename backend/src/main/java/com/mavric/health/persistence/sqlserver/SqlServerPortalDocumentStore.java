package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Explicit portal-document adapter, never a bean. Executor and REQUIRED manager must share
 * the future runtime datasource. The SP owns link locking, publication filtering and audit. */
public final class SqlServerPortalDocumentStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerPortalDocumentStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);this.transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 public List<Map<String,Object>> documents(HttpServletRequest request,String patient){try{return transactions.execute(tx->{var c=context(request);Checks.id(patient);var result=executor.execute(SqlServerProcedure.PORTAL_DOCUMENTS,c,patient);if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>200)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(SqlServerPortalDocumentStore::document).toList();});}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),List.of("PAC","RES")))throw ApiException.forbidden();
  if(tenant.modules()==null || !tenant.modules().contains("PORTAL"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();return c;
 }
 private static Map<String,Object> document(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));for(String key:List.of("title","type","content"))out.put(key,text(row,key,false));if(!(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();out.put("revision",revision);out.put("signerId",id(row,"signerId",true));out.put("signedAt",time(row,"signedAt"));String hash=text(row,"contentHash",true);if(hash!=null && !hash.matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();out.put("contentHash",hash);out.put("originalId",id(row,"originalId",true));return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null && !canonical(value))throw SqlServerErrors.database();return value;}
 private static String time(Map<String,Object> row,String key){String value=text(row,key,true);if(value!=null)try{Instant time=Instant.parse(value);if(!value.endsWith("Z") || time.getNano()%1000!=0 || time.isBefore(Instant.parse("0001-01-01T00:00:00Z")) || time.isAfter(Instant.parse("9999-12-31T23:59:59.999999Z")))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}return value;}
 @Override public String toString(){return "SqlServerPortalDocumentStore[redacted]";}
}
