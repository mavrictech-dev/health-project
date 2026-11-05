package com.mavric.health.support;
import java.util.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.shared.*;
import com.mavric.health.identity.*;
import com.mavric.health.tenancy.TenantRef;
@RestController
public class SupportController {
    private final com.mavric.health.persistence.sqlserver.SqlServerSupportStore store;private final Sql sql;private final Access access;private final AccountLifecycleService lifecycle;
    @org.springframework.beans.factory.annotation.Autowired
    public SupportController(Sql sql,Access access,AccountLifecycleService lifecycle) {this.sql=sql;this.access=access;this.lifecycle=lifecycle;this.store=null;}
    public SupportController(com.mavric.health.persistence.sqlserver.SqlServerSupportStore store,Access access,AccountLifecycleService lifecycle){this.sql=null;this.store=Objects.requireNonNull(store);this.access=access;this.lifecycle=lifecycle;}
    private static ApiException unavailable(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private HttpServletRequest request(){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw unavailable();var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof TenantRef))throw unavailable();
        if(!actor.equals(req.getAttribute("health.actor")) || !Objects.equals(actor.tenantId(),host==null?null:((TenantRef)host).id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw unavailable();if(host==null && Collections.disjoint(actor.roles(),List.of("SAD","SOP")))throw ApiException.forbidden();return req;
    }
    public record Ticket(@NotBlank @jakarta.validation.constraints.Email @Size(max=254) String email,@NotBlank @Size(max=180) String subject,@NotBlank @Size(max=4000) String message,@NotNull @Pattern(regexp="LOW|NORMAL|HIGH|URGENT") String priority) {}
    public record Step(@Min(1) int expectedRevision,@Pattern(regexp="OPEN|IN_PROGRESS|WAITING_USER|RESOLVED|CLOSED") @NotNull String status,@NotNull @Pattern(regexp="LOW|NORMAL|HIGH|URGENT") String priority,@Size(max=4000) String message) {}
    @PostMapping("/api/public/support") @Transactional Object create(@Valid @RequestBody Ticket p,HttpServletRequest req) {if(store!=null)throw unavailable();lifecycle.rate(com.mavric.health.audit.TraceContext.address(req),"support");String id=Checks.id(),ref="MVT-"+UUID.randomUUID().toString().substring(0,12).toUpperCase(Locale.ROOT);var t=(TenantRef)req.getAttribute("health.tenant");var a=(Actor)req.getAttribute("health.actor");sql.call("sp_support_create",id,t==null?null:t.id(),a==null?null:a.id(),ref,sql.json(p));return Map.of("reference",ref,"status","OPEN","message","Solicitud registrada. Conserva tu referencia.","provider","Mavric Technologies","website","https://mavrictec.com");}
    @GetMapping("/api/support") Object list() {if(store!=null)return store.list(request());if(access.actor().tenantId()==null) {access.roles("SAD","SOP");return sql.rows("SELECT * FROM support_tickets ORDER BY updated_at DESC LIMIT 200");}return sql.rows("SELECT * FROM support_tickets WHERE tenant_id=? AND actor_id=? ORDER BY updated_at DESC LIMIT 100",access.tenantId(),access.userId());}
    private Map<String,Object> ticket(String id) {var row=sql.one("SELECT * FROM support_tickets WHERE id=?",Checks.id(id));var actor=access.actor();if(actor.tenantId()==null) access.roles("SAD","SOP");else if(!actor.tenantId().equals(row.get("tenantId")) || !actor.id().equals(row.get("actorId"))) throw ApiException.missing();return row;}
    @GetMapping("/api/support/{id}") Object get(@PathVariable String id) {if(store!=null)return store.detail(request(),id);var row=ticket(id);row.put("comments",sql.rows("SELECT c.id,c.message,c.created_at,u.name actor_name FROM support_comments c JOIN users u ON u.id=c.actor_id WHERE ticket_id=? ORDER BY c.created_at",id));return row;}
    @PostMapping("/api/support/{id}/steps") @Transactional Object step(@PathVariable String id,@Valid @RequestBody Step p) {if(store!=null)throw unavailable();var row=ticket(id);if(access.actor().tenantId()!=null) {if(!row.get("status").equals(p.status()) || !row.get("priority").equals(p.priority())) throw ApiException.forbidden();if(p.message()==null || p.message().isBlank()) throw ApiException.invalid("Escribe tu respuesta.");}sql.call("sp_support_step",id,access.userId(),p.expectedRevision(),p.status(),p.priority(),Checks.id(),p.message());return get(id);}
}
