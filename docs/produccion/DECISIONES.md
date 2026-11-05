# Decisiones y contratos de integracion

## D-01: alcance y autoridad

Nuevo encargo directo del usuario amplia setup a ejecucion del plan. Misma pareja,
cuentas, Run y worktree. El supervisor mantiene estos documentos; programacion y
QA se delegan secuencialmente. Prohibido integrar producto en main, commit/push o
publicar. Se revisan diffs y se ejecutan comprobaciones sobre worktree de entrega.

## D-02: arquitectura y datos

DECISION DE MOTOR SUSTITUIDA por D-09 (aclaracion directa del usuario, 2026-11-03).
Objetivo vigente: monolito Java/Spring, SQL Server y 100 % de persistencia mediante
SP parametrizados, incluidas lecturas, sesiones, auditoria y comprobaciones de salud.
MySQL8.4 describe el backend heredado y no el objetivo arquitectonico.
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

Revision SAAS-01.A aceptada para UI/contrato: ocho archivos frontend, propietario nuevo, alta de primera sede/perfiles/cuotas, lista y detalle/configuracion. La seleccion de perfiles no habilita uso clinico. No agregar edicion de suscripciones/planes sin revision esperada, cobros, correo real ni confirmacion de pago. Siguiente corte desbloqueado: lectura de equipo en ORG-01.B; correo, pacientes y uso clinico conservan sus dependencias.

## D-07: primer corte ORG-01

Implementar una ruta tenant ADM para lectura de configuracion y alta de sede propia, mostrando cuotas del servidor como referencia y dejando al SP la autorizacion atomica. No editar membresias/suscripciones ni enviar invitaciones en ORG-01.A: esas escrituras carecen de expectedRevision/idempotencia y no deben fingir control concurrente; IAM/correo sigue separado. Solo lectura del equipo existente.

## D-08: ORG-01.A y lectura de equipo

ORG-01.A aceptada para alta de sede propia y visualizacion de cuotas/sedes con autoridad final del SP. Continuar el equipo como vista de solo lectura: los miembros vienen de /tenant/configuration, sin exponer datos mas alla de nombre/roles/estado/asignaciones necesarias. No modificar membresias mientras PUT /tenant/members carezca de expectedRevision, ni iniciar invitaciones/correo.


Actualizacion D-08 tras ORG-01.B: se acepta la consulta de miembros en solo lectura con proyeccion de nombre/roles/estado/propietario y asignaciones por nombres. Correo/credenciales/IDs no se exponen en la vista; no se hacen cambios a membresias, invitaciones ni correo. ORG-01 queda integrada solo en frontend interceptado; validar API, persistencia y transacciones reales cuando el entorno QA tenga daemon disponible, antes de completar el parent o abrir operaciones clinicas.


## D-09: SQL Server y persistencia exclusivamente mediante SP

El 2026-11-03 el usuario aclara que toda la persistencia debe cumplir docs/Arquitectura_Health_Project.md, especialmente secciones 2 y 9: SQL Server y SP para lecturas, escrituras, sesiones, auditoria y health checks. Esta instruccion directa prevalece sobre la frase contradictoria de PLAN_EJECUCION_PRODUCCION.md:22 y las decisiones anteriores que mantuvieron MySQL. El supervisor reconoce que debio exponer la contradiccion antes de aceptar el motor heredado como objetivo.

El backend actual no cumple: driver/Flyway/URL/Compose son MySQL; Sql.rows/one/optional ejecutan lecturas SQL directas; Sql.call establece variables de sesion MySQL antes de llamar SP. Inventario textual: 11 migraciones, 60 declaraciones CREATE PROCEDURE (53 nombres distintos por redefiniciones), 116 llamadas a helpers de lectura en 22 archivos Java. No es una medicion de cobertura ni prueba runtime.

Corregir implica portar esquema, SP, errores, tipos/JSON, concurrencia y contratos de resultados; sustituir consultas Java por llamadas parametrizadas a SP; separar cuenta de migracion de cuenta runtime con EXECUTE solo sobre SP aprobados; adaptar entorno/suites. Una sustitucion del conector no basta. Diseno y criterios en MIGRACION_SQLSERVER.md. No se modifica el plan/README protegidos en esta correccion; se registra aqui su discrepancia.

Las aceptaciones frontend anteriores conservan su evidencia de UI/HTTP interceptada. Ninguna valida SQL Server ni conformidad de persistencia. Se reabre ARQ-02 para el contrato fisico y queda bloqueada la aceptacion integral de QA/INT/SAAS/ORG hasta demostrar el nuevo backend. No extender funcionalidades dependientes de DB antes de cerrar el primer recorrido SQL Server. No borrar volumen MySQL, migraciones historicas o datos existentes.


## D-10: ejecucion de la migracion y QA2022 local

El usuario ordeno aplicar la migracion con el programador. Se conserva Run run_624b9269b491, rebind generation3 al coordinador restaurado term_0a40d921-c692-4112-ace7-e6023edef4e8. Programador restaurado term_820779be-5e60-4a84-99f9-eaa999841df4, mismo session01a19e4c-15af-74e0-a1b9-75fc7093b98f; /status confirma mendozadeafabisa@gmail.com. No se lanzo otra sesion ni se cambio cuenta global.

Servicio MSSQLSERVER ya estaba activo: SQLServer2022 Developer16.0.1000.6, WindowsOnly=1; cuenta Windows actual tiene sysadmin. No se cambio el modo de autenticacion ni se inicio/reinicio servicio alguno. Supervisor comprobo ausencia del destino y creo solamente health_project_sqlserver_qa_20261103, compat160 y marca health_project_scope. Esta base sintetica exclusiva es el destino de las pruebas; ninguna base existente de usuarios esta autorizada como destino. No confundir pruebas ejecutadas como administrador con prueba de permisos runtime minimos; estas ultimas requieren usuario efectivo restringido y pruebas negativas.

Secuencia: esquema/semillas nuevos, SP por familias, adaptador JDBC y conversion de Java, despues configuracion/entorno/suites. El cambio de datasource activo se integra solo cuando las familias esten migradas. El paquete inicial amplio fallo sin cambios; SQL-01.A1 acotado produjo semilla parcial y se reintento el mismo Task con instrucciones de completar esquema. No aceptar el estado parcial como migracion. Cada entrega tendra revision de SQL y ejecucion en motor real; conservar migraciones MySQL historicas inactivas y datos existentes.


## D-11: contexto de SP y outbox en migracion

Acuerdo de A2: question msg_2263398396e2 / reply msg_7404c9852589. usp_request_context sustituye completamente contexto hp_* por conexion/operacion (incluido anonimo); scopes REQUEST/IDENTITY/BOOTSTRAP/WORKER elegidos por Spring, nunca body. El bootstrap de administrador requiere principal de setup/migracion distinto, sin grant runtime para elevar identidades aunque pueda declarar ese scope.

Outbox sin ampliar esquema: UPDATE OUTPUT atomico reclama PENDING/FAILED vencidos e incrementa attempts como claim_version; ack/fail exige id+version+SENDING. Nunca se reclama SENDING automaticamente; resultado SMTP ambiguo queda para conciliacion y no como FAILED reintentable. No prometer exactly-once ni entrega de invitacion. No correo real en esta migracion. Java se adaptara en su paquete, despues de validar SP.


## D-12: contratos de SaaS/organizacion durante migracion

A3 question msg_492154009b96 / reply msg_2711730228f2: helper privado de target valida SAD plataforma o ADM del mismo tenant sin sustituir contexto original. Escritura normal exige OPEN/tenant habilitado/modulo; ajuste administrativo de suscripcion/status por SAD puede operar tenant suspendido para recuperacion explicita sin reactivarlo automaticamente. Timezone IANA se valida en Java con ZoneId.of y se conserva en SQL, sin traducirla a catalogo Windows.

Question msg_247c7169eb2b / reply msg_afa6b0dd469a: registro publico conserva misma TX Spring create -> pending -> tenant_create -> issue. ScopeIDENTITY/hostplataforma/actorNULL, propietario pending activo sin plataforma ni memberships/tenantowner anteriores, cuotas/ciclo servidor. No wrapper nuevo ni marca de conexion que sobreviva rollback; no reanudar identidad existente en esta migracion. DOCTOR exige dominio clinico coherente; otros propietarios pueden tener dominio clinico opcional valido sin recibir PRO automaticamente.


## D-13: alcance observado durante portado clinico/operativo

A4 pregunta msg_b557781e8c28/reply msg_33bfcdbcbbbe: conservar historia longitudinal de mismo tenant y politicas de rama actuales; escrituras revalidan branch/autor, documentos conservan original SIGNED y paciente/encounter propios. Auditoria segura de lecturas portal se integra al SP con TX, sin cuerpos ni tokens. No filtrar por rama lecturas que hoy son tenant-wide por intuicion. Pregunta msg_61ae2b4ad522/reply msg_08ba56409f7d: perfiles DEMO/pending conservan etiquetas y validacion estructural, no se certifican ni bloquean globalmente por una regla nueva durante migracion; solo QA sintetica, ESP-02/PIL profesionales pendientes.

