package com.mavric.health.hospital.domain;
import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() {}
    public record Resource(@NotBlank String branchId,@NotBlank @Size(max=100) String name,@NotNull @Pattern(regexp="BED|CAGE") String kind) { }
    public record Admission(@NotBlank String patientId,@NotBlank String resourceId,@NotBlank @Size(max=1000) String reason) { }
    public record Revision(@Min(1) int expectedRevision) { }
}
