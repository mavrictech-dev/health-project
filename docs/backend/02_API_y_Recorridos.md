# API y recorridos de integración

Fecha: 14 de octubre de 2026. Los ejemplos son datos ficticios y los precios iniciales son configurables.

## Convenciones

Prefijo `/api`. JSON con propiedades `camelCase`, fechas `YYYY-MM-DD` e instantes ISO 8601 en UTC. UUID canónicos para entidades. Sesión `Authorization: Bearer <accessToken>` emitida por el login del mismo host. Una sesión de plataforma no abre historias clínicas ni funciona en un tenant.

Las escrituras con revisión envían `expectedRevision`. Citas, caja, movimientos de stock y transferencias exigen `Idempotency-Key` de 8 a 100 caracteres ASCII (letras, números, `_`, `.`, `:`, `-`). Repetir la misma clave y contenido devuelve el recurso existente; otros datos con la misma clave causan 409. No se debe aplicar un reintento automático indiscriminado a otros POST.

## Identidad

| Método y ruta | Función |
| --- | --- |
| GET `/public/context` | Resuelve plataforma o cliente desde el host; sin secretos |
| POST `/auth/login` | `{email,password}`; devuelve token, vencimiento y usuario |
| POST `/auth/invitations/accept` | Credenciales de identidad + host del cliente; activa membresía INVITED |
| GET `/auth/me` | Identidad y roles de la sesión actual |
| DELETE `/auth/session` | Revoca la sesión actual |
| PUT `/auth/password` | `{currentPassword,newPassword}`; revoca todas sus sesiones |

Una persona que trabaja en varios clientes conserva una identidad global y membresías independientes. Inicia una sesión por cliente. Roles, estado y vínculos del portal se reevalúan por solicitud; una membresía INACTIVE invalida el acceso del token aunque todavía no haya vencido.

## Consola general y organización

| Ruta | Operaciones |
| --- | --- |
| `/platform/plans` | GET catálogo / POST nuevo; PUT `/{id}` crea una versión |
| `/platform/users` | GET identidades / POST nueva |
| `/platform/tenants` | GET clientes / POST alta atómica; GET `/{id}` detalle |
| `/platform/tenants/{id}/status` | PUT TRIAL, ACTIVE, SUSPENDED o CANCELLED con motivo |
| `/platform/tenants/{id}/configuration` | GET configuración, sedes, áreas, equipo y facturas SaaS |
| `/platform/tenants/{id}/subscription` | PUT plan, ciclo y capacidades |
| `/platform/tenants/{id}/branches` | POST sede; PUT `/{branch}` |
| `/platform/tenants/{id}/areas` | POST área; PUT `/{area}` |
| `/platform/tenants/{id}/members` | PUT identidad existente o nueva, roles y asignaciones |
| `/platform/tenants/{id}/specialties` | PUT especialidades habilitadas |
| `/platform/tenants/{id}/invoices/{invoice}/payment` | POST registro interno del pago SaaS |
| `/platform/specialties`, `/platform/audit` | GET catálogo completo / auditoría administrativa |
| `/tenant/configuration`, `/tenant/plans` | GET configuración propia / planes compatibles |
| `/tenant/subscription`, `/tenant/specialties`, `/tenant/members` | PUT administración propia |
| `/tenant/branches`, `/tenant/areas` | POST; PUT `/{id}` |
| `/tenant/members/lookup?email=...` | GET busca una identidad por email exacto (ADM) |
| `/tenant/branches`, `/tenant/professionals`, `/tenant/specialties/catalog` | GET directorios y perfiles del ámbito |

El SAD opera la consola desde `health.localhost` o `admin.health.localhost`. El ADM administra su propio cliente. Un rol administrativo no otorga automáticamente permisos de consulta clínica. PRO, ASI, REC, DIA, FAR, ALM, CAJ, AUD, PAC y RES representan profesional, asistente, recepción, diagnóstico, farmacia, almacén, caja, auditor, paciente y responsable.

Ejemplo de alta en `POST /platform/tenants`:

