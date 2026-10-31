package com.mavric.health.saas.domain;

import java.util.Set;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import com.mavric.health.identity.IdentityService.UserInput;

public final class Requests {
    private Requests() { }
    public record Plan(@NotBlank @Size(max=100) String name,@NotNull @Size(max=500) String description,@NotNull @Pattern(regexp="DRAFT|PUBLISHED|ARCHIVED") String status,
        @Min(0) @Max(1_000_000_000_000L) long baseMinor,@Min(0) @Max(1_000_000_000_000L) long branchMinor,@Min(0) @Max(1_000_000_000_000L) long professionalMinor,
        @Min(1) int includedBranches,@Min(1) int includedProfessionals,@Min(1) int includedSpecialties,@Min(1) @Max(10000) int maxBranches,@Min(1) @Max(100000) int maxProfessionals,@Min(1) @Max(241) int maxSpecialties,@Min(0) @Max(60) int annualDiscount,
        @NotEmpty Set<String> kinds,@NotEmpty Set<String> domains,@NotEmpty Set<String> modules) { }
    public record Subscription(@NotBlank String planId,@NotNull @Pattern(regexp="MONTHLY|YEARLY") String cycle,@Min(1) int branchQuota,@Min(1) int professionalQuota,@Min(1) int specialtyQuota) { }
    public record Tenant(@NotBlank @Size(max=160) String name,@NotBlank String slug,@NotNull @Pattern(regexp="DOCTOR|CLINIC|HOSPITAL|VETERINARY|DENTAL|SPECIALTY_CENTER") String kind,@NotNull @Pattern(regexp="HUMAN|ANIMAL") String domain,
        String ownerUserId,@Valid UserInput owner,@NotBlank String timezone,@NotBlank @Size(max=160) String branchName,@NotNull @Size(max=300) String address,@NotEmpty Set<String> specialties,@NotNull @Valid Subscription subscription) { }
    public record Status(@NotNull @Pattern(regexp="TRIAL|ACTIVE|SUSPENDED|CANCELLED") String status,@NotBlank @Size(max=500) String reason) { }
}
