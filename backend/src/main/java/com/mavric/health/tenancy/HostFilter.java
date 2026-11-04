package com.mavric.health.tenancy;

import java.io.IOException;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.web.filter.OncePerRequestFilter;
import com.mavric.health.shared.*;
import com.mavric.health.persistence.sqlserver.SqlServerSecurityStore;

public class HostFilter extends OncePerRequestFilter {
    private final Settings settings; private final Sql sql; private final Errors errors;
    private final SqlServerSecurityStore securityStore;
    public HostFilter(Settings settings,Sql sql,Errors errors) { this.settings=settings; this.sql=sql; this.errors=errors; this.securityStore=null; }
    public HostFilter(Settings settings,SqlServerSecurityStore securityStore,Errors errors) {
        this.settings=settings;this.sql=null;this.errors=errors;this.securityStore=java.util.Objects.requireNonNull(securityStore);
    }
    @Override protected void doFilterInternal(HttpServletRequest req,HttpServletResponse res,FilterChain chain) throws ServletException,IOException {
        try {
            req.removeAttribute("health.tenant");
            var slug=DomainRules.resolve(req.getServerName(),settings.baseDomain());
            if(slug.isPresent()) {
                var row=securityStore!=null?securityStore.tenantBySlug(req,slug.get()).orElseThrow(ApiException::missing):
                        sql.one("SELECT t.id,t.name,t.slug,t.kind,t.domain,t.status,v.modules FROM tenants t JOIN subscriptions s ON s.tenant_id=t.id JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.slug=?",slug.get());
                req.setAttribute("health.tenant",new TenantRef(row.get("id").toString(),row.get("name").toString(),slug.get(),row.get("kind").toString(),row.get("domain").toString(),row.get("status").toString(),securityStore!=null?modules(row.get("modules")):sql.strings(row.get("modules"))));
            }
            chain.doFilter(req,res);
        } catch(ApiException e) { errors.write(req,res,e); }
    }
    private static java.util.List<String> modules(Object value) {
        if (!(value instanceof java.util.List<?> values)) throw invalidResult();
        java.util.List<String> result=new java.util.ArrayList<>();
        for (Object item:values) {
            if (!(item instanceof String text)) throw invalidResult();
            result.add(text);
        }
        return java.util.List.copyOf(result);
    }
    private static ApiException invalidResult() { return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos."); }
}
