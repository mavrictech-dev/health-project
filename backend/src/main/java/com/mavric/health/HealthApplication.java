package com.mavric.health;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
@org.springframework.scheduling.annotation.EnableScheduling
public class HealthApplication {
    public static void main(String[] args) {
        for(String argument:args) {
            String flag=argument.split("=",2)[0];
            if(flag.equalsIgnoreCase("--migrate") || flag.equalsIgnoreCase("--setup") || flag.equalsIgnoreCase("--bootstrap"))
                throw new IllegalArgumentException("Use the separate migration/setup process.");
        }
        SpringApplication application=new SpringApplication();
        application.addListeners(new com.mavric.healthsqlserver.SqlServerApplicationSourceSelector(application));
        application.run(args);
    }
}
