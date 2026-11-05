# Ensamblado SQL Server: contrato y estado

Auditoria A52 del 5 de noviembre de 2026, aceptada como inspeccion estatica.
Informes Orca: msg_e1d08a75d0cb, msg_3e7691fec50d, msg_19c574d0fc9c y
msg_dd188b41730d. Cierre: msg_7146d53bd230, task_9884fa7bdeea / ctx_0413ad736efc.

## Hallazgos contrastados

Hay 24 consumidores Java de persistencia y 24 clases Store: 23 de runtime y una
de bootstrap. Los servicios de negocio tienen alternativas SQL Server aisladas.
Faltan las factories que compongan esas alternativas en el runtime.

Los constructores @Autowired actuales seleccionan Sql. SecurityConfiguration
crea TraceFilter, HostFilter y SessionFilter con Sql. AttemptRecorder tambien
depende de Sql; IdentityService con SQL Server usa store.failed REQUIRES_NEW,
por lo que la composicion puede excluir ese bean heredado.

HealthApplication escanea componentes, habilita scheduling y su opcion
--migrate usa Flyway con db/migration heredado. Bootstrap es un runner
transaccional escaneado. application.yml mantiene el datasource MySQL; pom ya
incluye el driver y Flyway para SQL Server.

El bytecode del driver instalado mssql-jdbc 13.4.0.jre11 confirma SELECT 1 dentro
de isValid(int). Hikari 7.0.2 y Actuator pueden seleccionar esa validacion por
defecto. V3 ya define usp_health_ready con ready INT=1 y V8 concede su ejecucion
al runtime. MonitorStore lo usa en details/sample; falta una comprobacion
independiente sin muestreo ni efectos.

La API instalada es org.springframework.boot.health.contributor.HealthIndicator,
de spring-boot-health 4.1.1. Las referencias de la matriz completa estan en los
cuatro informes Orca; la parte 4 corrige las erratas de numeros de linea.

## Contrato arquitectonico

1. Componer explicitamente fuera de com.mavric.health, sin escaneo general,
   duplicacion de beans ni override. Mantener un solo main para el empaquetado.
2. Usar un DataSource, JdbcTemplate, manager predeterminado y executor con
   Purpose.RUNTIME. Los 23 stores comparten ese datasource y manager; los
   DTO y hashes usan el mapper Spring configurado.
3. Seleccionar todos los constructores SQL, incluido Portal con cuatro stores y
   Scheduling SQL. Access SQL resuelve branch/link. Identity SQL se comparte
   entre lifecycle, plataforma y organizacion. Probar la ausencia global de
   Sql, AttemptRecorder, Bootstrap y Flyway en el runtime.
4. Reservar EXECUTE sobre SP aprobados al principal runtime. Migracion, setup y
   bootstrap usan procesos y principales separados. No provisionar logins desde
   la aplicacion. Rechazar flags y credenciales de setup, Flyway y SQL init en
   el runtime; evitar importar el root heredado.
5. Preservar auth, stateless, whitelist, SAD, cookies, CSRF, afterCommit y el
   orden Trace -> Host -> Session. Crear los filtros dentro de la cadena para
   evitar su doble registro como filtros servlet.
6. Separar readiness de liveness y del modo operacional. Usar HEALTH_READY para
   readiness y, posteriormente, EXEC dbo.usp_health_ready como probe fijo del
   pool. No usar el executor desde el probe del pool: adquiriria otra conexion.
7. Begin, commit, rollback y SET son control transaccional. El requisito de
   acceso mediante SP cubre datos, salud, auditoria y tareas internas. Esto no
   acredita ausencia de todo texto SQL en el protocolo del driver.
8. Mantener jobs deshabilitados por defecto en el root SQL. Scheduler y correo
   se habilitan expresamente en un corte posterior con validacion sintetica.

## Secuencia y gates

