package com.mavric.health.identity;
import org.springframework.stereotype.Service;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.mail.*;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.beans.factory.annotation.Value;
import com.mavric.health.shared.Sql;
@Service
public class MailDelivery {
    private final Sql sql;private final JavaMailSender sender;private final String from;
    public MailDelivery(Sql sql,JavaMailSender sender,@Value("${health.mail.from}") String from) {this.sql=sql;this.sender=sender;this.from=from;}
    @Scheduled(fixedDelay=5000,initialDelay=10000) public void send() {
        try {for(var row:sql.rows("SELECT id,recipient,subject,body FROM mail_outbox WHERE attempts<5 AND (status='PENDING' OR status IN ('FAILED','SENDING') AND retry_at<UTC_TIMESTAMP()) ORDER BY created_at LIMIT 10")) {
            String id=row.get("id").toString();sql.call("sp_mail_status",id,"SENDING");try {var message=new SimpleMailMessage();message.setFrom(from);message.setTo(row.get("recipient").toString());message.setSubject(row.get("subject").toString());message.setText(row.get("body").toString());sender.send(message);sql.call("sp_mail_status",id,"SENT");} catch(Exception e) {sql.call("sp_mail_status",id,"FAILED");}
        }} catch(Exception e) {org.slf4j.LoggerFactory.getLogger(MailDelivery.class).warn("Mail delivery cycle unavailable");}
    }
}
