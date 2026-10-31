package com.mavric.health.organization.domain;
import java.util.Set;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import com.mavric.health.identity.IdentityService.UserInput;
public final class Requests {
    private Requests() { }
    public record Branch(@NotBlank @Size(max=160) String name,@NotNull @Size(max=300) String address,boolean external,boolean active) { }
    public record Area(@NotBlank String branchId,@NotBlank @Size(max=160) String name,@NotEmpty Set<String> specialties) { }
    public record Specialties(@NotEmpty Set<String> specialties) { }
    public record Member(String userId,@Valid UserInput user,@NotEmpty Set<String> roles,@NotNull @Pattern(regexp="ACTIVE|INVITED|INACTIVE") String status,@NotEmpty Set<String> branches,@NotNull Set<String> specialties) { }
}
