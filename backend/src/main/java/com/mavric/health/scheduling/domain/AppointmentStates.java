package com.mavric.health.scheduling.domain;
import java.util.*;
import com.mavric.health.shared.ApiException;
public final class AppointmentStates {
    private static final Map<String,Set<String>> NEXT=Map.of("REQUESTED",Set.of("RESERVED","CANCELLED"),"RESERVED",Set.of("RESERVED","CONFIRMED","CANCELLED"),"CONFIRMED",Set.of("RESERVED","WAITING","CANCELLED"),"WAITING",Set.of("CALLED","WITHDRAWN"),"CALLED",Set.of("IN_CARE","WAITING","WITHDRAWN"),"IN_CARE",Set.of("COMPLETED"));
    private AppointmentStates() { }
    public static void check(String from,String to) { if(!NEXT.getOrDefault(from,Set.of()).contains(to)) throw new ApiException(409,"INVALID_TRANSITION","Transición de cita no permitida."); }
}
