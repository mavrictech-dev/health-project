package com.mavric.health.clinical.domain;
import java.util.Map;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() { }
    public record Start(@NotBlank String patientId,@NotBlank String branchId,@NotBlank String specialtyCode) { }
    public record Note(@Min(1) int expectedRevision,@NotNull @Size(max=100000) String note) { }
    public record Revision(@Min(1) int expectedRevision) { }
    public record Entry(@NotNull @Pattern(regexp="EVALUATION|OBSERVATION|ANNOTATION|ORDER|PRESCRIPTION") String kind,@NotNull Map<String,Object> payload) { }
}
