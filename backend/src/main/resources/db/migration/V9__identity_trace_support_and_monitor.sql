ALTER TABLE users ADD email_verified BOOLEAN NOT NULL DEFAULT TRUE, ADD login_failures INT NOT NULL DEFAULT 0, ADD locked_until DATETIME(6) NULL;
ALTER TABLE auth_sessions ADD csrf_token CHAR(64) NOT NULL DEFAULT '', ADD last_seen_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), ADD user_agent VARCHAR(300) NOT NULL DEFAULT '', ADD source_ip VARCHAR(80) NOT NULL DEFAULT '';
ALTER TABLE audit_events MODIFY actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, ADD request_id CHAR(36) NULL, ADD method VARCHAR(10) NULL, ADD route VARCHAR(250) NULL, ADD source_ip VARCHAR(80) NULL, ADD user_agent VARCHAR(300) NULL, ADD actor_roles JSON NULL, ADD before_state JSON NULL, ADD after_state JSON NULL, ADD resource_type VARCHAR(60) NULL, ADD INDEX(request_id), ADD INDEX(tenant_id,created_at);
CREATE TABLE request_traces (
 id CHAR(36) PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 method VARCHAR(10) NOT NULL, route VARCHAR(250) NOT NULL, status INT NOT NULL, duration_ms BIGINT NOT NULL, source_ip VARCHAR(80) NOT NULL, user_agent VARCHAR(300) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), INDEX(tenant_id,created_at), INDEX(actor_id,created_at), INDEX(status,created_at)
);
CREATE TABLE identity_tokens (
 token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, purpose ENUM('VERIFY','RESET') NOT NULL, expires_at DATETIME(6) NOT NULL, used_at DATETIME(6) NULL,
 FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(tenant_id) REFERENCES tenants(id), INDEX(user_id,purpose)
);
CREATE TABLE mail_outbox (
 id CHAR(36) PRIMARY KEY, recipient VARCHAR(254) NOT NULL, subject VARCHAR(200) NOT NULL, body TEXT NOT NULL,
 status ENUM('PENDING','SENDING','SENT','FAILED') NOT NULL DEFAULT 'PENDING', attempts INT NOT NULL DEFAULT 0, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), sent_at DATETIME(6) NULL, retry_at DATETIME(6) NULL
);
CREATE TABLE support_tickets (
 id CHAR(36) PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 reference VARCHAR(30) NOT NULL UNIQUE, email VARCHAR(254) NOT NULL, subject VARCHAR(180) NOT NULL, message TEXT NOT NULL,
 status ENUM('OPEN','IN_PROGRESS','WAITING_USER','RESOLVED','CLOSED') NOT NULL DEFAULT 'OPEN', priority ENUM('LOW','NORMAL','HIGH','URGENT') NOT NULL,
 revision INT NOT NULL DEFAULT 1, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), INDEX(tenant_id,created_at)
);
CREATE TABLE support_comments (id CHAR(36) PRIMARY KEY, ticket_id CHAR(36) NOT NULL, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, message TEXT NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), FOREIGN KEY(ticket_id) REFERENCES support_tickets(id));
CREATE TABLE application_state (id INT PRIMARY KEY, mode ENUM('OPEN','READ_ONLY','MAINTENANCE') NOT NULL, message VARCHAR(300) NOT NULL, revision INT NOT NULL DEFAULT 1);
INSERT INTO application_state VALUES(1,'OPEN','Todos los servicios disponibles',1);
CREATE TABLE health_samples (id BIGINT AUTO_INCREMENT PRIMARY KEY, instance_id CHAR(36) NOT NULL, db_status VARCHAR(20) NOT NULL, db_latency_ms BIGINT NOT NULL, memory_used BIGINT NOT NULL, memory_max BIGINT NOT NULL, uptime_ms BIGINT NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), INDEX(created_at));
DELIMITER $$
DROP PROCEDURE sp_audit$$
CREATE PROCEDURE sp_audit(IN t CHAR(36), IN actor CHAR(36), IN action_name VARCHAR(80), IN target VARCHAR(100), IN meta JSON)
BEGIN
 INSERT INTO audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles)
 VALUES(t,actor,action_name,target,meta,@hp_request_id,@hp_method,@hp_route,@hp_source_ip,@hp_user_agent,@hp_actor_roles);
END$$
CREATE PROCEDURE sp_audit_change(IN t CHAR(36), IN resource_name VARCHAR(60), IN target VARCHAR(100), IN operation_name VARCHAR(20), IN previous JSON, IN next_value JSON)
BEGIN
 INSERT INTO audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 VALUES(t,@hp_actor_id,CONCAT(resource_name,'_',operation_name),target,JSON_OBJECT('operation',operation_name),@hp_request_id,@hp_method,@hp_route,@hp_source_ip,@hp_user_agent,@hp_actor_roles,previous,next_value,resource_name);
