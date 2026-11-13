package com.mavric.health.patients.domain;

import java.util.*;
import tools.jackson.core.*;
import tools.jackson.databind.*;
import com.mavric.health.patients.domain.Requests.Link;

/** Root Link command only: inspect raw tokens before any map/tree coercion. */
public final class LinkDeserializer extends ValueDeserializer<Link> {
    private static <T>T invalid(DeserializationContext context) { return context.reportInputMismatch(Link.class,"Formato de comando de vinculo no valido."); }
    @Override public Link getNullValue(DeserializationContext context) { return invalid(context); }
    @Override public Link deserialize(JsonParser parser,DeserializationContext context) {
        if(parser.currentToken()!=JsonToken.START_OBJECT)return invalid(context);
        var fields=new HashSet<String>();
        String user=null,relationship=null;Integer revision=null;Boolean active=null;List<String> scopes=null;
        JsonToken token;
        while((token=parser.nextToken())!=JsonToken.END_OBJECT) {
            if(token!=JsonToken.PROPERTY_NAME)return invalid(context);
            String key=parser.currentName();
            if(!fields.add(key))return invalid(context);
            token=parser.nextToken();
            if(token==null)return invalid(context);
            switch(key) {
                case "userId" -> { if(token!=JsonToken.VALUE_STRING)return invalid(context);user=parser.getString(); }
                case "relationship" -> { if(token!=JsonToken.VALUE_STRING)return invalid(context);relationship=parser.getString(); }
                case "active" -> { if(token!=JsonToken.VALUE_TRUE && token!=JsonToken.VALUE_FALSE)return invalid(context);active=token==JsonToken.VALUE_TRUE; }
                case "expectedRevision" -> {
                    if(token!=JsonToken.VALUE_NUMBER_INT)return invalid(context);
                    String lexical=parser.getString();
                    if(!lexical.matches("0|[1-9][0-9]{0,9}"))return invalid(context);
                    try { revision=Integer.valueOf(lexical); } catch(NumberFormatException rejected) { return invalid(context); }
                }
                case "scopes" -> {
                    if(token!=JsonToken.START_ARRAY)return invalid(context);
                    scopes=new ArrayList<>();
                    while((token=parser.nextToken())!=JsonToken.END_ARRAY) {
                        if(token!=JsonToken.VALUE_STRING)return invalid(context);
                        scopes.add(parser.getString());
                    }
                }
                default -> { return invalid(context); }
            }
        }
        Set<String> expected=Boolean.TRUE.equals(active)?Set.of("userId","expectedRevision","relationship","active","scopes"):Set.of("userId","expectedRevision","active");
        var value=new Link(user,revision,relationship,active,scopes);
        if(!fields.equals(expected) || !value.valid() || parser.nextToken()!=null)return invalid(context);
        return value;
    }
}
