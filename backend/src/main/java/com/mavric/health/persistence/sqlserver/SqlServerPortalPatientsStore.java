package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Explicit portal-patient adapter, never a bean. Executor and REQUIRED manager must share
 * the future runtime datasource. The SP owns link locking, active-link selection and audit. */
public final class SqlServerPortalPatientsStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerPortalPatientsStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);this.transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 /** V5 has no TOP/pagination: preserve its complete linked-patient result, without a Java cap. */
 public List<Map<String,Object>> patients(HttpServletRequest request){try{return transactions.execute(tx->{var c=context(request);var result=executor.execute(SqlServerProcedure.PORTAL_PATIENTS,c);if(result==null || result.resultSets().size()!=1)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(SqlServerPortalPatientsStore::patient).toList();});}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),List.of("PAC","RES")))throw ApiException.forbidden();
  if(tenant.modules()==null || !tenant.modules().contains("PORTAL"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();return c;
 }
 private static Map<String,Object> patient(Map<String,Object> row){var out=new LinkedHashMap<String,Object>();out.put("id",id(row,"id",false));String name=text(row,"name",false);if(name.isBlank() || name.length()>160)throw SqlServerErrors.database();out.put("name",name);String domain=text(row,"domain",false);if(!Set.of("HUMAN","ANIMAL").contains(domain))throw SqlServerErrors.database();out.put("domain",domain);String birth=text(row,"birthDate",true);if(birth!=null)try{LocalDate date=LocalDate.parse(birth);if(date.getYear()<1 || date.getYear()>9999 || !birth.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}") || !date.toString().equals(birth))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}out.put("birthDate",birth);String species=text(row,"species",true);if(species!=null && species.length()>80)throw SqlServerErrors.database();out.put("species",species);String relationship=text(row,"relationship",false);if(relationship.isBlank() || relationship.length()>80)throw SqlServerErrors.database();out.put("relationship",relationship);if(!(field(row,"scopes") instanceof List<?> values))throw SqlServerErrors.database();var scopes=new ArrayList<String>();for(Object value:values){if(!(value instanceof String scope) || !Set.of("APPOINTMENTS","DOCUMENTS","BILLING").contains(scope) || scopes.contains(scope))throw SqlServerErrors.database();scopes.add(scope);}out.put("scopes",List.copyOf(scopes));return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null && !canonical(value))throw SqlServerErrors.database();return value;}
 @Override public String toString(){return "SqlServerPortalPatientsStore[redacted]";}
}
