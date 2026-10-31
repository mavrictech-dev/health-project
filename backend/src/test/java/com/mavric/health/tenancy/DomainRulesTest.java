package com.mavric.health.tenancy;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import com.mavric.health.shared.ApiException;

class DomainRulesTest {
    @Test void validTenantIsResolvedFromOneSubdomain() { assertEquals("clinica-aurora",DomainRules.resolve("clinica-aurora.health.localhost","health.localhost").orElseThrow()); }
    @Test void platformHostsHaveNoTenant() { assertTrue(DomainRules.resolve("health.localhost","health.localhost").isEmpty()); assertTrue(DomainRules.resolve("admin.health.localhost","health.localhost").isEmpty()); }
    @Test void arbitraryHostsAndNestedNamesAreRejected() { for(String host:new String[]{"localhost","health.localhost.evil.test","evilhealth.localhost","one.two.health.localhost","api.health.localhost"}) assertThrows(ApiException.class,()->DomainRules.resolve(host,"health.localhost"),host); }
    @Test void reservedAndMalformedSlugsAreRejected() { for(String slug:new String[]{"admin","www","api","auth","portal","-clinic","clinic-","UPPER","two.parts","a".repeat(64)}) assertThrows(ApiException.class,()->DomainRules.slug(slug),slug); }
    @Test void urlUsesConfiguredDomainAndPort() { Settings settings=new Settings("health.localhost","http://health.localhost:8080",8,null); assertEquals("http://dr-mateo.health.localhost:8080",settings.tenantUrl("dr-mateo")); }
    @Test void publicOriginMustBelongToBaseDomain() { assertThrows(IllegalArgumentException.class,()->new Settings("health.localhost","http://different.test",8,null)); }
}
