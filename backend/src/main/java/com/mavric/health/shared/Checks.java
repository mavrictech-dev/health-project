package com.mavric.health.shared;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;
import tools.jackson.databind.ObjectMapper;

public final class Checks {
    private Checks() { }
    public static String id() { return UUID.randomUUID().toString(); }
    public static String id(String value) { try { if(value==null || !UUID.fromString(value).toString().equals(value)) throw new IllegalArgumentException(); return value; } catch(IllegalArgumentException e) { throw ApiException.invalid("Identificador inválido."); } }
    public static String hash(String value) { try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8))); } catch(NoSuchAlgorithmException e) { throw new IllegalStateException(e); } }
    public static void password(String password) { if(password==null || password.length()<12 || password.getBytes(StandardCharsets.UTF_8).length>72) throw ApiException.invalid("La contraseña debe tener al menos 12 caracteres y como máximo 72 bytes."); }
    public static void json(Object value,ObjectMapper mapper) { if(mapper.writeValueAsString(value).length()>200_000) throw ApiException.invalid("La captura excede el tamaño permitido."); depth(value,0); }
    private static void depth(Object value,int level) { if(level>30) throw ApiException.invalid("La captura contiene demasiados niveles."); if(value instanceof Map<?,?> m) m.values().forEach(v->depth(v,level+1)); if(value instanceof Collection<?> c) c.forEach(v->depth(v,level+1)); }
    public static int limit(int limit) { return Math.max(1,Math.min(limit,200)); }
}
