package com.mavric.health.monitor;

import java.util.Objects;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.HealthIndicator;
import com.mavric.health.persistence.sqlserver.SqlServerMonitorStore;

/** Explicit adapter only; registration and readiness groups belong to future complete wiring. */
public final class SqlServerDatabaseHealthIndicator implements HealthIndicator {
    private final SqlServerMonitorStore store;

    public SqlServerDatabaseHealthIndicator(SqlServerMonitorStore store) {
        this.store=Objects.requireNonNull(store);
    }

    @Override public Health health() {
        try {
            store.ready();
            return Health.up().build();
        } catch(RuntimeException failure) {
            return Health.down().build();
        }
    }
}
