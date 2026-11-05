package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.util.function.Supplier;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.shared.Checks;

/** Unwired outbox gateway; executor and REQUIRED manager must share the runtime datasource.
 * Claims commit before delivery. Ambiguous/SENDING rows require reconciliation, not an automatic resend. */
public final class SqlServerMailDeliveryStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerMailDeliveryStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 public record ClaimedMail(String id,String recipient,String subject,String body,int claimVersion){@Override public String toString(){return "ClaimedMail[redacted]";}}
 private static SqlServerContext worker(){return new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.WORKER);}
 private <T> T within(Supplier<T> work){try{return transactions.execute(tx->work.get());}catch(RuntimeException error){throw SqlServerErrors.map(error);}}
 public List<ClaimedMail> claim(){return within(()->{
  var result=executor.execute(SqlServerProcedure.MAIL_CLAIM,worker(),10);
  if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>10)throw SqlServerErrors.database();
  List<ClaimedMail> claimed=new ArrayList<>();Set<String> ids=new HashSet<>();
  for(var row:result.resultSets().getFirst()){
   String id=text(row,"id");try{if(!UUID.fromString(id).toString().equals(id))throw SqlServerErrors.database();}catch(IllegalArgumentException invalid){throw SqlServerErrors.database();}
   if(!ids.add(id) || !(row.get("claimVersion") instanceof Integer version) || version<1 || version>5)throw SqlServerErrors.database();
   claimed.add(new ClaimedMail(id,text(row,"recipient"),text(row,"subject"),text(row,"body"),version));
  }
  return List.copyOf(claimed);
 });}
 public void complete(String id,int claimVersion,String outcome){within(()->{
  Checks.id(id);if(claimVersion<1 || claimVersion>5 || outcome==null || !Set.of("SENT","REJECTED","AMBIGUOUS").contains(outcome))throw SqlServerErrors.invalid();
  var result=executor.execute(SqlServerProcedure.MAIL_COMPLETE,worker(),id,claimVersion,outcome);
  if(result==null || !result.resultSets().isEmpty())throw SqlServerErrors.database();return null;
 });}
 private static String text(Map<String,Object> row,String key){if(!(row.get(key) instanceof String value))throw SqlServerErrors.database();return value;}
 @Override public String toString(){return "SqlServerMailDeliveryStore[redacted]";}
}
