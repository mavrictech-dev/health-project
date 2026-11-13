package com.mavric.healthcards;
import java.time.*;
import org.junit.jupiter.api.Test;
import com.mavric.health.shared.ApiException;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class AgendaControllerTest {
    @Test void calendarAllowsOnlyPositiveBoundedWindows(){var from=Instant.parse("2026-11-13T05:00:00Z");assertDoesNotThrow(()->AgendaController.window(from,from.plus(Duration.ofDays(7))));assertDoesNotThrow(()->AgendaController.window(from,from.plus(Duration.ofDays(8))));for(var end:new Instant[]{from,from.minusSeconds(1),from.plus(Duration.ofDays(8)).plusSeconds(1)})assertEquals(400,assertThrows(ApiException.class,()->AgendaController.window(from,end)).status);assertThrows(ApiException.class,()->AgendaController.window(null,from));}
    @Test void malformedAndMissingCalendarQueriesAreClientErrorsWithoutDataCalls()throws Exception{
        var access=mock(com.mavric.health.identity.Access.class);var store=mock(com.mavric.health.persistence.sqlserver.SqlServerCardsStore.class);
        var mvc=org.springframework.test.web.servlet.setup.MockMvcBuilders.standaloneSetup(new AgendaController(access,store)).setControllerAdvice(new com.mavric.health.shared.Errors.Advice(new com.mavric.health.shared.Errors(new tools.jackson.databind.ObjectMapper()))).build();
        mvc.perform(get("/api/v1/agenda/citas").param("branchId","93000000-0000-4000-8000-000000000001").param("from","not-a-date").param("to","2026-11-14T05:00:00Z")).andExpect(status().isBadRequest()).andExpect(jsonPath("$.title").value("INVALID_REQUEST"));
        mvc.perform(get("/api/v1/agenda/citas").param("from","2026-11-13T05:00:00Z").param("to","2026-11-14T05:00:00Z")).andExpect(status().isBadRequest());verifyNoInteractions(access,store);
    }
}
