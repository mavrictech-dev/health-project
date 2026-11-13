package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import com.mavric.health.shared.Errors;
import com.mavric.health.tenancy.Settings;
import tools.jackson.databind.ObjectMapper;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class RucAuthControllerTest {
    @Test void resolverAcceptsOnlyRucAndReturnsOnlyHostnameWithoutCookie() throws Exception {
        var service=mock(IdentityService.class);when(service.tenantSpace(eq("00000000001"),any())).thenReturn(Map.of("hostname","clinic.health.localhost"));
        var mvc=MockMvcBuilders.standaloneSetup(new AuthController(service,mock(Access.class),new Settings("health.localhost","https://health.localhost",8,null))).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).build();
        mvc.perform(post("/api/public/tenant-space").contentType("application/json").content("{\"ruc\":\"00000000001\"}")).andExpect(status().isOk()).andExpect(content().json("{\"hostname\":\"clinic.health.localhost\"}")).andExpect(header().doesNotExist("Set-Cookie"));
        clearInvocations(service);
        for(String json:List.of("{\"ruc\":12345678901}","{}","{\"ruc\":\"00000000001\",\"password\":\"CANARY\"}","{\"ruc\":\"00000000001\",\"ruc\":\"00000000002\"}"))mvc.perform(post("/api/public/tenant-space").contentType("application/json").content(json)).andExpect(status().isBadRequest()).andExpect(header().doesNotExist("Set-Cookie"));
        verifyNoInteractions(service);
    }
    @Test void loginRejectsNumericRucExtraOrDuplicatedFieldsBeforeService() throws Exception {
        var service=mock(IdentityService.class);var mvc=MockMvcBuilders.standaloneSetup(new AuthController(service,mock(Access.class),new Settings("health.localhost","https://health.localhost",8,null))).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).build();
        for(String extra:List.of("\"ruc\":12345678901,","\"ruc\":\"00000000001\",\"tenantId\":\"forged\",","\"ruc\":\"00000000001\",\"ruc\":\"00000000002\","))mvc.perform(post("/api/auth/login").contentType("application/json").content("{"+extra+"\"email\":\"qa@example.test\",\"password\":\"CANARY\"}")).andExpect(status().isBadRequest()).andExpect(header().doesNotExist("Set-Cookie"));verifyNoInteractions(service);
    }
}
