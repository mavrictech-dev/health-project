# PAC-01.B5.P1: preparar QA real readonly de consulta de vinculos

Arquitecto2026-11-10. Mismo Run run_624b9269b491, programador recuperapiura,
term_7286bcc6-6224-4d5f-a389-b06a09939ca3/sesion01a1c5c7-d534-7d01-ac3a-c18bf31075ec,
worktree separado retenido --no-daemon. Nuevos Task/Dispatch de preambulo. Leer
AGENTS.md absoluto, frontend/AGENTS.md, flujo/TAREAS y este contrato. Supervisor
unico escritor de docs/tablero/revision. Comprobar raiz/rama/locales y preservar.

B1SQL,B2API,B3UI aceptadas en sus alcances; B4E1readinessREAL aceptada con
15artefactos/687SHA/726pines,raw0/12.172s/poll1/activos0 ydatos/huellaiguales.
E1 queda cerrado e inmutable. Falta unir API/UI reales con fixtures sinteticas.
Este paquete SOLO PREPARA herramientas y pruebas offline. NO ejecuta entorno,
DPAPI/SQL/HTTP/navegador/probes nativos,login oQAreal. EjecucionE2 posterior a
revision. No repetir E1/A69/B1 ni borrar diarios para reutilizarlos.

## Ownership exclusivo

Cuatro rutas NUEVAS (ausentes en supervisor al delegar):

- frontend/scripts/patient-links-real-qa.cjs
- frontend/tests/patient-links-real-qa.test.ts
- scripts/run-patient-links-real-qa.py
- scripts/tests/test_patient_links_real_qa_launcher.py

Mas NUEVOS artefactos TEMP B5P1: B5P1-environment.py, B5P1-reviewed-pins.json,
reportes/tests auxiliares propios y snapshots. Ningun otro archivo de producto,
docs/config/deps/migraciones/AGENTS/SQL o herramientas previas se edita. Consultar
por Orca antes de ampliar. Sin copiar checkout/reset/checkout/stash/main/commit/
push/cuentasglobales/gastos/FactuEz/shutdown. Nuevos archivos fuente solamente;
los687 anteriores se preservan. No ejecutar suites Java/Nextbuild/demo sin cambios
de app: este paquete no cambia producto ni bundle.

## Nuevo contexto para operacion B5, con historia E1 preservada

La futura operacion sera QA de negocio readonly, no retry del gateE1 aprobado.
Crear COPIA byte-exacta de TEMP/B4P1-environment.py (SHA
F5CD650F52A424BFA775D97D5EE6EF88AD903CDF47C8E074090F6AA13E1B41B0)
como TEMP/B5P1-environment.py con SOLO tres deltas de constantes:
MANIFEST -> TEMP/B5P1-reviewed-pins.json;
LEDGER -> PREPARED/B5-readonly-attempt.json;
COMPLETED -> PREPARED/B5-readonly-completed.json.
PREPARED sigue siendo TEMP/B4P1-prepared: clases-final/app existentes se reutilizan.
Copiar manifestB4 SHA6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6
al NUEVO manifestB5 SIN cambiar contenido726pines. Originales/diariosE1 intactos.
Sin runId/path/env/command arbitrarios, nuevo target o fallbacktrusttrue.
Demostrar diff exacto3constantes y pruebas de ledgerB5 exclusivo/inercia; no
ejecutar esta copia. Si necesita cuarto delta, consultar antes. Jar85D8FEA0...,
driverE36F5237...,truststore7988CDDE... yJava/clasesP1 se conservan sin recompilar.

El launcher nuevo importa contextoB5 inert y en futura opcion --execute-readonly
entra UNAvez en managed_environment con pins aprobados, mantiene el with abierto
durante navegador y verifica ensure_alive antes/despues; cleanupJobs siempre.
Default --plan no carga credenciales/contexto/proceso/red ni escribe diarios.
Futura ledger propia de QAlauncher tambien exclusiva, sin autoretry/reanudacion
automatica de fallos o borrado de operacion. Los hash finales quedan en informe
para comando E2 revisado; no invocar --execute* en P1.

## Credenciales y transporte existente, solo futura ejecucion

Reutilizar por import funciones seguras de scripts/run-patients-real-qa.py SHA
249395F1120CDE3F68426339683BCC2117D3E4993E5C2F5553513FBB56E7EDFE
(node_environment,resolve_node,validate_manifest,decrypt_manifest,contained_run,
filter_result), sin editar archivo ni ejecutar su main/execute. contained_run
asigna Job antes de enviar stdin; runner nuevo espera EOF ANTES de importar
Playwright/lanzar Edge. WindowsJob/kill-on-close y cleanup de hijos propios.
Se puede establecer TIMEOUT_SECONDS=120 SOLO en la instancia importada para
limitar QA al deadline180s del contexto; no modificar fuente base o timeout
del entorno. Deadline insuficiente implica FAIL seguro, no proceso detached.
Ejecucion futura canonicalROOT=D:/Mavric/Health Project. Las cuatro fuentes
nuevas se preparan en el worker y solo supervisor las integrara por SHA tras
review; no escribirlas alli ahora ni apuntar a inputs/DPAPI de otro checkout.
Las pruebas P1 usan dobles antes de esa integracion; no ejecutar por suplir
la ausencia del runner nuevo en la raiz canonical.

