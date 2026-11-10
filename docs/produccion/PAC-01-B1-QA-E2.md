# PAC-01.B1.QA.E2: matriz real con verificador R2

Encargo supervisor 2026-11-10; usuario reitera terminar pendientes tras levantar
Docker. El Compose heredado usa MySQL, no es el destino de esta prueba. QA SQL
Server existente arrancada por Start-only elevado aceptado por Windows; no TLS.
Contrato E2 sustituye los pins/cwd de E1, cuyo intento0/40 sigue fallido historico.

Leer AGENTS.md absoluto del supervisor D:/Mavric/Health Project y contratos
PAC-01-B1.md, PAC-01-B1-R2.md, PAC-01-B1-QA-E1.md y este E2. Supervisor unico
escritor docs/tablero. Programador recuperapiura@gmail.com retenido
term_7286bcc6-6224-4d5f-a389-b06a09939ca3, mismo worktree/sesion --no-daemon.
Usar tus nuevos Task/Dispatch del preambulo, no los historicos E1/R2.

## Ownership y fuentes congeladas

NINGUNA fuente para editar. Ejecucion QA y reportes/harness nuevos SOLO TEMP
con prefijo B1E2; no modificar fuentes, docs, snapshots, artefactos anteriores,
ramas, cuentas, Docker, servicios, certificados, DPAPI ni secretos.

Cwd de ejecucion del controlador EXACTO:
D:/Mavric/Health Project/tmp/pac-01-b1-20261110/r2-review

Entradas bajo ese directorio, verificar ambos SHA antes/despues:

- backend/scripts/verify-sqlserver-patient-links-read.sql:
  8BCAF401111C311297B4E75331DE3E1BC48716029D87D5E5667E2CAAB94B3A61.
- backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql:
  CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060.

## Entorno actual comprobado

HEALTHPROJECTQA Running/Manual PID19056 observado, listener127.0.0.1:14335,
DAC solo loopback. SQLcmd administrativo LPC lpc:.\HEALTHPROJECTQA / Windows
Integrated, CONTROL separado del runtime/bootstrap. No TCP Windows/SSPI fallback.
Base health_project_sqlserver_qa_isolated_20261105, marcador exacto de COMMON.
Wrapper de arranque conservado en tmp/pac-01-b1-20261110/environment-attempt2;
huella protegida antes/despues identica
a04d8236d807b3527dce32d8c8168e2e691902c89c0dd3eb79dda933ae8ca2af.

Supervisor ya ejecuto UN probe readonly del COMMON corregido+baseline: rawExit0,
stderr0, installed0,roleACL562,optionalhistory0, modoOPEN. Respuesta y hashes
en environment-attempt2/supervisor-baseline.json; no fixtures ni compilacionV13.
No repetir otro probe previo. Tu controlador obtiene sus propios baselines.
No servicios/APIs/browser concurrentes contra SQL QA durante la matriz. Los
contenedores MySQL levantados por el usuario permanecen ajenos a este test.

## Ejecucion autorizada

UNA ejecucion PRE_APLICACION del B1_RUNNER extraido EXACTAMENTE del verificador
R2 con UTF8 desde Python, cwd snapshot anterior. NO ejecutar SQL entero ni
AUTOCOMMIT_POST_APLICACION. No copiar fuentes a producto ni activar Java/frontend.
Se autoriza adaptar en TEMP el harness pasivo E1 preservado para usar nuevo
cwd,pins,Task/Dispatch y prefijo B1E2; no cambiar logica ni respuesta del runner.
Ledger previo creado exclusivamente, sin overwrite/retry; capturar exit, fases,
baseline hashes y errores seguros del MISMO intento. OriginalE1 no se altera.

PRE permite solo sus40fases revisadas (5positivas/35negativas), V13/2ACL/usuarios
WITHOUT LOGIN/fixtures nuevas dentro de TX externas revertidas. No COMMIT,
instalacion persistente, logins, setupV1..V12 ni cambios de datos existentes.
Runtime del test impersonado al usuario restringido; no usar dbo como runtime.
Mismo delta562->564 dentroTX y vuelta562, mismos fingerprints antes/despues por
conexion nueva. Conservar25fixtures PACQA y otras filas/sesiones/auditoria previas.

Parar al primer fallo/drift/compilacion/guardas/framing o incertidumbre. No reintento,
correccion de codigo/SQL, compensacion/delete/reseed ni conexiones de diagnostico
posteriores. Capturar numeroMsg/Level/State/Line y exit del mismo intento; si hace
falta mensaje de engine, guardarlo solo local en TEMP del intento sin imprimir
SQL/filas/tokens/valores de negocio en chat. No cambiar filtros o aceptar errores
distintos para conseguir PASS. El cierre de conexion es la frontera de rollback
para transacciones doomed; respetar validacion3998 del runner sin relajarla.

## Entrega

Informe TEMP B1E2 con inputSHA, cwd/invocacion/start/end/exit, fases reales
terminadas y pendientes, hashes antes/despues, estado final y limites. Comparar
672fuentes conocidas antes/despues sin cambios; no repetir suites Java/Next/demo.
55lecturas esperadas solo si pasan5positivas con11casos cada una. No presentar
modoOPEN como pruebaREAD_ONLY. POST/autocommit queda pendiente de instalacion
supervisada posterior; este paquete no la autoriza.

Si40fasesPASS, succeeded EN_REVISION; si falla, failed con evidencia y0retries.
Procesar/ack todos los lotes disponibles y enviar worker_done con resultado real
y report-path. EN_REVISION no requiere aprobacion previa para enviar done.
Conservar terminal/sesion. Sin commit/push/main/FactuEz/cuentas globales ni shutdown.
