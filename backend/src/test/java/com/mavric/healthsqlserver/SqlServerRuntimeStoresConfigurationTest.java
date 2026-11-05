package com.mavric.healthsqlserver;

import java.util.*;
import java.lang.reflect.*;
import javax.sql.DataSource;
import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.zaxxer.hikari.HikariDataSource;
import com.mavric.health.persistence.sqlserver.*;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Construction/reference inspection only: no business methods, transactions, pool startup or database connections. */
class SqlServerRuntimeStoresConfigurationTest {
    static final Set<Class<?>> STORES=Set.of(SqlServerAccessStore.class,SqlServerAccountLifecycleStore.class,
            SqlServerAuditStore.class,SqlServerClinicalStore.class,SqlServerDocumentStore.class,
            SqlServerFinanceStore.class,SqlServerHospitalStore.class,SqlServerIdentityStore.class,
            SqlServerInventoryStore.class,SqlServerMailDeliveryStore.class,SqlServerMonitorStore.class,
            SqlServerOrganizationStore.class,SqlServerPatientStore.class,SqlServerPlatformStore.class,
            SqlServerPortalAppointmentStore.class,SqlServerPortalBalanceStore.class,SqlServerPortalDocumentStore.class,
            SqlServerPortalPatientsStore.class,SqlServerSchedulingStore.class,SqlServerSecurityStore.class,
            SqlServerSupportStore.class,SqlServerTraceStore.class,SqlServerWorkflowStore.class);
    static final Set<Class<?>> MAPPERS=Set.of(SqlServerClinicalStore.class,SqlServerDocumentStore.class,
            SqlServerFinanceStore.class,SqlServerHospitalStore.class,SqlServerInventoryStore.class,
            SqlServerPatientStore.class,SqlServerSchedulingStore.class,SqlServerWorkflowStore.class);
    static Object field(Object object,String name)throws Exception{var field=object.getClass().getDeclaredField(name);field.setAccessible(true);return field.get(object);}
    static String bean(Class<?> type){return Character.toLowerCase(type.getSimpleName().charAt(0))+type.getSimpleName().substring(1);}
    static int propagation(Class<?> type,String field){if(type==SqlServerTraceStore.class || type==SqlServerIdentityStore.class && field.equals("failed"))return TransactionDefinition.PROPAGATION_REQUIRES_NEW;if(type==SqlServerIdentityStore.class && field.equals("mandatory") || type==SqlServerAccountLifecycleStore.class && field.equals("registration"))return TransactionDefinition.PROPAGATION_MANDATORY;return TransactionDefinition.PROPAGATION_REQUIRED;}
    static void references(AnnotationConfigApplicationContext context,SqlServerExecutor executor,PlatformTransactionManager manager,TransactionTemplate shared,ObjectMapper mapper)throws Exception{
        assertEquals(23,STORES.size());var found=new HashSet<Class<?>>();int templates=0,mappers=0;
        for(Class<?> type:STORES){var beans=context.getBeansOfType(type);assertEquals(1,beans.size(),type.getSimpleName());Object store=beans.values().iterator().next();assertSame(store,context.getBean(bean(type)));assertSame(executor,field(store,"executor"));found.add(store.getClass());
            if(type==SqlServerSecurityStore.class){assertSame(shared,field(store,"transactions"));assertSame(manager,shared.getTransactionManager());assertEquals(TransactionDefinition.PROPAGATION_REQUIRED,shared.getPropagationBehavior());}
            for(var f:type.getDeclaredFields())if(TransactionTemplate.class.isAssignableFrom(f.getType())){f.setAccessible(true);var tx=(TransactionTemplate)f.get(store);assertSame(manager,tx.getTransactionManager());assertEquals(propagation(type,f.getName()),tx.getPropagationBehavior(),type.getSimpleName()+"."+f.getName());templates++;}
            if(MAPPERS.contains(type)){assertSame(mapper,field(store,"mapper"));mappers++;}
        }
        assertEquals(STORES,found);assertEquals(25,templates);assertEquals(8,mappers);
        assertTrue(context.getBeansOfType(SqlServerBootstrapStore.class).isEmpty());
        var actual=new HashSet<Class<?>>();for(String name:context.getBeanDefinitionNames()){var type=context.getType(name);if(type!=null && type.getName().startsWith("com.mavric.health.persistence.sqlserver.") && type.getSimpleName().endsWith("Store"))actual.add(type);}assertEquals(STORES,actual);
    }

