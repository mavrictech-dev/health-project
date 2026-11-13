package com.mavric.health.identity;

import java.util.*;
import jakarta.validation.constraints.*;
import tools.jackson.core.*;
import tools.jackson.databind.*;
import tools.jackson.databind.annotation.JsonDeserialize;
import com.mavric.health.shared.Ruc;

/** Local root DTO decoders. Invitations/recovery keep their existing DTOs. */
public final class RucRequests {
    private RucRequests() {}
    @JsonDeserialize(using=LoginDecoder.class)
    public record Login(String ruc,@NotBlank @Email @Size(max=254) String email,@NotBlank @Size(max=128) String password) {
        @Override public String toString(){return "RucLogin[redacted]";}
    }
    @JsonDeserialize(using=SpaceDecoder.class)
    public record Space(@NotBlank @Pattern(regexp="[0-9]{11}") String ruc) {}
    @JsonDeserialize(using=ProfileDecoder.class)
    public record Profile(@NotBlank @Size(max=160) String name,@NotBlank @Pattern(regexp="[0-9]{11}") String ruc,
            @NotBlank @Size(max=64) String timezone,@NotNull @Min(1) Integer expectedRevision) {}
    public static final class Text extends ValueDeserializer<String> {
        @Override public String deserialize(JsonParser parser,DeserializationContext context){
            if(parser.currentToken()!=JsonToken.VALUE_STRING)return context.reportInputMismatch(String.class,"RUC textual requerido.");
            return Ruc.require(parser.getString());
        }
    }
    private static <T>T invalid(DeserializationContext c,Class<T> type){return c.reportInputMismatch(type,"Campos o tipos de solicitud no validos.");}
    private static Map<String,String> fields(JsonParser p,DeserializationContext c,Class<?> type,Set<String> allowed){
        if(p.currentToken()!=JsonToken.START_OBJECT)return c.reportInputMismatch(type,"Objeto requerido.");
        var values=new LinkedHashMap<String,String>();JsonToken token;
        while((token=p.nextToken())!=JsonToken.END_OBJECT){
            if(token!=JsonToken.PROPERTY_NAME)return c.reportInputMismatch(type,"Campo requerido.");
            String key=p.currentName();if(!allowed.contains(key)||values.containsKey(key))return c.reportInputMismatch(type,"Campo no permitido o repetido.");
            token=p.nextToken();
            if(key.equals("expectedRevision")){
                if(token!=JsonToken.VALUE_NUMBER_INT)return c.reportInputMismatch(type,"Revision entera requerida.");
                String lexical=p.getString();if(!lexical.matches("[1-9][0-9]{0,9}"))return c.reportInputMismatch(type,"Revision no valida.");
                try{Integer.parseInt(lexical);}catch(NumberFormatException rejected){return c.reportInputMismatch(type,"Revision no valida.");}
                values.put(key,lexical);
            }else{
                if(token!=JsonToken.VALUE_STRING)return c.reportInputMismatch(type,"Texto requerido.");values.put(key,p.getString());
            }
        }
        if(p.nextToken()!=null)return c.reportInputMismatch(type,"Una solicitud requerida.");return values;
    }
    public static final class LoginDecoder extends ValueDeserializer<Login>{
        @Override public Login getNullValue(DeserializationContext c){return invalid(c,Login.class);}
        @Override public Login deserialize(JsonParser p,DeserializationContext c){
            var v=fields(p,c,Login.class,Set.of("ruc","email","password"));
            if(!v.keySet().containsAll(Set.of("email","password")))return invalid(c,Login.class);
            if(v.containsKey("ruc"))Ruc.require(v.get("ruc"));return new Login(v.get("ruc"),v.get("email"),v.get("password"));
        }
    }
    public static final class SpaceDecoder extends ValueDeserializer<Space>{
        @Override public Space getNullValue(DeserializationContext c){return invalid(c,Space.class);}
        @Override public Space deserialize(JsonParser p,DeserializationContext c){var v=fields(p,c,Space.class,Set.of("ruc"));return new Space(Ruc.require(v.get("ruc")));}
    }
    public static final class ProfileDecoder extends ValueDeserializer<Profile>{
        @Override public Profile getNullValue(DeserializationContext c){return invalid(c,Profile.class);}
        @Override public Profile deserialize(JsonParser p,DeserializationContext c){
            var v=fields(p,c,Profile.class,Set.of("name","ruc","timezone","expectedRevision"));
            if(v.size()!=4)return invalid(c,Profile.class);
            return new Profile(v.get("name"),Ruc.require(v.get("ruc")),v.get("timezone"),Integer.valueOf(v.get("expectedRevision")));
        }
    }
}
