package com.mavric.health.tenancy;
import java.util.List;
public record TenantRef(String id,String name,String slug,String kind,String domain,String status,List<String> modules) { }
