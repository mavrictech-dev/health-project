# PAC-01.B5.P1.R1: prueba de scope independiente del checkout

Revision supervisor2026-11-10 del P1task_2a13d59328f9/ctx_4e58d4bba3bf.
47artefactos/691SHA/726pines contrastados,687fuentes previas intactas y copia
TEMP B5 exactamente3constantes; diariosE1 preservados. Cuatrofuentes nuevas
todavia NO integradas. No aceptar ni ejecutar E2 antes de corregir este test.

Ownership SOLO scripts/tests/test_patient_links_real_qa_launcher.py en el
worktree del programador. Las otras tres fuentes, copiaTEMPcontexto/manifest,
bundles, diarios y fuentes supervisor se preservan byte a byte. Mantener mismo
Run run_624b9269b491, cuenta recuperapiura/terminal/sesion/worktree --no-daemon.
Nuevos Task/Dispatch del preambulo. Leer AGENTS.md absoluto y contratoB5P1/R1.
Supervisor unico escritor docs/tablero; no cambiosglobales/commit/push/main.

## Hallazgo reproducido sin operaciones reales

test_ledger_exclusive_and_worker_execution_refused_before_credential_or_context
invoca Operations.preflight({}) y espera PATH_SCOPE_CHANGED con __file__ real.
Desde worker rechaza por su ubicacion, pero desde canonicalROOTD:/Mavric/Health
Project pasa esa guarda y rechaza PIN_INVALID por diccionario de pins vacio.
Por tanto el test fallaria tras integracion legitima, aunque el launcher cumpla.
Supervisor reprodujo worker->PATH_SCOPE_CHANGED y canonical->PIN_INVALID
cambiando solo el atributo __file__ del modulo en memoria;0DPAPI/SQL/HTTP/procesos.

Corregir la prueba para simular explicitamente ubicacion NO canonical con
patch.object(__file__,...)/ROOT controlado, y probar tambien ubicacioncanonical
con pins{} ->PIN_INVALID. No modificar guardas del launcher ni expectativas de
seguridad para aceptar paths equivocados. La prueba debe pasar desde cualquiera
de los dos checkouts, y conservar el testdeledger exclusivo y preflight real
con archivos sinteticos/inputs manipulados que ya existe.

Rerun SOLO suitePython de este archivo y comprobacion del caso canonical/worker
con dobles; no hace falta repetir103frontend/check ya aceptados como evidencia
offline previa si esas fuentes no cambian. No compilar/invocar entorno/native,
DPAPI/SQL/HTTP/Edge, ni suites Java/Next/demo/build o datos reales.

Informe TEMP B5P1-R1-programmer-report.json con SHAprevio/final,diff y prueba
independiente delcwd, comandos/exits/conteos y0delta fuera delownership. Preservar
P1report/snapshots y contexto/hash, sin sobrescribirlos. Si requiereotra ruta,
consultar por Orca antes. Entrega succeeded EN_REVISION, no aceptacion; ack lotes
yworker_done veraz, misma sesion/terminal retenidas. E2sigue no autorizado.

## Aclaracion de contrato de autenticacion

El logout propio existente usa DELETE /api/auth/browser/session. El permiso
previo para logout se refiere a esa operacion real; se acepta ese unico DELETE
de autenticacion propio, sin permitir DELETE de negocio/otras sesiones. La
guardade metodos del runner ya limita esa ruta; no necesita cambiar por R1.
Las referencias POSTlogout del contratoP1 no sustituyen el protocolo vigente.
