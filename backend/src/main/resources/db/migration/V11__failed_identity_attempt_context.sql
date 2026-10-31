DELIMITER $$
DROP PROCEDURE sp_login_failure$$
CREATE PROCEDURE sp_login_failure(IN u CHAR(36), IN t CHAR(36))
BEGIN
 IF u IS NOT NULL THEN UPDATE users SET login_failures=IF(locked_until IS NOT NULL AND locked_until<UTC_TIMESTAMP(6),1,login_failures+1),locked_until=IF(login_failures>=5,UTC_TIMESTAMP(6)+INTERVAL 15 MINUTE,locked_until) WHERE id=u; END IF;
 CALL sp_audit(t,NULL,'LOGIN_FAILED',COALESCE(u,'unknown'),JSON_OBJECT('result','REJECTED','attemptedAccountId',u));
END$$
DELIMITER ;
