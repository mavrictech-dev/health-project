package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.shared.Ruc;
import static org.junit.jupiter.api.Assertions.*;

class RucRequestsTest {
    final ObjectMapper mapper=new ObjectMapper();
    @Test void formatIsTextualExactlyElevenAsciiDigitsWithoutTaxVerification(){
        assertTrue(Ruc.valid("00000000001"));
        for(String bad:Arrays.asList(null,"","0000000001","000000000001"," 00000000001","00000000001 ","+00000000001","0000000000-","００００００００００１","٠٠٠٠٠٠٠٠٠٠١","1e0000000000"))assertFalse(Ruc.valid(bad));
    }
    @Test void loginAndResolverAreClosedAndDoNotCoerceOrCarryPasswordsToResolution(){
        var value=mapper.readValue("{\"ruc\":\"00000000001\",\"email\":\"qa@example.test\",\"password\":\" leading 🦷 trailing \"}",RucRequests.Login.class);
        assertEquals(" leading 🦷 trailing ",value.password());assertFalse(value.toString().contains("leading"));
        assertNull(mapper.readValue("{\"email\":\"qa@example.test\",\"password\":\"p\"}",RucRequests.Login.class).ruc());
        for(String json:List.of("{\"ruc\":12345678901}","{\"ruc\":null}","{\"ruc\":\"00000000001\",\"password\":\"canary\"}","{\"ruc\":\"00000000001\",\"ruc\":\"00000000002\"}","{\"RUC\":\"00000000001\"}","{}","{\"ruc\":\"00000000001\"} {}"))assertThrows(RuntimeException.class,()->mapper.readValue(json,RucRequests.Space.class));
    }
    @Test void profileRequiresFourExactFieldsAndPositiveLexicalInteger(){
        String prefix="{\"name\":\"Name\",\"ruc\":\"00000000001\",\"timezone\":\"UTC\",\"expectedRevision\":";
        assertEquals(2147483647,mapper.readValue(prefix+"2147483647}",RucRequests.Profile.class).expectedRevision());
        for(String token:List.of("0","-0","-1","1.0","1e0","\"1\"","true","null","2147483648"))assertThrows(RuntimeException.class,()->mapper.readValue(prefix+token+"}",RucRequests.Profile.class));
        for(String extra:List.of(",\"slug\":\"new\"",",\"expectedRevision\":2",",\"ownerUserId\":\"canary\""))assertThrows(RuntimeException.class,()->mapper.readValue(prefix+"1"+extra+"}",RucRequests.Profile.class));
    }
    @Test void sharedRegisterRucRemainsOptionalForPortalButNumericInputNeverBecomesText(){
        String prefix="{\"name\":\"Synthetic\",\"email\":\"qa@example.test\",\"password\":\"SyntheticPassword123!\",\"acceptTerms\":true";
        assertNull(mapper.readValue(prefix+"}",AccountLifecycleService.Register.class).ruc());
        assertEquals("00000000001",mapper.readValue(prefix+",\"ruc\":\"00000000001\"}",AccountLifecycleService.Register.class).ruc());
        assertThrows(RuntimeException.class,()->mapper.readValue(prefix+",\"ruc\":12345678901}",AccountLifecycleService.Register.class));
    }
}