Appmanifest EXISTENTE tmp/patients-real-env-20261109/patients-manifest.dpapi,
CurrentUser; nunca leer/decryptar durante P1. Readinesshistorica94C962F88B2C346B6D3CE3DC2C461129B6730E02AF138E392A063C61B9F4EE08
en esa carpeta solo autoriza cipherSHA
adf5bada134203d6d69c2d1a662073fe411d2f8ff3f6e983e54fdbcff45d1aed,
runIdpacqa-20261109-a1/QA DBaislada/base18300. Sus antiguos flags trusttrue NO
son estadoTLS actual. Helperprovision4415F6DB...0EAD autorizado solo en futura
cargaCurrentUser por wrapper revisado; no authglobal/tokenfiles/bootstrap/store
directo/credencialesargv/env/plainfiles/log/console/artefactos. No copiar DPAPI.

Slots existentes: human qa-3fe6475a3f-a.health.localhost,otherHuman
qa-3fe6475a3f-b.health.localhost,animal qa-3fe6475a3f-v.health.localhost, port18300.
Validar esquema completo, hosts/tenants canonicos distintos, emails.example.test,
DB/run/base fijos, despues hostcontext/session reales coincidentes y ADM/REC
sinSAD/SOP/PAC/RES mixtos. No aceptar manifiesto de otros datos/hosts.

## Runner real que debe quedar preparado (no ejecutarlo)

Import inerte, flags cerrados --readonly, stdin JSON con EOF, Playwright msedge.
Acceso real mediante cookie/CSRF con contextos separados por host. Se permiten
POST auth/browser/login y logout propios; el resto de negocio es SOLO GET.
Ningun PUT/POSTpatients/DELETE/fixtures/cambio de roles/estado o envio de correo.
Sin route.fulfill/respuestas sustituidas: guardas de navegador solo continue
para origen/path/metodo permitido o abort+FAIL. APIRequestContext tiene tambien
guarda propia antes de llamada (no depende de page.route). Sin HAR/traces/video/
logs cuerpos/cookies/tokens; captures solo despues de autenticar/ficha sintetica.
Capturar solo codigo seguro/IDsrequestUUID/conteos/paths de capturas con SHA.

Fixtures conocidas, sin provisionar o cambiar datos: pacienteHUMAN
c692af54-6391-4e8a-9b95-7bcbdd930bcc (A68PUTlinks+revocacion documentados en
CIERRE_LOCAL_20261106.json); perfilactualhuman debe poder leerlo y tener al menos
un vinculo para probar datos historicos. ParaANIMAL buscar identificador exacto
PACQA-pacqa-20261109-a1-ANIMAL-UI (PACA real), exigir unico paciente del tenant y
domainANIMAL y resultado links vacio esperado. Si faltan/mutan estas fixtures,
reportar PREREQUISITE_FAILED ySTOP, sin escanear otras cuentas/datos, inventar
PASS o crear fixtures para destrabar. No extraer credenciales de otros checkpoints.

Preparar verificaciones reales: GETlinks seven-field camelCase/types/IDs/scopes
ytenantexacto, limite21/offset0 ysubpaginas1/offset0,1 comparadas con ordenreal;
incluir inactivos segunobservado, []ANIMAL, 404neutral para mismo pacienteHUMAN
enotherHuman,401anonimo. UIactual: ficha no llama links hastaaccion, cargarlista
del mismo paciente y estado/alcances/nombres coincidentes conAPI, volver/cerrar,
consulta explicita ydatosactuales, emptyANIMAL, escritorio1440/movil390/temas y
teclado/nooverflow/errorespagina. Logout real seguido deconsulta debe expirar
sesion sin mostrarfilas. No provocar403/5xx cambiando permisos/configuracion.
Registrar que pagingUI21 puede NO estar ejercitado si fixturetiene<21: no
atribuirle los29sinteticos ni55SQLprevios como21filas reales en este navegador.

Recoger cada GETlinks observado (API+UI) con requestIdUUID real,status,actorId,
tenantId,patientId/fase, deduplicado. Esto permitira despues al supervisor
contrastar UNPATIENT_LINKS_READ por lectura200 yninguno por401/404, metadata{},
sinSQLdesdeNode/runtime. Login/logout/trazas/audit generan cambios autorizados
de auth/audit en futuraE2, pero no negocio/ACL/esquema; no esperar baselineglobal
exacta tras login. AuditoriaSQLreadonly y conservacion se especificaran enE2,
no ejecutar ahora ni anadirprocedimientos/grants para la prueba.

## Pruebas offline y entrega

Tests significativos con fakes: manifest/host/session/roles contaminados, shapes/
sevenfields/UUID/orden/subpaginas/[]/crosspatient/negativos; requestguard real
rechaza escritura/hostajeno y no usa fulfil; import noI/O/Playwright. Python:
default inert, pins/cipher/paths/env, loader soloenexecute con dobles, Jobantes
stdin/EOF, resultado estricto+redaccion passwords, deadlines/cleanup/contexto
vivo yfallos/ledgers exclusivos. Runners/modelos no se etiquetan como motorreal.
Ejecutar npm run check y npm test, mas suitePython nueva. Sin navegador/probes
nativos/servicios/SQL/DPAPI/HTTP en P1 y sin nuevas suites/builds de app.

Informe TEMP/B5P1-programmer-report.json con cuatrofuentes+SHA/diff, baseline,
tresdeltasTEMP, manifestcopiadoidentico/pines/diariosE1preservados, pruebas/exits/
conteos/comandofuturo y limites/fallosiniciales. No secretos. succeededEN_REVISION
hasta review; no E2 sin paquete supervisor. Procesar/ack lotes antes de done y
conservar cuenta/sesion/terminal, sin main/despliegue/certificados/UAC/shutdown.
