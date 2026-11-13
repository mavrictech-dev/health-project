# PAC-01.C1.DOCKER.P1: provisioning aislado SQL2022, tooling offline

Contrato supervisor, 2026-11-12. Usuario habilito Docker y autoriza continuar.
Daemon desktop-linux29.8.2/Linuxamd64 responde; WindowsHEALTHPROJECTQA sigueStopped.
Imagen oficial descargada por supervisor, sin contenedor/volumen/DB creados.
P1 SOLO prepara herramientas con procesos doblados. Provisioning REAL requiere
revision y encargo posterior; no Docker/SQL/HTTP real desde este Dispatch.

Leer AGENTS.md, docs/agent-workflow.md, TAREAS.md, MIGRACION_SQLSERVER.md y
PAC-01-C1-QA-SECUENCIA.md CANONICOS en D:/Mavric/Health Project. Pareja vigente,
cuentas por proceso/--no-daemon, worktree/terminal/sesion retenidos e IDs NUEVOS
del preambulo. Supervisor unico escritor documental. Consultar Orca para ampliar.

## Ownership exclusivo y referencias

SOLO dos archivos NUEVOS en worktree programador:

- scripts/health-sqlserver-docker-qa.py
- scripts/tests/test_health_sqlserver_docker_qa.py

Mas TEMP NUEVOS C1DockerP1-* para snapshot/comandos/tests/diff/reporte. No editar
fuentes previas, compose, V1-V14, Java/frontend/deps/config/DPAPI/TLS/docs/AGENTS,
verificadorLPC/tests anteriores o evidencia previa. No sync/reset ni copiar
migraciones al worker. Tooling futuro lee ROOT canonico explicito, verifica pines
V1-V14 de moduloC1P2R1 sin modificarlo ni activar main. Preservar ambosworktrees,
726pines/301historicos/21snapshots y entregas previas; recalcular inventarioactual.

Imagen fijada por digest descargado, no tagmutable ni pullautomatico:
mcr.microsoft.com/mssql/server@sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f
ImageID observado igual sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f.
DockerCLI C:/Program Files/Docker/Docker/resources/bin/docker.exe SHA256
6C699720BB9523DEDB9EB5D22A49951EA9210DBDB1314A3554029EEE9BE76896.
Contexto explicito desktop-linux, endpoint npipe:////./pipe/dockerDesktopLinuxEngine.
Sin variablesDOCKER_* actuales. No seleccionglobal/remoto/envhostil u otrodaemon.

## Plan y modo operativo futuro protegido

Precision P1-Q1, respuesta supervisor a msg_5a0e405370c6, 2026-11-12:
no hay SHA medido del /opt/mssql-tools18/bin/sqlcmd interno. Manifest candidato
puede registrarlo pendiente/null SOLO como preparacion offline; provision debe
rechazarlo ANTES de cualquier mutacion/proceso operativo. No inventar pin o
medirlo desde este Dispatch. Otro gate readonly acotado/revisado determinara
el hash de ese archivo en la imagen exacta antes de aprobar manifest operativo.
Plan y pruebas dobladas pueden continuar; validar negativo de pinpendiente.

Se aprueba sa NUEVO exclusivo del contenedor como principal de provisioning/
migracion, separado de los roles runtime/bootstrap, y ownerSQLsa de la DB nueva.
No requiere otro WITHOUTLOGIN administrativo. Su privilegio no se entrega a
backend/runtime/bootstrap ni se reutiliza fuera de este contenedor. Comprobar
owner/dbo y que la conexion migradora no pertenece a roles de ejecucion; runtime
posterior seguira EXECUTEsolo con principal distinto, nunca sa. Estos criterios
no autorizan operaciones reales en P1 ni cambian ownership de dosfuentes.

Pythonstdlib sin deps. Plan offline y provision one-shot bajo manifest revisado;
importar/plan/generar nunca ejecuta procesos. No opcion de target/scriptlibre,
repair/reapply/drop/reset/reseed/adopt/reutilizar/reemplazar o limpiar recursos.
Manifest futuro fija hashes dosfuentes nuevas, canonicasV1-V14/modulo/template
C1P2R1, DockerCLI/digest/ID exactos. P1 entrega candidato NO aprobado. Failclosed
si falta/cambia fuente/pin/target/daemon/arquitectura. No mainreal en este paquete.

Target NUEVO fijo: contenedor y hostname healthproject-c1qa-20261112,
label com.mavric.health.qa=c1-20261112, volumen healthproject-c1qa-20261112-data
con mismo label, DB health_project_c1_docker_qa_20261112. Marker exacto:
Health Project isolated Docker C1 QA; provisioned 2026-11-12; no real data.
Linuxamd64 SQL2022Developer, MSSQL_PID=Developer/ACCEPT_EULA=Y, bind SOLO
127.0.0.1:14436->1433, volumen nuevo dedicado /var/opt/mssql. Sinprivileged/
hostnetwork/socketmount/binddatosprevios/restartautomatico. Verificar ausencia
de nombres/puerto antes de crear: colisionSTOP, sin adoptar ni cambiar nombre.
No compose.yaml/compose.qa.yaml, sonMySQLheredado. No tocar serviciosWindows,
recursosajenos/FactuEz, contexto/daemon, authentication/TLS/globalconfig.

