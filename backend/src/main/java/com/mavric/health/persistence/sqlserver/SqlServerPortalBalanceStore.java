package com.mavric.health.persistence.sqlserver;
import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
/** Explicit portal-balance adapter, never a bean. Executor and REQUIRED manager must share
 * the future runtime datasource. The SP owns link locking, balance calculation and audit. */
public final class SqlServerPortalBalanceStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerPortalBalanceStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);this.transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 public Map<String,Object> balance(HttpServletRequest request,String patient){try{return transactions.execute(tx->{var c=context(request);Checks.id(patient);var result=executor.execute(SqlServerProcedure.PORTAL_BALANCE,c,patient);if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()!=1)throw SqlServerErrors.database();var row=result.resultSets().getFirst().getFirst();if(!(field(row,"balanceMinor") instanceof Long amount) || !(field(row,"currency") instanceof String currency) || !currency.equals("PEN"))throw SqlServerErrors.database();return Map.<String,Object>of("balanceMinor",amount,"currency",currency);});}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest request){
  if(request==null)throw SqlServerErrors.database();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(request.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),List.of("PAC","RES")))throw ApiException.forbidden();
  if(tenant.modules()==null || !tenant.modules().contains("PORTAL"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  if(!tenant.modules().contains("FINANCE"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();return c;
 }
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 @Override public String toString(){return "SqlServerPortalBalanceStore[redacted]";}
}