| Corte | Resultado |
| --- | --- |
| A53 | ready en MonitorStore e indicador explicito sin bean/config; cuatro rutas. |
| Infraestructura | Propiedades validadas, probe SP, manager/executor y factories de stores fuera del scan. |
| Identidad y seguridad | Access, Identity, lifecycle, browser, support y cadena SQL con cookies/CSRF preservados. |
| Negocio y portal | Factories completas y pruebas de rutas sin Sql. |
| Root y setup | Activacion expresa despues del grafo completo; runtime separado de setup y jobs. |
| Jobs y perfil QA | Opt-in desactivado, sender sintetico, perfil sin secretos y grafo completo. |
| JDBC real | Grants negativos, transacciones, conexion compartida, reset, eviction, rollback y concurrencia. |
| HTTP y visual | Flujos reales de identidad, tenant, portal y SaaS; escritorio, movil y capturas despues de JDBC. |

A53-A58 estan aceptadas, con verify independiente hasta 982/982.
A58 incorpora la raiz SQL y guardas de modo, con pruebas de contexto
sin servidor ni conexion. El launcher actual conserva su ruta heredada;
los siguientes cortes
requieren un encargo concreto antes de editar. La activacion exige el grafo
completo y su evidencia; estos cortes no habilitan protocolos clinicos.

## Evidencia y limites

A52 no edito archivos ni ejecuto tests, build, conexiones o servicios. Reporto
149 SHA intactos. El supervisor comparo esas rutas: solo queda la diferencia
de newline A38 conocida, sin diferencia de contenido.

El supervisor contrasto fuentes de root, runner y seguridad; inspecciono el
bytecode del driver y la API HealthIndicator; conto los stores. No ejecuto el
grafo futuro, pool, permisos ni protocolo de red.

A51 verify independiente 922/922 y JAR aprobado siguen como baseline anterior.
SQL-01 permanece EN_CURSO: wiring, JDBC, grants, HTTP y validacion visual real
siguen pendientes.

## Bloqueo historico de A58, resuelto el 2026-11-05

A58 sigue en correccion y no esta integrada. El programador alcanzo su limite de
uso; la pantalla indica recuperacion a las 15:31. Su segundo verify dejo 982
pruebas, un fallo y cero errores u omisiones.

El fallo es una asercion que rechaza cualquier nombre de bean con "scheduled".
Un diagnostico independiente encontro la configuracion de observacion de Boot,
con cero ScheduledAnnotationBeanPostProcessor, cero TaskScheduler y pool apagado.
El driver estuvo simulado y no recibio getConnection. Esto localiza el fallo de
la prueba; no reemplaza la verificacion final pendiente.

La instruccion R-A58-SCHED-ASSERT quedo en la misma Task/Dispatch mediante
msg_d21e5a0d8674. A57 conserva el ultimo codigo aceptado. No se integro codigo
incompleto ni se cambio de cuenta, sesion o trabajador.


SQL-01.A58 aceptada, 2026-11-05. Informes msg_cdf0324432e5 y cierre
msg_960065124930, task_29bfb2dd6f0e / ctx_beb186f7d50e. Correccion de la
asercion de scheduling y bloqueo de cuota resueltos con la cuenta y sesion
originales. Cuatro SHA coinciden con la entrega; 165 rutas protegidas comparadas,
solo EOF A38 conocido sin diferencia semantica. Revision personal del root,
guardas y suites; snapshot independiente tmp/sqlserver-a58-review desde HEAD.
JDK21 mvnw -B -ntp verify: 982 pruebas, cero fallos/errores/omisiones,
BUILD SUCCESS, JAR/repackage PASS, 50.987 s. Log verify-supervisor-a58.log.
Root explicito fuera del scan, 18 controladores, AOP y un solo grafo SQL;
excluye inicializacion/Flyway/datasource automatico/correo y no habilita jobs.
Guardas fallan antes de construir el pool. Driver y manager de prueba simulados:
no conexion JDBC, servidor HTTP, grants, concurrencia o capturas nuevas.
Launcher actual sigue heredado; SQL-01 EN_CURSO. Siguen pendientes seleccion
del root/perfil QA, setup separado y validacion real JDBC/HTTP/visual.


