# PAC-01.A.QA.E1: ejecutar recorrido real aislado

## Actualizacion E1.R1, 2026-11-09

La primera attempt1794242208475 fallo antes de login por rutas Windows ausentes
en el wrapper temporal. L1 esta revisada, integrada y probada realmente sin
credenciales: Edge launch/closePASS, timeout de4procesos propios deja0activos.
Esta revision SUSTITUYE los comandos/pin de wrapper originales, incluidos los
que pudieran aparecer en el texto historico del preambulo. NO ejecutar
tmp/patients-real-env-20261109/run-qa-reviewed.py. Se reintenta la MISMA tarea
task_c0871e7d4bb8 reabierta con nuevo Dispatch; ctx_e57613f2dc29 queda historico, usar los nuevos IDs
en mensajes y done. La fuente frontend/runner, manifiesto y runId no cambian.
Leer esta version del archivo absoluto antes de ejecutar y atender mailbox.

Encargo supervisor del9nov, posterior a revision de herramientas task_5a7358409b8e /
ctx_1c94305dd25c. SOLO ejecucion QA secuencial; no editar fuentes o documentos.
Producto A/R1 y runner estan revisados/integrados en checkout supervisor. Leer
D:/Mavric/Health Project/AGENTS.md y estos contratos antes de ejecutar.

## Entorno preparado y ownership

- SQL HEALTHPROJECTQA Running/Manual; listener ordinario127.0.0.1:14335 y DAC
  loopback. Start-only supervisado con aceptacion Windows; fingerprint protegido
  7970854109e3742fa8c345ca526ba38d8c69e9bef0f87288ca72af7dc791eb02 igual antes/despues.
- DB existente health_project_sqlserver_qa_isolated_20261105, sin setup/bootstrap
  repetidos. Backend real loopback18080, perfil sqlserver-qa, jobsfalse, SOLO login
  hp_qa_runtime_20261105; readiness UP, estado OPEN. No credenciales migrador/bootstrap.
- Proxy real loopback18300 sirve frontend live integrado y conserva Host al backend.
  Tres hosts sinteticos HUMAN/HUMAN/ANIMAL contrastados por public/context.
- Las credenciales QA seleccionadas del checkpoint antiguo quedaron SOLO en
  manifiesto DPAPI CurrentUser dentro de tmp/patients-real-env-20261109. No leer
  store/checkpoint/auth directamente: usar exclusivamente el wrapper aprobado.
- TLS estricto A69 continua bloqueada; encrypt true/trustServerCertificate true
  solo QA del backend. No certificados, binding, servicios nuevos, cambio de red
  o configuracion global. No afirmar cadena TLS ni autorizacion productiva.

Worker conserva su sesion/worktree separado. Ejecuta los comandos aprobados que
usan runner congelado del SUPERVISOR, no backend antiguo de su worktree. Ownership
de fuentes: NINGUNO. Artefactos nuevos solo reportes/capturas propios del runner en
D:/Mavric/Health Project/frontend/test-results/patients-real-qa/pacqa-20261109-a1/
y tu informe TEMP. No modificar docs/evidencias versionadas ni artefactos anteriores.
No limpiar/reset/stash/commit/push/main/FactuEz ni matar procesos ajenos.

## Comandos exactos, dos fases

Primero verificar SHA antes de cualquier ejecucion:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath 'D:/Mavric/Health Project/scripts/run-patients-real-qa.py'
Get-FileHash -Algorithm SHA256 -LiteralPath 'D:/Mavric/Health Project/frontend/scripts/patients-real-qa.cjs'
```

Lanzador esperado249395F1120CDE3F68426339683BCC2117D3E4993E5C2F5553513FBB56E7EDFE.
Runner esperado1BB53685CF5B375B434D75DABE8BD61260672E167C5EADBC0271B1DBF0D8FE32.
Si difieren, parar y consultar. Wrapper verifica ademas hash del manifiesto cifrado,
runId y DB, descifra solo en memoria, envia a Node exclusivamente por stdin y
publica solo resultado filtrado, sin volcar stdout/stderr crudos o secretos.

```powershell
python 'D:/Mavric/Health Project/scripts/run-patients-real-qa.py' --readonly
```

Leer y procesar reporte de esta nueva attempt. Solo si rawExit0 y todos los controles
aplicables estan pasados (not-applicable permitido solo falta de pagina/datos),
continuar una vez con escrituras sinteticas autorizadas expresamente por este encargo:

```powershell
python 'D:/Mavric/Health Project/scripts/run-patients-real-qa.py' --allow-synthetic-writes
```

RunId fijo pacqa-20261109-a1. Preparacion de21pacientes humanos, alta humana y animal
UI, edicion opaca revisionada con conflicto, duplicado409 recuperable, persistencia
tras recarga/nuevo contexto y aislamiento HTTP segun PAC-01-A-QA.md. Todo por API/SP
runtime existentes. Capturas SOLO fixtures propias sinteticas, nunca login/passwords,
sesiones, HAR, traces o storageState. Sin correos/destinatarios reales ni gastos.

Ante CUALQUIER fallo, resultado incierto, colision o rechazo inesperado: no repetir
comando, cambiar runId, resembrar/resetear ni limpiar. Conservar attempt y comunicar
control/codigo/status/reportPath por Orca; supervisor decide reconciliacion o fix.
No reenviar POST ni sobrescribir revisiones por tu cuenta. No ejecutar suites
generales verify-api/identity porque compartirian estado y crearían otros fixtures.

## Entrega y revision

Informe TEMP: comandos/exit/tiempos, dos reportes attempt, controles reales/pasados/
reusados/reanudados/noaplicables, capturas de escritorio/movil con inspeccion propia,
cantidad de fixtures nuevas/reusadas y cualquier limitacion. No pegar credenciales,
cookies, token, body completo ni checkpoint en mensajes o informe. Logs del servidor
no son archivos asignados; consultar antes de ampliacion. Comprobar hashes fuente
antes/despues: cero cambios. Todos los lotes Orca procesados/ack antes de done.
Exito del worker deja EN_REVISION; supervisor verificara artefactos y visual real
independientemente. No afirmar grants SQL/JDBC nuevos ni TLS validada.