```json
{
  "name": "Hospital de ejemplo",
  "slug": "hospital-ejemplo",
  "kind": "HOSPITAL",
  "domain": "HUMAN",
  "owner": {
    "name": "Administrador de ejemplo",
    "email": "admin@example.test",
    "password": "Una-clave-de-ejemplo-12",
    "domain": null,
    "credential": null
  },
  "timezone": "America/Lima",
  "branchName": "Central",
  "address": "Dirección de ejemplo",
  "specialties": ["REEMPLAZAR_CON_CODIGO_DEL_CATALOGO"],
  "subscription": {
    "planId": "00000000-0000-0000-0000-000000000003",
    "cycle": "MONTHLY",
    "branchQuota": 3,
    "professionalQuota": 20,
    "specialtyQuota": 30
  }
}
```

La respuesta incluye `hostname` y `url`. Para un propietario existente se envía `ownerUserId` en lugar de `owner`. Los tipos son DOCTOR, CLINIC, HOSPITAL, VETERINARY, DENTAL y SPECIALTY_CENTER. DOCTOR puede ser HUMAN o ANIMAL y tiene una identidad clínica. VETERINARY exige ANIMAL. Sedes externas para un independiente representan lugares de atención; no conceden acceso a la historia de otro cliente.

## Pacientes, agenda y atención

| Método y ruta | Función |
| --- | --- |
| GET/POST `/patients` | Directorio paginado / registrar paciente |
| GET/PUT `/patients/{id}` | Consultar / `{expectedRevision,patient}` |
| GET `/patients/{id}/history` | Historia compartida entre sedes, limitada y auditada |
| PUT `/patients/{id}/links` | Vínculo de portal `{userId,relationship,active,scopes}` |
| GET `/appointments?from=...&to=...&branchId=...` | Agenda por rango de hasta 93 días |
| POST `/appointments` | Reservar con clave de idempotencia |
| GET/PUT `/appointments/{id}` | Consultar / cambiar estado o reprogramar con revisión |
| POST `/encounters` | `{patientId,branchId,specialtyCode}` inicia atención |
| GET `/encounters/{id}` | Atención y entradas con copia del perfil |
| PUT `/encounters/{id}/note` | `{expectedRevision,note}` guarda evolución |
| POST `/encounters/{id}/entries` | Captura clínica validada por tipo y perfil |
| POST `/encounters/{id}/finalize` | `{expectedRevision,note}` cierra atención |

Paciente: `{name,domain,identifier,birthDate,species,contact,allergies}`; los animales requieren especie. Identificador único dentro del cliente. Cita: `{patientId,branchId,professionalId,specialtyCode,startsAt,endsAt,status,service,note}`; duración entre 5 y 480 minutos y profesional asignado a sede y especialidad.

Estados de cita: REQUESTED → RESERVED → CONFIRMED → WAITING → CALLED → IN_CARE → COMPLETED. Recepción puede cancelar antes de la cola; WAITING y CALLED pueden terminar en WITHDRAWN. La reprogramación devuelve una cita reservada a RESERVED. La API protege la ocupación de un profesional global incluso entre clientes, sin exponer los datos de la cita del otro cliente.

Entradas clínicas: `{kind,payload}` con EVALUATION, OBSERVATION, ANNOTATION, ORDER o PRESCRIPTION. EVALUATION usa `{profileCode,values}` con los campos y opciones del perfil. OBSERVATION usa `{parameter,value,unit}`. ANNOTATION usa `{component,structure,condition}` y solo admite familias del perfil de la atención; los gráficos dentales requieren el módulo DENTAL. Los puntos o estructuras adicionales pueden guardarse en el payload, pero la validación geométrica exhaustiva por gráfico sigue pendiente. ORDER usa `{type,description}`. PRESCRIPTION exige `{medication,dose,route,frequency,unit,quantity}`.

Una atención finalizada conserva su nota y entradas. Las aclaraciones posteriores se representan con documentos/adendas, sin modificar el original firmado.

## Documentos y portal

| Ruta | Función |
| --- | --- |
| GET `/documents?patientId=...` | Documentos del paciente |
| POST `/documents` | `{patientId,encounterId?,title,type,content,originalId?}` |
| GET/PUT `/documents/{id}` | Consulta / `{expectedRevision,operation,content?}` |
| GET `/portal/patients` | Solo pacientes vinculados a esta cuenta |
| GET `/portal/patients/{id}/documents` | Firmados, publicados y vigentes |
| GET `/portal/patients/{id}/appointments` | Citas del paciente vinculado |
| GET `/portal/patients/{id}/balance` | Saldo con alcance BILLING y módulo FINANCE |
| POST `/portal/appointments` | Solicitud REQUESTED con alcance APPOINTMENTS |

