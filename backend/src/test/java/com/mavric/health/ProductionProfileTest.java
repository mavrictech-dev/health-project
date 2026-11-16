package com.mavric.health;

import java.nio.file.*;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.*;
import java.util.stream.Stream;
import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.zaxxer.hikari.HikariDataSource;
import com.mavric.health.identity.Actor;
import com.mavric.health.identity.BranchTokens;
import com.mavric.health.identity.Bootstrap;
import com.mavric.health.identity.MailDelivery;
import com.mavric.healthsqlserver.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.context.support.GenericApplicationContext;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.mock.web.MockServletContext;
import org.springframework.web.context.support.GenericWebApplicationContext;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Real ConfigData + factory discovery + SpringApplication; no embedded server, SQL or provider traffic. */
class ProductionProfileTest {
    private static ch.qos.logback.classic.Level originalRootLevel;

    @BeforeAll static void preserveRootLogging() {
        originalRootLevel = ((ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME)).getLevel();
    }

    // Class callbacks also surround every dynamic executable created by @TestFactory.
    @AfterAll static void restoreRootLogging() {
        ((ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(org.slf4j.Logger.ROOT_LOGGER_NAME)).setLevel(originalRootLevel);
    }

    @TempDir Path temporary;
    static final String CANARY = "private-input-canary";
    record Inputs(Map<String,Object> properties,Path secrets) { }

    static String randomSecret() {
        byte[] bytes = new byte[48]; new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
    Inputs inputs() throws Exception {
        Path secrets = Files.createDirectory(temporary.resolve(UUID.randomUUID().toString()));
        Files.writeString(secrets.resolve("HEALTH_JWT_SECRET"), randomSecret());
        Files.writeString(secrets.resolve("health.sqlserver.runtime.password"), randomSecret());
        var p = new LinkedHashMap<String,Object>();
        p.put("spring.profiles.active", "production");
        p.put("HEALTH_PRODUCTION_SECRETS_DIR", secrets.toAbsolutePath().toString().replace('\\','/') + "/");
        p.put("HEALTH_BASE_DOMAIN", "health.example.test");
        p.put("HEALTH_PUBLIC_ORIGIN", "https://health.example.test");
        p.put("HEALTH_SQLSERVER_SERVER", "sql.example.test");
        p.put("HEALTH_SQLSERVER_DATABASE", "health_project_synthetic");
        p.put("HEALTH_SQLSERVER_RUNTIME_USER", "synthetic_execute_only");
        p.put("logging.level.root", "OFF");
        p.put("spring.main.banner-mode", "off");
        return new Inputs(p, secrets);
    }
    static SpringApplication application(Map<String,Object> properties) {
        var environment = new StandardEnvironment();
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME);
        environment.getPropertySources().addFirst(new MapPropertySource("synthetic-only", properties));
        var application = new SpringApplication();
        assertTrue(application.getInitializers().stream().anyMatch(ProductionProfileGuard.class::isInstance), "Factory must be discovered automatically");
        application.setEnvironment(environment);
        application.setWebApplicationType(WebApplicationType.SERVLET);
        application.setLogStartupInfo(false);
        application.setRegisterShutdownHook(false);
        application.setApplicationContextFactory(type -> {
            var context = new GenericWebApplicationContext();
            context.setServletContext(new MockServletContext());
            return context;
        });
        application.addListeners(new SqlServerApplicationSourceSelector(application));
        return application;
    }

    @Test void productionLoadsTheFactoryAndActualProfileWithoutOpeningConnectionsAndKeepsJwtAcrossContexts() throws Exception {
        Inputs inputs = inputs();
        String token;
        var actor = new Actor("91000000-0000-4000-8000-000000000001", "Synthetic", "qa@example.test", "92000000-0000-4000-8000-000000000001", List.of("REC"), "a".repeat(64));
        String branch = "93000000-0000-4000-8000-000000000001";
        try (var drivers = mockConstruction(SQLServerDataSource.class)) {
            try (var context = application(inputs.properties()).run()) {
                var env = context.getEnvironment();
                assertEquals("runtime", env.getProperty("health.sqlserver.mode"));
                assertEquals("false", env.getProperty("spring.flyway.enabled"));
                assertEquals("never", env.getProperty("spring.sql.init.mode"));
                assertEquals("false", env.getProperty("health.sqlserver.jobs.enabled"));
                assertEquals("https://health.example.test", context.getBean(com.mavric.health.tenancy.Settings.class).publicOrigin());
                var sql = context.getBean(SqlServerRuntimeProperties.class);
                assertEquals("sql.example.test", sql.serverName());
                assertEquals(1433, sql.port());
                assertFalse(sql.trustServerCertificate());
                assertTrue(java.security.MessageDigest.isEqual(Files.readAllBytes(inputs.secrets().resolve("health.sqlserver.runtime.password")), sql.password().getBytes(java.nio.charset.StandardCharsets.UTF_8)));
                assertEquals(1, context.getBeansOfType(javax.sql.DataSource.class).size());
                var pool = context.getBean(HikariDataSource.class);
                assertFalse(pool.isRunning()); assertNull(pool.getHikariPoolMXBean());
                assertEquals("EXEC dbo.usp_health_ready", pool.getConnectionTestQuery());
                for (Class<?> type : List.of(Bootstrap.class, MailDelivery.class, org.flywaydb.core.Flyway.class,
                        org.springframework.scheduling.annotation.ScheduledAnnotationBeanPostProcessor.class,
                        org.springframework.boot.sql.init.AbstractScriptDatabaseInitializer.class))
                    assertTrue(context.getBeansOfType(type).isEmpty(), type.getSimpleName());
                token = context.getBean(BranchTokens.class).issue("s".repeat(43), actor, branch, Instant.now().plusSeconds(300));
            }
            try (var restarted = application(inputs.properties()).run()) {
                assertEquals(branch, restarted.getBean(BranchTokens.class).verify(token).branchId());
                assertFalse(restarted.getBean(HikariDataSource.class).isRunning());
            }
            assertEquals(2, drivers.constructed().size());
            for (var driver : drivers.constructed()) {
                verify(driver).setEncrypt("true"); verify(driver).setTrustServerCertificate(false);
                verify(driver, never()).getConnection(); verify(driver, never()).getConnection(anyString(), anyString());
            }
        }
    }

    static void rejected(Inputs inputs, String expectedCode) {
        try (var drivers = mockConstruction(SQLServerDataSource.class); var pools = mockConstruction(HikariDataSource.class)) {
            var failure = assertThrows(RuntimeException.class, () -> application(inputs.properties()).run());
            assertTrue(drivers.constructed().isEmpty(), "Driver created before production validation");
            assertTrue(pools.constructed().isEmpty(), "Pool created before production validation");
            var seen = Collections.newSetFromMap(new IdentityHashMap<Throwable,Boolean>());
            boolean safe = false, expected = expectedCode == null;
            for (Throwable t = failure; t != null && seen.add(t); t = t.getCause()) {
                String message = Objects.toString(t.getMessage(), "");
                assertFalse(message.contains(CANARY));
                if (message.startsWith("HP_PRODUCTION_")) { assertNull(t.getCause()); safe = true; }
                if (message.equals("Unsafe application source selection.")) safe = true;
                if (message.equals(expectedCode)) expected = true;
            }
            assertTrue(safe, "Failure must be sanitized");
            assertTrue(expected, "Expected safe diagnostic code was absent");
        }
    }

    @TestFactory Stream<DynamicTest> jwtFilesAreMandatoryAndNeverFallBackToRandomKeys() {
        return Stream.of("missing", "empty", "short", "newline").map(kind -> DynamicTest.dynamicTest("JWT " + kind, () -> {
            var input = inputs(); Path file = input.secrets().resolve("HEALTH_JWT_SECRET");
            switch (kind) {
                case "missing" -> Files.delete(file);
                case "empty" -> Files.writeString(file, "");
                case "short" -> Files.writeString(file, CANARY);
                case "newline" -> Files.writeString(file, randomSecret() + "\ninside");
            }
            rejected(input, "HP_PRODUCTION_JWT");
        }));
    }

    @TestFactory Stream<DynamicTest> unsafeProductionOverridesAreRejectedBeforeDriverConstruction() {
        var cases = List.of(
            Map.entry("HEALTH_PUBLIC_ORIGIN", "http://health.example.test"),
            Map.entry("HEALTH_PUBLIC_ORIGIN", "https://other.example.test"),
            Map.entry("HEALTH_PUBLIC_ORIGIN", "https://" + CANARY + "@health.example.test"),
            Map.entry("HEALTH_PUBLIC_ORIGIN", "https://health.example.test/path"),
            Map.entry("HEALTH_PUBLIC_ORIGIN", "https://health.example.test:0"),
            Map.entry("HEALTH_PUBLIC_ORIGIN", "https://health.example.test:65536"),
            Map.entry("HEALTH_BASE_DOMAIN", CANARY),
            Map.entry("health.sqlserver.mode", "mysql"),
            Map.entry("health.sqlserver.runtime.trust-server-certificate", "true"),
            Map.entry("health.sqlserver.jobs.enabled", "true"),
            Map.entry("spring.flyway.enabled", "true"),
            Map.entry("spring.sql.init.mode", "always"),
            Map.entry("migrate", "false"), Map.entry("setup", "false"), Map.entry("bootstrap", "false"),
            Map.entry("MIGRATION_PASSWORD", CANARY), Map.entry("BOOTSTRAP_ADMIN_PASSWORD", CANARY),
            Map.entry("spring.datasource.url", "jdbc:mysql://synthetic.invalid/legacy"),
            Map.entry("DATABASE_PASSWORD", CANARY),
            Map.entry("server.forward-headers-strategy", "framework"),
            Map.entry("HEALTH_SQLSERVER_SERVER", "127.0.0.1"),
            Map.entry("HEALTH_SQLSERVER_SERVER", "."),
            Map.entry("HEALTH_SQLSERVER_SERVER", "::"),
            Map.entry("HEALTH_SQLSERVER_SERVER", "[::]"),
            Map.entry("spring.profiles.active", "production,sqlserver-qa")
        );
        return cases.stream().map(change -> DynamicTest.dynamicTest("reject " + change.getKey() + " variant " + cases.indexOf(change), () -> {
            var input = inputs(); input.properties().put(change.getKey(), change.getValue()); rejected(input, null);
        }));
    }

    @TestFactory Stream<DynamicTest> externalSqlInputsHaveNoCredentialOrDestinationDefaults() {
        return Stream.of("HEALTH_SQLSERVER_SERVER", "HEALTH_SQLSERVER_DATABASE", "HEALTH_SQLSERVER_RUNTIME_USER", "password").map(key -> DynamicTest.dynamicTest("missing " + key, () -> {
            var input = inputs();
            if (key.equals("password")) Files.delete(input.secrets().resolve("health.sqlserver.runtime.password"));
            else input.properties().remove(key);
            rejected(input, "HP_PRODUCTION_SQL_INPUTS");
        }));
    }

    @Test void otherProfilesAreUnchangedEvenWithInputsThatProductionWouldReject() {
        try (var drivers = mockConstruction(SQLServerDataSource.class); var pools = mockConstruction(HikariDataSource.class); var context = new GenericApplicationContext()) {
            context.getEnvironment().setActiveProfiles("sqlserver-qa");
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource("synthetic", Map.of("HEALTH_JWT_SECRET", "", "health.sqlserver.jobs.enabled", "true")));
            int before = context.getBeanDefinitionCount();
            assertDoesNotThrow(() -> new ProductionProfileGuard().initialize(context));
            assertEquals(before, context.getBeanDefinitionCount());
            assertTrue(drivers.constructed().isEmpty()); assertTrue(pools.constructed().isEmpty());
        }
    }
}
