package com.mavric.health.scheduling.application;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
import com.mavric.health.scheduling.domain.Requests.*;
import com.mavric.health.scheduling.domain.AppointmentStates;
@Service
public class SchedulingService {
    private final com.mavric.health.persistence.sqlserver.SqlServerSchedulingStore store;private final Sql sql; private final Access access;
    @org.springframework.beans.factory.annotation.Autowired
    public SchedulingService(Sql sql,Access access) { this.sql=sql;this.access=access;this.store=null; }
    public SchedulingService(com.mavric.health.persistence.sqlserver.SqlServerSchedulingStore store,Access access){this.sql=null;this.store=Objects.requireNonNull(store);this.access=access;}
    private static ApiException unavailable(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private jakarta.servlet.http.HttpServletRequest request(){var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request==null)throw unavailable();var actor=access.actor();Object host=request.getAttribute("health.tenant");if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw unavailable();if(!actor.equals(request.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();if(actor.roles()==null)throw unavailable();if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),List.of("REC","PRO","ASI","AUD")))throw ApiException.forbidden();access.roles("REC","PRO","ASI","AUD");return request;}

    private jakarta.servlet.http.HttpServletRequest writeRequest(boolean portal){
        var req=com.mavric.health.audit.TraceContext.REQUEST.get();if(req==null)throw unavailable();
        var actor=access.actor();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw unavailable();
        if(!actor.equals(req.getAttribute("health.actor")) || !(host instanceof com.mavric.health.tenancy.TenantRef tenant) || actor.tenantId()==null || !actor.tenantId().equals(tenant.id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw unavailable();
        var roles=portal?List.of("PAC","RES"):List.of("REC","PRO");
        if(actor.roles().contains("SAD") || actor.roles().contains("SOP") || Collections.disjoint(actor.roles(),roles))throw ApiException.forbidden();
        access.write("CORE",roles.toArray(String[]::new));return req;
    }
    public List<Map<String,Object>> list(Instant from,Instant to,String branchId) {if(store!=null){var req=request();if(branchId!=null){Checks.id(branchId);access.branch(branchId);}return store.list(req,from,to,branchId);} access.roles("REC","PRO","ASI","AUD"); if(branchId!=null) access.branch(branchId); if(!to.isAfter(from) || Duration.between(from,to).toDays()>93) throw ApiException.invalid("Consulta como máximo 93 días."); return sql.rows("SELECT * FROM appointments WHERE tenant_id=? AND starts_at>=? AND starts_at<? AND (? IS NULL OR branch_id=?) ORDER BY starts_at LIMIT 200",access.tenantId(),java.sql.Timestamp.from(from),java.sql.Timestamp.from(to),branchId,branchId); }
    public Map<String,Object> get(String id) {if(store!=null)return store.get(request(),id); access.roles("REC","PRO","ASI","AUD"); return row(id); }
    private Map<String,Object> row(String id) { return sql.one("SELECT * FROM appointments WHERE tenant_id=? AND id=?",access.tenantId(),Checks.id(id)); }
    public static void times(Instant start,Instant end) { if(start==null || end==null || !end.isAfter(start) || Duration.between(start,end).toMinutes()<5 || Duration.between(start,end).toMinutes()>480) throw ApiException.invalid("El horario debe durar entre 5 y 480 minutos."); }
    @Transactional public Map<String,Object> reserve(Reserve p,String key,boolean portal) {if(store!=null){
        var req=writeRequest(portal);if(p==null)throw ApiException.invalid("Datos de cita requeridos.");
        if(portal){access.module("PORTAL");Checks.id(p.patientId());access.link(p.patientId(),"APPOINTMENTS");if(!"REQUESTED".equals(p.status()))throw ApiException.invalid("El portal solicita citas; recepci\u00f3n confirma su reserva.");}
        else {Checks.id(p.branchId());access.branch(p.branchId());}
        times(p.startsAt(),p.endsAt());if(p.startsAt().isBefore(Instant.now().minusSeconds(60)))throw ApiException.invalid("Selecciona un horario futuro.");
        return store.reserve(req,p,key,portal);
    }
        access.write("CORE",portal?new String[]{"PAC","RES"}:new String[]{"REC","PRO"}); if(portal) { access.module("PORTAL"); access.link(p.patientId(),"APPOINTMENTS"); if(!p.status().equals("REQUESTED")) throw ApiException.invalid("El portal solicita citas; recepción confirma su reserva."); }
        else access.branch(p.branchId()); times(p.startsAt(),p.endsAt()); if(p.startsAt().isBefore(Instant.now().minusSeconds(60))) throw ApiException.invalid("Selecciona un horario futuro.");
        Map<String,Object> body=new LinkedHashMap<>(); body.put("patientId",Checks.id(p.patientId())); body.put("branchId",Checks.id(p.branchId())); body.put("professionalId",Checks.id(p.professionalId())); body.put("specialtyCode",p.specialtyCode()); body.put("startsAt",utc(p.startsAt())); body.put("endsAt",utc(p.endsAt())); body.put("status",p.status()); body.put("service",p.service()); body.put("note",p.note());
        sql.call("sp_appointment_reserve",access.tenantId(),Checks.id(),access.userId(),sql.json(body),Idempotency.key(key),Checks.hash(sql.json(p)));
        return sql.one("SELECT * FROM appointments WHERE tenant_id=? AND request_key=?",access.tenantId(),key);
    }
    @Transactional public Map<String,Object> change(String id,Change p) {if(store!=null){var req=writeRequest(false);return store.change(req,id,p,access::branch);}
        access.write("CORE","REC","PRO"); var current=row(id); access.branch(current.get("branchId").toString()); AppointmentStates.check(current.get("status").toString(),p.status());
        if(p.startsAt()!=null || p.endsAt()!=null) { times(p.startsAt(),p.endsAt()); if(!p.status().equals("RESERVED") || p.startsAt().isBefore(Instant.now())) throw ApiException.invalid("Reprograma una reserva a un horario futuro."); }
        sql.call("sp_appointment_change",access.tenantId(),id,access.userId(),p.expectedRevision(),p.status(),p.startsAt(),p.endsAt()); return row(id);
    }
    private static String utc(Instant i) { return DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSSSSS").withZone(ZoneOffset.UTC).format(i); }
}
