package com.mavric.health.shared;

import java.sql.SQLException;
import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import tools.jackson.databind.ObjectMapper;

@Component
public class Errors {
    private final ObjectMapper mapper;
    public Errors(ObjectMapper mapper) { this.mapper=mapper; }
    public Map<String,Object> body(int status,String code,String detail,HttpServletRequest request) {
        return Map.of("type","urn:health-project:error:"+code.toLowerCase(Locale.ROOT),"title",code,"status",status,"detail",detail,"instance",request.getRequestURI(),"requestId",Objects.toString(request.getAttribute("health.requestId"),UUID.randomUUID().toString()));
    }
    public void write(HttpServletRequest req,HttpServletResponse res,ApiException e) throws java.io.IOException { res.setStatus(e.status); res.setCharacterEncoding("UTF-8"); res.setContentType("application/problem+json"); res.getWriter().write(mapper.writeValueAsString(body(e.status,e.code,e.getMessage(),req))); }
    @RestControllerAdvice
    public static class Advice {
        private final Errors errors;
        public Advice(Errors errors) { this.errors=errors; }
        private ResponseEntity<?> result(int status,String code,String detail,HttpServletRequest req) { return ResponseEntity.status(status).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(errors.body(status,code,detail,req)); }
        @ExceptionHandler(ApiException.class) public ResponseEntity<?> api(ApiException e,HttpServletRequest req) { return result(e.status,e.code,e.getMessage(),req); }
        @ExceptionHandler(MethodArgumentNotValidException.class) public ResponseEntity<?> validation(MethodArgumentNotValidException e,HttpServletRequest req) { return result(400,"VALIDATION_FAILED",e.getBindingResult().getFieldErrors().stream().map(f->f.getField()+": "+f.getDefaultMessage()).distinct().collect(java.util.stream.Collectors.joining("; ")),req); }
        @ExceptionHandler({HttpMessageNotReadableException.class,IllegalArgumentException.class}) public ResponseEntity<?> invalid(Exception e,HttpServletRequest req) { return result(400,"INVALID_REQUEST","Formato o campos no válidos.",req); }
        @ExceptionHandler(DataAccessException.class) public ResponseEntity<?> database(DataAccessException e,HttpServletRequest req) {
            Throwable c=e; while(c.getCause()!=null) c=c.getCause();
            if(c instanceof SQLException sql && "45000".equals(sql.getSQLState())) {
                String[] parts=sql.getMessage().split(":",2); String code=parts[0].replace("HP_","");
                int status=switch(code) { case "NOT_FOUND"->404; case "FORBIDDEN","SUSPENDED"->403; case "INVALID"->400; default->409; };
                return result(status,code,parts.length>1?parts[1]:"Operación rechazada.",req);
            }
            if(c instanceof SQLException sql && (sql.getErrorCode()==1213 || sql.getErrorCode()==1205)) return result(409,"CONCURRENT_CHANGE","Otra operación cambió el recurso. Reintenta con la misma clave de idempotencia.",req);
            if(c instanceof SQLException sql && Set.of(1062,1451,1452,3819).contains(sql.getErrorCode())) return result(409,"DATA_CONFLICT","Referencia inválida o recurso duplicado.",req);
            org.slf4j.LoggerFactory.getLogger(Advice.class).error("Database operation failed at {} with code {}",req.getRequestURI(),c instanceof SQLException sql?sql.getErrorCode():0);
            return result(500,"DATABASE_ERROR","No se pudo completar la operación de datos.",req);
        }
        @ExceptionHandler(Exception.class) public ResponseEntity<?> unexpected(Exception e,HttpServletRequest req) { org.slf4j.LoggerFactory.getLogger(Advice.class).error("Unhandled {} at {}",e.getClass().getSimpleName(),req.getRequestURI()); return result(500,"INTERNAL_ERROR","No se pudo completar la operación.",req); }
    }
}
