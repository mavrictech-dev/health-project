# PAC-01.C1.DOCKER.PROVISION.E1: una base SQL2022 sintetica nueva

Contrato supervisor, 2026-11-12. Continuidad Docker autorizada por usuario.
Tras PIN-E1 revisada y pin aprobado, se autoriza UNA invocacion del tooling
ROOT P1R1 exacto para crear el entorno nuevo y aplicar SOLO V1-V13. No desplegar
producto ni activar backend/API/frontend. No V14 o matrizPRE111 en este encargo.
Leer AGENTS/flujo/TAREAS, contratosP1/Q1/R1/PIN-E1 y D-87.AU CANONICOS en
D:/Mavric/Health Project. Misma pareja/cuentas por proceso/--no-daemon/worktree/
terminal/sesion retenidos, IDs NUEVOS del preambulo. Supervisor unico escritor
documental; consultar Orca antes de ampliar ownership o recuperar fallos.

## Fuentes y manifiesto de una ejecucion

ROOT/scripts/health-sqlserver-docker-qa.py SHA256
6F5FE6126410A1F0002184B6DE976125E4189109B5C4A019ED9C1DCBF032CA2A y test
ROOT/scripts/tests/test_health_sqlserver_docker_qa.py SHA
D05D8A5D4C9C6977D9BAA48B4512A8FC28DDC5A5EDBD0D46FAD42DFF7B22E73A.
Modulo C1P2R1 CEB2C952...0CC22/template9476CEC9...C1D4D y TODOS los pines V1-V14
del manifiesto canonico intactos, V14solo conservacion NO ejecucion.

Manifiesto NUEVO aprobado por supervisor:
ROOT/tmp/c1dockerpin-e1-supervisor-20261112/reviewed-provision-manifest.json.
Su SHA exacto se fija en evidencia versionada DOCKER_SQL_PIN_E1_20261112.json;
verificarlo antes de toda invocacion, sin editarlo o regenerarlo desde worker.
reviewed=true e innerSqlcmdSha256 aprobado:
447775C5DA41E04AC04CEBDB2EB0DDED06213402342715040BEA49B58AB05ADC.
Todos los manifiestos candidatos anteriores null/unreviewed permanecen intactos.
La aprobacion es para esta sola Task, no habilitacion general de PROVISION.

Antes de correr: snapshot/conservacion717fuentes y TODOS los artefactos previos,
pines726/historia301/snapshots21/migraciones25. No repetir tests/parser/Maven/
frontend;35tests propios y5SQL/41callsmodelo revisados ya existen. Los outputs
previos no se sobrescriben. No sync/reset o copia de fuentes al worktreeworker.

## Ownership y limites operativos

Solo evidencia NUEVA ROOT/tmp/C1Docker-ProvisionE1-20261112-run01 (debe NOexistir
antes del CLI), ROOT/tmp/c1docker-provision-e1-20261112 para capturas externas y
TEMP NUEVOS C1DockerProvisionE1-* para helper/fingerprint/reporte. Ninguna fuente,
test, manifest revisado, doc/board, jar/deps/config/credencialprevia o evidencia
antigua editada. Puede escribir helper de captura/comandos acotado en TEMP,
pero ejecutar SOLO el CLI ROOT revisado, sin parchearlo/instrumentarlo en vuelo.

Target fijo NUEVO healthproject-c1qa-20261112, hostname igual, volumen nuevo
healthproject-c1qa-20261112-data, DB health_project_c1_docker_qa_20261112,
label com.mavric.health.qa=c1-20261112/runlabel propio y SOLO127.0.0.1:14436.
Imagen4525e3ef...13b7f y CLI6C699720...6896 completos en manifest, contexto
desktop-linux/namedpipe aprobado. Sin composeMySQL, otros recursos/FactuEz,
MSSQLSERVER/WindowsHEALTHPROJECTQA, Somee/AgendlyCitas, UAC/servicios/TLS o
seleccionglobal/contextoremoto/pull/rediseño de imagen. El contenedor de PIN
3b39d275c60a913fbcd8b63918b76a87c8e4b49f0bc89d645211230f7a36c202 se conserva
exited y no se reutiliza/reinicia para SQL. Colision/preflight es STOP, no adoptar.

