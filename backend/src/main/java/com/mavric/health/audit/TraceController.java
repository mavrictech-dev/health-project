package com.mavric.health.audit;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/trace")
public class TraceController {
    private final AuditService service;
    public TraceController(AuditService service) {this.service=service;}
    @GetMapping("/events") Object events(@RequestParam(required=false) String query,@RequestParam(required=false) String actor,@RequestParam(required=false) String resource,@RequestParam(required=false) String requestId,@RequestParam(required=false) String from,@RequestParam(required=false) String to,@RequestParam(defaultValue="0") long before,@RequestParam(defaultValue="50") int limit) {return service.events(query,actor,resource,requestId,from,to,before,limit);}
    @GetMapping("/requests") Object requests(@RequestParam(defaultValue="50") int limit,@RequestParam(defaultValue="0") int status,@RequestParam(defaultValue="") String query) {return service.requests(limit,status,query);}
    @GetMapping("/requests/{id}") Object journey(@PathVariable String id) {return service.journey(id);}
}
