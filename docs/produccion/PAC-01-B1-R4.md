# PAC-01.B1.R4: sintaxis del verificador y protocolo sqlcmd

Encargo supervisor2026-11-10. E3 task_8dd7018f8dd2/ctx_60264a630817 failed0/40,
un intento,3baselinesidenticos, V13ausente/ACL562. stderr del MISMOintento:
Msg156 Level15 cerca de keyword'off' en declaracion y lectura de @cases.
SQLcmdraw0 con -V16 no fuePASS: el controlador rechazo OUTPUT_FRAME_INVALID.
Evidencia congelada tmp/pac-01-b1-20261110/e3-review. No repetir esa matriz.

Leer AGENTS.md absoluto/flujo/TAREAS/D-87.M/B1/E3. Misma cuenta recuperapiura,
worktree/terminal retenidos --no-daemon, supervisor mendozadeafabisa unico escritor
de docs/tablero. Mismo Run, nuevos Task/Dispatch del preambulo. TLSlocalQAvalidada
se conserva; sin Apply/reissue/restart ni traficoHTTP/JDBC extra.

## Ownership UNICA ruta

backend/scripts/verify-sqlserver-patient-links-read.sql
SHA previo38F432F122437206669749F82BF6B364757B3A6BE2782FFEAE1E2A9F6090344B.
MigracionV13 debe permanecer667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51.
No tocar SP/ACL/migraciones previas,helpers,docs,Java/frontend/config/credenciales.
675fuentes conocidas,unico delta autorizado. Harnesstests/reportes nuevos soloTEMP
B1R4. Preservar todos los artefactos/fallos y fuentes anteriores.

## Correcciones concretas y limitadas

1 Columna 'off' sin delimitar es keyword TSQL. Renombrar SOLO columna interna
de @cases a page_offset y referencia @off=page_offset. Conservar variable @off,
parametroSP@offset, valores11casos/paginacion/roles/auditoria y40fases exactos.

2 En invoke cambiar umbral sqlcmd -V16 a -V11 para que errores de sintaxis
severity15 no queden raw0. Conservar -b,:OnErrorExit,LPC-E,DB fija,minenv,-y0sin-h,
UTF8,framingestricto,shellfalse ytimeouts; no aceptar raw0 sinframe/stderrvacio.

3 Rama de validate_response para xact_state=-1 exige hoy raw1 sintetico, pero
protocolo REAL de sqlcmdinstalado devuelve16 para el UNICO Msg3998Level16.
Actualizar a exit16 EXACTO con el mismo regexestricto de3998 yframe de fase/error/
estado esperado. No aceptar cualquiernonzero, conjuntos amplios,stderr extra o
raw0. Ramas0/1 mantienenraw0/stderr0. Matriz de codigosnegativos no cambia.

Supervisor verifico esos hechos mediante DOS diagnosticos independientes sin
DDL/DML/filasnegocio ni reintentar matriz: querysintaxisconstante Msg102Level15
sale15 con-V11; BEGIN/THROWsintetico/CATCHframe en TX sin datos devuelveestado-1,
Msg3998unico/raw16 al rollbackautomaticofinbatch. No se llamanSPs de negocio ni
se creanfixtures. sqlcmdSHA7220B526AB97B0A5B30ED7B09C497AB7FAD39141090F8801D68691C38FF248DA,
e3-review/sqlcmd-error-protocol.json contiene salida exacta segura.

## Pruebas offline y sintaxis real sin ejecutar negocio

Regresiones enfocadas deben observar argvreal de invoke,modelo de frame por
validate_response y SQLgeneradoREAL (COMMON+PRE+V13). Demostrar que versiones
anterioresoff/-V16/raw1 fallan, que raw16+3998exacto yframecorrecto acepta, y que
raw0/raw1/otrosraw/3998extra/truncado/uotroMsg siempre rechaza. Conservar positivos,
675baseline,40fases,SPpin yfingerprints. No suitesJava/Next/demo ya aceptadas.

Se permiten SOLO DOS invocaciones reales en QA, sin ejecutar PRE/POST:

A) PARSEONLY de SQL generado para positive_adm completo con susGO originales.
ConexionSQLcmdLPC/DBfija con nuevosflags, comenzar con SET PARSEONLY ON;GO en
batchSEPARADO ANTES de cualquiercodigo generado. Mantener ON duranteTODOS los
batches, comprobar que la fuente no contiene otra ordenPARSEONLY ni ejecucion
SQLCMDexterna; finalizar en batchSEPARADO SET PARSEONLY OFF;GO y cerrarconexion.
Exigir raw0/stdoutvacio/stderrvacio. Este modo SOLO analiza sintaxis, no compila
ni ejecuta statements, no instalaSP/ACL/fixtures ni iniciaTX de negocio.
Fuente primaria: https://learn.microsoft.com/en-us/sql/t-sql/statements/set-parseonly-transact-sql

B) Probe del protocolo3998, conexionnueva: COMMONvalido0/0, BEGINTRAN,THROW51002
con mensajeSINTETICO fijo dentroTRY,CATCH capturaerror51002/state-1 y emite
B1_RESULT phaseforeign_patient/statusPASS/error51002/xact_state-1. Sin SELECT
tablasnegocio/DDL/DML/EXEC/fixtures, dejar rollbackautomatico al fin de batch.
Observar raw16,stderrSOLO3998 y usar validate_response nuevo para comprobar
protocolo. No contar el campo baselineRestored delhelper como fingerprintreal:
es validacion de error sintetico, NO prueba del SP sobre paciente ajeno.

Antesde cada conexioncrearledger exclusivo nuevo y pinearBYTES reales UTF8 del
SQL/harness, no textoLFnormalizado. Si falla pin antesSQL,consultar; si falla un
probe real,STOPsinretry yreportar. No dejar PARSEONLYOFF en un batch con fixtures
que pudiera ejecutarlas; cerrar siempreproceso/conexion acotado. Omitir B si A
falla. Max2conexiones reales; ningun otro diagnostico o intento de matriz.

## Entrega

Reporte TEMP B1R4-programmer-report.json con diff/hashes yregresion,2probes y
limites. ParseonlyPASS no es SPcompilado ni40fasesnegocioPASS; doomprobe no es
autorizacionreal de SP. SP_NO_COMPILADO/MATRIZ_NO_EJECUTADA/V13NOINSTALADA.
Si todo preparado y2probesPASS,succeededEN_REVISION; si falla,failed sin ampliar.
Procesar/ack lotes yworker_done conresultado real. Conservar terminal/sesion.
Sin commit/push/main/FactuEz/cuentasglobales/compras/shutdown.
