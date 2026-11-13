# PAC-01.C1.P2.R1: conservar evidencia de fallo antes de uso operativo

Contrato supervisor, 2026-11-12. Continuidad local autorizada. OFFLINE: no
SQL/JDBC/HTTP/SQLcmd/mainreal/probes/servicios/Somee/AgendlyCitas o instalacion.
Leer AGENTS/flujo/TAREAS, PAC-01-C1-P2.md y PAC-01-C1-QA-SECUENCIA.md CANONICOS
en D:/Mavric/Health Project, este contrato y evidencia
evidencias/VINCULOS_VERIFICADOR_C1P2_20261112.json antes de editar.
Misma pareja/cuentas por proceso/--no-daemon/Run/terminal/sesion/worktree.
Usar IDs NUEVOS del preambulo, no los IDs historicos de C1.P2.

## Revision R-C1P2-01

task_de0b6f78d791/ctx_49d75d51c681 done msg_7478f6fa6f60 revisada:365artefactos/
12referencias/707fuentesprevias/726pines/301historicos/21snapshots/25migraciones/
155artefactosprevios exactos;710fuentes tras3adiciones. Supervisor lee las tres
fuentes y ejecuta18tests independientes con subprocess real BLOQUEADO:PASS.
Parserworker112SQL/111fases0errores es solo sintaxis, ninguna prueba de motor.
InformeSHA7FB0626338DB5D6891924A497A70E7F9D0BBA6DC1C9E6F0462DA9462F47DE684.
Original no integrado ni autorizado para ejecucion.

Problema reproducido OFFLINE en tmp/c1p2-supervisor-20261112/failure-observability.json:
Runner completa sequence_human_adm y falla en revision_exponent con frame
invalido; solo entrega FRAME_INVALID con excepcion sin phase/nonce/checks.
Si baselinefinal ademas deriva, finally reemplaza esa causa por
FINAL_BASELINE_DRIFT. Se pierde evidencia de fase inicial y controles previos;
Transport captura stdout/stderr/rawexit en memoria pero no deja evidencia
duradera por llamada, y CLI solo imprime status/code. Esto impide revisar un
primer fallo real sin instrumentar/repetir la ejecucion. Falla cerrado, pero
se devuelve antes de su uso operativo por falta de trazabilidad.

## Ownership SOLO dos fuentes existentes

- scripts/verify-patient-link-management-sql.py
- scripts/tests/test_patient_link_management_sql_verifier.py

Mas TEMP NUEVOS C1P2R1-* para snapshots/diff/tests/reporte. Conservar archivos
originales C1P2-* y todas las fuentes previas. Plantilla SQL
backend/scripts/verify-sqlserver-patient-link-management.sql queda CONGELADA
SHA9476CEC9A4C3906AD9E0D17EA964ED63C4B353372F4F879EEAA13049600C1D4D.
No V1-V14, Java/API/UI, configuracion/deps/docs/AGENTS, helpers compartidos o
sync/reset del worktree. Baseline710; unica variacion permitida esas dos fuentes,
sin adicion de producto. Consultar por Orca antes de ampliar alcance.

## Resultado exigido y limites

1. Fallo estructurado conserva causa PRIMARIA, stage (baselineinicial/prephase/
   phaseinvoke/phasevalidate/postbaseline/finalbaseline), phase/nonce si aplica,
   controles completos previos como PARCIALES y resultado de conservacion fresh.
   Un error secundario de finalbaseline NO reemplaza el inicial. Un error de
   transporte Failure mantiene su codigo concreto (p.ej.TIMEOUT); no colapsarlo
   siempre a PHASE_TRANSPORT_FAILED. Errores imprevistos siguen saneados.
2. Evidencia local nueva de corrida, exclusiva/sin sobrescribir, requerida por
   CLI operativo ANTES de permitir el primer transporte. Puede anadir opcion
   --evidence-dir, conservando el unico modo PRE_APLICACION y review-manifest
   cerrado. Ubicacion local nueva en root/tmp o TEMPpropio, sinUNC/reparse/escape
   o borrado. Nunca tocar evidencia vieja ni crear evidencia desde un import.
3. Cada llamada deja intento ANTES del transporte y resultado/desenlace con
   stage/phase/nonce/orden, hashSQL y evidencia suficiente para reconstruir el
   SQL generado de las fuentes congeladas. Guardar codigoexit/longitudes/
   hashesstdoutstderr y campos de frame SOLO si validado. Para diagnostico de
   error nativo puede extraer cabecera numerica Msg/Level/State/Line conocida;
   no copiar arbitrariamente mensajes o buffers con posibles valores de filas.
   No rawrowvalues, definiciones del motor, passwords/tokens o secretos en logs.
   SQL generado es fuente controlada de fixtures, no salida de datos; si se
   conserva, mantenerlo solo en namespace local y no reenviarlo automaticamente.
4. Reporte final de exito/fallo enlaza journal/summary, intentos y checks
   efectivamente aceptados. Parciales nunca convierten corridaFAIL enPASS.
   Registrar por separado baselinepost y final, incluyendo intentos fallidos.
   Un fallo de escritura de evidencia no permite seguir con fases mutantes ni
   terminarPASS; despues de transporte mantener comprobaciones readonly de
   conservacion/final sin compensaciones. Antes de primer transporte, fallo
   de evidencia debe dejar cero llamadas. No retries de fase/proceso.
5. No cambiar SQL, matriz111/expectederrors/checkcounts, fixtures, argumentos
   SQLcmd, target/entorno/pines/hashV14, definicion de baseline o normalizacion
   de frames/errores. Mantener una conexion por llamada, parada al primer fallo
   y baselines nuevas de cleanup. No nuevas sondas/transportes o codepaths de
   aplicacion/POST. Solo mejorar evidencia y preservacion de causas.

## Pruebas y entrega

Subprocess SIEMPRE doblado; importar/modular/generar no invoca motor. Extender
tests con dosfases: primerPASS y segundaFRAME_INVALID debe conservar phase2/
nonce/primercheck; finalbaselinefallida conserva AMBOS fallos. Cubrir timeout,
baselineinitialfail, evidencewritefail antes de transporte (cero llamadas),
fallo de registro posterior (sin siguiente fase, cleanupreadonly conservado),
carpetaexistente/escape y resumen sin canary/secreto/valores de salida arbitraria.
Probar persistencia con archivos ficticios TEMPpropios y lectura despues de
terminar runner, no una variable en memoria presentada como journalduradero.

Preservar18tests existentes con cambios minimos de interfaz; no relajar aserciones
de framing/target. Comparar SQL generado viejo/nuevo con noncefijo: baseline y
las111fases deben ser byte/texto exactos. Si son iguales, no repetir parser112
ni Maven/frontend; fuenteSQL/migraciones inmutables y ninguna prueba de negocio.
py_compile enTEMPpropio, sin nuevas dependencias. No mainreal incluso confakeargs
que puedan abrir motor por fallback; tests inyectan transporte doblado.

TEMP/C1P2R1-programmer-report.json con nuevosIDs,2SHA/diff/snapshots, contratos
de journal/fallo, comandos/exits, regresiones y conservacion de710fuentes/
pines/historia/evidencia original; generar nuevo manifestcandidato sin aprobarlo.
Estado EN_REVISION; succeeded solo herramienta preparada. ACKdeliveryId si
aparece, procesar todos los lotes antes de worker_done y conservar terminal.
Sin commit/push/main/despliegue/gasto/datosreales/FactuEz.
