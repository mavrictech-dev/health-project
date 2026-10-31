package com.mavric.health.tenancy;

import java.io.IOException;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.web.filter.OncePerRequestFilter;
import com.mavric.health.shared.*;

public class HostFilter extends OncePerRequestFilter {
    private final Settings settings; private final Sql sql; private final Errors errors;
    public HostFilter(Settings settings,Sql sql,Errors errors) { this.settings=settings; this.sql=sql; this.errors=errors; }
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
        try {
            var slug=DomainRules.resolve(req.getServerName(),settings.baseDomain());
            if(slug.isPresent()) {
                var row=sql.one("SELECT t.id,t.name,t.slug,t.kind,t.domain,t.status,v.modules FROM tenants t JOIN subscriptions s ON s.tenant_id=t.id JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.slug=?",slug.get());
                req.setAttribute("health.tenant",new TenantRef(row.get("id").toString(),row.get("name").toString(),slug.get(),row.get("kind").toString(),row.get("domain").toString(),row.get("status").toString(),sql.strings(row.get("modules"))));
            }
            chain.doFilter(req,res);
        } catch(ApiException e) { errors.write(req,res,e); }
    }
}