A59 preparada segun D-67: launcher/selector posterior a ConfigData/perfil QA y
una suite, ownership cuatro rutas de tmp/sql-01-a59-spec.md. Sin arranque real,
setup, JDBC o HTTP. Dependencia A58 aceptada; pendiente Dispatch.


SQL-01.A59 aceptada, 2026-11-05. Informe msg_d58995381183 y cierre
msg_962eefb0267b, task_9023895f0ad8 / ctx_5b618a21611b. Cuatro SHA confirmados;
169 rutas protegidas conservadas, solo EOF A38 ya conocido. Revision personal
main/selector/perfil/suite: una sola raiz seleccionada por Environment tras
ConfigData, fuentes externas rechazadas, guard A58 reutilizado; Flyway fuera del
launcher y switches de setup rechazados antes de construir Spring. QA exige
credenciales externas, loopback y jobs apagados. Snapshot independiente
 tmp/sqlserver-a59-review: JDK21 mvnw -B -ntp verify, 990 pruebas, cero
fallos/errores/omisiones, BUILD SUCCESS, JAR/repackage PASS, 52.847 s.
Log verify-supervisor-a59.log. Primer fallo worker era nombre de PropertySource
sintetico incorrecto; se corrigio fixture sin relajar producto.
Estas pruebas cargan YAML y eventos preparados; NO validan ConfigData end-to-end,
arranque, JDBC o HTTP real. Sin nuevas capturas. SQL-01 EN_CURSO: setup separado,
runner sintetico, transporte JDBC y QA real/visual siguen pendientes. El motor
local compartido tiene transporte TCP/NP deshabilitado segun evidencia historica;
no se habilita ni reinicia automaticamente para superar ese limite.


A60 preparada D-68/tmp/sql-01-a60-spec.md: QA de JAR/ConfigData/HTTP reales
con DB deliberadamente inaccesible; sin rutas versionadas asignadas. Separar
esta evidencia negativa de integracion JDBC positiva. Dependencia A59 aceptada.


SQL-01.A60 ACEPTADA para QA HTTP negativa, 2026-11-05. Correccion entregada
msg_ced2b9913463 y cierre succeeded msg_ccb16861a3c1, task_7744886e8fdf /
ctx_7042ff8c30a7. Supervisor comprobo SHA y diff unico de asercion autorizada,
original FAIL archivado intacto y173 rutas protegidas (solo EOF A38 conocido).
Ejecucion independiente python tmp/sqlserver-a60-review/harness.py con JAR del
snapshot independiente A59: rawexit0,47/47 checks,53.890s. Solo se adapto ruta
JAR del harness; producto sin cambios. JAR supervisor SHA
b13d12a8308b6fc31d2644c9c0e00c7af70edebb3c0e9c4a0a8e97cc7cf39b10.
HTTP real: liveness200UP antes/despues de DB fallida, readiness503DOWN,
health503DOWN con nombres de grupos sin componentes/detalles, public/status500
DATABASE_ERROR saneado con requestId y no-store. Cuatro arranques inseguros
rechazados. Cinco procesos propios cerrados y sin listeners, puertoDB reservado
sin escucha y cerrado. Canary ausente. Evidencia/logs en tmp/sqlserver-a60-review.
Esto valida ConfigData, proceso y HTTP con destino SQL INACCESIBLE, no JDBC
exitoso, login/tenant, grants, negocio, migraciones ni UI; sin capturas nuevas.
Preflight supervisor de solo lectura confirmado hoy: MSSQLSERVER running,
TCPEnabled0, NpEnabled0, IsIntegratedSecurityOnly1. Base QA marcada conserva
133 SP. No se cambio servicio/autenticacion/configuracion/credenciales ni datos.
Proximo corte prepara preflight reproducible que falle cerrado ante estos
bloqueos; setup separado y entorno JDBC positivo aun pendientes.


