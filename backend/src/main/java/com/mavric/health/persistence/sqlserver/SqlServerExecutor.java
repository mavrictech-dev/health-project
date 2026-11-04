package com.mavric.health.persistence.sqlserver;

import java.sql.*;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import javax.sql.DataSource;
import com.microsoft.sqlserver.jdbc.SQLServerConnection;
import com.zaxxer.hikari.HikariDataSource;
import com.mavric.health.shared.ApiException;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceUtils;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.ObjectReader;
import tools.jackson.databind.DeserializationFeature;

/** Unwired adapter: Spring owns transaction boundaries and the supplied principal's datasource. */
public final class SqlServerExecutor {
    public enum Purpose { RUNTIME, BOOTSTRAP }
    private static final String CONTEXT_CALL = "{call dbo.usp_request_context(?,?,?,?,?,?,?,?,?,?)}";
    private static final List<SqlServerProcedure.Parameter> CONTEXT_PARAMETERS = List.of(
            SqlServerProcedure.ascii(JDBCType.CHAR,36), SqlServerProcedure.unicode(10),
            SqlServerProcedure.unicode(250), SqlServerProcedure.unicode(80), SqlServerProcedure.unicode(300),
            SqlServerProcedure.ascii(JDBCType.CHAR,36), SqlServerProcedure.unicode(4000),
            SqlServerProcedure.ascii(JDBCType.CHAR,36), SqlServerProcedure.ascii(JDBCType.CHAR,64),
            SqlServerProcedure.ascii(JDBCType.VARCHAR,20));
    private static final Set<String> JSON_COLUMNS = Set.of("roles","modules","kinds","domains","specialties",
            "branches","scopes","profile","profileSnapshot","payload","metadata","contact","allergies",
            "creators","operators","readers","transitions","beforeState","afterState","actorRoles");
    private final JdbcTemplate jdbc;
    private final ObjectMapper mapper;
    private final ObjectReader jsonReader;
    private final Purpose purpose;

    public SqlServerExecutor(JdbcTemplate jdbc, ObjectMapper mapper, Purpose purpose) {
        if (jdbc == null || mapper == null || purpose == null) throw SqlServerErrors.invalid();
        this.jdbc=jdbc; this.mapper=mapper; this.purpose=purpose;
        this.jsonReader=mapper.readerFor(Object.class).with(DeserializationFeature.USE_BIG_DECIMAL_FOR_FLOATS);
    }

    public record Result(List<List<Map<String,Object>>> resultSets, List<Integer> updateCounts) {
        public Result {
            resultSets=resultSets.stream().map(rows -> rows.stream()
                    .map(row -> Collections.unmodifiableMap(new LinkedHashMap<>(row))).toList()).toList();
            updateCounts=List.copyOf(updateCounts);
        }
        @Override public String toString() { return "SqlServerResult[redacted]"; }
    }

    public Result execute(SqlServerProcedure procedure, SqlServerContext context, Object... arguments) {
        if (procedure == null || context == null || context.scope() == null || arguments == null)
            throw SqlServerErrors.invalid();
        if (purpose == Purpose.RUNTIME && (procedure.bootstrap() || context.scope() == SqlServerContext.Scope.BOOTSTRAP)
                || purpose == Purpose.BOOTSTRAP && (!procedure.bootstrap() || context.scope() != SqlServerContext.Scope.BOOTSTRAP))
            throw SqlServerErrors.invalid();
        Object[] values=arguments.clone();
        validate(procedure.parameters(), values);
        Object[] before=contextValues(context); // serialization/length/type validation BEFORE connection acquisition
        Object[] after=contextValues(SqlServerContext.empty());
        try {
            return jdbc.execute((ConnectionCallback<Result>) connection -> {
                Throwable failure=null;
                Result result=null;
                try {
                    invoke(connection, CONTEXT_CALL, CONTEXT_PARAMETERS, before, false);
                    result=invoke(connection, procedure.call(), procedure.parameters(), values, true);
                } catch (SQLException | RuntimeException error) {
                    failure=SqlServerErrors.map(error);
                } catch (Error error) {
                    failure=error;
                } finally {
                    try {
                        invoke(connection, CONTEXT_CALL, CONTEXT_PARAMETERS, after, false);
                    } catch (SQLException | RuntimeException | Error reset) {
                        ApiException safeReset=SqlServerErrors.database();
                        invalidate(connection, safeReset);
                        if (failure == null) failure=reset instanceof Error ? reset : safeReset;
                        else failure.addSuppressed(safeReset);
                    }
                }
                if (failure instanceof Error fatal) throw fatal;
                if (failure != null) throw (ApiException) failure;
                return result;
            });
        } catch (RuntimeException error) {
            throw SqlServerErrors.map(error); // also sanitizes datasource/acquisition failures
        }
    }

    private Object[] contextValues(SqlServerContext context) {
        String roles=null;
        if (context.roles() != null) {
            for (Object role : context.roles()) if (!(role instanceof String)) throw SqlServerErrors.invalid();
            try { roles=mapper.writeValueAsString(context.roles()); }
            catch (RuntimeException error) { throw SqlServerErrors.invalid(); }
        }
        Object[] values={context.requestId(),context.method(),context.route(),context.sourceIp(),context.userAgent(),
                context.actorId(),roles,context.tenantId(),context.tokenHash(),context.scope().name()};
        validate(CONTEXT_PARAMETERS, values);
        return values;
    }

