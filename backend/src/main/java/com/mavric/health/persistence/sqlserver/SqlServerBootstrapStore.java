package com.mavric.health.persistence.sqlserver;
import java.util.*;
import java.util.function.Supplier;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.shared.Checks;

/** Unwired setup-only gateway. Requires a Purpose.BOOTSTRAP executor and manager backed by
 * the SAME separate bootstrap datasource; this class does not authenticate a DB principal. */
public final class SqlServerBootstrapStore {
 private final SqlServerExecutor executor;private final TransactionTemplate transactions;
 public SqlServerBootstrapStore(SqlServerExecutor executor,PlatformTransactionManager manager){this.executor=Objects.requireNonNull(executor);transactions=new TransactionTemplate(Objects.requireNonNull(manager));}
 public void initialize(String email,Supplier<String> passwordHash){
  try{transactions.execute(tx->{
   var context=new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.BOOTSTRAP);
   var result=executor.execute(SqlServerProcedure.BOOTSTRAP_EXISTS,context);
   if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>1)throw SqlServerErrors.database();
   var rows=result.resultSets().getFirst();
   if(!rows.isEmpty()){
    if(!(rows.getFirst().get("id") instanceof String id) || !canonical(id))throw SqlServerErrors.database();
    return null;
   }
   if(email==null || email.isBlank() || email.length()>254)throw SqlServerErrors.invalid();
   if(passwordHash==null)throw SqlServerErrors.database();
   String id=Checks.id(),hash=passwordHash.get();
   if(hash==null || hash.isBlank() || hash.length()>100)throw SqlServerErrors.invalid();
   var created=executor.execute(SqlServerProcedure.BOOTSTRAP_CREATE,context,id,email.toLowerCase(Locale.ROOT),hash);
   if(created==null || !created.resultSets().isEmpty())throw SqlServerErrors.database();
   return null;
  });}catch(RuntimeException error){throw SqlServerErrors.map(error);}
 }
 private static boolean canonical(String value){try{return UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException error){return false;}}
 @Override public String toString(){return "SqlServerBootstrapStore[redacted]";}
}
