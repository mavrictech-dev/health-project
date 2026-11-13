# PAC-01.C1.DOCKER.DIAG.E1: descomponer guardas mediante metadata readonly

Estado posterior 2026-11-12: ejecuciondetenida por incompatibilidad de flags
de formato introducida en ESTE contrato supervisor (-h-1 con -y0). Matchexacto
60bytes/SHA D5C9A771...4C3F4 identifica mensajeCLI de opciones mutuamente
excluyentes. Consulta no ejecutada, predicados no observados. Conservar corrida
failed/UNKNOWN; NO volver a ejecutar este contrato ni quitar flags en esta Task.
Supervisor comunicomsg_6455f823c475 y preparara encargo posterior sin -h.

Supervisor, 2026-11-12. Dos tareas previas permanecenfailed: PROVISION-E1 y
RECONCILE-E1. Este objetivo NUEVO no repite readiness: mide por separado los
predicados que el primer IF agrupa, sin operaciones mutantes o datos de negocio.
Leer AGENTS/flujo/TAREAS, P1/Q1/R1/PIN/PROVISION/RECONCILE y D-87.AW CANONICOS
en D:/Mavric/Health Project. Misma pareja/cuentasporproceso/--no-daemon/terminal/
sesion/worktree; IDs NUEVOS del preambulo. Supervisor unico escritor documental.

## Hallazgo exacto, no conjetura de autenticacion

Informe RECONCILE SHA D3473E25D666EA24BA1D0114A226F85054EB845CB49E1B8257CD3EB582CA742D.
Supervisor reconstruyo SOLO errorescontrolados del SQL. Un candidato coincide
EXACTAMENTE en118bytes y SHA D9B43E05BED8ABBACDC477B7682D3E26DE9BAC04D149E4FF5CC396C45C07CF86:

```text
Msg 59999, Level 16, State 1, Server healthproject-c1qa-20261112, Line 9
C1Docker isolated engine/sa/TCP prerequisite
```

LF entre lineas y LFfinal. El mensaje procede del IF inicial de engine_guard,
antes de DBcollision/frame. La SQL fue recibida/ejecutada hasta esa guarda; no
atribuir fallo a password/flags ni afirmar cual OR falla sin medirlo. Regex del
helper anterior omitio segmento Server, por eso numericHeaders estaba vacio;
no significa que el motor no emitiera cabecera. No editar evidencia anterior.

## Ownership y frontera fisica

Solo TEMP NUEVOS C1DockerDiagE1-* para helper/SQL/plan/receipts/reporte y
ROOT/tmp/C1Docker-DiagE1-20261112-run01 evidencia NUEVAcreateonly. Ninguna edicion
de producto/tests/config/deps/manifiestos/docs o evidencia vieja. Preservar717
fuentes y todos los artefactos/pines/historia incluyendo ambas corridasfallidas.
Sin repetir suites/parser/Maven/frontend que no cambiaron. Si prepara SQL nuevo,
puede validar sintaxis local sin conexion, no confundirla con motor.

CID UNICO existente4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
volumenhealthproject-c1qa-20261112-data/runlabela52e4ded46af4fe29d9f16a28b938719,
hostnamehealthproject-c1qa-20261112, labels/loopback/bridge/restart/ACLfisicas
exactos de RECONCILE. Imagen4525e3ef...13b7f/CLI6C699720...6896/inner447775C5...05ADC
completos en manifest073BBFE5...0958E y contratosanteriores. Verificar hashes
completos, fuentesROOTdriver6F5FE612...32CA2A/testD05D8A5D...22E73A/canonicas intactas.
Dockerexec directo porCID y TCP127.0.0.1,1433 DENTRO del mismo contenedor. No
hostSQLWindows, Somee/AgendlyCitas/otrosrecursos/FactuEz o pincontainerparado.

Hasta8comandos readonly como RECONCILE: contexto/daemon/imagen/volumen/CID/
innerpin/UNAsqlmetadata/inspectfinal. AntesSQL exigir Dockerpropiedad/imagen/
hostname/mount/loopback/Runningtrue aprobados. Si falla o parado, STOP sin start.
Sin create/start/stop/restart/compose/pull/rm/prune/provision/grants/DDL/DML/
credencialesnuevas/envglobal o consultas de negocio. Inspectsolo camposselectivos,
nunca Config.Env/logslibres. Una conexionSQL, no retry/polling/segunda conexion.

