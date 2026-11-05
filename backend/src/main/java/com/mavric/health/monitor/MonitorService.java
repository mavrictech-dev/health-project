package com.mavric.health.monitor;
import java.util.*;
import java.lang.management.ManagementFactory;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.shared.*;
import com.mavric.health.identity.Access;
@Service
public class MonitorService {
    private final com.mavric.health.persistence.sqlserver.SqlServerMonitorStore store;private final Sql sql;private final Access access;private final String instance=Checks.id();
    @org.springframework.beans.factory.annotation.Autowired
    public MonitorService(Sql sql,Access access) {this.sql=sql;this.access=access;this.store=null;}
    public MonitorService(com.mavric.health.persistence.sqlserver.SqlServerMonitorStore store,Access access){this.sql=null;this.store=Objects.requireNonNull(store);this.access=access;}
    private static ApiException unavailable(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    private jakarta.servlet.http.HttpServletRequest monitorRequest(boolean write){
        var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request==null)throw unavailable();var actor=access.actor();Object host=request.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw unavailable();
        if(!actor.equals(request.getAttribute("health.actor")) || !Objects.equals(actor.tenantId(),host==null?null:((com.mavric.health.tenancy.TenantRef)host).id()))throw ApiException.forbidden();
        if(actor.roles()==null)throw unavailable();
        if(write?(host!=null || !actor.roles().contains("SAD")):Collections.disjoint(actor.roles(),host==null?List.of("SAD","SOP"):List.of("ADM","AUD")))throw ApiException.forbidden();return request;
    }
    private void sampleSql(){try{var runtime=Runtime.getRuntime();store.sample(instance,runtime.totalMemory()-runtime.freeMemory(),runtime.maxMemory(),ManagementFactory.getRuntimeMXBean().getUptime());}catch(Exception error){org.slf4j.LoggerFactory.getLogger(MonitorService.class).warn("Database health sample unavailable");}}

    @Scheduled(fixedDelay=15000,initialDelay=12000) public void sample() {if(store!=null){sampleSql();return;}long start=System.nanoTime();try {sql.one("SELECT 1 ready");var runtime=Runtime.getRuntime();sql.call("sp_health_sample",instance,"UP",(System.nanoTime()-start)/1_000_000,runtime.totalMemory()-runtime.freeMemory(),runtime.maxMemory(),ManagementFactory.getRuntimeMXBean().getUptime());} catch(Exception e) {org.slf4j.LoggerFactory.getLogger(MonitorService.class).warn("Database health sample unavailable");}}
    public Object status() {if(store!=null){var request=com.mavric.health.audit.TraceContext.REQUEST.get();if(request==null)throw unavailable();return store.status(request);}var state=sql.one("SELECT mode,message,revision FROM application_state WHERE id=1");state.put("status",state.get("mode").equals("OPEN")?"OPERATIONAL":"RESTRICTED");return state;}
    public Object details() {if(store!=null){var request=monitorRequest(false);var data=store.details(request);var result=new LinkedHashMap<String,Object>(data);result.put("version","0.1.0");result.put("instanceId",instance);result.put("uptimeMs",ManagementFactory.getRuntimeMXBean().getUptime());return Collections.unmodifiableMap(result);}
        boolean platform=access.actor().tenantId()==null;if(platform) access.roles("SAD","SOP");else access.roles("ADM","AUD");
        Map<String,Object> result=new LinkedHashMap<>();result.put("application",status());result.put("version","0.1.0");result.put("instanceId",instance);result.put("uptimeMs",ManagementFactory.getRuntimeMXBean().getUptime());
        long start=System.nanoTime();sql.one("SELECT 1 ready");result.put("database",Map.of("status","UP","latencyMs",(System.nanoTime()-start)/1_000_000));
        if(platform) {result.put("samples",sql.rows("SELECT * FROM health_samples ORDER BY id DESC LIMIT 120"));result.put("mail",sql.rows("SELECT status,COUNT(*) total FROM mail_outbox GROUP BY status"));result.put("requests",sql.rows("SELECT FLOOR(status/100)*100 status_group,COUNT(*) total,ROUND(AVG(duration_ms)) average_ms FROM request_traces WHERE created_at>UTC_TIMESTAMP()-INTERVAL 1 HOUR GROUP BY status_group"));result.put("migrations",sql.rows("SELECT version,description,installed_on,success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 20"));}
        else {result.put("requests",sql.rows("SELECT FLOOR(status/100)*100 status_group,COUNT(*) total,ROUND(AVG(duration_ms)) average_ms FROM request_traces WHERE tenant_id=? AND created_at>UTC_TIMESTAMP()-INTERVAL 1 HOUR GROUP BY status_group",access.tenantId()));result.put("samples",List.of());}
        return result;
    }
    @Transactional public Object mode(int revision,String mode,String message) {if(store!=null){var request=monitorRequest(true);access.platform();return store.mode(request,revision,mode,message);}access.platform();if(!Set.of("OPEN","READ_ONLY","MAINTENANCE").contains(mode) || message==null || message.isBlank() || message.length()>300) throw ApiException.invalid("Indica un estado y un motivo.");sql.call("sp_application_mode",access.userId(),revision,mode,message);return status();}
}
