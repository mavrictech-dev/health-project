package com.mavric.health.inventory.api;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.inventory.application.InventoryService;
import com.mavric.health.inventory.domain.Requests.*;
@RestController @RequestMapping("/api/inventory")
public class InventoryController {
    private final InventoryService service;
    public InventoryController(InventoryService service) { this.service=service; }
    @GetMapping("/lots") Object lots() { return service.lots(); }
    @PostMapping("/lots") Object lot(@Valid @RequestBody Lot p) { return service.lot(p); }
    @PostMapping("/movements") Object move(@Valid @RequestBody Move p,@RequestHeader("Idempotency-Key") String key) { return service.move(p,key); }
    @GetMapping("/transfers") Object transfers() { return service.transfers(); }
    @PostMapping("/transfers") Object transfer(@Valid @RequestBody Transfer p,@RequestHeader("Idempotency-Key") String key) { return service.transfer(p,key); }
    @PostMapping("/transfers/{id}/receive") Object receive(@PathVariable String id) { return service.receive(id); }
    @GetMapping("/prescriptions") Object prescriptions() { return service.prescriptions(); }
}
