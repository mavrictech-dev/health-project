package com.mavric.health.identity;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.mail.*;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.beans.factory.annotation.Value;
import com.mavric.health.shared.Sql;
@Service
public class MailDelivery {
    private final com.mavric.health.persistence.sqlserver.SqlServerMailDeliveryStore store;private final Sql sql;private final JavaMailSender sender;private final String from;
    @org.springframework.beans.factory.annotation.Autowired
    public MailDelivery(Sql sql,JavaMailSender sender,@Value("${health.mail.from}") String from) {this.sql=sql;this.sender=sender;this.from=from;this.store=null;}
    public MailDelivery(com.mavric.health.persistence.sqlserver.SqlServerMailDeliveryStore store,JavaMailSender sender,String from){this.sql=null;this.store=java.util.Objects.requireNonNull(store);this.sender=sender;this.from=from;}
    private static void unavailable(){org.slf4j.LoggerFactory.getLogger(MailDelivery.class).warn("Mail delivery cycle unavailable");}
    private void deliverSql(){
        if(org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive()){unavailable();return;}
        java.util.List<com.mavric.health.persistence.sqlserver.SqlServerMailDeliveryStore.ClaimedMail> claimed;
        try{claimed=store.claim();}catch(Exception failure){unavailable();return;}
        for(var mail:claimed){
            String outcome="SENT";
            try{var message=new SimpleMailMessage();message.setFrom(from);message.setTo(mail.recipient());message.setSubject(mail.subject());message.setText(mail.body());sender.send(message);}
            catch(Exception failure){outcome="AMBIGUOUS";unavailable();}
            try{store.complete(mail.id(),mail.claimVersion(),outcome);}catch(Exception failure){unavailable();}
        }
    }
    @Scheduled(fixedDelay=5000,initialDelay=10000) public void send() {if(store!=null){deliverSql();return;}
        try {for(var row:sql.rows("SELECT id,recipient,subject,body FROM mail_outbox WHERE attempts<5 AND (status='PENDING' OR status IN ('FAILED','SENDING') AND retry_at<UTC_TIMESTAMP()) ORDER BY created_at LIMIT 10")) {
            String id=row.get("id").toString();sql.call("sp_mail_status",id,"SENDING");try {var message=new SimpleMailMessage();message.setFrom(from);message.setTo(row.get("recipient").toString());message.setSubject(row.get("subject").toString());message.setText(row.get("body").toString());sender.send(message);sql.call("sp_mail_status",id,"SENT");} catch(Exception e) {sql.call("sp_mail_status",id,"FAILED");}
        }} catch(Exception e) {org.slf4j.LoggerFactory.getLogger(MailDelivery.class).warn("Mail delivery cycle unavailable");}
    }
}
