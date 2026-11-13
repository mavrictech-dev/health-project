package com.mavric.health.saas.api;
import java.util.*;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.saas.application.PlatformService;
import com.mavric.health.saas.domain.Requests.*;
import com.mavric.health.organization.application.OrganizationService;
import com.mavric.health.organization.domain.Requests.*;
import com.mavric.health.identity.IdentityService.UserInput;

@RestController @RequestMapping("/api/platform")
public class PlatformController {
    private final PlatformService service; private final OrganizationService organization;
    public PlatformController(PlatformService service,OrganizationService organization) { this.service=service; this.organization=organization; }
    @GetMapping("/plans") Object plans() { return service.plans(); }
    @PostMapping("/plans") Object plan(@Valid @RequestBody Plan p) { return service.plan(null,p); }
    @PutMapping("/plans/{id}") Object plan(@PathVariable String id,@Valid @RequestBody Plan p) { return service.plan(id,p); }
    @GetMapping("/users") Object users(@RequestParam(defaultValue="100") int limit) { return service.users(limit); }
    @PostMapping("/users") Object user(@Valid @RequestBody UserInput p) { return service.createUser(p); }
    @GetMapping("/tenants") Object tenants(@RequestParam(defaultValue="100") int limit) { return service.tenants(limit); }
    @PostMapping("/tenants") Object tenant(@Valid @RequestBody Tenant p) { return service.create(p); }
    @GetMapping("/tenants/{id}") Object tenant(@PathVariable String id) { return service.tenant(id); }
    @PutMapping("/tenants/{id}/profile") Object profile(@PathVariable String id,@Valid @RequestBody com.mavric.health.identity.RucRequests.Profile p) {return service.profile(id,p);}
    @PutMapping("/tenants/{id}/status") Object status(@PathVariable String id,@Valid @RequestBody Status p) { return service.status(id,p); }
    @GetMapping("/tenants/{id}/configuration") Object config(@PathVariable String id) { return organization.configuration(id); }
    @PutMapping("/tenants/{id}/subscription") Object subscription(@PathVariable String id,@Valid @RequestBody Subscription p) { return organization.subscription(id,p); }
    @PostMapping("/tenants/{id}/branches") Object branch(@PathVariable String id,@Valid @RequestBody Branch p) { return organization.branch(id,null,p); }
    @PutMapping("/tenants/{id}/branches/{branch}") Object branch(@PathVariable String id,@PathVariable String branch,@Valid @RequestBody Branch p) { return organization.branch(id,branch,p); }
    @PostMapping("/tenants/{id}/areas") Object area(@PathVariable String id,@Valid @RequestBody Area p) { return organization.area(id,null,p); }
    @PutMapping("/tenants/{id}/areas/{area}") Object area(@PathVariable String id,@PathVariable String area,@Valid @RequestBody Area p) { return organization.area(id,area,p); }
    @PutMapping("/tenants/{id}/specialties") Object specialties(@PathVariable String id,@Valid @RequestBody Specialties p) { return organization.specialties(id,p); }
    @PutMapping("/tenants/{id}/members") Object member(@PathVariable String id,@Valid @RequestBody Member p) { return organization.member(id,p); }
    @PostMapping("/tenants/{id}/invoices/{invoice}/payment") Object pay(@PathVariable String id,@PathVariable String invoice) { return service.pay(id,invoice); }
    @GetMapping("/specialties") Object catalog(@RequestParam(defaultValue="") String query) { return service.specialties(query); }
    @GetMapping("/audit") Object audit(@RequestParam(defaultValue="100") int limit) { return service.audit(limit); }
}
