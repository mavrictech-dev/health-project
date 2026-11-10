# PAC-01.B5.R4: politica de recursos estaticos verificados, solo offline

Supervisor 2026-11-10, mismo Run run_624b9269b491 y programador recuperapiura,
terminal/sesion/worktree retenidos --no-daemon. Usar Task/Dispatch del nuevo
preambulo; leer AGENTS.md absoluto, flujo/TAREAS, frontend/AGENTS.md y documentacion
Next instalada pertinente. Supervisor escribe docs/tablero/revision, no worker.

E4 task_d85679301779/ctx_9f7c59b345f1 FAILED revisada: una invocacion raw1,
UNSAFE_REQUEST en human-ui/ui-ficha/ASSERTION tras un control API positivo y tres
lecturas200 con tres auditorias correlacionadas, cero violaciones. Seis controles
faltan. Cuatro queries readonly raw0; una sesion nueva/revocada, negocio/historia
iguales, Node/Edge/app/proxy medidos0. Supervisor verifica 33 artefactos,695 fuentes,
726 pines y175 historicos. VINCULOS_QA_FALLO_E4_20261110.json. Sin retry ni borrar
diarios/salida E4. No afirmar QA completa ni negativos/UI por evidencia parcial.

## Hallazgo, diseno y limites

La solicitud exacta rechazada no se registro; no atribuir causa confirmada a DNS,
demo, prefetched RSC o API arbitraria. Hay incompatibilidad estatica demostrada:
allowedRequest rechaza GET /demo/, /demo/__next.demo.__PAGE__.txt y
/__next._tree.txt. RuntimeHome tiene Link a /demo/ y el export revisado contiene
out/demo/__next._tree.txt, __next._full.txt, index.html/index.txt y segmento
__next.$c$path/__PAGE__.txt; tambien root __next._tree.txt. Next instalado explica
payloads estaticos para navegacion. QA A aceptada permitia todos GET non-API;
R4 debe mantener una politica mas precisa mediante inventario verificado.

Corregir SOLO politica de assets estaticos: same-origin GET/HEAD a rutas exactas
derivadas de los 444 archivos del export root ya pinneado. Mantener rechazo
incondicional de /api y /actuator como estaticos. API sigue su allowlist actual
sin ninguna ampliacion, y POST/PUT/PATCH/DELETE negocio siguen rechazados. No
activar rutas publicas de registro API, soporte, monitor, cuentas o navegacion
ajena como efecto lateral. No route.fulfill/mocks para futura prueba real.

Implementar helper comprobable que construya Set de rutas a partir de nombres
relativos validados del inventario aprobado. Permitir archivo exacto, alias de
directorio/index.html con/sin slash y alias RSC Windows EXACTO inverso de la
normalizacion del proxy preview-live.cjs (ultimo punto se vuelve directorio).
No prefijos amplios nuevos, regex generica para cualquier .txt, aceptar cualquier
GET non-API, ni rutas fuera de inventario. Denegar rutas hostiles/traversal,
encoded separators, symlinks/reparse y origen/credenciales ajenas.

Fuente de inventario: manifest TEMP aprobado 726 pines SHA256
6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6,
exactamente 444 rutas bajo D:/Mavric/Health Project/frontend/out. Puede preparar
lista constante en runner desde ese manifest durante R4, o cargar SOLO el mismo
manifest fijo validado SHA en run() antes de browser, filtrando raiz exacta y
rechazando cualquier delta/cuenta inesperada. No recorrer nuevos roots ni leer
credenciales. Import/default siguen inertes (sin fs/Playwright/procesos/red).
Si necesita otra fuente/archivo fuera de ownership, preguntar por Orca.

Agregar diagnostico cerrado de primera denegacion para futuros fallos: method
de enum fijo y categoria fija (p.ej INVALID_URL,FOREIGN_ORIGIN,API_READ,API_WRITE,
STATIC_PATH,ROUTE_HANDLER), sin URL/path arbitrario/headers/query/body/password/
stack. Preservar denegacion real y callback abort; no ocultar eventos inseguros.
Report/launcher validator admiten SOLO esquema/enum cerrado. Es informacion de
QA, no filtro que convierte fallo en PASS. Mantener pasos/categorias previos.

## Ownership y futura operacion E5

Solo cuatro herramientas QA en worktree programador:

- frontend/scripts/patient-links-real-qa.cjs
- frontend/tests/patient-links-real-qa.test.ts
- scripts/run-patient-links-real-qa.py
- scripts/tests/test_patient_links_real_qa_launcher.py

NUEVOS TEMP B5R4-* para contexto/manifest/inventario/diffs/snapshots/pruebas/report.
No editar producto frontend/out, backend/SQL/config/deps/base helpers/docs/AGENTS
ni fuentes supervisor. Sin refactor de cookie/transporte/cleanup, datos/roles/CSRF,
fixture IDs o cuotas. Conservar ambos guardas antes del fetch y en browser route.

Preparar B5R4-environment.py desde original B4P1
F5CD650F52A424BFA775D97D5EE6EF88AD903CDF47C8E074090F6AA13E1B41B0
con SOLO tres constantes: MANIFEST=TEMP/'B5R4-reviewed-pins.json',
LEDGER=PREPARED/'B5-E5-readonly-attempt.json',
COMPLETED=PREPARED/'B5-E5-readonly-completed.json'. Manifest identico726pines.
Wrapper apunta B5R4/contexto/manifest, propios B5-E5-browser-attempt/completed;
runner+validator salida fija b5-readonly-e5 bajo mismo pacqa-20261109-a1.
Sin parametros de path/Run/host ni tocar contextos/historia/diarios E1-E4/R2/R3.
E5 NO autorizada en este encargo: solo preparacion offline y revision posterior.

## Pruebas y entrega

Pruebas de helpers/politica reales con dobles sin red: inventario aprobado exacto,
alias root/public/demo/app/RSC y archivos de medios, exclusiones API/actuator aun
si aparecen en inventario hostil; rutas desconocidas/origen ajeno y metodos de
escritura siempre abortan. Verificar API allowlist existente sin delta y rechazos
API ajenas/IDs/query no admitidos. Probar callbacks continue/abort y diagnosticos
cerrados sin datos canario; guardianes separados siguen funcionando. Nada de
tests que solo busquen strings o de desactivar prefeteches/producto para pasar.

Check/npmtest y suite Python afectada; no build/Java/Next/demoQA/native probes ni
DPAPI/SQL/HTTP/Edge/arranque de contexto. Conservar 695 fuentes salvo cuatro owned,
726 pines/444 export y todos historicos E1-E4/R2/R3. No servicios/TLS/UAC/Docker/
fixtures/cuentas globales/main/commit/push/gasto/FactuEz/shutdown.

TEMP/B5R4-programmer-report.json: cuatro SHA/diff/snapshot, antes/despues/ownership,
manifest identico/contexto tres constantes, inventario/alias examinados, pruebas/
comandos/exits/conteos/fallos/limites. E4 exact rejected request queda no observado,
sin inventar causalidad. Si PASS succeeded EN_REVISION de preparacion offline;
si falla/bloqueo comunicar verdad y no ampliar. ACK lotes completos antes de
worker_done, preservar sesion/terminal. QA real E5 solo con nuevo encargo revisado.
