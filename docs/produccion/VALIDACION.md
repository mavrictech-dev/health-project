# Validacion y limites de evidencia

## Entornos

- Supervisor: D:/Mavric/Health Project; cambios previos del usuario preservados.
- Implementacion: worktree health-programmer, Maczz09/health-programmer.
- Previsto QA aislada: health-project-qa, 18080/13307/18025, tmp/qa/.env.
- No pacientes reales, envios externos, gastos ni publicacion.

## Evidencia de baseline

Setup: parser 2/2; IdentityOnly dos roles; tres rechazos esperados; procesos/sesiones
distintos --no-daemon; Git limpio del trabajador; tres capturas y reportes leidos.
Pruebas previas de instaladora: check correcto, 30/30 mock, Java10/10, build:demo82,
QA demo13, smoke correcto con 24 abortos de navegacion/prefetch separados. No son
nuevas ejecuciones de produccion. Ver ../agent-workflow.md.

## Ejecuciones actuales

2 de noviembre: `docker context show` = desktop-linux; `docker version --format
'{{json .Server}}'` falla porque no existe dockerDesktopLinuxEngine. No se inicio
Docker Desktop ni se afectaron contenedores existentes. Responsable: entorno local.
No hay MySQL/API real disponible para aceptar persistencia ni migraciones.

Continuar QA aislada verificable sin daemon, contratos y cambios frontend.
Registrar cada comando con resultado, revision de codigo y limitaciones; tests de
transporte simulado no son integracion MySQL.

## QA-01.A — ejecucion independiente del supervisor

En worktree programador: `python -B -m unittest discover -s scripts/tests -v`:
18/18 OK (0.801s), incluye exclusividad, release incluso error/interrupt, entorno,
destinos, transportes falsos Python y restauracion UI/CSRF con VM Node. No API real.
`python -B scripts/health-qa.py config`: exit0, Compose real validado sin daemon.
`python -B scripts/health-qa.py status`: exit1 QA_DAEMON_UNAVAILABLE; lockExists=false.
`git diff --check`: sin errores. Revision R1 pendiente por lock entre worktrees;
estos resultados solos no aprueban el defecto descubierto.

R1: lectura del diff adicional y nueva ejecucion independiente de la misma suite:
23/23 OK (3.018s), con cinco casos nuevos para common-dir, repos independientes,
Git overrides y reemplazos de lock. Ruta real del lock:
D:/Mavric/Health Project/.git/health-project-qa.run.lock. Credenciales siguen en
tmp/qa del programador; esta prueba no arranca servicios.

## INT-01.A — evidencia durante implementacion

El trabajador informa check/40 tests/build live85 paginas, aun pendientes de
aceptacion y navegador final. npm ci informo26 avisos agregados sin cambiar lock.
Supervisor ejecuto `npm audit --omit=dev --json` en frontend del worktree:
exit0, cero conocidas en dependencias de produccion (todos niveles0). No equivale
a revision de seguridad del producto ni a cero avisos en tooling/desarrollo.

Probe supervisor `node tmp/review-api-race.cjs`: fallo reproducido exit1,
newSessionCsrfPreserved=false con respuestas fetch falsas fuera de orden; sin
tokens reales ni API de red. Correccion delegada msg_c8a1564f9b60, ver REVISIONES.

Tras cambio de api.ts en R1, mismo probe independiente repetido:
exit0 y newSessionCsrfPreserved=true. Sin cambiar el probe ni usar red. La
aceptacion de INT-01.A sigue pendiente de cierre y regresiones completas.

## INT-01.A+R1 — comprobaciones finales independientes

- npm test:46/46,0 fallos/canceladas/omitidas,378.8425ms.
- npm run check:exit0.
- node tmp/review-api-race.cjs:exit0; CSRF nuevo preservado.
- node scripts/live-shell-qa.cjs:16 recorridos, errors=[] y blocked=[],
  network=intercepted, mysqlVerified=false; preview propio detenido por finally.
