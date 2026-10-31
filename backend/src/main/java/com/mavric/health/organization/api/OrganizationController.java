package com.mavric.health.organization.api;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.organization.application.OrganizationService;
import com.mavric.health.organization.domain.Requests.*;
import com.mavric.health.saas.domain.Requests.Subscription;

@RestController @RequestMapping("/api/tenant")
public class OrganizationController {
    private final OrganizationService service;
    public OrganizationController(OrganizationService service) { this.service=service; }
    @GetMapping("/configuration") Object config() { return service.configuration(null); }
    @PutMapping("/subscription") Object subscription(@Valid @RequestBody Subscription p) { return service.subscription(null,p); }
    @GetMapping("/plans") Object plans() { return service.availablePlans(); }
    @GetMapping("/branches") Object branches() { return service.directory(); }
    @PostMapping("/branches") Object branch(@Valid @RequestBody Branch p) { return service.branch(null,null,p); }
    @PutMapping("/branches/{id}") Object branch(@PathVariable String id,@Valid @RequestBody Branch p) { return service.branch(null,id,p); }
    @PostMapping("/areas") Object area(@Valid @RequestBody Area p) { return service.area(null,null,p); }
    @PutMapping("/areas/{id}") Object area(@PathVariable String id,@Valid @RequestBody Area p) { return service.area(null,id,p); }
    @PutMapping("/specialties") Object specialties(@Valid @RequestBody Specialties p) { return service.specialties(null,p); }
    @GetMapping("/specialties/catalog") Object catalog() { return service.catalog(); }
    @PutMapping("/members") Object member(@Valid @RequestBody Member p) { return service.member(null,p); }
    @GetMapping("/members/lookup") Object lookup(@RequestParam String email) { return service.lookup(email); }
    @GetMapping("/professionals") Object professionals(@RequestParam(required=false) String branchId) { return service.professionals(branchId); }
}
