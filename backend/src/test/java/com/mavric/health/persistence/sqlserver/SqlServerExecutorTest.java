package com.mavric.health.persistence.sqlserver;

import java.math.*;
import java.sql.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import com.microsoft.sqlserver.jdbc.SQLServerConnection;
import com.zaxxer.hikari.HikariDataSource;
import com.mavric.health.shared.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.ConnectionHolder;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/** JDBC doubles only: no SQL Server connection, migrations, Spring application or network. */
class SqlServerExecutorTest {
    private static final String CONTEXT="{call dbo.usp_request_context(?,?,?,?,?,?,?,?,?,?)}";
    private static final String ID="00000000-0000-4000-8000-000000000001";
    private final ObjectMapper mapper=new ObjectMapper();

    final class Fixture {
        final DataSource ds;
        final Connection connection=mock(Connection.class);
        final Deque<CallableStatement> queue=new ArrayDeque<>();
        final List<String> calls=new ArrayList<>();
        final SqlServerExecutor executor;
        Fixture() throws SQLException { this(mock(DataSource.class),SqlServerExecutor.Purpose.RUNTIME); }
        Fixture(DataSource ds,SqlServerExecutor.Purpose purpose) throws SQLException {
            this.ds=ds; when(ds.getConnection()).thenReturn(connection);
            when(connection.prepareCall(anyString())).thenAnswer(inv->{calls.add(inv.getArgument(0));return queue.removeFirst();});
            executor=new SqlServerExecutor(new JdbcTemplate(ds),mapper,purpose);
        }
        void add(CallableStatement... statements) { queue.addAll(Arrays.asList(statements)); }
        void noTransactionControl() throws SQLException {
            verify(connection,never()).commit(); verify(connection,never()).rollback();
            verify(connection,never()).setAutoCommit(anyBoolean()); verify(connection,never()).getMetaData();
        }
    }

    private CallableStatement sequence(Object... events) throws SQLException {
        CallableStatement statement=mock(CallableStatement.class);
        AtomicInteger position=new AtomicInteger();
        when(statement.execute()).thenAnswer(i->events.length>0 && events[0] instanceof ResultSet);
        when(statement.getResultSet()).thenAnswer(i->(ResultSet)events[position.get()]);
        when(statement.getUpdateCount()).thenAnswer(i->position.get()<events.length && events[position.get()] instanceof Integer n?n:-1);
        when(statement.getMoreResults(Statement.CLOSE_CURRENT_RESULT)).thenAnswer(i->{
            int next=position.incrementAndGet();return next<events.length && events[next] instanceof ResultSet;
        });
        return statement;
    }

    private ResultSet rows(String[] labels,int[] types,Object[]... data) throws SQLException {
        ResultSet rs=mock(ResultSet.class); ResultSetMetaData metadata=mock(ResultSetMetaData.class);
        when(rs.getMetaData()).thenReturn(metadata); when(metadata.getColumnCount()).thenReturn(labels.length);
        for(int i=0;i<labels.length;i++) { when(metadata.getColumnLabel(i+1)).thenReturn(labels[i]);when(metadata.getColumnType(i+1)).thenReturn(types[i]); }
        AtomicInteger row=new AtomicInteger(-1);
        when(rs.next()).thenAnswer(i->row.incrementAndGet()<data.length);
        when(rs.getObject(anyInt())).thenAnswer(i->data[row.get()][(int)i.getArgument(0)-1]);
        when(rs.getTimestamp(anyInt(),any(Calendar.class))).thenAnswer(i->data[row.get()][(int)i.getArgument(0)-1]);
        when(rs.getDate(anyInt(),any(Calendar.class))).thenAnswer(i->data[row.get()][(int)i.getArgument(0)-1]);
        return rs;
    }

