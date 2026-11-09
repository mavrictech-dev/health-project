# PAC-01.A: directorio y ficha administrativa con API real

Contrato del supervisor, 2026-11-09. Depende de INT-01, ORG-01 y A68 aceptadas
en su alcance local. No cierra PAC-01 completo: vinculos, responsables y recorrido
asistencial se encargaran por separado. TLS A69 conserva su bloqueo independiente.

## Objetivo y arquitectura

Conectar `/app/pacientes` al shell live existente para listar, buscar, paginar,
consultar, crear y editar pacientes administrativos. La demo conserva su circuito.
Usar `api` existente (cookie HttpOnly, CSRF, expiracion y correlacion). Ningun
acceso a SQL desde frontend ni cambio a contratos HTTP, Java o migraciones.
Datos y permisos proceden del servidor; no usar fixtures/demo/localStorage como
fuente de pacientes. El host determina tenant y dominio HUMAN/ANIMAL.

Lectura: ADM/REC/PRO/ASI/AUD en host tenant y sesion coincidente. Escritura:
ADM/REC/PRO, sujeta ademas al rechazo del servidor por modulo/estado. SAD/SOP,
PAC/RES y otros roles no acceden al directorio interno aunque conozcan la ruta.

## Contratos existentes a contrastar antes de implementar

- GET `/patients?query=...&limit=...&offset=...`: array, sin total. Paginas de 20;
  pedir 21 para detectar siguiente, mostrar 20 y avanzar offset20. No inventar total.
- GET `/patients/{id}`: ficha actual del tenant. Proyeccion SQL Server camelCase:
  id, tenantId, name, domain, identifier, birthDate nullable, species nullable,
  contact objeto, allergies array de strings, revision entero positivo, createdAt.
- POST `/patients`: name (1..160), domain, identifier (1..100), birthDate nullable
  sin futuro, species nullable (max80), contact objeto, allergies strings(max160).
- PUT `/patients/{id}`: `{expectedRevision,patient}`; revision original, sin auto
  reintento. No enviar tenantId, actor ni campos controlados por servidor.

Contrastar PatientController, Requests, PatientService, SqlServerPatientStore y
V5 en checkout supervisor. El contacto puede contener claves adicionales: editar
telefono/correo sin borrar las claves desconocidas. Conservar alergias, especie,
fecha y otros campos aunque el formulario no los cambie; no sobrescribir con vacios.
Validar identidad, tenant, dominio y forma de respuesta antes de mostrarlos.

## Diseno y aceptacion

Integrar entrada Pacientes y vista dedicada en RuntimeWorkspace, consistente con
sus paneles, formularios laterales, tipografia y tres temas. Busqueda explicita o
debounce con cancelacion; cambios de consulta vuelven a primera pagina. No mostrar
respuestas antiguas al cambiar consulta, ficha, host o identidad. Carga, vacio real,
error recuperable y denegacion visibles; teclado y etiquetas accesibles.

Alta/edicion con revision previa a confirmar, boton bloqueado durante envio y
exito solo ante respuesta valida. Conservar borrador al fallar. En409 mostrar
conflicto y ofrecer recargar ficha explicitamente; no sustituir la revision ni
sobrescribir automaticamente. En error ambiguo de alta (red/5xx/respuesta invalida)
bloquear reenvio automatico y guiar a comprobar el directorio: POST no garantiza
idempotencia. No afirmar que el alta fallo si el resultado es desconocido.
Edicion conserva borrador hasta resolver la respuesta; no repetir escrituras.

HUMAN/ANIMAL se obtiene del host; especie solo aplica a animal. No inventar
responsables, vinculos de portal ni historia clinica. La ficha administrativa no
presenta datos demo ni accesos a modulos aun no integrados. No incluir datos de
pacientes en console/logs, URL de busqueda persistida o almacenamiento navegador.

Escritorio1440 y movil390: sin overflow de pagina; tabla con scroll interno o
tarjetas; panel/formulario navegables y estados de carga/error/conflicto legibles.

## Ownership exclusivo del programador

Solo estas rutas dentro de su worktree separado:

- frontend/src/components/runtime-patients.tsx (nuevo)
- frontend/src/lib/patient-types.ts (nuevo)
- frontend/src/styles/live-patients.css (nuevo, importar desde componente)
- frontend/src/lib/live-routes.ts
- frontend/src/components/runtime-workspace.tsx
- frontend/tests/patients.test.ts (nuevo)
- frontend/tests/live-shell.test.ts (solo nuevos casos de permisos/ruta)
- frontend/scripts/patients-live-qa.cjs (nuevo)

No tocar otros archivos. Para ampliar ownership, consultar por Orca primero.
Supervisor unico escritor de documentos/decisiones/tablero/revision/evidencia.
No commit, push, main, reset, stash, limpieza masiva, SQL mutante, servicios,
certificados, cuentas globales ni secretos. FactuEz queda fuera del alcance.

Antes de editar leer AGENTS.md absoluto del supervisor y frontend/AGENTS.md,
la guia Next instalada y este contrato. Verificar raiz/rama/worktree/cambios.
La rama worker sigue en0b24487 y conserva trabajo historico sin commit: no asumir
HEAD equivalente al producto publicado dee42d1. Las rutas frontend compartidas
de este paquete se compararon iguales normalizando CRLF/LF. Guardar baseline de
hashes de archivos previos y demostrar que no se modifico nada fuera de ownership.
Leer backend actual desde D:/Mavric/Health Project; no sincronizar todo el worktree.

## Validacion y entrega

Ejecutar check TypeScript, pruebas frontend y build live; demo build/QA por turno
separado si comparte salida. Pruebas relevantes de permisos, shape/tenant/dominio,
paginacion sin total, preservacion de contacto y revision, cancelacion/respuestas
viejas, 401/403/409 y resultado ambiguo. El script Playwright debe soportar endpoint
local sintetico configurable, sin credenciales en codigo/argv/env persistente,
sin capturar tokens/cookies/cuerpos sensibles en reportes.

En esta fase no arrancar SQL/backend ni acceder a DPAPI operativo: servicio QA
observado Stopped el9nov. Se admite harness de navegador con respuestas simuladas
solo como prueba de contrato, identificado expresamente. Preparar recorrido real
reutilizable sin ejecutar escrituras; QA real SQL/HTTP/visual se delegara despues
de revision y preparacion supervisora del entorno. No llamar validacion real a mocks.

Entregar resumen, archivos/hashes, delta sobre baseline, comandos/exit/resultados,
evidencia de desktop/movil, limites y pendientes. Un check/build/test inesperadamente
no cero requiere corregir o reportar bloqueo; no worker_done succeeded ocultandolo.
Procesar todos los lotes Orca y ack cada deliveryId antes del siguiente check y
antes de worker_done. Informe del programador queda EN_REVISION hasta aceptacion
independiente del supervisor. Conservar terminal/sesion para correcciones.