- Revision source: listado real restaurado, textos UTF8 y estado de ruta correctos.
- view_image: live-intercepted-sad-clients-detail.png, mobile-navy.png y
  storage-blocked.png del worktree; legibilidad/movil/panel inspeccionados.
- Builds del trabajador: live85 y mock85, secuenciales; demo13 sin API real.
  No se repitio build sin cambios; se verifico el artefacto con navegador.
- Integracion local:14 archivos con hash identico a fuentes revisadas, fuera de
  main; QA7 preservada. Ninguna prueba acredita backend actual.

## SAAS-01.A+R1 - revision frontend independiente

- npm test: 55/55; npm run check: exit 0.
- node scripts/saas-live-qa.cjs: 9 grupos, 7 HTTP y 1 fallo de red esperados; errores JS/solicitudes/consola inesperados vacios.
- node scripts/live-shell-qa.cjs: 16; wrapper --demo: 13, apiRequests=0.
- Reporte saas-live-intercepted.json: APIs interceptadas, mysqlVerified=false y persistenceOrRollbackVerified=false. Unicamente Edge/Chromium; no prueba persistencia, rollback o MySQL.
- Ocho archivos comparados por SHA256 con el worktree del programador e integrados localmente. R1 verifico UTF-8 estricto, hashes y estado sin cambios; no se recodifico fuente valida. Capturas review/detail/mobile confirman acentos y password ausente.
- Worker reporto builds live/mock de 85 paginas en el paquete inicial; R1 no altero runtime y no se repitieron. Previews propios detenidos.
- No iniciar Docker/API real: pipe dockerDesktopLinuxEngine ausente. No se acredita alta persistente, aislamiento de tenant, concurrencia, duplicado ni rollback.

## ORG-01.A - validacion independiente en supervisor

- npm test: 62/62; npm run check: exit 0.
- Builds live y demo secuenciales: exit 0, 85 paginas cada uno; ruta organizacion presente en ambos exports.
- node scripts/organization-live-qa.cjs: 9 grupos, 8 HTTP/1 red esperados, JS inesperados 0, mysqlVerified=false.
- node scripts/live-shell-qa.cjs: 16, errores vacios; wrapper --demo: 13, apiRequests=0.
- Capturas via view_image: organization-intercepted-configuration.png, confirmed-get.png, mobile-navy.png y mobile-review.png.
- Siete archivos comparados por SHA256 e integrados localmente; 25 archivos anteriores QA/INT/SAAS no cambiaron. git diff --check sin errores.
- La consulta backend de configuracion selecciona t.id mas s.*; la tabla subscriptions aporta tenant_id -> tenantId via Sql.camel. El parser coincide con el contrato.
- Export QA totalmente interceptado; MySQL, persistencia, rollback, concurrencia y navegador distinto de Edge/Chromium no verificados.


## ORG-01.B - validacion independiente en supervisor

- Tras copiar unicamente los cinco archivos autorizados y comprobar SHA256, `npm test`: 68/68; `npm run check`: exit0.
- `npm run build` y `npm run build:demo`: exit0, 85 rutas cada uno.
- `node scripts/organization-live-qa.cjs`: 12 recorridos/grupos, 8 POST interceptados, 33 lecturas de configuracion, 8 respuestas HTTP esperadas y 1 red esperada; JS inesperados0; `mysqlVerified=false`.
- `node scripts/live-shell-qa.cjs`: 16, errores0. `node scripts/demo-qa.cjs` contra preview estatico local: 13, `apiRequests=0`, errores0; preview propio detenido.
- `git diff --check` sin errores. Capturas inspeccionadas via `view_image`: organization-intercepted-team-desktop.png, organization-intercepted-team-unavailable-references.png y organization-intercepted-team-mobile-{light,dark,navy}.png.
- Revisado `OrganizationService.configuration`; los campos corresponden a las queries Java. Reporte `organization-live-intercepted.json`: synthetic/intercepted, privacidad comprobada en QA, MySQL/persistencia/rollback/concurrencia=false. No hay pruebas de API real ni funcionalidad de invitaciones.
- Los otros archivos compartidos que existian en ambos worktrees mantienen hash identico. No se copia ningun otro archivo del worktree de programacion.


