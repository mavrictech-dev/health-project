package com.mavric.health.monitor;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
@RestController
public class MonitorController {
    private final MonitorService service;
    public MonitorController(MonitorService service) {this.service=service;}
    public record Mode(@Min(1) int expectedRevision,@NotBlank String mode,@NotBlank String message) {}
    @GetMapping("/api/public/status") Object status() {return service.status();}
    @GetMapping("/api/monitor") Object details() {return service.details();}
    @PutMapping("/api/monitor/mode") Object mode(@Valid @RequestBody Mode p) {return service.mode(p.expectedRevision(),p.mode(),p.message());}
}
