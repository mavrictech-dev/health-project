# PAC-01.C1.DOCKER.V13.INSTALL.E1: preparar QA rollback y carga condicionada

Supervisor 2026-11-13. Leer AGENTS/flujo/TAREAS y D-87.BH CANONICOS ROOT
D:/Mavric/Health Project. Misma pareja/cuentas por proceso/--no-daemon/
terminal/sesion/worktree retenidos; IDs NUEVOS del preambulo. Supervisor unico
escritor docs. FASE I solo preparacion OFFLINE; FASE II solo tras ask/review/
recibo NUEVO supervisor. No pedir permiso adicional al usuario para este entorno
sintetico Docker autorizado. Esta Task no activa backend ni produccion.

## Estado revisado

P1.R3 task_bd0cc2f207fe/ctx_a2430264ab85 succeeded, done msg_a3b12b4bbec4.
Supervisor60artefactos/717fuentes/28referencias freshhash,43tests propiosPASS,
37metodos previos conservados salvo representacionRAW, definicionesproducto
previas ASTiguales excepto rename sql_raw;5RAWexactos/5render reconstruccion/
lineas<=4094, apply227batches AST/tokensiguales. UNAqueryreadonly real prueba
241longitudes+hashesfuente y3ISJSONvalidos/2controlesvalidos,8callsconformes.
2fuentes ROOT integradas SHA14CCA63F...6E8A4 y4965F837...163FE con backups.
V1-V14/canonicas/checks intactos, esquema Docker aun vacio, V14 no aplicada.

Nuevo manifest SOLO FUENTES revisadas, NO permiso operativo por si mismo:
ROOT/tmp/c1docker-v13-install-20261113/reviewed-sources-manifest.json
SHA935E2FFB7E11A33666E5C902F771C7BDF781334F233238A5A74B1C33DCA1BCB8.
Driver14CCA63FABAC04254FD7A192CC398A9DAE8C24CF36FF47BAADC96A13B7B6E8A4,
tests4965F837771915AC4798218A0B49FE9039F8DE489BF8B85A30ED62F2D06163FE.
Import/validate_manifest sin procesos PASS. No usar manifests/approval viejos.

## Ownership y frontera

Solo TEMP NUEVOS C1DockerV13InstallE1-* y evidencia NUEVA create-only
ROOT/tmp/C1Docker-V13InstallE1-20261113-run01. Ninguna edicion producto/tests/
config/deps/docs/V1-V14/renderer/verificador o artefactos previos.717fuentes
intactas entrecheckouts; guardar freshhash antes/despues y referencias concretas
relevantes, sin rehash general56k o suitesMaven/frontend/43tests ya aceptados.
Helper puede importar funciones ROOT pinneadas, no monkeypatch en vuelo.

CID UNICO4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
hostname/nombrehealthproject-c1qa-20261112, volumenhealthproject-c1qa-20261112-data,
runlabela52e4ded46af4fe29d9f16a28b938719, DBhealth_project_c1_docker_qa_20261112,
markeroriginal, loopback127.0.0.1:14436->1433, bridge/restart=no/privilegedfalse/
bindsnull/unicomountrw /var/opt/mssql. Imagen/CLI/inner/context/endpoint/daemon/
labels exactos del manifest validado. CuentaSQLSA propia SOLO migracion/QA;
ninguna cuentaruntime real/CONTROLruntime o nuevos secretos/usuarios.
NO CLI PROVISION ni Provisioner.execute: recursos y DB ya existen. Sin
create/start/stop/restart/rm/prune/pull/compose/repair/adopt. Si no running o
guards cambian STOP. No Windows SQL/Somee/AgendlyCitas/FactuEz/otros recursos.

## FASE I: preparar paquete completo sin procesos Docker/SQL

Helper/capture/SQL/schema/plan puros al importar/generar. Fuente revisada ROOT
como unica generadora. Cinco payloads/etapas previstos, nonces distintos:
1 pre_schema metadata actual y requisito EMPTY antes del primer BEGIN.
2 qa_rollback: sql_raw apply V1-V13, sustituir UNICO COMMITfinal porROLLBACK,
  luego render_sql. Canonicas/GO/BOM/guardas/pre-finalcount1state1 intactas.
3 post_qa_schema: metadata readonly fresca, sin presuponer vacio antes de medir.
4 install_commit: sql(data,apply_v1_v13,nonce), UNA TX y COMMITfinal originales.
5 verify_database: sql(data,verify_database,nonce), conexion NUEVA y baseline37.

Metadata pre/post y reconciliacion de fallo reutiliza contenido de SCHEMA-E1
TEMP/C1DockerSchemaE1-metadata-ready.sql SHA
EDFF62976CEBD67F54DB07F1FC6FA4C13B8989FC5DB0DDA603BC54B6A2F90E64,
solo nonce nuevo y render_sql; en PRE se agrega empty_guard() antes del frame.
Engine/configured guard exactas. Parser cerrado de metadata como APPLY.DIAG.E1:
4hashesNULL solo con corevacio/V13V14Flywayausentes, permissions/roles HEX64,
catalogFingerprintCompletefalse separado, sin fabricar hashes. En PRE exigir
todos conteosusuario/roles/ACL0; count0/state0o1, compat160/markerexacto.
POSTQA requiere mismo esquema vacio y hashes/metadata estructural iguales aPRE;
estadoXACT0o1 es observacion de sesion separada, no hash de datos a normalizar.

