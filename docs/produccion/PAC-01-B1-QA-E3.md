# PAC-01.B1.QA.E3: matriz SQL real tras R3 aceptada

Encargo supervisor2026-11-10, mismo Run run_624b9269b491, misma pareja y terminal
retenida del programador recuperapiura. Leer AGENTS.md absoluto/flujo y contratos
B1/E2/R3 desde D:/Mavric/Health Project. Usar nuevos Task/Dispatch del preambulo.
Supervisor unico escritor docs/tablero/aceptacion. E1/E2 fallidos se conservan;
este gate no los transforma enPASS ni reutiliza sus artefactos/fixtures.

R3 aceptada SOLO preflight:675SHA/18artefactos contrastados,2deltas autorizados,
SP/ACL byte-identicos yverificador solo pin; regresionindependiente2pares/40casos
negativos/14variantes offlinePASS. UNprobe real de primerbatchmetadataONLY con
0/0->1/1->ROLLBACK0/0PASS, sin compilacionSP ni matriz. Fallo LF/CRLF anterior fue
antesSQL, pinTEMPcorregido tras aprobacion expresa y guardado en historial.

## Ownership/entradas

NINGUNA fuente para editar. Ejecutar solo codigo revisado del snapshot supervisor:
cwd D:/Mavric/Health Project/tmp/pac-01-b1-20261110/r3-review

- backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql:
  667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51.
- backend/scripts/verify-sqlserver-patient-links-read.sql:
  38F432F122437206669749F82BF6B364757B3A6BE2782FFEAE1E2A9F6090344B.

Verificar bytesSHA reales antes/despues, sin normalizar pins ni regenerar fuentes.
675fuentes conocidas preservadas. Reporte/harness/ledger nuevos SOLO TEMP B1E3;
no modificar snapshot,fuentes,docs o artefactos previos. Se permite adaptar harness
pasivoE2 SOLO cwd/pins/IDs/prefijo; no cambiar controlador o respuestas SQL.
UTF8 desde archivoPython, sin recodificacion de literales por PowerShellstdin.

## Entorno y autorizacion

QAHEALTHPROJECTQA Running/Manual, ordinaryloopback14335; transporte SQLcmdLPC
WindowsIntegrated lpc:.\HEALTHPROJECTQA con principalCONTROL separado, sin SQL
password/DPAPI. Runtime en test SOLO usuarios temporales restringidos WITHOUTLOGIN
dentroTX. Base exacta health_project_sqlserver_qa_isolated_20261105 y marcadorCOMMON.

TLSlocalQA validada previamente,ForceEncryption1,CAprivada/My y truststoreJVM
exclusivo. No repetirJDBC/TLS ni Apply/reissue/restart/servicios. LPC de esta
matriz no se presenta como pruebaTLS. Huella protegida vigente a04d8236...ae8ca2af.
Supervisor comprobacionreadonlyantesE3: baselineigual al postTLSQA y E2previo,
V13ausente/562ACL/history0/modeOPEN; no nuevas consultas o sondas previas.
Archivo r3-independent/before-matrix-baseline.json. QA exclusiva, sin HTTP/browser,
backend SQLruntime/otrosfixtures o traficoSQL concurrentes del supervisor.

Autoriza UNA invocacion del main B1_RUNNER extraido EXACTAMENTE, PRE_APLICACION.
Extraer bloque con marcadores ANCLADOS a inicio de linea, no al ejemplo delheader.
No rawwholeSQL, AUTOCOMMIT_POST_APLICACION, instalacionpersistente ni COMMIT.
Sus40fases revisadas crean V13/2ACL y fixtures SOLO enTXexterna revertida; cuenta
runtime no heredaCONTROL. Nada de setupV1..V12, cambiosowner/principalesexistentes,
reseed o borradoscompensatorios. Conservar25PACQA y todas las filas anteriores.

Matriz:5positivas con11lecturas cada una (55solo si pasan),35negativas reales,
auditoria1porread, paginas/orden/topes/scopes yaislamiento. ACL562->564 temporal,
vuelta562 y fingerprints antes/despues de cada fase en conexiones nuevas. Mismo
patron3998 estricto/rawexit si doomed, sin aceptar errores arbitrarios o truncado.
ModoOPEN observado no es prueba READ_ONLY.

## Ante errores

STOPprimerfallo/deriva/guardas/framing/compilacion/timeout. Sin cambios o reintentos,
sin mas conexionesdiagnostico por worker. Capturar diagnosticosseguros del MISMO
intento mediante observerpasivo,stdout/stderr guardado SOLO TEMP sin divulgar
filas/password/tokens/SQL sensible. No alterar devoluciones del runner, baselines,
filtros o expectederrors para forzarPASS. Si no0, failed con fases que realmente
pasaron, error y evidencia de rollback/fingerprint o incertidumbre. No fabricar
checks completados por compilacion/projection/ACL.

Si40PASS, succeeded EN_REVISION con reporte TEMP B1E3-programmer-report.json,
start/end/exit/result/pins/675SHA/baselines/cantidades y limites. InstalacionV13,
POST/autocommit, API/Java/frontend siguen gates posteriores. Procesar/ack todos
los lotes disponibles y worker_done real sin esperar aceptacion previa. Conservar
terminal/sesion; sin commit/push/main/FactuEz/cuentas/gastos ni shutdown.