END$$
CREATE TRIGGER audit_no_update BEFORE UPDATE ON audit_events FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:La auditoría es inmutable'; END$$
CREATE TRIGGER audit_no_delete BEFORE DELETE ON audit_events FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:La auditoría es inmutable'; END$$
CREATE PROCEDURE sp_request_finish(IN request_key CHAR(36), IN t CHAR(36), IN actor CHAR(36), IN verb VARCHAR(10), IN route_name VARCHAR(250), IN result_code INT, IN elapsed BIGINT, IN address VARCHAR(80), IN agent VARCHAR(300))
BEGIN INSERT INTO request_traces(id,tenant_id,actor_id,method,route,status,duration_ms,source_ip,user_agent) VALUES(request_key,t,actor,verb,route_name,result_code,elapsed,address,agent); END$$
DROP PROCEDURE sp_session_save$$
CREATE PROCEDURE sp_session_save(IN p_hash CHAR(64), IN p_user CHAR(36), IN t CHAR(36), IN p_expiry DATETIME(6))
BEGIN
 INSERT INTO auth_sessions(token_hash,user_id,tenant_id,expires_at,csrf_token,user_agent,source_ip) VALUES(p_hash,p_user,t,p_expiry,HEX(RANDOM_BYTES(32)),COALESCE(@hp_user_agent,''),COALESCE(@hp_source_ip,''));
 UPDATE users SET login_failures=0,locked_until=NULL WHERE id=p_user;
 CALL sp_audit(t,p_user,'LOGIN_SUCCEEDED',p_user,JSON_OBJECT('expiresAt',p_expiry));
END$$
CREATE PROCEDURE sp_login_failure(IN u CHAR(36), IN t CHAR(36))
BEGIN
 IF u IS NOT NULL THEN UPDATE users SET login_failures=IF(locked_until IS NOT NULL AND locked_until<UTC_TIMESTAMP(6),1,login_failures+1),locked_until=IF(login_failures>=5,UTC_TIMESTAMP(6)+INTERVAL 15 MINUTE,locked_until) WHERE id=u; END IF;
 CALL sp_audit(t,u,'LOGIN_FAILED',COALESCE(u,'unknown'),JSON_OBJECT('result','REJECTED'));
