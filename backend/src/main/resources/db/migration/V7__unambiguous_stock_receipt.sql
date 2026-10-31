DELIMITER $$
DROP PROCEDURE sp_transfer_receive$$
CREATE PROCEDURE sp_transfer_receive(IN t CHAR(36), IN p_id CHAR(36), IN actor CHAR(36))
BEGIN
 DECLARE transfer_status VARCHAR(20); DECLARE lot_key CHAR(36); DECLARE destination CHAR(36); DECLARE qty DECIMAL(14,3);
 CALL sp_write_guard(t,'INVENTORY');
 SELECT status,lot_id,destination_branch_id,quantity INTO transfer_status,lot_key,destination,qty FROM stock_transfers WHERE tenant_id=t AND id=p_id FOR UPDATE;
 IF transfer_status IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='HP_NOT_FOUND:Transferencia inexistente'; END IF;
 IF transfer_status='IN_TRANSIT' THEN
  INSERT INTO stock_lots(id,tenant_id,branch_id,name,lot,expiry,quantity,unit)
   SELECT UUID(),t,destination,src.name,src.lot,src.expiry,qty,src.unit FROM stock_lots src WHERE src.tenant_id=t AND src.id=lot_key
   ON DUPLICATE KEY UPDATE quantity=stock_lots.quantity+VALUES(quantity);
  UPDATE stock_transfers SET status='RECEIVED',received_at=UTC_TIMESTAMP(6) WHERE tenant_id=t AND id=p_id;
  CALL sp_audit(t,actor,'TRANSFER_RECEIVED',p_id,JSON_OBJECT());
 END IF;
END$$
DELIMITER ;
