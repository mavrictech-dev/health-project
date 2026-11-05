package com.mavric.health;

import java.util.*;
import com.mavric.health.tenancy.Settings;
import com.mavric.healthsqlserver.*;
import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.zaxxer.hikari.HikariDataSource;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.bootstrap.DefaultBootstrapContext;
import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.boot.context.properties.bind.*;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.boot.support.EnvironmentPostProcessorApplicationListener;
import org.springframework.core.Ordered;
import org.springframework.core.env.*;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.scheduling.annotation.EnableScheduling;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class HealthApplicationModeTest {
    static final String CANARY="synthetic-private-password-canary";
    static MockEnvironment runtime(){return new MockEnvironment()
            .withProperty("health.sqlserver.mode","runtime").withProperty("spring.flyway.enabled","false")
            .withProperty("spring.sql.init.mode","never").withProperty("management.endpoint.health.probes.enabled","true")
            .withProperty("management.endpoint.health.group.liveness.include","livenessState")
            .withProperty("management.endpoint.health.group.readiness.include","readinessState,db");}
    static ApplicationEnvironmentPreparedEvent event(SpringApplication application,ConfigurableEnvironment environment){return new ApplicationEnvironmentPreparedEvent(new DefaultBootstrapContext(),application,new String[0],environment);}
    static void safe(Throwable failure,String message){assertEquals(message,failure.getMessage());assertNull(failure.getCause());assertFalse(failure.toString().contains(CANARY));}
    static void rejected(ConfigurableEnvironment environment){var application=new SpringApplication();var selector=new SqlServerApplicationSourceSelector(application);safe(assertThrows(IllegalStateException.class,()->selector.onApplicationEvent(event(application,environment))),"Unsafe application source selection.");assertTrue(application.getAllSources().isEmpty());}

    @Test void mainKeepsLegacyAnnotationsAndRegistersBoundListenerOnAnEmptyApplicationWithoutRunningIt(){
        assertTrue(HealthApplication.class.isAnnotationPresent(SpringBootApplication.class));
        assertTrue(HealthApplication.class.isAnnotationPresent(ConfigurationPropertiesScan.class));
        assertTrue(HealthApplication.class.isAnnotationPresent(EnableScheduling.class));
        String[] arguments={"--spring.profiles.active=sqlserver-qa","--health.sqlserver.mode=runtime"};
        try(var applications=mockConstruction(SpringApplication.class,(application,context)->{
            assertEquals(1,context.arguments().size());assertEquals(0,((Class<?>[])context.arguments().get(0)).length);
        })) {
            HealthApplication.main(arguments);assertEquals(1,applications.constructed().size());var application=applications.constructed().getFirst();
            var listener=org.mockito.ArgumentCaptor.forClass(SqlServerApplicationSourceSelector.class);
            var order=inOrder(application);order.verify(application).addListeners(listener.capture());order.verify(application).run(same(arguments));order.verifyNoMoreInteractions();
            var other=new SpringApplication();listener.getValue().onApplicationEvent(event(other,new MockEnvironment()));assertTrue(other.getAllSources().isEmpty());
        }
    }
    @Test void dangerousFlagsFailBeforeSpringOrFlywayRegardlessOfCaseOrAssignedValue(){
        try(var applications=mockConstruction(SpringApplication.class);var flyway=mockStatic(Flyway.class)) {
            for(String flag:List.of("--migrate","--setup","--bootstrap","--MIGRATE","--SeTuP","--BOOTSTRAP"))
                for(String suffix:List.of("","=","=false","="+CANARY))
                    safe(assertThrows(IllegalArgumentException.class,()->HealthApplication.main(new String[]{"--ordinary=value",flag+suffix})),"Use the separate migration/setup process.");
            assertTrue(applications.constructed().isEmpty());flyway.verifyNoInteractions();
        }
    }
    @Test void effectiveEnvironmentSelectsExactlyOneRootAndRunsAfterConfigDataWithoutInfrastructure(){
        try(var pools=mockConstruction(HikariDataSource.class);var drivers=mockConstruction(SQLServerDataSource.class)){
            for(boolean sql:List.of(false,true)){
                var application=new SpringApplication();var selector=new SqlServerApplicationSourceSelector(application);
                assertEquals(Ordered.LOWEST_PRECEDENCE,selector.getOrder());assertTrue(selector.getOrder()>EnvironmentPostProcessorApplicationListener.DEFAULT_ORDER);
                selector.onApplicationEvent(event(application,sql?runtime():new MockEnvironment()));
                assertEquals(Set.of(sql?SqlServerRuntimeRoot.class:HealthApplication.class),application.getAllSources());
            }
            assertTrue(pools.constructed().isEmpty());assertTrue(drivers.constructed().isEmpty());
        }
    }
    @Test void invalidModesAndUnsafeRuntimeNeverFallBackOrExposeValues(){
        for(String mode:List.of(""," ","RUNTIME","legacy",CANARY))rejected(runtime().withProperty("health.sqlserver.mode",mode));
        for(var invalid:List.of(Map.entry("spring.flyway.enabled","true"),Map.entry("spring.sql.init.mode","always"),Map.entry("setup","false"),Map.entry("MIGRATION_PASSWORD",CANARY),Map.entry("management.endpoint.health.group.readiness.include","*")))
            rejected(runtime().withProperty(invalid.getKey(),invalid.getValue()));
    }
    @Test void preexistingSourcesAndScalarIndexedOrEnvironmentBoundExternalSourcesCannotMixRoots(){
        for(boolean sql:List.of(false,true)){
            var application=new SpringApplication(HealthApplication.class);var selector=new SqlServerApplicationSourceSelector(application);
            safe(assertThrows(IllegalStateException.class,()->selector.onApplicationEvent(event(application,sql?runtime():new MockEnvironment()))),"Unsafe application source selection.");assertEquals(Set.of(HealthApplication.class),application.getAllSources());
            for(var source:List.of(Map.entry("spring.main.sources",HealthApplication.class.getName()),Map.entry("spring.main.sources",""),Map.entry("spring.main.sources[0]",HealthApplication.class.getName()),Map.entry("spring.main.sources[1]",CANARY),Map.entry("spring.main.sources[0]",CANARY)))
                rejected((sql?runtime():new MockEnvironment()).withProperty(source.getKey(),source.getValue()));
            var environment=sql?runtime():new MockEnvironment();environment.getPropertySources().addFirst(new SystemEnvironmentPropertySource("synthetic-scalar-systemEnvironment",Map.of("SPRING_MAIN_SOURCES",HealthApplication.class.getName())));rejected(environment);
            var indexed=sql?runtime():new MockEnvironment();indexed.getPropertySources().addFirst(new SystemEnvironmentPropertySource("synthetic-indexed-systemEnvironment",Map.of("SPRING_MAIN_SOURCES_0_",HealthApplication.class.getName())));rejected(indexed);
        }
    }
    @Test void foreignEventDoesNothingAndOwnRepeatedEventFailsWithoutAddingAnotherRoot(){
        var application=new SpringApplication();var other=new SpringApplication();var selector=new SqlServerApplicationSourceSelector(application);
        selector.onApplicationEvent(event(other,runtime()));assertTrue(application.getAllSources().isEmpty());assertTrue(other.getAllSources().isEmpty());
        selector.onApplicationEvent(event(application,runtime()));assertEquals(Set.of(SqlServerRuntimeRoot.class),application.getAllSources());
        safe(assertThrows(IllegalStateException.class,()->selector.onApplicationEvent(event(application,new MockEnvironment()))),"Unsafe application source selection.");assertEquals(Set.of(SqlServerRuntimeRoot.class),application.getAllSources());
    }
    static MockEnvironment profile(Map<String,Object> external)throws Exception{
        var environment=new MockEnvironment();var loader=new YamlPropertySourceLoader();
        for(var source:loader.load("base",new ClassPathResource("application.yml")))environment.getPropertySources().addLast(source);
        var qa=loader.load("qa",new ClassPathResource("application-sqlserver-qa.yml"));for(int i=qa.size()-1;i>=0;i--)environment.getPropertySources().addFirst(qa.get(i));
        environment.getPropertySources().addFirst(new MapPropertySource("synthetic-inputs",external));return environment;
    }
    static SqlServerRuntimeProperties properties(ConfigurableEnvironment environment){return Binder.get(environment).bind("health.sqlserver.runtime",Bindable.of(SqlServerRuntimeProperties.class)).get();}
    @Test void qaYamlOverridesLegacyDefaultsBindsWithSyntheticInputsAndSelectsSqlFromProfile()throws Exception{
        for(boolean customPort:List.of(false,true)){
            var inputs=new LinkedHashMap<String,Object>();inputs.put("HEALTH_SQLSERVER_DATABASE","synthetic_qa");inputs.put("HEALTH_SQLSERVER_RUNTIME_USER","synthetic_runtime");inputs.put("HEALTH_SQLSERVER_RUNTIME_PASSWORD",CANARY);if(customPort)inputs.put("HEALTH_SQLSERVER_HTTP_PORT","18081");
            var environment=profile(inputs);var application=new SpringApplication();new SqlServerApplicationSourceSelector(application).onApplicationEvent(event(application,environment));assertEquals(Set.of(SqlServerRuntimeRoot.class),application.getAllSources());
            new SqlServerRuntimeModeGuard(environment).postProcessBeanDefinitionRegistry(new DefaultListableBeanFactory());
            var runtime=properties(environment);assertEquals("127.0.0.1",runtime.serverName());assertEquals(1433,runtime.port());assertNull(runtime.instanceName());assertEquals(false,runtime.trustServerCertificate());assertEquals("synthetic_qa",runtime.databaseName());assertEquals("synthetic_runtime",runtime.username());assertTrue(CANARY.equals(runtime.password()));
            var settings=Binder.get(environment).bind("health",Bindable.of(Settings.class)).get();int port=customPort?18081:18080;
            assertEquals("health.localhost",settings.baseDomain());assertEquals("http://health.localhost:"+port,settings.publicOrigin());assertEquals(8,settings.sessionHours());assertEquals(port,environment.getProperty("server.port",Integer.class));assertEquals("127.0.0.1",environment.getProperty("server.address"));assertEquals("none",environment.getProperty("server.forward-headers-strategy"));assertEquals("false",environment.getProperty("health.sqlserver.jobs.enabled"));
            for(String key:List.of("spring.datasource.url","spring.datasource.username","spring.datasource.password","spring.flyway.url","spring.flyway.user","spring.flyway.password","health.bootstrap.email","health.bootstrap.password"))assertEquals("",environment.getProperty(key));
            for(String key:List.of("management.endpoint.health.show-details","management.endpoint.health.show-components"))assertEquals("never",environment.getProperty(key));
            assertNull(environment.getProperty("DATABASE_PASSWORD"));assertNull(environment.getProperty("health.sqlserver.runtime.port"));assertNull(environment.getProperty("health.sqlserver.runtime.instance-name"));
        }
    }
    @Test void qaHasNoRequiredDatabaseOrCredentialDefaultsAndHigherPriorityModeAlwaysWins()throws Exception{
        var noInputs=profile(Map.of());for(String key:List.of("database-name","username","password"))assertEquals("",noInputs.getProperty("health.sqlserver.runtime."+key));assertThrows(RuntimeException.class,()->properties(noInputs));
        for(String missing:List.of("HEALTH_SQLSERVER_DATABASE","HEALTH_SQLSERVER_RUNTIME_USER","HEALTH_SQLSERVER_RUNTIME_PASSWORD")){
            var inputs=new HashMap<String,Object>(Map.of("HEALTH_SQLSERVER_DATABASE","synthetic_qa","HEALTH_SQLSERVER_RUNTIME_USER","synthetic_runtime","HEALTH_SQLSERVER_RUNTIME_PASSWORD",CANARY));inputs.remove(missing);assertThrows(RuntimeException.class,()->properties(profile(inputs)));
        }
        rejected(profile(Map.of("health.sqlserver.mode",CANARY)));
        var absent=new SpringApplication();var environment=profile(Map.of("health.sqlserver.mode","runtime"));new SqlServerApplicationSourceSelector(absent).onApplicationEvent(event(absent,environment));assertEquals(Set.of(SqlServerRuntimeRoot.class),absent.getAllSources());
    }
}
