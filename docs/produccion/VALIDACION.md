# Validacion y limites de evidencia

## Entornos

- Supervisor: D:/Mavric/Health Project; cambios previos del usuario preservados.
- Implementacion: worktree health-programmer, Maczz09/health-programmer.
- Previsto QA aislada: health-project-qa, 18080/13307/18025, tmp/qa/.env.
- No pacientes reales, envios externos, gastos ni publicacion.

## Evidencia de baseline

Setup: parser 2/2; IdentityOnly dos roles; tres rechazos esperados; procesos/sesiones
distintos --no-daemon; Git limpio del trabajador; tres capturas y reportes leidos.
Pruebas previas de instaladora: check correcto, 30/30 mock, Java10/10, build:demo82,
QA demo13, smoke correcto con 24 abortos de navegacion/prefetch separados. No son
nuevas ejecuciones de produccion. Ver ../agent-workflow.md.

## Ejecuciones actuales

2 de noviembre: `docker context show` = desktop-linux; `docker version --format
'{{json .Server}}'` falla porque no existe dockerDesktopLinuxEngine. No se inicio
Docker Desktop ni se afectaron contenedores existentes. Responsable: entorno local.
No hay MySQL/API real disponible para aceptar persistencia ni migraciones.

Continuar QA aislada verificable sin daemon, contratos y cambios frontend.
Registrar cada comando con resultado, revision de codigo y limitaciones; tests de
transporte simulado no son integracion MySQL.

## QA-01.A — ejecucion independiente del supervisor

En worktree programador: `python -B -m unittest discover -s scripts/tests -v`:
18/18 OK (0.801s), incluye exclusividad, release incluso error/interrupt, entorno,
destinos, transportes falsos Python y restauracion UI/CSRF con VM Node. No API real.
`python -B scripts/health-qa.py config`: exit0, Compose real validado sin daemon.
`python -B scripts/health-qa.py status`: exit1 QA_DAEMON_UNAVAILABLE; lockExists=false.
`git diff --check`: sin errores. Revision R1 pendiente por lock entre worktrees;
estos resultados solos no aprueban el defecto descubierto.

R1: lectura del diff adicional y nueva ejecucion independiente de la misma suite:
23/23 OK (3.018s), con cinco casos nuevos para common-dir, repos independientes,
Git overrides y reemplazos de lock. Ruta real del lock:
D:/Mavric/Health Project/.git/health-project-qa.run.lock. Credenciales siguen en
tmp/qa del programador; esta prueba no arranca servicios.

## INT-01.A — evidencia durante implementacion

El trabajador informa check/40 tests/build live85 paginas, aun pendientes de
aceptacion y navegador final. npm ci informo26 avisos agregados sin cambiar lock.
Supervisor ejecuto `npm audit --omit=dev --json` en frontend del worktree:
exit0, cero conocidas en dependencias de produccion (todos niveles0). No equivale
a revision de seguridad del producto ni a cero avisos en tooling/desarrollo.

Probe supervisor `node tmp/review-api-race.cjs`: fallo reproducido exit1,
newSessionCsrfPreserved=false con respuestas fetch falsas fuera de orden; sin
tokens reales ni API de red. Correccion delegada msg_c8a1564f9b60, ver REVISIONES.

Tras cambio de api.ts en R1, mismo probe independiente repetido:
exit0 y newSessionCsrfPreserved=true. Sin cambiar el probe ni usar red. La
aceptacion de INT-01.A sigue pendiente de cierre y regresiones completas.

## INT-01.A+R1 — comprobaciones finales independientes

- npm test:46/46,0 fallos/canceladas/omitidas,378.8425ms.
- npm run check:exit0.
- node tmp/review-api-race.cjs:exit0; CSRF nuevo preservado.
- node scripts/live-shell-qa.cjs:16 recorridos, errors=[] y blocked=[],
  network=intercepted, mysqlVerified=false; preview propio detenido por finally.
- Revision source: listado real restaurado, textos UTF8 y estado de ruta correctos.
- view_image: live-intercepted-sad-clients-detail.png, mobile-navy.png y
  storage-blocked.png del worktree; legibilidad/movil/panel inspeccionados.
- Builds del trabajador: live85 y mock85, secuenciales; demo13 sin API real.
  No se repitio build sin cambios; se verifico el artefacto con navegador.
- Integracion local:14 archivos con hash identico a fuentes revisadas, fuera de
  main; QA7 preservada. Ninguna prueba acredita backend actual.
