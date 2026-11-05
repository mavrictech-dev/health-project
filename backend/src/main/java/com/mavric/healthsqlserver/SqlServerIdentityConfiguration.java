package com.mavric.healthsqlserver;

import jakarta.servlet.http.HttpServletRequest;
import com.mavric.health.identity.*;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.shared.Errors;
import com.mavric.health.support.SupportController;
import com.mavric.health.tenancy.Settings;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;
import tools.jackson.databind.ObjectMapper;

/** Explicit factories outside legacy scan. A web context supplies its per-request resolvable proxy. */
@Configuration(proxyBeanMethods=false)
public class SqlServerIdentityConfiguration {
    @Bean Access access(HttpServletRequest request,@Qualifier("sqlServerAccessStore") SqlServerAccessStore store) {
        return new Access(request,store);
    }
    @Bean IdentityService identityService(@Qualifier("sqlServerIdentityStore") SqlServerIdentityStore store,
            Access access,@Qualifier("passwords") PasswordEncoder passwords,Settings settings) {
        return new IdentityService(store,access,passwords,settings);
    }
    @Bean AccountLifecycleService accountLifecycleService(
            @Qualifier("sqlServerAccountLifecycleStore") SqlServerAccountLifecycleStore store,
            IdentityService identity,Settings settings,@Qualifier("passwords") PasswordEncoder passwords) {
        return new AccountLifecycleService(store,identity,settings,passwords);
    }
    @Bean BrowserSessionController browserSessionController(IdentityService identity,Access access,
            @Qualifier("sqlServerIdentityStore") SqlServerIdentityStore store,Settings settings) {
        return new BrowserSessionController(identity,access,store,settings);
    }
    @Bean SupportController supportController(@Qualifier("sqlServerSupportStore") SqlServerSupportStore store,
            Access access,AccountLifecycleService lifecycle) {
        return new SupportController(store,access,lifecycle);
    }
    @Bean Errors errors(ObjectMapper mapper) {return new Errors(mapper);}
    @Bean Errors.Advice errorsAdvice(Errors errors) {return new Errors.Advice(errors);}
}