## D-09 - discrepancia SQL Server, revision estatica 2026-11-03

Se contrastaron docs/Arquitectura_Health_Project.md (SQL Server/100 % SP), PLAN_EJECUCION_PRODUCCION.md:22 (MySQL), pom.xml, application.yml, compose.yaml, Sql.java y SessionFilter.java. Inventario textual guardado en tmp/sqlserver-architecture-audit.json: 11 migraciones, 60 declaraciones CREATE PROCEDURE/53 nombres distintos, 116 llamadas sql.rows/one/optional en 22 archivos Java. No se ejecutaron nuevas suites, servicios o migraciones; no se afirma que SQL Server este implementado ni probado. La evidencia anterior sigue siendo historica del backend MySQL o frontend interceptado. No renombrar indicadores mysqlVerified como sqlServerVerified para aparentar cobertura.


## SQL-01.A1 - SQLServer2022 real

Base exclusiva health_project_sqlserver_qa_20261103, creada solo tras comprobar que no existia, con marca health_project_scope;37 tablas aplicadas desde V1/V2, exit0 en transaccion. Pruebas de constraints:2 escenarios positivos/9 negativos/rollback correcto. Comparacion independiente de241 perfiles completos, nombres y flags contra fuenteV5:PASS. Ver REVISIONES.md y logs ignorados tmp/sqlserver-*.

Conexion administrativa Windows local/shared memory, sin cambiar servicios ni autenticacion global. TCP y named pipes de la instancia estan deshabilitados (registro comprobado solo lectura); listener1434 es administrativo, no se usa como transporte runtime. JDBC/HTTP real requiere un transporte ordinario disponible; no se habilita/reinicia la instancia compartida automaticamente. Sqlcmd permite validar SP en motor sin ese cambio. Pruebas con sysadmin no acreditan permisos runtime; se haran pruebas bajo usuario efectivo restringido sin login en base QA.


## SQL-01.A2 - procedimientos en motor y permisos efectivos

54 SP aplicados a QA con sqlcmd en transaccion, exit0. tmp/review-sqlserver-a2.py ejecuta16 pruebas independientes reales;16 PASS y cleanup0: sesion/host/membresia actual, aislamiento de auditoria, rechazo de roles falsificados y sesiones revocadas, TX obligatoria, claim_version y no replay ambiguo, NULLmetadata/scope invalido, salud por SP y denegacion de SELECT/DML/auxiliar privado/bootstrap bajo usuario de base WITHOUT LOGIN con grants puntuales de prueba. Conexion subyacente Windows sysadmin; no se acredita login runtime desplegado. Detalle tmp/sqlserver-a2-tests.json y .log. Fuente final SHA b4ebe83471354e2027315d95e1657afde72ad2c19c508e2ef764c2356f940ce0.

Probe JDBC13.4.0 real con DLL native task-local (artefactos MavenCentral/TLS/checksum): conexion localhost1433 a baseQA rechazada con SQLState08S01, conforme a TCPEnabled0 comprobado. No se usa listener administrativo ni se cambia servicio. SQLcmd local/sharedmemory permite continuar pruebas del motor.

## SQL-01.A5 - revision independiente de operaciones, 2026-11-03

- Snapshot V6 del programador: SHA256
  5b007234afce7a435fe9220111249e537a22b467ed922cfdb45c3bec69949458.
- Aplicacion: tmp/sqlserver-apply-a5.sql mediante sqlcmd local, autenticacion
  Windows; destino y marca comprobados antes de BEGIN TRAN. Exit 0, 133 SP.
- `python -u -B tmp/review-sqlserver-a5.py`: 29/29 PASS. Reporte
  tmp/sqlserver-a5-tests.json y detalle tmp/sqlserver-a5-tests.log.
- Dos conexiones simultaneas por carrera: devoluciones, recurso hospitalario y
  dispensacion del remanente de receta. Un ganador y un 51003 por carrera.
