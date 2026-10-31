package com.mavric.health.inventory.domain;
import java.util.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() {}
    public record Lot(@NotBlank String branchId,@NotBlank @Size(max=160) String name,@NotBlank @Size(max=100) String lot,@NotNull LocalDate expiry,@NotBlank @Size(max=30) String unit) { }
    public record Move(@NotBlank String lotId,@NotNull @Pattern(regexp="RECEIVE|DISPENSE") String kind,@NotNull @DecimalMin("0.001") @Digits(integer=11,fraction=3) BigDecimal quantity,String patientId,String prescriptionId) { }
    public record Transfer(@NotBlank String lotId,@NotBlank String destinationBranchId,@NotNull @DecimalMin("0.001") @Digits(integer=11,fraction=3) BigDecimal quantity) { }
}
