package com.mavric.healthsqlserver;

import com.mavric.health.persistence.sqlserver.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;

/** Explicit runtime store factories only. The future complete root must supply the qualified A54 infrastructure. */
@Configuration(proxyBeanMethods=false)
public class SqlServerRuntimeStoresConfiguration {
    @Bean(name="sqlServerAccessStore")
    SqlServerAccessStore sqlServerAccessStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerAccessStore(executor,manager);
    }
    @Bean(name="sqlServerAccountLifecycleStore")
    SqlServerAccountLifecycleStore sqlServerAccountLifecycleStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerAccountLifecycleStore(executor,manager);
    }
    @Bean(name="sqlServerAuditStore")
    SqlServerAuditStore sqlServerAuditStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerAuditStore(executor,manager);
    }
    @Bean(name="sqlServerClinicalStore")
    SqlServerClinicalStore sqlServerClinicalStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerClinicalStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerDocumentStore")
    SqlServerDocumentStore sqlServerDocumentStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerDocumentStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerFinanceStore")
    SqlServerFinanceStore sqlServerFinanceStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerFinanceStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerHospitalStore")
    SqlServerHospitalStore sqlServerHospitalStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerHospitalStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerIdentityStore")
    SqlServerIdentityStore sqlServerIdentityStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerIdentityStore(executor,manager);
    }
    @Bean(name="sqlServerInventoryStore")
    SqlServerInventoryStore sqlServerInventoryStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerInventoryStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerMailDeliveryStore")
    SqlServerMailDeliveryStore sqlServerMailDeliveryStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerMailDeliveryStore(executor,manager);
    }
    @Bean(name="sqlServerMonitorStore")
    SqlServerMonitorStore sqlServerMonitorStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerMonitorStore(executor,manager);
    }
    @Bean(name="sqlServerOrganizationStore")
    SqlServerOrganizationStore sqlServerOrganizationStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerOrganizationStore(executor,manager);
    }
    @Bean(name="sqlServerPatientStore")
    SqlServerPatientStore sqlServerPatientStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerPatientStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerPlatformStore")
    SqlServerPlatformStore sqlServerPlatformStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerPlatformStore(executor,manager);
    }
    @Bean(name="sqlServerPortalAppointmentStore")
    SqlServerPortalAppointmentStore sqlServerPortalAppointmentStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerPortalAppointmentStore(executor,manager);
    }
    @Bean(name="sqlServerPortalBalanceStore")
    SqlServerPortalBalanceStore sqlServerPortalBalanceStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerPortalBalanceStore(executor,manager);
    }
    @Bean(name="sqlServerPortalDocumentStore")
    SqlServerPortalDocumentStore sqlServerPortalDocumentStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerPortalDocumentStore(executor,manager);
    }
    @Bean(name="sqlServerPortalPatientsStore")
    SqlServerPortalPatientsStore sqlServerPortalPatientsStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerPortalPatientsStore(executor,manager);
    }
    @Bean(name="sqlServerSchedulingStore")
    SqlServerSchedulingStore sqlServerSchedulingStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerSchedulingStore(executor,manager,mapper);
    }
    @Bean(name="sqlServerSecurityStore")
    SqlServerSecurityStore sqlServerSecurityStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionTemplate") TransactionTemplate transactions) {
        return new SqlServerSecurityStore(executor,transactions);
    }
    @Bean(name="sqlServerSupportStore")
    SqlServerSupportStore sqlServerSupportStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerSupportStore(executor,manager);
    }
    @Bean(name="sqlServerTraceStore")
    SqlServerTraceStore sqlServerTraceStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager) {
        return new SqlServerTraceStore(executor,manager);
    }
    @Bean(name="sqlServerWorkflowStore")
    SqlServerWorkflowStore sqlServerWorkflowStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper) {
        return new SqlServerWorkflowStore(executor,manager,mapper);
    }
}
