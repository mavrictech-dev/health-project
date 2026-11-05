package com.mavric.healthsqlserver;

import com.mavric.health.identity.Access;
import com.mavric.health.portal.PortalService;
import com.mavric.health.scheduling.application.SchedulingService;
import com.mavric.health.persistence.sqlserver.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Complete portal constructor selection, without importing or activating any other configuration. */
@Configuration(proxyBeanMethods=false)
public class SqlServerPortalConfiguration {
    @Bean(name="portalService")
    PortalService portalService(
            @Qualifier("sqlServerPortalDocumentStore") SqlServerPortalDocumentStore documents,
            @Qualifier("sqlServerPortalAppointmentStore") SqlServerPortalAppointmentStore appointments,
            @Qualifier("sqlServerPortalPatientsStore") SqlServerPortalPatientsStore patients,
            @Qualifier("sqlServerPortalBalanceStore") SqlServerPortalBalanceStore balance,
            @Qualifier("access") Access access,
            @Qualifier("schedulingService") SchedulingService scheduling) {
        return new PortalService(documents,appointments,patients,balance,null,access,scheduling);
    }
}
