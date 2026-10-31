package com.mavric.health.clinical.api;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.clinical.application.ClinicalService;
import com.mavric.health.clinical.domain.Requests.*;
@RestController @RequestMapping("/api/encounters")
public class ClinicalController {
    private final ClinicalService service;
    public ClinicalController(ClinicalService service) { this.service=service; }
    @PostMapping Object start(@Valid @RequestBody Start p) { return service.start(p); }
    @GetMapping("/{id}") Object get(@PathVariable String id) { return service.get(id); }
    @PutMapping("/{id}/note") Object note(@PathVariable String id,@Valid @RequestBody Note p) { return service.note(id,p,false); }
    @PostMapping("/{id}/finalize") Object close(@PathVariable String id,@Valid @RequestBody Note p) { return service.note(id,p,true); }
    @PostMapping("/{id}/entries") Object entry(@PathVariable String id,@Valid @RequestBody Entry p) { return service.entry(id,p); }
}
