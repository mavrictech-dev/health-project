package com.mavric.health.audit;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/audit")
public class AuditController {
    private final AuditService service;
    public AuditController(AuditService service) { this.service=service; }
    @GetMapping Object audit(@RequestParam(defaultValue="100") int limit) { return service.list(limit); }
}