    @Test void consumesInterleavedCountsZeroAndEmptySetsUntilFinalMinusOne() throws Exception {
        Fixture f=new Fixture(); CallableStatement before=sequence(0),after=sequence();
        ResultSet empty=rows(new String[]{"id"},new int[]{Types.INTEGER});
        ResultSet value=rows(new String[]{"tenant_id"},new int[]{Types.CHAR},new Object[]{ID});
        CallableStatement call=sequence(0,empty,7,value,0);
        f.add(before,call,after);
        var result=f.executor.execute(SqlServerProcedure.ORGANIZATION_CONFIGURATION,SqlServerContext.empty(),ID);
        assertEquals(2,result.resultSets().size()); assertTrue(result.resultSets().get(0).isEmpty());
        assertEquals(ID,result.resultSets().get(1).get(0).get("tenantId")); assertEquals(List.of(0,7,0),result.updateCounts());
        verify(empty).close();verify(value).close();verify(call).close();verify(before).close();verify(after).close();
        verify(f.ds,times(1)).getConnection(); f.noTransactionControl();
    }

    @Test void preservesOrganizationEightAndSupportTwoResultsets() throws Exception {
        for (SqlServerProcedure p:List.of(SqlServerProcedure.ORGANIZATION_CONFIGURATION,SqlServerProcedure.SUPPORT_DETAIL)) {
            Fixture f=new Fixture(); int expected=p==SqlServerProcedure.SUPPORT_DETAIL?2:8;
            Object[] sets=new Object[expected];for(int i=0;i<expected;i++)sets[i]=rows(new String[]{"id"},new int[]{Types.CHAR});
            f.add(sequence(),sequence(sets),sequence());
            assertEquals(expected,f.executor.execute(p,SqlServerContext.empty(),ID).resultSets().size());
            f.noTransactionControl();
        }
    }

    @Test void preservesUnicodeLongJsonNullEmptyAndExactNumbersWithoutParsingCredentials() throws Exception {
        Fixture f=new Fixture(); String text="\u00c1\u4e2d\ud83e\uddb7".repeat(2400),json=mapper.writeValueAsString(Map.of("text",text));
        BigDecimal amount=new BigDecimal("99999999999999999999999999999999999.123");
        BigInteger integer=new BigInteger("99999999999999999999999999999999999999");
        ResultSet rs=rows(new String[]{"profile_snapshot","password_hash","nullable_value","empty_value","amount_minor","large_integer","active","roles"},
                new int[]{Types.NVARCHAR,Types.NVARCHAR,Types.NVARCHAR,Types.VARCHAR,Types.DECIMAL,Types.NUMERIC,Types.BIT,Types.NVARCHAR},
                new Object[]{json,"synthetic-not-json[credential]",null,"",amount,integer,true,"[\"ADM\"]"});
        f.add(sequence(),sequence(rs),sequence());
        var result=f.executor.execute(SqlServerProcedure.IDENTITY_CREDENTIALS,SqlServerContext.empty(),"qa@example.test");
        Map<String,Object> row=result.resultSets().get(0).get(0);
        assertEquals(text,((Map<?,?>)row.get("profileSnapshot")).get("text"));
        assertEquals("synthetic-not-json[credential]",row.get("passwordHash")); assertTrue(row.containsKey("nullableValue"));
        assertNull(row.get("nullableValue"));assertEquals("",row.get("emptyValue"));assertSame(amount,row.get("amountMinor"));
        assertSame(integer,row.get("largeInteger"));assertEquals(true,row.get("active"));assertEquals(List.of("ADM"),row.get("roles"));
        assertFalse(result.toString().contains("credential"));
        assertThrows(UnsupportedOperationException.class,()->row.put("other",1));
    }

