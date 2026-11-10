# PAC-01.B5.R3: alcance de cookie y preparacion E4, solo offline

Supervisor 2026-11-10. Mismo Run run_624b9269b491 y programador recuperapiura,
terminal term_7286bcc6-6224-4d5f-a389-b06a09939ca3, sesion/worktree retenidos,
cuenta por proceso --no-daemon. Nuevos Task/Dispatch del preambulo; leer AGENTS.md
absoluto, flujo/TAREAS, frontend/AGENTS.md y este contrato. Supervisor escribe
tablero/documentos/revision. Preservar checkout historico, no reset/sync/commit/push.

E3 task_90e714865b19/ctx_c5fefc021198 FAILED revisada: una invocacion raw1,
SESSION_MISMATCH en cookie-validation/ASSERTION, cero lecturas/checks/capturas.
Una sesion creada/revocada, cuatro queries readonly raw0, negocio/ACL/historia
iguales. Cleanup Node/Edge/app/proxy medido0, 695 fuentes/726 pines/106 historicos
intactos. Evidencia VINCULOS_QA_FALLO_E3_20261110.json. No repetir E3 ni borrar
diarios, salida b5-readonly-e3 o artefactos E1/E2/R2/E3. R3 NO ejecuta E4.

## Hallazgo supervisor y correccion

Backend BrowserSessionController.cookie limita health_session a Path=/api,
HttpOnly. QA A previamente aceptada usa context.cookies(origin+'/api/'). El
runner nuevo usa context.cookies(origin), que consulta la raiz /. El filtro de
la version Playwright instalada exige parsedURL.pathname.startsWith(cookie.path).
Supervisor ejecuto SOLO esa funcion extraida de coreBundle.js con cookie FALSA:
consulta raiz devuelve0, /api/ devuelve1, sin navegador/red. Bundle SHA256
2325CA4C1C83070E89DC49FB82525508F0A68E0CF12E2A624277968DA216B7E0.
Defecto determinista de alcance de URL en QA consistente con fallo observado;
no declarar validacion real corregida ni causa del E2 anterior.

Corregir consulta a origin+'/api/' en helper de validacion usado de verdad por
newClient. Conservar exigencia health_session/HttpOnly y aislamiento de origen;
no consultar todas las cookies sin filtro, no copiar/mover cookies, no imprimir
valores ni cambiar Path del backend, auth, roles, CSRF, cookie/security settings.
Agregar prueba offline de ese helper con context.cookies doble, fijando URL
exacta /api/, positivo y negativas cookie ausente/nombre ajeno/HttpOnly false.
La prueba debe fallar con la antigua consulta de raiz, sin arrancar Playwright.
Puede comprobar metadata path=/api, sin valores en reportes o logs.

Revision estatica del resto del flujo contra fuentes/QA previa permitida;
reportar otras discrepancias por Orca ANTES de ampliar cambios. No diagnostico
operativo, nuevos privilegios o sustituir API/UI por mocks en una futura QA real.

## Ownership y namespace E4

Solo estas cuatro herramientas en worktree programador:

- frontend/scripts/patient-links-real-qa.cjs
- frontend/tests/patient-links-real-qa.test.ts
- scripts/run-patient-links-real-qa.py
- scripts/tests/test_patient_links_real_qa_launcher.py

Mas NUEVOS TEMP B5R3-* para contexto/manifest/snapshots/diffs/reportes. Nada en
fuentes supervisor, backend/SQL/producto frontend/bundles/deps/config/AGENTS/docs.
Base scripts/run-patients-real-qa.py SHA256
249395F1120CDE3F68426339683BCC2117D3E4993E5C2F5553513FBB56E7EDFE intacto.
Conservar transporte readonly R2, flags, diagnosticos y cleanup observado sin
refactor ni relajacion. No ampliar allowlist o sacar comprobaciones para pasar.

Preparar TEMP/B5R3-environment.py desde B4P1 original SHA256
F5CD650F52A424BFA775D97D5EE6EF88AD903CDF47C8E074090F6AA13E1B41B0
con SOLO tres constantes nuevas:
MANIFEST=TEMP/'B5R3-reviewed-pins.json',
LEDGER=PREPARED/'B5-E4-readonly-attempt.json',
COMPLETED=PREPARED/'B5-E4-readonly-completed.json'.
Manifest identico726pines SHA256
6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6.
Launcherversionado apunta contexto/manifest B5R3, diarios propios
B5-E4-browser-attempt/completed.json. Runner+validator fijan nuevo directorio
b5-readonly-e4 bajo mismo pacqa-20261109-a1. Sin selector arbitrario de path/Run/
host/operacion. Actualizar tests de namespace/historia; no tocar ningun original
B4/B5P1/B5R2 ni diarios utilizados, extraccion/classes/truststore o credenciales.

## Verificacion y entrega

OFFLINE EXCLUSIVO: 0DPAPI/SQL/HTTP/Edge/arranques de contexto/probes nativos,
sin servicios/TLSApply/UAC/Docker/fixtures/cuentas globales/FactuEz/shutdown/gasto.
Check/npmtest y suite Python afectada, sin build/Java/Next/demo ni suites previas.
Mantener pruebas R2 y agregar regresion cookie significativa, sin solo buscar
strings de implementacion. Import/defaults inertes, E4 diarios/salida ausentes.

Informe TEMP/B5R3-programmer-report.json con cuatro SHA/diffs/snapshots, baseline
fuentes antes/despues y cero delta fuera de ownership, 726 pines/historia E1/E2/
R2/E3 preservada, tres constantes/contexto y manifest identico, comandos/exits/
conteos/fallos/limites. No guardar cookies/secretos o dumps de excepciones.
Si PASS: succeeded EN_REVISION (preparacion offline), no QA real validada.
Si fallo/bloqueo: reportar verdad, sin ampliacion. Procesar/ACK lotes completos
antes de worker_done, conservar terminal/sesion. E4 requiere nuevo encargo tras
revision e integracion supervisora; no commit/push por trabajador ni nuevo Run.
