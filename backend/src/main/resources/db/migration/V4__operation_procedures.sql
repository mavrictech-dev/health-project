CREATE TABLE workflow_definitions (
 type VARCHAR(60) PRIMARY KEY, module VARCHAR(40) NOT NULL, patient_required BOOLEAN NOT NULL,
 animal_only BOOLEAN NOT NULL DEFAULT FALSE, creators JSON NOT NULL, operators JSON NOT NULL, readers JSON NOT NULL, transitions JSON NOT NULL
);
DELIMITER $$
CREATE PROCEDURE sp_finance_post(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON, IN key_value VARCHAR(100), IN hash_value CHAR(64))
BEGIN
 DECLARE locked_patient CHAR(36); DECLARE previous_hash CHAR(64); DECLARE balance_value BIGINT; DECLARE paid BIGINT; DECLARE refunded BIGINT; DECLARE parent_key CHAR(36);
 CALL sp_write_guard(t,'FINANCE');
 SELECT id INTO locked_patient FROM patients WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.patientId') FOR UPDATE;
 IF locked_patient IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
 SELECT request_hash INTO previous_hash FROM finance_movements WHERE tenant_id=t AND request_key=key_value;
 IF previous_hash IS NOT NULL THEN
  IF previous_hash<>hash_value THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Clave de idempotencia utilizada con otros datos'; END IF;
 ELSE
  SELECT COALESCE(SUM(IF(kind='PAYMENT',-amount_minor,amount_minor)),0) INTO balance_value FROM finance_movements WHERE tenant_id=t AND patient_id=locked_patient;
  IF JSON_UNQUOTE(p->'$.kind')='PAYMENT' AND p->'$.amountMinor'>balance_value THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El pago excede el saldo pendiente'; END IF;
  SET parent_key=NULLIF(JSON_UNQUOTE(p->'$.parentId'),'null');
  IF JSON_UNQUOTE(p->'$.kind')='REFUND' THEN
   SELECT amount_minor INTO paid FROM finance_movements WHERE tenant_id=t AND id=parent_key AND patient_id=locked_patient AND kind='PAYMENT';
   SELECT COALESCE(SUM(amount_minor),0) INTO refunded FROM finance_movements WHERE tenant_id=t AND parent_id=parent_key AND kind='REFUND';
   IF paid IS NULL OR p->'$.amountMinor'>paid-refunded THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Devolución superior al pago disponible'; END IF;
  ELSEIF parent_key IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Solo una devolución referencia un pago'; END IF;
  INSERT INTO finance_movements(id,tenant_id,patient_id,kind,amount_minor,title,parent_id,actor_id,request_key,request_hash) VALUES(p_id,t,locked_patient,JSON_UNQUOTE(p->'$.kind'),p->'$.amountMinor',JSON_UNQUOTE(p->'$.title'),parent_key,actor,key_value,hash_value);
  CALL sp_audit(t,actor,'FINANCE_POSTED',p_id,JSON_OBJECT('kind',JSON_UNQUOTE(p->'$.kind'),'amountMinor',p->'$.amountMinor'));
 END IF;
