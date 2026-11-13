# PAC-01.C1.DOCKER.APPLY.DIAG.E1: diagnostico con rollback, gate supervisor

Contrato supervisor 2026-11-12. Leer AGENTS, docs/agent-workflow.md, TAREAS,
D-87.BB y los contratos Docker R2/SCHEMA-E1 CANONICOS ROOT
D:/Mavric/Health Project. Misma pareja, cuentas por proceso/--no-daemon,
terminal/sesion/worktree retenidos, IDs NUEVOS del preambulo. Supervisor unico
escritor docs/tablero. Dos fases: preparar OFFLINE; ejecutar SOLO tras ask,
revision y recibo NUEVO del supervisor. No pedir al usuario otra confirmacion.

## Objetivo y hechos revisados

R2 FAILED (task_87e222cb1e24/ctx_186130c277cf): create/configure confirmados,
apply exit16/stderr278SHA AA1A92E5C466F995A1045341C80DF8EC67763BC253A2E3EA5065DA1E37F75338,
sin verify. Error nativo original descartado por tooling: causa no acreditada.
SCHEMA-E1 FAILED (task_a76b261e1fd5/ctx_aab016ee1ba4), done msg_0c1aef444885:
metadata SQL exit0/stderr0, stdout699SHA
FC71A27B543A19F38CE27F7309D1B8571664134CD59542C7C57E3956D941AA0C.
Parser previo rechazo cuatro hashes NULL. No se cambia su outcome o contrato.
Supervisor revisa79artefactos/717fuentes/17journal/8calls, tipos/nonce/SQL y
Dockerfinal conforme. Observacion independiente: userObjects/tables/SP/triggers/
roles/ACL/usuarios adicionales=0, V13/V14/Flyway ausentes, marker/compat validos,
count0/state0. Esquema vacio al leer, NO instalacion lista ni mecanismo de
rollback anterior probado. No repetir SCHEMA solo para corregir su parser.

Nuevo objetivo: diagnosticar el fallo de carga en la DB sintetica propia con
una prueba acotada SIN COMMIT, conservando por primera vez el error nativo de
esta operacion y reconciliando despues. No cambiar migraciones ni arreglar
posibles causas hasta tener el diagnostico. BOM interior de V13 observado,
ScriptDom160 original227batches0errores; ninguna causalidad inferida de ello.

## Ownership y frontera

Solo TEMP NUEVOS C1DockerApplyDiagE1-* y evidencia NUEVA create-only
ROOT/tmp/C1Docker-ApplyDiagE1-20261112-run01. Sin ediciones producto/tests/docs/
config/V1-V14/tooling existente ni artefactos/manifiestos/approval anteriores.
Preservar717fuentes y evidencia/pines anteriores. Baselinefresh, no reset/sync.
Pines ROOT driver C65743A57479BE15BC27D821D682478367C5DF2AE93F550E31CEC84E89A951A6,
test C85FF9D231212B9DDC95C5169C537F1F5B209158ABAD1E10D5F57C2DAD2C0B06,
resto canonicas/CLI/imagen/inner exactos en
ROOT/tmp/c1docker-r2-complete-20261112/reviewed-complete-manifest.json
SHA665C9ED529EF24B1A0737086DD273F32280A237CC7896D284AE0F8DA42DB9E29.
Este manifest es referencia de pines, su PROVISION NO se ejecuta.

CID UNICO4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
nombre/hostname healthproject-c1qa-20261112, volumen healthproject-c1qa-20261112-data,
runlabel a52e4ded46af4fe29d9f16a28b938719, DBhealth_project_c1_docker_qa_20261112,
marker original, loopback127.0.0.1:14436->1433, bridge/restart=no/privilegedfalse/
bindsnull/unico mount rw /var/opt/mssql. Validacion completa fisica, imagen,
labels y pines como SCHEMA-E1. No Somee/AgendlyCitas/Windows/FactuEz/otrosrecursos.
No create/start/stop/restart/rm/prune/pull/compose o nuevascredenciales.

## Fase I OFFLINE y gate

Preparar helper/SQL/schema/commandplan y capture externo que no actuan al
importar/generar. Puede reutilizar funciones ROOT verificadas sin modificar ni
monkeypatch del motor o comandos en vuelo. Native shell=False, argv arrays,
Dockercontextdesktop-linux/endpoint/daemon29.8.2 exactos, entorno filtrado.
SA propio SOLO setup/diagnostico, export SQLCMDPASSWORD dentro contenedor;
nunca leer Config.Env, passwordargv/-P/archivo/envhost/envglobal o logs libres.

Payload probe deriva del ORIGINAL EXACTO
ROOT/tmp/C1Docker-R2Complete-20261112-run01/0022.sql
SHA9DC06862CD9CFC359F369B981A72D4DC2F803224D9A1508D70B4DFF6BF08BD54:
SOLO sustituir nonce428d04213e64408596242f578b107ab9 por NUEVO32hex y la UNICA
sentencia top-level `COMMIT TRANSACTION;` final por `ROLLBACK TRANSACTION;`.
Ni normalizar BOM interior/encoding/GO ni modificar V1-V13/options/guardas/
BEGIN/SQL/probe/ACL/post_guard. Antes de procesos acreditar diferencia unica,
AST o scanner top-level sin COMMIT ejecutable, 1BEGIN/1ROLLBACK y exactitud de
canonicas embebidas. No convertir texto dentro de cuerposSP en sentencia
ejecutada, no quitar comprobacion pre-final count1/state1. Primeras guardas
engine/configured/EMPTY originales requieren DB propia fresca vacia antesBEGIN.
No introducir transaccion persistente ni dar COMMIT a ninguna fase del probe.

