DELIMITER $$
CREATE PROCEDURE sp_audit(IN t CHAR(36), IN actor CHAR(36), IN action_name VARCHAR(80), IN target VARCHAR(100), IN meta JSON)
BEGIN
 INSERT INTO audit_events(tenant_id,actor_id,action,target_id,metadata) VALUES(t,actor,action_name,target,meta);
END$$
CREATE PROCEDURE sp_write_guard(IN t CHAR(36), IN feature VARCHAR(40))
BEGIN
 DECLARE tenant_status VARCHAR(20); DECLARE enabled_modules JSON;
 SELECT a.status,v.modules INTO tenant_status,enabled_modules FROM tenants a JOIN subscriptions s ON s.tenant_id=a.id JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE a.id=t FOR SHARE;
 IF tenant_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Cliente inexistente'; END IF;
 IF tenant_status NOT IN ('TRIAL','ACTIVE') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_SUSPENDED:El cliente está suspendido'; END IF;
 IF feature IS NOT NULL AND NOT JSON_CONTAINS(enabled_modules,JSON_QUOTE(feature)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Módulo no contratado'; END IF;
END$$
CREATE PROCEDURE sp_user_create(IN p_id CHAR(36), IN p_name VARCHAR(160), IN p_email VARCHAR(254), IN p_hash VARCHAR(100), IN p_domain VARCHAR(10), IN p_credential VARCHAR(100))
BEGIN
 INSERT INTO users(id,name,email,password_hash,clinical_domain,credential) VALUES(p_id,p_name,p_email,p_hash,p_domain,p_credential);
END$$
CREATE PROCEDURE sp_bootstrap(IN p_id CHAR(36), IN p_email VARCHAR(254), IN p_hash VARCHAR(100))
BEGIN
 IF NOT EXISTS(SELECT 1 FROM users WHERE platform_role='SAD') THEN
  CALL sp_user_create(p_id,'Administrador general',p_email,p_hash,NULL,NULL);
  UPDATE users SET platform_role='SAD' WHERE id=p_id;
 END IF;
END$$
CREATE PROCEDURE sp_session_save(IN p_hash CHAR(64), IN p_user CHAR(36), IN t CHAR(36), IN p_expiry DATETIME(6))
BEGIN
 DELETE FROM auth_sessions WHERE expires_at<UTC_TIMESTAMP()-INTERVAL 1 DAY;
 INSERT INTO auth_sessions(token_hash,user_id,tenant_id,expires_at) VALUES(p_hash,p_user,t,p_expiry);
END$$
CREATE PROCEDURE sp_session_revoke(IN p_hash CHAR(64))
BEGIN UPDATE auth_sessions SET revoked=TRUE WHERE token_hash=p_hash; END$$
CREATE PROCEDURE sp_password_change(IN p_user CHAR(36), IN p_hash VARCHAR(100))
BEGIN
 UPDATE users SET password_hash=p_hash WHERE id=p_user;
 UPDATE auth_sessions SET revoked=TRUE WHERE user_id=p_user;
END$$
CREATE PROCEDURE sp_invitation_accept(IN t CHAR(36), IN u CHAR(36))
BEGIN
 CALL sp_write_guard(t,'CORE');
 UPDATE memberships SET status='ACTIVE' WHERE tenant_id=t AND user_id=u AND status='INVITED';
 IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Invitación no disponible en este espacio'; END IF;
 CALL sp_audit(t,u,'INVITATION_ACCEPTED',u,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_plan_save(IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE ver INT DEFAULT 0;
 IF EXISTS(SELECT 1 FROM plans WHERE id=p_id) THEN SELECT current_version INTO ver FROM plans WHERE id=p_id FOR UPDATE; END IF;
 INSERT INTO plans(id,name,description,status,current_version) VALUES(p_id,JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.description'),JSON_UNQUOTE(p->'$.status'),ver+1)
 ON DUPLICATE KEY UPDATE name=VALUES(name),description=VALUES(description),status=VALUES(status),current_version=ver+1;
 INSERT INTO plan_versions(plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,included_specialties,max_branches,max_professionals,max_specialties,annual_discount,kinds,domains,modules)
 VALUES(p_id,ver+1,p->'$.baseMinor',p->'$.branchMinor',p->'$.professionalMinor',p->'$.includedBranches',p->'$.includedProfessionals',p->'$.includedSpecialties',p->'$.maxBranches',p->'$.maxProfessionals',p->'$.maxSpecialties',p->'$.annualDiscount',p->'$.kinds',p->'$.domains',p->'$.modules');
 CALL sp_audit(NULL,actor,'PLAN_VERSION_CREATED',p_id,JSON_OBJECT('version',ver+1));
END$$
CREATE PROCEDURE sp_subscription_validate(IN t CHAR(36), IN p_kind VARCHAR(40), IN p_domain VARCHAR(10), IN p JSON)
BEGIN
 DECLARE cfg JSON; DECLARE b_used INT DEFAULT 0; DECLARE pro_used INT DEFAULT 0; DECLARE spec_used INT DEFAULT 0;
 DECLARE plan_key CHAR(36); DECLARE ver INT; DECLARE max_b INT; DECLARE max_p INT; DECLARE max_s INT; DECLARE min_b INT; DECLARE min_p INT;
 DECLARE kinds JSON; DECLARE domains JSON; DECLARE enabled_modules JSON;
 SET plan_key=JSON_UNQUOTE(p->'$.planId');
 SELECT a.current_version,v.max_branches,v.max_professionals,v.max_specialties,v.included_branches,v.included_professionals,v.kinds,v.domains,v.modules INTO ver,max_b,max_p,max_s,min_b,min_p,kinds,domains,enabled_modules FROM plans a JOIN plan_versions v ON v.plan_id=a.id AND v.version=a.current_version WHERE a.id=plan_key AND a.status='PUBLISHED' FOR SHARE;
 IF ver IS NULL OR NOT JSON_CONTAINS(kinds,JSON_QUOTE(p_kind)) OR NOT JSON_CONTAINS(domains,JSON_QUOTE(p_domain)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Plan incompatible con el cliente'; END IF;
 IF p->'$.branchQuota'<min_b OR p->'$.branchQuota'>max_b OR p->'$.professionalQuota'<min_p OR p->'$.professionalQuota'>max_p OR p->'$.specialtyQuota'<1 OR p->'$.specialtyQuota'>max_s THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:Capacidad fuera de los límites del plan'; END IF;
 IF p_kind='DOCTOR' AND p->'$.professionalQuota'<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:El independiente tiene una identidad clínica'; END IF;
 IF t IS NOT NULL THEN
  SELECT COUNT(*) INTO b_used FROM branches WHERE tenant_id=t AND active AND NOT external;
  SELECT COUNT(*) INTO pro_used FROM memberships WHERE tenant_id=t AND status<>'INACTIVE' AND JSON_CONTAINS(roles,'"PRO"');
  SELECT COUNT(*) INTO spec_used FROM tenant_specialties WHERE tenant_id=t;
  IF EXISTS(SELECT 1 FROM tenant_specialties s JOIN specialties a ON a.code=s.specialty_code WHERE s.tenant_id=t AND a.dental) AND NOT JSON_CONTAINS(enabled_modules,'"DENTAL"') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Hay especialidades que requieren odontología'; END IF;
 END IF;
 IF p->'$.branchQuota'<b_used OR p->'$.professionalQuota'<pro_used OR p->'$.specialtyQuota'<spec_used THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:No se puede reducir el contrato por debajo del consumo'; END IF;
END$$
CREATE PROCEDURE sp_specialties_validate(IN t CHAR(36), IN p_domain VARCHAR(10), IN p_kind VARCHAR(40), IN p_codes JSON, IN quota INT, IN enabled_modules JSON)
BEGIN
 IF JSON_LENGTH(p_codes)=0 OR JSON_LENGTH(p_codes)>quota THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:Revisa la cantidad de especialidades'; END IF;
 IF EXISTS(SELECT 1 FROM JSON_TABLE(p_codes,'$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j LEFT JOIN specialties s ON s.code=j.code WHERE s.code IS NULL OR s.domain<>p_domain OR (p_kind='DENTAL' AND NOT s.dental)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Especialidad incompatible con el ámbito'; END IF;
 IF EXISTS(SELECT 1 FROM JSON_TABLE(p_codes,'$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j JOIN specialties s ON s.code=j.code WHERE s.dental) AND NOT JSON_CONTAINS(enabled_modules,'"DENTAL"') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Las especialidades requieren el módulo odontológico'; END IF;
END$$
CREATE PROCEDURE sp_tenant_create(IN t CHAR(36), IN branch_key CHAR(36), IN owner_key CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE plan_key CHAR(36); DECLARE ver INT; DECLARE enabled_modules JSON;
 CALL sp_subscription_validate(NULL,JSON_UNQUOTE(p->'$.kind'),JSON_UNQUOTE(p->'$.domain'),p->'$.subscription');
 SET plan_key=JSON_UNQUOTE(p->'$.subscription.planId');
 SELECT a.current_version,v.modules INTO ver,enabled_modules FROM plans a JOIN plan_versions v ON v.plan_id=a.id AND v.version=a.current_version WHERE a.id=plan_key FOR SHARE;
 CALL sp_specialties_validate(NULL,JSON_UNQUOTE(p->'$.domain'),JSON_UNQUOTE(p->'$.kind'),p->'$.specialties',p->'$.subscription.specialtyQuota',enabled_modules);
 IF JSON_UNQUOTE(p->'$.kind')='DOCTOR' AND NOT EXISTS(SELECT 1 FROM users WHERE id=owner_key AND clinical_domain=JSON_UNQUOTE(p->'$.domain')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Ámbito profesional incompatible'; END IF;
 INSERT INTO tenants(id,name,slug,kind,domain,owner_user_id,timezone) VALUES(t,JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.slug'),JSON_UNQUOTE(p->'$.kind'),JSON_UNQUOTE(p->'$.domain'),owner_key,JSON_UNQUOTE(p->'$.timezone'));
 INSERT INTO subscriptions VALUES(t,plan_key,ver,JSON_UNQUOTE(p->'$.subscription.cycle'),p->'$.subscription.branchQuota',p->'$.subscription.professionalQuota',p->'$.subscription.specialtyQuota',IF(JSON_UNQUOTE(p->'$.subscription.cycle')='YEARLY',CURRENT_DATE+INTERVAL 1 YEAR,CURRENT_DATE+INTERVAL 1 MONTH));
 INSERT INTO branches(id,tenant_id,name,address) VALUES(branch_key,t,JSON_UNQUOTE(p->'$.branchName'),JSON_UNQUOTE(p->'$.address'));
 INSERT INTO tenant_specialties SELECT t,j.code FROM JSON_TABLE(p->'$.specialties','$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j;
 INSERT INTO areas(id,tenant_id,branch_id,name,specialties) VALUES(UUID(),t,branch_key,'Consulta y atención',p->'$.specialties');
 INSERT INTO memberships VALUES(t,owner_key,IF(JSON_UNQUOTE(p->'$.kind')='DOCTOR',JSON_ARRAY('ADM','PRO'),JSON_ARRAY('ADM')),'ACTIVE',TRUE);
 INSERT INTO membership_branches VALUES(t,owner_key,branch_key);
 IF JSON_UNQUOTE(p->'$.kind')='DOCTOR' THEN INSERT INTO membership_specialties SELECT t,owner_key,j.code FROM JSON_TABLE(p->'$.specialties','$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j; END IF;
 CALL sp_audit(t,actor,'TENANT_CREATED',t,JSON_OBJECT('slug',JSON_UNQUOTE(p->'$.slug')));
END$$
CREATE PROCEDURE sp_tenant_status(IN t CHAR(36), IN actor CHAR(36), IN next_status VARCHAR(20), IN reason VARCHAR(500))
BEGIN
 UPDATE tenants SET status=next_status WHERE id=t;
 IF ROW_COUNT()=0 AND NOT EXISTS(SELECT 1 FROM tenants WHERE id=t) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Cliente inexistente'; END IF;
 CALL sp_audit(t,actor,'TENANT_STATUS_CHANGED',t,JSON_OBJECT('status',next_status,'reason',reason));
END$$
CREATE PROCEDURE sp_subscription_change(IN t CHAR(36), IN actor CHAR(36), IN invoice_key CHAR(36), IN p JSON)
BEGIN
 DECLARE tenant_kind VARCHAR(40); DECLARE tenant_domain VARCHAR(10); DECLARE plan_key CHAR(36); DECLARE ver INT; DECLARE amount BIGINT;
 SELECT kind,domain INTO tenant_kind,tenant_domain FROM tenants WHERE id=t FOR UPDATE;
 IF tenant_kind IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Cliente inexistente'; END IF;
 CALL sp_subscription_validate(t,tenant_kind,tenant_domain,p);
 SET plan_key=JSON_UNQUOTE(p->'$.planId'); SELECT current_version INTO ver FROM plans WHERE id=plan_key;
 UPDATE subscriptions SET plan_id=plan_key,plan_version=ver,cycle=JSON_UNQUOTE(p->'$.cycle'),branch_quota=p->'$.branchQuota',professional_quota=p->'$.professionalQuota',specialty_quota=p->'$.specialtyQuota',renewal_date=IF(JSON_UNQUOTE(p->'$.cycle')='YEARLY',CURRENT_DATE+INTERVAL 1 YEAR,CURRENT_DATE+INTERVAL 1 MONTH) WHERE tenant_id=t;
 SELECT base_minor+GREATEST(0,p->'$.branchQuota'-included_branches)*branch_minor+GREATEST(0,p->'$.professionalQuota'-included_professionals)*professional_minor INTO amount FROM plan_versions WHERE plan_id=plan_key AND version=ver;
 IF JSON_UNQUOTE(p->'$.cycle')='YEARLY' THEN SELECT ROUND(amount*12*(100-annual_discount)/100) INTO amount FROM plan_versions WHERE plan_id=plan_key AND version=ver; END IF;
 INSERT INTO saas_invoices(id,tenant_id,amount_minor,cycle,status) VALUES(invoice_key,t,amount,JSON_UNQUOTE(p->'$.cycle'),'PENDING');
 CALL sp_audit(t,actor,'SUBSCRIPTION_CHANGED',t,JSON_OBJECT('planId',plan_key,'version',ver));
END$$
CREATE PROCEDURE sp_branch_save(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE k VARCHAR(40); DECLARE quota INT; DECLARE used INT; DECLARE previous_external BOOLEAN; DECLARE previous_active BOOLEAN;
 SELECT kind INTO k FROM tenants WHERE id=t FOR UPDATE; CALL sp_write_guard(t,'CORE');
 SELECT branch_quota INTO quota FROM subscriptions WHERE tenant_id=t;
 SELECT COUNT(*) INTO used FROM branches WHERE tenant_id=t AND active AND NOT external;
 SELECT external,active INTO previous_external,previous_active FROM branches WHERE tenant_id=t AND id=p_id;
 IF JSON_UNQUOTE(p->'$.external')='true' AND k<>'DOCTOR' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Los lugares externos pertenecen a independientes'; END IF;
 IF (previous_active IS NULL OR NOT previous_active OR previous_external) AND JSON_UNQUOTE(p->'$.active')='true' AND JSON_UNQUOTE(p->'$.external')='false' AND used>=quota THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:No hay capacidad de sedes'; END IF;
 IF previous_active AND NOT previous_external AND (JSON_UNQUOTE(p->'$.active')='false' OR JSON_UNQUOTE(p->'$.external')='true') AND used<=1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Debe quedar una sede propia activa'; END IF;
 IF EXISTS(SELECT 1 FROM branches WHERE id=p_id AND tenant_id<>t) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede inexistente'; END IF;
 IF EXISTS(SELECT 1 FROM branches WHERE id=p_id AND tenant_id=t) THEN UPDATE branches SET name=JSON_UNQUOTE(p->'$.name'),address=JSON_UNQUOTE(p->'$.address'),external=JSON_UNQUOTE(p->'$.external')='true',active=JSON_UNQUOTE(p->'$.active')='true' WHERE tenant_id=t AND id=p_id;
 ELSE INSERT INTO branches(id,tenant_id,name,address,external,active) VALUES(p_id,t,JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.address'),JSON_UNQUOTE(p->'$.external')='true',JSON_UNQUOTE(p->'$.active')='true'); END IF;
 CALL sp_audit(t,actor,'BRANCH_SAVED',p_id,JSON_OBJECT('active',p->'$.active'));
END$$
CREATE PROCEDURE sp_specialties_save(IN t CHAR(36), IN actor CHAR(36), IN codes JSON)
BEGIN
 DECLARE k VARCHAR(40); DECLARE d VARCHAR(10); DECLARE quota INT; DECLARE enabled_modules JSON;
 SELECT kind,domain INTO k,d FROM tenants WHERE id=t FOR UPDATE; CALL sp_write_guard(t,'CORE');
 SELECT s.specialty_quota,v.modules INTO quota,enabled_modules FROM subscriptions s JOIN plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE s.tenant_id=t;
 CALL sp_specialties_validate(t,d,k,codes,quota,enabled_modules);
 IF EXISTS(SELECT 1 FROM membership_specialties m WHERE m.tenant_id=t AND NOT JSON_CONTAINS(codes,JSON_QUOTE(m.specialty_code))) OR EXISTS(SELECT 1 FROM appointments a WHERE a.tenant_id=t AND NOT JSON_CONTAINS(codes,JSON_QUOTE(a.specialty_code))) OR EXISTS(SELECT 1 FROM encounters e WHERE e.tenant_id=t AND NOT JSON_CONTAINS(codes,JSON_QUOTE(e.specialty_code))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La especialidad tiene asignaciones o historia; consérvala'; END IF;
 DELETE FROM tenant_specialties WHERE tenant_id=t AND NOT JSON_CONTAINS(codes,JSON_QUOTE(specialty_code));
 INSERT IGNORE INTO tenant_specialties SELECT t,j.code FROM JSON_TABLE(codes,'$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j;
 CALL sp_audit(t,actor,'SPECIALTIES_CONFIGURED',t,JSON_OBJECT('count',JSON_LENGTH(codes)));
END$$
CREATE PROCEDURE sp_member_save(IN t CHAR(36), IN u CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE d VARCHAR(10); DECLARE quota INT; DECLARE used INT; DECLARE was_pro BOOLEAN DEFAULT FALSE; DECLARE is_pro BOOLEAN; DECLARE is_owner BOOLEAN DEFAULT FALSE;
 SELECT domain INTO d FROM tenants WHERE id=t FOR UPDATE; CALL sp_write_guard(t,'CORE');
 SELECT professional_quota INTO quota FROM subscriptions WHERE tenant_id=t;
 SELECT JSON_CONTAINS(roles,'"PRO"') AND status<>'INACTIVE',owner INTO was_pro,is_owner FROM memberships WHERE tenant_id=t AND user_id=u;
 SET is_pro=JSON_CONTAINS(p->'$.roles','"PRO"') AND JSON_UNQUOTE(p->'$.status')<>'INACTIVE';
 SELECT COUNT(*) INTO used FROM memberships WHERE tenant_id=t AND status<>'INACTIVE' AND JSON_CONTAINS(roles,'"PRO"');
 IF is_pro AND NOT COALESCE(was_pro,FALSE) AND used>=quota THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_QUOTA:No hay licencias profesionales disponibles'; END IF;
 IF is_pro AND NOT EXISTS(SELECT 1 FROM users WHERE id=u AND clinical_domain=d AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Identidad clínica incompatible'; END IF;
 IF JSON_LENGTH(p->'$.branches')=0 OR EXISTS(SELECT 1 FROM JSON_TABLE(p->'$.branches','$[*]' COLUMNS(id CHAR(36) PATH '$')) j LEFT JOIN branches b ON b.id=j.id AND b.tenant_id=t WHERE b.id IS NULL OR NOT b.active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Asigna sedes activas de este cliente'; END IF;
 IF is_pro AND (JSON_LENGTH(p->'$.specialties')=0 OR EXISTS(SELECT 1 FROM JSON_TABLE(p->'$.specialties','$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j LEFT JOIN tenant_specialties s ON s.tenant_id=t AND s.specialty_code=j.code WHERE s.specialty_code IS NULL)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Asigna especialidades activadas'; END IF;
 IF COALESCE(is_owner,FALSE) AND (JSON_UNQUOTE(p->'$.status')<>'ACTIVE' OR NOT JSON_CONTAINS(p->'$.roles','"ADM"')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Conserva el administrador propietario activo'; END IF;
 INSERT INTO memberships VALUES(t,u,p->'$.roles',JSON_UNQUOTE(p->'$.status'),FALSE) ON DUPLICATE KEY UPDATE roles=VALUES(roles),status=VALUES(status);
 DELETE FROM membership_branches WHERE tenant_id=t AND user_id=u;
 INSERT INTO membership_branches SELECT t,u,j.id FROM JSON_TABLE(p->'$.branches','$[*]' COLUMNS(id CHAR(36) PATH '$')) j;
 DELETE FROM membership_specialties WHERE tenant_id=t AND user_id=u;
 IF JSON_CONTAINS(p->'$.roles','"PRO"') THEN INSERT INTO membership_specialties SELECT t,u,j.code FROM JSON_TABLE(p->'$.specialties','$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j; END IF;
 CALL sp_audit(t,actor,'MEMBERSHIP_SAVED',u,JSON_OBJECT('status',JSON_UNQUOTE(p->'$.status')));
END$$
CREATE PROCEDURE sp_area_save(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 CALL sp_write_guard(t,'CORE');
 IF NOT EXISTS(SELECT 1 FROM branches WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.branchId') AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede no disponible'; END IF;
 IF JSON_LENGTH(p->'$.specialties')=0 OR EXISTS(SELECT 1 FROM JSON_TABLE(p->'$.specialties','$[*]' COLUMNS(code VARCHAR(100) PATH '$')) j LEFT JOIN tenant_specialties s ON s.tenant_id=t AND s.specialty_code=j.code WHERE s.specialty_code IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Especialidades no activadas'; END IF;
 IF EXISTS(SELECT 1 FROM areas WHERE id=p_id AND tenant_id<>t) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Área inexistente'; END IF;
 IF EXISTS(SELECT 1 FROM areas WHERE id=p_id AND tenant_id=t) THEN UPDATE areas SET branch_id=JSON_UNQUOTE(p->'$.branchId'),name=JSON_UNQUOTE(p->'$.name'),specialties=p->'$.specialties' WHERE tenant_id=t AND id=p_id; ELSE INSERT INTO areas(id,tenant_id,branch_id,name,specialties) VALUES(p_id,t,JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.name'),p->'$.specialties'); END IF;
 CALL sp_audit(t,actor,'AREA_SAVED',p_id,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_invoice_pay(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36))
BEGIN
 DECLARE invoice_status VARCHAR(20);
 SELECT status INTO invoice_status FROM saas_invoices WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF invoice_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Comprobante inexistente'; END IF;
 IF invoice_status='PENDING' THEN UPDATE saas_invoices SET status='PAID',paid_at=UTC_TIMESTAMP(6) WHERE tenant_id=t AND id=p_id; CALL sp_audit(t,actor,'SAAS_PAYMENT_RECORDED',p_id,JSON_OBJECT()); END IF;
END$$
DELIMITER ;
