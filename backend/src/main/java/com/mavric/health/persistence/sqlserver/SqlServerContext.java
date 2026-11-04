package com.mavric.health.persistence.sqlserver;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** Trusted server context, explicitly passed, never populated from an HTTP body. */
public record SqlServerContext(String requestId, String method, String route,
        String sourceIp, String userAgent, String actorId, List<String> roles,
        String tenantId, String tokenHash, Scope scope) {
    public enum Scope { REQUEST, IDENTITY, WORKER, BOOTSTRAP }

    public SqlServerContext {
        roles = roles == null ? null : Collections.unmodifiableList(new ArrayList<>(roles));
    }

    public static SqlServerContext empty() {
        return new SqlServerContext(null, null, null, null, null, null, null, null, null, Scope.REQUEST);
    }

    @Override public String toString() { return "SqlServerContext[redacted]"; }
}
