package com.mavric.health.identity;
import java.time.*;
import java.util.*;
import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import org.springframework.http.ResponseCookie;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
@RestController @RequestMapping("/api/auth")
public class BrowserSessionController {
    private final IdentityService service;private final Access access;private final Sql sql;private final Settings settings;
    public BrowserSessionController(IdentityService service,Access access,Sql sql,Settings settings) {this.service=service;this.access=access;this.sql=sql;this.settings=settings;}
    @PostMapping("/browser/login") Object login(@Valid @RequestBody AuthController.Login p,HttpServletRequest req,HttpServletResponse res) {
        var result=service.login(p.email(),p.password(),(TenantRef)req.getAttribute("health.tenant"),com.mavric.health.audit.TraceContext.address(req));String token=result.get("accessToken").toString();
        res.addHeader("Set-Cookie",ResponseCookie.from("health_session",token).httpOnly(true).secure(settings.publicOrigin().startsWith("https:")).sameSite("Strict").path("/api").maxAge(Duration.ofHours(settings.sessionHours())).build().toString());
        var response=new LinkedHashMap<String,Object>();response.put("user",result.get("user"));response.put("expiresAt",result.get("expiresAt"));response.put("csrfToken",sql.one("SELECT csrf_token FROM auth_sessions WHERE token_hash=?",Checks.hash(token)).get("csrfToken"));return response;
    }
    @GetMapping("/browser/session") Object session() {
        var actor=access.actor();var current=sql.one("SELECT csrf_token,expires_at FROM auth_sessions WHERE token_hash=?",actor.tokenHash());
        Map<String,Object> user=new LinkedHashMap<>();user.put("id",actor.id());user.put("name",actor.name());user.put("email",actor.email());user.put("roles",actor.roles());user.put("tenantId",actor.tenantId());
        return Map.of("user",user,"csrfToken",current.get("csrfToken"),"expiresAt",current.get("expiresAt"));
    }
    @DeleteMapping("/browser/session") void end(HttpServletResponse res) { service.logout();res.addHeader("Set-Cookie",ResponseCookie.from("health_session","").httpOnly(true).secure(settings.publicOrigin().startsWith("https:")).sameSite("Strict").path("/api").maxAge(0).build().toString()); }
    @GetMapping("/sessions") Object sessions() {return sql.rows("SELECT SHA2(token_hash,256) id,tenant_id,created_at,last_seen_at,expires_at,revoked,user_agent,source_ip,(token_hash=?) current FROM auth_sessions WHERE user_id=? ORDER BY created_at DESC LIMIT 100",access.actor().tokenHash(),access.userId());}
    @DeleteMapping("/sessions/{id}") @org.springframework.transaction.annotation.Transactional void revoke(@PathVariable String id) {var row=sql.one("SELECT token_hash FROM auth_sessions WHERE user_id=? AND SHA2(token_hash,256)=?",access.userId(),id);sql.call("sp_session_end",row.get("tokenHash"),access.userId());}
}
