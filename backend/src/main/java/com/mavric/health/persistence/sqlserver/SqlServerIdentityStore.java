package com.mavric.health.persistence.sqlserver;

import java.time.*;
import java.util.*;
import java.util.function.Supplier;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import com.mavric.health.shared.ApiException;

/** Unwired identity persistence. Executor and manager MUST use the same runtime datasource.
 *  Templates enforce boundaries without relying on an IdentityService self-invocation proxy. */
public final class SqlServerIdentityStore {
    private final SqlServerExecutor executor;
    private final TransactionTemplate required,failed,mandatory;

    public SqlServerIdentityStore(SqlServerExecutor executor,PlatformTransactionManager manager) {
        this.executor=Objects.requireNonNull(executor);
        Objects.requireNonNull(manager);
        required=new TransactionTemplate(manager);
        required.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
        failed=new TransactionTemplate(manager);
        failed.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        mandatory=new TransactionTemplate(manager);
        mandatory.setPropagationBehavior(TransactionDefinition.PROPAGATION_MANDATORY);
    }

    /** Credentials are INTERNAL, never a bearer response or diagnostic payload. */
    public record Credentials(String id,String name,String email,String passwordHash,String platformRole,
            boolean emailVerified,boolean locked,Instant lockedUntil) {
        @Override public String toString() { return "IdentityCredentials[redacted]"; }
    }
    public record Membership(String userId,List<String> roles) {
        public Membership { roles=List.copyOf(roles); }
    }
    public record SavedSession(String csrfToken,Instant expiresAt) {
        @Override public String toString() { return "SavedSession[redacted]"; }
    }
    public record SessionSummary(String id,String tenantId,Instant createdAt,Instant lastSeenAt,Instant expiresAt,
            boolean revoked,String userAgent,String sourceIp,boolean current) {
        @Override public String toString() { return "SessionSummary[redacted]"; }
    }

    public <T> T required(Supplier<T> work) { return within(required,work); }

    public void create(HttpServletRequest request,String id,String name,String email,String hash,String domain,String credential) {
        required(()-> {
            var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
            if(context.actorId()==null || Collections.disjoint(context.roles(),List.of("SAD","ADM"))) throw ApiException.forbidden();
            executeVoid(SqlServerProcedure.USER_CREATE,context,id,name,email,hash,domain,credential);
            return Boolean.TRUE;
        });
    }

    /** Only the future complete registration unit may enter this MANDATORY, anonymous operation. */
    public void createForRegistration(HttpServletRequest request,String id,String name,String email,String hash,String domain,String credential) {
        within(mandatory,()-> {
            var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
            if(context.actorId()!=null) throw ApiException.forbidden();
            executeVoid(SqlServerProcedure.USER_CREATE,context,id,name,email,hash,domain,credential);
            return Boolean.TRUE;
        });
    }