Operaciones documentales SAVE, SIGN, PUBLISH y WITHDRAW. La firma interna registra usuario, instante y SHA-256 del contenido. No representa una firma certificada por un proveedor. La adenda usa `originalId` de un documento firmado del mismo paciente. Publicación requiere vínculo vigente con alcance DOCUMENTS; revocar el vínculo retira la lectura de inmediato.

## Caja, inventario y hospital

| Ruta | Función |
| --- | --- |
| GET `/finance/patients/{id}` | Saldo clínico en unidades menores de PEN |
| GET `/finance/patients/{id}/movements` | Movimientos de caja |
| POST `/finance/movements` | `{patientId,kind,amountMinor,title,parentId?}` + clave |
| GET/POST `/inventory/lots` | Lotes / `{branchId,name,lot,expiry,unit}` |
| POST `/inventory/movements` | `{lotId,kind,quantity,patientId?,prescriptionId?}` + clave |
| GET/POST `/inventory/transfers` | Transferencias / `{lotId,destinationBranchId,quantity}` + clave |
| POST `/inventory/transfers/{id}/receive` | Recepción idempotente |
| GET `/inventory/prescriptions` | Pendientes clínicos visibles a farmacia, sin historia completa |
| GET/POST `/hospital/resources` | Recursos / `{branchId,name,kind}` BED humano o CAGE animal |
| GET/POST `/hospital/admissions` | Estancias / `{patientId,resourceId,reason}` |
| POST `/hospital/admissions/{id}/discharge` | Egreso con `expectedRevision` |

Caja utiliza CHARGE, PAYMENT y REFUND; devoluciones referencian un pago del mismo paciente y los pagos no exceden el saldo. Los comprobantes SaaS pertenecen a otra tabla y flujo.

Stock admite RECEIVE y DISPENSE. Dispensar exige una prescripción del mismo paciente, medicamento y unidad iguales a los del lote, vigencia y cantidad suficiente; varias dispensaciones no superan lo prescrito. Transferir descuenta en origen y recibir suma una sola vez en destino. Antes de desactivar una sede deben resolverse su atención, citas, estancias, procesos, transferencias y stock pendientes.

## Procesos y auditoría

GET `/workflows/definitions` lista procesos permitidos por rol y módulo. GET `/workflows?type=...` lista casos del cliente. POST `/workflows` crea `{type,branchId,patientId?,title,payload}` en DRAFT. GET `/workflows/{id}` devuelve historial. POST `/workflows/{id}/steps` usa `{expectedRevision,status,payload}` y valida rol y transición. Estados y payload de cada revisión se conservan.

Hay 15 definiciones iniciales: laboratorio, imagen, cirugía, anestesia, urgencia, sesión especializada, transfusión, trasplante, reproducción, población veterinaria, seguimiento, presupuesto, compra, integración y soporte. El motor persiste el recorrido; los protocolos específicos y los conectores externos todavía necesitan implementación especializada.

GET `/audit?limit=100` devuelve auditoría propia a ADM/AUD. La consola de plataforma recibe únicamente eventos administrativos en su endpoint; las notas clínicas no se incluyen en esos metadatos.

## Recorrido para conectar el frontend

1. Resolver `/public/context` al abrir el host. Elegir navegación de plataforma o cliente.
2. Autenticar, conservar token en memoria y cargar `/auth/me`. Cerrar sesión al recibir 401; explicar 403 y 409 con el detalle del error.
3. SAD: crear el cliente y usar el `url` retornado. ADM: cargar configuración, sedes, áreas, profesionales y especialidades.
4. Recepción: registrar paciente, reservar cita y actualizar la cola con revisión.
5. Profesional: iniciar atención, renderizar `profileSnapshot`, guardar capturas y finalizar.
6. Profesional: crear, firmar y publicar documento. Portal: consultar solo sus vínculos y documentos vigentes.
7. Caja/farmacia: cargar movimientos con claves estables por intención del usuario; refrescar saldos y stock después de confirmar.
8. Hospital/procesos: seguir revisiones y estados autorizados; recargar ante conflicto.

La adaptación se hará por módulo. La presentación actual continuará siendo mock hasta conectar cada flujo y probarlo contra la API.
