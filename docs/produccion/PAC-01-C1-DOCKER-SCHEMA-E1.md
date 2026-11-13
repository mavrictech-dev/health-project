# PAC-01.C1.DOCKER.SCHEMA.E1: reconciliar metadata tras instalacion fallida

Contrato supervisor, 2026-11-12. Continuidad Docker local ya autorizada. Leer
AGENTS, docs/agent-workflow.md, TAREAS y D-87.BA CANONICOS en
D:/Mavric/Health Project. Misma pareja, cuentas por proceso/--no-daemon,
terminal/sesion/worktree retenidos, IDs NUEVOS del preambulo. Supervisor unico
escritor documental. No pedir al usuario otro permiso para esta lectura local.

## Estado revisado y objetivo nuevo

R2 task_87e222cb1e24 / ctx_186130c277cf termino FAILED, msg_856a2e47d4b3.
Fuente offline aceptada/integrada; fase II obtuvo readiness/create/configure,
pero apply_v1_v13 orden22 exit16, stdout0, stderr278 SHA
AA1A92E5C466F995A1045341C80DF8EC67763BC253A2E3EA5065DA1E37F75338.
Verify NO intentada. Informe TEMP/C1DockerP1R2-programmer-report.json SHA
B169E444108C764844D40055636A6FB259FF99E53B600A3425A6FD63985777FB.
Supervisor contrasto 10558 artefactos, 717 fuentes, 45 entradas journal,
22 intentos/21 recibos, 4 SQL byteexactas. Estado esquema UNKNOWN; ningun
rollback, commit, instalacion completa o causa nativa acreditados.

Objetivo: UNA consulta NUEVA de metadata en la DB creada para medir su esquema
actual, conservando recursos y fallo anterior. No repetir apply, provisioning,
readiness master que exige DB ausente ni verify que presupone esquema completo.
El recibo R2 anterior esta consumido y NO autoriza mas mutaciones.

## Ownership, pines y fronteras

Solo TEMP NUEVOS C1DockerSchemaE1-* y evidencia NUEVA create-only
ROOT/tmp/C1Docker-SchemaE1-20261112-run01. Ninguna edicion de producto, tests,
configuracion, V1-V14, scripts existentes, manifiestos, docs o evidencia vieja.
Preservar las 717 fuentes y artefactos previos. No repetir suites ya aceptadas.
Driver ROOT C65743A57479BE15BC27D821D682478367C5DF2AE93F550E31CEC84E89A951A6;
test C85FF9D231212B9DDC95C5169C537F1F5B209158ABAD1E10D5F57C2DAD2C0B06.
Canonicas y pines en ROOT/tmp/c1docker-r2-complete-20261112/
reviewed-complete-manifest.json SHA
665C9ED529EF24B1A0737086DD273F32280A237CC7896D284AE0F8DA42DB9E29;
se consulta como referencia de pines, NO se ejecuta su operacion PROVISION.

CID UNICO 4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
nombre/hostname healthproject-c1qa-20261112,
volumen healthproject-c1qa-20261112-data,
labels com.mavric.health.qa=c1-20261112,
com.mavric.health.qa.run=a52e4ded46af4fe29d9f16a28b938719.
Loopback127.0.0.1:14436->1433, bridge, restart=no, privileged=false,
binds=null, unico mount volumen propio rw /var/opt/mssql.
Imagen mcr.microsoft.com/mssql/server@sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f.
CLI SHA6C699720BB9523DEDB9EB5D22A49951EA9210DBDB1314A3554029EEE9BE76896,
inner /opt/mssql-tools18/bin/sqlcmd SHA
447775C5DA41E04AC04CEBDB2EB0DDED06213402342715040BEA49B58AB05ADC.
Context desktop-linux / npipe:////./pipe/dockerDesktopLinuxEngine,
daemon29.8.2 linux/amd64 (info x86_64 equivalente).
No Windows SQL, Somee, AgendlyCitas, FactuEz, otros recursos o pin-container.

## Operacion de solo lectura, autorizada una vez por este contrato

Hasta8 comandos: contexto/daemon/imagen/volumen/CIDrunning/innerpin,
UNA SQL metadata, inspectfinal. Misma validacion fisica completa anterior.
Si falla preflight STOP, sin start/restart/repair. No PROVISION, create/stop/
rm/prune/compose/pull/grants/DDL/DML, nuevas credenciales, envglobal o retry.

