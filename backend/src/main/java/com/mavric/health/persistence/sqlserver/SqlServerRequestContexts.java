package com.mavric.health.persistence.sqlserver;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import com.mavric.health.audit.TraceContext;
import com.mavric.health.identity.Actor;
import com.mavric.health.tenancy.TenantRef;

/** Internal request boundary extracted from A10 unchanged; never reads authority from HTTP data. */
final class SqlServerRequestContexts {
    private SqlServerRequestContexts() {}
    static SqlServerContext from(HttpServletRequest request,SqlServerContext.Scope scope) {
        Object tenantValue=request.getAttribute("health.tenant"),actorValue=request.getAttribute("health.actor");
        Object requestId=request.getAttribute("health.requestId"),source=request.getAttribute("health.sourceIp");
        if (tenantValue!=null && !(tenantValue instanceof TenantRef) || actorValue!=null && !(actorValue instanceof Actor)
                || requestId!=null && !(requestId instanceof String) || source!=null && !(source instanceof String))
            throw inconsistent();
        TenantRef tenant=(TenantRef)tenantValue;
        Actor actor=(Actor)actorValue;
        String tenantId=tenant==null?null:tenant.id();
        if (tenant!=null && tenantId==null || actor!=null && (actor.id()==null || actor.tokenHash()==null
                || !Objects.equals(tenantId,actor.tenantId()))) throw inconsistent();
        return new SqlServerContext((String)requestId,request.getMethod(),truncate(request.getRequestURI(),250),
                TraceContext.address(request),truncate(request.getHeader("User-Agent"),300),
                actor==null?null:actor.id(),actor==null?null:strings(actor.roles()),tenantId,
                actor==null?null:actor.tokenHash(),scope);
    }

    private static String truncate(String value,int length) {
        if (value==null || value.length()<=length) return value;
        // Keep UTF-16 pairs intact at an NVARCHAR(n) boundary.
        int end=length;
        if (Character.isHighSurrogate(value.charAt(end-1)) && Character.isLowSurrogate(value.charAt(end))) end--;
        return value.substring(0,end);
    }

    private static List<String> strings(Object value) {
        if (!(value instanceof List<?> values)) throw inconsistent();
        List<String> result=new ArrayList<>();
        for (Object item:values) {
            if (!(item instanceof String text)) throw inconsistent();
            result.add(text);
        }
        return List.copyOf(result);
    }
    private static com.mavric.health.shared.ApiException inconsistent() { return SqlServerErrors.database(); }
}
