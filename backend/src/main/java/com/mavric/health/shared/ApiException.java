package com.mavric.health.shared;

public class ApiException extends RuntimeException {
    public final int status;
    public final String code;
    public ApiException(int status, String code, String message) { super(message); this.status=status; this.code=code; }
    public static ApiException missing() { return new ApiException(404,"NOT_FOUND","Recurso no disponible en este espacio."); }
    public static ApiException forbidden() { return new ApiException(403,"FORBIDDEN","No tienes permiso para esta operación."); }
    public static ApiException invalid(String detail) { return new ApiException(400,"INVALID_REQUEST",detail); }
}
