package com.mavric.health.audit;
import jakarta.servlet.http.HttpServletRequest;
public final class TraceContext {
    public static final ThreadLocal<HttpServletRequest> REQUEST=new ThreadLocal<>();
    public static String address(HttpServletRequest request) {return java.util.Objects.toString(request.getAttribute("health.sourceIp"),request.getRemoteAddr());}
    private TraceContext() {}
}
