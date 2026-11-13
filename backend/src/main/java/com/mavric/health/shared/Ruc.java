package com.mavric.health.shared;

/** Local format only; never claims tax authority verification or converts to a number. */
public final class Ruc {
    private Ruc() {}
    public static boolean valid(String value){return value!=null && value.matches("[0-9]{11}");}
    public static String require(String value){if(!valid(value))throw ApiException.invalid("RUC de 11 digitos ASCII requerido.");return value;}
}
