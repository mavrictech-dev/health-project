package com.mavric.health.persistence.sqlserver;

import java.util.*;
import java.time.Instant;
import java.util.function.Supplier;
import com.mavric.health.shared.Checks;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.shared.ApiException;

/** Unwired public catalog. Executor and manager must share the runtime datasource.
 * REQUIRED groups validation and both reads, without promising a snapshot isolation level. */
public final class SqlServerAccountLifecycleStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate transactions,registration;
    public SqlServerAccountLifecycleStore(SqlServerExecutor executor,PlatformTransactionManager manager) {
        this.executor=Objects.requireNonNull(executor);
        transactions=new TransactionTemplate(Objects.requireNonNull(manager));
        transactions.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
        registration=new TransactionTemplate(manager);
        registration.setPropagationBehavior(TransactionDefinition.PROPAGATION_MANDATORY);
    }
    public Map<String,Object> options(HttpServletRequest request) {
        try {
            var result=transactions.execute(status-> {
                if(request==null || request.getAttribute("health.tenant")!=null) throw SqlServerErrors.database();
                var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
                var plans=rows(executor.execute(SqlServerProcedure.REGISTRATION_PLANS,context)).stream().map(SqlServerAccountLifecycleStore::plan).toList();
                var specialties=rows(executor.execute(SqlServerProcedure.REGISTRATION_SPECIALTIES,context)).stream().map(SqlServerAccountLifecycleStore::specialty).toList();
                return Map.<String,Object>of("plans",plans,"specialties",specialties);
            });
            if(result==null) throw SqlServerErrors.database();
            return result;
        } catch(RuntimeException error) {throw SqlServerErrors.map(error);}
    }
    /** Internal identity carrier: never an HTTP response or diagnostic payload. */
    public record Account(String id,String email,boolean emailVerified,String platformRole) {
        @Override public String toString() {return "Account[redacted]";}
    }
    public <T> T required(Supplier<T> work) {
        try {return transactions.execute(status->work.get());}
        catch(RuntimeException failure) {throw SqlServerErrors.map(failure);}
    }
    private static SqlServerContext anonymous(HttpServletRequest request) {
        if(request==null) throw SqlServerErrors.database();
        var authentication=org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        if(request.getAttribute("health.actor")!=null || authentication!=null && authentication.getPrincipal() instanceof com.mavric.health.identity.Actor) throw ApiException.forbidden();
        return identity(request);
    }
    public boolean emailExists(HttpServletRequest request,String email) {
        return required(()-> {
            var context=anonymous(request);
            if(email==null || email.isBlank() || email.length()>254) throw SqlServerErrors.invalid();
            var values=rows(executor.execute(SqlServerProcedure.IDENTITY_EMAIL_EXISTS,context,email));
            if(values.size()>1) throw SqlServerErrors.database();
            if(values.isEmpty()) return false;
            canonicalResult(text(values.getFirst(),"id"));return true;
        });
    }
    public void pending(HttpServletRequest request,String userId) {registrationWrite(request,userId,false);}
    public void portalRegister(HttpServletRequest request,String userId) {registrationWrite(request,userId,true);}
    private void registrationWrite(HttpServletRequest request,String userId,boolean portal) {
        try {
            registration.execute(status-> {
                var context=anonymous(request);Checks.id(userId);
                if(portal && context.tenantId()==null) throw ApiException.forbidden();
                noRows(executor.execute(portal?SqlServerProcedure.PORTAL_REGISTER:SqlServerProcedure.IDENTITY_PENDING,context,userId));return null;
            });
        } catch(RuntimeException failure) {throw SqlServerErrors.map(failure);}
    }
    private static SqlServerContext identity(HttpServletRequest request) {
        if(request==null) throw SqlServerErrors.database();
        return SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
    }
    public Optional<Account> lookup(HttpServletRequest request,String email) {
        return required(()-> {
            var context=identity(request);
            if(email==null || email.isBlank() || email.length()>254) throw SqlServerErrors.invalid();
            var values=rows(executor.execute(SqlServerProcedure.IDENTITY_ACCOUNT_LOOKUP,context,email));
            if(values.size()>1) throw SqlServerErrors.database();
            if(values.isEmpty()) return Optional.empty();
            var row=values.getFirst();String id=text(row,"id");canonicalResult(id);
            if(!(row.get("emailVerified") instanceof Boolean verified) || !row.containsKey("platformRole")) throw SqlServerErrors.database();
            Object role=row.get("platformRole");
            if(role!=null && (!(role instanceof String) || !Set.of("SAD","SOP").contains(role))) throw SqlServerErrors.database();
            return Optional.of(new Account(id,text(row,"email"),verified,(String)role));
        });
    }
    public boolean membership(HttpServletRequest request,String userId) {
        return required(()-> {
            var context=identity(request);Checks.id(userId);
            if(context.tenantId()==null) throw ApiException.forbidden();
            var values=rows(executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,context,userId,context.tenantId(),false));
            if(values.size()>1) throw SqlServerErrors.database();
            if(values.isEmpty()) return false;
            var row=values.getFirst();String id=text(row,"userId");canonicalResult(id);
            if(!id.equals(userId) || !Set.of("ACTIVE","INVITED").contains(text(row,"status"))) throw SqlServerErrors.database();
            return true;
        });
    }
    public void issue(HttpServletRequest request,String hash,String user,String purpose,Instant expiry,String mailId,String subject,String body) {
        required(()-> {
            var context=identity(request);hash(hash);Checks.id(user);Checks.id(mailId);purpose(purpose);
            if(expiry==null || subject==null || subject.isBlank() || subject.length()>200 || body==null || body.isBlank()) throw SqlServerErrors.invalid();
            noRows(executor.execute(SqlServerProcedure.IDENTITY_ISSUE,context,hash,user,purpose,expiry,mailId,subject,body,null));return null;
        });
    }
    public void redeem(HttpServletRequest request,String hash,String purpose,String passwordHash) {
        required(()-> {
            var context=identity(request);hash(hash);purpose(purpose);
            if("VERIFY".equals(purpose)?passwordHash!=null:passwordHash==null || passwordHash.isBlank() || passwordHash.length()>100) throw SqlServerErrors.invalid();
            noRows(executor.execute(SqlServerProcedure.IDENTITY_REDEEM,context,hash,purpose,passwordHash));return null;
        });
    }
    private static void purpose(String purpose) {if(!"VERIFY".equals(purpose) && !"RESET".equals(purpose)) throw SqlServerErrors.invalid();}
    private static void hash(String hash) {if(hash==null || !hash.matches("[0-9a-fA-F]{64}")) throw SqlServerErrors.invalid();}
    private static void canonicalResult(String id) {
        try {if(!UUID.fromString(id).toString().equals(id)) throw SqlServerErrors.database();}
        catch(IllegalArgumentException failure) {throw SqlServerErrors.database();}
    }
    private static void noRows(SqlServerExecutor.Result result) {if(result==null || !result.resultSets().isEmpty()) throw SqlServerErrors.database();}
    private static List<Map<String,Object>> rows(SqlServerExecutor.Result result) {
        if(result==null || result.resultSets().size()!=1) throw SqlServerErrors.database();
        return result.resultSets().getFirst();
    }
    private static String text(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof String value)) throw SqlServerErrors.database();
        return value;
    }
    private static List<String> strings(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof List<?> values)) throw SqlServerErrors.database();
        List<String> copy=new ArrayList<>();
        for(Object value:values) {if(!(value instanceof String item)) throw SqlServerErrors.database();copy.add(item);}
        return List.copyOf(copy);
    }
    private static Integer quota(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof Integer value) || value<1) throw SqlServerErrors.database();
        return value;
    }
    private static Map<String,Object> plan(Map<String,Object> row) {
        String id=text(row,"id");
        try {if(!UUID.fromString(id).toString().equals(id)) throw SqlServerErrors.database();}
        catch(IllegalArgumentException invalid) {throw SqlServerErrors.database();}
        if(!(row.get("baseMinor") instanceof Long base) || base<0) throw SqlServerErrors.database();
        return Map.of("id",id,"name",text(row,"name"),"kinds",strings(row,"kinds"),"domains",strings(row,"domains"),
                "includedBranches",quota(row,"includedBranches"),"includedProfessionals",quota(row,"includedProfessionals"),
                "includedSpecialties",quota(row,"includedSpecialties"),"baseMinor",base);
    }
    private static Map<String,Object> specialty(Map<String,Object> row) {
        if(!(row.get("dental") instanceof Boolean dental)) throw SqlServerErrors.database();
        return Map.of("code",text(row,"code"),"name",text(row,"name"),"domain",text(row,"domain"),"dental",dental);
    }
    @Override public String toString() {return "SqlServerAccountLifecycleStore[redacted]";}
}
