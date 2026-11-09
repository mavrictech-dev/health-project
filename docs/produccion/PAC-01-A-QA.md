# PAC-01.A.QA: preparar recorrido SQL/HTTP/browser real

Encargo del supervisor, 2026-11-09, continuacion D-83. A/R1 revisadas e integradas
localmente por ocho SHA exactos. R1 mantiene su rechazo historico y correccion.
No afirmar validacion real antes de ejecutar contra backend real preparado.

## Entorno y limites de este Dispatch

Supervisor: D:/Mavric/Health Project, health/production-wave0, backend SQL Server
completo y V1..V12. Worker conserva HEAD0b24487 y trabajo historico; leer backend
actual desde supervisor, sin copiarlo ni ejecutar su version antigua.
SQL dedicado HEALTHPROJECTQA esta Stopped/Manual hoy; TCP127.0.0.1:14335,
DB health_project_sqlserver_qa_isolated_20261105 ya provisionada con datos sinteticos.
Backend previsto loopback18080, proxy18300, host health.localhost y tenants QA.
Plan actual sin elevar: INSPECTION_ACCESS_DENIED/mutation_attemptedfalse.
No ejecutar setup, V1..V12, bootstrap ni crear logins/credenciales/base otra vez.
TLS A69 sigue bloqueada por UAC; no actuar sobre certificados ni eludirla.

En este Dispatch SOLO implementar herramientas y sus pruebas offline. No arrancar
servicios/backend/proxy, no descifrar DPAPI operativo ni conectarse a SQL/API real.
Supervisor preparara entorno y credenciales despues de revisar el codigo; un
paquete posterior ejecutara QA real secuencial sin compartir estado concurrente.

## Ownership exclusivo

- frontend/scripts/patients-real-qa.cjs (nuevo)
- frontend/tests/patients-real-qa.test.ts (nuevo)

No otros archivos, dependencias o producto. Si necesitas otra ruta, consulta por
Orca. Conservar todos los archivos anteriores y ocho SHA A/R1; baseline de fuente
antes/despues, sin limpieza/reset/stash/commit/push/main ni FactuEz. Supervisor
unico escritor de docs, tablero, decisiones, revisiones y validacion. Leer
D:/Mavric/Health Project/AGENTS.md, frontend/AGENTS.md y contratos PAC-01-A.md/R1.

## Herramienta de QA real

Reutilizar Playwright/Edge instalado, api de navegador cookie/CSRF, selectores y
contratos revisados. No interceptar ni simular respuestas reales. La herramienta
consume configuracion de credenciales SOLO por stdin JSON en memoria; nunca por
argv/env/archivo de configuracion, no localStorage/sessionStorage, HAR/traces,
storageState ni dumps. No guardar input ni objeto usuario/sesion en reportes.
Sin screenshot de login/contraseñas ni console/errors con cargas sensibles.
Reportes solo nombres de controles, status y IDs/identificadores QA del propio
run; errores sanitizados y exit no cero en cualquier fallo. Cerrar sus contextos/
navegador al terminar; no administrar servicios/procesos ajenos.

Manifest v1 por stdin:

```json
{
  "schema":"health-patients-real-qa-v1",
  "qaDatabase":"health_project_sqlserver_qa_isolated_20261105",
  "baseUrl":"http://health.localhost:18300",
  "runId":"pacqa-20261109-example",
  "human":{"hostname":"qa-example-a.health.localhost","tenantId":"UUID",
    "email":"owner-a.example@example.test","password":"IN_MEMORY_ONLY"},
  "otherHuman":{"hostname":"qa-example-b.health.localhost","tenantId":"UUID",
    "email":"owner-b.example@example.test","password":"IN_MEMORY_ONLY"},
  "animal":{"hostname":"qa-example-v.health.localhost","tenantId":"UUID",
    "email":"owner-v.example@example.test","password":"IN_MEMORY_ONLY"}
}
```

