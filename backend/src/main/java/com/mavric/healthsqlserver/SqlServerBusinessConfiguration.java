package com.mavric.healthsqlserver;

import com.mavric.health.identity.Access;
import com.mavric.health.identity.IdentityService;
import com.mavric.health.tenancy.Settings;
import com.mavric.health.persistence.sqlserver.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.audit.AuditService;
import com.mavric.health.monitor.MonitorService;
import com.mavric.health.saas.application.PlatformService;
import com.mavric.health.organization.application.OrganizationService;
import com.mavric.health.patients.application.PatientService;
import com.mavric.health.scheduling.application.SchedulingService;
import com.mavric.health.clinical.application.ClinicalService;
import com.mavric.health.documents.application.DocumentService;
import com.mavric.health.billing.application.FinanceService;
import com.mavric.health.inventory.application.InventoryService;
import com.mavric.health.hospital.application.HospitalService;
import com.mavric.health.workflows.application.WorkflowService;

/** Explicit service selection only; no root imports, transaction AOP or job activation. */
@Configuration(proxyBeanMethods=false)
public class SqlServerBusinessConfiguration {
    @Bean(name="auditService")
    AuditService auditService(@Qualifier("sqlServerAuditStore") SqlServerAuditStore store,@Qualifier("access") Access access) {
        return new AuditService(store,access);
    }
    @Bean(name="monitorService")
    MonitorService monitorService(@Qualifier("sqlServerMonitorStore") SqlServerMonitorStore store,@Qualifier("access") Access access) {
        return new MonitorService(store,access);
    }
    @Bean(name="platformService")
    PlatformService platformService(@Qualifier("sqlServerPlatformStore") SqlServerPlatformStore store,@Qualifier("access") Access access,@Qualifier("identityService") IdentityService identity,Settings settings) {
        return new PlatformService(store,access,identity,settings);
    }
    @Bean(name="organizationService")
    OrganizationService organizationService(@Qualifier("sqlServerOrganizationStore") SqlServerOrganizationStore store,@Qualifier("access") Access access,@Qualifier("identityService") IdentityService identity) {
        return new OrganizationService(access,store,identity);
    }
    @Bean(name="patientService")
    PatientService patientService(@Qualifier("sqlServerPatientStore") SqlServerPatientStore store,@Qualifier("access") Access access,ObjectMapper mapper) {
        return new PatientService(store,access,mapper);
    }
    @Bean(name="schedulingService")
    SchedulingService schedulingService(@Qualifier("sqlServerSchedulingStore") SqlServerSchedulingStore store,@Qualifier("access") Access access) {
        return new SchedulingService(store,access);
    }
    @Bean(name="clinicalService")
    ClinicalService clinicalService(@Qualifier("sqlServerClinicalStore") SqlServerClinicalStore store,@Qualifier("access") Access access,ObjectMapper mapper) {
        return new ClinicalService(store,access,mapper);
    }
    @Bean(name="documentService")
    DocumentService documentService(@Qualifier("sqlServerDocumentStore") SqlServerDocumentStore store,@Qualifier("access") Access access) {
        return new DocumentService(store,access);
    }
    @Bean(name="financeService")
    FinanceService financeService(@Qualifier("sqlServerFinanceStore") SqlServerFinanceStore store,@Qualifier("access") Access access) {
        return new FinanceService(store,access);
    }
    @Bean(name="inventoryService")
    InventoryService inventoryService(@Qualifier("sqlServerInventoryStore") SqlServerInventoryStore store,@Qualifier("access") Access access) {
        return new InventoryService(store,null,access);
    }
    @Bean(name="hospitalService")
    HospitalService hospitalService(@Qualifier("sqlServerHospitalStore") SqlServerHospitalStore store,@Qualifier("access") Access access) {
        return new HospitalService(store,null,access);
    }
    @Bean(name="workflowService")
    WorkflowService workflowService(@Qualifier("sqlServerWorkflowStore") SqlServerWorkflowStore store,@Qualifier("access") Access access,ObjectMapper mapper) {
        return new WorkflowService(store,null,access,mapper);
    }
}
