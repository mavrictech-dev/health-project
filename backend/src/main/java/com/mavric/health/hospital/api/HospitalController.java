package com.mavric.health.hospital.api;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.hospital.application.HospitalService;
import com.mavric.health.hospital.domain.Requests.*;
@RestController @RequestMapping("/api/hospital")
public class HospitalController {
    private final HospitalService service;
    public HospitalController(HospitalService service) { this.service=service; }
    @GetMapping("/resources") Object resources() { return service.resources(); }
    @PostMapping("/resources") Object resource(@Valid @RequestBody Resource p) { return service.resource(p); }
    @GetMapping("/admissions") Object admissions() { return service.admissions(); }
    @PostMapping("/admissions") Object admit(@Valid @RequestBody Admission p) { return service.admit(p); }
    @PostMapping("/admissions/{id}/discharge") Object discharge(@PathVariable String id,@Valid @RequestBody Revision p) { return service.discharge(id,p.expectedRevision()); }
}
