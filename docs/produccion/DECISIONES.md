# Decisiones y contratos de integracion

## D-01: alcance y autoridad

Nuevo encargo directo del usuario amplia setup a ejecucion del plan. Misma pareja,
cuentas, Run y worktree. El supervisor mantiene estos documentos; programacion y
QA se delegan secuencialmente. Prohibido integrar producto en main, commit/push o
publicar. Se revisan diffs y se ejecutan comprobaciones sobre worktree de entrega.

## D-02: arquitectura y datos

Mantener monolito Java21/SpringBoot4.1.1, JDBC, MySQL8.4 y SP transaccionales.
Next16.4.3 estatico; mock se selecciona en build y exporta out-demo; live exporta
out y usa /api same-origin. No sustituir contratos live por modelos del store.
Tenant desde Host validado; SAD plataforma no obtiene historia clinica. Navegador
con cookie HttpOnly host-only y CSRF; token solo en memoria. Sin tenant arbitrario
en cabecera/body. Preferencias visuales pueden persistir, datos de negocio no.

## D-03: QA-01 aislada

Proyecto Compose exclusivo health-project-qa, archivo compose.qa.yaml independiente,
puertos loopback 18080/13307/18025 y volumen propio; imagen backend con etiqueta
qa. Secretos sinteticos en tmp/qa/.env, nunca .env existente. Datos example.test.
Runner stdlib Python con bloqueo exclusivo COMPARTIDO entre worktrees del mismo
Git common-dir para todas las acciones del stack o estado global; secretos por
worktree. Un lock local no basta porque Compose y puertos son comunes. Pruebas
API, identidad y navegador serializadas. No ejecutar
verify-persistence sobre stack normal. No down -v ni borrar volumen/datos.
Sin daemon disponible: validar configuracion y tests del runner, registrar bloqueo
de ejecucion real y continuar frontend/contratos independientes. No arrancar ni
reiniciar recursos de otros proyectos.

## D-04: ARQ-02 contratos actuales por recurso

Fuente autoritativa: controladores/Requests.java/servicios y migraciones existentes;
docs/backend/02 se complementa con docs/backend/04 para cookie/CSRF. Ejemplos
sinteticos, UUID a sustituir por respuesta del servidor, sin credenciales reales.

| Recurso | Entrada/respuesta y limites actuales | Revision / idempotencia |
| --- | --- | --- |
| Contexto/sesion | GET /public/context → platform/name/hostname; GET /auth/browser/session → user{id,name,email,roles,tenantId},csrfToken,expiresAt | Cookie HttpOnly host-only; 401 borra sesion local; error de red no se presenta como credenciales incorrectas |
| Clientes | GET /platform/tenants?limit=200 → array; POST Tenant → tenant con id/hostname/url/planVersion/cupos/consumo; GET /{id} y /configuration | Sin offset/cursor actualmente; listado acotado debe decirlo. Alta atomica SP, slug unico, sin clave idempotente generica; no auto-retry POST |
| Planes | GET /platform/plans → array de versiones vigentes; POST/PUT Plan → version creada; status DRAFT/PUBLISHED/ARCHIVED, importes enteros minor PEN | Crear version no cambia contratos previos; API actual no acepta expectedRevision. Edicion concurrente pendiente de contrato posterior |
| Suscripcion | PUT /platform/tenants/{id}/subscription con planId,cycle,branchQuota,professionalQuota,specialtyQuota → configuracion | SP rechaza cuotas inferiores al consumo; no expectedRevision actual, no simular proteccion optimista desde UI |
| Sedes/equipo | POST/PUT branches; PUT members con userId O user, roles,status,branches,specialties | Asignaciones/cupos atomicos SP; identidad global y membresias por tenant |
| Pacientes | GET /patients?query=&limit=50&offset=0 → array; PUT /{id} con expectedRevision y patient | Mostrar continuacion sin inventar total; 409 mantiene borrador. Link contiene userId,relationship,active,scopes |
| Agenda | GET from/to UTC max93 dias, hasta200; POST patientId/branchId/professionalId/specialtyCode/startsAt/endsAt/status/service/note | Idempotency-Key ASCII8-100 estable por intencion; PUT incluye expectedRevision; misma clave+otro payload409 |
| Atencion/entradas | POST /encounters; GET /{id} con profileSnapshot/entries; note/finalize; entries {kind,payload} | Nota/finalize con expectedRevision; cierre y firma son acciones diferentes; entradas validadas por perfil |
| Historia/documentos | Historia limits 200/1000/200; documentos hasta200; PUT documento {expectedRevision,operation,content?} | SAVE/SIGN/PUBLISH/WITHDRAW; adenda conserva originalId; firma interna SHA256, no certificada |
| Portal | /portal/patients; /patients/{id}/documents,appointments,balance | PAC/RES y vinculo vigente por APPOINTMENTS/DOCUMENTS/BILLING, no seleccionar tenant en body |
| Caja/stock/transferencia | Importes enteros minor, cantidades segun DTO; SP de negocio | Clave idempotente donde exige controlador; reconsultar resultado tras fallo ambiguo |
| Auditoria/monitor/soporte | /trace eventos/requests con cursor y hasMore; /monitor; /support | Modo y pasos soporte con expectedRevision; sin datos sensibles en logs |