- Cleanup de fixtures: exit 0; SELECT posterior devuelve 0 usuarios qa-a4/qa-a5.
  Los casos ordinarios se revirtieron y solo los fixtures propios de concurrencia
  requirieron limpieza. Sin datos reales, envios, cambios de servicio o de instancia.
- Credenciales efectivas almacenadas contrastadas: arquitecto recuperapiura,
  programador mendozadeafabisa. Sesiones retenidas distintas; procesos restaurados
  de ambas sesiones observados con --no-daemon. Run asumido por la terminal actual
  term_779d7560-04db-4c25-a7de-8be1163bcfb6 tras comprobar coordinador anterior
  inactivo, con limite de uso, y todas las tareas anteriores asentadas.
- Los errores de la primera version del harness (clave JSON y parametro create)
  se corrigieron antes del resultado final. No hubo correccion adicional de V6.
- Limites: conexion subyacente administrativa y aserciones de motor. No se
  ejecutaron HTTP/JDBC, cuenta runtime desplegada ni QA visual nueva porque no
  hubo cambios frontend. La evidencia visual previa conserva su alcance original.

## SQL-01.A6 - preflight de snapshot, entrega final pendiente

Avance msg_1f768cd3731e, Task task_f3b982860225 / Dispatch ctx_4d330d95d46d.
El supervisor inspecciono la proyeccion de users, support_comments y los guards
inmutables del borrador. Snapshot SHA256
56a0a6ad1c9ec2d6172085394d532c17d22d5cc45ecf4929d4fbaae9933d41a0:
31 CREATE TRIGGER (29 negocio, 2 inmutabilidad), UTF8 estricto sin U+FFFD.
`python -B tmp/sqlserver-preflight.py V7__audit_triggers.sql`: exit 0 en SQL
Server2022, destino QA marcado, CREATE dentro de TX y ROLLBACK. Comprobacion
posterior: 0 triggers persistidos, 133 procedimientos conservados. Evidencia
tmp/sqlserver-v7-preflight.json, .log y snapshot.

Esta ejecucion solo acredita compilacion del snapshot; no se integra V7 ni se
acepta A6. Faltan el informe final, verificacion de hashes y pruebas funcionales
multirregistro, cambios de PK/tenant, Unicode/hash, rollback, permisos e
inmutabilidad con operaciones reales. El programador sigue en revision estatica.

### A6: revision funcional de entrega final (sustituye estado preflight)

`python -u -B tmp/review-sqlserver-a6.py`: 20/21 PASS, exit1 por hash UTF8 largo;
rollbackVerificationExit0. Cada caso instala snapshot y fixtures dentro de la
misma TX y los revierte, incluidas pruebas negativas. Postconsulta explicita:
0 triggers/0 usuarios fixture/133 SP. Cuatro comprobaciones se ejecutan como
usuario DB efimero WITHOUT LOGIN con EXECUTE solo en dos SP de prueba, sin
grants sobre tablas; esto no acredita login runtime desplegado.

Se ejercitan 29 triggers en un recorrido sintetico y se verifican controles
multirregistro, MERGE, PK/tenant, no-op, privacidad e inmutabilidad. El hash largo
se compara contra Python sobre bytes originales, sin sustituir la referencia
por HASHBYTES de la misma expresion defectuosa. Reproduccion y valores en
REVISIONES.md; V7 DEVUELTA y sin integrar. Consultada documentacion primaria
[CAST y CONVERT](https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver16)
durante investigacion; la evidencia determinante es la reproduccion en esta
instancia SQL2022, no la simple presencia de COLLATE UTF8 en el texto fuente.

### A6.R1: probe independiente del enfoque, aun sin aceptar V7

