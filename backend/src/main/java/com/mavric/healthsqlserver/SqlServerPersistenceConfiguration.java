package com.mavric.healthsqlserver;

import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.zaxxer.hikari.HikariDataSource;
import com.mavric.health.persistence.sqlserver.SqlServerExecutor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

/** Explicit import only, outside the legacy scan. Construction never starts the pool or borrows a connection. */
@Configuration(proxyBeanMethods=false)
@EnableConfigurationProperties(SqlServerRuntimeProperties.class)
public class SqlServerPersistenceConfiguration {
    @Bean(name={"dataSource","sqlServerRuntimeDataSource"},destroyMethod="close")
    HikariDataSource dataSource(SqlServerRuntimeProperties properties) {
        var driver=new SQLServerDataSource();
        driver.setServerName(properties.serverName());
        if(properties.port()!=null)driver.setPortNumber(properties.port());
        if(properties.instanceName()!=null)driver.setInstanceName(properties.instanceName());
        driver.setDatabaseName(properties.databaseName());
        driver.setUser(properties.username());
        driver.setPassword(properties.password());
        driver.setEncrypt("true");
        driver.setTrustServerCertificate(properties.trustServerCertificate());
        driver.setLoginTimeout(10);
        var pool=new HikariDataSource();
        pool.setDataSource(driver);
        pool.setPoolName("health-sqlserver-runtime");
        pool.setMaximumPoolSize(12);
        pool.setMinimumIdle(0);
        pool.setConnectionTimeout(10000);
        pool.setValidationTimeout(5000);
        pool.setAutoCommit(true);
        pool.setReadOnly(false);
        pool.setTransactionIsolation("TRANSACTION_READ_COMMITTED");
        pool.setInitializationFailTimeout(-1);
        pool.setConnectionTestQuery("EXEC dbo.usp_health_ready");
        pool.setConnectionInitSql(null);
        return pool;
    }
    @Bean(name={"transactionManager","sqlServerRuntimeTransactionManager"})
    DataSourceTransactionManager transactionManager(@Qualifier("sqlServerRuntimeDataSource") HikariDataSource pool) {
        return new DataSourceTransactionManager(pool);
    }
    @Bean(name={"jdbcTemplate","sqlServerRuntimeJdbcTemplate"})
    JdbcTemplate jdbcTemplate(@Qualifier("sqlServerRuntimeDataSource") HikariDataSource pool) {
        return new JdbcTemplate(pool);
    }
    @Bean(name="sqlServerRuntimeTransactionTemplate")
    TransactionTemplate transactionTemplate(@Qualifier("sqlServerRuntimeTransactionManager") DataSourceTransactionManager manager) {
        var template=new TransactionTemplate(manager);
        template.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRED);
        return template;
    }
    @Bean(name="sqlServerRuntimeExecutor")
    SqlServerExecutor executor(@Qualifier("sqlServerRuntimeJdbcTemplate") JdbcTemplate jdbc,ObjectMapper mapper) {
        return new SqlServerExecutor(jdbc,mapper,SqlServerExecutor.Purpose.RUNTIME);
    }
}
