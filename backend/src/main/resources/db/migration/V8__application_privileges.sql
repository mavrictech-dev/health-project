-- Explicitly revoke Docker's initial ALL grant, whose database pattern is escaped.
-- The application's account is dedicated to this database; Flyway runs separately.
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'health_app'@'%';
GRANT SELECT, EXECUTE ON `health\_project`.* TO 'health_app'@'%';
