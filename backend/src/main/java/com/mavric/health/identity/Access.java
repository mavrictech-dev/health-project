package com.mavric.health.identity;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.TenantRef;

@Component
public class Access {
    private final HttpServletRequest request; private final Sql sql;
    public Access(HttpServletRequest request,Sql sql) { this.request=request; this.sql=sql; }
    public Actor actor() { var auth=SecurityContextHolder.getContext().getAuthentication(); if(auth==null || !(auth.getPrincipal() instanceof Actor actor)) throw new ApiException(401,"UNAUTHENTICATED","Inicia sesión en este espacio."); return actor; }
    public TenantRef tenant() { Object value=request.getAttribute("health.tenant"); if(!(value instanceof TenantRef t)) throw ApiException.forbidden(); return t; }
    public String tenantId() { return tenant().id(); }
    public String userId() { return actor().id(); }
    public void roles(String... roles) { if(Collections.disjoint(actor().roles(),Arrays.asList(roles))) throw ApiException.forbidden(); }
    public void platform() { if(request.getAttribute("health.tenant")!=null || actor().tenantId()!=null) throw ApiException.forbidden(); roles("SAD"); }
    public void write(String feature,String... roles) { roles(roles); TenantRef t=tenant(); if(!List.of("TRIAL","ACTIVE").contains(t.status())) throw new ApiException(403,"SUSPENDED","El cliente conserva sus datos; las operaciones están suspendidas."); module(feature); }
    public void module(String feature) { if(feature!=null && !tenant().modules().contains(feature)) throw new ApiException(403,"MODULE_NOT_INCLUDED","El contrato no incluye este módulo."); }
    public void branch(String id) {
        Checks.id(id); sql.one("SELECT id FROM branches WHERE tenant_id=? AND id=? AND active=TRUE",tenantId(),id);
        if(!actor().roles().contains("ADM") && sql.optional("SELECT branch_id FROM membership_branches WHERE tenant_id=? AND user_id=? AND branch_id=?",tenantId(),userId(),id).isEmpty()) throw ApiException.forbidden();
    }
    public void link(String patient,String scope) { if(sql.optional("SELECT patient_id FROM patient_links WHERE tenant_id=? AND user_id=? AND patient_id=? AND active AND JSON_CONTAINS(scopes,JSON_QUOTE(?))",tenantId(),userId(),patient,scope).isEmpty()) throw ApiException.missing(); }
}
