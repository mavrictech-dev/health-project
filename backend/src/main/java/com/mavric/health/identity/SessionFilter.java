package com.mavric.health.identity;

import java.io.IOException;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.TenantRef;
import com.mavric.health.persistence.sqlserver.SqlServerSecurityStore;

public class SessionFilter extends OncePerRequestFilter {
    private final Sql sql; private final Errors errors;
    private final SqlServerSecurityStore securityStore;
    private BranchTokens branchTokens;
    public void branchTokens(BranchTokens tokens){this.branchTokens=tokens;}
    public SessionFilter(Sql sql,Errors errors) { this.sql=sql; this.errors=errors;this.securityStore=null; }
    public SessionFilter(SqlServerSecurityStore securityStore,Errors errors) {
        this.sql=null;this.errors=errors;this.securityStore=Objects.requireNonNull(securityStore);
    }
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
        boolean authenticated=false;
        try {
            req.removeAttribute("health.actor");
            req.removeAttribute("health.branch");
            SecurityContextHolder.clearContext();
            String path=req.getRequestURI();
            if("POST".equals(req.getMethod()) && "/api/public/tenant-space".equals(path)) {chain.doFilter(req,res);return;}
            if(Set.of("/api/v1/auth/login","/api/auth/login","/api/auth/browser/login","/api/auth/register","/api/auth/invitations/accept").contains(path) || path.startsWith("/api/auth/recovery/") || path.startsWith("/api/auth/verify/")) {chain.doFilter(req,res);return;}
            String header=req.getHeader("Authorization");
            boolean cookieSession=false;
            if(header==null && req.getCookies()!=null) for(var cookie:req.getCookies()) if(cookie.getName().equals("health_session")) {header="Bearer "+cookie.getValue();cookieSession=true;break;}
            if(header!=null && !req.getRequestURI().equals("/api/auth/login")) {
                BranchTokens.Claims branch=null;
                if(branchTokens!=null && header.startsWith("Bearer ") && header.substring(7).contains(".")){branch=branchTokens.verify(header.substring(7));header="Bearer "+branch.sid();}
                if(!header.matches("Bearer [A-Za-z0-9_-]{43}")) throw unauthenticated();
                String hash=Checks.hash(header.substring(7));
                var session=(securityStore!=null?securityStore.resolveSession(req,hash):
                        sql.optional("SELECT s.user_id,s.tenant_id,s.csrf_token,u.name,u.email,u.platform_role FROM auth_sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=? AND NOT s.revoked AND s.expires_at>UTC_TIMESTAMP(6) AND u.active AND u.email_verified",hash)).orElseThrow(SessionFilter::unauthenticated);
                TenantRef tenant=(TenantRef)req.getAttribute("health.tenant");
                String tenantId=tenant==null?null:tenant.id();
                if(!Objects.equals(tenantId,session.get("tenantId"))) throw unauthenticated();
                List<String> roles;
                if(tenantId==null) {
                    Object role=session.get("platformRole");
                    if(!(role instanceof String text) || !Set.of("SAD","SOP").contains(text)) throw unauthenticated();
                    roles=List.of(text);
                } else {
                    if(session.get("platformRole")!=null) throw unauthenticated();
                    var membership=(securityStore!=null?securityStore.activeMembership(req,session.get("userId").toString()):
                            sql.optional("SELECT roles FROM memberships WHERE tenant_id=? AND user_id=? AND status='ACTIVE'",tenantId,session.get("userId"))).orElseThrow(SessionFilter::unauthenticated);
                    roles=securityStore!=null?roles(membership.get("roles")):sql.strings(membership.get("roles"));
                    if(roles.isEmpty()) throw unauthenticated();
                }
                Actor actor=new Actor(session.get("userId").toString(),session.get("name").toString(),session.get("email").toString(),tenantId,roles,hash);
                if(branch!=null){
                    if(!actor.id().equals(branch.subject()) || !Objects.equals(tenantId,branch.tenantId()) || !new HashSet<>(roles).equals(new HashSet<>(branch.permissions())))throw unauthenticated();
                    req.setAttribute("health.branch",branch.branchId());
                }
                if(cookieSession && !Set.of("GET","HEAD","OPTIONS").contains(req.getMethod())) {
                    String csrf=req.getHeader("X-CSRF-Token");
                    Object expected=session.get("csrfToken");
                    if(csrf==null || csrf.isEmpty() || !(expected instanceof String token) || token.isEmpty()
                            || !java.security.MessageDigest.isEqual(csrf.getBytes(java.nio.charset.StandardCharsets.UTF_8),token.getBytes(java.nio.charset.StandardCharsets.UTF_8))) throw new ApiException(403,"CSRF_INVALID","Actualiza la sesión antes de continuar.");
                }
                if(!Set.of("GET","HEAD","OPTIONS").contains(req.getMethod()) && tenantId!=null && !req.getRequestURI().startsWith("/api/auth/") && !req.getRequestURI().startsWith("/api/v1/auth/") && !req.getRequestURI().startsWith("/api/support")) {
                    var state=securityStore!=null?securityStore.applicationStatus(req):sql.one("SELECT mode,message FROM application_state WHERE id=1");
                    if(!state.get("mode").equals("OPEN")) throw new ApiException(503,"APPLICATION_READ_ONLY",state.get("message").toString());
                }
                req.setAttribute("health.actor",actor);
                if(securityStore!=null) securityStore.touchSession(req);
                else sql.call("sp_session_touch",hash);
                var auth=new UsernamePasswordAuthenticationToken(actor,null,roles.stream().map(SimpleGrantedAuthority::new).toList());
                SecurityContextHolder.getContext().setAuthentication(auth);
                authenticated=true;
            }
            chain.doFilter(req,res);
        } catch(ApiException e) {
            if(!authenticated) { req.removeAttribute("health.branch");req.removeAttribute("health.actor");SecurityContextHolder.clearContext(); }
            errors.write(req,res,e);
        }
    }
    private static List<String> roles(Object value) {
        if(!(value instanceof List<?> values)) throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
        List<String> result=new ArrayList<>();
        for(Object item:values) {
            if(!(item instanceof String text)) throw new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");
            result.add(text);
        }
        return List.copyOf(result);
    }
    private static ApiException unauthenticated() { return new ApiException(401,"UNAUTHENTICATED","Sesión no válida para este espacio."); }
}
