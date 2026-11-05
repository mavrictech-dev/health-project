package com.mavric.healthsqlserver;

import java.util.List;
import java.util.Objects;
import com.mavric.health.HealthApplication;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.context.ApplicationListener;
import org.springframework.core.Ordered;

/** Selects one root after ConfigData has prepared this application's effective environment. */
public final class SqlServerApplicationSourceSelector implements ApplicationListener<ApplicationEnvironmentPreparedEvent>,Ordered {
    private final SpringApplication application;
    private boolean selected;

    public SqlServerApplicationSourceSelector(SpringApplication application){this.application=Objects.requireNonNull(application);}
    @Override public int getOrder(){return LOWEST_PRECEDENCE;}
    @Override public void onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        if(event.getSpringApplication()!=application)return;
        try {
            var environment=event.getEnvironment();
            if(selected || !application.getAllSources().isEmpty()
                    || environment.containsProperty("spring.main.sources")
                    || Binder.get(environment).bind("spring.main.sources",Bindable.setOf(String.class)).isBound())throw invalid();
            String mode=environment.getProperty("health.sqlserver.mode");
            Class<?> source;
            if(mode==null)source=HealthApplication.class;
            else if("runtime".equals(mode)) {
                new SqlServerRuntimeModeGuard(environment).postProcessBeanDefinitionRegistry(new DefaultListableBeanFactory());
                source=SqlServerRuntimeRoot.class;
            } else throw invalid();
            application.addPrimarySources(List.of(source));
            selected=true;
        } catch(RuntimeException failure){throw invalid();}
    }
    private static IllegalStateException invalid(){return new IllegalStateException("Unsafe application source selection.");}
}
