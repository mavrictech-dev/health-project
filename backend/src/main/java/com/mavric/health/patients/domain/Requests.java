package com.mavric.health.patients.domain;
import java.time.LocalDate;
import java.util.*;
import jakarta.validation.constraints.*;
public final class Requests {
    private Requests() { }
    public record Patient(@NotBlank @Size(max=160) String name,@NotNull @Pattern(regexp="HUMAN|ANIMAL") String domain,@NotBlank @Size(max=100) String identifier,@PastOrPresent LocalDate birthDate,@Size(max=80) String species,@NotNull Map<String,Object> contact,@NotNull Set<@Size(max=160) String> allergies) { }
    public record Edit(@Min(1) int expectedRevision,@jakarta.validation.Valid @NotNull Patient patient) { }
    @tools.jackson.databind.annotation.JsonDeserialize(using=LinkDeserializer.class)
    public record Link(String userId,Integer expectedRevision,String relationship,Boolean active,List<String> scopes) {
        public Link { if(scopes!=null)scopes=Collections.unmodifiableList(new ArrayList<>(scopes)); }
        public boolean valid() {
            if(!linkId(userId) || expectedRevision==null || expectedRevision<0 || active==null)return false;
            if(!active)return relationship==null && scopes==null;
            if(relationship==null || relationship.length()>80 || relationship.chars().allMatch(Requests::linkSpace) || scopes==null || scopes.isEmpty())return false;
            var seen=new HashSet<String>();
            for(Object value:scopes)if(!(value instanceof String scope) || !Set.of("APPOINTMENTS","DOCUMENTS","BILLING").contains(scope) || !seen.add(scope))return false;
            return true;
        }
    }
    public static boolean linkId(String value) { return value!=null && value.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"); }
    // Exact whitespace whitelist in V14; validation never trims the stored value.
    private static boolean linkSpace(int c) { return c==32 || c>=9&&c<=13 || c==160 || c==5760 || c>=8192&&c<=8202 || c==8232 || c==8233 || c==8239 || c==8287 || c==12288; }
}
