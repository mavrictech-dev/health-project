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
import com.mavric.health.billing.domain.Requests.Post;
/** Explicit/unwired finance adapter; executor and REQUIRED manager must share the runtime datasource.
 * Mapper must be the configured Spring mapper used by legacy Sql.json. V6 owns ledger locks/rules. */
public final class SqlServerFinanceStore {
 private static final Set<String> READ=Set.of("CAJ","AUD"),KINDS=Set.of("CHARGE","PAYMENT","REFUND");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;private final ObjectMapper mapper;
 public SqlServerFinanceStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=Objects.requireNonNull(executor);this.transactions=new TransactionTemplate(Objects.requireNonNull(manager));this.mapper=Objects.requireNonNull(mapper);}
 private <T>T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest req,Set<String> roles,boolean write){
  if(req==null)throw SqlServerErrors.database();Object host=req.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(req.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(req,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();
  if(!write && (tenant.modules()==null || !tenant.modules().contains("FINANCE")))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");
  if(write){if(!Set.of("TRIAL","ACTIVE").contains(Objects.toString(tenant.status(),"")))throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones est\u00e1n suspendidas.");if(tenant.modules()==null || !tenant.modules().contains("FINANCE"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");}return c;
 }

 public Map<String,Object> balance(HttpServletRequest request,String patient){return within(()->{var c=context(request,READ,false);Checks.id(patient);var rows=sets(executor.execute(SqlServerProcedure.FINANCE_BALANCE,c,patient),1);if(rows.size()!=1)throw SqlServerErrors.database();var row=rows.getFirst();Number amount=exactNumber(field(row,"balanceMinor"));String currency=text(row,"currency",false);if(!currency.equals("PEN"))throw SqlServerErrors.database();return Map.of("balanceMinor",amount,"currency",currency);});}
 public List<Map<String,Object>> movements(HttpServletRequest request,String patient){return within(()->{var c=context(request,READ,false);Checks.id(patient);return sets(executor.execute(SqlServerProcedure.FINANCE_MOVEMENTS,c,patient),200).stream().map(row->movement(row,c.tenantId(),patient)).toList();});}
 public Map<String,Object> post(HttpServletRequest request,Post p,String key){return within(()->{
  var c=context(request,Set.of("CAJ"),true);if(p==null)throw SqlServerErrors.invalid();Checks.id(p.patientId());if(p.parentId()!=null)Checks.id(p.parentId());if(p.kind()==null || !KINDS.contains(p.kind()) || p.amountMinor()<1 || p.amountMinor()>1000000000000L || p.title()==null || p.title().isBlank() || p.title().length()>200)throw SqlServerErrors.invalid();String requestKey=Idempotency.key(key);
  // One serialization of the ORIGINAL DTO, without formatting/reordering/canonicalization.
  String json=mapper.writeValueAsString(p),hash=Checks.hash(json),generated=Checks.id();var rows=sets(executor.execute(SqlServerProcedure.FINANCE_POST,c,generated,json,requestKey,hash),1);if(rows.size()!=1)throw SqlServerErrors.database();var row=movement(rows.getFirst(),c.tenantId(),p.patientId());
  if(!requestKey.equals(row.get("requestKey")) || !hash.equals(row.get("requestHash")) || !p.kind().equals(row.get("kind")) || !Long.valueOf(p.amountMinor()).equals(row.get("amountMinor")) || !p.title().equals(row.get("title")) || !Objects.equals(p.parentId(),row.get("parentId")) || !"PEN".equals(row.get("currency")) || generated.equals(row.get("id"))&&!c.actorId().equals(row.get("actorId")))throw SqlServerErrors.database();
  // Same-key replay may return an existing UUID and the original cashier's actorId.
  return row;
 });}
 private static List<Map<String,Object>> sets(SqlServerExecutor.Result result,int max){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();return result.resultSets().getFirst();}
 private static Map<String,Object> movement(Map<String,Object> row,String tenant,String patient){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId","actorId"))out.put(key,id(row,key,false));if(!tenant.equals(out.get("tenantId")) || !patient.equals(out.get("patientId")))throw SqlServerErrors.database();String kind=text(row,"kind",false);if(!KINDS.contains(kind))throw SqlServerErrors.database();out.put("kind",kind);if(!(field(row,"amountMinor") instanceof Long amount) || amount<1)throw SqlServerErrors.database();out.put("amountMinor",amount);String currency=text(row,"currency",false);if(currency.length()!=3)throw SqlServerErrors.database();out.put("currency",currency);String title=text(row,"title",false);if(title.length()>200)throw SqlServerErrors.database();out.put("title",title);out.put("parentId",id(row,"parentId",true));String key=text(row,"requestKey",false);if(!key.matches("[A-Za-z0-9_.:-]{8,100}"))throw SqlServerErrors.database();out.put("requestKey",key);String hash=text(row,"requestHash",false);if(!hash.matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();out.put("requestHash",hash);out.put("createdAt",time(row,"createdAt"));return Collections.unmodifiableMap(out);}
 /** Preserve immutable exact Number representation, including DECIMAL(38,0), never narrow to long. */
 private static Number exactNumber(Object value){BigInteger integer;if(value instanceof BigDecimal decimal){try{var bounded=decimal.stripTrailingZeros();if(bounded.scale()>0 || (long)bounded.precision()-bounded.scale()>38)throw SqlServerErrors.database();integer=bounded.toBigIntegerExact();}catch(ArithmeticException invalid){throw SqlServerErrors.database();}}else if(value instanceof BigInteger big)integer=big;else if(value instanceof Byte || value instanceof Short || value instanceof Integer || value instanceof Long)integer=BigInteger.valueOf(((Number)value).longValue());else throw SqlServerErrors.database();if(integer.abs().toString().length()>38)throw SqlServerErrors.database();return (Number)value;}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null && !canonical(value))throw SqlServerErrors.database();return value;}
 private static String time(Map<String,Object> row,String key){String value=text(row,key,false);try{Instant parsed=Instant.parse(value);if(!value.endsWith("Z") || parsed.getNano()%1000!=0 || parsed.isBefore(Instant.parse("0001-01-01T00:00:00Z")) || parsed.isAfter(Instant.parse("9999-12-31T23:59:59.999999Z")))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}return value;}
 @Override public String toString(){return "SqlServerFinanceStore[redacted]";}
}
