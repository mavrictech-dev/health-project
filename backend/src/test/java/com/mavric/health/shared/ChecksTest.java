package com.mavric.health.shared;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
class ChecksTest {
    @Test void uuidMustHaveCanonicalForm() { assertEquals("00000000-0000-0000-0000-000000000001",Checks.id("00000000-0000-0000-0000-000000000001")); assertThrows(ApiException.class,()->Checks.id("1-1-1-1-1")); }
    @Test void passwordLengthUsesBytesForBcrypt() { assertDoesNotThrow(()->Checks.password("UnPasswordDePrueba2026")); assertThrows(ApiException.class,()->Checks.password("corta")); assertThrows(ApiException.class,()->Checks.password("é".repeat(37))); }
    @Test void tokensAreHashedDeterministically() { assertEquals(64,Checks.hash("example").length()); assertEquals(Checks.hash("example"),Checks.hash("example")); assertNotEquals(Checks.hash("example"),Checks.hash("other")); }
}
