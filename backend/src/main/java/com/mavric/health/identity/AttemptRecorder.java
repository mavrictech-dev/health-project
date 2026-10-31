package com.mavric.health.identity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import com.mavric.health.shared.Sql;
@Service
public class AttemptRecorder {
    private final Sql sql;
    public AttemptRecorder(Sql sql) {this.sql=sql;}
    @Transactional(propagation=Propagation.REQUIRES_NEW) public void failed(String user,String tenant) {sql.call("sp_login_failure",user,tenant);}
}
