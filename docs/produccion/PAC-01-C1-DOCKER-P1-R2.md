# PAC-01.C1.DOCKER.P1.R2: corregir guarda y completar base con gate supervisor

Contrato supervisor, 2026-11-12. Continuidad Docker local autorizada. DOSFASES:
I implementacion OFFLINE; II completarDB propia SOLO tras pregunta/review/recibo
explicito del supervisor por Orca. No invocar procesos Docker/SQL antes del gate.
No pedir permiso al usuario: este gate es revision del coordinador arquitecto.
Leer AGENTS/flujo/TAREAS, P1/Q1/R1/PIN/PROVISION/RECONCILE/DIAG-E1/E2 y D-87.AY
CANONICOS en D:/Mavric/Health Project. Misma pareja/cuentasporproceso/--no-daemon/
terminal/sesion/worktree; IDsNUEVOS del preambulo. Supervisor unico escritor docs.

## Hechos y cambio autorizado

DIAG-E2 task_d8a859935952/ctx_8a5b6895111a done msg_bd2a594aa1ae diagnostica
12predicados/17facts validos:11true, solo xactState0false; count0/state1/optionsOFF,
MachineNameEXACT54/loginSA4/major16/Developer/TCP, targetAbsenttrue/userDBcount0.
No inferir TXexplicita a partir de state1cuando count0. XACT_STATE indica estado
committable; @@TRANCOUNT cuenta profundidad de transacciones. El caso observado
es evaluacion de statement sin BEGIN abierto, no permiso para operar con TX
externa/doomed o para relajar SP/guardas de negocio. Fuentes oficiales:
https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql
https://learn.microsoft.com/en-us/sql/t-sql/functions/trancount-transact-sql

Cambiar SOLO clausula transaccional de engine_guard administrativo Docker:
conservar @@TRANCOUNT<>0 como rechazo y aceptar XACT_STATE SOLO0o1, rechazar-1
y cualquier otro valor. Usar expresion explicita NOT IN (0,1) junto al OR de
contador. Todas las demas clausulas host/version/edicion/TCP/sa/owner, pines,
ACL/DDL/canonicas, readonlyframes, orden/args/timeouts/secretos/journal permanecen.
No cambiar `IF @@TRANCOUNT<>1 OR XACT_STATE()<>1` antes de COMMIT de migraciones.
No SET/COMMIT/ROLLBACK extra para fabricar estado0, suprimirerror o activar SQL.

## Ownership fase I, solo dosfuentes existentes en worker

- scripts/health-sqlserver-docker-qa.py (actual6F5FE612...32CA2A)
- scripts/tests/test_health_sqlserver_docker_qa.py (actualD05D8A5D...22E73A)

Mas TEMP NUEVOS C1DockerP1R2-* para snapshot/diff/tests/SQL/helper/candidato/reporte.
Baseline717 entrecheckouts,2deltaspermitidos/0adiciones. No ROOT/otrasfuentes/
V1-V14/runnerLPC/template/Java/frontend/config/deps/AGENTS/docs/artefactosviejos.
No sync/reset, cuenta/contextoglobal, serviciosWindows/Somee/AgendlyCitas/FactuEz.

Fase I: offline, subprocess/socket doblados en tests. Preservar35tests previos
y verificar corpus cincoSQL completos: UNICOdelta aprobado es la clausula
engine_guard, ninguna diferencia dentro de bytesV1-V13 o otras guardas/BEGIN/
COMMIT. Comparar AST/clausula y modelos41comandos/6mutaciones argv/payloadENV:
solo SQLguarddelta, nada de-h. No tests que presenten un modelo como prueba de
estadoSQLreal; conservacion/AST prueban estructura, aceptacionmotor sera faseII.
Si parsea SQL nuevo, solo sintaxislocal; no repetirMaven/frontend/suitesajenas.
Confirmar count0/state0 y count0/state1 admitidos por politica, count>0 o doom
rechazados sin perder otrasguardas; no fabricar esos estados en el motor ahora.

Preparar tambien helperTEMP de faseII con commandplan y SQL completas para
review, pero NOejecutarlo. Import/plan/generar no abre proceso/socket. CLIhelper
--execute debe exigir ANTES de procesos el recibo supervisor fijo
ROOT/tmp/c1docker-r2-complete-20261112/approval.json, su SHA comunicado por Orca,
helper/source/manifest pins y target exactos. Este archivo NO existe/no lo crea
el trabajador. Candidatos son reviewedfalse/no aprobacion operativa.

## STOP al gate: pregunta por Orca antes de faseII