A5 preguntas msg_4a4453edd984 y msg_f21f3f038351, replies msg_444fda704eb2 y msg_cf7c5bcea2ed: no crear mutador de recurso hospitalario ausente ni conditions/requiredData de workflows que el motor actual no contiene. Conservar listados tenant-wide para roles actuales, sin inventar ADM universal; writes mantienen roles/branch/modulo. Finance CAJ/AUD sin exigir PRO. Brechas de producto se conservan explicitas; la migracion no las declara resueltas.

## D-14: cierre de operaciones y proximo corte de auditoria

A5 aceptada por el supervisor tras 29/29 comprobaciones en SQL Server real;
no hay cambio HTTP ni activacion del datasource. Se conserva la distincion entre
SP compilados/ejecutados y runtime completo pendiente. A6 tiene ownership solo
de V7__audit_triggers.sql nuevo. Debe conservar la proyeccion segura de V10 MySQL
y la inmutabilidad de V9, adaptando inserted/deleted a conjuntos de multiples
filas de SQL Server. No se otorga EXECUTE al runtime sobre helpers privados ni
acceso a tablas para facilitar pruebas. Permisos definitivos y Java se tratan
en paquetes posteriores; no configurar otra base, servicio o autenticacion de
instancia para sortear el bloqueo de transporte.

### D-14.A: proyecciones planas y claves completas en A6

Pregunta msg_f4caccd2ae16, Dispatch ctx_4d330d95d46d. Se contrastaron V1,
usp_audit_change/usp_trace_events V3 y V10 historico. Se aprueba mantener
tenant NULL historico para users/plans/plan_versions/tenants/application_state;
support_comments deriva tenant del ticket correspondiente a cada fila/estado,
NULL solo para ticket de plataforma. Un cambio de ticket/tenant debe conservar
procedencia anterior y nueva, sin imputar ambas al tenant actual de la conexion.
La FK no tiene cascade; ticket ausente es error de integridad, no excusa para
degradar un comentario tenant a evento global silenciosamente.

modules/specialties/roles/scopes se representan como *_sha256 sobre UTF8
completo del valor almacenado, NULL preservado. El helper exige proyecciones
planas y el contrato no promete mostrar arrays originales desde la auditoria.
Conservar los restantes campos escalares seguros; no arrays anidados ni JSON
escapado fingiendo valores estructurados. Diferencias de serializacion cuentan
como cambio del valor persistido, sin inventar normalizacion semantica.

Emparejar inserted/deleted por PK completa y tenant, incluidos componentes de
PK compuestas. Cambios de clave/tenant se registran como DELETE anterior e
INSERT nuevo; ningun emparejamiento arbitrario por numero de fila o ID parcial.
Estas adaptaciones se aprueban como contrato de implementacion, no como V7
implementada o validada. Ownership sigue limitado al archivo V7.

### D-14.B: materializacion local UTF8 para corregir R-A6-UTF8

Pregunta msg_43c08eed1310, seguimiento ctx_840acbdaeb78. Se autoriza usar tabla
variable local por trigger con columnas varchar(max) COLLATE
Latin1_General_100_BIN2_UTF8 como destino de asignacion DIRECTA de los valores
NVARCHAR originales. HASHBYTES lee los bytes ya almacenados en esa columna,
sin conversion inline a la pagina de codigo de la DB ni cambios de esquema
persistente. Preservar lado inserted/deleted, PK completa, tenant y NULL; el
resto de proyecciones/joins/contexto/guards no cambia. No helper persistente,
grant ni cambio de collation de base/tabla existente.

Antes de autorizar se probo el enfoque en SQL2022 real: 6/6 casos con bytes,
longitud y SHA256 comparados contra Python independiente (ASCII, vacio, NULL,
texto null, acentos+CJK+emoji y JSON largo16014bytes). Ejemplo corto
C381E4B8ADF09FA6B7 y largo9cd5937d...b2fb6a1 coinciden exactamente. Evidencia
tmp/sqlserver-a6-utf8-materialization-probe.sql/.json. Solo tablas variables,
sin escrituras persistentes. Esto acredita el mecanismo, no la implementacion
final V7: repetir matriz de triggers y before/after tras la correccion.

