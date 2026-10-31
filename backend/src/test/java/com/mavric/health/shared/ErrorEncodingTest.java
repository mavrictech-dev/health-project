package com.mavric.health.shared;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.*;
import tools.jackson.databind.json.JsonMapper;
import static org.junit.jupiter.api.Assertions.*;
class ErrorEncodingTest {
    @Test void filterErrorsUseUtf8AndPreserveCorrelation() throws Exception {
        var request=new MockHttpServletRequest("GET","/api/monitor");request.setAttribute("health.requestId","known-request");var response=new MockHttpServletResponse();
        var mapper=JsonMapper.builder().build();new Errors(mapper).write(request,response,new ApiException(401,"UNAUTHENTICATED","Inicia sesión en este espacio."));
        assertEquals("UTF-8",response.getCharacterEncoding());var body=mapper.readTree(response.getContentAsByteArray());assertEquals("Inicia sesión en este espacio.",body.get("detail").asString());assertEquals("known-request",body.get("requestId").asString());
    }
}
