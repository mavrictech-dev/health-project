# PAC-01.B2: lectura de vinculos en Java/API

Encargo del arquitecto, 2026-11-10. Continuacion autorizada del mismo Run
run_624b9269b491. B1 SQL esta aceptada localmente: PRE40/40 (55 lecturas,
35 negativas), instalacion supervisada V13 una vez y POST autocommit51000,
sin deriva de datos/permisos. Ver PACIENTES_VINCULOS_SQL_20261110.json y D-87.Q.
No repetir esas ejecuciones. La entrega B2 es implementacion y QA OFFLINE;
HTTP/SQL/visual reales se delegaran despues de revision independiente.

Programador recuperapiura@gmail.com, terminal retenida
term_7286bcc6-6224-4d5f-a389-b06a09939ca3, sesion
01a1c5c7-d534-7d01-ac3a-c18bf31075ec, worktree
C:/Users/maxmo/orca/workspaces/Health Project/health-programmer, --no-daemon.
Usar los nuevos Task/Dispatch del preambulo. Leer expresamente AGENTS.md del
supervisor D:/Mavric/Health Project y docs/agent-workflow.md, TAREAS.md y este
contrato. Verificar raiz/rama/worktree/estado y preservar todos los cambios
historicos. Supervisor unico escritor de documentos/tablero y aprobacion.

## Ownership exclusivo: ocho rutas

Prefijo backend/src/; solo estas siete existentes y una nueva:

- main/java/com/mavric/health/patients/api/PatientController.java
- main/java/com/mavric/health/patients/application/PatientService.java
- main/java/com/mavric/health/persistence/sqlserver/SqlServerPatientStore.java
- main/java/com/mavric/health/persistence/sqlserver/SqlServerProcedure.java
- test/java/com/mavric/health/patients/application/PatientServiceSqlServerTest.java
- test/java/com/mavric/health/persistence/sqlserver/SqlServerPatientStoreTest.java
- test/java/com/mavric/health/persistence/sqlserver/SqlServerProcedureContractTest.java
- test/java/com/mavric/health/patients/api/PatientLinksControllerSqlServerTest.java (nueva)

Baseline supervisor en tmp/pac-01-b1-20261110/b2-input-baseline.json: seis
existentes identicas byte a byte entre ambos worktrees; PatientController solo
difiere por LF/CRLF (mismo texto); nueva ausente en ambos. No copiar checkout,
resetear, hacer checkout de otra rama o sustituir cambios ajenos. Capturar SHA
reales propios antes/despues. La normalizacion de newline solo explica el diff,
no tolera pins de ejecucion. Si hacen falta otras rutas, preguntar por Orca y
terminar turno antes de ampliarlas.

## Comportamiento y contrato

GET /api/patients/{id}/links?limit=50&offset=0 devuelve un array JSON, incluido
[] sin vinculos o al paginar fuera del resultado. Defaults50/0; limit se limita
a1..200 y offset minimo0. No total inventado, busqueda global ni escritura.
Cada fila contiene SOLO tenantId,patientId,userId,userName,relationship,active,
scopes. active indica estado del vinculo, no de la cuenta/membresia. Conservar
vinculos historicos inactivos y orden entregado por SQL (collation de SQL, no
ordenacion Java). Sin email, hashes, tokens, datos clinicos o campos adicionales.

Acceso administrativo tenant ADM o REC, rechazando SAD/SOP, tenantnull y PAC/RES
incluso mezclados con ADM/REC. Actor Access debe coincidir con request y host;
contexto REQUEST con IDs canonicos/tokenhash valido. Aplicar tambien defensa en
store para sus llamadores directos. La autoridad final de usuario/sesion/
membresia sigue siendo el SP, no los roles declarados por Java. Lectura permitida
en SUSPENDED/sin PORTAL y sin access.write/guardas de escritura. No alterar los
permisos ni comportamiento de PUT links, list/get/save/history existentes.