Tras codigo/tests/helper congelados, preguntar al coordinador mediante ask del
preambulo y terminar turno esperando respuesta. Adjuntar TEMP/C1DockerP1R2-stage1-report.json
con2SHA/snapshot/diff/35tests+extras si necesarios/corpus5SQL/AST/conservacion,
helperSHA/comandos/SQL/candidato. No worker_done aun si espera faseII; no ejecutar
ni editar nada congelado despues de pedir revision. Supervisor revisa delta y
pruebas propias, integra2rutasROOT porSHA, crea NUEVOmanifest de fuentes con
pininner447775C5...05ADC y reciboapproval con helperSHA/manifestSHA/CID/scope.
RespuestaOrca negativa o sinrecibo implica mantener FASEI/STOP, nunca interpretarla
como permiso para cambiar alcance. Si requierecorreccion, consultar/revisar de nuevo.

Tras integracion supervisora, fijar baselinefresh717fuentes con2deltasworker y
2deltasROOT autorizadas separadamente. No reportar esas copias del supervisor
como cambios ajenos del worker ni permitir cualquier otrodelta durante faseII.

## FaseII condicionada: completar recursos PROPIOS existentes una vez

Solo tras respuestaexplicita y recibopinneado. NO usar CLI PROVISION original:
sus guards de colision siguen intactas, no se eliminan o evaden para reejecutarlo.
Helperacotado usa funcionesSQL/transport/evidencia revisadas ROOT con fuentes
actualizadas; no monkeypatch en vuelo. Puede reusar metodos de Provisioner
sin execute, fijando SOLO CID/volumen/runlabel ya propios segun recibo revisado.
El runlabel del recurso no se cambia por el ID de esta operacion.

CID UNICO4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
volumenhealthproject-c1qa-20261112-data y runlabela52e4ded46af4fe29d9f16a28b938719;
hostnamehealthproject-c1qa-20261112, loopback127.0.0.1:14436, imagen4525e3ef...13b7f/
CLI6C699720...6896/contextdesktop-linux/npipeapproved. Pincontainerparado3b39d275...
se conserva sin operar. No create/start/restart/reset/delete/adopt o nuevosrecursos.

Secuencia acotada: contexto/daemon/imagen/volumen/CIDrunning/guards/pin -> UNA
readiness SQL readonlymaster con engine_guard corregido y DBtargetausente ->
create_databaseUNAvez fueraTX -> configure_database compat160/marker ->
apply_v1_v13 en UNATXexterna/GO/COMMITfinal -> verify_database conexionNUEVA.
Usar SQL_STAGES y SQL byteexacta generada de fuentes revisadas, cada faseUNAvez;
no codigoSQLlibre añadido al apply. ChecksC1 antes de cada SQLcomo tooling,
cuentaSA migradora propia soloexportinsidecontainer. No passwordargv/Config.Env/
envarchivo/envglobal o cuentaSA runtime. Modelo de commands plan fijado en faseI.

DBobjetivo health_project_c1_docker_qa_20261112. Si freshreadiness no acredita
DBausente/target/guardas, STOP sin crear/adoptar. No V14/Flywayhistory/fixtures
reales/PROVISIONCLI/negocio/backend/frontend/Windows/Somee. Expectativa nueva:
37tablas/134SP/31triggers/564ACLroles/V13presente/V14ausente/OPEN/ownerSQLsa,
hashesinternos37tablas/catalogo sin rawfilas. Esto no prueba PRE111/JDBC/TLS/UI.

Evidence NUEVA ROOT/tmp/C1Docker-R2Complete-20261112-run01, capturaexterna nueva
ROOT/tmp/c1docker-r2-complete-20261112/capture y TEMP C1DockerP1R2-*; sin overwrite/
delete/reparse/UNC. Approval/manifest solo supervisor. Intento durable antes de
procesos y resultado despues, primaria/secundarias/stats/IDs preservados. Original
timeout180/SQLlogin30/query120, capturaBIN deCLI sin timeout exterior corto.
No segunda readiness/proceso o retry para obtenerPASS. Ante fallo/timeout/recibo
incierto conservar estadoUNKNOWN y parar; no cleanup/reconcile/repair/reapply/
rollbackmanual/reseteos hasta otroencargo. No inferir que SQL murio por timeout.

## Cierre

Si faseII falla, outcome failed y fuenteoffline/operacion separados en reporte;
no volver a correr helper. Si PASS, dejar contenedorSQLrunning/volumen/evidencia
paraQAposterior. TEMP/C1DockerP1R2-programmer-report.json con IDs, stage1 y reply/
approvalSHA, fuente/helper/manifest/SQLpins, comandos/recibos/exit/tiempos,
freshreadiness/DB/verify/huellas y conservacion. EN_REVISION, no basevalidada
hasta revision independiente del supervisor. ACKdeliveryId/procesar todos lotes
antes de worker_done, mantener terminal. Sin commit/push/main/despliegue/gastos.