Guardar stdout/stderr BIN de ESTE probe antes de validacion, max64KiB/canal,
solo evidencia local de la DB sintetica/canonicas, no imprimir buffers en
terminal/reportes al usuario. Hash/longitud/exit/headers numericos/frase
controlada en informe; error inesperado retenido local para review. Overflow:
hash/longitud/fallo sin volcar ni segunda ejecucion. Conservar primaria y
secundarias de storage. Captura CLI padre sin timeout exterior corto. Timeout
SQL180/login30/query120, no cambios flags -C -b -V11 -r1 -f65001 -y0 -w65535
-x -X1 -l30 -t120; SIN-h/-W/-P. Original :On Error exit permanece.

Preparar UNA metadataPOST readonly usando SQL de SCHEMA-E1 SHAEDFF6297...0E64
EXACTA salvo nonce nuevo distinto. Mismas guardas engine/configured, sin empty/
post_guard ni tablas negocio. Parser NUEVO documentado para este contrato:
tipos/claves/nonce estrictos; objects/modules/columns/indexes pueden serNULL
SOLO con userObjects=tables=SP=triggers=0 y ausenciaV13/V14/Flyway. Son valores
observados, no hashes validos: catalogFingerprintComplete=false. Permissions/
roles obligatorios HEX64. Cualquier otra combinacion NULL se rechaza sin
default fabricado. Conteos0 no significan DBlista, son postcondicion esperada
de prueba conROLLBACK. No cambiar parser/evidencia SCHEMA-E1 existente.

Modelos offline necesarios: rechazo antes de gate, plan con 1probe/1post y
sin mutaciones fueraTX/COMMIT; diagnostico nativo no0 preservado y post unico;
timeout/transporte incierto no genera otroSQL; primaria+storagesecundaria;
parsernullable solo caso vacio, rechaza ruido/duplicados/tipos/nonce/null
incorrectos. run/Popen/socket doblados. No repetir37tests/Maven/frontend.

Preguntar por Orca con TEMP/C1DockerApplyDiagE1-stage1-report.json: pines/helper/
capture/SQL/SHA/diff/AST/comandos/modelos y recibo candidato reviewedfalse.
STOP, terminar turno esperando supervisor. CLI --execute exige recibo NUEVO
ROOT/tmp/c1docker-apply-diag-e1-20261112/approval.json pinneado por SHA comunicado
en reply; bound Task/Dispatch/helper/capture/SQL/plan/target/scope. Trabajador
no crea approval. No usar recibos R2 consumidos. Fuente/helper congelados al ask.

## Fase II solo tras gate supervisor

Hasta10 comandos y DOS SQL maximo: contexto/daemon/imagen/volumen/CIDrunning/
innerpin -> UN probe ROLLBACK -> CIDrunning -> UNA metadataPOST -> inspectfinal.
Guarda antesBEGIN exige emptyfresh; si falla, no reparar/retry. Si preflight
falla, noSQL. Timeout/CLIerror de transporte incierto/storage imposible de
asegurar antes de fase siguiente: STOP UNKNOWN sin segundoSQL/cleanup.

Si probe termina normalmente (incluye error SQL con header reconocido y
salida preservada), se permite la metadataPOST preplaneada aun con exit no0:
es reconciliacion readonly, no reparacion/reintento. No deducir rollback desde
exit ni fabricar metadata. Si hay dudas sobre finalizacion de SQLcmd o proceso
vivo, STOP antesPOST y consultar, no usar nueva conexion como prueba de muerte.
Si probe llega aROLLBACK, validar frame existente solo como recibo de prueba;
NO presentarlo como instalacionapplyPASS aunque contenga stageapply/oktrue.

Diagnostico satisfactorio: error nativo capturado/identificado y postestado
medido vacio, guardasfisicas conformes; un exitSQLno0 esperado NO hacefallar
por si solo esta Taskdiagnostica. Informe distingue probeFailed/deploymentReadyfalse.
Si no reproduce error peroROLLBACK/postvacio acreditados, informar diagnostico
sin causa reproducida, sin declarar arreglado y sin un segundo intento.
Si post no es vacio, STOP failed/UNKNOWN, no cleanup/rollbackmanual/recovery.
No aplicar V14 ni crear usuariosruntime/fixtures/backend/HTTP/frontend.

Journal intento durable antes de cada proceso, resultado y buffers antes
de parser, conservar secundaria/IDs/tiempos. Informe final
TEMP/C1DockerApplyDiagE1-programmer-report.json: IDs/reply/approval/sourcepins/
payloads/modelos/intentos/recibos/errores/reconciliacion/conservacion/limites.
EN_REVISION, sin instalacion lista. ACK deliveryId, procesar todos lotes antes
de worker_done, mantener terminal. Sin commit/push/main/despliegue/gastos/datosreales.
