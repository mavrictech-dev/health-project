package com.mavric.health.billing.domain;
import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() {}
    public record Post(@NotBlank String patientId,@NotNull @Pattern(regexp="CHARGE|PAYMENT|REFUND") String kind,@Min(1) @Max(1_000_000_000_000L) long amountMinor,@NotBlank @Size(max=200) String title,String parentId) { }
}
