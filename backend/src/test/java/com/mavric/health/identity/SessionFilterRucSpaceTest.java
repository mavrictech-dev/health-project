package com.mavric.health.identity;

import java.util.*;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.*;
import org.springframework.mock.web.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import com.mavric.health.persistence.sqlserver.SqlServerSecurityStore;
import com.mavric.health.shared.Errors;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SessionFilterRucSpaceTest {
    @AfterEach void clear(){SecurityContextHolder.clearContext();}
    @Test void exactPostIgnoresAnyPreviousCredentialWithoutSessionRpcOrCookie() throws Exception {
        for(String credential:List.of("old","A".repeat(43),"malformed bearer")) {
            var store=mock(SqlServerSecurityStore.class);var filter=new SessionFilter(store,new Errors(new ObjectMapper()));
            var req=new MockHttpServletRequest("POST","/api/public/tenant-space");var res=new MockHttpServletResponse();
            req.setCookies(new Cookie("health_session",credential));req.addHeader("Authorization",credential);
            req.setAttribute("health.actor","untrusted previous actor");
            SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken("old","ignored"));
            var called=new boolean[1];
            filter.doFilter(req,res,(request,response)->{called[0]=true;assertNull(req.getAttribute("health.actor"));assertNull(SecurityContextHolder.getContext().getAuthentication());});
            assertTrue(called[0]);assertEquals(200,res.getStatus());assertNull(res.getHeader("Set-Cookie"));verifyNoInteractions(store);
        }
    }
    @Test void neighboringUrisAndOtherMethodsDoNotReceiveAnonymousSkip() throws Exception {
        for(String[] target:List.of(new String[]{"GET","/api/public/tenant-space"},new String[]{"PUT","/api/public/tenant-space"},new String[]{"POST","/api/public/tenant-space/"},new String[]{"POST","/api/public/tenant-space/extra"})) {
            var store=mock(SqlServerSecurityStore.class);var filter=new SessionFilter(store,new Errors(new ObjectMapper()));
            var req=new MockHttpServletRequest(target[0],target[1]);var res=new MockHttpServletResponse();req.setCookies(new Cookie("health_session","malformed"));
            filter.doFilter(req,res,(request,response)->fail("Neighbor must process/reject the malformed session"));
            assertEquals(401,res.getStatus());assertNull(res.getHeader("Set-Cookie"));verifyNoInteractions(store);
        }
    }
    @Test void neighboringRequestWithWellFormedBearerStillChecksSession() throws Exception {
        var store=mock(SqlServerSecurityStore.class);var filter=new SessionFilter(store,new Errors(new ObjectMapper()));
        var req=new MockHttpServletRequest("GET","/api/public/tenant-space");var res=new MockHttpServletResponse();
        req.addHeader("Authorization","Bearer "+"A".repeat(43));when(store.resolveSession(eq(req),anyString())).thenReturn(Optional.empty());
        filter.doFilter(req,res,(request,response)->fail("Unknown session must be rejected"));assertEquals(401,res.getStatus());verify(store).resolveSession(eq(req),anyString());verifyNoMoreInteractions(store);
    }
}
