# PAC-01.C1.DOCKER.PIN.E1: medir binario en imagen exacta, sin motor SQL

Contrato supervisor, 2026-11-12. Usuario habilito Docker para continuar.
P1R1 aceptada e integrada OFFLINE tras35tests propios,5SQL byteexactos y
41comandosmodelo identicos. Este encargo autoriza SOLO inspeccion acotada de
imagen con UN contenedor NUEVO que ejecuta sha256sum, no SQL Server/sqlcmd.
No provisioning de la base, volumen, red externa, credenciales o puerto.

Leer AGENTS/flujo/TAREAS, P1/Q1/R1 y D-87.AT CANONICOS en D:/Mavric/Health Project.
Misma pareja/cuentas por proceso/--no-daemon/worktree/sesion/terminal; usar IDs
NUEVOS del preambulo. Supervisor unico escritor docs/board/evidencia versionada.
No producto/docs/manifestoperativo nuevos ni cambios de fuentes/config/deps.

## Ownership, evidencia y preflight

Solo TEMP NUEVOS C1DockerPinE1-* para helper de comandos/receipts/reporte y
ROOT/tmp/C1Docker-PinE1-20261112-run01 para evidencia exclusiva create-only.
Sin overwrite/delete/reparse/UNC. Evidencia antes de cada mutacion y despues,
hashes/longitudes/exit/tiempo/argv/IDs exactos. Conservar errorprimario/secundarios
si tambien falla escribir. No repetir suites/parser/Maven/frontend por rutina.
Revalidar717fuentes entrecheckouts y pines/historia/artefactos anteriores; ningun
delta permitido. Puede usar importNOmain de toolingROOTintegrado para refs/
CLI/entorno/evidencia, con hashes exactos y sin invocar PROVISION.

CLI C:/Program Files/Docker/Docker/resources/bin/docker.exe SHA
6C699720BB9523DEDB9EB5D22A49951EA9210DBDB1314A3554029EEE9BE76896;
contexto explicito desktop-linux, namedpipe npipe:////./pipe/dockerDesktopLinuxEngine,
engine29.8.2/Linuxamd64. Rechazar overridesDOCKER_*/SQLCMD/sa o otrodaemon;
no cambio global de contexto. shell=False, argvlista/capturabinaria, timeout30s.
Usar Python para argumentos con comillas de templatesGo: PowerShelllegacy puede
eliminarlas. No imprimir Dockerinspect completo/Config.Env/logs o recursosajenos.

Imagen EXACTA descargada, no pull/tagmutable:
mcr.microsoft.com/mssql/server@sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f
ImageIDigual sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f.
Supervisor verifico por lectura imagenlinux/amd64, usermssql y Config.Volumes
ausente/null (lookup Go index, acceso directo falla por keyausente). Revalidar
selectivamente id/digests/os/arch/user/labels/volumes antes de crear; si imagen
declara volumenes o cambia algun pin, STOP. No crear volumen anonimo.

## Una creacion y un arranque de proceso sin SQL

Nombre/hostname NUEVOS: healthproject-c1qa-sqlcmdpin-20261112.
Label com.mavric.health.qa=c1-sqlcmdpin-20261112 y label de runnonce propio.
Comprobar ausencia exacta del nombre antes de crear, no adoptar/renombrar/reusar.
No recursos healthproject-c1qa-20261112 ni HEALTHPROJECTQA/Somee/AgendlyCitas.

Comando create autorizado (anteponer CLI pinneado y --context desktop-linux;
expandir solo labelnonce propio y digest literal anterior):

```text
container create --pull=never --platform linux/amd64 --name healthproject-c1qa-sqlcmdpin-20261112 --hostname healthproject-c1qa-sqlcmdpin-20261112 --label com.mavric.health.qa=c1-sqlcmdpin-20261112 --label com.mavric.health.qa.run=<nonce> --user mssql --read-only --network none --cap-drop ALL --security-opt no-new-privileges=true --restart=no --no-healthcheck --entrypoint /usr/bin/sha256sum <imagen-exacta> /opt/mssql-tools18/bin/sqlcmd
```

NO env/secreto/EULA/puerto/mount/privileged/socket o volumen. CIDdevuelto exige
64hexlower exactos/raw0/stderrvacio; validar inspeccion SELECTIVA por eseID:
imagen/labels/hostname/user esperados, entrypointsha256sum y Cmdunico pathSQLcmd,
estadoCreated/noRunning, readonlyrootfs=true/networknone/restartno/privilegedfalse,
capdropALL/no-new-privileges=true, sin binds/mounts/portbindings/publishAllPorts,
healthcheckNONE. Se permiten representaciones nativas null/listavacia de campos
sin recursos, sin relajar propiedad o valores. Si difiere, STOPsinarrancar.

UNA llamada container start --attach <CIDexacto> ejecuta SOLOsha256sum.
Exigir raw0, stderrvacio y stdout EXACTO 64hexlower + dosespacios +
/opt/mssql-tools18/bin/sqlcmd con finalLF/CRLF opcional. Registrar hashmedido,
NO inventarlo/normalizar salida arbitraria. PostinspectNUEVO porCID confirma
identidad/guardas intactas, exited/Runningfalse/ExitCode0. No otro start/exec.
Conservar contenedor parado y todaevidencia; no rm/prune/cleanup automatico.

Ante timeout/reciboperdido/escritura incierta: UNKNOWN/STOP sin retry/reconcile
o limpieza; conservar fase/IDconocido y consultar por Orca. No inferir que CLI
timeout detuvo el contenedor. Colision/preflightfallido no permite mutaciones.
No sqlcmd -?/-Q, shell, sqlservr, conexionTCP/SQL, creacionDB o credencial.
Solo hash binario dentro de imagenpinneada. No prueba autenticacionSQLCMDPASSWORD
con-X1/TLS/JDBC: el readinessreal posterior debera validarlo ANTES de CREATE DB.

## Entrega y aceptacion

TEMP/C1DockerPinE1-programmer-report.json: nuevosIDs, comandos/receipts ordenados,
fuentes/CLI/imagenpins, CID/labels/estadofresco, SHAmedido, salidasha segura,
conservacion717fuentes/pines/evidencias y ceroSQL/DB/volumen/credenciales.
Exito solo si hashmedido y estado final ambos acreditados, EN_REVISION.
Error/timeout/preflightbloqueado se reporta failed/UNKNOWN con evidencia, no
success por capturarlo. Supervisor aprobara el pin; no cambiar reviewedfalse/
innerpinNull de manifiestos originales ni generar aprobacionoperativa.
Procesar todos los lotes/ACKdeliveryId antes de worker_done, mantener terminal.
No commit/push/main/despliegue/gastos/datosreales/FactuEz o serviciosWindows.
