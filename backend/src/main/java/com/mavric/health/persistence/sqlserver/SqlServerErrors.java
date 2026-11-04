package com.mavric.health.persistence.sqlserver;

import java.sql.SQLException;
import java.util.ArrayDeque;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.Set;
import com.mavric.health.shared.ApiException;

/** Vendor numbers only; driver messages, SQLState, parameters and SQL never become HTTP details. */
public final class SqlServerErrors {
    private SqlServerErrors() { }

    public static ApiException map(Throwable failure) {
        if (failure instanceof ApiException api) return api;
        Set<Throwable> visited = Collections.newSetFromMap(new IdentityHashMap<>());
        var pending = new ArrayDeque<Throwable>();
        if (failure != null) pending.add(failure);
        while (!pending.isEmpty()) {
            Throwable current = pending.removeFirst();
            if (!visited.add(current)) continue;
            if (current instanceof SQLException sql) {
                ApiException mapped = vendor(sql.getErrorCode());
                if (mapped != null) return mapped;
                if (sql.getNextException() != null) pending.addLast(sql.getNextException());
            }
            if (current.getCause() != null) pending.addLast(current.getCause());
        }
        return database();
    }

    static ApiException invalid() { return new ApiException(400, "INVALID", "Contexto o parametros de datos no validos."); }
    static ApiException database() { return new ApiException(500, "DATABASE_ERROR", "No se pudo completar la operacion de datos."); }

    private static ApiException vendor(int code) {
        return switch (code) {
            case 51000 -> new ApiException(400, "INVALID", "Datos no validos para esta operacion.");
            case 51001 -> new ApiException(403, "FORBIDDEN", "No tienes permiso para esta operacion.");
            case 51002 -> new ApiException(404, "NOT_FOUND", "Recurso no disponible en este espacio.");
            case 51003 -> new ApiException(409, "CONFLICT", "El recurso cambio o la operacion entra en conflicto.");
            case 51004 -> new ApiException(403, "SUSPENDED", "Las operaciones de este cliente estan suspendidas.");
            case 51005 -> new ApiException(409, "APPLICATION_READ_ONLY", "Las escrituras no estan disponibles.");
            case 1205 -> new ApiException(409, "CONCURRENT_CHANGE", "Otra operacion produjo un conflicto concurrente.");
            case 2601, 2627, 547 -> new ApiException(409, "DATA_CONFLICT", "Referencia no valida o recurso duplicado.");
            case 229 -> database(); // Do not reinterpret a denied DB grant as a later HTTP permission failure.
            default -> null; // In particular, SQL permission229 is NOT an HTTP user role failure.
        };
    }
}
