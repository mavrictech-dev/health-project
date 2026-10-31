package com.mavric.health.identity;

import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;

@Configuration
public class SecurityConfiguration {
    @Bean PasswordEncoder passwords() { return new BCryptPasswordEncoder(12); }
    @Bean org.springframework.security.core.userdetails.UserDetailsService bearerOnlyUsers() { return username->{ throw new org.springframework.security.core.userdetails.UsernameNotFoundException("Use the tenant session API"); }; }
    @Bean SecurityFilterChain security(HttpSecurity http,Settings settings,Sql sql,Errors errors) throws Exception {
        HostFilter host=new HostFilter(settings,sql,errors); SessionFilter session=new SessionFilter(sql,errors);var trace=new com.mavric.health.audit.TraceFilter(sql,errors);
        return http.csrf(c->c.disable()).formLogin(c->c.disable()).httpBasic(c->c.disable())
            .sessionManagement(c->c.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(c->c.authenticationEntryPoint((req,res,e)->errors.write(req,res,new ApiException(401,"UNAUTHENTICATED","Inicia sesión en este espacio."))).accessDeniedHandler((req,res,e)->errors.write(req,res,ApiException.forbidden())))
            .authorizeHttpRequests(c->c.requestMatchers("/api/public/**","/api/auth/login","/api/auth/browser/login","/api/auth/invitations/accept","/api/auth/register","/api/auth/recovery/**","/api/auth/verify/**","/actuator/health/**").permitAll().requestMatchers("/api/platform/**").hasAuthority("SAD").anyRequest().authenticated())
            .addFilterBefore(trace,UsernamePasswordAuthenticationFilter.class).addFilterAfter(host,com.mavric.health.audit.TraceFilter.class).addFilterAfter(session,HostFilter.class).build();
    }
}
