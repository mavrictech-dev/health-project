package com.mavric.health.patients.api;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.patients.application.PatientService;
import com.mavric.health.patients.domain.Requests.*;
@RestController @RequestMapping({"/api/patients","/api/v1/pacientes"})
public class PatientController {
    private final PatientService service;
    public PatientController(PatientService service) { this.service=service; }
    @GetMapping Object list(@RequestParam(defaultValue="") String query,@RequestParam(defaultValue="50") int limit,@RequestParam(defaultValue="0") int offset) { return service.list(query,limit,offset); }
    @GetMapping("/{id}") Object get(@PathVariable String id) { return service.get(id); }
    @GetMapping("/{id}/links") Object links(@PathVariable String id,@RequestParam(defaultValue="50") String limit,@RequestParam(defaultValue="0") String offset) { return service.links(id,Integer.parseInt(limit),Integer.parseInt(offset)); }
    @GetMapping("/{id}/links/{userId}") Object linkEdit(@PathVariable String id,@PathVariable String userId) { return service.linkEdit(id,userId); }
    @PostMapping Object create(@Valid @RequestBody Patient p) { return service.save(null,p,0); }
    @PutMapping("/{id}") Object edit(@PathVariable String id,@Valid @RequestBody Edit p) { return service.save(id,p.patient(),p.expectedRevision()); }
    @PutMapping("/{id}/links") Object link(@PathVariable String id,@Valid @RequestBody Link p) { return service.link(id,p); }
    @GetMapping("/{id}/history") Object history(@PathVariable String id) { return service.history(id); }
}
