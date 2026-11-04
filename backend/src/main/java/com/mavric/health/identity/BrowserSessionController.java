package com.mavric.health.identity;
import java.time.*;
import java.util.*;
import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import org.springframework.http.ResponseCookie;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.persistence.sqlserver.SqlServerIdentityStore;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
@RestController @RequestMapping("/api/auth")
public class BrowserSessionController {
    private final IdentityService service;private final Access access;private final Sql sql;private final Settings settings;
    private final SqlServerIdentityStore identityStore;
    @Autowired
    public BrowserSessionController(IdentityService service,Access access,Sql sql,Settings settings) {this.service=service;this.access=access;this.sql=sql;this.settings=settings;this.identityStore=null;}
    public BrowserSessionController(IdentityService service,Access access,SqlServerIdentityStore identityStore,Settings settings) {
        this.service=Objects.requireNonNull(service);this.access=Objects.requireNonNull(access);
        this.sql=null;this.settings=Objects.requireNonNull(settings);this.identityStore=Objects.requireNonNull(identityStore);
    }
    @PostMapping("/browser/login") Object login(@Valid @RequestBody AuthController.Login p,HttpServletRequest req,HttpServletResponse res) {
        if(identityStore!=null) {
            var result=service.loginBrowser(p.email(),p.password(),(TenantRef)req.getAttribute("health.tenant"),TraceContext.address(req));
            if(result==null) throw databaseError();
            // Revalidate the internal carrier before writing headers; never return the carrier itself.
            var checked=new IdentityService.BrowserLogin(result.token(),result.user(),result.expiresAt(),result.csrfToken());
            var user=checked.user();
            var response=Map.of("user",Map.of("id",user.id(),"name",user.name(),"email",user.email(),"roles",user.roles()),
                    "expiresAt",checked.expiresAt().toString(),"csrfToken",checked.csrfToken());
            cookieAfterCommit(res,cookie(checked.token(),Duration.ofHours(settings.sessionHours())));
            return response;
        }
        var result=service.login(p.email(),p.password(),(TenantRef)req.getAttribute("health.tenant"),com.mavric.health.audit.TraceContext.address(req));String token=result.get("accessToken").toString();
        var response=new LinkedHashMap<String,Object>();response.put("user",result.get("user"));response.put("expiresAt",result.get("expiresAt"));response.put("csrfToken",sql.one("SELECT csrf_token FROM auth_sessions WHERE token_hash=?",Checks.hash(token)).get("csrfToken"));
        res.addHeader("Set-Cookie",cookie(token,Duration.ofHours(settings.sessionHours())));return response;
    }
    @GetMapping("/browser/session") Object session() {
        var actor=access.actor();
        if(identityStore!=null) {
            var current=identityStore.currentSession(signedRequest(actor));
            return Map.of("user",user(actor),"csrfToken",current.csrfToken(),"expiresAt",current.expiresAt().toString());
        }
        var current=sql.one("SELECT csrf_token,expires_at FROM auth_sessions WHERE token_hash=?",actor.tokenHash());
        Map<String,Object> user=new LinkedHashMap<>();user.put("id",actor.id());user.put("name",actor.name());user.put("email",actor.email());user.put("roles",actor.roles());user.put("tenantId",actor.tenantId());
        return Map.of("user",user,"csrfToken",current.get("csrfToken"),"expiresAt",current.get("expiresAt"));
    }
    @DeleteMapping("/browser/session") void end(HttpServletResponse res) {
        service.logout();
        String expired=cookie("",Duration.ZERO);
        if(identityStore!=null)cookieAfterCommit(res,expired);else res.addHeader("Set-Cookie",expired);
    }
    @GetMapping("/sessions") Object sessions() {
        if(identityStore!=null)return identityStore.listSessions(signedRequest(access.actor())).stream().map(BrowserSessionController::sessionBody).toList();
        return sql.rows("SELECT SHA2(token_hash,256) id,tenant_id,created_at,last_seen_at,expires_at,revoked,user_agent,source_ip,(token_hash=?) current FROM auth_sessions WHERE user_id=? ORDER BY created_at DESC LIMIT 100",access.actor().tokenHash(),access.userId());
    }
    @DeleteMapping("/sessions/{id}") @org.springframework.transaction.annotation.Transactional void revoke(@PathVariable String id) {
        if(identityStore!=null) { identityStore.revokeSession(signedRequest(access.actor()),id);return; }
        var row=sql.one("SELECT token_hash FROM auth_sessions WHERE user_id=? AND SHA2(token_hash,256)=?",access.userId(),id);sql.call("sp_session_end",row.get("tokenHash"),access.userId());
    }
    private String cookie(String token,Duration age) {
        return ResponseCookie.from("health_session",token).httpOnly(true).secure(settings.publicOrigin().startsWith("https:"))
                .sameSite("Strict").path("/api").maxAge(age).build().toString();
    }
    private static void cookieAfterCommit(HttpServletResponse response,String cookie) {
        if(!TransactionSynchronizationManager.isActualTransactionActive()) { response.addHeader("Set-Cookie",cookie);return; }
        if(!TransactionSynchronizationManager.isSynchronizationActive())throw databaseError();
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override public void afterCommit() { response.addHeader("Set-Cookie",cookie); }
        });
    }
    private static Map<String,Object> user(Actor actor) {
        Map<String,Object> user=new LinkedHashMap<>();
        user.put("id",actor.id());user.put("name",actor.name());user.put("email",actor.email());
        user.put("roles",actor.roles());user.put("tenantId",actor.tenantId());return user;
    }
    private static Map<String,Object> sessionBody(SqlServerIdentityStore.SessionSummary row) {
        Map<String,Object> data=new LinkedHashMap<>();
        data.put("id",row.id());data.put("tenantId",row.tenantId());data.put("createdAt",row.createdAt().toString());
        data.put("lastSeenAt",row.lastSeenAt().toString());data.put("expiresAt",row.expiresAt().toString());
        data.put("revoked",row.revoked());data.put("userAgent",row.userAgent());data.put("sourceIp",row.sourceIp());data.put("current",row.current());
        return data;
    }
    private static HttpServletRequest signedRequest(Actor actor) {
        HttpServletRequest request=TraceContext.REQUEST.get();
        if(request==null)throw databaseError();
        if(!actor.equals(request.getAttribute("health.actor")))throw ApiException.forbidden();
        Object host=request.getAttribute("health.tenant");
        if(host!=null && !(host instanceof TenantRef))throw databaseError();
        if(!Objects.equals(actor.tenantId(),host==null?null:((TenantRef)host).id()))throw ApiException.forbidden();
        return request;
    }
    private static ApiException databaseError() { return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos."); }
}