    public Optional<Credentials> credentials(HttpServletRequest request,String email) {
        return required(()->optional(executor.execute(SqlServerProcedure.IDENTITY_CREDENTIALS,
                SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY),email)).map(row->
                new Credentials(text(row,"id",false),text(row,"name",false),text(row,"email",false),
                        text(row,"passwordHash",false),text(row,"platformRole",true),
                        bit(row,"emailVerified"),bit(row,"locked"),instant(row,"lockedUntil",true))));
    }

    public Optional<Membership> membership(HttpServletRequest request,String userId) {
        return required(()-> {
            var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
            if(context.tenantId()==null) throw inconsistent();
            return optional(executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,context,
                    userId,context.tenantId(),true)).map(row-> {
                if(!userId.equals(text(row,"userId",false)) || !"ACTIVE".equals(text(row,"status",false))) throw inconsistent();
                Object value=row.get("roles");
                if(!(value instanceof List<?> list)) throw inconsistent();
                List<String> roles=new ArrayList<>();
                for(Object item:list) {
                    if(!(item instanceof String role)) throw inconsistent();
                    roles.add(role);
                }
                return new Membership(userId,roles);
            });
        });
    }

    public SavedSession saveSession(HttpServletRequest request,String hash,String userId,Instant expires) {
        return saveSession(request,hash,userId,expires,null);
    }
    public SavedSession saveSession(HttpServletRequest request,String hash,String userId,Instant expires,String ruc) {
        return required(()-> {
            var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
            if(context.tenantId()!=null)com.mavric.health.shared.Ruc.require(ruc);else if(ruc!=null)throw ApiException.forbidden();
            Map<String,Object> row=optional(context.tenantId()==null?executor.execute(SqlServerProcedure.SESSION_SAVE,context,hash,userId,expires):
                    executor.execute(SqlServerProcedure.TENANT_SESSION_SAVE,context,hash,userId,expires,ruc))
                    .orElseThrow(SqlServerIdentityStore::inconsistent);
            return savedSession(row);
        });
    }
    /** Holds the trusted host tenant row until the outer login transaction ends. */
    public boolean lockTenantRuc(HttpServletRequest request,String ruc){return required(()->{
        com.mavric.health.shared.Ruc.require(ruc);var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
        if(c.tenantId()==null || c.actorId()!=null)throw ApiException.forbidden();
        var found=optional(executor.execute(SqlServerProcedure.IDENTITY_TENANT_RUC_LOCK,c,ruc));if(found.isEmpty())return false;
        var row=found.get();if(!row.keySet().equals(Set.of("id","ruc","revision")) || !c.tenantId().equals(text(row,"id",false)) || !ruc.equals(text(row,"ruc",false)) || !(row.get("revision") instanceof Integer revision) || revision<1)throw inconsistent();return true;
    });}
    /** Anonymous platform lookup, no password/session/authentication is involved. */
    public String tenantSpace(HttpServletRequest request,String ruc,String baseDomain){return required(()->{
        com.mavric.health.shared.Ruc.require(ruc);var c=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
        if(c.tenantId()!=null || c.actorId()!=null)throw ApiException.forbidden();
        if(baseDomain==null || baseDomain.length()>253 || !baseDomain.matches("[a-z0-9]+([.-][a-z0-9]+)*"))throw inconsistent();
        var row=optional(executor.execute(SqlServerProcedure.TENANT_SPACE_RESOLVE,c,ruc,baseDomain)).orElseThrow(ApiException::missing);
        if(!row.keySet().equals(Set.of("hostname")))throw inconsistent();String host=text(row,"hostname",false);
        try{var slug=com.mavric.health.tenancy.DomainRules.resolve(host,baseDomain);
            if(host.length()>253 || slug.isEmpty() || !(slug.get()+"."+baseDomain).equals(host))throw inconsistent();
        }catch(RuntimeException poisoned){throw inconsistent();}return host;
    });}

    public SavedSession currentSession(HttpServletRequest request) {
        return required(()->savedSession(optional(executor.execute(SqlServerProcedure.SESSION_CURRENT,
                actorContext(request))).orElseThrow(ApiException::missing)));
    }

    public List<SessionSummary> listSessions(HttpServletRequest request) {
        return required(()-> {
            var result=executor.execute(SqlServerProcedure.SESSIONS_LIST,actorContext(request));
            if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>100) throw inconsistent();
            return result.resultSets().getFirst().stream().map(row-> {
                String id=text(row,"id",false);
                if(!opaqueId(id)) throw inconsistent();
                return new SessionSummary(id,text(row,"tenantId",true),instant(row,"createdAt",false),
                        instant(row,"lastSeenAt",false),instant(row,"expiresAt",false),bit(row,"revoked"),
                        text(row,"userAgent",false),text(row,"sourceIp",false),bit(row,"current"));
            }).toList(); // Explicit projection: extra driver/SP columns cannot escape to HTTP.
        });
    }

    public String passwordHash(HttpServletRequest request) {
        return required(()->text(optional(executor.execute(SqlServerProcedure.IDENTITY_PASSWORD_HASH,
                actorContext(request))).orElseThrow(ApiException::missing),"passwordHash",false));
    }

    public void changePassword(HttpServletRequest request,String hash) {
        required(()-> { executeVoid(SqlServerProcedure.PASSWORD_CHANGE,actorContext(request),hash);return Boolean.TRUE; });
    }

    public void revokeSession(HttpServletRequest request) {
        required(()-> { executeVoid(SqlServerProcedure.SESSION_REVOKE,actorContext(request),(Object)null);return Boolean.TRUE; });
    }

    public void revokeSession(HttpServletRequest request,String id) {
        required(()-> {
            if(!opaqueId(id)) throw ApiException.missing(); // Preserve unknown/foreign-id 404, never binder 400.
            executeVoid(SqlServerProcedure.SESSION_REVOKE,actorContext(request),id);
            return Boolean.TRUE;
        });
    }
    public void acceptInvitation(HttpServletRequest request,String userId) {
        required(()-> {
            var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY);
            if(context.tenantId()==null) throw ApiException.forbidden();
            executeVoid(SqlServerProcedure.INVITATION_ACCEPT,context,userId);
            return Boolean.TRUE;
        });
    }

    public void failed(HttpServletRequest request,String userId) {
        within(failed,()-> {
            executeVoid(SqlServerProcedure.LOGIN_FAILURE,
                    SqlServerRequestContexts.from(request,SqlServerContext.Scope.IDENTITY),userId);
            return Boolean.TRUE;
        });
    }

    private static SqlServerContext actorContext(HttpServletRequest request) {
        var context=SqlServerRequestContexts.from(request,SqlServerContext.Scope.REQUEST);
        if(context.actorId()==null) throw ApiException.forbidden();
        return context;
    }
    private static boolean opaqueId(String id) { return id!=null && id.matches("[0-9a-fA-F]{64}"); }
    private static SavedSession savedSession(Map<String,Object> row) {
        String csrf=text(row,"csrfToken",false);
        if(!opaqueId(csrf)) throw inconsistent();
        return new SavedSession(csrf,instant(row,"expiresAt",false));
    }
    private <T> T within(TransactionTemplate template,Supplier<T> work) {
        try { return template.execute(status->work.get()); }
        catch(RuntimeException error) { throw SqlServerErrors.map(error); }
    }
    private void executeVoid(SqlServerProcedure procedure,SqlServerContext context,Object... parameters) {
        var result=executor.execute(procedure,context,parameters);
        if(result==null || !result.resultSets().isEmpty()) throw inconsistent();
    }
    private static Optional<Map<String,Object>> optional(SqlServerExecutor.Result result) {
        if(result==null || result.resultSets().size()!=1 || result.resultSets().getFirst().size()>1) throw inconsistent();
        var rows=result.resultSets().getFirst();
        return rows.isEmpty()?Optional.empty():Optional.of(rows.getFirst());
    }
    private static String text(Map<String,Object> row,String key,boolean nullable) {
        if(!row.containsKey(key)) throw inconsistent();
        Object value=row.get(key);
        if(value==null && nullable) return null;
        if(!(value instanceof String text)) throw inconsistent();
        return text;
    }
    private static boolean bit(Map<String,Object> row,String key) {
        if(!(row.get(key) instanceof Boolean value)) throw inconsistent();
        return value;
    }
    private static Instant instant(Map<String,Object> row,String key,boolean nullable) {
        String value=text(row,key,nullable);
        if(value==null) return null;
        try {
            Instant instant=Instant.parse(value);
            if(!value.endsWith("Z") || instant.getNano()%1000!=0) throw inconsistent();
            return instant;
        } catch(DateTimeException error) { throw inconsistent(); }
    }
    private static ApiException inconsistent() { return SqlServerErrors.database(); }
    @Override public String toString() { return "SqlServerIdentityStore[redacted]"; }
}