Servicio nuevo solo SQL Server: si no hay store, fallar cerrado DATABASE_ERROR
500 saneado sin usar Sql, MySQL, consultas directas ni fallback. Reutilizar
validacion de request/contexto existente sin cambiar silenciosamente otros
endpoints. ID del paciente canonico antes de ejecutar, errores400/401/403/404/
409/500 mediante mecanismos actuales y mapeoSqlServerErrors. Ausente/ajeno
conservan el mismo404 del SP; no preconsultar GET para diferenciarlos.

Descriptor tipado PATIENT_LINKS_LIST: {call dbo.usp_patient_links_list(?,?,?)};
patient_id CHAR36 sin default, limit INTEGER defaultLiteral50, offset INTEGER
defaultLiteral0. RUNTIME, nunca BOOTSTRAP. No SQL dinamico o cambios al Executor.
Store abre/participa transaccion mediante TransactionTemplate/within existente;
exactamente UNA llamada de negocio a ese descriptor, sin GET previo, llamada de
auditoria adicional, branches o SP de guardas desde Java. SP audita dentro de
la misma transaccion. Commit/rollback/mapeo de fallos permanecen existentes.

Validar resultado fail-closed: una resultset exacta incluso vacia, filas <=limit,
tenant/patient coincidentes, userId canonico y no duplicado dentro de la pagina,
userName String no null <=160 y relationship String no null <=80. No introducir
rechazos de historicos por texto vacio. active Boolean estricto. scopes ya sale
de SqlServerExecutor como List; validar que todos son String y devolver copia
inmutable. Admitir [] y preservar valores desconocidos, duplicados y orden de
scopes historicos: la lectura no concede acceso ni revalida derechos de escritura.
No objetos/scalars/nulls en scopes, no convertirlos a String. Proyectar solo las
siete claves explicitas; filas/lista/scopes defensivos e inmutables. Ausencias,
tipos invalidos, contaminacion entre tenant/paciente o resultsets extra fallan
DATABASE_ERROR500 saneado y rollback. No mutar el resultado del Executor.

El test de contratos debe conservar la validacion exacta historica de V3..V6 y
V8 (133 SP,107runtime,2bootstrap,24private). Anadir V13 como delta explicito:
un solo SP nuevo, firma parseada desde recurso SQL inmutable y GRANT EXECUTE
runtime/DENY bootstrap solo sobre ese objeto. Catalogo publico tipado pasa de
108 a109. No editar migraciones ni debilitar el parser/allowlist para hacerlo pasar.

## Pruebas y entrega

Pruebas significativas de store/servicio/controller y contrato: defaults/clamps/
offset, [] y varios vinculos activos/inactivos, HUMAN/ANIMAL, SUSPENDED/sinPORTAL,
scopes historicos, array/seven-field projection/noemail, tipos/datos contaminados,
roles permitidos/denegados y mezclados, desajuste host/actor, UUID invalido,
401 y errores deSP/commit, transaccion/singleSP/noextraGET/audit/legacy. Probar
enrutamiento HTTP con MockMvc standalone sin socket/Boot y parametros invalidos;
puede usar Errors existente. Los mocks/modelos no son prueba de SQL/HTTP real.

Ejecutar primero las cuatro suites afectadas y despues Maven verify completo
con JDK21; capturar comandos, rawexit y conteos Surefire/fails/errors/skipped sin
llamar servicios reales. No volver a ejecutar suites frontend/demo sin cambios.
Si falla una prueba, corregir dentro del ownership, conservar fallo inicial y
reportar resultado final veraz; fuera de scope consultar. No ampliar a otros
modulos/tests porque un conteo/contrato presuponga108: informar ese bloqueo.

Informe TEMP B2-programmer-report.json con IDs, fuentes previas/finales y SHA,
diffs por ocho rutas, lista exacta de ediciones, pruebas/resultados/limites y
artefactos con SHA. No secretos. Producto supervisor permanece sin editar hasta
revision; no servicios/SQL/HTTP/DPAPI/TLS/UAC/restart/certificados/Docker, fixtures,
migraciones/grants/dependencias/configuracion/frontend/docs/commit/push/main,
FactuEz/cuentasglobales/gastos/datos reales/shutdown. Consultar y ackear los lotes
disponibles de Orca antes de worker_done. succeeded significa EN_REVISION, no
aceptacion funcional. Mantener terminal y sesion retenidas.