Validate before launching: exact schema/database, base only http://health.localhost:18300
sin auth/path/query/hash alternativos, hostname unico con prefijo qa- y sufijo
.health.localhost sin DNS externo, tenant UUID canonico distinto por entrada,
emails .example.test, passwords no vacios, runId seguro/acotado y prefijo pacqa-.
No escribir credenciales en fallos de validacion. Verificar HostContext remoto
coincide exactamente con hostname/tenantId/dominio esperado antes de negocio.
Usar host resolver rules limitadas a health.localhost y *.health.localhost.

Default --readonly: permitir login/logout de navegador y GET necesarios, bloquear
otros metodos de negocio mediante route.abort. Recorrer directorio, consulta,
detalle administrativo y paginacion si existe. No usar datos demo. No afirmar
comprobacion de escritura, persistencia o SQL grants en este modo.

Solo flag explicito --allow-synthetic-writes habilita recorrido mutante posterior
aprobado. Se prepara codigo ahora, no se usa contra entorno real en este Dispatch.
Crear fixtures por API HTTP existente cookie+CSRF (no SQL directo) y minimo una
alta humana y animal desde UI. Identificadores/nombres deterministas por runId
y dominio, prefijo PACQA; nunca modificar registros ajenos o de otros runs.
Antes de POST consultar identificador exacto y contrastar nombre/dominio/tenant;
si existe valido, reusar sin duplicar. Colisiones inesperadas o resultado incierto
detienen el run sin retry/cleanup/compensacion. Reinicio debe reconciliar por
identificador y estado antes de continuar; no resetear fixtures ni datos previos.
Puedes reducir matriz si hace falta, pero no omitir silenciosamente un criterio:
escalar alcance o prerequisito que no puedas garantizar en estas dos rutas.

## Recorrido posterior que debe quedar preparado

1. Login en host correcto, leer directorio/ficha desde API real; sin token JS
   persistido; tenant/dominio/identidad remotos concordantes.
2. Alta humana y animal desde UI y recuperacion tras reload/nuevo contexto de
   navegador y login; confirmar revisions, identificador/contacto/especie.
3. Preparar21 registros HUMAN del mismo run para paginacion (lookahead21,20visibles,
   segunda pagina y busqueda); HTTP preparatorio con CSRF permitido, sin tablas.
4. Editar ficha con campos opacos contact/allergies sembrados por API y verificar
   que se preservan. Dos contextos obtienen misma revision: primera escritura
   confirma, segunda409 conserva borrador, recarga explicita usa revision nueva.
5. Crear con identificador duplicado409 y recuperar borrador segun R1, sin otra
   peticion hasta nueva confirmacion manual. No forzar fallos500 en servidor real.
6. Segundo tenant humano no ve IDs del primero (HTTP404); una sesion no se reutiliza
   para otro host (401); dominios HUMAN/ANIMAL se mantienen separados. Verificar
   API junto a UI, sin atribuir esto a permisos SQL/JDBC que no se vuelven a probar.
7. Capturas SOLO de fixtures propias sinteticas en escritorio1440/movil390,
   incluidos formulario/conflicto; no overflow de pagina, controles accesibles.
   No capturar directorios historicos con registros de otro run.

## Pruebas y entrega

Tests offline relevantes de manifest/guardas, redaccion, politica readonly,
decision reusar/crear/stop por colision y resultado incierto. Exportar helpers
puros desde CJS si facilita probarlos, con CLI detras de require.main; no ejecutar
browser/red al importar modulo. Sintaxis Node, TypeScript y suite frontend deben
pasar; no hace falta repetir builds/demo ya aceptados si no cambia producto.
No mocks presentados como resultados reales. La entrega es herramienta preparada,
no recorrido ejecutado. Informe TEMP con hashes, baseline/delta, comandos/exit,
prerrequisitos y limites. Ack todos los lotes antes de worker_done; EN_REVISION
hasta aceptacion independiente. Conservar sesion retenida para ejecucion posterior.