Pregunta msg_43c08eed1310: materializar NVARCHAR directamente en columna de tabla
variable varchar(max) con collation UTF8. Probe del supervisor en SQL2022:
6/6 PASS, exit0; bytes/longitud/SHA256 exactos contra Python para NULL, vacio,
texto null, ASCII, U+00C1/U+4E2D/U+1F9B7 y JSON largo. Corto9bytes con hash
d36faa8acee4903285ebe95bdb3e571843d487a9efc5b3c5e25d012ddae1cec3; largo16014bytes
con hash9cd5937d4dd981f187d3e6ddeb66693cbe982d11c2cb8fea7435ae735b2fb6a1.
Evidencia tmp/sqlserver-a6-utf8-materialization-probe.sql/.json; DBwrites=false.
Implementacion de V7 y regresiones de triggers siguen pendientes (D-14.B).

### A6.R1: V7 corregida, 25/25 independientes PASS

Comandos reales desde raiz (SHA como argumento protege el snapshot):
```powershell
python -u -B tmp/review-sqlserver-a6.py tmp/sqlserver-v7-r1-snapshot.sql c5657fa2329ab306d93ddda99efce52f95285575c8437295666b35670dbadf1f
python -u -B tmp/review-sqlserver-a6-r1-unicode.py
python -B tmp/accept-sqlserver-a6-r1.py
sqlcmd -S localhost -d health_project_sqlserver_qa_20261103 -E -C -b -f 65001 -i tmp/sqlserver-a6-r1-install.sql -o tmp/sqlserver-a6-r1-install.log
```

Primer harness 21/21 y rollbackVerificationExit0; adicional 4/4 con hashes
Python de todos los campos antes/despues, multirregistro y Unicode largo.
Los informes conservan SHA exacto c5657fa2...f1f. Pruebas sobre SQL2022 real
mediante sqlcmd administrativo; cuatro casos del primer harness usan usuario
WITHOUT LOGIN restringido, no login/JDBC runtime desplegado. Instalacion final
solo tras aceptacion: guardas nombre y marcador QA, 31 triggers/133 SP/0 usuarios.
No queda principal/fixture de prueba. Credenciales leidas solo para comparar
email de ambos roles; no tokens expuestos ni sesiones cambiadas.

Sin nuevas capturas: A6 modifica SQL, no interfaz. La evidencia visual previa
es frontend con transporte interceptado; sigue sin validar integracion real.

### A7 entrega original:7/7fases reales PASS, compatibilidad historial FAIL

Supervisor ejecuto python -B tmp/review-sqlserver-a7-provisional.py y
python -B tmp/review-sqlserver-a7-final.py: exit0; snapshot verificado por SHA
de V8 y verificador.7fases SQL2022 PASS,562permisos efectivos,308negativos229;
6fases de denegaciones esperadas retornan exit1 con3998 controlado y cleanup
independiente. Reportes tmp/sqlserver-a7-final-review.json/.log conservan
stdout y baseline4E96A8D47A07A3863D50E05694533B230143F82938F131FFF6601FF2F0499874.

Prueba adicional python -B tmp/review-sqlserver-a7-history-repro.py documenta
fallo esperado de la entrega original al existir tabla dbo.flyway_schema_history
sintetica representativa: rawsqlcmd exit1/51000, cleanup identical. Harness
exit0 significa reproduccion del defecto confirmada, NO criterio productoPASS.
No se ejecuto Flyway real, JDBC, HTTP ni QAvisual; esos siguen pendientes.
V8 DEVUELTA, no integrada/aplicada permanentemente. Se conserva evidencia de
ambos resultados sin presentar PASS del catalogo parcial como migracion validada.

### A7.R1 corregida:10/10fases PASS en ejecucion del supervisor

Comando python -B tmp/review-sqlserver-a7-final.py --r1, raiz Health Project.
Hashes exactos V8 63ca532a...067f4e y verificador76c9d3ca...d2217a.
Snapshot bajo tmp/sqlserver-a7-r1-snapshot; stdout/resultados completos en
tmp/sqlserver-a7-r1-review.log/.json.10fases y20checks pre/post desde conexiones
nuevas, mismo fingerprint4E96A8D47A07A3863D50E05694533B230143F82938F131FFF6601FF2F0499874.

