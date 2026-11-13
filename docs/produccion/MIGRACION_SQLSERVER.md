# Correccion de persistencia a SQL Server

Actualizacion 2026-11-12 (D-87.AR): usuario habilito Docker y autoriza continuar.
Dockerdesktop-linux operativo; imagen oficialSQL2022 descargada por digest.
Se prepara entorno sintetico NUEVO separado segun PAC-01-C1-DOCKER-P1.md.
Esta autorizacion sustituye limitesDocker historicos siguientes, sin cambiar
SQLServer100%SP, activar composeMySQLheredado o permitir tocar recursosajenos.

Autoridad: aclaracion directa del usuario del 3 de noviembre de 2026; D-09 y docs/Arquitectura_Health_Project.md, secciones 2 y 9. Objetivo: SQL Server y 100 % acceso de datos por SP parametrizados. El backend existente sigue en MySQL; esta migracion no esta implementada ni validada.

## Discrepancia comprobada

- Arquitectura: SQL Server; cuenta runtime sin permisos directos de tablas/DDL; lecturas, sesiones, auditoria y salud mediante SP.
- Plan de produccion: linea22 declara MySQL vigente y llama historicas a referencias SQL Server. Esa decision queda sustituida por instruccion del usuario, sin editar el archivo protegido.
- backend/pom.xml: flyway-mysql y mysql-connector-j. application.yml y compose.yaml: JDBC MySQL; imagen mysql8.4. compose.qa.yaml y runners de QA tambien dependen de MySQL.
- Sql.java usa queryForList y variables @hp_* de MySQL; el helper call descarta resultsets, por lo que no permite sustituir lecturas por SP sin ampliar su contrato. SessionFilter y otros servicios consultan tablas mediante SQL directo.
- Inventario textual: 11 migraciones SQL, 60 declaraciones CREATE PROCEDURE y 53 nombres distintos; 116 llamadas a sql.rows/one/optional en 22 archivos Java. Se conserva evidencia en tmp/sqlserver-architecture-audit.json; los conteos no equivalen a sentencias unicas ni cobertura ejecutada.

## Paquetes secuenciales y ownership a fijar antes de cada Dispatch

1. SQL-01.A: contrato fisico y primer recorrido de infraestructura/identidad. Definir resultsets, tipos, JSON, UTC, errores y transaccion; elaborar esquema SQL Server y SP de contexto/sesion/estado/salud con permisos por procedimiento. Revisar compatibilidad de contratos HTTP antes de sustituir el backend. No activar un backend parcial como si todos los recorridos estuvieran migrados.
2. SQL-01.B: portar SaaS/organizacion y restantes modulos, reemplazar TODOS los helpers de lectura directa por llamadas a SP aprobados. Incluir autenticacion, trazabilidad, idempotencia y auditoria; controlar IDs y tenant en servidor. Los contratos HTTP deben preservarse o versionarse conscientemente.
3. SQL-01.C: entorno sintetico SQL Server separado; adaptacion de suites y permisos. Cuenta de migracion separada; runtime EXECUTE solo sobre SP aprobados, sin SELECT/INSERT/UPDATE/DELETE a tablas ni DDL. Cualquier migracion de datos existentes necesita inventario/validacion y conserva la fuente; ninguna eliminacion automatica.

Cada paquete requiere ownership concreto antes de delegar al Codex retenido. El supervisor sigue siendo unico escritor de tablero/decisiones/revisiones. No modificar archivos asignados simultaneamente. No commit/push/main, gastos, publicacion ni datos reales. No arrancar/reiniciar Docker sin revocar el limite vigente.

## Aceptacion

- Cero consultas directas a tablas desde el runtime Java, incluidos health checks, filtros de sesion y tareas internas. Llamadas JDBC a SP con nombres permitidos y parametros declarados. DDL solo por migraciones con cuenta separada.
- Driver/migrador, esquema y procedimientos realmente compatibles con SQL Server; sin variables de sesion, funciones o sintaxis MySQL pendientes. El adaptador consume resultsets/parametros/errores del SP, sin SQL proporcionado por cliente.
- Cuenta runtime puede ejecutar solo SP aprobados; pruebas negativas de lectura/escritura directa/DDL. SP no deben conceder escape mediante SQL dinamico arbitrario.
- Tenant y actor validados; transacciones dirigidas por Spring, sin commits autonomos ocultos; rollback, conflictos e idempotencia probados en SQL Server real con datos sinteticos.
- Primer recorrido completo: contexto de host, login, lectura y revocacion de sesion, estado/salud y auditoria; despues repetir SaaS/organizacion y suites por modulo.
- Pruebas anteriores frontend/interceptadas se conservan, pero no acreditan SQL Server. Docker sigue sin daemon; se descubrio SQL Server2022 local ya ejecutandose y se creo base sintetica exclusiva health_project_sqlserver_qa_20261103 (D-10). Se usara este motor para validacion, sin tocar otras bases ni cambiar autenticacion de instancia.
