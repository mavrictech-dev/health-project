package com.mavric.health.identity;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.Instant;
import java.util.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.shared.ApiException;

/** Signed branch scope layered on the revocable SQL session. Never stores clinical data. */
public final class BranchTokens {
    private final byte[] key;
    private final ObjectMapper mapper;
    private static final String HEADER="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9";
    public BranchTokens(ObjectMapper mapper,String secret) {
        this.mapper=mapper;
        if(secret==null || secret.isBlank()){key=new byte[32];new SecureRandom().nextBytes(key);}
        else {key=secret.getBytes(StandardCharsets.UTF_8);if(key.length<32)throw new IllegalArgumentException("HEALTH_JWT_SECRET requires at least 32 bytes");}
    }
    public record Claims(String sid,String subject,String tenantId,String branchId,List<String> permissions,Instant expiresAt) {
        @Override public String toString(){return "BranchClaims[redacted]";}
    }
    public String issue(String sid,Actor actor,String branchId,Instant expiresAt) {
        if(sid==null || !sid.matches("[A-Za-z0-9_-]{43}") || actor.tenantId()==null)throw invalid();
        UUID.fromString(branchId);
        var payload=Map.of("iss","health-project","aud","health-api","jti",sid,"sub",actor.id(),"tenantId",actor.tenantId(),"branchId",branchId,"permissions",actor.roles(),"iat",Instant.now().getEpochSecond(),"exp",expiresAt.getEpochSecond());
        String content=HEADER+"."+Base64.getUrlEncoder().withoutPadding().encodeToString(mapper.writeValueAsBytes(payload));
        return content+"."+Base64.getUrlEncoder().withoutPadding().encodeToString(sign(content));
    }
    public Claims verify(String token) {
        try {
            if(token==null || token.length()>4096)throw invalid();
            String[] parts=token.split("\\.",-1);
            if(parts.length!=3 || !HEADER.equals(parts[0]) || !MessageDigest.isEqual(sign(parts[0]+"."+parts[1]),Base64.getUrlDecoder().decode(parts[2])))throw invalid();
            var p=mapper.readTree(Base64.getUrlDecoder().decode(parts[1]));
            if(!"health-project".equals(p.path("iss").asText()) || !"health-api".equals(p.path("aud").asText()) || !p.path("exp").isIntegralNumber() || !p.path("permissions").isArray())throw invalid();
            Instant expiry=Instant.ofEpochSecond(p.path("exp").asLong());if(!expiry.isAfter(Instant.now()))throw invalid();
            String sid=p.path("jti").asText(),sub=p.path("sub").asText(),tenant=p.path("tenantId").asText(),branch=p.path("branchId").asText();
            if(!sid.matches("[A-Za-z0-9_-]{43}"))throw invalid();UUID.fromString(sub);UUID.fromString(tenant);UUID.fromString(branch);
            var permissions=new ArrayList<String>();for(var role:p.path("permissions")){if(!role.isString() || !role.asText().matches("[A-Z]{3}"))throw invalid();permissions.add(role.asText());}
            return new Claims(sid,sub,tenant,branch,List.copyOf(permissions),expiry);
        } catch(RuntimeException bad){throw invalid();}
    }
    private byte[] sign(String text) {
        try {var mac=Mac.getInstance("HmacSHA256");mac.init(new SecretKeySpec(key,"HmacSHA256"));return mac.doFinal(text.getBytes(StandardCharsets.US_ASCII));}
        catch(GeneralSecurityException e){throw new IllegalStateException("JWT signing unavailable",e);}
    }
    private static ApiException invalid(){return new ApiException(401,"UNAUTHENTICATED","Sesión de sucursal no válida. Vuelve a acceder.");}
}