## Query NUEVA, solo metadata de los predicados

Entrada DBmaster, mismos shellSQLSA propio, CLI/environment y flagssecurity/
timeouts de RECONCILE. Se permite SOLO agregar -h -1 para eliminar headers del
resultset de diagnostico, no cambiar -C/-b/-V11/-r1/-f65001/-y0/-w65535/-x/-X1/
-l30/-t120. Nunca -P/passwordargv, no leer secreto en host: shelloriginal exporta
SQLCMDPASSWORD de MSSQL_SA_PASSWORD sin echo. Timeout180SQL/30inspeccion.

SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF; capturar
@@TRANCOUNT/XACT_STATE antes de lecturas y los valores builtin usados por
engine_guard. NO anteponer el IF que precisamente impide medir. La frontera de
esta lectura diagnostica es el CIDfisico comprobado y master seleccionado;
no se autoriza omitir guardas en migraciones/negocio o aceptar target alternativo.

Emitir UNframeJSON propio C1DIAG/nonceNUEVO y conjunto cerrado de claves. Observar
TODOS los predicados por separado con mismas conversiones/collations/longitudes:
DB_NAME master/DATALENGTH12; MachineName exactaBIN2 y DATALENGTHconvertNVARCHAR54;
major16; Edition LIKE N'Developer Edition%'; net_transportTCP; SUSER_SNAMEsaBIN2 y
DATALENGTH4; sysadmin1; @@TRANCOUNT0; XACT_STATE0. ValorNULL debe quedar explicito
o fallo, no true por coercion. Comparar codigo con IF original y adjuntar SQL
COMPLETO/hash antes de unica ejecucion; no medir solo el predicado sospechado.

Hechos auxiliares seguros: longitudesint, majorint/EngineEditionint, contadores/
@@OPTIONSbit2, DB_IDtargetausenteBIT y numeroDBuser(metadata) sin nombres/filas.
Para nombres/motor NOexportar textoarbitrario: enums cerrados de MachineName
EXACT/UPPERCASE_EXPECTED/PREFIX15/PREFIX15_UPPER/OTHER/NULL, loginEXPECTED_SA/
OTHER/NULL, transporteTCP/SHARED_MEMORY/NAMED_PIPE/OTHER/NULL, Edition
DEVELOPER64/DEVELOPER_OTHER/OTHER/NULL; SHA opcional del valorUnicode, nunca
password/cookies/buffers ni rawfilas. Ningun sys.databases SELECT* o nombre de
otraDB. Estado de targetausente es OBSERVACION de metadata, no permiso para crear.

Parser cierra tipos/claves/correlacion/enum e identidad de diagnostico, rechaza
duplicados/colas/stderr/exitinesperado. Valoresfalse son un diagnostico valido,
no readinessPASS: mantener campo separado readinessAuthorized=false. No fabricar
datos o relajar reglas para aceptar valores. stdoutJSON solo camposaprobados.
Si SQL falla, headers numericos con ServerOPCIONAL, hashes/longitudes y frases
cerradas; ningun mensajenativo arbitrario. Tras SQLintentada solo inspectfinal,
sin correccion de fuente/host/roles o segundoSQL aunque se identifique la causa.

## Entrega

TEMP/C1DockerDiagE1-programmer-report.json: nuevosIDs/pines/SQLexacto/nonce,
commands/recibos/journalsummary y predicadosfallidos observados con evidencia,
estadoDockerfinal/conservacion. Succeeded solo si se obtuvo frameDIAGvalido con
TODOS los predicados y guardasfisicas intactas; puede contenerfalse y sigue
EN_REVISION, jamas provisioning/basevalidada. Frameausente/timeout/error nativo
se reporta failed/UNKNOWN, recursos conservados y sin retry/cleanup. Supervisor
revisara el predicado antes de encargar cambio de tooling y otra instalacion.
ACKdeliveryId si aparece y procesar todos los lotes antes de worker_done;
mantener terminal/sesion. Sin commit/push/main/despliegue/gastos/datosreales.
