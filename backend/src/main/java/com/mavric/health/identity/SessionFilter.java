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

public class SessionFilter extends OncePerRequestFilter {
    private final Sql sql; private final Errors errors;
    public SessionFilter(Sql sql,Errors errors) { this.sql=sql; this.errors=errors; }
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
        try {
            String path=req.getRequestURI();
            if(Set.of("/api/auth/login","/api/auth/browser/login","/api/auth/register","/api/auth/invitations/accept").contains(path) || path.startsWith("/api/auth/recovery/") || path.startsWith("/api/auth/verify/")) {chain.doFilter(req,res);return;}
            String header=req.getHeader("Authorization");
            boolean cookieSession=false;
            if(header==null && req.getCookies()!=null) for(var cookie:req.getCookies()) if(cookie.getName().equals("health_session")) {header="Bearer "+cookie.getValue();cookieSession=true;break;}
            if(header!=null && !req.getRequestURI().equals("/api/auth/login")) {
                if(!header.matches("Bearer [A-Za-z0-9_-]{43}")) throw unauthenticated();
                String hash=Checks.hash(header.substring(7));
                var session=sql.optional("SELECT s.user_id,s.tenant_id,s.csrf_token,u.name,u.email,u.platform_role FROM auth_sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=? AND NOT s.revoked AND s.expires_at>UTC_TIMESTAMP(6) AND u.active AND u.email_verified",hash).orElseThrow(SessionFilter::unauthenticated);
                TenantRef tenant=(TenantRef)req.getAttribute("health.tenant");
                String tenantId=tenant==null?null:tenant.id();
                if(!Objects.equals(tenantId,session.get("tenantId"))) throw unauthenticated();
                List<String> roles;
                if(tenantId==null) { Object role=session.get("platformRole"); if(role==null) throw unauthenticated(); roles=List.of(role.toString()); }
                else roles=sql.strings(sql.optional("SELECT roles FROM memberships WHERE tenant_id=? AND user_id=? AND status='ACTIVE'",tenantId,session.get("userId")).orElseThrow(SessionFilter::unauthenticated).get("roles"));
                Actor actor=new Actor(session.get("userId").toString(),session.get("name").toString(),session.get("email").toString(),tenantId,roles,hash);
                req.setAttribute("health.actor",actor);
                if(cookieSession && !Set.of("GET","HEAD","OPTIONS").contains(req.getMethod())) {
                    String csrf=req.getHeader("X-CSRF-Token");
                    if(csrf==null || !java.security.MessageDigest.isEqual(csrf.getBytes(java.nio.charset.StandardCharsets.UTF_8),session.get("csrfToken").toString().getBytes(java.nio.charset.StandardCharsets.UTF_8))) throw new ApiException(403,"CSRF_INVALID","Actualiza la sesión antes de continuar.");
                }
                if(!Set.of("GET","HEAD","OPTIONS").contains(req.getMethod()) && tenantId!=null && !req.getRequestURI().startsWith("/api/auth/") && !req.getRequestURI().startsWith("/api/support")) {
                    var state=sql.one("SELECT mode,message FROM application_state WHERE id=1");
                    if(!state.get("mode").equals("OPEN")) throw new ApiException(503,"APPLICATION_READ_ONLY",state.get("message").toString());
                }
                sql.call("sp_session_touch",hash);
                var auth=new UsernamePasswordAuthenticationToken(actor,null,roles.stream().map(SimpleGrantedAuthority::new).toList());
                SecurityContextHolder.getContext().setAuthentication(auth);
            }
            chain.doFilter(req,res);
        } catch(ApiException e) { errors.write(req,res,e); }
    }
    private static ApiException unauthenticated() { return new ApiException(401,"UNAUTHENTICATED","Sesión no válida para este espacio."); }
}