Referencia primaria consultada: [collation por columna y copia a destino UTF8](https://learn.microsoft.com/en-us/sql/relational-databases/collations/set-or-change-the-column-collation/).

### D-15: separar ejecucion runtime, bootstrap y migracion

Siguiente paquete SQL-01.A7 limitado a V8__execution_permissions.sql y
backend/scripts/verify-sqlserver-permissions.sql nuevos. Roles DB propiedad dbo
hp_runtime_executor y hp_bootstrap_executor; EXECUTE por objeto literal aprobado,
nunca a todo esquema/base/public. Bootstrap recibe solo contexto, exists y create;
no runtime. Helpers internos sin acceso directo, invocacion legitima por cadena
de propiedad. Ambos sin CRUD directo sobre las 37 tablas ni DDL/roles amplios.
No crear logins/usuarios persistentes, credenciales o membresias reales.
El principal de migracion permanece administrativo y separado.

Inventariar explicitamente las 133 SP con justificacion de categoria antes de
aprobar. Prueba en base QA exclusiva mediante usuarios WITHOUT LOGIN y TX
revertida, con controles efectivos positivos/negativos; no confundir con login
JDBC ni autenticacion HTTP. El Bootstrap Java heredado aun corre en arranque:
debera separarse del datasource runtime en la conversion Java posterior.
Ownership de programador solo dos archivos; supervisor conserva documentos.

### D-15.A: compatibilidad bootstrap de privilegio minimo

Pregunta msg_37e1794422f7 (A7 ctx_caf2cefe03bb) confirmada contra V3:
usp_bootstrap_exists/create exigen db_owner o sysadmin. EXECUTE por objeto
solo no basta; el contrato D-15 inicial necesitaba esta evolucion. Se autoriza
EXCLUSIVAMENTE en V8 dos ALTER PROCEDURE literales para admitir tambien
IS_ROLEMEMBER(N'hp_bootstrap_executor')=1 en esa guarda. V3 fuente aplicada
permanece intacta; firmas, scope BOOTSTRAP, transaccion, bloqueos, idempotencia,
validaciones y demas cuerpo conservados exactamente. No EXECUTE AS OWNER,
permisos amplios ni cambios a otro SP. Entrega exige diff de cuerpos y prueba
real del rol sin privilegios fijos; rollback restaura definiciones originales.

usp_access_branch y usp_access_patient_link se clasifican como entradas runtime
aprobadas: sustituyen lecturas directas de identity/Access.java branch/link,
con validacion de actor/sesion/tenant del lado servidor. No confundir con helpers
require/guard internos. Probar bootstrap sin scope rechazado y runtime con
scope BOOTSTRAP aun denegado a ambos SP. No se modifica Java en este paquete.

### D-15.B: QA de denegaciones con transacciones inutilizables

Pregunta msg_e3264b727cb2: worker comunica CREATE TABLE262 e impersonacion15517
con XACT_STATE=-1 pese a XACT_ABORT OFF; REVERT3930 o rollback que elimina al
usuario efimero dificultan continuar el harness oneTX. Se inspecciono su script
y se corrige la restriccion de QA, sin ampliar permisos de producto.

Autorizar fases rollback-only SECUENCIALES y conexiones independientes para
esos negativos y scope51001. Cada fase instala V8/roles/fixtures dentro de su
transaccion, afirma error y estado, cierra conexion sin COMMIT; nueva conexion
administrativa comprueba rollback, contexto liberado, hashes de definiciones
bootstrap originales y baseline133SP/31triggers/37tablas/0users/0roles-principales
de A7. Falla de limpieza detiene siguientes fases y retorna exit no cero.
No se autoriza CREATE USER/LOGIN persistente ni cambios a instancia.

Se prefieren fases independientes a fixtures SP WITH EXECUTE AS: no hacen
falta nuevos modulos de prueba ni cadenas de propiedad que compliquen el
resultado. Mantener intentos REALES CREATE TABLE y EXECUTE AS dbo; DROP3701 o
HAS_PERMS solos no prueban esos rechazos. No retirar guardas ni elevar usuario
para que pase la suite. El informe debe distinguir pruebas motor del worker
de la futura revision independiente del supervisor.

### D-15.C: historial de migraciones opcional y restringido

Revision supervisora de A7 detecta/reproduce R-A7-HISTORY: conteo exacto37tablas
rechaza dbo.flyway_schema_history previsto por usp_monitor_migrations en V3.
Corregir ANTES de integrar/aplicar V8:37tablas negocio + opcional exclusivamente
esa tabla de infraestructura, propiedad/cadena dbo compatible, sin ignorar
otras tablas. Con historial, agregar8DENY DML por objeto (4x2roles):570ACL; sin
el,562 originales. Ningun nuevo GRANT ni crear/poblar historial desde V8.
Lectura solo SP con autorizacion SAD/SOP, nunca directo ni bootstrap.

Ownership de correccion solo V8 y verificador no integrados. V1-V7 inmutables.
Ampliar QA con historial representativo sintetico y tabla desconocida, ambos
rollback-only y cleanup independiente. No confundir fixture de historial con
ejecucion de Flyway/JDBC real, aun pendiente. Supervisor no escribe DB durante
correccion delegada; no nueva sesion/worktree/cuenta ni config global.

### D-15.D: visibilidad de metadatos limitada al historial

Pregunta msg_52027c25a65d: worker informa catalogo570/effective570 PASS, pero
usp_monitor_migrations devuelve0filas porque OBJECT_ID del historial esNULL
bajo runtime sin permisos de metadatos. Supervisor contrasta V3: ese IF existe
y usa contexto caller; aun pendiente repetir personalmente el caso corregido.

Se autoriza opcion A: GRANT VIEW DEFINITION ON OBJECT::dbo.flyway_schema_history
TO hp_runtime_executor, SOLO si la tabla existe. Un permiso de metadatos sobre
esa tabla, sin nuevo SELECT/DML/EXEC ni grant de esquema/base. Conservar8DENY
CRUD a ambos roles y solo2ALTERbootstrap D-15.A; no evolucionar monitor ni
EXECUTE AS OWNER. Conteo con historial pasa a571ACL; sin historial562.
Bootstrap sin VIEW DEFINITION y sin EXEC del monitor. Lectura de filas solo
por SP con guardas SAD/SOP/plataforma/sesion existentes.

Probar visibilidad OBJECT_ID runtime, permiso efectivo exacto, ausencia de
grantsmetadata amplios, CRUDdirecto8rechazos229, fila sintetica recuperada por
SP autorizado y llamada sin actor/sesion de plataforma rechazada51001. Mantener
rollback independiente y cleanup; SQLrepresentativo no acredita Flyway/JDBC real.
Ownership sin cambio, dos archivos de A7.R1, V1-V7 inmutables.

Documentacion primaria consultada: [Microsoft: visibilidad de metadatos](https://learn.microsoft.com/en-us/sql/relational-databases/security/metadata-visibility-configuration).
Explica funciones de metadatos que retornanNULL y VIEW DEFINITION por objeto;
la aceptacion requiere ademas evidencia real en esta instancia, no solo documentacion.

### D-16: adaptador JDBC separado antes de convertir servicios

A7.R1 aceptada para fuente y10fases motor rollback-only; roles no desplegados.
Siguiente paquete A8 limitado a pom(dependenciasSQLServer compatibles),4clases
nuevas persistence/sqlserver y2suites nuevas. Contrato completo del encargo en
tmp/sql-01-a8-spec.md. Adaptador sin registro de bean ni datasource activo,
12procedimientos de entrada tipados y contexto interno porSP en misma conexion,
limpieza finally e invalidacion si falla. Consume todosRS/updatecounts sin SQL
arbitrario; tipos/UTC/JSON/NULL preservados y errores SQLServer seguros sin retry.
Proposito runtime separado de bootstrap, que requerira principal propio al cablear.

No retocar Sql.java/Errors.java/Bootstrap ni servicios/config/MySQL heredados en
este corte. Su presencia sigue siendo brecha100%SP, no arquitectura destino.
Primero preparar/verificar adaptador y dependencias sin activar app; despues
convertir identidad/infraestructura y familias secuenciales, revisar migrador y
transporte real. Dobles JDBC son pruebas de contrato unitarias, no integracion.

Referencias primarias consultadas para contrato: [Microsoft RS multiples](https://learn.microsoft.com/en-us/sql/connect/jdbc/using-multiple-result-sets),
[Microsoft procedimientos](https://learn.microsoft.com/en-us/sql/connect/jdbc/using-statements-with-stored-procedures),
[Flyway SQL Server](https://documentation.red-gate.com/flyway/reference/database-driver-reference/sql-server-database).
Versiones se contrastan con BOM/codigo local, no se actualizan frameworks.

### D-17: completar catalogo antes de convertir consumidores

A8 aceptada aislada con49/49pruebas independientes. SiguienteA9 ownership4
archivos: Procedure/Executor/suiteExecutor y nueva suiteContrato. Catalogo
exacto108operaciones:106runtime+2bootstrap, pues los107grantsruntimeV8 incluyen
usp_request_context, que sigue SOLO interno. Agregar96descriptores a los12
iniciales, con parametros ordenados/tipos/longitudes desde V3-V6. No exponer
24helpersprivados ni contexto como llamada de libre seleccion.

Agregar solo tipos publicos requeridos (INT/BIGINT/NVARCHARMAX),sin narrowing
ni truncado y con validacion antesconexion. QAcontrato compara fuentesSQL y
matrizV8 contra catalogoJava, sin clonar enum en otroarray; mocks verifican
binds y MAX/errores/bordes. No wiring,consumidores,config,migraciones,DB oHTTP.
Esto desbloquea conversion modular posterior, no acredita100%SP todavia.
Encargo completo tmp/sql-01-a9-spec.md; supervisor conserva documentos.

### D-18: convertir host y sesion sin activar un backend parcial

A9 aceptada: catalogo completo y 169 pruebas independientes. Siguiente A10
limita ownership a HostFilter, SessionFilter, nuevo SqlServerSecurityStore y
dos suites nuevas. Store usa cinco descriptores aprobados y TransactionOperations
del datasource runtime; contexto explicito desde atributos internos de request.
Transacciones cortas terminan antes del FilterChain, nunca abarcan downstream.

Agregar constructores explicitos para el camino SQL Server y conservar los
constructores actuales que SecurityConfiguration aun utiliza. No seleccionar
motor desde HTTP, ni fallback a consultas legadas cuando falle un SP. El camino
legado es transicion temporal que debe retirarse en el cierre 100% SP; no se
adopta una arquitectura multibase permanente. Sin beans, wiring, configuracion
o activacion en este corte. SecurityConfiguration y servicios restantes intactos.

Preservar host validado, aislamiento, sesion, roles, CSRF y errores HTTP vigentes
(incluido 503 de mantenimiento en filtro). Pruebas con filtros reales y request/
response simulados; gateway y transacciones con dobles, sin atribuir integracion
SQL Server o navegador. Encargo completo en tmp/sql-01-a10-spec.md.

### D-18.A: revocacion entre lookup y touch

Avance msg_e3dc74c811cb contrastado con V3: session_resolve filtra sesion y
contexto host; session_touch ejecuta require_actor nuevamente. Mantener 401
cuando lookup devuelve vacio, membresia falta o host/rol no corresponde. Si
la sesion pierde validez entre lecturas y touch, conservar 403 FORBIDDEN seguro
del SP, sin autenticar ni continuar FilterChain. No traducir infraestructura
500 a 401 y no reintentar. Son transacciones cortas separadas; no se promete
atomicidad de toda la request ni ausencia de carreras con revocacion.

Exigir prueba de esta carrera simulada y de error 500, con cadena detenida y
sin fallback legado. El mismo datasource para executor y TransactionOperations
sera verificado al cablear, aun pendiente; A10 no crea ni activa ese wiring.

### D-19: IdentityService con SP y registro fallido independiente

A10 aceptada con218 pruebas independientes. A11 tiene ownership seis archivos:
IdentityService, SecurityStore (solo extraer contexto), nueva utilidad de contexto,
IdentityStore y dos suites. Constructor SQL explicito; constructor legado marcado
@Autowired para preservar seleccion actual de Spring. Sin beans/config nuevos.
Legado temporal se retira al cierre100%SP, sin fallback por error ni eleccion HTTP.

Contexto compartido conserva exactamente controles A10. IdentityStore usa nueve
descriptores V3 y TransactionTemplates REQUIRED/REQUIRES_NEW con mismo manager
runtime: independiente SOLO el login fallido, equivalente al AttemptRecorder
existente, que no se llama en camino SQL. Futuro wiring debe acreditar datasource
comun y durabilidad reales; mocks no lo demuestran. Login/accept se agrupan sin
self-invocation parcial, verifican password en servidor y no exponen hashes/CSRF
en respuesta bearer. Actor solo tras exito de unidad transaccional, considerando
commit/rollback envolvente; conservar API, rate limit y politicas existentes.

BrowserSessionController/Bootstrap/AttemptRecorder/Access/config y migraciones
no se modifican en A11. Falta convertir esos consumidores antes de activar SQL.
Encargo completo tmp/sql-01-a11-spec.md; pruebas de contrato y servicios con
dobles, sin DB/HTTP real ni habilitacion del backend.

### D-19.A: entradas explicitas para crear usuario administrativo o de registro

Pregunta msg_26836b1b9f84 contrastada con AccountLifecycle.register: ese caller
usa identity.create seguido de pending/portal o tenant/outbox en su TX. Se
autoriza separar caminos SQL por metodo de servidor: create(UserInput) requiere
Actor administrativo y scope REQUEST; nueva createForRegistration(UserInput)
requiere Actor ausente y scope IDENTITY. No inferir elevacion por anonimato de
create, URI, body o headers. No endpoint nuevo ni modificacion de AccountLifecycle.

La nueva entrada de registro debe participar en TX externa MANDATORY, con
template o guarda efectiva aun al invocarse sin proxy; no crear/confirmar TX
propia que deje usuario antes de pending/tenant/outbox. Se permite ese tercer
modo transaccional exclusivamente para registro. Fallar seguro sin USER_CREATE
si falta TX/request, existe Actor o se usa constructor legado para nueva entrada.
create legado permanece como hoy y AccountLifecycle actual sigue usandolo; su
conversion posterior invocara la nueva entrada dentro de TX completa.

Ownership A11 sigue seis archivos, nueve descriptores, sin registro/correo nuevo
ni activacion. Exigir pruebas de rechazo y participacion MANDATORY con dobles;
la atomicidad de registro completo y persistencia real aun no estan validadas.

### D-20: sesiones de navegador y CSRF del resultado de login

A11 aceptada con249 pruebas independientes y cierre formal. Siguiente A12
limita ownership a BrowserSessionController,IdentityService,IdentityStore,
sus dos suites y una suite nueva de controller. Mantener constructor legado
@Autowired y camino SQL explicito, sin wiring o endpoints nuevos.

Entrada interna loginBrowser reutiliza autenticacion/unidad transaccional A11 y
SavedSession del mismo SESSION_SAVE; no segunda lectura para obtener CSRF.
Resultado interno tipado/redactado, controller proyecta solo user/expiry/CSRF y
coloca bearer exclusivamente en cookie HttpOnly con flags existentes, despues
de exito. Login/accept bearer conservan shape sin CSRF y hooks afterCommit.

Store agrega SESSION_CURRENT y SESSIONS_LIST, reutiliza SESSION_REVOKE por id
opaco sin SELECT ni rehash. 11 descriptores totales, contexto REQUEST propio,
RS/cardinalidad/tipos/columnas seguras dentroTX, sin filtrar hashes/CSRF en lista.
Preservar404 desconocido, cookie/logout y errores existentes. Pruebas HTTP
simuladas/manager doble, sin atribuirlas a browser o SQL Server real.
Encargo completo tmp/sql-01-a12-spec.md; no activar backend parcial.


### D-21: Access de sede/vinculo por SP en constructor explicito

A12 aceptada con279pruebas independientes. A13 convierte solamente Access.branch
y Access.link, mas store aislado y dos suites nuevas; cuatro archivos.
Constructor legado con @Autowired preservado y constructor SQL explicito, sin
activar beans/datasource ni cambiar otros metodos publicos de Access.

Autoridad de branch/link SQL: SecurityContext.actor coincide con health.actor
y TenantRef del request inyectado; sin actor401, incoherencia o plataforma403,
antes del SP. No usar otro request de TraceContext para sustituir autoridad.
REQUEST deriva actor/tenant/token de atributos internos. ADM tambien consultaSP.
ACCESS_BRANCH(id) y ACCESS_PATIENT_LINK(patient,scope), solo esos dos descriptores;
REQUIRED y mapeo dentroTX,0..1fila,ids exactos. Ids canonicos Checks.id y scope
no blanco<=80UTF16, sin cambio de caso ni lista cerrada adicional.

Decision consciente para futuro camino SQL: V3 devuelve opcion vacia tanto por
sede ausente/inactiva/ajena como por falta de asignacion; unificar404 para estos
casos evita lectura extra y revelar existencia. Link vacio tambien404. Legado
conserva sus403/404. Este cambio del camino SQL queda documentado antes de su
activacion; formato HTTP de errores permanece. RS/tipos/ids incompatibles500
seguro con rollback, erroresSP mapeados sin fallback/reintento.
Encargo tmp/sql-01-a13-spec.md; pruebas de permisos modeladas no validan DB real.


### D-22: catalogo de registro y limite temporal del ciclo SQL

Siguiente A14 convierte solo AccountLifecycleService.options y agrega store
aislado con dos suites;4archivos. Constructor legado @Autowired conserva
comportamiento; SQL explicito sin beans/datasource activo. Host del request
interno debe coincidir con TenantRef argumento; plataforma ofrece plans y
specialties,tenant ofrece solo portal:true sin consultas. Catalogo sigue publico.

REGISTRATION_PLANS y REGISTRATION_SPECIALTIES,REQUEST,una unidad REQUIRED,
ambos resultsets0..Nfilas dentroTX. Proyeccion explicita de ocho campos plan y
cuatro especialidad,INTInteger/BIGINTLong/BITBoolean,arraysString inmutables,
orden/Unicode preservados,sin techo241 ni campos demo/privados. Datos SP
malformados500 seguro,fallos sin lista vacia fingida/retry/fallback.

No se activa un servicio SQL incompleto: register/request/redeem del nuevo
constructor fallan500seguro antes de efecto/interaccion hasta sus paquetes
siguientes. El legado y rate/issue conservan comportamiento. No tocar rutas
ni flujo de correo ahora. Bootstrap separado se aborda despues de acordar
transaccion/principal propio; no reutilizar la TX runtime como setup.
Encargo tmp/sql-01-a14-spec.md. Pruebas offline no acreditan catalogo/API real.


### D-23: enlaces de identidad sin alta ni SMTP

A14 aceptada316/316; siguiente A15 convierte request/redeem con store existente
y nueva suite controller standalone; ownership5archivos. Legado,options/rate,
rutas y formatos actuales preservados; registerSQL sigue guardado500.
Host interno coincide con TenantRef,scopeIDENTITY de helper servidor.
Store agrega LOOKUP/MEMBERSHIP(active_only=false)/ISSUE/REDEEM:6SPtotales
con catalogo previo. REQUIRED agrupa elegibilidad,token,outbox; no TX autonoma.

Cuenta ausente/nohost/membresia ausente/RESETunverified retorna normalmente
sinISSUE,misma aceptacion API generica. Elegibles usan token32bytes/43base64url,
hash persistido,link fragment y origen Settings,TTL86400VERIFY/1800RESET.
ISSUE toma userId y resuelve destinatario en DB; registration_tenant siempreNULL,
no destinatario del cliente ni correo real en A15. Carrier interno redactado.
Redeem valido manda hashToken,purpose y hashPassword soloRESET;VERIFYNULL.
Sin sesion/cookie/autenticar ni exponer tokens en respuesta/diagnosticos.

Tipos/cardinalidad/0RS de escrituras y contexto se validan dentroTX; erroresSP
se preservan sin fallback/retry ni exito ficticio. Si elegibilidad cambia durante
ISSUE,abortayerrorseguro; no capturar fallo enTXexterna para ocultar rollback.
Carreras y no enumeracion de red bajo fallos quedan para QA conectada; no
presentar aceptacion generica de casos normales como validacion integral IAM.
Se reemplaza solo testA14 de guardas mutadoras por guarda register y pruebas
del request/redeem nuevo; demas315pruebas anteriores conservadas.
Encargo tmp/sql-01-a15-spec.md. No SMTP/DB/HTTP conectado ni100%SP activado.


### D-24: alta del portal por tenant, plataforma aun guardada

A15 aceptada331/331. A16 limita registerSQL a tenant existente coherente con
request interno y sin Actor; plataforma mantiene500 seguro hastaA17. Misma
ownership5archivos lifecycle/store/tres suites. Legado,options/request/redeem/
rate conservados; no configuracion,SMTP ni crear organizacion en este corte.

Unidad REQUIRED:EMAIL_EXISTS incluyendo inactivos ->createForRegistration A11
MANDATORY ->IDENTITY_PENDING ->PORTAL_REGISTER ->issueSqlVERIFY existente.
TresSP nuevos en lifecycle store,9totales; USER_CREATE permanece en IdentityStore.
Pending/portal requieren MANDATORY propio para impedir commit aislado. Actor
ausente,scopeIDENTITY y mismo manager/datasource son contrato previo al wiring.

Nombre/email/password/terms son unicos datos efectivos; tipo/dominio/plan/sede
del formulario no conceden rol ni tenant. Dominio/credential UserInputNULL;
SP decide PAC/RES y sede; no paciente/vinculo/historia ni sesion automatica.
Duplicates normales retornan misma202 sin reactivar/reenviar ni filtrar identidad.
Error o carrera posterior revierte y preserva400/403/409/500, sin retry/exito falso.
ISSUE registration_tenantNULL,origen tenant validado,TTL86400 y fragmento A15;
no manipular health.tenant/actor para aparentar otro contexto.
Encargo tmp/sql-01-a16-spec.md; atomicidad/roles/concurrencia real aun sin probar.


### D-25: registro publico de organizacion sin cambiar contexto de host

A16 aceptada343/343. A17 completa registerSQL plataforma,misma ownership5archivos.
Validacion hostanonimo,basicos y organizacion antes de EMAIL_EXISTS para no
distinguir email existente con formulario incompleto. Portal/legado/catalogo/
request/redeem/rate preservados; antiguas guardas500plataforma se actualizan
conscientemente a validacion400/hostmismatch403 y alta202.

Unidad REQUIRED:EMAIL_EXISTS ->REGISTRATION_PLAN ->createForRegistration A11 ->
PENDING ->SAAS_TENANT_CREATE ->ISSUEVERIFY. Store suma2SP,11totales; createTenant
y emisionRegistration MANDATORY. JSON9campos raiz con subscription5campos,
cuotas incluidas obtenidas del SP,MONTHLY,America/Lima,Sede principal. Propietario
recien creado,dominio soloDOCTOR; no actor privilegiado o cuotas del cliente.
Respuesta publica del SP validada contra ids/slug/kind/domain/statusTRIAL.

Host del request sigue plataformaNULL/ActorNULL todaTX. Usar metodo explicito
ISSUE registration_tenant=tenantIdCREADO soloVERIFY,validado porSP V3; normal
ISSUE A15/A16 conservaNULL. Enlace Settings.tenantUrl(created.slug),sin sustituir
health.tenant/actor ni autenticar propietario. Sin camposprivilegiados HTTP.
Errores/commit abortan sin202falso/retry; no prometer idempotencia o anonimato
de red bajo carreras por pruebasoffline. Encargo tmp/sql-01-a17-spec.md.
Sin DB/SMTP/config activa ni aprobacion clinica por crear perfiles.


### D-26: traza HTTP independiente al terminar el filtro

A17 aceptada trasR1/353pruebas. A18 limita ownership aTraceFilter,store nuevo
y dos suites. Constructor Sql vigente y nuevo SQL explicito,sin beans/config
activa. UUIDservidor/headers/TraceContext y reglasOrigin/gateway/exclusiones
se conservan. Persistir SOLO al finalizarchain,con estado final y duracionms.

Store usa unicamente REQUEST_FINISH(status,duration),scopeREQUEST,0RS,contexto
del request final por helper existente; no SecurityContext que SessionFilter
ya puede limpiar ni otroThreadLocal. Correlacion debe coincidir con UUIDlocal
servidor; contexto interno corrupto500 y metricasinvalidas400 sinexecutor.

Decision acotadaREQUIRES_NEW: confirmar traza fuera de TX de negocio y poder
registrar fallos aun con rollback llamador. No extender TX sobrechain ni cambiar
otros stores; independencia/pool/locks reales quedan para QAconectada.
Fallo de persistencia conserva respuesta/excepcion original segun comportamiento
best-effort actual,con logestatico+ID sin secretos. ThreadLocal siempre limpio,
incluso fallo del store; no query/body/cookies/tokens claros nuevos en datos.
Encargo tmp/sql-01-a18-spec.md; gateways/async/pool y SQL/JDBC reales no validados.


### D-27: lectura tipada de auditoria/trazas y contrato de filtros SQL

A18 aceptada368/368. A19 convierte AuditService4metodos con store y2suites,
ownership4archivos,sin controllers/config. Legacy @Autowired y nuevo SQL
explicito; contexto interno coincide con Access.actor/host. list soloADM/AUD
tenant; events/requests/journey SAD/SOPplataforma oADM/AUDtenant.

AUDIT_LIST/TRACE_EVENTS/TRACE_REQUESTS/TRACE_JOURNEY,REQUEST,REQUIRED. Limit
clamp1..200,eventos SP ya retorna limit+1,cursor del ultimo visible; journey
consume2RS y hasta200steps de201 sin segunda query. Proyectar campos exactos
V3 con tipos/nulls,inmutabilidad profunda y JSONVALUE (incluyeNULL),sin columnas
privadas extras ni estrecharLong. Tenant exige filaspropias oeventosNULLdel
puenteSP; plataforma permite rootNULL+eventoTenantCreado. Sin autoridad cliente.

Decision consciente solo nuevo caminoSQL: fechasinvalidas o precision>6->400
en vez de truncar; resource>60/queryrequests>250->400 por limites del contrato.
Queryevents se trunca100UTF16sinpartirsurrogates como legacy; blank->NULL,
UUIDfiltros canonicos,statuspositiveumbral intacto,before<=0sin filtro. No
imponer from<to nuevo. Legacy no cambia. ErroresSPpreservados/datosmal500,
sin fallback/retry ni snapshotreal prometido. Encargo tmp/sql-01-a19-spec.md.


### D-28: estado publico y muestreo WORKER antes de completar monitor

A19 aceptada385/385. A20 limita MonitorService a status/sample con store y
2suites,nueva ownership4archivos. Constructorlegacy @Autowired y SQLexplicito,
instanceUUID estable/Scheduled15000/12000 conservados. Details/mode SQL fallan
500seguro antes de efectos hastaA21; no configuracion activa ni nuevoendpoint.

APPLICATION_STATUS enREQUESTpublico devuelve4campos(mode/message/revision/
statusderivado),sin login/informacion de infraestructura extra. Sampleusa
HEALTH_READY conWORKER sinningun datoHTTP/actor/tenant/token,readyInteger1
obligatorio antes de HEALTH_SAMPLE(UP/latenciams/metricasJVM). UnidadREQUIRED
para ambos,mapeos dentrocallback;no sampleUP anteprobeinvalido,ni DOWNficticio.
FallosStoreseguros,samplerbest-effortconWARNestatico sin datos/Throwable.
TresSPtotales,sin SELECT1Java,cache/retry oTXsobre tareas. Actuator/pool se
convierten despues; no probarlos ni declararlos migrados en este corte.
Encargo tmp/sql-01-a20-spec.md. Modelos no acreditan disponibilidaddurable real.


D-29 (2026-11-04): A21 completa Monitor details/mode mediante SP y constructor
explicito sin wiring. Details plataforma SAD/SOP,tenant ADM/AUD;mode SADsolo.
Lecturas REQUIRED sin promesa snapshot;mode+status misma unidad. Proyeccion
explicita,inmutabilidad,nullableversionFlyway,contextoREQUEST coherente y
ningunSPplataforma desde tenant. Contrato detallado tmp/sql-01-a21-spec.md.


D-30: MailDelivery SQL usa claim/complete REQUIRED separados,claim confirmado
antes del emisor fueraTX;rechazar ciclo con outerTX. Excepcion del emisor
es AMBIGUOUS,exito SENT;fallo complete no reclasifica ni reenvia. WORKER9NULL,
sin red real ni wiring,claim_version y exclusionSENDING conservados.


D-31: Bootstrap por constructorSQL explicito,store REQUIRED con datasource/
executorBOOTSTRAP separados runtime. EXISTS antes de validacion password/hash;
supplier de hash dentro unidad que CREATE. ContextoBOOTSTRAP9NULL,sin wiring
ni usuarios reales. Carrera se resuelve por SP idempotente,no garantia deinsert.


D-32: soporte SQL por etapas,A24list/detail unicamente,create/stepguardados
hastaA25. PlataformaSAD/SOP,tenant autor autenticado sinrestriccionADM/AUD,
contextoREQUEST coherente y proyeccionexacta,nullableplataforma/MAX preservado.
Una REQUIRED por lectura,sinwiring ni promesa snapshot.


D-33: A25publicsupportREQUESTanonimo/tenantanonimo permitido,requestinterno
igual argumentoHTTP,rate existente anteswrite. CREATE0RS recibo5camposlegacy;
STEP6args2RS sinlecturaextra,SPautoridad de transiciones/revision/tenantcomment.
GuardatestA24 sustituido explicitamente por regresionesnuevas,sinwiring.


D-34: A26 cuatrolecturas plataforma porSP soloSAD,REQUESTcoherente,otras
operacionesSQLguardadas. Proyecciones tipadas y JSONprofundo inmutable,
query220UTF16sintruncar y limits1..200. Constructoraislado,sinwiring.


D-35: A27tenants/tenant/statusSAD,29columnas+hostname/urldesdeSettings.
Status unSPdevuelvefila;augmentSettings dentrocallbackTX antescommit,fallo
revierte. Nolecturaextra ni autoreanudacion ni revisioninventada,sinwiring.


D-36: A28planmutador usaSAAS_PLAN_SAVE1SPconBooleancreate/proyeccion21,
version/locks resueltosSP. CreateUser ejecutaIdentityService.create firmado
dentroREQUIRED y PLATFORM_USERS(id,1) mismaunidad,body5camposlegacy;sinwiring.


D-36.A: preguntaA28 msg_dff134da15ed contrastada con fuente IdentityStore47-54:
create administrativo usa REQUIRED,NO MANDATORY;solo createForRegistration
MANDATORY. Conservar ambas clases y probar joinREQUIRED mismo manager/datasource
con PlatformStore;sin commitinterno. La frase anterior del encargo fue imprecisa
y queda sustituida. DescriptionNULL rechazado por Requests/JSONstringV4.


D-37: A29completaPlatformService aislado:createTenant une ownerexistente
lookup o IdentityService.create nuevo conSAAS_TENANT_CREATE ySettingsantes
commitREQUESTSAD. Pay1SP2args/8campos,sin cobroexterno. Sinwiring/DBreal.


D-38: A30Organizationlookup/directory/professionals/catalog/plans tenant-only,
lookup/plansADM,restocualquieractorcoherente. BranchAccessA13preservado mas
SPprofessionalsautoridad. 5SPREQUEST tipados,config/writeguardados,sinwiring.


D-39: A31configuracion1SP8RS,ADMhostactual oSADtargetexplicito. Root31campos
idtenantpreservado,agruparpares poruser sinN+1,proyecciones ycoherenciatenant/
IDs antescommitREQUIRED. CincoescriturasSQLguardadas,sinwiring.


D-40: A32subscription/branch/area/specialties1SPcadaoperacion,contexto
SADexplicit/ADMcurrentA31,mapper8RSreutilizado sinlecturaextra para cambios
contrato/especialidades. POSTPUTBoolean yUUIDservidor,memberguardado,sinwiring.


D-41: A33member usaIdentityService.create administrativo REQUIRED si nuevo,
seguido MEMBER_SAVE enmismaunidad;existinguser sinSPplataformaSAD-only ni
lookup porqueMEMBER_SAVE validaactive/role y404. JSON4/retorno7legacy,sinwiring.


D-42 (2026-11-05): A34pacienteslist/get/save3SP,tenantwide contextofirmado,
rolesreadADMREC PRO ASI AUD/writeADMREC PRO+CORE. HTTPcreateexpected0/
update>=1,UUIDservidor,JSON7campos yproyeccion11;link/historyguardados,
sinwiring/datosreales ni reglasclinicasnuevas.


D-43 (2026-11-05): A35linkADMREC+PORTAL/historyPROASIAUD2SP,history4RS
conauditoriainterna callerTX ysinGET/auditextra. Longitudinaltenantwide,
entries/docencounterpuedenfueraTOP200,proyecciones13/8/16+limits,sinwiring.


D-44 (2026-11-05): A36agenda list/get2SP,REC PRO ASI AUD sinADMsolo,
contextREQUESTtenantwide. BranchAccessA13listopcional,getsinbranchfiltro,
precisionUTCmicro yDuration.toDays<=93legacy,proyeccion14;writesguardados.


D-44.A: motordemostrodivisionnumericcontradice diascompletosJava. R-A36-SQL-
WINDOW requiereV9incrementalALTERsolo predicado con divisionBIGINT explicita
(o equivalenteexacto93diascompletos),sin tocarV1-V8aplicadas ni cuatroSHAJava.
Regresionmotorreal antesaceptarA36,sinJDBC/HTTP claim.

Resolucion 2026-11-05: A36.R1 aceptada despues de inspeccion exacta de V9 y 8/8
fases SQL Server reales repetidas por el supervisor. CONVERT(bigint,86400000000)
mantiene el limite por dias completos: 93d23h y 94d-1us permitidos; 94d exactos,
reversed/equal rechazados. V9 incremental, no instalada permanentemente en QA.
No acredita wiring, JDBC, HTTP ni permisos efectivos de cuenta runtime.


D-45 (2026-11-05): A37 portara SchedulingService.reserve/change al store SQL
Server existente, conservando rutas/DTO y constructor legacy. Staff: CORE con
REC/PRO, sede asignada y escritura atomica por usp_appointment_reserve/change.
Portal: PAC/RES, PORTAL, vinculo APPOINTMENTS y solo REQUESTED; no cambiar el
controller actual. Reserve conserva Idempotency.key, UUID servidor, JSON de 9
campos en orden legacy, fechas UTC a microsegundos y SHA-256 UTF-8 del JSON exacto
de Requests.Reserve serializado por el ObjectMapper configurado. Replay misma
clave/hash retorna fila; hash distinto y horario/conflictos siguen siendo del
SP. Change conserva revision, estados/transition, sede y reglas de reprogramacion
futura RESERVED. Ambos dentro REQUIRED y sin retry. Contrato probado con dobles;
eso no valida SQL real/JDBC/HTTP, que siguen como gate posterior. Sin wiring,
configuracion, controladores, SP, migraciones, endpoint ni funcionalidad nueva.

A37 aceptada en implementacion aislada: serializacion de hash verificada contra
Sql.json con el mapper configurado; test suite y revision fuente pasan. La clase
store requiere el constructor con ese mismo ObjectMapper para escribir. SQL
Server real, concurrencia, cuenta/runtime JDBC, wiring y HTTP permanecen gates.


D-46 (2026-11-05): A38 completa el consumidor ClinicalService con el store SQL
Server explicitamente seleccionado. get usa ENCOUNTER_GET (2 resultsets, read
audit incluido); start usa ENCOUNTER_START (su resultset compuesto, sin GET
extra); note conserva GET previo/branch/finalize validation y usa ENCOUNTER_NOTE
para mutar y retornar estado; entry conserva GET previo, branch/autor, Checks.json
y la validacion existente del profileSnapshot antes de CLINICAL_ENTRY_ADD. SQL
Server mappings deben consumir resultsets de los SP sin SELECT directo. No mover,
debilitar o sustituir reglas clinicas ni aprobar perfiles. Constructor legado,
routes/DTO y respuestas intactos; sin wiring, schema, nuevas reglas, datos reales,
JDBC/HTTP ni activar perfiles. Tests mock no son QA motor.

A38 aceptada solo como store/servicio explicitamente seleccionado y suite offline
independiente. D-46 se implemento: profileSnapshot validado por logica existente,
resultsets/auditoria sin lecturas duplicadas y sin backend activo. SQL Server real,
JDBC, wiring/grants y aprobacion de perfiles clinicos siguen fuera de esta decision.

D-47 (2026-11-05): Migrar únicamente DocumentService con adaptador SQL Server explícito. Preservar rutas/DTO y métodos list/get/create/change. Lectura PRO/ASI/AUD; escritura PRO + CORE y tenant activo según contratos ya aprobados. Usar DOCUMENTS_LIST/DOCUMENT_GET/DOCUMENT_CREATE/DOCUMENT_CHANGE y proyecciones compatibles; validar forma/tenant/IDs/resultsets. Mantener auditorías DOCUMENT_LIST_READ y DOCUMENT_READ en SP. create retorna el resultset compuesto de CREATE, no ejecutar GET duplicado. change mantiene lectura previa y validación SAVE del servicio legado, usa SP con revisión optimista y acepta el resultset del CHANGE sin GET posterior redundante. Firma UTF-8, inmutabilidad, publicación/vínculo, retiro, revisión y auditoría permanecen en SP V5 existente. No cambiar SP, wiring/config, controllers/DTO, perfiles ni habilitar funcionalidad parcial. Pruebas unitarias offline no equivalen a JDBC/SQL Server/HTTP.

D-47 resuelta para implementación: A39 aceptada como adapter aislado tras revisión
fuente y 692/692 en snapshot independiente. El cambio no activa DocumentService.
Validación real con SQL Server/JDBC/HTTP, grants, firma/publicación e integración
sigue pendiente; PortalService documental queda en tarea secuencial A40.

D-48 (2026-11-05): A40 porta exclusivamente PortalService.documents mediante SqlServerPortalDocumentStore explícito. Mantener portal() (PAC/RES + PORTAL), Checks.id, controller y proyección. No llamar Access.link/SELECT Java en la rama SQL: usp_portal_scope resuelve tenant/actor, módulo y vínculo DOCUMENTS activo bajo HOLDLOCK; usp_portal_documents filtra SIGNED/published/not withdrawn, limita/ordena 200 y registra PORTAL_DOCUMENTS_READ bajo la misma transacción. El store consume/valida nueve campos camelizados y no infiere campos ausentes. El wiring de PortalService completo y el QA real SQL/JDBC/HTTP quedan en gates posteriores.

Aclaración arquitectónica A40: se autoriza el constructor explícito
(SqlServerPortalDocumentStore, Sql, Access, SchedulingService) para conservar los
recorridos no migrados; `Sql` permanece solo para patients/appointments/balance y
SchedulingService para reserve. `documents` debe usar exclusivamente el store en
la rama seleccionada, sin fallback. Constructor legacy `@Autowired` sin cambios.
Respuesta supervisora msg_1200f775c2d5 a la consulta msg_5bd454c50aa8.

D-48 resuelta para implementación: A40 fue revisada e integrada únicamente para
PortalService.documents; constructor legacy intacto y constructor explícito
(SqlServerPortalDocumentStore, Sql, Access, SchedulingService) conserva los
colaboradores de los métodos no migrados. Suite independiente 712/712. No hay
validación real del vínculo/SQL/JDBC/HTTP, ni backend activo. Siguiente A41
PortalService.appointments por propiedad secuencial del mismo archivo.

D-49 (2026-11-05): A41 migra únicamente PortalService.appointments con store SQL Server explícito. Mantener portal() PAC/RES + PORTAL, Checks.id, controladores y respuesta. La rama SQL no usa Access.link ni SELECT auxiliar: usp_portal_scope verifica vínculo APPOINTMENTS activo/bajo HOLDLOCK y módulos; usp_portal_appointments audita en transacción, filtra por paciente y conserva orden starts_at DESC,id y límite 200. El adaptador valida proyección, estados y UTC; no duplica reglas de enlace/visibilidad. SQL/JDBC/HTTP real y wiring siguen pendientes.

D-49 resuelta para implementación: A41 migrada/aceptada como lectura aislada,
con snapshot 733/733; bodies previos de PortalService y stores A39/A40 preservados.
No evidencia SQL Server/JDBC/HTTP, guards del SP o wiring. Próximo A42 migra
PortalService.patients en secuencia sobre el archivo compartido.

D-50 (2026-11-05): A42 migra exclusivamente PortalService.patients con store SQL Server explícito. Mantener portal() PAC/RES + PORTAL y omitir Access.link/SELECT de apoyo: usp_portal_scope valida host/tenant/actor/subscription; usp_portal_patients devuelve vínculos activos del actor con scopes y audit PORTAL_PATIENTS_READ bajo REQUIRED, orden name,id. Proyección whitelist de siete campos; scopes preservados y validados contra APPOINTMENTS/DOCUMENTS/BILLING. Los constructores y métodos A39-A41 se mantienen. SQL/JDBC/HTTP/wiring siguen pendientes.

D-50 resuelta para implementación: PortalService.patients aceptado como lectura
SQL aislada en snapshot independiente (754/754). Se conserva la cardinalidad sin
cap por ausencia de límite en V5. No acredita guards, vínculo o auditoría reales;
siguiente paquete A43 migra balance secuencialmente.

D-51 (2026-11-05): A43 migra exclusivamente PortalService.balance mediante PORTAL_BALANCE. Mantener guards portal() PAC/RES+PORTAL, module FINANCE y Checks.id en ese orden. SQL branch usa SP sin Access.link ni consultas Java; usp_portal_scope es autoridad para FINANCE y vínculo BILLING activo, y el SP audita/computa balance dentro de REQUIRED. Devolver balanceMinor BIGINT y currency PEN; pagos negativos y demás movimientos positivos como indica V5, sin excluir saldo negativo. Constructor explícito nuevo añade balance store a selectores A40-A42; legacy y métodos restantes preservados. No equivale a validación JDBC/SQL/HTTP/wiring real.

D-51 resuelta para implementación: A43 accepted como store aislado tras verify
independiente 773/773. No validar con doubles el balance/ledger o enlace BILLING
real. Todo PortalService tiene ahora consumers preparados aisladamente; pasar a
inventario de consumidores no portal y diseñar cableado solo con revisión completa.

D-52 (2026-11-05): Migrar FinanceService.balance/movements/post con SqlServerFinanceStore explícito. Balance retorna agregación decimal38 Number intacta; movements usa solo FINANCE_MOVEMENTS, sin balance/query de preflight, y conserva límite/orden. Post preserva serializer configurado, SHA-256 exacto UTF8 e idempotency key; V6 es autoridad para pagos/refunds/locks/replay/conflicto/auditoría y retorna row para nueva o replay. No read-after-write Java, cálculo/validación ledger duplicados ni activación/wiring. SQL Server/JDBC/HTTP siguen gate separado.

D-52 resuelta para implementación: FinanceService balance/movements/post aceptado
en snapshot independiente 797/797; mapper/hash confirmado. Sin validar balance
real, movimiento, replay concurrente, locks, grants JDBC/HTTP o wiring.

D-53 (2026-11-05): A45 prepara solo InventoryService.lots/transfers/prescriptions con los tres SP de V6 existentes y store explicito sin wiring. Preservar permisos por lectura, proyecciones 8/10/6, orden y limite 200, decimales exactos, fechas y JSON profundo. Constructor mixto SqlServerInventoryStore/Sql/Access mantiene escrituras legacy sin migrarlas parcialmente; no nuevos permisos ni queries. Ownership secuencial de cuatro archivos en tmp/sql-01-a45-spec.md. SQL/JDBC/HTTP y permisos reales siguen pendientes.

D-53 resuelta para implementacion aislada: A45 revisada e integrada con verify independiente 818/818. Contratos de lecturas preservados; escrituras, runtime SQL Server y QA real siguen pendientes.

D-54 (2026-11-05): A46 migra solo lot/move de inventario, SP V6 existentes. JSON original con mapper configurado y hash exacto, UUID nuevo o replay previo, mapping dentro REQUIRED; V6 autoridad para branch/stock/prescripcion/PHARMACY/idempotencia/audit. Sin preflight SQL ni read-after-write. Se permite agregar mapper al constructor de store y ajustar tests A45 en sus cuatro rutas; transfer/receive permanecen legacy hasta A47. Sin wiring ni validacion real de motor.

D-54 resuelta para implementacion aislada: A46 aceptada e integrada tras SHA/revision y verify independiente 832/832. V6 conserva autoridad de stock/branch/dispensacion. A47 completa transfer/receive antes de avanzar con otros consumidores y wiring.

D-55 (2026-11-05): A47 completa transfer/receive de inventario con V6 existente. Start UUID/JSON/key/hash exacto; replay puede ya estar RECEIVED y debe conservarse. Receive un ID y retorno RECEIVED con timestamp; SP autoridad de branch/stock/unidad/locks/audit. Sin queries ni calculo de negocio Java. Mismas cuatro rutas, preservando A45/A46 y legacy; sin wiring, QA SQL/JDBC/HTTP pendiente.

D-55 resuelta para implementacion: A47 revisada e integrada tras SHA/review/verify independiente 847/847. Todo InventoryService tiene caminos de store aislados; wiring/QA real pendientes.

D-56 (2026-11-05): A48 prepara resources/admissions HospitalService via HOSPITAL_RESOURCES/ADMISSIONS sin args. Preservar roles HOSPITAL, orden/limite200 y proyecciones7/11 incluyendo computed/nullable; sin branch filtros, recalcular ocupacion o inventar protocolos. Constructor mixto conserva tres escrituras legacy. Solo cuatro rutas en tmp/sql-01-a48-spec.md; sin wiring ni habilitar hospitalizacion.

D-56 resuelta para implementacion: A48 aceptada e integrada con SHA/review y verify independiente 869/869. Lecturas hospitalarias solo aisladas; pendientes escrituras y QA real.

D-57 (2026-11-05): A49 completa resource/admit/discharge con tres SP V6 existentes, un resultado por operacion, sin preflight/read-after-write. Mapper Spring para DTO original, nuevo UUID solo create; alta por ID/revision con conflicto MAX en SP, sin overflow Java. V6 autoridad de dominio/paciente/recurso/branch/ocupacion/locks/audit. Conservar A48 y legacy en cuatro paths; sin wiring ni habilitacion clinica.

D-57 resuelta para implementacion: A49 aceptada e integrada con SHA/review/verify independiente 885/885. HospitalService completo aislado, sin habilitacion clinica ni QA real.

D-58 (2026-11-05): A50 prepara solo WorkflowService.definitions/list mediante dos SP V6. SP autoridad para permisos/modulos dinamicos de definiciones actuales; Java valida autoridad tenant/request y proyeccion, no filtra por copia local de roles o catalogo fijo. definitions8 sin limite artificial (V6 sin TOP), list12 max200. get/create/step y helper definition permanecen legacy para evitar mezcla de dependencias en este corte. Ownership cuatro rutas, sin wiring/protocolos nuevos.

D-58 resuelta para artefacto: A50 aceptada e integrada tras SHA/review/verify independiente 905/905. Su Task/Dispatch NO cerrados: el programador alcanzo usage limit antes de worker_done; instruccion msg_2c08b3a801cf para completar reporte sin tocar archivos al recuperar cuota. No relanzar cuenta/sesion ni comprar creditos; no despachar dependientes con A50 aun abierta.

D-59 preparada (2026-11-05): siguiente A51 debe migrar get/create/step juntos porque las escrituras llaman get internamente. Reutilizar WORKFLOW_GET/CREATE/STEP con dos resultsets (case12 + history5) sin get preflight/read-after-write adicionales. V6 autoridad de permisos dinamicos/branch/transiciones/revision/locks; preservar Checks.json200000/depth30 solo en escrituras y mapper configurado. Pendiente encargo final y Dispatch hasta cierre A50.

D-59 contrato fijado,2026-11-05: A50 cerrada settled tras worker_done msg_36c5ed3e4930. A51 puede delegarse con tmp/sql-01-a51-spec.md: case12+history5 sinlimite, root13; preservar Checks.json en writes, no preflight/get extra ni permisos dinamicos cacheados. Escribir los3 recorridos juntos y mantener A50/legacy. MAX revision delegado SP409 y comparacion long; sinwiring. Bloqueo cuota previo resuelto sin cambiar cuentas/sesiones.

D-59 resuelta para implementacion: A51 aceptada e integrada con SHA/review/verify independiente922/922. WorkflowService completo aislado, sin activar backend.

D-60 (2026-11-05): A52 auditoria de solo lectura previa al ensamblado runtime completo. Supervisor verifica SecurityConfiguration construye filtros legacy con Sql, componentes @Autowired seleccionan constructores legacy, application.yml sigue datasourceMySQL y health Actuator/Hikari/AttemptRecorder deben revisarse por posibles accesos fueraSP. Estas referencias no equivalen a paths SQL inalcanzables comprobados. Worker debe producir matriz completa de consumidores/constructores/alcanzabilidad/filtros/jobs/setup/permisos y ownership de siguientes cortes; no editar ni activar nada. Impide presentar composicion parcial como migracion completa.

D-60 resuelta como auditoria estatica aceptada,no runtimevalidado. ENSAMBLADO_SQLSERVER.md:root explicito fuera scan,mismoDSmanager/executor/mapper,setup separado,poolprobeSP/healthSP,sin grafo parcial.24Stores=23runtime+bootstrap confirmados.

D-61 (2026-11-05): A53 void SqlServerMonitorStore.ready() REQUIRED,WORKER9NULL,un HEALTH_READY ceroargs,1RS1fila readyInteger1. Sin SAMPLE/APPLICATION_STATUS/requestHTTP. Nuevo SqlServerDatabaseHealthIndicator implementa Boot4 HealthIndicator directamente,constructorstore,sinbean/config. UP tras retorno store;RuntimeException=>DOWN sin detalles/exception/cause/logs. No Health.down(error)/AbstractHealthIndicator ni metadata/isValid/Sql. Sin liveness/pool/arranque en este corte.

D-61 resuelta para implementacion: A53 aceptada/integrada tras SHA/review/verify independiente934/934. ReadinessSP e indicador aislados, sin registrar/activar.

D-62 (2026-11-05): A54 prepara propiedades e infraestructura explicita fuera scan en com.mavric.healthsqlserver, cuatro rutas nuevas sin root/main/import desdelegacy. Propiedades tipadas de endpoint/database/credencialruntime externa, driverSQLServer fijo sin JDBCURL con credenciales; toString/errores sin secretos. Hikari lazy sin apertura, probe fijo EXEC dbo.usp_health_ready, sin initSQL/isValid; unDSmanager/JdbcTemplate/executorRUNTIME/TransactionTemplate. Sin stores (factories siguiente paquete), setup/jobs/HTTP ni activacion. Credenciales y principales reales siguen sin validar.


D-62 contrato de A54: health.sqlserver.runtime usa propiedades tipadas serverName,
port opcional, instanceName opcional, databaseName, username, password externo y
trustServerCertificate (false). Port e instance son excluyentes; sin ambos usa
1433. SQLServerDataSource por API tipada y encrypt=true, sin URL con credenciales.
Hikari sin arrancar al crear: max12/minIdle0, connectionTimeout10s,
validationTimeout5s, loginTimeout10s, initFailTimeout=-1, READ_COMMITTED,
autoCommit=true y probe fijo EXEC dbo.usp_health_ready, initSQL null.
Cinco beans: un DS, manager default, JdbcTemplate, TransactionTemplate REQUIRED,
executor RUNTIME; mismo DS/mapper. No stores, root, jobs, health bean ni conexion
en este corte. Alias identifican el mismo objeto, sin segundo datasource.

D-62 resuelta para implementacion: A54 aceptada/integrada tras SHA/review/verify independiente948/948. Infraestructura declarativa fuera scan, sinroot ni aperturaPool.

D-63 (2026-11-05): A55 agrega solo SqlServerRuntimeStoresConfiguration y su suite fuera scan, factories explicitamente nombradas para23storesruntime existentes. ExcluirBootstrapStore. Compartir executorRUNTIME/manager/mapper deA54; SecurityStore usa TransactionTemplateREQUIRED; conservar propagaciones internas REQUIRES_NEW/MANDATORY. Usar overload mapper de Clinical/Document/Finance/Hospital/Inventory/Patient/Scheduling/Workflow. Sinimportauto/root/services/health/jobs ni conexion.

D-63 resuelta para implementacion: A55 aceptada/integrada trasSHA/review/verify independiente952/952. Factories23runtime sinRoot/poolactivo.

D-64 (2026-11-05): A56 prepara dos configuraciones fuera scan: identidad (Access con proxyHttpServletRequest,IdentitySQL,lifecycleSQL,BrowserSessionSQL,SupportSQL,Errors/Advice) y seguridad (BCrypt12,bearerOnlyUsers,cadenaSQL). Settings/mapper/stores suministrados explicitamente;sin defaults/root/scan. Orden Trace->Host->Session ypoliticaslegacy exactas,cookieCSRF/origin/afterCommit intactos. Filtros locales dentrocadena,no@BeanFilter adicional. Tests servlet/chain mocksinpuerto/motor, no lospresentarcomoHTTP/backendreal. Sin editar legacy/stores/infra ni activar grafo parcial.

D-64 resuelta para implementacion: A56 aceptada/integrada trasSHA/review/verify independiente965/965. Factoriesidentidad/cadenaSQL fuera scan,politicaslegacy exactas,sin rootAOP/servidor.

D-65 (2026-11-05): A57 agrega factories12serviciosnegocio yPortalfull7args enconfigBusiness/Portal y2Tests,fuera scan sinimports/root/AOP/scheduling. CuatrostoresPortal obligatorios+SchedulingSQL compartido,SqlNULL enconstructoresmixtos yaaceptados. MismoAccess/Identity/Settings/mapper deA56/A54 ystoresA55 porqualifiers. Probarcompletitud/referencias,crossservicePortal.reserve->SchedulingSQL yjobsinertes,sin invocar conexiones. No cambios deproducto ni controladoresdelegadoresaun.

D-65 resuelta para implementacion: A57 aceptada/integrada trasSHA/review/verify independiente973/973. Negocio/Portal declarativosfuera scan,sinrootactivo.

D-66 (2026-11-05): A58 prepara SqlServerRuntimeRoot y ModeGuard mas2Tests,sin modificarHealthApplication/launcher. Root fuera scan sinmain/SpringBootConfiguration,imports explicitosA54-A57+16controladoresdelegadores (Browser/Support yAdvice yaA56),Settings binding,AOPclassproxy ydbHealthIndicatorA53. AutoConfigBoot4 con exclusiones datasource/Jdbc/Txmanager/Flyway/SQLinitializer/defaultDBhealth/Mail;usar clasesinstaladas reales. Guard temprano exige mode=runtime,Flywayfalse,SQLinitnever,probesenabledtrue ygrupos livenessState/readinessState+db;rechaza setup/Bootstrap/migrationcreds/jobs/override. Testsconfigautoconfigoffline sinSpringApplication/puerto/conexion. Launcher/setup/jobs/perfilQA seencargan despues;noactivarrootparcial.

D-66 requisitos externos del root: health.sqlserver.mode=runtime,
spring.flyway.enabled=false, spring.sql.init.mode=never,
management.endpoint.health.probes.enabled=true, liveness.include=livenessState
y readiness.include=readinessState,db bajo management.endpoint.health.group.
Sin valores de migracion/bootstrap en Environment; flags migrate/setup/bootstrap
rechazados incluso vacios, jobs/override solo ausente o false. Show-details y
show-components solo ausente o never. El guard no introduce defaults ni altera
System properties: perfil QA posterior debe suministrar los valores y vaciar
spring.flyway.url/user/password heredados. Este corte no cambia el launcher.

D-66 revisionA58 pendiente: R-A58-SCHED-ASSERT distingue ScheduledTasksObservationAutoConfiguration (metadatosBoot) de ScheduledAnnotationBeanPostProcessor/TaskScheduler activos. No excluir observacion inofensiva solo para hacer pasar test. Sustituir aserciongenerica por checks de tiposactivos y conservar el resto. Programador original tieneinstruccionmsg_d21e5a0d8674;cuota hasta15:31 impidecorreccion/cierreahora. No interpretar escalacion como salida de proceso ni reiniciar/cambiarcuentas, no activar/integrarWIP.


D-66 resuelta: A58 aceptada e integrada tras cuatro SHA y verify independiente
982/982 con JAR PASS. El guard conserva el rechazo temprano de configuracion
insegura; no excluye metadatos de observacion inofensivos. La prueba distingue
TaskScheduler y ScheduledAnnotationBeanPostProcessor activos. No activa launcher
ni acredita JDBC o HTTP real.


D-67 (2026-11-05): A59 conecta el main existente a una seleccion de fuente por
ApplicationEnvironmentPreparedEvent posterior a ConfigData. Instancia Spring
sin fuentes iniciales; modo ausente selecciona solo legacy, runtime solo la raiz
SQL completa A58; modo invalido falla sin fallback. Rechazar fuentes adicionales
spring.main.sources incluidas listas, y prevalidar SQL con el guard existente.
Retirar ejecucion Flyway del antiguo --migrate: el launcher rechaza migracion,
setup y bootstrap con error seguro antes de construir Spring; el proceso separado
sigue pendiente. Esto cambia deliberadamente el switch heredado para impedir
migracion MySQL accidental al elegir un perfil SQL. No habilita un migrador nuevo.
Perfil sqlserver-qa local, sin credenciales/DB por defecto, jobs apagados, Flyway
SQL init y bootstrap inertes, readiness SP separada de liveness, bind127.0.0.1.
Puerto/origen sinteticos coherentes (18080 predeterminado), TLS sin trust bypass
predeterminado. Cuatro rutas de tmp/sql-01-a59-spec.md, pruebas offline; no arranque
ni JDBC/HTTP hasta runner sintetico y setup con principal separado. Conservar
legacy sin modo SQL y demo independiente; no declarar migracion terminada.


D-67 resuelta: A59 aceptada con verify independiente990/990 y JAR PASS.
Launcher/perfil implementados; arranque y ConfigData end-to-end aun no probados.
Mantener separados QA HTTP de indisponibilidad y conexion JDBC exitosa real.


D-68 (2026-11-05): A60 es QA secuencial sin edicion versionada. Ejecutar JAR A59
real con ConfigData y perfil SQL QA en loopback, entorno hijo minimo sin secretos
existentes y destino JDBC deliberadamente inaccesible (puerto local reservado sin
listen). Verificar liveness UP, readiness/root DOWN, error publico saneado y
rechazos de modo/fuentes/setup sin fallback. Cerrar solo procesos propios.
Esto acredita HTTP real negativo, no JDBC exitoso ni permisos/integracion SQL.
La evidencia historica de TCP/NP deshabilitados no autoriza cambiar o reiniciar
la instancia SQL compartida. Setup/runner permanente y QA JDBC positiva siguen
pendientes; este corte permite encontrar defectos de arranque antes de resolver
el transporte. Ownership solo tmp/sqlserver-a60-qa; supervisor conserva docs.
