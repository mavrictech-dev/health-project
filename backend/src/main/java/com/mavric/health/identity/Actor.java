package com.mavric.health.identity;
import java.util.List;
public record Actor(String id,String name,String email,String tenantId,List<String> roles,String tokenHash) { }