    private static void validate(List<SqlServerProcedure.Parameter> parameters, Object[] values) {
        if (parameters.size() != values.length) throw SqlServerErrors.invalid();
        for (int i=0;i<values.length;i++) parameters.get(i).validate(values[i]);
    }

    private Result invoke(Connection connection, String call, List<SqlServerProcedure.Parameter> parameters,
            Object[] values, boolean collect) throws SQLException {
        List<List<Map<String,Object>>> sets=new ArrayList<>();
        List<Integer> counts=new ArrayList<>();
        try (CallableStatement statement=connection.prepareCall(call)) {
            for (int i=0;i<values.length;i++) {
                Object value=values[i]; JDBCType type=parameters.get(i).type();
                if (value == null) statement.setNull(i+1,type.getVendorTypeNumber());
                else switch (type) {
                    case NVARCHAR -> statement.setNString(i+1,(String)value);
                    case CHAR, VARCHAR -> statement.setString(i+1,(String)value);
                    case BIT -> statement.setBoolean(i+1,(Boolean)value);
                    case INTEGER -> statement.setInt(i+1,(Integer)value);
                    case BIGINT -> statement.setLong(i+1,(Long)value);
                    // DATETIME2(6): deliberately floor sub-microsecond precision; never round across a second.
                    case TIMESTAMP -> statement.setTimestamp(i+1,Timestamp.from(((Instant)value).truncatedTo(ChronoUnit.MICROS)),utc());
                    default -> throw SqlServerErrors.invalid();
                }
            }
            boolean hasResult=statement.execute();
            while (true) {
                if (hasResult) {
                    try (ResultSet rs=statement.getResultSet()) {
                        List<Map<String,Object>> rows=new ArrayList<>();
                        while (rs.next()) if (collect) rows.add(row(rs));
                        if (collect) sets.add(rows); // preserve EMPTY resultsets too
                    }
                } else {
                    int count=statement.getUpdateCount();
                    if (count == -1) break;
                    if (collect) counts.add(count); // zero/interleaved counts do not terminate consumption
                }
                hasResult=statement.getMoreResults(Statement.CLOSE_CURRENT_RESULT);
            }
        }
        return new Result(sets,counts);
    }

    private Map<String,Object> row(ResultSet rs) throws SQLException {
        Map<String,Object> row=new LinkedHashMap<>();
        ResultSetMetaData columns=rs.getMetaData();
        for (int i=1;i<=columns.getColumnCount();i++) {
            String name=camel(columns.getColumnLabel(i));
            Object value=rs.getObject(i);
            if (value != null) {
                if (value instanceof NClob clob) {
                    try { value=rs.getNString(i); } finally { clob.free(); }
                } else if (value instanceof Clob clob) {
                    try { value=rs.getString(i); } finally { clob.free(); }
                }
                if (value instanceof LocalDateTime local) value=local.toInstant(ZoneOffset.UTC).toString();
                else if (value instanceof OffsetDateTime offset) value=offset.toInstant().toString();
                else if (value instanceof Timestamp || columns.getColumnType(i)==Types.TIMESTAMP) {
                    value=rs.getTimestamp(i,utc()).toInstant().toString();
                } else if (value instanceof LocalDate date) value=date.toString();
                else if (value instanceof java.sql.Date || columns.getColumnType(i)==Types.DATE) {
                    value=Instant.ofEpochMilli(rs.getDate(i,utc()).getTime()).atZone(ZoneOffset.UTC).toLocalDate().toString();
                } else if (!(value instanceof Boolean) && (columns.getColumnType(i)==Types.BIT || columns.getColumnType(i)==Types.BOOLEAN)) {
                    value=rs.getBoolean(i);
                }
                if (value instanceof String text && JSON_COLUMNS.contains(name)) value=jsonReader.readValue(text);
            }
            row.put(name,value); // SQL NULL is intentionally preserved
        }
        return row;
    }

    private void invalidate(Connection connection, ApiException safeReset) {
        Connection target=DataSourceUtils.getTargetConnection(connection);
        boolean discarded=false;
        try { target.abort(Runnable::run); discarded=true; }
        catch (SQLException | RuntimeException error) { safeReset.addSuppressed(SqlServerErrors.database()); }
        // Eviction prevents a failed-reset Hikari entry from rejoining its pool, even if abort failed.
        DataSource source=jdbc.getDataSource();
        if (source instanceof HikariDataSource pool) {
            try { pool.evictConnection(target); discarded=true; }
            catch (RuntimeException error) { safeReset.addSuppressed(SqlServerErrors.database()); }
        }
        if (!discarded) {
            // Unwrap the physical Microsoft connection: close() on a pooled facade alone can return dirty state.
            try { target.unwrap(SQLServerConnection.class).close(); }
            catch (SQLException | RuntimeException error) { safeReset.addSuppressed(SqlServerErrors.database()); }
        }
    }

    private static Calendar utc() {
        GregorianCalendar calendar=new GregorianCalendar(TimeZone.getTimeZone("UTC"),Locale.ROOT);
        calendar.setGregorianChange(new java.util.Date(Long.MIN_VALUE)); // SQL DATETIME2 uses the proleptic Gregorian calendar.
        return calendar;
    }
    private static String camel(String source) {
        StringBuilder result=new StringBuilder(); boolean upper=false;
        for (char c:source.toCharArray()) {
            if (c=='_') upper=true;
            else { result.append(upper?Character.toUpperCase(c):c); upper=false; }
        }
        return result.toString();
    }
}