SA NUEVO propio generado por tooling, entornohijo SOLO, no argv/log/envglobal/
archivo de secretos ni lectura de Config.Env. Sa solo migracion/owner, no runtime.
Preservar roles EXECUTE/deny aprobados, sin credenciales/usuariosruntime o grants
adicionales para solventar errores. No destinatarios/datos reales o gastos.

## Una invocacion exacta, sin retry

```text
python -B "D:/Mavric/Health Project/scripts/health-sqlserver-docker-qa.py" PROVISION --canonical-root "D:/Mavric/Health Project" --manifest "D:/Mavric/Health Project/tmp/c1dockerpin-e1-supervisor-20261112/reviewed-provision-manifest.json" --evidence-dir "D:/Mavric/Health Project/tmp/C1Docker-ProvisionE1-20261112-run01"
```

No crear primero evidence-dir. Capturar stdout/stderrCLI binarios y exit en
archivos nuevos externos a evidence-dir, sin publicar reportecompleto/buffers.
Guardar intento/tiempo/PIDhelper antes; execyield corto no significa timeout o
salida del proceso. Tooling tiene timeout180 por comando y SQLlogin30/query120;
no imponer limite de shell menor que mate una corrida valida, ni reenviar si
la respuesta tarda. No sqlcmd/probes manuales o llamadas extras del worker.

Secuencia EXACTA revisada: contexto/daemon/imagen/ausencia/puerto -> volumen/
contenedor nuevos -> startUNAvez -> checksimagen/volumen/CID/pin -> UNAreadiness
SQL readonly (DBmaster) -> createDBUNAvez fueraTX -> compat160/marker -> V1-V13
byteexactos/GO en UNATXexterna con COMMITfinal -> conexionNUEVA de verificacion.
Readiness debe probar autenticacion SQLCMDPASSWORD con flags-X1 y targethost/
SQLmajor16/Developer/TCP/sa ANTES de CREATE DB. No inferir compatibilidad desde
PIN, mocks o docs. Si servidor tarda/falla auth/transporte/frame, STOP; no
quitar flags/cambiar password/reintentar readiness/provision para forzarPASS.

No V14, Flywayhistory, runtimebackend, fixtures reales, reenviar migraciones,
repair/reapply/rollbackmanual o compensacion. Postestado esperado:37tablas/
134SP/31triggers/564ACLroles, V13presente/V14ausente/OPEN, ownerSQLsa/CONTROL
separado y markerDocker propio. Fingerprints internos de37tablas y catalogo
completo sin rawfilas/definiciones. Es baseline NUEVA, no igual a Windows ni
prueba SQLPRE111, JDBC/TLS/authHTTP/CSRF/UI de gestion.

## Fallos, entrega y reconciliacion posterior

Primer fallo detiene todo. Guardar primaria/secundarios, phase/order/nonce/IDs,
rawexit/stats/recibos validados. Timeout o reciboperdido puede dejar SQL vivo y
commit tardio: resultado UNKNOWN y recursos conservados, sin retry/cleanup/
startstop/reconcile/adopt o migracion alternativa. No omitir la entrega si falla.
Worker_done outcome failed para corridaFAIL/UNKNOWN, no succeeded por capturarla.
Se resolvera con otro gate readonly revisado; no inventar estado final limpio.

Si PASS: conservar contenedor SQL running para siguiente QA, volumen y evidencia;
no cleanup automatico. Informe TEMP/C1DockerProvisionE1-programmer-report.json
con nuevosIDs/hashmanifest/comando/exits/tiempos, CID/volumen/runlabel, journal/
summary, readiness y estado final validados, counts/fingerprints y conservacion
717fuentes/artefactos/pines. Solo EN_REVISION, supervisor verificara evidencia
y una baseline readonly independiente desde conexion nueva antes de aceptar.
No sonar puerto externo, otro target o consultar tablas reales.
ACKdeliveryId si aparece y procesar todos los lotes antes de worker_done,
mantener terminal/sesion. No commit/push/main/despliegue o nuevas autorizaciones.
