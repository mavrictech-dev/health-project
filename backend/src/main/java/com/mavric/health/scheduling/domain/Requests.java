package com.mavric.health.scheduling.domain;
import java.time.Instant;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() { }
    public record Reserve(@NotBlank String patientId,@NotBlank String branchId,@NotBlank String professionalId,@NotBlank String specialtyCode,@NotNull Instant startsAt,@NotNull Instant endsAt,@NotNull @Pattern(regexp="RESERVED|REQUESTED") String status,@NotBlank @Size(max=160) String service,@NotNull @Size(max=1000) String note) { }
    public record Change(@Min(1) int expectedRevision,@NotNull @Pattern(regexp="RESERVED|CONFIRMED|WAITING|CALLED|IN_CARE|COMPLETED|CANCELLED|WITHDRAWN") String status,Instant startsAt,Instant endsAt) { }
}
