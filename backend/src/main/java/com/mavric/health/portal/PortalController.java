package com.mavric.health.portal;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.scheduling.domain.Requests.Reserve;
@RestController @RequestMapping("/api/portal")
public class PortalController {
    private final PortalService service;
    public PortalController(PortalService service) { this.service=service; }
    @GetMapping("/patients") Object patients() { return service.patients(); }
    @GetMapping("/patients/{id}/documents") Object documents(@PathVariable String id) { return service.documents(id); }
    @GetMapping("/patients/{id}/appointments") Object appointments(@PathVariable String id) { return service.appointments(id); }
    @PostMapping("/appointments") Object reserve(@Valid @RequestBody Reserve p,@RequestHeader("Idempotency-Key") String key) { return service.reserve(p,key); }
    @GetMapping("/patients/{id}/balance") Object balance(@PathVariable String id) { return service.balance(id); }
}