Normal/history/unknown_table rawexit0; ddl_runtime/ddl_bootstrap/impersonate_
runtime/impersonate_bootstrap/scope_exists/scope_create/monitor_unauthorized
rawexit1 intencional con3998unico tras errores esperados262/15517/51001.
Runner globalexit0 afirma resultados+cleanup, no oculta errores inesperados.
562ACL sinhistoria/571conhistoria,308/317negativos229 respectivamente; autorizacion
SAD/SOP y rechazo anonimo verificados porSP, tabla desconocida no causa mutacion.

V8 y verificador integrados localmente por bytes/SHA, V1-V7 preservadas.
V8 aplicada solo dentroTX revertidas, no roles persistentes ni historial/usuarios
fixture. Scope real es motorSQL2022 e impersonacionDB WITHOUT LOGIN; historial
sintetico representativo. Aun pendientes Flyway real, JDBC/logins, HTTP y
recorridos UI contra backendSQLServer. No nueva validacion visual en este corte.

### A8: build y pruebas del supervisor sobre snapshot exacto

Preparacion python -B tmp/prepare-sqlserver-a8-review.py verifica SHA7archivos,
pom(delta exacto2dependencias) y87bases preintegracion; copia aislada bajo
tmp/sqlserver-a8-review/backend. Desde alli .\mvnw.cmd -B -ntp verify exit0:
49tests/0fail/0error/0skip (22Executor,17Errors,10previos),jar y repackagePASS.
JDK21.0.5, Mavenwrapper3.9.11. ReportsSurefire XML/txt en snapshot/target;
tmp/sqlserver-a8-acceptance.json conserva resultados y hashes.

Comando independiente .\mvnw.cmd -B -ntp dependency:tree con -Dincludes de
mssql-jdbc,flyway-core/sqlserver/mysql,mysql-connector-j,HikariCP exit0; versiones
13.4.0.jre11/12.4.0/9.7.0/7.0.2,gestionadas porBoot4.1.1. Dos avisosJDK de
Mockito/agentdinamico no impidieron tests; no se cambio build por ello.

Alcance unitario: doblesJDBC y Spring ConnectionHolder simulado, cargaDriver
offline, no conexionSQLServer real. Prueba de reset/abort/evict no acredita
poolreal ni rollback real; siguen pendientes transporte/login/Flyway/HTTP.
Siete archivos integrados por hash sin activar datasource ni beans. No nueva
prueba visual para este cambio de backend; evidencia UI previa fue interceptada.

### A9: compilacion y 169 pruebas del supervisor

python -B tmp/prepare-sqlserver-a9-review.py verifico los cuatro SHA de entrega
y preparo snapshot desde la base del supervisor. En
tmp/sqlserver-a9-review/backend: .\mvnw.cmd -B -ntp verify, exit 0, BUILD SUCCESS
16.126 s; 169 tests/0 failures/0 errors/0 skipped, empaquetado PASS. Reports
XML/txt en target/surefire-reports del snapshot; manifiesto y resumen en
tmp/sqlserver-a9-review-manifest.json y tmp/sqlserver-a9-acceptance.json.

Se verifican 108 firmas contra recursos SQL, binds INT/BIGINT/MAX y regresiones
del adaptador; contexto mantiene 10 campos internos. Son contratos estaticos
y mocks JDBC, sin motor conectado, Flyway, pool real, HTTP o navegacion visual.
No se repitieron suites de permisos/frontend sin cambios pertinentes. Cuatro
archivos integrados localmente por hash, sin app o datasource nuevo activado.

### A10: filtros y store, 218 pruebas del supervisor

python -B tmp/prepare-sqlserver-a10-review.py verifico cinco SHA y94 bases.
En tmp/sqlserver-a10-review/backend: .\mvnw.cmd -B -ntp verify, exit0;218tests
sin failures/errors/skips y empaquetado PASS. Reports XML/txt en target/
surefire-reports del snapshot; manifiesto y acceptance.json en tmp.