END$$
CREATE PROCEDURE sp_session_touch(IN p_hash CHAR(64))
BEGIN UPDATE auth_sessions SET last_seen_at=UTC_TIMESTAMP(6) WHERE token_hash=p_hash AND last_seen_at<UTC_TIMESTAMP()-INTERVAL 1 MINUTE; END$$
CREATE PROCEDURE sp_session_end(IN p_hash CHAR(64), IN u CHAR(36))
BEGIN UPDATE auth_sessions SET revoked=TRUE WHERE token_hash=p_hash AND user_id=u; CALL sp_audit(@hp_tenant_id,u,'SESSION_REVOKED',u,JSON_OBJECT()); END$$
CREATE PROCEDURE sp_identity_pending(IN u CHAR(36))
BEGIN UPDATE users SET email_verified=FALSE WHERE id=u; END$$
CREATE PROCEDURE sp_identity_issue(IN h CHAR(64), IN u CHAR(36), IN t CHAR(36), IN kind VARCHAR(10), IN expiry DATETIME(6), IN mail_id CHAR(36), IN recipient_email VARCHAR(254), IN title VARCHAR(200), IN content TEXT)
BEGIN
 SELECT id FROM users WHERE id=u FOR UPDATE;
 UPDATE identity_tokens SET used_at=UTC_TIMESTAMP(6) WHERE user_id=u AND purpose=kind AND used_at IS NULL;
 INSERT INTO identity_tokens VALUES(h,u,t,kind,expiry,NULL);
 INSERT INTO mail_outbox(id,recipient,subject,body) VALUES(mail_id,recipient_email,title,content);
 CALL sp_audit(t,u,CONCAT(kind,'_LINK_REQUESTED'),u,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_identity_redeem(IN h CHAR(64), IN t CHAR(36), IN kind VARCHAR(10), IN password_value VARCHAR(100))
BEGIN
 DECLARE u CHAR(36); DECLARE token_tenant CHAR(36); DECLARE expiry DATETIME(6); DECLARE redeemed DATETIME(6);
 SELECT user_id,tenant_id,expires_at,used_at INTO u,token_tenant,expiry,redeemed FROM identity_tokens WHERE token_hash=h AND purpose=kind FOR UPDATE;
 IF u IS NULL OR NOT (token_tenant<=>t) OR redeemed IS NOT NULL OR expiry<UTC_TIMESTAMP(6) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:El enlace no es válido o ya venció'; END IF;
 IF kind='VERIFY' THEN UPDATE users SET email_verified=TRUE WHERE id=u;
 ELSE CALL sp_password_change(u,password_value); UPDATE users SET login_failures=0,locked_until=NULL WHERE id=u; END IF;
 UPDATE identity_tokens SET used_at=UTC_TIMESTAMP(6) WHERE user_id=u AND purpose=kind AND used_at IS NULL;
 CALL sp_audit(t,u,CONCAT(kind,'_COMPLETED'),u,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_portal_register(IN t CHAR(36), IN u CHAR(36))
BEGIN
 DECLARE b CHAR(36); DECLARE d VARCHAR(10);
 CALL sp_write_guard(t,'PORTAL'); SELECT domain INTO d FROM tenants WHERE id=t; SELECT id INTO b FROM branches WHERE tenant_id=t AND active ORDER BY id LIMIT 1;
 INSERT INTO memberships VALUES(t,u,IF(d='ANIMAL',JSON_ARRAY('RES'),JSON_ARRAY('PAC')),'ACTIVE',FALSE);
 INSERT INTO membership_branches VALUES(t,u,b);
 CALL sp_audit(t,u,'PORTAL_ACCOUNT_REGISTERED',u,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_mail_status(IN mail_id CHAR(36), IN next_status VARCHAR(10))
BEGIN
 IF next_status='SENDING' THEN UPDATE mail_outbox SET status='SENDING',attempts=attempts+1,retry_at=UTC_TIMESTAMP()+INTERVAL 2 MINUTE WHERE id=mail_id;
 ELSE UPDATE mail_outbox SET status=next_status,sent_at=IF(next_status='SENT',UTC_TIMESTAMP(),NULL),body=IF(next_status='SENT','[contenido entregado]',body) WHERE id=mail_id; END IF;
END$$
CREATE PROCEDURE sp_support_create(IN p_id CHAR(36), IN t CHAR(36), IN u CHAR(36), IN ref VARCHAR(30), IN p JSON)
BEGIN
 INSERT INTO support_tickets(id,tenant_id,actor_id,reference,email,subject,message,priority) VALUES(p_id,t,u,ref,JSON_UNQUOTE(p->'$.email'),JSON_UNQUOTE(p->'$.subject'),JSON_UNQUOTE(p->'$.message'),JSON_UNQUOTE(p->'$.priority'));
 CALL sp_audit(t,u,'SUPPORT_REQUESTED',p_id,JSON_OBJECT('reference',ref));
END$$
CREATE PROCEDURE sp_support_step(IN p_id CHAR(36), IN u CHAR(36), IN expected INT, IN next_status VARCHAR(30), IN priority_value VARCHAR(10), IN comment_id CHAR(36), IN comment_text TEXT)
BEGIN
 DECLARE rev INT; DECLARE current_status VARCHAR(30); DECLARE t CHAR(36);
 SELECT tenant_id,revision,status INTO t,rev,current_status FROM support_tickets WHERE id=p_id FOR UPDATE;
 IF rev IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Solicitud inexistente'; END IF;
 IF rev<>expected THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La solicitud cambió; actualiza la vista'; END IF;
 IF next_status<>current_status AND NOT ((current_status='OPEN' AND next_status IN ('IN_PROGRESS','CLOSED')) OR (current_status='IN_PROGRESS' AND next_status IN ('WAITING_USER','RESOLVED','CLOSED')) OR (current_status='WAITING_USER' AND next_status IN ('IN_PROGRESS','RESOLVED','CLOSED')) OR (current_status='RESOLVED' AND next_status IN ('IN_PROGRESS','CLOSED'))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Transición de soporte no permitida'; END IF;
 UPDATE support_tickets SET status=next_status,priority=priority_value,revision=revision+1,updated_at=UTC_TIMESTAMP(6) WHERE id=p_id;
 IF comment_text IS NOT NULL AND CHAR_LENGTH(comment_text)>0 THEN INSERT INTO support_comments VALUES(comment_id,p_id,u,comment_text,UTC_TIMESTAMP(6)); END IF;
 CALL sp_audit(t,u,'SUPPORT_UPDATED',p_id,JSON_OBJECT('from',current_status,'to',next_status,'revision',rev+1));
END$$
CREATE PROCEDURE sp_application_mode(IN actor CHAR(36), IN expected INT, IN next_mode VARCHAR(20), IN description VARCHAR(300))
BEGIN
 UPDATE application_state SET mode=next_mode,message=description,revision=revision+1 WHERE id=1 AND revision=expected;
 IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El estado cambió; actualiza la vista'; END IF;
 CALL sp_audit(NULL,actor,'APPLICATION_MODE_CHANGED','application',JSON_OBJECT('mode',next_mode,'reason',description));
END$$
CREATE PROCEDURE sp_health_sample(IN instance_key CHAR(36), IN db_value VARCHAR(20), IN latency BIGINT, IN used_memory BIGINT, IN max_memory BIGINT, IN uptime BIGINT)
BEGIN
 INSERT INTO health_samples(instance_id,db_status,db_latency_ms,memory_used,memory_max,uptime_ms) VALUES(instance_key,db_value,latency,used_memory,max_memory,uptime);
 DELETE FROM health_samples WHERE created_at<UTC_TIMESTAMP()-INTERVAL 7 DAY;
END$$
DELIMITER ;
