# Health Project: avances y pendientes

Corte: 6 de noviembre de 2026. Rama de entrega: `health/production-wave0` en
[GitHub](https://github.com/mavrictech-dev/health-project/tree/health/production-wave0).
El proyecto sigue en desarrollo y QA local; no está aprobado para producción.

## Lo que tenemos

| Área | Estado comprobado |
| --- | --- |
| Arquitectura y coordinación | Tablero por dependencias, decisiones, revisión y evidencias en `docs/produccion`. Orquestación mediante Orca con worktrees separados. |
| Roles | Arquitecto/supervisor: `recuperapiura@gmail.com`. Programador: `mendozadeafabisa@gmail.com`. Identidades verificadas en los últimos dispatch; sin cambios globales de cuenta. |
| Frontend | Demo independiente y primeras entregas live de acceso, SaaS y organización incorporadas. La validación anterior de esas pantallas incluye API interceptada; falta su aceptación completa con SQL Server real. |
| Backend SQL Server | Esquema, procedimientos, adaptadores y consumidores Java incorporados. Raíz runtime explícita y perfil `sqlserver-qa`, con DataSource, transacciones y llamadas a SP. Su activación es opt-in; el código heredado permanece en el repositorio. |
| Persistencia instalada | Instancia dedicada `HEALTHPROJECTQA`, SQL Server 2022 Developer, base sintética `health_project_sqlserver_qa_isolated_20261105`. Migraciones V1–V9 aplicadas y catálogo reconciliado: 37 tablas, 133 SP y 31 triggers habilitados. |
| Permisos | Matriz de 562 permisos comprobada. Logins runtime y bootstrap separados, cada uno con su rol aprobado; migrador separado. Pruebas reales rechazan acceso directo a tablas y DDL con los logins restringidos. |
| Credenciales locales | Almacén DPAPI CurrentUser fuera de Git. Las pruebas enviaron las contraseñas por memoria/stdin; no se publican sus valores ni el archivo cifrado. |
| Herramientas de setup | Configuración de instancia, preflight, permisos y aprovisionamiento de base versionados. A67 se incorpora como **trabajo en revisión**, con su defecto conocido y sin declarar su aprobación. |

No se copió información de pacientes ni datos de otros proyectos. La instancia
compartida y FactuEz quedaron fuera de las modificaciones.

## Pruebas y límites de la evidencia

| Evidencia | Fecha | Resultado y alcance |
| --- | --- | --- |
| Suite Java A59 y empaquetado | 5 nov. | 990/990 pruebas y JAR aprobados en snapshot independiente. Incluye fixtures y mocks; no acredita todos los recorridos reales. |
| Herramientas Python/PowerShell | 6 nov. | **123/123 PASS**, salida 0. Ejecutada sobre la copia que se sube. Incluye contratos, errores, cifrado simulado y comprobaciones locales de solo lectura; no ejecutó aprovisionamiento SQL. |
| JDBC real con Microsoft JDBC 13.4.0 | 5 nov. | **17/17 PASS**: autenticación TCP de ambos logins, identidad efectiva, SP permitidos, contexto y rechazos de lectura/escritura directa, DDL y procedimientos ajenos al rol. |
| Backend HTTP con SQL Server real | 5 nov. | **7/7 PASS**, sin mocks: liveness/readiness/salud `UP`, estado y contexto públicos, y `401` en dos rutas privadas sin sesión. |
| Build backend offline | 5 nov. | `mvn -o -DskipTests package`: aprobado. Este comando no volvió a ejecutar la suite Java. |
| Integridad posterior a HTTP | 5 nov. | Objetos, permisos, semillas y principales correctos. Único delta de filas: tres trazas sintéticas en `request_traces`. Usuarios, sesiones y tenants continuaban vacíos. |
| Visual reciente con backend real | Pendiente | No hay capturas de esta última fase SQL/JDBC/HTTP ni aceptación visual de recorridos autenticados. |

Las pruebas positivas JDBC/HTTP usaron `encrypt=true` y
`trustServerCertificate=true` **exclusivamente en QA local**. La cadena TLS no
está validada. Tampoco se ha probado todo el ciclo de vida del pool, concurrencia,
rollback de operaciones de negocio o persistencia de todos los módulos.

Las pruebas del 5 de noviembre no se presentan como repetidas en este corte.
Detalle: [evidencia estructurada](evidencias/SQLSERVER_QA_20261105.json) y
[fuentes exactas de los harnesses](evidencias/fuentes-qa-20261105/README.md).

## Defecto A67 y estado del programador

Los logins se instalaron y una lectura posterior confirmó el resultado. Sin
embargo, el comando de creación informó `SQLCMD_FAILED` porque `sqlcmd -r1`
envió a stderr los dos avisos informativos de cambio de base de `USE`.
Se conserva ese error histórico; la creación no se repitió.

Un diagnóstico de solo lectura comprobó que `-m 1` elimina esos avisos y sigue
propagando un error SQL sintético con salida distinta de cero. Falta incorporar
la corrección y su regresión al código. La herramienta y sus pruebas se suben
**sin modificar**, como trabajo en revisión:

- `scripts/provision-isolated-sqlserver-logins.py`
- `scripts/tests/test_isolated_sqlserver_logins.py`

Los verificadores de setup comparan un estado inicial de datos vacíos. Las tres
trazas sintéticas posteriores son un cambio esperado; no hay que borrarlas ni
repetir creación o migraciones para recuperar una huella histórica.

El último aviso de Codex indicó cuota agotada hasta el 11 de noviembre, 11:35.
La consulta Orca de este corte reportó el dispatch `ctx_b1a926031df9` como
`abandoned`, etapa `terminal_missing`, con liveness `unverifiable`: el terminal
asignado ya no está activo tras una recuperación de Orca. No se ha lanzado otro
agente, cambiado cuentas ni modificado ese estado. El informe final y el cierre
de aceptación de A67 siguen pendientes.

Run: `run_624b9269b491`. Task de A67: `task_e9b58257c00d`.

## Qué falta, por orden de dependencia

1. Corregir el reporte SQLcmd de A67, probarlo y cerrar/reconciliar su entrega en
   Orca; recuperar un trabajador autorizado sin alterar cuentas globales.
2. Completar QA JDBC del pool: reciclaje, limpieza de contexto tras fallos,
   transacciones, rollback, conflictos y concurrencia.
3. Preparar el bootstrap SAD sintético con su principal separado y probar login
   de aplicación, cookies, CSRF, expiración/revocación y aislamiento entre hosts.
4. Validar con backend real los recorridos SaaS y organización ya incorporados:
   planes, clientes, contratos, sedes, áreas, equipo, duplicados y cuotas.
5. Continuar por dependencias con pacientes, agenda, historia, documentos y
   portal. La existencia de SP/adaptadores no equivale a aceptación funcional.
6. Ejecutar Playwright con API real en escritorio y móvil: navegación,
   formularios, carga/error, capturas inspeccionadas, consola, red y overflow.
7. Validar la cadena TLS y completar los gates de seguridad, correo/adjuntos,
   backup/restauración, observabilidad, carga y operación exigidos por el plan.
8. Completar la aceptación profesional de lo clínico y las autorizaciones de
   piloto/producción. No se han autorizado datos o destinatarios reales ni gastos.

No hay base para dar un porcentaje global de finalización: el tablero conserva
entregas parciales y áreas todavía `POR_VERIFICAR`.

## Estado local y alcance de esta subida

Al comprobar este corte, `MSSQL$HEALTHPROJECTQA` estaba **Stopped / Manual**,
sin listener QA en 14335. El backend de prueba no estaba escuchando en 18080.
No se arrancó ni reconfiguró SQL para esta subida.

Se compararon 183 rutas cambiadas del worktree del programador: 180 ya coincidían
con la rama publicada al normalizar CRLF/LF, una difería solo en whitespace final
y las dos restantes eran A67. Se incorporaron estas dos últimas por su SHA256
revisado, conservando intacto el worktree del programador.

La subida incluye código, pruebas, documentación y evidencia seleccionada sin
secretos. Se excluyen `.env`, credenciales DPAPI, bases/archivos SQL de datos,
sesiones, logs, `tmp`, dependencias, instaladores y binarios generados.
Las migraciones y semillas SQL de código sí forman parte del repositorio.

Se conserva `main` en `0b24487c77055a081f6e76f0b18bc544ce4b1958`.
Esta entrega no implica merge en main, despliegue ni aprobación de producción.

Referencias de seguimiento: [tablero](TAREAS.md), [decisiones](DECISIONES.md),
[validación](VALIDACION.md) y [revisiones](REVISIONES.md).
