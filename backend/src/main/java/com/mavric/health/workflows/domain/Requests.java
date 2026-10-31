package com.mavric.health.workflows.domain;
import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() {}
    public record Create(@NotBlank String type,@NotBlank String branchId,String patientId,@NotBlank @Size(max=200) String title,@NotNull Map<String,Object> payload) { }
    public record Step(@Min(1) int expectedRevision,@NotBlank @Size(max=40) String status,@NotNull Map<String,Object> payload) { }
}
