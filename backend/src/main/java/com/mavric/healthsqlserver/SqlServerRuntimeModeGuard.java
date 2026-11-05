package com.mavric.healthsqlserver;

import java.util.*;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.beans.factory.support.*;
import org.springframework.boot.context.properties.bind.*;
import org.springframework.core.PriorityOrdered;
import org.springframework.core.env.Environment;

/** Fail closed before runtime singleton construction; values and binding causes never enter diagnostics. */
public final class SqlServerRuntimeModeGuard implements BeanDefinitionRegistryPostProcessor,PriorityOrdered {
    private final Environment environment;
    public SqlServerRuntimeModeGuard(Environment environment){this.environment=Objects.requireNonNull(environment);}
    @Override public int getOrder(){return HIGHEST_PRECEDENCE;}
    @Override public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry)throws BeansException {
        if(registry instanceof DefaultListableBeanFactory factory)factory.setAllowBeanDefinitionOverriding(false);
        try {
            require("health.sqlserver.mode","runtime");
            require("spring.flyway.enabled","false");
            require("spring.sql.init.mode","never");
            require("management.endpoint.health.probes.enabled","true");
            group("management.endpoint.health.group.liveness.include",Set.of("livenessState"));
            group("management.endpoint.health.group.readiness.include",Set.of("readinessState","db"));
            for(String key:List.of("migrate","setup","bootstrap","MIGRATE","SETUP","BOOTSTRAP","--migrate","--setup","--bootstrap"))
                if(environment.containsProperty(key))throw invalid();
            for(String key:List.of("MIGRATION_USER","MIGRATION_PASSWORD","spring.flyway.url","spring.flyway.user","spring.flyway.password","BOOTSTRAP_ADMIN_EMAIL","BOOTSTRAP_ADMIN_PASSWORD","health.bootstrap.email","health.bootstrap.password")) {
                String value=environment.getProperty(key);if(value!=null && !value.isEmpty())throw invalid();
            }
            optional("health.sqlserver.jobs.enabled","false");
            optional("spring.main.allow-bean-definition-overriding","false");
            optional("management.endpoint.health.show-details","never");
            optional("management.endpoint.health.show-components","never");
        } catch(RuntimeException failure) {throw invalid();}
    }
    @Override public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory)throws BeansException {
        if(beanFactory instanceof DefaultListableBeanFactory factory)factory.setAllowBeanDefinitionOverriding(false);
    }
    private void require(String key,String expected){if(!expected.equals(environment.getProperty(key)))throw invalid();}
    private void optional(String key,String expected){String value=environment.getProperty(key);if(value!=null && !expected.equals(value))throw invalid();}
    private void group(String key,Set<String> expected){List<String> values=Binder.get(environment).bind(key,Bindable.listOf(String.class)).orElse(List.of());var unique=new HashSet<>(values);if(unique.size()!=values.size() || !expected.equals(unique))throw invalid();}
    private static IllegalStateException invalid(){return new IllegalStateException("Unsafe SQL Server runtime configuration.");}
}
