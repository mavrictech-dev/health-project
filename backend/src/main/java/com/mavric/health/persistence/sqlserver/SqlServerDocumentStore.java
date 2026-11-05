package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.time.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import tools.jackson.databind.ObjectMapper;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.shared.*;
import com.mavric.health.documents.domain.Requests.*;
/** Unwired document adapter. Executor/REQUIRED manager must share the runtime datasource,
 * and mapper must be the configured Spring mapper. SPs own signatures and publication rules. */
public final class SqlServerDocumentStore {
 private static final Set<String> READ=Set.of("PRO","ASI","AUD"),OPERATIONS=Set.of("SAVE","SIGN","PUBLISH","WITHDRAW");
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;private final ObjectMapper mapper;
 public SqlServerDocumentStore(SqlServerExecutor executor,PlatformTransactionManager manager,ObjectMapper mapper){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));this.mapper=Objects.requireNonNull(mapper);}
 public <T>T required(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException failure){throw SqlServerErrors.map(failure);}}
 private static SqlServerContext context(HttpServletRequest req,Set<String> roles,boolean write){
  if(req==null)throw SqlServerErrors.database();Object host=req.getAttribute("health.tenant");if(host!=null && !(host instanceof TenantRef))throw SqlServerErrors.database();
  if(!(req.getAttribute("health.actor") instanceof Actor actor) || !(host instanceof TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
  if(actor.roles()==null)throw SqlServerErrors.database();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();
  var c=SqlServerRequestContexts.from(req,SqlServerContext.Scope.REQUEST);if(!canonical(c.actorId()) || !canonical(c.tenantId()) || c.tokenHash()==null || !c.tokenHash().matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();
  if(write){if(!Set.of("TRIAL","ACTIVE").contains(Objects.toString(tenant.status(),"")))throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones est\u00e1n suspendidas.");if(tenant.modules()==null || !tenant.modules().contains("CORE"))throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este m\u00f3dulo.");}return c;
 }

 public List<Map<String,Object>> list(HttpServletRequest request,String patient){return required(()->{var c=context(request,READ,false);Checks.id(patient);var rows=rows(executor.execute(SqlServerProcedure.DOCUMENTS_LIST,c,patient),c.tenantId(),200);for(var row:rows)if(!patient.equals(row.get("patientId")))throw SqlServerErrors.database();return rows;});}
 public Map<String,Object> get(HttpServletRequest request,String id){return required(()->{var c=context(request,READ,false);Checks.id(id);return one(executor.execute(SqlServerProcedure.DOCUMENT_GET,c,id),c.tenantId(),id,true);});}
 public Map<String,Object> create(HttpServletRequest request,Create p){return required(()->{
  var c=context(request,Set.of("PRO"),true);if(p==null)throw SqlServerErrors.invalid();Checks.id(p.patientId());if(p.encounterId()!=null)Checks.id(p.encounterId());if(p.originalId()!=null)Checks.id(p.originalId());if(!nonblank(p.title(),200) || !nonblank(p.type(),60) || !nonblank(p.content(),100000))throw SqlServerErrors.invalid();
  String id=Checks.id();var row=one(executor.execute(SqlServerProcedure.DOCUMENT_CREATE,c,id,mapper.writeValueAsString(p)),c.tenantId(),id,false);
  if(!p.patientId().equals(row.get("patientId")) || !Objects.equals(p.encounterId(),row.get("encounterId")) || !Objects.equals(p.originalId(),row.get("originalId")) || !p.title().equals(row.get("title")) || !p.type().equals(row.get("type")) || !p.content().equals(row.get("content")) || !"DRAFT".equals(row.get("status")) || !Integer.valueOf(1).equals(row.get("revision")) || !Boolean.FALSE.equals(row.get("published")) || !Boolean.FALSE.equals(row.get("withdrawn")) || row.get("signerId")!=null || row.get("signedAt")!=null || row.get("contentHash")!=null)throw SqlServerErrors.database();return row;
 });}
 public Map<String,Object> change(HttpServletRequest request,String id,Change p){return required(()->{
  var c=context(request,Set.of("PRO"),true);Checks.id(id);if(p==null || p.expectedRevision()<1 || p.operation()==null || !OPERATIONS.contains(p.operation()) || p.content()!=null && p.content().length()>100000)throw SqlServerErrors.invalid();if("SAVE".equals(p.operation()) && (p.content()==null || p.content().isBlank()))throw ApiException.invalid("Escribe el contenido del borrador.");
  // The SP audits its mutation and invokes its audited get internally; do not add a GET here.
  return one(executor.execute(SqlServerProcedure.DOCUMENT_CHANGE,c,id,p.expectedRevision(),p.operation(),p.content()),c.tenantId(),id,false);
 });}
 private static boolean nonblank(String text,int max){return text!=null && !text.isBlank() && text.length()<=max;}
 private static Map<String,Object> one(SqlServerExecutor.Result result,String tenant,String id,boolean missing){var rows=rows(result,tenant,1);if(rows.isEmpty() && missing)throw ApiException.missing();if(rows.size()!=1 || !id.equals(rows.getFirst().get("id")))throw SqlServerErrors.database();return rows.getFirst();}
 private static List<Map<String,Object>> rows(SqlServerExecutor.Result result,String tenant,int max){if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>max)throw SqlServerErrors.database();return result.resultSets().getFirst().stream().map(row->document(row,tenant)).toList();}
 private static Map<String,Object> document(Map<String,Object> row,String tenant){var out=new LinkedHashMap<String,Object>();for(String key:List.of("id","tenantId","patientId"))out.put(key,id(row,key));if(!tenant.equals(out.get("tenantId")))throw SqlServerErrors.database();for(String key:List.of("encounterId","originalId","signerId"))out.put(key,nullableId(row,key));for(String key:List.of("title","type","content"))out.put(key,text(row,key,false));String status=text(row,"status",false);if(!Set.of("DRAFT","SIGNED").contains(status))throw SqlServerErrors.database();out.put("status",status);if(!(field(row,"revision") instanceof Integer revision) || revision<1)throw SqlServerErrors.database();out.put("revision",revision);out.put("signedAt",time(row,"signedAt",true));String hash=text(row,"contentHash",true);if(hash!=null && !hash.matches("[a-fA-F0-9]{64}"))throw SqlServerErrors.database();out.put("contentHash",hash);for(String key:List.of("published","withdrawn")){if(!(field(row,key) instanceof Boolean flag))throw SqlServerErrors.database();out.put(key,flag);}out.put("createdAt",time(row,"createdAt",false));return Collections.unmodifiableMap(out);}
 private static Object field(Map<String,Object> row,String key){if(row==null || !row.containsKey(key))throw SqlServerErrors.database();return row.get(key);}
 private static String text(Map<String,Object> row,String key,boolean nullable){Object value=field(row,key);if(value==null && nullable)return null;if(!(value instanceof String text))throw SqlServerErrors.database();return text;}
 private static boolean canonical(String id){if(id==null)return false;try{return UUID.fromString(id).toString().equals(id);}catch(IllegalArgumentException invalid){return false;}}
 private static String id(Map<String,Object> row,String key){String value=text(row,key,false);if(!canonical(value))throw SqlServerErrors.database();return value;}
 private static String nullableId(Map<String,Object> row,String key){String value=text(row,key,true);if(value!=null && !canonical(value))throw SqlServerErrors.database();return value;}
 private static String time(Map<String,Object> row,String key,boolean nullable){String value=text(row,key,nullable);if(value!=null)try{Instant parsed=Instant.parse(value);if(!value.endsWith("Z") || parsed.getNano()%1000!=0 || parsed.isBefore(Instant.parse("0001-01-01T00:00:00Z")) || parsed.isAfter(Instant.parse("9999-12-31T23:59:59.999999Z")))throw SqlServerErrors.database();}catch(DateTimeException invalid){throw SqlServerErrors.database();}return value;}
 @Override public String toString(){return "SqlServerDocumentStore[redacted]";}
}
