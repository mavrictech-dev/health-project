package com.mavric.health.workflows.api;
import java.util.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.workflows.application.WorkflowService;
import com.mavric.health.workflows.domain.Requests.*;
@RestController @RequestMapping("/api/workflows")
public class WorkflowController {
    private final WorkflowService service;
    public WorkflowController(WorkflowService service) { this.service=service; }
    @GetMapping("/definitions") Object definitions() { return service.definitions(); }
    @GetMapping Object list(@RequestParam String type) { return service.list(type); }
    @GetMapping("/{id}") Object get(@PathVariable String id) { return service.get(id); }
    @PostMapping Object create(@Valid @RequestBody Create p) { return service.create(p); }
    @PostMapping("/{id}/steps") Object step(@PathVariable String id,@Valid @RequestBody Step p) { return service.step(id,p); }
}
