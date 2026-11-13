package com.mavric.health.identity;

import java.util.Map;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.tenancy.*;

@RestController
public class AuthController {
    private final IdentityService service; private final Access access; private final Settings settings;
    public AuthController(IdentityService service,Access access,Settings settings) { this.service=service; this.access=access; this.settings=settings; }
    public record Login(@NotBlank @Email @Size(max=254) String email,@NotBlank @Size(max=128) String password) { }
    public record Password(@NotBlank String currentPassword,@NotBlank String newPassword) { }
    @PostMapping("/api/auth/login") Map<String,Object> login(@Valid @RequestBody RucRequests.Login input,HttpServletRequest req) { return service.login(input.ruc(),input.email(),input.password(),(TenantRef)req.getAttribute("health.tenant"),com.mavric.health.audit.TraceContext.address(req)); }
    @PostMapping("/api/public/tenant-space") Map<String,Object> space(@Valid @RequestBody RucRequests.Space input,HttpServletRequest req){return service.tenantSpace(input.ruc(),com.mavric.health.audit.TraceContext.address(req));}
    @PostMapping("/api/auth/invitations/accept") Map<String,Object> accept(@Valid @RequestBody Login input,HttpServletRequest req) { return service.accept(input.email(),input.password(),(TenantRef)req.getAttribute("health.tenant"),com.mavric.health.audit.TraceContext.address(req)); }
    @GetMapping("/api/auth/me") Map<String,Object> me() { Actor actor=access.actor(); var data=new java.util.LinkedHashMap<String,Object>(); data.put("id",actor.id()); data.put("name",actor.name()); data.put("email",actor.email()); data.put("roles",actor.roles()); data.put("tenantId",actor.tenantId()); return data; }
    @DeleteMapping("/api/auth/session") void logout() { service.logout(); }
    @PutMapping("/api/auth/password") void password(@Valid @RequestBody Password input) { service.password(input.currentPassword(),input.newPassword()); }
    @GetMapping("/api/public/context") Map<String,Object> context(HttpServletRequest req) { TenantRef tenant=(TenantRef)req.getAttribute("health.tenant"); if(tenant==null)return Map.of("platform",true,"baseDomain",settings.baseDomain());var result=new java.util.LinkedHashMap<String,Object>();result.put("platform",false);result.put("id",tenant.id());result.put("name",tenant.name());result.put("slug",tenant.slug());result.put("kind",tenant.kind());result.put("domain",tenant.domain());result.put("hostname",settings.hostname(tenant.slug()));if(tenant.ruc()!=null){result.put("ruc",tenant.ruc());result.put("revision",tenant.revision());}return java.util.Collections.unmodifiableMap(result); }
}
