package com.mavric.health.documents.domain;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() { }
    public record Create(@NotBlank String patientId,String encounterId,@NotBlank @Size(max=200) String title,@NotBlank @Size(max=60) String type,@NotBlank @Size(max=100000) String content,String originalId) { }
    public record Change(@Min(1) int expectedRevision,@NotNull @Pattern(regexp="SAVE|SIGN|PUBLISH|WITHDRAW") String operation,@Size(max=100000) String content) { }
}
