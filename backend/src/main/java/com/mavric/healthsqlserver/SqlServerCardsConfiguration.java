package com.mavric.healthsqlserver;

import org.springframework.context.annotation.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.env.Environment;
import org.springframework.transaction.PlatformTransactionManager;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.identity.*;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.tenancy.Settings;
import com.mavric.healthcards.*;

@Configuration(proxyBeanMethods=false)
public class SqlServerCardsConfiguration {
    @Bean BranchTokens branchTokens(ObjectMapper mapper,Environment env){return new BranchTokens(mapper,env.getProperty("HEALTH_JWT_SECRET",""));}
    @Bean SqlServerCardsStore cardsStore(@Qualifier("sqlServerRuntimeExecutor") SqlServerExecutor executor,@Qualifier("sqlServerRuntimeTransactionManager") PlatformTransactionManager manager,ObjectMapper mapper){return new SqlServerCardsStore(executor,manager,mapper);}
    @Bean BranchAuthController branchAuthController(IdentityService identity,Access access,SqlServerCardsStore store,BranchTokens tokens,Settings settings){return new BranchAuthController(identity,access,store,tokens,settings);}
    @Bean CardsController cardsController(Access access,SqlServerCardsStore store){return new CardsController(access,store);}
}