    @Test void a54AndAll23StoresShareRealInfrastructureWithoutStartingPoolOrBorrowingConnections()throws Exception{
        var mapper=tools.jackson.databind.json.JsonMapper.builder().enable(tools.jackson.databind.SerializationFeature.INDENT_OUTPUT).build();
        try(var construction=mockConstruction(SQLServerDataSource.class);var context=SqlServerPersistenceConfigurationTest.context(SqlServerRuntimePropertiesTest.values(),mapper)){
            context.register(SqlServerRuntimeStoresConfiguration.class);context.refresh();
            var pool=context.getBean(HikariDataSource.class);var manager=context.getBean(DataSourceTransactionManager.class);var jdbc=context.getBean(JdbcTemplate.class);var executor=context.getBean(SqlServerExecutor.class);var template=context.getBean("sqlServerRuntimeTransactionTemplate",TransactionTemplate.class);
            references(context,executor,manager,template,mapper);
            assertEquals(1,context.getBeansOfType(DataSource.class).size());assertEquals(1,context.getBeansOfType(PlatformTransactionManager.class).size());assertEquals(1,context.getBeansOfType(JdbcTemplate.class).size());assertEquals(1,context.getBeansOfType(TransactionTemplate.class).size());assertEquals(1,context.getBeansOfType(SqlServerExecutor.class).size());
            assertSame(pool,jdbc.getDataSource());assertSame(pool,manager.getDataSource());assertSame(jdbc,field(executor,"jdbc"));assertSame(mapper,field(executor,"mapper"));assertEquals(SqlServerExecutor.Purpose.RUNTIME,field(executor,"purpose"));assertFalse(pool.isRunning());assertNull(pool.getHikariPoolMXBean());assertEquals(1,construction.constructed().size());var driver=construction.constructed().getFirst();verify(driver,never()).getConnection();verify(driver,never()).getConnection(anyString(),anyString());
            var allowed=new HashSet<Class<?>>(STORES);allowed.addAll(Set.of(SqlServerRuntimeStoresConfiguration.class,SqlServerPersistenceConfiguration.class,SqlServerRuntimeProperties.class,SqlServerExecutor.class));var actual=new HashSet<Class<?>>();for(String name:context.getBeanDefinitionNames()){var type=context.getType(name);if(type!=null && type.getName().startsWith("com.mavric."))actual.add(type);}assertEquals(allowed,actual);
            assertTrue(Arrays.stream(context.getBeanDefinitionNames()).noneMatch(name->name.toLowerCase(Locale.ROOT).contains("flyway") || name.toLowerCase(Locale.ROOT).contains("scheduled")));
        }
    }

    @Test void qualifiedDoubleInfrastructureConstructsStoresWithoutAnyExecutionOrTransaction()throws Exception{
        var executor=mock(SqlServerExecutor.class);var manager=mock(PlatformTransactionManager.class);var template=new TransactionTemplate(manager);var mapper=new ObjectMapper();
        try(var context=new AnnotationConfigApplicationContext()){
            context.registerBean("sqlServerRuntimeExecutor",SqlServerExecutor.class,()->executor);context.registerBean("sqlServerRuntimeTransactionManager",PlatformTransactionManager.class,()->manager);context.registerBean("sqlServerRuntimeTransactionTemplate",TransactionTemplate.class,()->template);context.registerBean(ObjectMapper.class,()->mapper);
            var decoy=mock(SqlServerExecutor.class);var otherManager=mock(PlatformTransactionManager.class);var otherTemplate=new TransactionTemplate(otherManager);
            context.registerBean("otherExecutor",SqlServerExecutor.class,()->decoy);context.registerBean("otherManager",PlatformTransactionManager.class,()->otherManager);context.registerBean("otherTemplate",TransactionTemplate.class,()->otherTemplate);
            context.register(SqlServerRuntimeStoresConfiguration.class);context.refresh();references(context,executor,manager,template,mapper);verifyNoInteractions(executor,manager,decoy,otherManager);
        }
    }

    @Test void missingQualifiedDependenciesFailEvenWithUnqualifiedDecoysAndNoFallback(){
        for(String missing:List.of("executor","manager","template","mapper")){
            var executor=mock(SqlServerExecutor.class);var manager=mock(PlatformTransactionManager.class);var shared=new TransactionTemplate(manager);
            try(var context=new AnnotationConfigApplicationContext()){
                context.registerBean(missing.equals("executor")?"otherExecutor":"sqlServerRuntimeExecutor",SqlServerExecutor.class,()->executor);
                context.registerBean(missing.equals("manager")?"otherManager":"sqlServerRuntimeTransactionManager",PlatformTransactionManager.class,()->manager);
                context.registerBean(missing.equals("template")?"otherTemplate":"sqlServerRuntimeTransactionTemplate",TransactionTemplate.class,()->shared);
                if(!missing.equals("mapper"))context.registerBean(ObjectMapper.class,()->new ObjectMapper());
                context.register(SqlServerRuntimeStoresConfiguration.class);assertThrows(RuntimeException.class,context::refresh);verifyNoInteractions(executor,manager);
            }
        }
    }

    @Test void explicitFactoryInventoryAndDefaultLegacyScanCannotImportPartialGraph(){
        var annotation=SqlServerRuntimeStoresConfiguration.class.getAnnotation(Configuration.class);assertNotNull(annotation);assertFalse(annotation.proxyBeanMethods());assertEquals(1,SqlServerRuntimeStoresConfiguration.class.getDeclaredAnnotations().length);
        var methods=Arrays.stream(SqlServerRuntimeStoresConfiguration.class.getDeclaredMethods()).filter(method->method.isAnnotationPresent(Bean.class)).toList();assertEquals(23,methods.size());assertEquals(STORES,new HashSet<>(methods.stream().map(Method::getReturnType).toList()));
        for(var method:methods)assertArrayEquals(new String[]{bean(method.getReturnType())},method.getAnnotation(Bean.class).name());
        var candidates=new ClassPathScanningCandidateComponentProvider(true).findCandidateComponents("com.mavric.health");assertTrue(candidates.stream().noneMatch(candidate->candidate.getBeanClassName().startsWith("com.mavric.healthsqlserver.")));
        try(var context=new AnnotationConfigApplicationContext()) {context.registerBean(ObjectMapper.class,()->new ObjectMapper());context.refresh();assertTrue(STORES.stream().allMatch(type->context.getBeansOfType(type).isEmpty()));}
    }
}
