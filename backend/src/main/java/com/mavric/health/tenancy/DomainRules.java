package com.mavric.health.tenancy;

import java.util.*;
import com.mavric.health.shared.ApiException;

public final class DomainRules {
    private static final Set<String> RESERVED=Set.of("www","admin","api","app","saas","mail","support","status","auth","portal","localhost");
    private DomainRules() { }
    public static String slug(String input) {
        if(input==null || input.length()>63 || !input.matches("[a-z0-9]+(-[a-z0-9]+)*") || RESERVED.contains(input)) throw ApiException.invalid("Subdominio inválido o reservado. Usa letras minúsculas, números y guiones.");
        return input;
    }
    public static Optional<String> resolve(String hostname,String baseDomain) {
        if(hostname==null) throw ApiException.missing();
        String host=hostname.toLowerCase(Locale.ROOT); if(host.endsWith(".")) host=host.substring(0,host.length()-1);
        if(host.equals(baseDomain) || host.equals("admin."+baseDomain)) return Optional.empty();
        String suffix="."+baseDomain;
        if(!host.endsWith(suffix)) throw ApiException.missing();
        String part=host.substring(0,host.length()-suffix.length());
        if(part.contains(".")) throw ApiException.missing();
        try { return Optional.of(slug(part)); } catch(ApiException e) { throw ApiException.missing(); }
    }
}
