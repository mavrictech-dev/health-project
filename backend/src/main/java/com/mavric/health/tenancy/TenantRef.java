package com.mavric.health.tenancy;
import java.util.List;
public record TenantRef(String id,String name,String slug,String kind,String domain,String status,List<String> modules,String ruc,int revision) {
    public TenantRef(String id,String name,String slug,String kind,String domain,String status,List<String> modules){this(id,name,slug,kind,domain,status,modules,null,0);}
}
