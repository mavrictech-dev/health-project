package com.mavric.healthcards;

import java.time.*;
import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.identity.Access;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.shared.*;

@RestController @RequestMapping("/api/v1/agenda")
public class AgendaController {
    private final Access access;private final SqlServerCardsStore store;
    public AgendaController(Access access,SqlServerCardsStore store){this.access=access;this.store=store;}
    private void branch(HttpServletRequest request,String branchId){access.roles("ADM","REC","PRO","ASI","AUD","CAJ");Checks.id(branchId);if(!branchId.equals(request.getAttribute("health.branch")))throw ApiException.forbidden();access.branch(branchId);}
    static void window(Instant from,Instant to){if(from==null||to==null||!to.isAfter(from)||Duration.between(from,to).compareTo(Duration.ofDays(8))>0)throw ApiException.invalid("Selecciona un intervalo de hasta ocho días.");}
    @GetMapping("/contexto") public Object context(@RequestParam String branchId,HttpServletRequest req){branch(req,branchId);return store.one(req,SqlServerProcedure.AGENDA_CONTEXT,branchId).get("payload");}
    @GetMapping("/citas") public Object list(@RequestParam String branchId,@RequestParam Instant from,@RequestParam Instant to,@RequestParam(required=false) String professionalId,HttpServletRequest req){branch(req,branchId);window(from,to);if(professionalId!=null)Checks.id(professionalId);var rows=store.rows(req,SqlServerProcedure.AGENDA_LIST,branchId,from,to,professionalId);return Map.of("rows",rows.stream().limit(1000).toList(),"hasMore",rows.size()>1000);}
    @GetMapping("/arqueo") public Object reconciliation(@RequestParam String branchId,@RequestParam Instant from,@RequestParam Instant to,HttpServletRequest req){branch(req,branchId);access.roles("ADM","REC","CAJ","AUD");window(from,to);return store.rows(req,SqlServerProcedure.AGENDA_COLLECTION_SUMMARY,branchId,from,to);}
    public record Collection(@NotBlank String branchId,@NotBlank String requestId,@Min(0) int expectedRevision,@NotNull @Pattern(regexp="PENDING|PAID") String status,@Min(0) @Max(2000000000) int amountMinor,@Pattern(regexp="CASH|CARD|TRANSFER|YAPE|PLIN|OTHER") String paymentMethod){}
    @PutMapping("/citas/{id}/cobro") public Object collection(@PathVariable String id,@Valid @RequestBody Collection p,HttpServletRequest req){
        branch(req,p.branchId());access.write("CORE","ADM","REC","CAJ");Checks.id(id);Checks.id(p.requestId());
        if(p.status().equals("PAID")?(p.paymentMethod()==null||p.amountMinor()<1):p.paymentMethod()!=null)throw ApiException.invalid("Un cobro pagado requiere importe positivo y medio de pago; pendiente no admite medio de pago.");
        return store.one(req,SqlServerProcedure.AGENDA_COLLECTION_SAVE,id,p.branchId(),p.requestId(),p.expectedRevision(),p.status(),p.amountMinor(),p.paymentMethod());
    }
}