A61 preparada segun D-69/tmp/sql-01-a61-spec.md: preflight reproducible local
solo lectura, dos rutas script/suite. ExitBLOCKED esperado por transporte/auth;
no valida JDBC, no realiza setup ni altera instancia compartida.


SQL-01.A61 ACEPTADA e integrada, 2026-11-05. Informe msg_af22b707777b y cierre
msg_f6e0ad8e207b task_260b01935c63 / ctx_2b5e8fd35eee. Dos SHA confirmados;
revision personal script/suite y173 rutas protegidas (solo EOF A38 conocido).
Snapshot independiente tmp/sqlserver-a61-review desde HEAD mas dos archivos:
python -B -m unittest discover -s scripts/tests -v,36/36 PASS en3.392s.
Primera invocacion del supervisor apunto al arbol base y ejecuto solo23tests
existentes (PASS15.398s); se corrigio el directorio y se ejecuto la suite completa
36 en snapshot. Ambos logs conservados, sin afirmar cobertura nueva con23.
CLI independiente de solo lectura: rawexit2 BLOCKED esperado,0.390s,stderr vacio;
scope exacto validado,37 tablas/133SP,compat160 ySQL2022 16.0.1000.6. Cuatro
bloqueos: TCPEnabled0, WindowsOnly1 incompatible con authruntime actual, roles
hp_runtime_executor y hp_bootstrap_executor ausentes. jdbc_positive_validated
false. Evidencia preflight-supervisor.json/run.json ylogs en snapshot.
Script no modifica SQL/registro/servicios/autenticacion/credenciales. Primer
ERRORworker porflagsSQLcmd incompatible preservado, correccion autorizada por
msg_4327632c0100; ejecucion final BLOCKED no se presenta como JDBC positivo.
Sin nuevas pruebas Java/frontend/HTTP/capturas por este cambio de herramienta.
Siguiente trabajo independiente: preparar instalacion de permisos V8 existente
SOLO en QA marcada con ensayo transaccional/rollback antes de aplicar. No
habilitar transporte/autenticacion compartidos; entornoJDBC positivo sigue abierto.


A62 preparada D-70/tmp/sql-01-a62-spec.md: setup permisosQA V8 inmutable,
script/suite nuevos; worker plan y ensayo conrollbackunicamente. Aplicacion
persistente solo tras review/ensayoindependiente del supervisor. No TCP/auth/JDBC.


SQL-01.A62 ACEPTADA para herramienta y ensayo, 2026-11-05. Informe
msg_042c08b34cb0 y cierre msg_899e1fa940d3,task_f1a61e6514e6/ctx_03dc4aa58e11.
Revision personal completa dosarchivos; SHA8419F0EC...35FDB1B9 yBF1F2E1D...DDB8B63F
confirmados.175protegidos comparados,soloEOF A38 conocido. Snapshotindependiente
tmp/sqlserver-a62-review: suite59/59PASS4.375s,planreal0en0.891s yrehearse0en3.594s.
TresSQLcmd0,estados0/0->1/1->0/0, before==after COMPLETO,protected9partes iguales,
rolesafter[] yACLafter0; fingerprint4E678570F62D8ABDC7EE76385D0681A80372BC7F77E0C434CC8789C9B90BC557
intacto. Snapshotinside562ACL comparado independientemente contra matriz literal
A7aprobada:562/562EXACT,checksum26750101C4E5390E38FF8B0A748601A886EF9D8E9897E6A3EFA5C45E8F36B870.
Bootstrap CREATEcanonico ambosSHA coinciden diagnostico;rawV8/bodiesALTER inmutables.
Historicos3erroresplan/4erroresensayo se conservan, no convertidos retroactivamente.
No nuevaspruebasMaven/frontend/HTTP/capturas; codigoJava baseline990 anterior.
Herramienta permite applyexplicito solo tras guards/postconditions; supervisor
procede segunD-70 a setup persistente SOLOQA marcada, con nueva comprobacion.
Esta aceptacion del ensayo aun NOafirma applyreal ni JDBCpositivo/login/negocio/UI.
