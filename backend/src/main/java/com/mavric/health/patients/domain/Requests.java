package com.mavric.health.patients.domain;
import java.time.LocalDate;
import java.util.*;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() { }
    public record Patient(@NotBlank @Size(max=160) String name,@NotNull @Pattern(regexp="HUMAN|ANIMAL") String domain,@NotBlank @Size(max=100) String identifier,@PastOrPresent LocalDate birthDate,@Size(max=80) String species,@NotNull Map<String,Object> contact,@NotNull Set<@Size(max=160) String> allergies) { }
    public record Edit(@Min(1) int expectedRevision,@jakarta.validation.Valid @NotNull Patient patient) { }
    public record Link(@NotBlank String userId,@NotBlank @Size(max=80) String relationship,boolean active,@NotEmpty Set<String> scopes) { }
}