END$$
CREATE PROCEDURE sp_stock_lot(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 CALL sp_write_guard(t,'INVENTORY');
 IF NOT EXISTS(SELECT 1 FROM branches WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.branchId') AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede inexistente'; END IF;
 INSERT INTO stock_lots(id,tenant_id,branch_id,name,lot,expiry,unit) VALUES(p_id,t,JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.lot'),JSON_UNQUOTE(p->'$.expiry'),JSON_UNQUOTE(p->'$.unit'));
 CALL sp_audit(t,actor,'STOCK_LOT_CREATED',p_id,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_stock_move(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON, IN key_value VARCHAR(100), IN hash_value CHAR(64))
BEGIN
 DECLARE qty DECIMAL(14,3); DECLARE expiry_date DATE; DECLARE previous_hash CHAR(64); DECLARE lot_key CHAR(36); DECLARE patient_key CHAR(36);
 DECLARE prescription_key CHAR(36); DECLARE ordered DECIMAL(14,3); DECLARE dispensed DECIMAL(14,3); DECLARE medication VARCHAR(2000); DECLARE prescribed_unit VARCHAR(2000); DECLARE lot_name VARCHAR(160); DECLARE lot_unit VARCHAR(40);
 CALL sp_write_guard(t,'INVENTORY'); SET lot_key=JSON_UNQUOTE(p->'$.lotId');
 SELECT quantity,expiry,name,unit INTO qty,expiry_date,lot_name,lot_unit FROM stock_lots WHERE tenant_id=t AND id=lot_key FOR UPDATE;
 IF qty IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Lote inexistente'; END IF;
 SELECT request_hash INTO previous_hash FROM stock_movements WHERE tenant_id=t AND request_key=key_value;
 IF previous_hash IS NOT NULL THEN
  IF previous_hash<>hash_value THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Clave utilizada con otros datos'; END IF;
 ELSE
  SET patient_key=NULLIF(JSON_UNQUOTE(p->'$.patientId'),'null');
  SET prescription_key=NULLIF(JSON_UNQUOTE(p->'$.prescriptionId'),'null');
  IF p->'$.quantity'<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Cantidad positiva requerida'; END IF;
  IF patient_key IS NOT NULL AND NOT EXISTS(SELECT 1 FROM patients WHERE tenant_id=t AND id=patient_key) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
  IF JSON_UNQUOTE(p->'$.kind')='DISPENSE' THEN
   CALL sp_write_guard(t,'PHARMACY');
   IF patient_key IS NULL OR prescription_key IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:La dispensación requiere paciente y prescripción'; END IF;
   SELECT c.payload->'$.quantity',JSON_UNQUOTE(c.payload->'$.medication'),JSON_UNQUOTE(c.payload->'$.unit') INTO ordered,medication,prescribed_unit FROM clinical_entries c JOIN encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=t AND c.id=prescription_key AND c.kind='PRESCRIPTION' AND e.patient_id=patient_key FOR UPDATE;
   IF ordered IS NULL OR medication<>lot_name OR prescribed_unit<>lot_unit THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Prescripción, medicamento o unidad incompatibles'; END IF;
   SELECT COALESCE(SUM(quantity),0) INTO dispensed FROM stock_movements WHERE tenant_id=t AND prescription_id=prescription_key AND kind='DISPENSE';
   IF p->'$.quantity'>ordered-dispensed THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Cantidad superior al pendiente de la prescripción'; END IF;
   IF expiry_date<CURRENT_DATE OR p->'$.quantity'>qty THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Lote vencido o cantidad insuficiente'; END IF;
   UPDATE stock_lots SET quantity=quantity-p->'$.quantity' WHERE tenant_id=t AND id=lot_key;
  ELSEIF JSON_UNQUOTE(p->'$.kind')='RECEIVE' AND prescription_key IS NULL THEN UPDATE stock_lots SET quantity=quantity+p->'$.quantity' WHERE tenant_id=t AND id=lot_key;
  ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Tipo de movimiento inválido'; END IF;
  INSERT INTO stock_movements(id,tenant_id,lot_id,kind,quantity,patient_id,prescription_id,actor_id,request_key,request_hash) VALUES(p_id,t,lot_key,JSON_UNQUOTE(p->'$.kind'),p->'$.quantity',patient_key,prescription_key,actor,key_value,hash_value);
  CALL sp_audit(t,actor,'STOCK_MOVED',p_id,JSON_OBJECT('kind',JSON_UNQUOTE(p->'$.kind'),'lotId',lot_key));
 END IF;
END$$
CREATE PROCEDURE sp_transfer_start(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON, IN key_value VARCHAR(100), IN hash_value CHAR(64))
BEGIN
 DECLARE qty DECIMAL(14,3); DECLARE source_branch CHAR(36); DECLARE expiry_date DATE; DECLARE previous_hash CHAR(64); DECLARE lot_key CHAR(36); DECLARE destination CHAR(36);
 CALL sp_write_guard(t,'INVENTORY'); SET lot_key=JSON_UNQUOTE(p->'$.lotId'); SET destination=JSON_UNQUOTE(p->'$.destinationBranchId');
 SELECT quantity,branch_id,expiry INTO qty,source_branch,expiry_date FROM stock_lots WHERE tenant_id=t AND id=lot_key FOR UPDATE;
 IF qty IS NULL OR NOT EXISTS(SELECT 1 FROM branches WHERE tenant_id=t AND id=destination AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Lote o destino inexistentes'; END IF;
 SELECT request_hash INTO previous_hash FROM stock_transfers WHERE tenant_id=t AND request_key=key_value;
 IF previous_hash IS NOT NULL THEN
  IF previous_hash<>hash_value THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Clave utilizada con otros datos'; END IF;
 ELSE
  IF source_branch=destination OR expiry_date<CURRENT_DATE OR p->'$.quantity'>qty THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Destino inválido, lote vencido o stock insuficiente'; END IF;
  UPDATE stock_lots SET quantity=quantity-p->'$.quantity' WHERE tenant_id=t AND id=lot_key;
  INSERT INTO stock_transfers(id,tenant_id,lot_id,destination_branch_id,quantity,status,request_key,request_hash) VALUES(p_id,t,lot_key,destination,p->'$.quantity','IN_TRANSIT',key_value,hash_value);
  CALL sp_audit(t,actor,'TRANSFER_STARTED',p_id,JSON_OBJECT('lotId',lot_key,'destinationBranchId',destination));
 END IF;
END$$
CREATE PROCEDURE sp_transfer_receive(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36))
BEGIN
 DECLARE transfer_status VARCHAR(20); DECLARE lot_key CHAR(36); DECLARE destination CHAR(36); DECLARE qty DECIMAL(14,3);
 CALL sp_write_guard(t,'INVENTORY');
 SELECT status,lot_id,destination_branch_id,quantity INTO transfer_status,lot_key,destination,qty FROM stock_transfers WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF transfer_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Transferencia inexistente'; END IF;
 IF transfer_status='IN_TRANSIT' THEN
  INSERT INTO stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit) SELECT UUID(),t,destination,name,lot,expiry,qty,unit FROM stock_lots WHERE tenant_id=t AND id=lot_key
  ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity);
  UPDATE stock_transfers SET status='RECEIVED',received_at=UTC_TIMESTAMP(6) WHERE tenant_id=t AND id=p_id;
  CALL sp_audit(t,actor,'TRANSFER_RECEIVED',p_id,JSON_OBJECT());
 END IF;
END$$
CREATE PROCEDURE sp_resource_create(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE d VARCHAR(10);
 CALL sp_write_guard(t,'HOSPITAL'); SELECT domain INTO d FROM tenants WHERE id=t;
 IF (d='ANIMAL' AND JSON_UNQUOTE(p->'$.kind')<>'CAGE') OR (d='HUMAN' AND JSON_UNQUOTE(p->'$.kind')<>'BED') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Tipo de recurso incompatible con el dominio'; END IF;
 IF NOT EXISTS(SELECT 1 FROM branches WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.branchId') AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede inexistente'; END IF;
 INSERT INTO hospital_resources(id,tenant_id,branch_id,name,kind) VALUES(p_id,t,JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.name'),JSON_UNQUOTE(p->'$.kind'));
 CALL sp_audit(t,actor,'HOSPITAL_RESOURCE_CREATED',p_id,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_admit(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE resource_key CHAR(36); DECLARE patient_key CHAR(36); DECLARE resource_active BOOLEAN;
 CALL sp_write_guard(t,'HOSPITAL');
 SELECT id INTO patient_key FROM patients WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.patientId') FOR UPDATE;
 SELECT id,active INTO resource_key,resource_active FROM hospital_resources WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.resourceId') FOR UPDATE;
 IF patient_key IS NULL OR resource_key IS NULL OR NOT resource_active THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente o recurso inexistentes'; END IF;
 IF EXISTS(SELECT 1 FROM admissions WHERE tenant_id=t AND status='ADMITTED' AND (resource_id=resource_key OR patient_id=patient_key)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El recurso o paciente tiene una estancia activa'; END IF;
 INSERT INTO admissions(id,tenant_id,patient_id,resource_id,status,reason) VALUES(p_id,t,patient_key,resource_key,'ADMITTED',JSON_UNQUOTE(p->'$.reason'));
 CALL sp_audit(t,actor,'PATIENT_ADMITTED',p_id,JSON_OBJECT('resourceId',resource_key));
END$$
CREATE PROCEDURE sp_discharge(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN expected INT)
BEGIN
 CALL sp_write_guard(t,'HOSPITAL');
 UPDATE admissions SET status='DISCHARGED',discharged_at=UTC_TIMESTAMP(6),revision=revision+1 WHERE tenant_id=t AND id=p_id AND status='ADMITTED' AND revision=expected;
 IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Estancia cerrada o revisión desactualizada'; END IF;
 CALL sp_audit(t,actor,'PATIENT_DISCHARGED',p_id,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_workflow_create(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE feature VARCHAR(40); DECLARE needs_patient BOOLEAN; DECLARE needs_animal BOOLEAN; DECLARE patient_key CHAR(36);
 SELECT module,patient_required,animal_only INTO feature,needs_patient,needs_animal FROM workflow_definitions WHERE type=JSON_UNQUOTE(p->'$.type');
 IF feature IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Tipo de proceso inexistente'; END IF;
 CALL sp_write_guard(t,feature);
 SET patient_key=NULLIF(JSON_UNQUOTE(p->'$.patientId'),'null');
 IF needs_patient AND patient_key IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:El proceso requiere un paciente'; END IF;
 IF patient_key IS NOT NULL AND NOT EXISTS(SELECT 1 FROM patients WHERE tenant_id=t AND id=patient_key) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
 IF needs_animal AND NOT EXISTS(SELECT 1 FROM tenants WHERE id=t AND domain='ANIMAL') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Proceso exclusivo de veterinaria'; END IF;
 IF NOT EXISTS(SELECT 1 FROM branches WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.branchId') AND active) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Sede inexistente'; END IF;
 INSERT INTO workflow_cases(id,tenant_id,branch_id,patient_id,type,status,title,payload,actor_id) VALUES(p_id,t,JSON_UNQUOTE(p->'$.branchId'),patient_key,JSON_UNQUOTE(p->'$.type'),'DRAFT',JSON_UNQUOTE(p->'$.title'),p->'$.payload',actor);
 INSERT INTO workflow_history(tenant_id,case_id,revision,status,payload,actor_id) VALUES(t,p_id,1,'DRAFT',p->'$.payload',actor);
 CALL sp_audit(t,actor,'WORKFLOW_CREATED',p_id,JSON_OBJECT('type',JSON_UNQUOTE(p->'$.type')));
END$$
CREATE PROCEDURE sp_workflow_step(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN expected INT, IN next_status VARCHAR(40), IN new_payload JSON)
BEGIN
 DECLARE current_status VARCHAR(40); DECLARE type_name VARCHAR(60); DECLARE rev INT; DECLARE steps JSON; DECLARE feature VARCHAR(40);
 SELECT status,type,revision INTO current_status,type_name,rev FROM workflow_cases WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF current_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Proceso inexistente'; END IF;
 SELECT transitions,module INTO steps,feature FROM workflow_definitions WHERE type=type_name;
 CALL sp_write_guard(t,feature);
 IF rev<>expected THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Revisión del proceso desactualizada'; END IF;
 IF NOT COALESCE(JSON_CONTAINS(JSON_EXTRACT(steps,CONCAT('$.',current_status)),JSON_QUOTE(next_status)),FALSE) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Transición de estado no permitida'; END IF;
 UPDATE workflow_cases SET status=next_status,payload=new_payload,revision=revision+1,updated_at=UTC_TIMESTAMP(6),actor_id=actor WHERE tenant_id=t AND id=p_id;
 INSERT INTO workflow_history(tenant_id,case_id,revision,status,payload,actor_id) VALUES(t,p_id,rev+1,next_status,new_payload,actor);
 CALL sp_audit(t,actor,'WORKFLOW_ADVANCED',p_id,JSON_OBJECT('status',next_status,'revision',rev+1));
END$$
DELIMITER ;
