package com.mavric.healthcards;
import java.time.*;
import org.junit.jupiter.api.Test;
import com.mavric.health.shared.ApiException;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class AgendaControllerTest {
    private static final String BRANCH="93000000-0000-4000-8000-000000000001", APPOINTMENT="97000000-0000-4000-8000-000000000002";
    private static org.springframework.test.web.servlet.MockMvc mvc(com.mavric.health.identity.Access access,com.mavric.health.persistence.sqlserver.SqlServerCardsStore store){return org.springframework.test.web.servlet.setup.MockMvcBuilders.standaloneSetup(new AgendaController(access,store)).setControllerAdvice(new com.mavric.health.shared.Errors.Advice(new com.mavric.health.shared.Errors(new tools.jackson.databind.ObjectMapper()))).build();}
    @Test void calendarAllowsOnlyPositiveBoundedWindows(){var from=Instant.parse("2026-11-13T05:00:00Z");assertDoesNotThrow(()->AgendaController.window(from,from.plus(Duration.ofDays(7))));assertDoesNotThrow(()->AgendaController.window(from,from.plus(Duration.ofDays(8))));for(var end:new Instant[]{from,from.minusSeconds(1),from.plus(Duration.ofDays(8)).plusSeconds(1)})assertEquals(400,assertThrows(ApiException.class,()->AgendaController.window(from,end)).status);assertThrows(ApiException.class,()->AgendaController.window(null,from));}
    @Test void malformedAndMissingCalendarQueriesAreClientErrorsWithoutDataCalls()throws Exception{
        var access=mock(com.mavric.health.identity.Access.class);var store=mock(com.mavric.health.persistence.sqlserver.SqlServerCardsStore.class);
        var mvc=org.springframework.test.web.servlet.setup.MockMvcBuilders.standaloneSetup(new AgendaController(access,store)).setControllerAdvice(new com.mavric.health.shared.Errors.Advice(new com.mavric.health.shared.Errors(new tools.jackson.databind.ObjectMapper()))).build();
        mvc.perform(get("/api/v1/agenda/citas").param("branchId","93000000-0000-4000-8000-000000000001").param("from","not-a-date").param("to","2026-11-14T05:00:00Z")).andExpect(status().isBadRequest()).andExpect(jsonPath("$.title").value("INVALID_REQUEST"));
        mvc.perform(get("/api/v1/agenda/citas").param("from","2026-11-13T05:00:00Z").param("to","2026-11-14T05:00:00Z")).andExpect(status().isBadRequest());verifyNoInteractions(access,store);
    }
    @Test void collectionRequiresExplicitRevisionAndAmountBeforeAnyDataCall()throws Exception{
        var access=mock(com.mavric.health.identity.Access.class);var store=mock(com.mavric.health.persistence.sqlserver.SqlServerCardsStore.class);var mvc=mvc(access,store);
        String body="{\"branchId\":\""+BRANCH+"\",\"requestId\":\"98000000-0000-4000-8000-000000000001\",\"expectedRevision\":0,\"status\":\"PENDING\",\"amountMinor\":0,\"paymentMethod\":null}";
        for(String invalid:java.util.List.of(body.replace("\"expectedRevision\":0,",""),body.replace("\"amountMinor\":0,",""),body.replace("\"expectedRevision\":0","\"expectedRevision\":null"),body.replace("\"amountMinor\":0","\"amountMinor\":null")))mvc.perform(put("/api/v1/agenda/citas/"+APPOINTMENT+"/cobro").requestAttr("health.branch",BRANCH).contentType("application/json").content(invalid)).andExpect(status().isBadRequest());
        verifyNoInteractions(access,store);
    }
    @Test void selectedBranchAndRoleFailuresNeverReachAgendaData()throws Exception{
        var access=mock(com.mavric.health.identity.Access.class);var store=mock(com.mavric.health.persistence.sqlserver.SqlServerCardsStore.class);var mvc=mvc(access,store);
        mvc.perform(get("/api/v1/agenda/contexto").param("branchId",BRANCH).requestAttr("health.branch","93000000-0000-4000-8000-000000000002")).andExpect(status().isForbidden());verifyNoInteractions(store);
        doThrow(ApiException.forbidden()).when(access).roles("ADM","REC","PRO","ASI","AUD","CAJ");
        mvc.perform(get("/api/v1/agenda/contexto").param("branchId",BRANCH).requestAttr("health.branch",BRANCH)).andExpect(status().isForbidden());verifyNoInteractions(store);
    }
    @Test void collectionForwardsTheSameBoundRequestAndPreservesConflicts()throws Exception{
        var access=mock(com.mavric.health.identity.Access.class);var store=mock(com.mavric.health.persistence.sqlserver.SqlServerCardsStore.class);var mvc=mvc(access,store);
        String requestId="98000000-0000-4000-8000-000000000001",body="{\"branchId\":\""+BRANCH+"\",\"requestId\":\""+requestId+"\",\"expectedRevision\":2,\"status\":\"PAID\",\"amountMinor\":9550,\"paymentMethod\":\"YAPE\"}";
        var procedure=com.mavric.health.persistence.sqlserver.SqlServerProcedure.AGENDA_COLLECTION_SAVE;
        when(store.one(any(),eq(procedure),eq(APPOINTMENT),eq(BRANCH),eq(requestId),eq(2),eq("PAID"),eq(9550),eq("YAPE"))).thenReturn(java.util.Map.of("revision",3));
        for(int i=0;i<2;i++)mvc.perform(put("/api/v1/agenda/citas/"+APPOINTMENT+"/cobro").requestAttr("health.branch",BRANCH).contentType("application/json").content(body)).andExpect(status().isOk()).andExpect(jsonPath("$.revision").value(3));
        verify(access,times(2)).write("CORE","ADM","REC","CAJ");
        verify(store,times(2)).one(any(),eq(procedure),eq(APPOINTMENT),eq(BRANCH),eq(requestId),eq(2),eq("PAID"),eq(9550),eq("YAPE"));
        when(store.one(any(),eq(procedure),eq(APPOINTMENT),eq(BRANCH),eq(requestId),eq(2),eq("PAID"),eq(9550),eq("YAPE"))).thenThrow(new ApiException(409,"CONFLICT","Cobro modificado."));
        mvc.perform(put("/api/v1/agenda/citas/"+APPOINTMENT+"/cobro").requestAttr("health.branch",BRANCH).contentType("application/json").content(body)).andExpect(status().isConflict());
    }
}
