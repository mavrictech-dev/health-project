# PAC-01.B4.E1: un arranque real de readiness con TLS estricto

Encargo supervisor2026-11-10, continuidad autorizada del usuario. Mismo Run
run_624b9269b491, programador recuperapiura, terminal
term_7286bcc6-6224-4d5f-a389-b06a09939ca3/sesion
01a1c5c7-d534-7d01-ac3a-c18bf31075ec/worktree retenidos --no-daemon.
Leer AGENTS.md absoluto, flujo/TAREAS, D-87.U y este contrato; usar IDs del nuevo
preambulo. Supervisor unico escritor docs/tablero/veredicto. Ownership fuente
NINGUNO; solo NUEVOS artefactos TEMP B4E1 de captura/ledger/harness e informes.

P1 task_131aca7351c3/ctx_4fcac67b4740 revisada independientemente:73artefactos,
726pines/687fuentes intactos,3classes recompilados identicos y26tests propiosPASS.
Correcciones ZIP/esperaProxy/cleanupFD aceptadas. Los dos probesP1 ya consumidos:
publicinspectraw0/155guardas (no155casos) ytimeout1.016s/raw1 esperado, activos0.
No repetir standaloneP1probes, extraccion, compilacion o suites backend/frontend.

## Permiso de ejecucion acotado

Se autoriza UNA invocacion REAL del launcher revisado --execute-readiness.
Solo Java/backend y Node/proxy propios, loopback18080/18300, SQLQA yaRunning en
127.0.0.1:14335. NO es permiso para TLSApply/certificados/UAC/restart/servicios,
setup/migraciones/V13/grants/principales/bootstrap/fixtures, ni usar Docker/MySQL.
Si SQLQA no estaRunning/loopback o puertosapp ocupados, STOP sin arrancar servicios
o matar procesos ajenos. Sin datos reales, gastos, FactuEz/main/commit/push.

Canonicalroot D:/Mavric/Health Project. Fuentesinmutables deP1 en TEMP:

- B4P1-environment.py SHA256
  F5CD650F52A424BFA775D97D5EE6EF88AD903CDF47C8E074090F6AA13E1B41B0
- B4P1-reviewed-pins.json SHA256
  6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6
- B4P1StrictRuntime.java SHA256
  E2C6E0D67D03A0AC69474B24316C354FF7DF74E07B51A495755DB3D3B572EC39

Jar supervisor85D8FEA0...D55512F, driverE36F5237...7E14AF66, storepublico
7988CDDE...685C037 y clases-final3 ya estan en manifest726. El launcher debe
usar EXACTAMENTE ese jar extraido, no jarviejo, otrocheckout o recompilacion.
No cambiar app,scriptJava/Python,manifest/pins/extraccion/stores o sourcehelpers
para facilitar una prueba. Si hay mismatch o fallo, informar failed y STOP.

Comando fijo con argv estructurado (no shell-built/passwordargs):

```text
C:/Users/maxmo/AppData/Local/Programs/Python/Python311/python.exe -B
C:/Users/maxmo/AppData/Local/Temp/B4P1-environment.py --execute-readiness
--approved-launcher-sha256 F5CD650F52A424BFA775D97D5EE6EF88AD903CDF47C8E074090F6AA13E1B41B0
--approved-manifest-sha256 6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6
```

El publicinspect interno del contexto es PREFLIGHT de E1 antes de secreto; queda
autorizado UNAvez como parte de esta invocacion, no otra ejecucion standaloneP1
ni las tres conexionesA69. Solo helperaprobado carga runtimepassword en memoria
y lo envia por stdin al child contenido. Nunca bootstrap/migradorpassword,
credenciales globales, argv/env/plainfiles/logs/chat. E1 no carga manifiesto
de aplicaciones ni login de navegador. No overrides ni fallback trusttrue/CA.

## Pre/post y evidencia independiente

Antes de invocar: preservar inventario687fuentes y726pines, verificar ausencia
de TEMP/B4P1-prepared/readiness-attempt.json yreadiness-completed.json. Reservar
artefacto TEMP B4E1-attempt exclusivo y registrar UNA invocacion, automaticRetryfalse.
No borrar/recrear diarios existentes para facilitar un retry. Snapshot SQLreal
readonly usando UNICAMENTE baseline() del controladorB1 revisado (no main/PRE/
POST/fixture); LPC WindowsIntegrated y DBmarcador fijos, sin passwords. Capturar
huella protegida con dot-source script configure-isolated-sqlserver-qa.ps1
SHA3FBC605A...831 y Get-QaProtectedBaseline, NO InvokeQaTool/Apply/Start.

Supervisor ya comprobo baseline readonly antesE1: igualdad exacta al B1POST,
installed1/ACL564/modeOPEN, protectedFingerprint
a04d8236d807b3527dce32d8c8168e2e691902c89c0dd3eb79dda933ae8ca2af.
Referencia local tmp/pac-01-b4-20261110/e1-preflight/database-baseline.json.
Revalidar antes y despues como pruebas de conservacion; no inventar vacio de
tablas o capturas antes de ejecucion si un harness falla. No extra SQLdiagnostico
o cambios para investigar un fallo sin volver a supervisor.

Tras UNexecute, verificar JSONcerrado del launcher y completion reales: raw0,
statusREADY_FOR_QA/codeREADY, readinessPolls>=1, appActiveAfterClose0 y
proxyActiveAfterClose0. El propio launcher espera HTTPhealth200/statusUP real
y startup exacto del proxy; su contrato strictfalse/encrypttrue ytruststore
dedicado hacen esta una prueba positiva del backend en QA. No modificar su
campo historico productTLSValidatedfalse: evidencia nueva debe delimitar
backendruntime local positivo vs TLSproductivo/general/negativos no ejecutados.
No inventar conteo SQL/JDBC exacto a partir de readinessPolls (pool/health pueden
usar mas llamadas); informar solo las observadas y el limite de evidencia.

Luego mismos datos/modulos/columnas/ACL/principales/roles/mode quepre, huella
protegidaigual, SQLQA sigueRunning, listeners18080/18300 propios cerrados.
Readiness/actuator no generan trazas /api, no se autorizan nuevas llamadasAPI
de negocio/login/fixtures. No UI/Playwright ni autorizar toda migracion/produccion.
No detener SQLQA al cerrar el entorno; solo Jobs app/proxy propios del launcher.

## Resultado y fallo

Informe TEMP/B4E1-programmer-report.json con IDs/comando/exits/start-end,
JSON/ledger/completion/pines/SHA/sources/prepost/limites. Capturar solo salida
cerrada autorizada, sin rawexceptions/logsdeapp/passwords. Mantener los diarios
y fallos; no reintentar aunque rawexitno0, no compensar/reseed/borrar/ajustar
config, no diagnosticosSQL/probesextra. Si timeout el launcher debe cerrar y
esperar sus Jobs; reportar activos y limitaciones sin afirmar cleanup no probado.
SiPASS succeeded EN_REVISION (no aceptacion). SiFAIL failed ySTOP, revision
supervisor antes de correccion o nueva ejecucion. Procesar/ack lotes Orca antes
de worker_done y conservar terminal/sesion. La QAreal API/UI de vinculos vendra
despues del gate de entorno, con su propio alcance/operacion revisada.