    @Test void utcTemporalReadsAndMicrosecondBindingIgnoreJvmTimezone() throws Exception {
        TimeZone original=TimeZone.getDefault();
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("America/Los_Angeles"));
            Fixture f=new Fixture(); Instant instant=Instant.parse("2026-01-02T12:34:56.123456789Z");
            Timestamp stamp=Timestamp.from(Instant.parse("2026-01-02T12:34:56.123456Z"));
            java.sql.Date day=new java.sql.Date(Instant.parse("2026-01-02T00:00:00Z").toEpochMilli());
            ResultSet rs=rows(new String[]{"expires_at","renewal_date","local_value"},new int[]{Types.TIMESTAMP,Types.DATE,Types.OTHER},
                    new Object[]{stamp,day,LocalDateTime.of(2026,1,2,10,0)});
            CallableStatement call=sequence(rs); f.add(sequence(),call,sequence());
            Map<String,Object> row=f.executor.execute(SqlServerProcedure.SESSION_SAVE,SqlServerContext.empty(),"a".repeat(64),ID,instant).resultSets().get(0).get(0);
            assertEquals("2026-01-02T12:34:56.123456Z",row.get("expiresAt"));assertEquals("2026-01-02",row.get("renewalDate"));
            assertEquals("2026-01-02T10:00:00Z",row.get("localValue"));
            verify(call).setTimestamp(eq(3),argThat(t->t.toInstant().equals(Instant.parse("2026-01-02T12:34:56.123456Z"))),argThat(c->c.getTimeZone().getID().equals("UTC")));
            verify(rs).getTimestamp(eq(1),argThat(c->c.getTimeZone().getID().equals("UTC")));
            verify(rs).getDate(eq(2),argThat(c->c.getTimeZone().getID().equals("UTC")));
            f.noTransactionControl();
        } finally { TimeZone.setDefault(original); }
    }

    @Test void typedNullsAndBitDefaultsAreExplicitNotDriverMetadata() throws Exception {
        Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
        f.executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,SqlServerContext.empty(),null,null,null);
        verify(call).setNull(1,Types.CHAR);verify(call).setNull(2,Types.CHAR);verify(call).setNull(3,Types.BIT);
        verify(call,never()).getParameterMetaData();verify(call,never()).setObject(anyInt(),any());
        Fixture b=new Fixture();CallableStatement bit=sequence();b.add(sequence(),bit,sequence());
        b.executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,SqlServerContext.empty(),ID,ID,true);
        verify(bit).setBoolean(3,true);
    }

    @Test void contextIsImmutableRedactedReplacedAndClearedOnSameSpringBoundConnection() throws Exception {
        Fixture f=new Fixture(); List<String> roles=new ArrayList<>(List.of("ADM"));
        SqlServerContext ctx=new SqlServerContext(ID,"POST","/api/test","127.0.0.1","Synthetic agent",ID,roles,ID,"a".repeat(64),SqlServerContext.Scope.REQUEST);
        roles.add("PRO");assertEquals(List.of("ADM"),ctx.roles());assertThrows(UnsupportedOperationException.class,()->ctx.roles().add("PRO"));
        assertEquals("SqlServerContext[redacted]",ctx.toString());
        CallableStatement before=sequence(),call=sequence(),after=sequence();f.add(before,call,after);
        TransactionSynchronizationManager.bindResource(f.ds,new ConnectionHolder(f.connection));
        try {
            f.executor.execute(SqlServerProcedure.HEALTH_READY,ctx);
            assertEquals(List.of(CONTEXT,"{call dbo.usp_health_ready()}",CONTEXT),f.calls);
            verify(f.ds,never()).getConnection();verify(f.connection,never()).close();
            verify(before).setString(1,ID);verify(before).setNString(2,"POST");verify(before).setNString(3,"/api/test");
            verify(before).setNString(4,"127.0.0.1");verify(before).setNString(5,"Synthetic agent");verify(before).setString(6,ID);
            verify(before).setNString(7,"[\"ADM\"]");verify(before).setString(8,ID);verify(before).setString(9,"a".repeat(64));verify(before).setString(10,"REQUEST");
            for(int i=1;i<=9;i++)verify(after).setNull(i,List.of(Types.CHAR,Types.NVARCHAR,Types.NVARCHAR,Types.NVARCHAR,Types.NVARCHAR,Types.CHAR,Types.NVARCHAR,Types.CHAR,Types.CHAR).get(i-1));
            verify(after).setString(10,"REQUEST");f.noTransactionControl();
        } finally { TransactionSynchronizationManager.unbindResource(f.ds); }
    }

    @Test void invalidArityTypesLengthsPurposeAndScopeNeverAcquireConnection() throws Exception {
        Fixture f=new Fixture();
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty(),"extra"));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.TENANT_BY_SLUG,SqlServerContext.empty(),42));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.TENANT_BY_SLUG,SqlServerContext.empty(),"x".repeat(64)));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.TENANT_BY_SLUG,SqlServerContext.empty(),"\u4e2d"));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.IDENTITY_MEMBERSHIP,SqlServerContext.empty(),ID,ID,1));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.SESSION_SAVE,SqlServerContext.empty(),"a",ID,LocalDateTime.now()));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.SESSION_SAVE,SqlServerContext.empty(),"a",ID,Instant.MAX));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.SESSION_SAVE,SqlServerContext.empty(),"a",ID,Instant.MIN));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.IDENTITY_CREDENTIALS,SqlServerContext.empty(),"x".repeat(255)));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,null));
        assertThrows(ApiException.class,()->f.executor.execute(null,SqlServerContext.empty()));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty(),(Object[])null));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.BOOTSTRAP_EXISTS,bootstrap()));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.BOOTSTRAP_CREATE,bootstrap(),ID,"qa@example.test","synthetic-hash"));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,bootstrap()));
        assertThrows(IllegalArgumentException.class,()->SqlServerProcedure.valueOf("usp_audit_change"));
        verify(f.ds,never()).getConnection();
    }

    @Test void invalidContextLengthAndOversizedSerializedRolesFailBeforeConnection() throws Exception {
        Fixture f=new Fixture();
        var longRoute=new SqlServerContext(null,null,"x".repeat(251),null,null,null,null,null,null,SqlServerContext.Scope.REQUEST);
        var longRoles=new SqlServerContext(null,null,null,null,null,null,List.of("x".repeat(4000)),null,null,SqlServerContext.Scope.REQUEST);
        var missingScope=new SqlServerContext(null,null,null,null,null,null,null,null,null,null);
        for(var ctx:List.of(longRoute,longRoles,missingScope))assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,ctx));
        verify(f.ds,never()).getConnection();
    }

    private SqlServerContext bootstrap() { return new SqlServerContext(null,null,null,null,null,null,null,null,null,SqlServerContext.Scope.BOOTSTRAP); }

    @Test void bootstrapPrincipalOnlyAdmitsBootstrapAndUsesUnicodeBinding() throws Exception {
        Fixture f=new Fixture(mock(DataSource.class),SqlServerExecutor.Purpose.BOOTSTRAP);
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,bootstrap()));
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.BOOTSTRAP_EXISTS,SqlServerContext.empty()));
        verify(f.ds,never()).getConnection();
        CallableStatement call=sequence();f.add(sequence(),call,sequence());
        f.executor.execute(SqlServerProcedure.BOOTSTRAP_CREATE,bootstrap(),ID,"qa@example.test","synthetic-hash");
        verify(call).setString(1,ID);verify(call).setNString(2,"qa@example.test");verify(call).setNString(3,"synthetic-hash");
        f.noTransactionControl();
    }

    @Test void lateErrorDiscardsPartialResultsAndCleansWithoutRetry() throws Exception {
        Fixture f=new Fixture(); ResultSet rs=rows(new String[]{"id"},new int[]{Types.INTEGER},new Object[]{1});
        CallableStatement call=sequence(rs),after=sequence();
        doThrow(new SQLException("private token late",null,51003)).when(call).getMoreResults(Statement.CLOSE_CURRENT_RESULT);
        f.add(sequence(),call,after);
        ApiException error=assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals(409,error.status);assertEquals("CONFLICT",error.code);assertFalse(error.toString().contains("private"));
        verify(call,times(1)).execute();verify(rs).close();verify(call).close();verify(after).execute();verify(after).close();
        verify(f.connection,never()).abort(any());f.noTransactionControl();
    }

    @Test void failedContextSetupStillClearsAndNeverInvokesBusiness() throws Exception {
        Fixture f=new Fixture();CallableStatement before=sequence(),after=sequence();
        when(before.execute()).thenThrow(new SQLException("private context",null,51001));f.add(before,after);
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals(List.of(CONTEXT,CONTEXT),f.calls);verify(before).close();verify(after).execute();verify(after).close();f.noTransactionControl();
    }

    @Test void failedResetAbortsAndEvictsHikariInsteadOfReturningSuccessfulData() throws Exception {
        HikariDataSource pool=mock(HikariDataSource.class);Fixture f=new Fixture(pool,SqlServerExecutor.Purpose.RUNTIME);
        CallableStatement after=sequence();when(after.execute()).thenThrow(new SQLException("secret reset",null,0));
        f.add(sequence(),sequence(),after);
        ApiException failure=assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals("DATABASE_ERROR",failure.code);assertFalse(failure.toString().contains("secret"));
        verify(f.connection).abort(any());verify(pool).evictConnection(f.connection);verify(after).close();f.noTransactionControl();
    }

    @Test void originalErrorRemainsPrimaryAndPhysicalFallbackClosesWhenAbortFails() throws Exception {
        Fixture f=new Fixture();CallableStatement call=sequence(),after=sequence();
        when(call.execute()).thenThrow(new SQLException("private first",null,51003));
        when(after.execute()).thenThrow(new SQLException("private reset",null,0));
        doThrow(new SQLFeatureNotSupportedException("private abort")).when(f.connection).abort(any());
        SQLServerConnection physical=mock(SQLServerConnection.class);when(f.connection.unwrap(SQLServerConnection.class)).thenReturn(physical);
        f.add(sequence(),call,after);
        ApiException failure=assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals("CONFLICT",failure.code);assertEquals(1,failure.getSuppressed().length);
        assertEquals("DATABASE_ERROR",((ApiException)failure.getSuppressed()[0]).code);
        assertFalse(Arrays.toString(failure.getSuppressed()).contains("private"));verify(physical).close();f.noTransactionControl();
    }

    @Test void readFailureClosesResourcesAndClearsContext() throws Exception {
        Fixture f=new Fixture();ResultSet rs=mock(ResultSet.class);when(rs.next()).thenThrow(new SQLException("private read",null,547));
        CallableStatement call=sequence(rs),after=sequence();f.add(sequence(),call,after);
        assertEquals("DATA_CONFLICT",assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty())).code);
        verify(rs).close();verify(call).close();verify(after).close();f.noTransactionControl();
    }

    @Test void microsoftDriverIsPresentWithoutConnecting() throws Exception {
        Driver driver=(Driver)Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver").getDeclaredConstructor().newInstance();
        assertTrue(driver.acceptsURL("jdbc:sqlserver://localhost;databaseName=synthetic"));
        assertFalse(driver.acceptsURL("jdbc:mysql://localhost/synthetic"));
    }

    @Test void unicodeEmptyAndNullInputAreBoundExactlyAndTimestampNullHasDeclaredType() throws Exception {
        for (String input:Arrays.asList(null,"","\u00c1\u4e2d\ud83e\uddb7")) {
            Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
            f.executor.execute(SqlServerProcedure.IDENTITY_CREDENTIALS,SqlServerContext.empty(),input);
            if(input==null)verify(call).setNull(1,Types.NVARCHAR);else verify(call).setNString(1,input);
        }
        Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
        f.executor.execute(SqlServerProcedure.SESSION_SAVE,SqlServerContext.empty(),null,null,null);
        verify(call).setNull(3,Types.TIMESTAMP);verify(call,never()).getParameterMetaData();
    }

    @Test void hikariEvictionStillDiscardsEntryWhenDriverAbortFails() throws Exception {
        HikariDataSource pool=mock(HikariDataSource.class);Fixture f=new Fixture(pool,SqlServerExecutor.Purpose.RUNTIME);
        CallableStatement after=sequence();when(after.execute()).thenThrow(new SQLException("private reset",null,0));
        doThrow(new SQLFeatureNotSupportedException("private abort")).when(f.connection).abort(any());
        f.add(sequence(),sequence(),after);
        assertEquals("DATABASE_ERROR",assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty())).code);
        verify(pool).evictConnection(f.connection);verify(f.connection,never()).unwrap(SQLServerConnection.class);f.noTransactionControl();
    }

    @Test void acquisitionFailureIsSanitizedWithoutAnotherConnectionAttempt() throws Exception {
        Fixture f=new Fixture();when(f.ds.getConnection()).thenThrow(new SQLException("private login/host",null,18456));
        ApiException failure=assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals("DATABASE_ERROR",failure.code);assertFalse(failure.toString().contains("private"));
        verify(f.ds,times(1)).getConnection();verify(f.connection,never()).prepareCall(anyString());
    }

    @Test void invalidJsonOutputStillClosesAndClearsWithoutLeakingText() throws Exception {
        Fixture f=new Fixture();ResultSet rs=rows(new String[]{"profile"},new int[]{Types.NVARCHAR},new Object[]{"private malformed-json"});
        CallableStatement call=sequence(rs),after=sequence();f.add(sequence(),call,after);
        ApiException failure=assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()));
        assertEquals("DATABASE_ERROR",failure.code);assertFalse(failure.toString().contains("private"));
        verify(rs).close();verify(call).close();verify(after).execute();f.noTransactionControl();
    }

    @Test void closeFailureAlsoPreventsSuccessAndResets() throws Exception {
        Fixture f=new Fixture();CallableStatement call=sequence(),after=sequence();
        doThrow(new SQLException("private close",null,1205)).when(call).close();f.add(sequence(),call,after);
        assertEquals("CONCURRENT_CHANGE",assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty())).code);
        verify(after).execute();verify(call,times(1)).execute();f.noTransactionControl();
    }

    @Test void fullNclobJsonAndNumericBitAreMappedThroughJdbcGetters() throws Exception {
        Fixture f=new Fixture();NClob clob=mock(NClob.class);String text="\u4e2d\ud83e\uddb7".repeat(3000);
        ResultSet rs=rows(new String[]{"profile","active"},new int[]{Types.NCLOB,Types.BIT},new Object[]{clob,1});
        when(rs.getNString(1)).thenReturn(mapper.writeValueAsString(Map.of("text",text)));when(rs.getBoolean(2)).thenReturn(true);
        f.add(sequence(),sequence(rs),sequence());
        var row=f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()).resultSets().get(0).get(0);
        assertEquals(text,((Map<?,?>)row.get("profile")).get("text"));assertEquals(true,row.get("active"));
        verify(rs).getNString(1);verify(rs).getBoolean(2);verify(rs).close();verify(clob).free();
    }

    @Test void jsonDecimalsAndLargeIntegersStayExactWithoutMutatingSharedMapper() throws Exception {
        Fixture f=new Fixture();
        String json="{\"money\":9999999999999999.123456789,\"units\":99999999999999999999999999999999999999}";
        ResultSet rs=rows(new String[]{"payload"},new int[]{Types.NVARCHAR},new Object[]{json});
        f.add(sequence(),sequence(rs),sequence());
        Map<?,?> payload=(Map<?,?>)f.executor.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty()).resultSets().get(0).get(0).get("payload");
        assertEquals(new BigDecimal("9999999999999999.123456789"),payload.get("money"));
        assertEquals(new BigInteger("99999999999999999999999999999999999999"),payload.get("units"));
        assertInstanceOf(Double.class,((Map<?,?>)mapper.readValue("{\"n\":1.25}",Object.class)).get("n"));
    }

    @Test void integerAndBigintBoundariesUseExactSettersWithoutNarrowingOrTransactionControl() throws Exception {
        // JDBC type boundaries only. Business ranges/authorization still belong to the real SP.
        for (int value:new int[]{Integer.MIN_VALUE,0,Integer.MAX_VALUE}) {
            Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
            f.executor.execute(SqlServerProcedure.MAIL_CLAIM,SqlServerContext.empty(),value);
            verify(call).setInt(1,value);verify(call,never()).setLong(anyInt(),anyLong());
            verify(call,never()).setObject(anyInt(),any());verify(call,never()).getParameterMetaData();
            verify(f.ds,times(1)).getConnection();f.noTransactionControl();
        }
        for (long value:new long[]{Long.MIN_VALUE,0L,Long.MAX_VALUE}) {
            Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
            f.executor.execute(SqlServerProcedure.REQUEST_FINISH,SqlServerContext.empty(),200,value);
            verify(call).setInt(1,200);verify(call).setLong(2,value);
            verify(call,never()).setObject(anyInt(),any());f.noTransactionControl();
        }
    }

    @Test void numericNullsBindDeclaredIntAndBigintAndNoDefaultIsSilentlySubstituted() throws Exception {
        Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
        f.executor.execute(SqlServerProcedure.REQUEST_FINISH,SqlServerContext.empty(),null,null);
        verify(call).setNull(1,Types.INTEGER);verify(call).setNull(2,Types.BIGINT);
        Fixture missing=new Fixture();
        assertThrows(ApiException.class,()->missing.executor.execute(SqlServerProcedure.MAIL_CLAIM,SqlServerContext.empty()));
        assertThrows(ApiException.class,()->missing.executor.execute(SqlServerProcedure.PATIENTS_LIST,SqlServerContext.empty(),"",100));
        verify(missing.ds,never()).getConnection();
        Fixture explicit=new Fixture();CallableStatement claimed=sequence();explicit.add(sequence(),claimed,sequence());
        explicit.executor.execute(SqlServerProcedure.MAIL_CLAIM,SqlServerContext.empty(),10);
        verify(claimed).setInt(1,10);
    }

    @Test void numericOverflowAndWrongNumberClassesFailLocallyBeforeConnection() throws Exception {
        Fixture f=new Fixture();
        for (Object bad:List.of(2147483648L,-2147483649L,1L,(short)1,(byte)1,1.0,1.0f,
                new BigInteger("2147483648"),new BigDecimal("1"),"1",true)) {
            ApiException error=assertThrows(ApiException.class,()->
                    f.executor.execute(SqlServerProcedure.MAIL_CLAIM,SqlServerContext.empty(),bad));
            assertEquals(400,error.status);assertEquals("INVALID",error.code);
        }
        for (Object bad:List.of(1,(short)1,1.0,1.0f,new BigInteger("9223372036854775808"),
                new BigInteger("-9223372036854775809"),new BigDecimal("1"),"1",true)) {
            assertEquals("INVALID",assertThrows(ApiException.class,()->
                    f.executor.execute(SqlServerProcedure.REQUEST_FINISH,SqlServerContext.empty(),200,bad)).code);
        }
        verify(f.ds,never()).getConnection();verify(f.connection,never()).prepareCall(anyString());
    }

    @Test void maxUnicodeAndLongJsonAreBoundVerbatimAndAllNewFamilyResultsAndCountsSurvive() throws Exception {
        String unicode="\u00c1\u4e2d\ud83e\uddb7".repeat(5000);
        String json=" \n"+mapper.writeValueAsString(Map.of("notes",unicode,"private",List.of("a","b")))+"\n ";
        assertTrue(json.length()>4000);
        Fixture f=new Fixture();
        ResultSet empty=rows(new String[]{"id"},new int[]{Types.CHAR});
        ResultSet value=rows(new String[]{"id","amount_minor","nullable_value","active"},
                new int[]{Types.CHAR,Types.BIGINT,Types.NVARCHAR,Types.BIT},
                new Object[]{ID,Long.MAX_VALUE,null,true});
        CallableStatement call=sequence(0,empty,0,value,5),after=sequence();f.add(sequence(),call,after);
        var result=f.executor.execute(SqlServerProcedure.FINANCE_POST,SqlServerContext.empty(),
                ID,json,"synthetic-key","f".repeat(64));
        verify(call).setString(1,ID);verify(call).setNString(2,json);
        verify(call).setNString(3,"synthetic-key");verify(call).setString(4,"f".repeat(64));
        assertEquals(List.of(0,0,5),result.updateCounts());assertEquals(2,result.resultSets().size());
        assertTrue(result.resultSets().get(0).isEmpty());var row=result.resultSets().get(1).get(0);
        assertEquals(Long.MAX_VALUE,row.get("amountMinor"));assertNull(row.get("nullableValue"));assertEquals(true,row.get("active"));
        verify(empty).close();verify(value).close();verify(call).close();verify(after).close();
        verify(call,never()).setObject(anyInt(),any());verify(call,times(1)).execute();f.noTransactionControl();
    }

    @Test void maxNullEmptyAndNonJsonTextAreNotParsedNormalizedOrReserializedBeforeBinding() throws Exception {
        for (String input:Arrays.asList(null,"","not-json \u4e2d\ud83e\uddb7\n".repeat(1000))) {
            Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
            f.executor.execute(SqlServerProcedure.SAAS_PLAN_SAVE,SqlServerContext.empty(),ID,input,false);
            if(input==null)verify(call).setNull(2,Types.NVARCHAR);else verify(call).setNString(2,input);
            verify(call).setBoolean(3,false);verify(call,never()).setObject(anyInt(),any());
        }
        Fixture f=new Fixture();
        assertThrows(ApiException.class,()->f.executor.execute(SqlServerProcedure.SAAS_PLAN_SAVE,
                SqlServerContext.empty(),ID,Map.of("not","a serialized String"),false));
        verify(f.ds,never()).getConnection();
    }

    @Test void traceMixedSignatureKeepsEveryDefaultPositionTypedIncludingUtcAndBigint() throws Exception {
        Fixture f=new Fixture();CallableStatement call=sequence();f.add(sequence(),call,sequence());
        Instant until=Instant.parse("2026-11-04T00:00:00.999999999Z");
        f.executor.execute(SqlServerProcedure.TRACE_EVENTS,SqlServerContext.empty(),
                null,ID,"patients",null,null,until,0L,50);
        verify(call).setNull(1,Types.NVARCHAR);verify(call).setString(2,ID);
        verify(call).setNString(3,"patients");verify(call).setNull(4,Types.CHAR);
        verify(call).setNull(5,Types.TIMESTAMP);
        verify(call).setTimestamp(eq(6),argThat(t->t.toInstant().equals(Instant.parse("2026-11-04T00:00:00.999999Z"))),
                argThat(c->c.getTimeZone().getID().equals("UTC")));
        verify(call).setLong(7,0L);verify(call).setInt(8,50);verify(call).close();f.noTransactionControl();
    }

    @Test void expandedCatalogDoesNotExpandBootstrapPurposeOrAllowBootstrapScopeInRuntime() throws Exception {
        Fixture b=new Fixture(mock(DataSource.class),SqlServerExecutor.Purpose.BOOTSTRAP),r=new Fixture();
        for (SqlServerProcedure procedure:SqlServerProcedure.values()) {
            Object[] nullParameters=new Object[procedure.parameters().size()];
            if (!procedure.bootstrap())
                assertThrows(ApiException.class,()->b.executor.execute(procedure,bootstrap(),nullParameters),procedure.name());
            assertThrows(ApiException.class,()->r.executor.execute(procedure,bootstrap(),nullParameters),procedure.name());
        }
        verify(b.ds,never()).getConnection();verify(r.ds,never()).getConnection();
    }
}
