package com.mavric.health.audit;
import org.springframework.stereotype.Service;
import com.mavric.health.identity.Access;
import com.mavric.health.shared.*;
@Service
public class AuditService {
    private final Sql sql;private final Access access;private final com.mavric.health.persistence.sqlserver.SqlServerAuditStore store;
    @org.springframework.beans.factory.annotation.Autowired
    public AuditService(Sql sql,Access access) { this.sql=sql;this.access=access;this.store=null; }
    public AuditService(com.mavric.health.persistence.sqlserver.SqlServerAuditStore store,Access access) {this.sql=null;this.store=java.util.Objects.requireNonNull(store);this.access=access;}
    private jakarta.servlet.http.HttpServletRequest request(boolean tenantOnly) {
        var actor=access.actor();var req=TraceContext.REQUEST.get();if(req==null)throw database();Object host=req.getAttribute("health.tenant");
        if(host!=null && !(host instanceof com.mavric.health.tenancy.TenantRef))throw database();
        if(!actor.equals(req.getAttribute("health.actor")) || !java.util.Objects.equals(actor.tenantId(),host==null?null:((com.mavric.health.tenancy.TenantRef)host).id()))throw ApiException.forbidden();
        if(tenantOnly && host==null)throw ApiException.forbidden();if(actor.roles()==null)throw database();
        if(java.util.Collections.disjoint(actor.roles(),host==null?java.util.List.of("SAD","SOP"):java.util.List.of("ADM","AUD")))throw ApiException.forbidden();return req;
    }
    private static ApiException database(){return new ApiException(500,"DATABASE_ERROR","No se pudo completar la operacion de datos.");}
    public Object list(int limit) {if(store!=null)return store.list(request(true),limit); access.roles("ADM","AUD"); return sql.rows("SELECT id,actor_id,action,target_id,metadata,created_at FROM audit_events WHERE tenant_id=? ORDER BY id DESC LIMIT ?",access.tenantId(),Checks.limit(limit)); }
    private String scope(String alias,java.util.List<Object> args) { if(access.actor().tenantId()==null) {access.roles("SAD","SOP");return "1=1";} access.roles("ADM","AUD");args.add(access.tenantId());if(alias.equals("e")) {args.add(access.tenantId());return "(e.tenant_id=? OR (e.tenant_id IS NULL AND EXISTS(SELECT 1 FROM request_traces own_request WHERE own_request.id=e.request_id AND own_request.tenant_id=?)))";}return alias+".tenant_id=?"; }
    public Object events(String query,String actor,String resource,String requestId,String from,String to,long before,int limit) {
        if(store!=null)return store.events(request(false),query,actor,resource,requestId,from,to,before,limit);
        var args=new java.util.ArrayList<Object>();String where=scope("e",args);StringBuilder filter=new StringBuilder(where);
        if(query!=null && !query.isBlank()) {filter.append(" AND (e.action LIKE ? OR e.target_id LIKE ? OR u.name LIKE ?)");for(int i=0;i<3;i++) args.add("%"+query.substring(0,Math.min(100,query.length()))+"%");}
        if(actor!=null && !actor.isBlank()) {filter.append(" AND e.actor_id=?");args.add(Checks.id(actor));}
        if(resource!=null && !resource.isBlank()) {filter.append(" AND e.resource_type=?");args.add(resource);}
        if(requestId!=null && !requestId.isBlank()) {filter.append(" AND e.request_id=?");args.add(Checks.id(requestId));}
        if(from!=null && !from.isBlank()) {filter.append(" AND e.created_at>=?");args.add(java.sql.Timestamp.from(java.time.Instant.parse(from)));}
        if(to!=null && !to.isBlank()) {filter.append(" AND e.created_at<?");args.add(java.sql.Timestamp.from(java.time.Instant.parse(to)));}
        if(before>0) {filter.append(" AND e.id<?");args.add(before);}int size=Checks.limit(limit);args.add(size+1);
        var rows=sql.rows("SELECT e.*,u.name actor_name,u.email actor_email,t.name tenant_name FROM audit_events e LEFT JOIN users u ON u.id=e.actor_id LEFT JOIN tenants t ON t.id=e.tenant_id WHERE "+filter+" ORDER BY e.id DESC LIMIT ?",args.toArray());
        return java.util.Map.of("items",rows.stream().limit(size).toList(),"hasMore",rows.size()>size,"nextCursor",rows.isEmpty()?0:rows.get(Math.min(rows.size(),size)-1).get("id"));
    }
    public Object journey(String id) {if(store!=null)return store.journey(request(false),id);var args=new java.util.ArrayList<Object>();String scope=scope("r",args);args.add(Checks.id(id));var request=sql.one("SELECT r.*,u.name actor_name FROM request_traces r LEFT JOIN users u ON u.id=r.actor_id WHERE "+scope+" AND r.id=?",args.toArray());request.put("steps",((java.util.Map<?,?>)events(null,null,null,id,null,null,0,200)).get("items"));return request;}
    public Object requests(int limit,int status,String query) {if(store!=null)return store.requests(request(false),limit,status,query);var args=new java.util.ArrayList<Object>();String scope=scope("r",args);if(status>0) {scope+=" AND r.status>=?";args.add(status);}if(query!=null && !query.isBlank()) {scope+=" AND (r.route LIKE ? OR r.id=?)";args.add("%"+query+"%");args.add(query);}args.add(Checks.limit(limit));return sql.rows("SELECT r.*,u.name actor_name FROM request_traces r LEFT JOIN users u ON u.id=r.actor_id WHERE "+scope+" ORDER BY r.created_at DESC LIMIT ?",args.toArray());}
}
