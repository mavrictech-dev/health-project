package com.mavric.health.documents.api;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.documents.application.DocumentService;
import com.mavric.health.documents.domain.Requests.*;
@RestController @RequestMapping("/api/documents")
public class DocumentController {
    private final DocumentService service;
    public DocumentController(DocumentService service) { this.service=service; }
    @GetMapping Object list(@RequestParam String patientId) { return service.list(patientId); }
    @GetMapping("/{id}") Object get(@PathVariable String id) { return service.get(id); }
    @PostMapping Object create(@Valid @RequestBody Create p) { return service.create(p); }
    @PutMapping("/{id}") Object change(@PathVariable String id,@Valid @RequestBody Change p) { return service.change(id,p); }
}
