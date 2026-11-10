# PAC-01.B1.R3: dbo legitimo SQL o Windows, sin cambiar propietario

Encargo supervisor2026-11-10. E2 task_091da7344237/ctx_622d6efdec77 failed0/40
en precondiciondbo deV13. Tresbaselines exactos y V13ausente/ACL562; no reintentar
esa fuente. TLSlocalA69 acaba de validarse JDBC4checks/3conexiones/1SPhealth,
con erroresCA/hostname rechazados y baselineposterior igual a E2preTLS. Sin
mas ApplyTLS/restart o cambios globales. Siguiente dependencia es corregir V13.

Leer AGENTS.md absoluto/flujo/TAREAS/DECISIONES D-87.H/K y contrato B1/R2/E2.
Programador recuperapiura en terminal/sesion/worktree retenidos --no-daemon;
coordinador mendozadeafabisa, mismo Run. Usar nuevos Task/Dispatch del preambulo.
Supervisor unico escritor documentos/tablero/revision/evidencia final.

## Evidencia independiente de la causa

tmp/pac-01-b1-20261110/e2-review/owner-sid-diagnostic.json:
principal_id1,name'dbo',typeU,authentication_type3(WINDOWS),schemaOwner1,
ownerSidMatches=true contra sys.databases.owner_sid deDB_ID().
La propuesta exigia typeS aun cuando el contrato solo requiere propietario dbo
correcto. SQLServer puede tener propietario Windows legitimo; NO ALTER AUTHORIZATION
ni convertir dbo/login ni reducir guardas para acomodar la prueba.

## Ownership exclusivo (dos rutas worker)

- backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql
  SHA previo CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060.
- backend/scripts/verify-sqlserver-patient-links-read.sql
  SHA previo 8BCAF401111C311297B4E75331DE3E1BC48716029D87D5E5667E2CAAB94B3A61.

Ninguna ruta mas. Baseline actual675fuentes incluye integracionTLSsupervisora;
conservarla y todo trabajo previo en amboscheckouts. V13 aun no aplicada, por eso
se permite corregir propuesta; V1..V12 aplicadas NUNCA se modifican/reaplican.

## Correccion concreta

Cambiar SOLO la precondicion de ownershipdbo de la migracion. Exigir dbo schema
con principal_id=1, dbo principal name exacto yprincipal_id=1, SID igual al
owner_sid REAL de la misma DB_ID(), y par tipo/autenticacion permitido:
typeS/authentication_type1(INSTANCE) O typeU/authentication_type3(WINDOWS).
No aceptar cualquier principal/tipo/G/NULL, usuario contenido ni schemaowner
distinto; metadataausente oincoherente falla cerrada antes deDDL.

Conservar transaccionEXTERNAcommittable,CONTROL separado, exclusiones roles,
rolowners/helpers/objetoinexistente y orden de guardas previos a CREATE.
El cuerpoSP y lasDOSACL deben permanecer BYTE-equivalentes, sin nuevas salidas,
guardas privadas o privilegios. En el verificador, cambiar SOLO constante
MIGRATION_SHA256 al nuevohash correcto (y comentario directamente obsoleto si
inevitable, explicarlo). No cambiar40fases,errores/pinsrestantes/fixtures/roles,
framing,baselines,COMMON/PRE/POST,capturasR2,controlador/transport a conveniencia.

## Validacion acotada

Diff que demuestre cuerpoSP/ACL sin cambios y verificador solo pin, AST Python
valido y40fases intactas; regresion enfocada de guardas que rechace quitar
schemaowner1,principal1,name/tipo/auth/SIDmatch, y admita losdos pares permitidos.
Harnesstests/reportes nuevos SOLO TEMP prefijo B1R3, no tercera ruta producto.

Se autoriza UN probe REAL de preflight en la QA actual, sin DDL/DML:
extraer SOLO primerbatch de V13 antes delprimerGO (precondiciones), comprobar
que NO contiene CREATE/ALTER/DROP/GRANT/DENY/INSERT/UPDATE/DELETE/EXEC de negocio,
envolverlo en BEGINTRAN externo y ROLLBACK, mismo SQLcmdLPC WindowsIntegrated
restringido a instancia/base/marcador de COMMONR2. Guardas0/0 capturadasantesde
metadata; finalcaptura1/1 antesROLLBACK y0/0 despues. Salidaunica JSONseguro de
preflightPASS, sin SELECT de tablas de negocio, fixtures, nuevosprincipales o
SQLautenticacion. No volver a ejecutar si falla. Este probe prueba SOLO ownership
y precondiciones, NO compila SP ni satisface matriz40fases.

Prohibido ejecutar PRE/APLICACION/POST delrunner completo, CREATEPROCEDURE o
instalarV13/ACL; siguiente gate requiere reviewindependiente y otroencargo.
No usar SQLcmdTCP-E/SSPI, contrasenas/DPAPI/API/servicios/Docker/TLS. No suites
Java/Next/demo. No alterar owner real para probar negativos; negativos mediante
lectura/modelos/variantes de predicado sin cambiar catalogo y etiquetados offline.

## Entrega

Informe TEMP B1R3-programmer-report.json con dosSHA nuevos/diff,baselinehashes,
regresiones y UNprobe preflightreadonly/rollback-only: SQLinvocations/exit/pines,
resultado/limites e historial. Si exito, succeeded EN_REVISION,SP_NO_COMPILADO,
MATRIZ_NO_EJECUTADA. Si falla, failed y consulta sin reintentos/correcciones extra.
Procesar/ack lotes antes de worker_done, conservar terminal/sesion.
Sin docs/commit/push/main/FactuEz/cuentas globales/compras ni shutdown.
