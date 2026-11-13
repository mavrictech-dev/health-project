package com.mavric.health.identity;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import com.mavric.health.saas.api.PlatformController;
import com.mavric.health.saas.application.PlatformService;
import com.mavric.health.organization.application.OrganizationService;
import com.mavric.health.shared.*;
import tools.jackson.databind.ObjectMapper;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** DTO/error projection only; standalone MVC does not establish SAD authorization. */
class RucProfileControllerTest {
    @Test void closedProfileAndCasErrorsPreserveHttpMeaning() throws Exception {
        String id="00000000-0000-4000-8000-000000000001";var service=mock(PlatformService.class);
        var mvc=MockMvcBuilders.standaloneSetup(new PlatformController(service,mock(OrganizationService.class))).setControllerAdvice(new Errors.Advice(new Errors(new ObjectMapper()))).build();
        String body="{\"name\":\"Edited\",\"ruc\":\"00000000001\",\"timezone\":\"UTC\",\"expectedRevision\":7}";
        when(service.profile(eq(id),any())).thenThrow(new ApiException(409,"CONFLICT","El recurso cambio."));
        mvc.perform(put("/api/platform/tenants/"+id+"/profile").contentType("application/json").content(body)).andExpect(status().isConflict());clearInvocations(service);
        for(String bad:List.of(body.replace("7}","7.0}"),body.replace("\"00000000001\"","12345678901"),body.replace("7}","7,\"slug\":\"forged\"}"),body.replace("7}","7,\"expectedRevision\":8}")))mvc.perform(put("/api/platform/tenants/"+id+"/profile").contentType("application/json").content(bad)).andExpect(status().isBadRequest());
        verifyNoInteractions(service);
    }
}