Ejemplo de alta administrativa (payload segun Requests.Tenant, rol SAD en host
plataforma; owner y ownerUserId son mutuamente excluyentes):

```json
{
  "name": "QA Clinica Aurora", "slug": "qa-aurora-ejemplo", "kind": "CLINIC", "domain": "HUMAN",
  "owner": {"name":"QA Propietario","email":"owner@example.test","password":"Solo-ejemplo-no-usar-12","domain":null,"credential":null},
  "timezone":"America/Lima", "branchName":"Central", "address":"Direccion ficticia",
  "specialties":["H_GENERAL_MEDICINE"],
  "subscription":{"planId":"00000000-0000-0000-0000-000000000003","cycle":"MONTHLY","branchQuota":1,"professionalQuota":1,"specialtyQuota":1}
}
```

El plan y codigo de especialidad se eligen desde catalogos reales compatibles;
el UUID ilustrativo no se fija en producto. DOCTOR humano/animal; VETERINARY
solo ANIMAL; otros tipos actuales HUMAN. Estados tecnicos se traducen al mostrar,
se envian enums del backend. No mapear implicitamente IDs del mock.

Checks.password exige minimo12 caracteres y maximo72 bytes UTF8. No confundir
bytes con caracteres en validacion UI. Password solo en memoria del formulario,
sin incluirlo en revision, storage, capturas o logs. Seguimiento msg_d1203f871cfd.

Errores application/problem+json:

```json
{"type":"urn:health-project:error:concurrent_change","title":"CONCURRENT_CHANGE","status":409,"detail":"Otra operacion cambio el recurso.","instance":"/api/appointments","requestId":"qa-ejemplo"}
```

400 valida datos;401 sesion ausente/vencida;403 rol/modulo/suspension;404 referencia
no disponible en contexto;409 duplicado/revision/estado/cupo;429 limite;503 modo
operativo/recurso no disponible. UI conserva formulario ante error, muestra
detalle y requestId sin exponer SQL/credenciales. No anunciar exito antes de
respuesta confirmada. GET cancelado por navegacion no se trata como fallo API.

## D-05: primer corte INT-01 y SAAS-01

INT-01.A endurece shell real: rutas explicitas/roles servidor, carga/vacio/error,
distincion error de sesion y red, CSRF y ausencia de datos demo en operaciones.
Preferencias visuales live separadas del store de negocio demo. /demo sigue
explicita, temas y paneles derechos preservados.

SAAS-01.A integra listado/detalle real de clientes, catalogo real de planes y
alta administrativa con primera sede/especialidades/cuotas, reutilizando
POST /platform/tenants. No sustituir por registro publico ni fingir guardado.
Primer corte no edita suscripciones existentes ni planes concurrentes mientras
no se cierre su revision esperada. Parent SAAS-01 permanece parcial hasta validar
persistencia nueva sesion/otro navegador, duplicados/rollback/cupos y aislamiento
contra MySQL. Pruebas de red interceptada sirven para UI/contrato, nunca para
aprobar esa integracion. No abrir acceso clinico a SAD/SOP.

## D-06: rutas estaticas SOP

Pregunta msg_da3ca44857d2 del programador: faltaban tres rutas de operacion en la
exportacion. Respuesta msg_1a9564afc663 autoriza SOLO añadir /operacion/soporte,
/operacion/trazabilidad y /operacion/monitor en routes.json y su generador si
corresponde, sin cambiar Next config. SOP conserva consola propia y sin clientes.
Debe verificarse entrada directa y exportacion (incremento esperado de tres rutas,
contar resultado real del build). No ejecutar generador sobre otros artefactos
fuera del ownership. El supervisor no edita archivos asignados al programador.

Inspeccion adicional: generador calculaba64 rutas frente a78 en routes.json,
omitiendo14 rutas runtime ya existentes. Seguimiento msg_3dc27a5ab1ea autoriza
conservar esas14 y sumar las3 SOP mediante lista runtime explicita, sin reescribir
spec.json o modificar las78 rutas previas. Se revisara diff y build final.