Guardar 5SQL completas, payloadRAW/renderSHA/offsets/reconstruccion, nonces y
plancondicional. Prever metadatareconcile con nonce propio como rama alternativa
a verify si install_commit retorna normalmente con error/recibo incompleto.
No sourceSQLlibre anadida al apply, cambiosBOM/normalizaciones o bypass del
renderer. Whitelist de sentencias transaccionales: QA1BEGIN/0COMMIT/1ROLLBACK;
INSTALL1BEGIN/1COMMIT/0ROLLBACK. Hasta que QA completa y POSTvacio se acrediten,
NO enviar INSTALL. Frameapply del QA es solo reciboROLLBACK, nunca instalacion.

Modelo max16comandos/5SQL: contexto/daemon/imagen/volumen/CIDrunning/innerpin,
PREsql7 -> CID8 -> QA9 -> CID10 -> POSTQA11 -> CID12 -> INSTALL13 -> CID14 ->
VERIFY15 -> finalCID16. Tras errorQAcompletado solo CID10/POSTQA11/finalCID12
para medir conservacion, luego STOP failed sin INSTALL. Tras errorINSTALL
completado, VERIFY15 se SUSTITUYE por UNAmetadatareconcile15, finalCID16 y STOP
failed/UNKNOWN, sin reapply. Nunca ejecutar ambas ramas VERIFY/reconcile.
Timeout/proceso vivo/transporte incierto/limitebuffers/storagefallido: STOP
sin otraSQL o reparacion; no deducir muerte o rollback desde timeout/silencio.

Modelos offline con run/Popen/socket doblados: gateausente/reviewedfalse/pincambio
bloquea antesprocesos; success16/5; QAerrorPOSTvacio sinINSTALL; POSTnoempty
bloqueaINSTALL; timeout sinSQLposterior; INSTALLerror solo1reconcile sinretry;
storage guarda causa primaria/secundaria; parsermetadata/frames/nonce/colas.
Solo parserlocal de SQLnuevo necesario; no repetir corpus canonicoprevio ya
igual salvo COMMITaROLLBACK/nonce/render. Modelos no son prueba de motor.

Ask supervisor con TEMP/C1DockerV13InstallE1-stage1-report.json y SHA de
helper/capture/plan/payloads/schema/manifest/target/candidato reviewedfalse,
source conservation y modelos. STOP y terminar turno, sin worker_done aun.
CLI --execute debe exigir ANTES de procesos recibo NUEVO
ROOT/tmp/c1docker-v13-install-20261113/approval.json y SHA comunicado porOrca,
bound Task/Dispatch/scope QA_ROLLBACK_THEN_INSTALL_EXISTING_V1_V13_ONCE y TODOS
los pines del paquete. El trabajador NO crea approval. No reutilizar R2/DIAG.

## FASE II condicionada tras review/recibo/reply

UNA invocacion capture/helper. Revalidar717fuentes/manifest/pines y outputs
ausentes; nueva baselinefresh de referencias, separar deltasdocumentales del
supervisor. Native shell=False/argvarrays, entorno filtrado, inputSQLbytes
renderizados y evidenciados EXACTOS; SQL_SHELL exporta SQLCMDPASSWORD dentro
contenedor, nunca Config.Env/-P/passwordargv/archivo/envhost/global. Mismosflags
-C -b -V11 -r1 -f65001 -y0 -w65535 -x -X1 -l30 -t120, NO-h/-W. TimeoutSQL180/
inspect30, capturaexterna espera mismochild sin timeoutcorto/kill/retry.

Journalintento durable antes de cada proceso; resultados/rawSQL y BINstdout/
stderr SOLO locales <=64KiB/canal antes de parser. Este scope permite buffers
del propio catalogo sintetico/canonicas, NO logs/secretos/datos de negocio.
No imprimir buffers o cuerposJSON en terminal/reportes al usuario; resumen
exit/hash/longitud/headersnumericos/frasescontroladas. Overflow conserva solo
hash/longitud y falla, no volcar. Primaria no reemplazada por storagesecundaria.

PRE debe acreditar identidad/ownerCONTROL/marker/compat yEMPTYfresh. QA debe
completar TODOS los batches/post_guard37tablas/134SP/31triggers/564ACL/V13si/
V14no/OPEN antesROLLBACK y framevalido. POSTQA conexionfresca debe medirEMPTY
conservado. SOLO entonces enviar INSTALLoriginalrender UNAvez, mismaDB con
empty_guard de nuevo antesBEGIN. Si cualquier diferencia/error STOP y nunca
fabricar continuidad. Retener erroresnativos, no arreglarlos en esta Task.

Tras INSTALLframevalido y COMMITrecibo, VERIFYfresh confirma37tablas/134SP/
31triggers/564ACL/V13/OPEN/owner/runtime-denies y hashes37tablas+catalogo
segun funcion ROOT baseline_parts/post_guard originales. No insertar fixtures
ni aplicarV14 ni activar backend/frontend/Flyway/jobs. Dejar recursos running.
Ante fallo/reciboperdido no prometer rollback o commit; rama readonly descrita,
recursos/evidencias conservados, sin cleanup/reapply ni nuevos procesos.

## Cierre

Succeeded solo si QArollback completa, POSTQAempty, INSTALLconfirmada y VERIFY
fresh completa con Dockerfinalconforme y conservacionfuentes/artefactos. Aun
EN_REVISION: supervisor verifica independientemente antes de DBvalidada.
Resultado V1-V13 local NO equivale a V14/PRE111/JDBC/HTTP/UI/productivo/Somee.
Si falla cualquier gate, outcome failed/UNKNOWN con etapa exacta; no marcar
completa por guardar un error. Informe TEMP/C1DockerV13InstallE1-programmer-report.json
con IDs/reply/approval/pines/payloads/modelos/orden/recibos/rawmetadata/error/
prepost/baselinefinal/conservacion/limites. ACKdeliveryId y todos lotes antes
de worker_done; mantener terminal/sesion. Sin commit/push/main/despliegue/gastos.
