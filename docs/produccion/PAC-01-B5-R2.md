# PAC-01.B5.R2: transporte de QA y diagnostico cerrado, solo offline

Arquitecto2026-11-10. E2task_8fc4de487847/ctx_81f27beb2ebc FAILED revisada:
28artefactos/695SHA/726pines intactos, UNAinvocacionraw1/human-login/
UNEXPECTED_FAILURE,0checks/0lecturas/0sesiones nuevas; datos estables/ACL e
historia conservados, app/proxyJobs0. No prueba positiva API/UI/audit ni
conteo Node/Edge cleanup. Evidencia VINCULOS_QA_FALLO_E2_20261110.json.
No reintentar E2, borrar su directorio/diarios o declarar causa no observada.

Mismo Run run_624b9269b491, programador recuperapiura/terminal/sesion/worktree
retenidos --no-daemon. IDs nuevos de preambulo, AGENTS.md absoluto/flujo/TAREAS
y estecontrato. Supervisor unico escritor docs/tablero/revision. Conservar
historial y snapshot de fuentes antes de editar; no fuente de supervisor.

## Ownership exclusivo de cuatro herramientas (ninguna app)

- frontend/scripts/patient-links-real-qa.cjs
- frontend/tests/patient-links-real-qa.test.ts
- scripts/run-patient-links-real-qa.py
- scripts/tests/test_patient_links_real_qa_launcher.py

Mas NUEVOS TEMP B5R2: contexto/manifest para futura operacion E3, reportes y
snapshots. NO modificar run-patients-real-qa.py base249395F1...7EDFE, frontend
producto/bundle, backend, SQL,config/deps/AGENTS/docs o archivos/historia previos.
R2 es PREPARACIONOFFLINE:0DPAPI/SQL/HTTP/Edge/contextostart/probes nativos. No
E3 sin nuevo paquete supervisor. Si faltaalcance, preguntar por Orca antes.

## Cambio de transporte basado en QA previa, sin inventar causa

E2solo expone UNEXPECTED_FAILURE durante human-login. La nueva herramienta
usa APIRequestContext.fetch y omite flags locales de QA A previamente aceptada.
A probado usa page.evaluate fetch same-origin y Chromium con DOSflags fijos:
--host-resolver-rules=MAP health.localhost 127.0.0.1, MAP *.health.localhost 127.0.0.1
--no-proxy-server. Esto es una hipotesis de transporte/resolucion; no confirmar
DNS oproxy como causa del incidente sin evidencia. No hacer diagnostico real ahora.

Reutilizar ese transporte browser para APIQA: guardarallowedRequest ANTES de
page.evaluate y comprobar originactual exacto dentro del browser; fetchrelativo
con cookies same-origin/cache-no-store/redirect-error/CSRF propio, target fijo.
Nada de resolver otros hosts, proxyglobal, target127conHost/Cookie manual,
almacenar cookies o relajar allowlist. Sin APIRequestContext.fetch paraestas
llamadas. Puede conservar adaptador respuesta url/status/headers/json para el
consumidor existente, con controles estrictos de tipos/JSON/errorno200. Browser
route guard continue/abort sigue vigente yambas capasimpiden escritura ajena.

Las respuestas de page.evaluate fetch tambien disparan page.on(response).
Evitardoble conteo: mismo requestId/mismosdatosse registra UNAvez; contradiccion
de status/actor/tenant/patient/fase debe seguir FAIL, no silenciarcolisiones.
Demostrar con dobles flujoAPIobservado poramboscaminos y UI; no red real.

## Diagnostico seguro de errores inesperados

Agregar pasos cerrados para acceso: context/pagecreated,navigation-access,
public-context,login-form,login-submit,login-navigation,session-validation y
otros necesarios en enum fijo. Reportar enFAIL solo paso y categoria cerrada
(p.ej DNS,CONNECT,TIMEOUT,JAVASCRIPT,ASSERTION,UNKNOWN), nunca mensaje/stack/URL
arbitrarios, respuesta, cookies, email/password/CSRF o screenshotsde login.
Se permite clasificar patrones del error SOLO en memoria y emitir enum. Tests
con errores que contengan secretos/formas escapadas deben demostrar ausencia
de datos en report/stdout/stderr. Extender validate_report aese esquema cerrado,
sin admitir camposarbitrarios o convertir unknown enPASS.

## Telemetria real de cleanup para futura ejecucion

El helperbase contiene Job.stop conQueryInformationJobObject/ActiveProcesses0,
pero wrapperactual no conserva esa observacion. Usar job_factory propio en
base.contained_run (sin tocarbase) para observar cuenta real0 tras stop yANTES
de cerrar handle, cierre deJob y wait/drain del proceso propios. Solo numeros/
flags/codigos cerrados, sin PIDkillajeno ni recorrer/matar procesospor nombre.
No inferir Node/Edge0desdeEXECUTION_FAILED. Si cleanupfalla, contador null/codigo
especifico preservado, nunca0inventado. Tests normal/childFAIL/timeout/assignfail/
cleanupfail con kernel/procesodobles, sin procesos operativos. Mantener Jobantes
stdin/EOF, KillOnClose y deadline120s/entorno180s; no cambiosglobales.

## Namespace nuevo E3, conservando E2 fallida

Preparar TEMP/B5R2-environment.py desde originalB4P1 F5CD650F...3E1B41B0 con
SOLO3deltas: MANIFEST TEMP/B5R2-reviewed-pins.json, LEDGER
PREPARED/B5-E3-readonly-attempt.json y COMPLETED
PREPARED/B5-E3-readonly-completed.json. Manifest nuevo identico726pines SHA
6BF5A987...1E35FA6; no cambiaroriginales/B5P1/historia/extraccion/classes/stores.
Launcherversionado apunta a ese contexto y ledgerpropioB5-E3-browser-attempt/
completed; Node+validatorreport fijan directorio b5-readonly-e3 bajo mismo RUN
pacqa-20261109-a1. Sin parametros arbitrarios de operacion/path/hosts/runId.
Esto prepara un futuro intento E3 tras correccion/review; NO ejecutarlo ahora.
Conservar intactos b5-readonly fallido y los4diariosB5 usados,masE1.

## Pruebas y entrega

Rerun check/npmtest y suitePython afectada (no appbuild/Java/Next/demo). Cubrir
same-origin/guardas antes de browserfetch, opciones/CSRF/flagsfijos, errorJSON/
403/401, observaciondoble/idcollision, categorias/pasos/redaccion ycleanup
observado/contradicciones, defaults inertes/ledgers. No pruebas de buscar solo
strings del codigo ni uso de NativeJob/Edge/DPAPI real. Mantener lookup fixtures
exactas ysemantica readonly; no cambiar cuotas/roles/datos para facilitar pruebas.

TEMP/B5R2-programmer-report.json con4fuentesSHA/diff, baseline/outsideownership0,
3constantescontexto/manifestidentico y hashes historiaE1/E2 conservados, tests/
comandos/exits/conteos/limites/fallos. Causa E2 queda no determinada hasta
evidencia; reportar que se alineo transporte y mejoro diagnostico, no que se
valido QAreal. succeededEN_REVISION, reviewantesE3; ACK lotes yworker_done real.
Sin TLSApply/UAC/servicios/Docker/fixtures/secretos/globalcuentas/gastos/main/
commit/push/FactuEz/shutdown; mismo agente retenido.
