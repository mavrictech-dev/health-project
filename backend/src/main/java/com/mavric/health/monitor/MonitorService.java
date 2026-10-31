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
    private final Sql sql;private final Access access;private final String instance=Checks.id();
    public MonitorService(Sql sql,Access access) {this.sql=sql;this.access=access;}
    @Scheduled(fixedDelay=15000,initialDelay=12000) public void sample() {long start=System.nanoTime();try {sql.one("SELECT 1 ready");var runtime=Runtime.getRuntime();sql.call("sp_health_sample",instance,"UP",(System.nanoTime()-start)/1_000_000,runtime.totalMemory()-runtime.freeMemory(),runtime.maxMemory(),ManagementFactory.getRuntimeMXBean().getUptime());} catch(Exception e) {org.slf4j.LoggerFactory.getLogger(MonitorService.class).warn("Database health sample unavailable");}}
    public Object status() {var state=sql.one("SELECT mode,message,revision FROM application_state WHERE id=1");state.put("status",state.get("mode").equals("OPEN")?"OPERATIONAL":"RESTRICTED");return state;}
    public Object details() {
        boolean platform=access.actor().tenantId()==null;if(platform) access.roles("SAD","SOP");else access.roles("ADM","AUD");
        Map<String,Object> result=new LinkedHashMap<>();result.put("application",status());result.put("version","0.1.0");result.put("instanceId",instance);result.put("uptimeMs",ManagementFactory.getRuntimeMXBean().getUptime());
        long start=System.nanoTime();sql.one("SELECT 1 ready");result.put("database",Map.of("status","UP","latencyMs",(System.nanoTime()-start)/1_000_000));
        if(platform) {result.put("samples",sql.rows("SELECT * FROM health_samples ORDER BY id DESC LIMIT 120"));result.put("mail",sql.rows("SELECT status,COUNT(*) total FROM mail_outbox GROUP BY status"));result.put("requests",sql.rows("SELECT FLOOR(status/100)*100 status_group,COUNT(*) total,ROUND(AVG(duration_ms)) average_ms FROM request_traces WHERE created_at>UTC_TIMESTAMP()-INTERVAL 1 HOUR GROUP BY status_group"));result.put("migrations",sql.rows("SELECT version,description,installed_on,success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 20"));}
        else {result.put("requests",sql.rows("SELECT FLOOR(status/100)*100 status_group,COUNT(*) total,ROUND(AVG(duration_ms)) average_ms FROM request_traces WHERE tenant_id=? AND created_at>UTC_TIMESTAMP()-INTERVAL 1 HOUR GROUP BY status_group",access.tenantId()));result.put("samples",List.of());}
        return result;
    }
    @Transactional public Object mode(int revision,String mode,String message) {access.platform();if(!Set.of("OPEN","READ_ONLY","MAINTENANCE").contains(mode) || message==null || message.isBlank() || message.length()>300) throw ApiException.invalid("Indica un estado y un motivo.");sql.call("sp_application_mode",access.userId(),revision,mode,message);return status();}
}
