DELIMITER $$
CREATE PROCEDURE sp_professional_guard(IN t CHAR(36), IN u CHAR(36), IN b CHAR(36), IN spec VARCHAR(100))
BEGIN
 DECLARE found_user CHAR(36);
 SELECT id INTO found_user FROM users WHERE id=u AND active FOR UPDATE;
 IF found_user IS NULL OR NOT EXISTS(SELECT 1 FROM memberships m JOIN membership_branches mb ON mb.tenant_id=m.tenant_id AND mb.user_id=m.user_id JOIN membership_specialties ms ON ms.tenant_id=m.tenant_id AND ms.user_id=m.user_id JOIN branches br ON br.tenant_id=mb.tenant_id AND br.id=mb.branch_id WHERE m.tenant_id=t AND m.user_id=u AND m.status='ACTIVE' AND JSON_CONTAINS(m.roles,'"PRO"') AND mb.branch_id=b AND br.active AND ms.specialty_code=spec) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_FORBIDDEN:Profesional sin asignación activa en esta sede y especialidad'; END IF;
END$$
CREATE PROCEDURE sp_patient_save(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON, IN expected INT)
BEGIN
 DECLARE d VARCHAR(10); DECLARE previous_domain VARCHAR(10);
 CALL sp_write_guard(t,'CORE'); SELECT domain INTO d FROM tenants WHERE id=t;
 IF JSON_UNQUOTE(p->'$.domain')<>d OR (d='ANIMAL' AND (JSON_UNQUOTE(p->'$.species')='null' OR JSON_UNQUOTE(p->'$.species')='')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Revisa el dominio y especie del paciente'; END IF;
 IF expected=0 THEN
  INSERT INTO patients(id,tenant_id,name,domain,identifier,birth_date,species,contact,allergies) VALUES(p_id,t,JSON_UNQUOTE(p->'$.name'),d,JSON_UNQUOTE(p->'$.identifier'),NULLIF(JSON_UNQUOTE(p->'$.birthDate'),'null'),NULLIF(JSON_UNQUOTE(p->'$.species'),'null'),p->'$.contact',p->'$.allergies');
 ELSE
  SELECT domain INTO previous_domain FROM patients WHERE tenant_id=t AND id=p_id FOR UPDATE;
  IF previous_domain IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
  UPDATE patients SET name=JSON_UNQUOTE(p->'$.name'),identifier=JSON_UNQUOTE(p->'$.identifier'),birth_date=NULLIF(JSON_UNQUOTE(p->'$.birthDate'),'null'),species=NULLIF(JSON_UNQUOTE(p->'$.species'),'null'),contact=p->'$.contact',allergies=p->'$.allergies',revision=revision+1 WHERE tenant_id=t AND id=p_id AND revision=expected;
  IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Revisión del paciente desactualizada'; END IF;
 END IF;
 CALL sp_audit(t,actor,'PATIENT_SAVED',p_id,JSON_OBJECT('revision',expected+1));
END$$
CREATE PROCEDURE sp_patient_link(IN t CHAR(36), IN p_patient CHAR(36), IN u CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 CALL sp_write_guard(t,'PORTAL');
 IF NOT EXISTS(SELECT 1 FROM patients WHERE tenant_id=t AND id=p_patient) OR NOT EXISTS(SELECT 1 FROM memberships WHERE tenant_id=t AND user_id=u AND (JSON_CONTAINS(roles,'"PAC"') OR JSON_CONTAINS(roles,'"RES"'))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente o cuenta de portal no disponibles'; END IF;
 INSERT INTO patient_links VALUES(t,p_patient,u,JSON_UNQUOTE(p->'$.relationship'),JSON_UNQUOTE(p->'$.active')='true',p->'$.scopes') ON DUPLICATE KEY UPDATE relationship=VALUES(relationship),active=VALUES(active),scopes=VALUES(scopes);
 CALL sp_audit(t,actor,'PORTAL_LINK_CHANGED',p_patient,JSON_OBJECT('userId',u,'active',p->'$.active'));
END$$
CREATE PROCEDURE sp_appointment_reserve(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON, IN request_key_value VARCHAR(100), IN request_hash_value CHAR(64))
BEGIN
 DECLARE existing_id CHAR(36); DECLARE previous_hash CHAR(64); DECLARE starts DATETIME(6); DECLARE ends DATETIME(6);
 CALL sp_write_guard(t,'CORE');
 CALL sp_professional_guard(t,JSON_UNQUOTE(p->'$.professionalId'),JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.specialtyCode'));
 SELECT id,request_hash INTO existing_id,previous_hash FROM appointments WHERE tenant_id=t AND request_key=request_key_value;
 IF existing_id IS NOT NULL THEN
  IF previous_hash<>request_hash_value THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La clave de idempotencia ya se utilizó con otros datos'; END IF;
 ELSE
  IF NOT EXISTS(SELECT 1 FROM patients WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.patientId')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
  SET starts=CAST(JSON_UNQUOTE(p->'$.startsAt') AS DATETIME(6)); SET ends=CAST(JSON_UNQUOTE(p->'$.endsAt') AS DATETIME(6));
  IF EXISTS(SELECT 1 FROM appointments WHERE professional_id=JSON_UNQUOTE(p->'$.professionalId') AND status NOT IN ('CANCELLED','WITHDRAWN') AND starts_at<ends AND ends_at>starts) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El profesional ya tiene una cita en ese horario'; END IF;
  INSERT INTO appointments(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,request_key,request_hash)
  VALUES(p_id,t,JSON_UNQUOTE(p->'$.patientId'),JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.professionalId'),JSON_UNQUOTE(p->'$.specialtyCode'),starts,ends,JSON_UNQUOTE(p->'$.status'),JSON_UNQUOTE(p->'$.service'),JSON_UNQUOTE(p->'$.note'),request_key_value,request_hash_value);
  CALL sp_audit(t,actor,'APPOINTMENT_RESERVED',p_id,JSON_OBJECT());
 END IF;
END$$
CREATE PROCEDURE sp_appointment_change(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN expected INT, IN next_status VARCHAR(20), IN starts DATETIME(6), IN ends DATETIME(6))
BEGIN
 DECLARE pro CHAR(36); DECLARE b CHAR(36); DECLARE spec VARCHAR(100); DECLARE rev INT; DECLARE locked_user CHAR(36);
 CALL sp_write_guard(t,'CORE');
 SELECT professional_id,branch_id,specialty_code,revision INTO pro,b,spec,rev FROM appointments WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF pro IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Cita inexistente'; END IF;
 IF rev<>expected THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La cita cambió; vuelve a consultarla'; END IF;
 SELECT id INTO locked_user FROM users WHERE id=pro FOR UPDATE;
 IF starts IS NOT NULL THEN
  CALL sp_professional_guard(t,pro,b,spec);
  IF EXISTS(SELECT 1 FROM appointments WHERE id<>p_id AND professional_id=pro AND status NOT IN ('CANCELLED','WITHDRAWN') AND starts_at<ends AND ends_at>starts) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El nuevo horario está ocupado'; END IF;
  UPDATE appointments SET starts_at=starts,ends_at=ends WHERE tenant_id=t AND id=p_id;
 END IF;
 UPDATE appointments SET status=next_status,revision=revision+1 WHERE tenant_id=t AND id=p_id;
 CALL sp_audit(t,actor,'APPOINTMENT_CHANGED',p_id,JSON_OBJECT('status',next_status,'revision',rev+1));
END$$
CREATE PROCEDURE sp_encounter_start(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE locked_patient CHAR(36);
 CALL sp_write_guard(t,'CORE'); CALL sp_professional_guard(t,actor,JSON_UNQUOTE(p->'$.branchId'),JSON_UNQUOTE(p->'$.specialtyCode'));
 SELECT id INTO locked_patient FROM patients WHERE tenant_id=t AND id=JSON_UNQUOTE(p->'$.patientId') FOR UPDATE;
 IF locked_patient IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
 INSERT INTO encounters(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,status,note,profile_snapshot) SELECT p_id,t,locked_patient,JSON_UNQUOTE(p->'$.branchId'),actor,code,'ACTIVE','',profile FROM specialties WHERE code=JSON_UNQUOTE(p->'$.specialtyCode');
 CALL sp_audit(t,actor,'ENCOUNTER_STARTED',p_id,JSON_OBJECT());
END$$
CREATE PROCEDURE sp_encounter_save(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN expected INT, IN p_note MEDIUMTEXT, IN finalize_visit BOOLEAN)
BEGIN
 CALL sp_write_guard(t,'CORE');
 IF NOT EXISTS(SELECT 1 FROM encounters WHERE tenant_id=t AND id=p_id AND professional_id=actor) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Atención no disponible para este profesional'; END IF;
 UPDATE encounters SET note=p_note,revision=revision+1,status=IF(finalize_visit,'FINALIZED',status),finalized_at=IF(finalize_visit,UTC_TIMESTAMP(6),NULL) WHERE tenant_id=t AND id=p_id AND professional_id=actor AND revision=expected AND status<>'FINALIZED';
 IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Atención finalizada o revisión desactualizada'; END IF;
 CALL sp_audit(t,actor,IF(finalize_visit,'ENCOUNTER_FINALIZED','ENCOUNTER_SAVED'),p_id,JSON_OBJECT('revision',expected+1));
END$$
CREATE PROCEDURE sp_clinical_entry(IN t CHAR(36), IN p_id CHAR(36), IN encounter_key CHAR(36), IN actor CHAR(36), IN p_kind VARCHAR(20), IN p_payload JSON)
BEGIN
 DECLARE s VARCHAR(20);
 CALL sp_write_guard(t,'CORE');
 SELECT status INTO s FROM encounters WHERE tenant_id=t AND id=encounter_key FOR UPDATE;
 IF s IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Atención inexistente'; END IF;
 IF s='FINALIZED' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:La atención está finalizada'; END IF;
 IF p_kind='ANNOTATION' AND JSON_UNQUOTE(p_payload->'$.component') IN ('HUMAN_DENTAL','VET_DENTAL','PERIODONTAL','ENDO','ORTHODONTIC','PROSTHETIC') THEN CALL sp_write_guard(t,'DENTAL'); END IF;
 INSERT INTO clinical_entries(id,tenant_id,encounter_id,kind,payload,profile_snapshot,actor_id) SELECT p_id,t,encounter_key,p_kind,p_payload,profile_snapshot,actor FROM encounters WHERE tenant_id=t AND id=encounter_key;
 CALL sp_audit(t,actor,'CLINICAL_ENTRY_ADDED',p_id,JSON_OBJECT('kind',p_kind,'encounterId',encounter_key));
END$$
CREATE PROCEDURE sp_document_create(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN p JSON)
BEGIN
 DECLARE patient_key CHAR(36); DECLARE original_key CHAR(36); DECLARE encounter_key CHAR(36);
 CALL sp_write_guard(t,'CORE'); SET patient_key=JSON_UNQUOTE(p->'$.patientId'); SET original_key=NULLIF(JSON_UNQUOTE(p->'$.originalId'),'null'); SET encounter_key=NULLIF(JSON_UNQUOTE(p->'$.encounterId'),'null');
 IF NOT EXISTS(SELECT 1 FROM patients WHERE tenant_id=t AND id=patient_key) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Paciente inexistente'; END IF;
 IF original_key IS NOT NULL AND NOT EXISTS(SELECT 1 FROM documents WHERE tenant_id=t AND id=original_key AND patient_id=patient_key AND status='SIGNED') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Documento original no disponible'; END IF;
 IF encounter_key IS NOT NULL AND NOT EXISTS(SELECT 1 FROM encounters WHERE tenant_id=t AND id=encounter_key AND patient_id=patient_key) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:La atención no corresponde al paciente'; END IF;
 INSERT INTO documents(id,tenant_id,patient_id,encounter_id,title,type,content,status,original_id) VALUES(p_id,t,patient_key,encounter_key,JSON_UNQUOTE(p->'$.title'),JSON_UNQUOTE(p->'$.type'),JSON_UNQUOTE(p->'$.content'),'DRAFT',original_key);
 CALL sp_audit(t,actor,'DOCUMENT_CREATED',p_id,JSON_OBJECT('originalId',original_key));
END$$
CREATE PROCEDURE sp_document_change(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36), IN expected INT, IN operation_name VARCHAR(20), IN new_content MEDIUMTEXT)
BEGIN
 DECLARE document_status VARCHAR(20); DECLARE rev INT; DECLARE patient_key CHAR(36);
 CALL sp_write_guard(t,'CORE');
 SELECT status,revision,patient_id INTO document_status,rev,patient_key FROM documents WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF document_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Documento inexistente'; END IF;
 IF rev<>expected THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Revisión documental desactualizada'; END IF;
 IF operation_name IN ('SAVE','SIGN') AND document_status<>'DRAFT' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:El documento firmado es inmutable; utiliza una adenda'; END IF;
 IF operation_name='SAVE' THEN UPDATE documents SET content=new_content,revision=revision+1 WHERE tenant_id=t AND id=p_id;
 ELSEIF operation_name='SIGN' THEN UPDATE documents SET status='SIGNED',signer_id=actor,signed_at=UTC_TIMESTAMP(6),content_hash=SHA2(content,256),revision=revision+1 WHERE tenant_id=t AND id=p_id;
 ELSEIF operation_name='PUBLISH' THEN
  CALL sp_write_guard(t,'PORTAL');
  IF document_status<>'SIGNED' OR NOT EXISTS(SELECT 1 FROM patient_links WHERE tenant_id=t AND patient_id=patient_key AND active AND JSON_CONTAINS(scopes,'"DOCUMENTS"')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_CONFLICT:Se requiere firma y un vínculo vigente de documentos'; END IF;
  UPDATE documents SET published=TRUE,withdrawn=FALSE,revision=revision+1 WHERE tenant_id=t AND id=p_id;
 ELSEIF operation_name='WITHDRAW' THEN UPDATE documents SET published=FALSE,withdrawn=TRUE,revision=revision+1 WHERE tenant_id=t AND id=p_id;
 ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_INVALID:Operación documental inválida'; END IF;
 CALL sp_audit(t,actor,CONCAT('DOCUMENT_',operation_name),p_id,JSON_OBJECT('revision',rev+1));
END$$
DELIMITER ;