Pruebas de filtros reales con HTTP simulado y store real con executor/manager
dobles: cinco SP, contexto desde atributos internos, callbacks transaccionales,
CSRF/host/membresia/roles/rutas,401/403/500 y503, sin fallback, actor tras touch
y atribucion downstream. SQL Server, datasource comun, rollback fisico, pool,
Flyway y HTTP/navegador reales siguen sin validar. No se ejecuto DB ni app.

Cinco archivos integrados por hash, sin tocar SecurityConfiguration o defaults.
No prueba visual nueva: camino SQL no activado y frontend intacto. Evidencia
visual anterior sigue siendo interceptada, no integracion real.

### A11 borrador:249 pruebas independientes, cierre bloqueado

Tras error de cuota del trabajador se inspeccionaron procesos y reports, sin
proceso Maven activo en su worktree. Segundo build worker habia terminado con
249tests/0fallos (artefactos, no reporte final). Supervisor ejecuto
python -B tmp/prepare-sqlserver-a11-draft-review.py y, desde snapshot
tmp/sqlserver-a11-draft-review/backend, .\mvnw.cmd -B -ntp verify: exit0,
BUILD SUCCESS18.808s,249tests/0failures/0errors/0skipped,jar/repackagePASS.

Manifest/result.json y reportsSurefire del snapshot conservan seis hashes
observados y resultados. Se comprueba igualdad de esos seis borradores con
worker y97bases backend del supervisor sin cambios. No integracion ni aceptacion,
falta informe final/preservacion del programador y worker_done. Unit tests con
dobles y TX modelada, no JDBC/DB/pool/Flyway/HTTP reales ni nueva QAvisual.

### A11: evidencia de borrador confirmada por entrega final

Reporte final y worker_done confirman los mismos seis hashes observados;
aceptacion en tmp/sqlserver-a11-acceptance.json. Se conserva verify independiente
249/249,0fail/0error/0skip y jar del snapshot tmp/sqlserver-a11-draft-review/backend
(18.808s), sin repetir suite porque no hubo cambios. Nuevas31 (20servicio+11store)
y218previas. Manifest y reportsSurefire siguen disponibles.

Seis archivos integrados localmente por hash. Se validan comportamiento de
servicio y contratos/transacciones modeladas; NO conexiones, suspension real,
durabilidad, pool, Flyway, HTTP conectado o registro completo. Wiring vigente
continua legado, no nueva evidencia visual o de API real. A12 queda pendiente.


### Preparacion de push autorizado, 2026-11-04

El usuario solicita continuar pendientes y hacer push. Antes de confirmar el
trabajo se verifica root D:/Mavric/Health Project, rama health/production-wave0,
worktree y origin https://github.com/mavrictech-dev/health-project.git. Remoto
de la rama en c715ecc9ff4aa67f3550553cd281f1b8ce2af758; main separado.

Backend completo coincide, normalizando solo EOL, con el snapshot independiente
A11 de 249/249 y jar PASS. Los seis SHA de aceptacion A11 coinciden exactamente.
Se reutiliza evidencia sin repetir Maven; no se contacto SQL Server. Frontend:
npm.cmd run check exit0 y npm.cmd test exit0,68/68,0fallos/0omitidas.
Escaneo local de49 archivos candidatos:0 coincidencias de patrones de claves
privadas, tokens GitHub/OpenAI o JWT. No incluir tmp, auth, env ni artefactos.
No nueva prueba visual; las evidencias visuales anteriores son interceptadas.
Migracion activa, JDBC/Flyway/HTTP y navegacion con backend real pendientes.


### A12 - snapshot supervisor,279 pruebas

python -B tmp/prepare-sqlserver-a12-review.py confirma6SHA de entrega y103bases,
prepara snapshot desde backend supervisor con solo6reemplazos autorizados.
Desde tmp/sqlserver-a12-review/backend: .\mvnw.cmd -B -ntp verify con JDK21,
exit0,BUILD SUCCESS20.765s,279tests/0failures/0errors/0skipped y jar/repackagePASS.
Log tmp/sqlserver-a12-review/verify-supervisor.log; XML en target/surefire-reports.
Controller19 nuevos,servicio25,store17,otras218;30nuevas+249previas.

