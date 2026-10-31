package com.mavric.health.scheduling.api;
import java.time.Instant;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.scheduling.application.SchedulingService;
import com.mavric.health.scheduling.domain.Requests.*;
@RestController @RequestMapping("/api/appointments")
public class SchedulingController {
    private final SchedulingService service;
    public SchedulingController(SchedulingService service) { this.service=service; }
    @GetMapping Object list(@RequestParam Instant from,@RequestParam Instant to,@RequestParam(required=false) String branchId) { return service.list(from,to,branchId); }
    @GetMapping("/{id}") Object get(@PathVariable String id) { return service.get(id); }
    @PostMapping Object create(@Valid @RequestBody Reserve p,@RequestHeader("Idempotency-Key") String key) { return service.reserve(p,key,false); }
    @PutMapping("/{id}") Object edit(@PathVariable String id,@Valid @RequestBody Change p) { return service.change(id,p); }
}
