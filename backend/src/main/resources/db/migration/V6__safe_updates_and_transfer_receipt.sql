-- Additive correction: V1-V5 remain immutable after first deployment.
DELIMITER $$
DROP PROCEDURE sp_plan_save$$
CREATE PROCEDURE sp_plan_save(IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE ver INT DEFAULT 0;
 IF EXISTS(SELECT 1 FROM plans WHERE id=p_id) THEN SELECT current_version INTO ver FROM plans WHERE id=p_id FOR UPDATE; END IF;
 IF EXISTS(SELECT 1 FROM plans WHERE name=JSON_UNQUOTE(p->'$.name') AND id<>p_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Nombre de plan ya utilizado'; END IF;
 IF ver>0 THEN UPDATE plans SET name=JSON_UNQUOTE(p->'$.name'),description=JSON_UNQUOTE(p->'$.description'),status=JSON_UNQUOTE(p->'$.status'),current_version=ver+1 WHERE id=p_id;
 ELSE INSERT INTO plans(id,name,description,status,current_version) VALUES(p_id,JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.description'),JSON_UNQUOTE(p->'$.status'),1); END IF;
 INSERT INTO plan_versions(plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,included_specialties,max_branches,max_professionals,max_specialties,annual_discount,kinds,domains,modules)
 VALUES(p_id,ver+1,p->'$.baseMinor',p->'$.branchMinor',p->'$.professionalMinor',p->'$.includedBranches',p->'$.includedProfessionals',p->'$.includedSpecialties',p->'$.maxBranches',p->'$.maxProfessionals',p->'$.maxSpecialties',p->'$.annualDiscount',p->'$.kinds',p->'$.domains',p->'$.modules');
 CALL sp_audit(NULL,actor,'PLAN_VERSION_CREATED',p_id,JSON_OBJECT('version',ver+1));
END$$
DROP PROCEDURE sp_transfer_receive$$
CREATE PROCEDURE sp_transfer_receive(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36))
BEGIN
 DECLARE transfer_status VARCHAR(20); DECLARE lot_key CHAR(36); DECLARE destination CHAR(36); DECLARE qty DECIMAL(14,3);
 CALL sp_write_guard(t,'INVENTORY');
 SELECT status,lot_id,destination_branch_id,quantity INTO transfer_status,lot_key,destination,qty FROM stock_transfers WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF transfer_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Transferencia inexistente'; END IF;
 IF transfer_status='IN_TRANSIT' THEN
  INSERT INTO stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit) SELECT UUID(),t,destination,name,lot,expiry,qty,unit FROM stock_lots WHERE tenant_id=t AND id=lot_key
  ON DUPLICATE KEY UPDATE quantity=stock_lots.quantity+VALUES(quantity);
  UPDATE stock_transfers SET status='RECEIVED',received_at=UTC_TIMESTAMP(6) WHERE tenant_id=t AND id=p_id;
  CALL sp_audit(t,actor,'TRANSFER_RECEIVED',p_id,JSON_OBJECT());
 END IF;
END$$
DROP PROCEDURE sp_branch_save$$
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
 IF previous_active AND JSON_UNQUOTE(p->'$.active')='false' AND (
 EXISTS(SELECT 1 FROM appointments WHERE tenant_id=t AND branch_id=p_id AND status NOT IN ('CANCELLED','WITHDRAWN','COMPLETED','NO_SHOW')) OR
 EXISTS(SELECT 1 FROM encounters WHERE tenant_id=t AND branch_id=p_id AND status='ACTIVE') OR
 EXISTS(SELECT 1 FROM admissions a JOIN hospital_resources r ON r.tenant_id=a.tenant_id AND r.id=a.resource_id WHERE a.tenant_id=t AND r.branch_id=p_id AND a.status='ADMITTED') OR
 EXISTS(SELECT 1 FROM stock_transfers x JOIN stock_lots l ON l.tenant_id=x.tenant_id AND l.id=x.lot_id WHERE x.tenant_id=t AND x.status='IN_TRANSIT' AND (x.destination_branch_id=p_id OR l.branch_id=p_id)) OR
 EXISTS(SELECT 1 FROM stock_lots WHERE tenant_id=t AND branch_id=p_id AND quantity>0) OR
 EXISTS(SELECT 1 FROM workflow_cases WHERE tenant_id=t AND branch_id=p_id AND status NOT IN ('COMPLETED','CANCELLED'))
 ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La sede mantiene operaciones o stock pendientes'; END IF;
 IF EXISTS(SELECT 1 FROM branches WHERE id=p_id AND tenant_id<>t) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede inexistente'; END IF;
 IF EXISTS(SELECT 1 FROM branches WHERE id=p_id AND tenant_id=t) THEN UPDATE branches SET name=JSON_UNQUOTE(p->'$.name'),address=JSON_UNQUOTE(p->'$.address'),external=JSON_UNQUOTE(p->'$.external')='true',active=JSON_UNQUOTE(p->'$.active')='true' WHERE tenant_id=t AND id=p_id;
 ELSE INSERT INTO branches(id,tenant_id,name,address,external,active) VALUES(p_id,t,JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.address'),JSON_UNQUOTE(p->'$.external')='true',JSON_UNQUOTE(p->'$.active')='true'); END IF;
 CALL sp_audit(t,actor,'BRANCH_SAVED',p_id,JSON_OBJECT('active',p->'$.active'));
END$$
DELIMITER ;
