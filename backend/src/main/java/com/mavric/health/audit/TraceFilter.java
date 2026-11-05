package com.mavric.health.audit;
import java.io.IOException;
import java.util.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.web.filter.OncePerRequestFilter;
import com.mavric.health.shared.*;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;
public class TraceFilter extends OncePerRequestFilter {
    private final Sql sql;private final Errors errors;private final com.mavric.health.persistence.sqlserver.SqlServerTraceStore store;
    public TraceFilter(Sql sql,Errors errors) { this.sql=sql;this.errors=errors;this.store=null; }
    public TraceFilter(com.mavric.health.persistence.sqlserver.SqlServerTraceStore store,Errors errors) {this.sql=null;this.errors=errors;this.store=Objects.requireNonNull(store);}
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
        long start=System.nanoTime(); String id=UUID.randomUUID().toString(); req.setAttribute("health.requestId",id);res.setHeader("X-Request-Id",id);res.setHeader("Cache-Control","no-store");TraceContext.REQUEST.set(req);boolean failure=false;
        if(Boolean.parseBoolean(System.getenv().getOrDefault("HEALTH_TRUST_GATEWAY","false"))) try {
            boolean gateway=Arrays.stream(java.net.InetAddress.getAllByName("gateway")).anyMatch(a->a.getHostAddress().equals(req.getRemoteAddr()));String forwarded=req.getHeader("X-Real-IP");
            if(gateway && forwarded!=null && forwarded.matches("[0-9a-fA-F:.]{1,64}")) req.setAttribute("health.sourceIp",forwarded);
        } catch(java.net.UnknownHostException ignored) { }
        try {
            String origin=req.getHeader("Origin");
            if(!Set.of("GET","HEAD","OPTIONS").contains(req.getMethod()) && origin!=null) {
                java.net.URI parsed;try { parsed=java.net.URI.create(origin); } catch(Exception e) { throw ApiException.forbidden(); }
                if(!req.getServerName().equalsIgnoreCase(parsed.getHost())) throw ApiException.forbidden();
            }
            chain.doFilter(req,res);
        } catch(ApiException e) {errors.write(req,res,e);} catch(ServletException|IOException|RuntimeException e) {failure=true;throw e;}
        finally {
            try {
                if(req.getRequestURI().startsWith("/api/") && !req.getRequestURI().equals("/api/public/status")) {
                    if(store!=null) store.finish(req,id,failure?500:res.getStatus(),(System.nanoTime()-start)/1_000_000);
                    else {
                    var t=(TenantRef)req.getAttribute("health.tenant");var a=(Actor)req.getAttribute("health.actor");String agent=Objects.toString(req.getHeader("User-Agent"),"");
                    sql.call("sp_request_finish",id,t==null?null:t.id(),a==null?null:a.id(),req.getMethod(),req.getRequestURI().substring(0,Math.min(250,req.getRequestURI().length())),failure?500:res.getStatus(),(System.nanoTime()-start)/1_000_000,TraceContext.address(req),agent.substring(0,Math.min(300,agent.length())));
                    }
                }
            } catch(Exception e) {org.slf4j.LoggerFactory.getLogger(TraceFilter.class).error("Trace persistence unavailable for request {}",id);}
            finally {TraceContext.REQUEST.remove();}
        }
    }
}