SQL en health_project_c1_docker_qa_20261112, con engine_guard(DATABASE) R2 y
configured_guard() EXACTAS de fuente ROOT. Guardan DB/host/major16/Developer/
TCP/SA/count0/state0o1/ownerCONTROL/marker/compat160. No usar empty_guard o
post_guard: precisamente se mide el esquema desconocido. Tras las guardas,
solo SELECT/variables/SET de sesion, sin BEGIN/COMMIT/ROLLBACK ni negocio.
No llamar SP de aplicacion, acceder tablas de usuario ni instalar V14.

Medir en UN frame JSON cerrado con nonce32hex nuevo y kind C1SCHEMA:
compat160 y marcador exacto como booleanos; numero objetos usuario, tablas,
tablas fuera dbo, SP dbo, triggers DML, roles objetivo validos/miembros/ACL,
usuarios adicionales; presencia V13 usp_patient_links_list, V14 edit_get y
columna revision de patient_links, y flyway_schema_history; @@TRANCOUNT y
XACT_STATE. Contadores NO son aserciones de 37/134/31/564: cero o parcial
son observaciones validas. Incluir SHA256 de catalogo metadata ordenado
(sys.objects/sys.sql_modules/sys.columns/sys.indexes/sys.database_permissions/
roles) y lista cerrada de conteos por tipo de objeto si ayuda a clasificar.
No extraer nombres arbitrarios, definiciones, filas, passwords ni otros DB.
No usar baseline_parts que presupone tablas presentes. Si algun campo no
puede observarse, NULL explicito/tipo documentado, no cero fabricado.
Guardar SQL completa, schema esperado y hash/nonce ANTES de ejecutar.

ARGV/transporte iguales al SQL de R2, salvo DB fija anterior y payload nuevo:
docker exec --interactive CID /bin/sh -c SQL_SHELL c1sql -S tcp:127.0.0.1,1433
-U sa -d DB -C -b -V 11 -r 1 -f 65001 -y 0 -w 65535 -x -X1 -l 30 -t 120.
NO -h/-W/-P. Secreto solo export dentro del contenedor, no Config.Env,
archivo/envhost o passwordargv. Native shell=False, captura binaria; timeout
180 SQL/30 inspect. No timeout exterior corto ni kill/reintento automatico.

Conservar stdout/stderr BIN de ESTA consulta metadata en evidencia local
exclusiva (max64KiB por canal) antes de parsear, incluso en exit no0. Este
permiso acotado evita perder nuevamente el motivo nativo; no cambia la
politica de otros verificadores ni autoriza logs/secretos/datos de negocio.
No imprimir buffers arbitrarios en terminal/reportes al usuario. Resumen:
longitud/SHA/codigo y headers numericos con Server/Procedure opcionales;
clasificar frases controladas conocidas. Mensaje inesperado se conserva
local, se reporta failed y STOP sin segunda consulta. Si supera limite, hash/
longitud, fallo y STOP, nunca volcar. Parser estricto: JSON sin header o header
exacto del alias documentado; rechazar duplicados/ruido/colas/stderr/exit/nonce/
tipos o claves inesperadas. No convertir diagnostico valido en base lista.

## Analisis offline del error original y cierre

Tambien revisar SOLO OFFLINE el payload original
ROOT/tmp/C1Docker-R2Complete-20261112-run01/0022.sql SHA
9DC06862CD9CFC359F369B981A72D4DC2F803224D9A1508D70B4DFF6BF08BD54.
Contiene BOM UTF8 interior al comienzo de V13 (offset1416638); es observacion,
NO causa probada. V2 no termina GO pero V3 comienza SET/GO: no asumir defecto
por esto. Puede parsear bytes reales con ScriptDom160 instalado, excluyendo
solo directiva SQLcmd :On Error exit, sin normalizar BOM interior; inspeccionar
limites de batches y reconstruir candidatos de error para comparar exactamente
278bytes/SHA original. No repetir parseos/suites ajenos. Diferenciar sintaxis
local, posibles causas y match exacto nativo. NUNCA ejecutar payload original
para diagnosticar ni corregirlo en este encargo. Si necesita ampliar, ask/STOP.

Journal durable antes/despues de cada comando, primaria/secundarias preservadas.
Solo inspectfinal autorizado tras SQL intentada; nada mas de Docker/SQL tras
fallo. Reporte TEMP/C1DockerSchemaE1-programmer-report.json con IDs/SQL/schema/
pines/commandplan/8recibos/frames/conservacion y analisis offline delimitado.
Succeeded si lectura metadata completa valida y guardas fisicas intactas,
aunque esquema sea vacio/parcial. Error/timeout/frame incompleto: failed/
UNKNOWN sinretry. Estado EN_REVISION; ninguna recuperacion/migracion autorizada.
ACK deliveryId y procesar todos lotes antes de worker_done. Mantener terminal.
Sin commit/push/main/despliegue/gastos/datos reales.
