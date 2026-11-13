package com.mavric.health.identity;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.shared.ApiException;
import static org.junit.jupiter.api.Assertions.*;

class BranchTokensTest {
    private final BranchTokens tokens=new BranchTokens(new ObjectMapper(),"synthetic-test-only-32-bytes-secret-value");
    private final Actor actor=new Actor("91000000-0000-4000-8000-000000000001","Synthetic","qa@example.test","92000000-0000-4000-8000-000000000001",List.of("PRO"),"a".repeat(64));
    private final String branch="93000000-0000-4000-8000-000000000001";
    @Test void signedScopeIncludesCurrentUserTenantBranchPermissionsAndRevocableSession(){var jwt=tokens.issue("A".repeat(43),actor,branch,Instant.now().plusSeconds(120));assertEquals(3,jwt.split("\\.").length);var claims=tokens.verify(jwt);assertEquals(actor.id(),claims.subject());assertEquals(actor.tenantId(),claims.tenantId());assertEquals(branch,claims.branchId());assertEquals(List.of("PRO"),claims.permissions());assertEquals("A".repeat(43),claims.sid());assertFalse(claims.toString().contains("AAAA"));}
    @Test void modifiedPayloadSignatureWrongKeyExpiredAndMalformedTokensAreRejected(){var jwt=tokens.issue("A".repeat(43),actor,branch,Instant.now().plusSeconds(120));assertThrows(ApiException.class,()->tokens.verify(jwt.substring(0,jwt.length()-5)+"abcde"));String[] parts=jwt.split("\\.");parts[1]=Base64.getUrlEncoder().withoutPadding().encodeToString("{\"permissions\":[\"SAD\"]}".getBytes());assertThrows(ApiException.class,()->tokens.verify(String.join(".",parts)));assertThrows(ApiException.class,()->new BranchTokens(new ObjectMapper(),"another-synthetic-32-byte-test-secret").verify(jwt));assertThrows(ApiException.class,()->tokens.verify(tokens.issue("A".repeat(43),actor,branch,Instant.now().minusSeconds(1))));for(String value:List.of("","opaque","a.b.c","none..","A".repeat(5000)))assertEquals(401,assertThrows(ApiException.class,()->tokens.verify(value)).status);}
    @Test void persistentKeyMustBeStrongAndStartupFallbackKeysAreIndependent(){assertThrows(IllegalArgumentException.class,()->new BranchTokens(new ObjectMapper(),"short"));var first=new BranchTokens(new ObjectMapper(),"");var second=new BranchTokens(new ObjectMapper(),"");assertThrows(ApiException.class,()->second.verify(first.issue("A".repeat(43),actor,branch,Instant.now().plusSeconds(120))));}
}
