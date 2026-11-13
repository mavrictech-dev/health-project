package com.mavric.healthcards;

import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.identity.Access;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.shared.*;

@RestController @RequestMapping("/api/v1")
public class CardsController {
    private final Access access;private final SqlServerCardsStore store;
    public CardsController(Access access,SqlServerCardsStore store){this.access=access;this.store=store;}
    public record Antecedent(@Min(0) int expectedVersion,@NotBlank @Size(max=20000) String personal,@NotNull @Size(max=20000) String family,@NotNull @Size(max=20000) String allergies,@NotNull @Size(max=20000) String medication){}
    public record Consultation(@NotBlank String requestId,@NotBlank String patientId,@NotBlank String branchId,@NotBlank @Size(max=20000) String anamnesis,@NotNull @Size(max=20000) String physicalExam,@NotNull @Size(max=20000) String diagnosis,@NotNull @Size(max=20000) String treatment,@NotNull @Pattern(regexp="ATTENDED|PENDING|CANCELLED|NO_SHOW") String status,String appointmentId,@Min(1) Integer expectedAppointmentRevision){}
    public record CatalogItem(@NotBlank String id,@Min(0) int expectedRevision,@NotBlank @Size(max=160) String name,@Min(0) int value,@NotNull Boolean active){}
    @GetMapping("/catalogo/servicios") public Object services(HttpServletRequest req){access.roles("ADM","REC","PRO","ASI","AUD");return store.rows(req,SqlServerProcedure.MEDICAL_SERVICES);}
    @GetMapping("/catalogo/convenios") public Object agreements(HttpServletRequest req){access.roles("ADM","REC","PRO","ASI","AUD");return store.rows(req,SqlServerProcedure.MEDICAL_AGREEMENTS);}
    @PostMapping("/catalogo/{kind}") public Object catalog(@PathVariable String kind,@Valid @RequestBody CatalogItem p,HttpServletRequest req){access.write("CORE","ADM");Checks.id(p.id());String type=switch(kind){case "servicios"->"SERVICE";case "convenios"->"AGREEMENT";default->throw ApiException.missing();};if(type.equals("AGREEMENT")&&p.value()>100)throw ApiException.invalid("El descuento debe estar entre 0 y 100.");return store.one(req,SqlServerProcedure.MEDICAL_CATALOG_SAVE,p.id(),type,store.json(Map.of("expectedRevision",p.expectedRevision(),"name",p.name(),"value",p.value(),"active",p.active())));}
    @GetMapping("/pacientes/directorio") public Object directory(@RequestParam String dni,HttpServletRequest req){access.roles("ADM","REC","PRO","ASI");if(!dni.matches("[0-9]{3,8}"))throw ApiException.invalid("Escribe entre 3 y 8 dígitos de DNI.");return store.rows(req,SqlServerProcedure.PATIENT_DNI_DIRECTORY,dni);}
    @GetMapping("/pacientes/{id}/antecedentes") public Object antecedents(@PathVariable String id,HttpServletRequest req){access.roles("PRO","ASI","AUD");Checks.id(id);return store.rows(req,SqlServerProcedure.PATIENT_ANTECEDENTS,id);}
    @PostMapping("/pacientes/{id}/antecedentes") public Object antecedent(@PathVariable String id,@Valid @RequestBody Antecedent p,HttpServletRequest req){access.write("CORE","PRO");Checks.id(id);return store.one(req,SqlServerProcedure.PATIENT_ANTECEDENT_ADD,Checks.id(),id,store.json(p));}
    @GetMapping("/pacientes/{id}/consultas") public Object consultations(@PathVariable String id,HttpServletRequest req){access.roles("PRO","ASI","AUD");Checks.id(id);return store.rows(req,SqlServerProcedure.CONSULTATIONS_LIST,id);}
    @PostMapping("/consultas") public Object consultation(@Valid @RequestBody Consultation p,HttpServletRequest req){access.write("CORE","PRO");Checks.id(p.patientId());Checks.id(p.branchId());Checks.id(p.requestId());if((p.appointmentId()==null)!=(p.expectedAppointmentRevision()==null))throw ApiException.invalid("Cita y revisión deben indicarse juntas.");if(p.appointmentId()!=null)Checks.id(p.appointmentId());if(!p.branchId().equals(req.getAttribute("health.branch")))throw ApiException.forbidden();access.branch(p.branchId());return store.one(req,SqlServerProcedure.CONSULTATION_ADD,p.requestId(),store.json(p));}
}
