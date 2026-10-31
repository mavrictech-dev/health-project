package com.mavric.health.identity;
import java.util.Map;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.tenancy.TenantRef;
@RestController
public class AccountLifecycleController {
    private final AccountLifecycleService service;
    public AccountLifecycleController(AccountLifecycleService service) {this.service=service;}
    public record Email(@NotBlank @jakarta.validation.constraints.Email @Size(max=254) String email) {}
    public record Redeem(@NotBlank String token,String password) {}
    private TenantRef tenant(HttpServletRequest req) {return (TenantRef)req.getAttribute("health.tenant");}
    private Map<String,String> accepted() {return Map.of("message","Si la solicitud corresponde a una cuenta disponible, recibirás un correo con los próximos pasos.");}
    @GetMapping("/api/public/registration") Object options(HttpServletRequest req) {return service.options(tenant(req));}
    @PostMapping("/api/auth/register") @ResponseStatus(org.springframework.http.HttpStatus.ACCEPTED) Object register(@Valid @RequestBody AccountLifecycleService.Register p,HttpServletRequest req) {service.rate(com.mavric.health.audit.TraceContext.address(req),"register");service.register(p,tenant(req));return accepted();}
    @PostMapping("/api/auth/recovery/request") Object recover(@Valid @RequestBody Email p,HttpServletRequest req) {service.rate(com.mavric.health.audit.TraceContext.address(req),"reset");service.request(p.email(),tenant(req),"RESET");return accepted();}
    @PostMapping("/api/auth/verify/request") Object verifyRequest(@Valid @RequestBody Email p,HttpServletRequest req) {service.rate(com.mavric.health.audit.TraceContext.address(req),"verify");service.request(p.email(),tenant(req),"VERIFY");return accepted();}
    @PostMapping("/api/auth/recovery/complete") Object reset(@Valid @RequestBody Redeem p,HttpServletRequest req) {service.redeem(p.token(),p.password(),tenant(req),"RESET");return Map.of("message","Contraseña actualizada. Inicia sesión con tu nueva contraseña.");}
    @PostMapping("/api/auth/verify/complete") Object verify(@Valid @RequestBody Redeem p,HttpServletRequest req) {service.redeem(p.token(),null,tenant(req),"VERIFY");return Map.of("message","Correo verificado. Ya puedes iniciar sesión en tu espacio.");}
}
