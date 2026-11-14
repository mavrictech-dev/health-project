package com.mavric.healthsqlserver;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import com.mavric.health.tenancy.Settings;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;

/** Production-only startup checks. Never opens a connection or includes input values in errors. */
public final class ProductionProfileGuard implements ApplicationContextInitializer<ConfigurableApplicationContext>, Ordered {
    @Override public int getOrder() { return Ordered.HIGHEST_PRECEDENCE + 100; }

    @Override public void initialize(ConfigurableApplicationContext context) {
        var env = context.getEnvironment();
        if (!Arrays.asList(env.getActiveProfiles()).contains("production")) return;
        try {
            if (Arrays.stream(env.getActiveProfiles()).anyMatch(List.of("demo", "mock", "sqlserver-qa")::contains))
                throw invalid("PROFILE");
            try {
                new SqlServerRuntimeModeGuard(env).postProcessBeanDefinitionRegistry(new DefaultListableBeanFactory());
            } catch (RuntimeException ignored) { throw invalid("RUNTIME"); }
            String jwt = property(env, "HEALTH_JWT_SECRET", "JWT");
            if (jwt == null || jwt.isBlank() || jwt.getBytes(StandardCharsets.UTF_8).length < 32
                    || jwt.chars().anyMatch(Character::isISOControl)) throw invalid("JWT");
            require(env, "health.sqlserver.runtime.trust-server-certificate", "false", "TLS");
            require(env, "server.forward-headers-strategy", "none", "FORWARDED");
            for (String key : List.of("spring.datasource.url", "spring.datasource.username", "spring.datasource.password",
                    "DATABASE_URL", "DATABASE_USER", "DATABASE_PASSWORD")) {
                String value = property(env, key, "LEGACY_DATASOURCE");
                if (value != null && !value.isEmpty()) throw invalid("LEGACY_DATASOURCE");
            }
            Settings settings;
            try { settings = Binder.get(env).bind("health", Settings.class).orElseThrow(() -> invalid("ORIGIN")); }
            catch (RuntimeException ignored) { throw invalid("ORIGIN"); }
            URI origin = URI.create(settings.publicOrigin());
            if (!"https".equals(origin.getScheme()) || origin.getPort() == 0 || origin.getPort() > 65535) throw invalid("ORIGIN");
            // Binder can leave an unresolved placeholder as a database/user string.
            // Resolve required inputs strictly before binding so none becomes an accidental fallback.
            for (String key : List.of("server-name", "database-name", "username", "password")) {
                String value = property(env, "health.sqlserver.runtime." + key, "SQL_INPUTS");
                if (value == null || value.isBlank()) throw invalid("SQL_INPUTS");
            }
            SqlServerRuntimeProperties sql;
            try { sql = Binder.get(env).bind("health.sqlserver.runtime", SqlServerRuntimeProperties.class).orElseThrow(() -> invalid("SQL_INPUTS")); }
            catch (RuntimeException ignored) { throw invalid("SQL_INPUTS"); }
            if (sql.trustServerCertificate()) throw invalid("TLS");
            String host = sql.serverName().toLowerCase(java.util.Locale.ROOT);
            if (host.equals("localhost") || host.equals("localhost.") || host.equals("(local)") || host.equals(".")
                    || host.equals("::1") || host.equals("[::1]") || host.equals("::") || host.equals("[::]")
                    || host.startsWith("127.") || host.equals("0.0.0.0")) throw invalid("SQL_EXTERNAL");
        } catch (IllegalStateException failure) {
            if (failure.getMessage() != null && failure.getMessage().matches("HP_PRODUCTION_[A-Z_]+")) throw failure;
            throw invalid("CONFIGURATION");
        } catch (RuntimeException ignored) { throw invalid("CONFIGURATION"); }
    }

    private static String property(ConfigurableEnvironment env, String key, String code) {
        try { return env.getProperty(key); }
        catch (RuntimeException ignored) { throw invalid(code); }
    }
    private static void require(ConfigurableEnvironment env, String key, String expected, String code) {
        if (!expected.equals(property(env, key, code))) throw invalid(code);
    }
    private static IllegalStateException invalid(String code) {
        return new IllegalStateException("HP_PRODUCTION_" + code);
    }
}
