package com.mavric.health.identity;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.Settings;

@Component
public class Bootstrap implements CommandLineRunner {
    private final com.mavric.health.persistence.sqlserver.SqlServerBootstrapStore store;private final Sql sql; private final Settings settings; private final PasswordEncoder passwords;
    @org.springframework.beans.factory.annotation.Autowired
    public Bootstrap(Sql sql,Settings settings,PasswordEncoder passwords) { this.sql=sql; this.settings=settings; this.passwords=passwords;this.store=null; }
    public Bootstrap(com.mavric.health.persistence.sqlserver.SqlServerBootstrapStore store,Settings settings,PasswordEncoder passwords){this.sql=null;this.store=java.util.Objects.requireNonNull(store);this.settings=settings;this.passwords=passwords;}
    @Override @Transactional public void run(String... args) {
        var config=settings.bootstrap(); if(config==null || config.email()==null || config.email().isBlank()) return;
        if(store!=null){store.initialize(config.email(),()->{Checks.password(config.password());return passwords.encode(config.password());});return;}
        if(sql.optional("SELECT id FROM users WHERE platform_role='SAD' LIMIT 1").isPresent()) return;
        Checks.password(config.password()); sql.call("sp_bootstrap",Checks.id(),config.email().toLowerCase(java.util.Locale.ROOT),passwords.encode(config.password()));
    }
}