python -B tmp/accept-sqlserver-a12.py vuelve a verificar SHA/bases y preservacion
de pruebas anteriores; integra5existentes+1nueva,98bases ajenas intactas.
Pruebas HTTP simuladas y manager de TX modelado; no Boot/puerto, DB, JDBC,
Flyway o navegador conectado. No nueva QAvisual; frontend no cambio. No repetir
suites frontend/motor sin cambios pertinentes. Integracion real sigue pendiente.


### A13 -301 pruebas independientes, entrega sin cierre formal

python -B tmp/prepare-sqlserver-a13-review.py confirma4SHA/104bases y prepara
snapshot tmp/sqlserver-a13-review/backend desde backend supervisor. Dentro de
snapshot, .\mvnw.cmd -B -ntp verify con JDK21:exit0,BUILD SUCCESS20.295s,
301tests/0failures/0errors/0skipped,jar/repackagePASS,2026-11-04T15:45:31-05:00.
Access12 nuevos+Store10,279previas completas. Log verify-supervisor.log y XML
Surefire preservados. Result.json verifica de nuevo hashes y104bases intactas.

Son executor/manager dobles, request y SecurityContext locales; no SQLServer
conectado, pertenencia/revocacion en motor ni navegacion/HTTP real. Sin QAvisual
nueva por cambio backend aislado. No integrar hasta cierre del encargo; cuotas
del trabajador impiden worker_done. No repetir suite si hashes no cambian.


### A13 - cierre recibido, misma evidencia301/301

Worker_done msg_d0f5e7def244 permite cerrar entrega. Cuatro SHA actuales iguales
al snapshot301/301,0fail/0error/0skip,jarPASS20.295s. Se reutiliza build del
supervisor del15:45, no se presenta como ejecucion nueva. Acceptance
tmp/sqlserver-a13-acceptance.json verifica104bases/103fueraownership y4SHA.
No conexionSQL/JDBC/Flyway/HTTP/navegador real. Cuatro archivos integrados sin
activar SQL; la prueba de permisos/modelos no acredita pertenencia en motor.


### A14 -316 pruebas del supervisor y preservacion

python -B tmp/prepare-sqlserver-a14-review.py:4SHA exactos/107bases, snapshot
tmp/sqlserver-a14-review/backend. Dentro: .\mvnw.cmd -B -ntp verify,JDK21,
exit0,BUILD SUCCESS25.776s,316tests/0failures/0errors/0skipped,jar/repackagePASS,
final2026-11-04T17:59:23-05:00.15nuevas+301previas. Log verify-supervisor.log
y XML target/surefire-reports del snapshot conservados.
python -B tmp/accept-sqlserver-a14.py verifica de nuevo hashes/baselines y
cuerpos legado/rate,integra4archivos.106bases ajenas intactas.
Pruebas con dobles/TransactionTemplate+manager modelado,sin SQL/JDBC/HTTP real.
No nueva captura ni QAvisual; catalogo aislado de frontend/config activa.


### A15 -331 pruebas y MockMvc standalone

python -B tmp/prepare-sqlserver-a15-review.py verifica5SHA/110bases y prepara
snapshot tmp/sqlserver-a15-review/backend. .\mvnw.cmd -B -ntp verify dentro de
snapshot con JDK21:exit0,BUILD SUCCESS22.257s,331tests/0failures/0errors/0skipped,
jar/repackagePASS,2026-11-04T18:11:20-05:00. Servicio14,store12,controller4,
301otras;15nuevas sobre316 (una guarda anterior reemplazada conscientemente).
Log verify-supervisor.log y XML Surefire conservados.
python -B tmp/accept-sqlserver-a15.py confirma hashes/bases,legado/rate y
pruebas anteriores salvo guarda D-23 y cleanup de sincronizaciones solicitado.
5archivos integrados;106bases ajenas intactas. Sin DB/app/puerto/SMTP ni nueva
prueba visual; MockMvc no acredita integracion real o no enumeracion bajo carrera.
