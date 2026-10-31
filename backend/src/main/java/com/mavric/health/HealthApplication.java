package com.mavric.health;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
@org.springframework.scheduling.annotation.EnableScheduling
public class HealthApplication {
    public static void main(String[] args) {
        if(java.util.Arrays.asList(args).contains("--migrate")) {
            org.flywaydb.core.Flyway.configure().dataSource(System.getenv("DATABASE_URL"),System.getenv("MIGRATION_USER"),System.getenv("MIGRATION_PASSWORD")).locations("classpath:db/migration").load().migrate();
            return;
        }
        SpringApplication.run(HealthApplication.class, args);
    }
}
