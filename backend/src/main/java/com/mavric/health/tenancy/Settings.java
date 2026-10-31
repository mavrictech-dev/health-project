package com.mavric.health.tenancy;

import java.net.URI;
import java.util.Locale;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("health")
public record Settings(String baseDomain,String publicOrigin,int sessionHours,Bootstrap bootstrap) {
    public record Bootstrap(String email,String password) { }
    public Settings {
        baseDomain=baseDomain.toLowerCase(Locale.ROOT);
        if(!baseDomain.matches("[a-z0-9]+([.-][a-z0-9]+)*") || !baseDomain.contains(".")) throw new IllegalArgumentException("HEALTH_BASE_DOMAIN inválido");
        URI origin=URI.create(publicOrigin);
        if(!SetHolder.SCHEMES.contains(origin.getScheme()) || !baseDomain.equals(origin.getHost()) || origin.getUserInfo()!=null || origin.getQuery()!=null || origin.getFragment()!=null || !(origin.getPath().isEmpty() || origin.getPath().equals("/"))) throw new IllegalArgumentException("HEALTH_PUBLIC_ORIGIN debe ser el origen del dominio base");
        if(sessionHours<1 || sessionHours>24) throw new IllegalArgumentException("SESSION_HOURS fuera de rango");
    }
    public String hostname(String slug) { return DomainRules.slug(slug)+"."+baseDomain; }
    public String tenantUrl(String slug) { URI origin=URI.create(publicOrigin); return origin.getScheme()+"://"+hostname(slug)+(origin.getPort()==-1?"":":"+origin.getPort()); }
    private static class SetHolder { static final java.util.Set<String> SCHEMES=java.util.Set.of("http","https"); }
}
