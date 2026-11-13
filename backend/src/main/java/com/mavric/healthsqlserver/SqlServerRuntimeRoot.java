package com.mavric.healthsqlserver;

import com.mavric.health.tenancy.Settings;
import com.mavric.health.monitor.SqlServerDatabaseHealthIndicator;
import com.mavric.health.persistence.sqlserver.SqlServerMonitorStore;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.*;
import org.springframework.core.env.Environment;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/** Complete explicit root, deliberately not selected by the legacy launcher or component scan. */
@Configuration(proxyBeanMethods=false)
@EnableAutoConfiguration(exclude={
        org.springframework.boot.flyway.autoconfigure.FlywayAutoConfiguration.class,
        org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration.class,
        org.springframework.boot.jdbc.autoconfigure.JdbcTemplateAutoConfiguration.class,
        org.springframework.boot.jdbc.autoconfigure.DataSourceTransactionManagerAutoConfiguration.class,
        org.springframework.boot.jdbc.autoconfigure.DataSourceInitializationAutoConfiguration.class,
        org.springframework.boot.jdbc.autoconfigure.health.DataSourceHealthContributorAutoConfiguration.class,
        org.springframework.boot.mail.autoconfigure.MailSenderAutoConfiguration.class,
        org.springframework.boot.transaction.autoconfigure.TransactionAutoConfiguration.class})
@EnableConfigurationProperties(Settings.class)
@EnableTransactionManagement(proxyTargetClass=true)
@Import({SqlServerPersistenceConfiguration.class,SqlServerRuntimeStoresConfiguration.class,
        SqlServerIdentityConfiguration.class,SqlServerSecurityConfiguration.class,
        SqlServerBusinessConfiguration.class,SqlServerPortalConfiguration.class,SqlServerCardsConfiguration.class,
        com.mavric.health.audit.AuditController.class,com.mavric.health.audit.TraceController.class,
        com.mavric.health.billing.api.FinanceController.class,com.mavric.health.clinical.api.ClinicalController.class,
        com.mavric.health.documents.api.DocumentController.class,com.mavric.health.hospital.api.HospitalController.class,
        com.mavric.health.identity.AccountLifecycleController.class,com.mavric.health.identity.AuthController.class,
        com.mavric.health.inventory.api.InventoryController.class,com.mavric.health.monitor.MonitorController.class,
        com.mavric.health.organization.api.OrganizationController.class,com.mavric.health.patients.api.PatientController.class,
        com.mavric.health.portal.PortalController.class,com.mavric.health.saas.api.PlatformController.class,
        com.mavric.health.scheduling.api.SchedulingController.class,com.mavric.health.workflows.api.WorkflowController.class})
public class SqlServerRuntimeRoot {
    @Bean static SqlServerRuntimeModeGuard sqlServerRuntimeModeGuard(Environment environment){return new SqlServerRuntimeModeGuard(environment);}
    @Bean SqlServerDatabaseHealthIndicator dbHealthIndicator(@Qualifier("sqlServerMonitorStore") SqlServerMonitorStore store){return new SqlServerDatabaseHealthIndicator(store);}
}
