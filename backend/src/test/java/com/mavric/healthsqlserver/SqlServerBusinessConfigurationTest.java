package com.mavric.healthsqlserver;

import java.util.*;
import java.lang.reflect.*;
import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.zaxxer.hikari.HikariDataSource;
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
import com.mavric.health.portal.PortalService;
import com.mavric.health.identity.*;
import com.mavric.health.tenancy.Settings;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.audit.TraceContext;
import org.junit.jupiter.api.*;
import org.springframework.context.annotation.*;
import org.springframework.core.env.MapPropertySource;
import org.springframework.mock.web.MockServletContext;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.support.*;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Explicit composition/reference inspection, without Boot, transactions, connections or scheduled jobs. */
class SqlServerBusinessConfigurationTest {
    static final Map<Class<?>,Class<?>> SERVICES=Map.ofEntries(Map.entry(AuditService.class,SqlServerAuditStore.class),Map.entry(MonitorService.class,SqlServerMonitorStore.class),Map.entry(PlatformService.class,SqlServerPlatformStore.class),Map.entry(OrganizationService.class,SqlServerOrganizationStore.class),Map.entry(PatientService.class,SqlServerPatientStore.class),Map.entry(SchedulingService.class,SqlServerSchedulingStore.class),Map.entry(ClinicalService.class,SqlServerClinicalStore.class),Map.entry(DocumentService.class,SqlServerDocumentStore.class),Map.entry(FinanceService.class,SqlServerFinanceStore.class),Map.entry(InventoryService.class,SqlServerInventoryStore.class),Map.entry(HospitalService.class,SqlServerHospitalStore.class),Map.entry(WorkflowService.class,SqlServerWorkflowStore.class));
    static Object field(Object object,String name)throws Exception{var f=object.getClass().getDeclaredField(name);f.setAccessible(true);return f.get(object);}
    static String name(Class<?> type){return Character.toLowerCase(type.getSimpleName().charAt(0))+type.getSimpleName().substring(1);}
    static Settings settings(){return new Settings("health.localhost","http://health.localhost:8080",8,null);}
    static AnnotationConfigWebApplicationContext webGraph(ObjectMapper mapper,Settings settings){var context=new AnnotationConfigWebApplicationContext();context.setServletContext(new MockServletContext());context.getEnvironment().getPropertySources().addFirst(new MapPropertySource("synthetic",SqlServerRuntimePropertiesTest.values()));context.addBeanFactoryPostProcessor(factory->{factory.registerSingleton("mapper",mapper);factory.registerSingleton("settings",settings);});context.register(SqlServerPersistenceConfiguration.class,SqlServerRuntimeStoresConfiguration.class,SqlServerIdentityConfiguration.class,SqlServerSecurityConfiguration.class,SqlServerBusinessConfiguration.class,SqlServerPortalConfiguration.class);return context;}
    static Map<String,Object> doubles(){var deps=new LinkedHashMap<String,Object>();deps.put("access",mock(Access.class));deps.put("identityService",mock(IdentityService.class));deps.put("settings",settings());deps.put("mapper",new ObjectMapper());for(Class<?> type:SERVICES.values())deps.put(name(type),mock(type));return deps;}
    @AfterEach void clean(){RequestContextHolder.resetRequestAttributes();TraceContext.REQUEST.remove();SecurityContextHolder.clearContext();TransactionSynchronizationManager.clear();}
    @Test void fullA54ToA57GraphUsesOnlyCompleteSqlServicesSharedDependenciesAndDormantPool()throws Exception{var mapper=new ObjectMapper();var settings=settings();try(var construction=mockConstruction(SQLServerDataSource.class);var context=webGraph(mapper,settings)){context.refresh();assertEquals(12,SERVICES.size());var access=context.getBean(Access.class);var identity=context.getBean(IdentityService.class);for(var entry:SERVICES.entrySet()){var beans=context.getBeansOfType(entry.getKey());assertEquals(1,beans.size());var service=beans.values().iterator().next();assertSame(service,context.getBean(name(entry.getKey())));assertSame(context.getBean(entry.getValue()),field(service,"store"));assertSame(access,field(service,"access"));assertNull(field(service,"sql"));}for(Class<?> type:List.of(PatientService.class,ClinicalService.class,WorkflowService.class))assertSame(mapper,field(context.getBean(type),"mapper"));assertSame(identity,field(context.getBean(PlatformService.class),"identities"));assertSame(identity,field(context.getBean(OrganizationService.class),"identities"));assertSame(settings,field(context.getBean(PlatformService.class),"settings"));var portal=context.getBean(PortalService.class);assertSame(context.getBean(SchedulingService.class),field(portal,"scheduling"));assertNull(field(portal,"sql"));assertSame(access,field(portal,"access"));for(var pair:Map.of("store",SqlServerPortalDocumentStore.class,"appointmentStore",SqlServerPortalAppointmentStore.class,"patientsStore",SqlServerPortalPatientsStore.class,"balanceStore",SqlServerPortalBalanceStore.class).entrySet())assertSame(context.getBean(pair.getValue()),field(portal,pair.getKey()));var executor=context.getBean(SqlServerExecutor.class);var manager=context.getBean(DataSourceTransactionManager.class);var pool=context.getBean(HikariDataSource.class);assertSame(pool,manager.getDataSource());assertSame(pool,context.getBean(JdbcTemplate.class).getDataSource());assertSame(context.getBean(JdbcTemplate.class),field(executor,"jdbc"));assertEquals(SqlServerExecutor.Purpose.RUNTIME,field(executor,"purpose"));for(Class<?> type:SqlServerRuntimeStoresConfigurationTest.STORES){var store=context.getBean(type);assertSame(executor,field(store,"executor"));for(Field f:type.getDeclaredFields())if(TransactionTemplate.class.isAssignableFrom(f.getType())){f.setAccessible(true);assertSame(manager,((TransactionTemplate)f.get(store)).getTransactionManager());}}assertSame(context.getBean("sqlServerRuntimeTransactionTemplate"),field(context.getBean(SqlServerSecurityStore.class),"transactions"));assertFalse(pool.isRunning());assertNull(pool.getHikariPoolMXBean());assertEquals(1,construction.constructed().size());verify(construction.constructed().getFirst(),never()).getConnection();verify(construction.constructed().getFirst(),never()).getConnection(anyString(),anyString());for(Class<?> type:List.of(com.mavric.health.shared.Sql.class,AttemptRecorder.class,Bootstrap.class,MailDelivery.class,com.mavric.health.monitor.SqlServerDatabaseHealthIndicator.class))assertTrue(context.getBeansOfType(type).isEmpty());assertTrue(Arrays.stream(context.getBeanDefinitionNames()).noneMatch(bean->bean.toLowerCase(Locale.ROOT).contains("scheduled") || bean.toLowerCase(Locale.ROOT).contains("flyway") || bean.contains("transactionAdvisor")));}}
    @Test void storeQualifiersAndSharedIdentityAccessDoNotChooseUnqualifiedDecoys()throws Exception{var deps=doubles();var decoy=mock(SqlServerAuditStore.class);try(var context=new AnnotationConfigApplicationContext()){deps.forEach((name,value)->context.getBeanFactory().registerSingleton(name,value));context.getBeanFactory().registerSingleton("otherAuditStore",decoy);context.register(SqlServerBusinessConfiguration.class);context.refresh();assertSame(deps.get("sqlServerAuditStore"),field(context.getBean(AuditService.class),"store"));assertSame(deps.get("identityService"),field(context.getBean(PlatformService.class),"identities"));assertSame(deps.get("identityService"),field(context.getBean(OrganizationService.class),"identities"));verifyNoInteractions(decoy);for(Class<?> type:SERVICES.values())verifyNoInteractions(deps.get(name(type)));}}
    @Test void missingRequiredCollaboratorsFailWithoutSqlOrDefaults(){for(String missing:List.of("sqlServerAuditStore","access","identityService","settings","mapper")){var deps=doubles();deps.remove(missing);if(missing.equals("sqlServerAuditStore"))deps.put("otherAuditStore",mock(SqlServerAuditStore.class));try(var context=new AnnotationConfigApplicationContext()){deps.forEach((name,value)->context.getBeanFactory().registerSingleton(name,value));context.register(SqlServerBusinessConfiguration.class);assertThrows(RuntimeException.class,context::refresh);}}}
    @Test void onlyTwelveExplicitFactoriesAndNoLegacyScanOrAutomaticActivation(){assertEquals(1,SqlServerBusinessConfiguration.class.getDeclaredAnnotations().length);assertFalse(SqlServerBusinessConfiguration.class.getAnnotation(Configuration.class).proxyBeanMethods());var methods=Arrays.stream(SqlServerBusinessConfiguration.class.getDeclaredMethods()).filter(method->method.isAnnotationPresent(Bean.class)).toList();assertEquals(12,methods.size());assertEquals(SERVICES.keySet(),new HashSet<>(methods.stream().map(Method::getReturnType).toList()));for(var method:methods)assertArrayEquals(new String[]{name(method.getReturnType())},method.getAnnotation(Bean.class).name());assertTrue(new ClassPathScanningCandidateComponentProvider(true).findCandidateComponents("com.mavric.health").stream().noneMatch(bean->bean.getBeanClassName().startsWith("com.mavric.healthsqlserver.")));}
}
