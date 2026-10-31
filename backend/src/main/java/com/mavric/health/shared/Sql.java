package com.mavric.health.shared;

import java.sql.*;
import java.time.Instant;
import java.util.*;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import tools.jackson.databind.ObjectMapper;

@Repository
public class Sql {
    private static final Set<String> JSON_COLUMNS=Set.of("roles","modules","kinds","domains","specialties","branches","scopes","profile","profileSnapshot","payload","metadata","contact","allergies","creators","operators","readers","transitions","beforeState","afterState","actorRoles");
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;
    public Sql(JdbcTemplate jdbc,ObjectMapper mapper) { this.jdbc=jdbc; this.mapper=mapper; }
    public String json(Object value) { return mapper.writeValueAsString(value); }
    public List<String> strings(Object value) { if(value instanceof Collection<?> c) return c.stream().map(Object::toString).toList(); return List.of(); }
    public List<Map<String,Object>> rows(String query,Object... params) {
        return jdbc.queryForList(query,params).stream().map(row->{
            Map<String,Object> result=new LinkedHashMap<>();
            row.forEach((key,value)->{
                String camel=camel(key);
                if(value instanceof byte[] bytes) value=new String(bytes,java.nio.charset.StandardCharsets.UTF_8);
                if(value instanceof String text && JSON_COLUMNS.contains(camel)) value=mapper.readValue(text,Object.class);
                if(value instanceof Timestamp stamp) value=stamp.toInstant().toString();
                if(value instanceof java.time.LocalDateTime local) value=local.toInstant(java.time.ZoneOffset.UTC).toString();
                if(value instanceof java.sql.Date date) value=date.toLocalDate().toString();
                result.put(camel,value);
            }); return result;
        }).toList();
    }
    public Optional<Map<String,Object>> optional(String q,Object... p) { return rows(q,p).stream().findFirst(); }
    public Map<String,Object> one(String q,Object... p) { return optional(q,p).orElseThrow(ApiException::missing); }
    public void call(String procedure,Object... parameters) {
        if(!procedure.matches("sp_[a-z_]+")) throw new IllegalArgumentException("Invalid procedure");
        jdbc.execute((ConnectionCallback<Void>) connection->{
            var req=com.mavric.health.audit.TraceContext.REQUEST.get();
            var actor=req==null?null:(com.mavric.health.identity.Actor)req.getAttribute("health.actor");
            var tenant=req==null?null:(com.mavric.health.tenancy.TenantRef)req.getAttribute("health.tenant");
            try(var context=connection.prepareStatement("SET @hp_request_id=?,@hp_method=?,@hp_route=?,@hp_source_ip=?,@hp_user_agent=?,@hp_actor_id=?,@hp_actor_roles=CONVERT(? USING utf8mb4),@hp_tenant_id=?")) {
                Object[] values={req==null?null:req.getAttribute("health.requestId"),req==null?null:req.getMethod(),req==null?null:req.getRequestURI().substring(0,Math.min(250,req.getRequestURI().length())),req==null?null:com.mavric.health.audit.TraceContext.address(req),req==null?null:Objects.toString(req.getHeader("User-Agent"),"").substring(0,Math.min(300,Objects.toString(req.getHeader("User-Agent"),"").length())),actor==null?null:actor.id(),actor==null?null:json(actor.roles()),tenant==null?null:tenant.id()};
                for(int i=0;i<values.length;i++) context.setObject(i+1,values[i]); context.execute();
            }
            try(CallableStatement statement=connection.prepareCall("{call "+procedure+"("+String.join(",",Collections.nCopies(parameters.length,"?"))+")}")) {
                for(int i=0;i<parameters.length;i++) {
                    Object value=parameters[i]; if(value instanceof Instant instant) value=Timestamp.from(instant);
                    statement.setObject(i+1,value);
                }
                boolean hasResult=statement.execute();
                while(true) { if(hasResult) { try(ResultSet ignored=statement.getResultSet()) { } } else if(statement.getUpdateCount()==-1) break; hasResult=statement.getMoreResults(); }
            } return null;
        });
    }
    private String camel(String s) { StringBuilder b=new StringBuilder(); boolean upper=false; for(char c:s.toCharArray()) { if(c=='_') upper=true; else { b.append(upper?Character.toUpperCase(c):c); upper=false; } } return b.toString(); }
}
