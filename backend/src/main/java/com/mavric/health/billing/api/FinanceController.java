package com.mavric.health.billing.api;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.billing.application.FinanceService;
import com.mavric.health.billing.domain.Requests.*;
@RestController @RequestMapping("/api/finance")
public class FinanceController {
    private final FinanceService service;
    public FinanceController(FinanceService service) { this.service=service; }
    @GetMapping("/patients/{id}") Object balance(@PathVariable String id) { return service.balance(id); }
    @GetMapping("/patients/{id}/movements") Object movements(@PathVariable String id) { return service.movements(id); }
    @PostMapping("/movements") Object post(@Valid @RequestBody Post p,@RequestHeader("Idempotency-Key") String key) { return service.post(p,key); }
}
