package com.mavric.health.shared;
public final class Idempotency {
    private Idempotency() { }
    public static String key(String key) { if(key==null || !key.matches("[A-Za-z0-9_.:-]{8,100}")) throw ApiException.invalid("Envía Idempotency-Key de 8 a 100 caracteres."); return key; }
}
