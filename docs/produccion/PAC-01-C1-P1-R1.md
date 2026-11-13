# PAC-01.C1.P1.R1: compatibilidad con transaccion JDBC inicial

Contrato supervisor, 2026-11-12. Continuidad autorizada por el usuario mientras
se prepara otra base Somee. AgendlyCitas queda excluida: sin conexiones remotas.
Paquete exclusivamente OFFLINE, anterior a C2 y a cualquier instalacion.

Leer AGENTS.md, docs/agent-workflow.md, TAREAS.md, PAC-01-C1-P1.md completo
(incluida Q1), este contrato y evidencias/VINCULOS_REVISION_C1P1_20261112.json
en el checkout CANONICO D:/Mavric/Health Project. No confiar en docs antiguos
del worktree. Mantener Run run_624b9269b491, programador recuperapiura,
worktree/sesion retenidos, cuenta por proceso y --no-daemon. Usar IDs NUEVOS
del preambulo, no los IDs historicos de la primera entrega.

## Defecto bloqueante R-C1P1-01

Entrega task_610a2325b428 / ctx_59a792d9cc2d succeeded de PREPARACION,
NO aprobada/integrada. V14 SHA
461DD6AD33264505CE983174B0C7E5CC66E3F9B66C3D65D6A141B8A7937F7714.
Supervisor leyo fuente completa y verifico32artefactos/695fuentes/726pines/
301historicos/21snapshots/28artefactosC0 sin cambios. Parser160 independiente:
cinco batches/0errores, sin motor. ACK5/edit8/retirada y2ACL presentes en fuente,
comportamiento real pendiente de QA.

Los cuerpos writer/edit_get, lineas488/695, rechazan @@TRANCOUNT=0 ANTES del
helper V10. Microsoft JDBC setAutoCommit(false) selecciona IMPLICIT_TRANSACTIONS;
request_context y EXEC por si solos no materializan TX. Executor hace contexto
y RPC; Store entra en TransactionTemplate sin lectura previa; Access.write
consulta valores en memoria. La primera operacion puede recibir51000 pese a
que Spring ya selecciono TX. Es inferencia desde fuentes/documentacion, NO
reproduccion nueva SQL/JDBC. C0 seccion1 preserva explicitamente semantica V10.

V10 usp_require_transaction materializa SOLO si el caller eligio el modo
implicito y el contador sigue0, mediante lectura interna sin BEGIN/COMMIT.
Autocommit continua rechazado. C1.P1 no autoriza perder esta compatibilidad
ni depender de otra lectura de negocio anterior.

Fuentes primarias:
- https://learn.microsoft.com/en-us/sql/connect/jdbc/reference/setautocommit-method-sqlserverconnection
- https://learn.microsoft.com/en-us/sql/t-sql/statements/set-implicit-transactions-transact-sql

## Ownership exclusivo y correccion

Programador SOLO modifica su fuente NO INSTALADA:
backend/src/main/resources/db/sqlserver/V14__patient_link_revision.sql.
Puede crear TEMP NUEVOS C1P1R1-* para snapshot/diff/parser/plan/reporte.
Supervisor es unico escritor docs/tablero/revision y checkout principal.

En AMBOS cuerpos nuevos reutilizar usp_require_transaction V10 para materializar
solo TX implicita ya elegida ANTES de exigir estado committable. Mantener
rechazo autocommit y TX doomed, sin resultados/auditoria/cambios de negocio
anteriores. Puede rechazar doom antes del helper; guard posterior exige
@@TRANCOUNT>0 y XACT_STATE=1. Sin BEGIN/COMMIT/ROLLBACK autonomos, SQL dinamico,
retry, helper nuevo o lectura de negocio para aparentar compatibilidad.
NO editar V10/helper/executor. Guardas de INSTALACION siguen exigiendo TX
abierta: esta correccion corresponde solo a cuerpos runtime.

Actualizar comentarios y NUEVO plan de casos para distinguir TX explicita,
implicita aun no materializada, autocommit y doom. Resto C1.P1/Q1 intacto:
CAS/INTMAX/no-op/locks/contexto/elegibilidad/retirada/audit/ACK5/edit8,
guardas/hash/ACL/firmas y V13/B. No sincronizar worktree ni copiar V10-V12 que
faltaban historicamente; leer V10 CANONICA. No editar otras fuentes/Java/API/UI,
verificadores/config/deps/AGENTS/docs o evidencia historica del primer paquete.

## Verificacion y entrega

- Preservar primero snapshot/diff/hash original y baseline fuentes/pines/historia.
  Al cierre, unica fuente modificada V14 y ninguna adicion de producto. Conservar
  los32artefactos anteriores, informe y snapshots. No sobrescribir C1P1-*.
- Parser TSQL160 local instalado, sin dependencias nuevas. Examinar delta de los
  dos cuerpos/comentarios. Sin suites/builds aprobados no relacionados.
- NUEVO plan NO EJECUTADO: ambos RPC primera llamada JDBC setAutoCommit(false),
  misma conexion tras commit/rollback, TX explicita, autocommit, doom, fallo y
  rollback sin negocio/audit persistente, compatibilidad Spring/pool. La sintaxis
  no prueba motor/JDBC. Verificador operativo sera paquete separado.
- TEMP/C1P1R1-programmer-report.json con IDs/SHA/diff/snapshot/comandos/exits,
  conservacion y limites. succeeded significa preparado EN_REVISION, no instalado.
  SQL/JDBC/HTTP/DPAPI/navegador/servicios/TLS/UAC/Docker/fixtures/cuentas globales/
  secretos/Somee NO autorizados en R1. Sin commit/push/main/despliegue/gastos/
  destinatarios o datos reales/FactuEz.
- Procesar todos los lotes y ACK de deliveryId si aparece antes de worker_done;
  conservar terminal. Ante dudas/cambio adicional, preguntar por Orca antes de
  ampliar ownership. Integracion requiere revision supervisora independiente;
  C2 compatible, verificador/QA SQL e instalacion siguen como gates separados.
