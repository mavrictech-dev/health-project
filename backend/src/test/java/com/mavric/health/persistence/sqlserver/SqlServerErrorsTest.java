package com.mavric.health.persistence.sqlserver;

import java.sql.SQLException;
import java.time.Duration;
import java.util.stream.Stream;
import com.mavric.health.shared.ApiException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SqlServerErrorsTest {
    static Stream<Arguments> codes() {
        return Stream.of(Arguments.of(51000,400,"INVALID"),Arguments.of(51001,403,"FORBIDDEN"),
                Arguments.of(51002,404,"NOT_FOUND"),Arguments.of(51003,409,"CONFLICT"),
                Arguments.of(51004,403,"SUSPENDED"),Arguments.of(51005,409,"APPLICATION_READ_ONLY"),
                Arguments.of(1205,409,"CONCURRENT_CHANGE"),Arguments.of(2601,409,"DATA_CONFLICT"),
                Arguments.of(2627,409,"DATA_CONFLICT"),Arguments.of(547,409,"DATA_CONFLICT"),
                Arguments.of(229,500,"DATABASE_ERROR"),Arguments.of(1062,500,"DATABASE_ERROR"),
                Arguments.of(0,500,"DATABASE_ERROR"));
    }

    @ParameterizedTest @MethodSource("codes")
    void vendorNumbersHaveControlledDetails(int vendor,int status,String code) {
        ApiException error=SqlServerErrors.map(new SQLException("password=private; SELECT secret", "45000", vendor));
        assertEquals(status,error.status); assertEquals(code,error.code);
        assertFalse(error.toString().contains("private")); assertFalse(error.toString().contains("SELECT"));
        assertNull(error.getCause()); assertEquals(0,error.getSuppressed().length);
    }

    @Test void traversesWrappersAndNextExceptionsWithoutDriverMessages() {
        SQLException wrapper=new SQLException("token=private", "S0001",0);
        wrapper.setNextException(new SQLException("private nested constraint",null,2627));
        ApiException mapped=SqlServerErrors.map(new IllegalStateException("private wrapper",wrapper));
        assertEquals("DATA_CONFLICT",mapped.code); assertFalse(mapped.toString().contains("private"));
    }

    @Test void cyclesTerminateAndStillFindLaterVendorCode() {
        SQLException a=mock(SQLException.class),b=mock(SQLException.class);
        when(a.getNextException()).thenReturn(a); when(a.getCause()).thenReturn(b);
        when(b.getNextException()).thenReturn(a); when(b.getErrorCode()).thenReturn(51002);
        assertTimeoutPreemptively(Duration.ofSeconds(2),()->assertEquals("NOT_FOUND",SqlServerErrors.map(a).code));
    }

    @Test void unknownCyclicGraphAndNullAreSafeDatabaseErrors() {
        SQLException loop=mock(SQLException.class);
        when(loop.getCause()).thenReturn(loop); when(loop.getNextException()).thenReturn(loop);
        assertTimeoutPreemptively(Duration.ofSeconds(2),()->assertEquals(500,SqlServerErrors.map(loop).status));
        assertEquals("DATABASE_ERROR",SqlServerErrors.map(null).code);
    }

    @Test void grantDenialIsNotReclassifiedByLaterBusinessPermissionException() {
        SQLException permission=new SQLException("private grant detail",null,229);
        permission.setNextException(new SQLException("private HTTP role detail",null,51001));
        assertEquals(500,SqlServerErrors.map(permission).status);
    }
}
