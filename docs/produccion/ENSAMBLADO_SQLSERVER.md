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

A53-A57 estan aceptadas, con verify independiente hasta 973/973.
A58 tiene ownership para la raiz SQL y guardas de modo, con pruebas de contexto
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
