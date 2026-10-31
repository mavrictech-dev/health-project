#!/bin/sh
set -eu
MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot <<'SQL'
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'health_app'@'%';
GRANT SELECT, EXECUTE ON `health\_project`.* TO 'health_app'@'%';
SQL