Credencial NUEVA aleatoria solo memoria y entorno PROCESO HIJO del DockerCLI;
argv --env MSSQL_SA_PASSWORD SIN valor toma el secreto del entornohijo. No
envarchivo/envglobal/secretosargv/log/inspeccion/excepciones. Configuracion del
contenedor contiene su secreto, no imprimirla. Dockerinspect SOLO campos
selectivos requeridos por ID; no Config.Env, inspect/logs libres o datosajenos.
SQLcmd dentro usa shellfijo que exporta SQLCMDPASSWORD de MSSQL_SA_PASSWORD y
exec /opt/mssql-tools18/bin/sqlcmd; sin interpolar secreto en shell o usar -P.
SQL por stdin binarioUTF8. Confirmar/pin inner sqlcmd. No credencialesSomee.

Antes de mutaciones verificar imagenID/digest/hostname/labels/puerto/volumen y
estado. dockerexec por ID exacto, shell=False/timeouts/capturabinaria. SQLcmd
stop-on-error/:On Error exit/-b/-V11/-r1/-f65001/-y0/-w65535/-x/-X1,
login/querytimeout acotados. ProtocoloframeJSON estricto correlacionado y
stderr inesperado falla aunque raw0; solo hashes/longitudes, no rawfilas.

Secuencia futura: validarrefs/manifest -> colisiones -> crearvolumen/contenedor
NUEVOS -> startUNAvez -> readinessreadonly bounded -> crearDBUNAvez fueraTX ->
marker/compat160 -> SOLOV1-V13 por bytesexactos en UNATXexterna, GO y COMMITfinal
en misma conexion -> verificar NUEVAconexion. No V14, Flywayhistory o usuarios
runtimepersistentes. Roles originalesEXECUTE/deny; migradorseparadoCONTROL,
no ampliar permisos por conveniencia. Solo semillasV2 aprobadas, no datosreales.
Validar hostname/SQLmajor16/TCP/DB/marker/owner antes de aplicar. Conservar fallos.

Cada mutacion: intento duradero antes y recibo despues con fase/IDs/hashSQL/
argvsaneado/exit/tiempo. Namespace nuevo exclusivo root/tmp/C1Docker-* o TEMP
propio, no overwrite/delete/reparse/UNC. Timeout/reciboperdido implica UNKNOWN,
no retrymutante/cleanupautomatico; timeout de dockerexec no demuestra que SQL
termino. Reconciliacionreadonly en otro gate; readinessreadonly bounded no es
retry de provisioning. Conservar recursos aun si falla. No emitirPASS sin
recibo fresco y estado inequívoco. No borrar trazas o reseed.

Postestado: DBmarca/owner/compat160,37tablas/134SP/31triggers/564ACLroles,
V13presente/V14ausente/OPEN. Derivar hashes internos37tablas/metadata completa
del manifiestocanonico, exportar hashes sin filas/definiciones/secretos. Baseline
Docker NUEVA, no exigir igualdad con Windows ni heredar suPASS/TLS/JDBC/UI.
No activarbackend/frontend/correo ni SQLruntimeparcial.

## Pruebas y entrega

Procesos globalmente doblados en TODOS los tests. Import/plan sin efectos,
ordencomandos/TX/GO/stop-on-error, evidenciaexclusiva y secretoCANARY ausente
de argv/log/resumen/error; negativos de colisiones, daemonhostil/pines/manifest/
digest/labels/hostname/volumen/puerto/fuente, fallosparciales/timeoutUNKNOWNsinretry.
Validar que no se ejecuta V14 o limpieza. No tests que solo repliquen codigo.
AST/generacion es estructura, nunca motor. No Maven/frontend/35unitariosviejos
sin cambios ni mainreal. ScriptsSQLgenerados completos para reviewsupervisor.

Informe TEMP/C1DockerP1-programmer-report.json: IDs,2SHA/snapshot/diff/CLI/
manifestcandidato/SQLgenerado/comandosplaneados, tests/exits/coberturas y
conservacion de fuentes/pines/historia/artefactos anteriores. EN_REVISION:
succeeded significa toolingoffline, no contenedor o DB provisionados.
Procesar todos los lotes y ACKdeliveryId si aparece antes de worker_done,
mantener terminal/sesion. Sin commit/push/main/despliegue/gastos/Somee/AgendlyCitas.

Documentacion oficial consultada por supervisor:
https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?pivots=cs1-powershell&view=sql-server-ver15
Documenta imagen2022 y herramientas /opt/mssql-tools18/bin. AdaptadorDocker de
matrizPRE111 es paquete posterior separado; no quitar guardasLPC existentes.
