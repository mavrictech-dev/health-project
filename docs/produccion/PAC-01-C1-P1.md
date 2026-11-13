# PAC-01.C1.P1: revision propia y revocacion de vinculos, SQL offline

Contrato del arquitecto, 2026-11-11. Sustituye las opciones preliminares SOLO
para este paquete. Continuidad autorizada, Run run_624b9269b491, programador
recuperapiura@gmail.com en worktree separado y terminal/sesion retenidos,
cuenta por proceso --no-daemon. Usar nuevos IDs del preambulo. Leer AGENTS.md,
flujo/TAREAS y este documento CANONICOS en D:/Mavric/Health Project; el worktree
worker no contiene documentos vigentes. Supervisor unico escritor docs/tablero.

C0 task_cbe1631fad10/ctx_1ca0fc8f62cf aceptada ESTATICA:16artefactos,71referencias/
46archivos,13migraciones/11consumidores contrastados,695fuentes/726pines/
301historicos/21snapshots intactos. No gestion implementada, motor consultado
o prueba funcional nueva. E5 readonly real permanece aceptada y no se repite.

## Resultado y ownership exclusivo

Implementar SOLO un archivo NUEVO en worktree programador:
backend/src/main/resources/db/sqlserver/V14__patient_link_revision.sql.
Mas NUEVOS TEMP C1P1-* para casos de aceptacion, analisis sintactico, snapshots,
diff y reporte. No escribir aun verificador operativo, Java/API/UI, candidatos
o responsables sin cuenta. No editar V1-V13, helpers globales, triggers V7,
ACL heredadas, fuentes supervisor, producto/bundles/deps/config/AGENTS/docs.

OFFLINE: no SQL/HTTP/DPAPI/navegador/procesos operativos, servicios/TLS/UAC,
Docker, fixtures o cambios de datos. No ejecutar/aplicar V14, ni PRE/POST/suites
aprobadas/build. No cuentas globales, gasto/main/commit/push/FactuEz/shutdown.
Revisar dudas por Orca antes de ampliar ownership. C1.P1 succeeded significa
fuente preparada EN_REVISION, nunca migracion instalada o gestion validada.

## Decision de compatibilidad y limites funcionales

Se adopta endurecer el escritor EXISTENTE usp_patient_link_save con CAS,
manteniendo firma (@patient_id char(36),@input nvarchar(max)). Ninguna via
runtime antigua queda capaz de escribir sin revision. El PUT actual debera
migrarse en C2; clientes sin expectedRevision fallaran cerrado. Los11consumidores
inventariados se actualizaran solo con ownership posterior. No instalar/activar
este cambio contra un backend escritor viejo: instalacion/integracion sera un
gate posterior, con API compatible preparada y QA revisada.

GET B usp_patient_links_list conserva exactamente siete columnas/semantica,
roles, paginacion, orden e historicos; no editar V13 ni agregarle revision.
Crear responsables/contactos no crea usuarios, membresias o permiso portal;
ese modelo se especifica despues. Selector tenant/candidatos sera otro paquete,
no lookup global por correo ni creacion/invitacion de identidad en C1.

## Migracion V14

- SQLServer2022/compat160. Transaccion EXTERNA committable, principal separado
  CONTROL, dbo/roles y dependencias aceptadas como V13; sin BEGIN/COMMIT propio.
  Fallar antes de cambios si existe revision/nuevo SP o deriva del esquema,
  writer V5 o trigger/ACL esperados. Documentar guards y normalizacion exacta
  de definicion antigua; no ignorar diferencias semanticas, no reapply/repair.
- Agregar dbo.patient_links.revision INT NOT NULL con DEFAULT1 y CHECK>=1,
  validando filas existentes sin alterar PK, relationship, active, scopes o
  identidad de paciente/cuenta. No cambiar otras tablas/filas o datos historicos.
- ALTER PROCEDURE dbo.usp_patient_link_save; conservar firma y permisos objeto
  existentes. Crear SOLO un SP publico adicional dbo.usp_patient_link_edit_get
  (@patient_id char(36),@user_id char(36)). Sin nuevos helpers en este paquete.
- Nuevo lector: GRANT EXECUTE runtime y DENY bootstrap por OBJETO, nada amplio.
  Resto de ACL, ownership y denies intactos, sin tablas/DDL para runtime.
  Delta previsto respecto antecedente E5: +1SP/+2ACL de roles; 135/566 si la
  baseline134/564 sigue vigente. Esto NO es una medicion del motor en C1.P1.
- GO/batches y guards deben funcionar bajo caller stop-on-error y la misma TX;
  no SQL dinamico para queries de negocio, remediacion o bypass de los guards.

## Autoridad y transaccion de ambas operaciones

Exigir REQUEST exacto, TX externa y XACT_STATE=1 antes de resultados/cambios.
Validar IDs canonicos y contexto obligatorio, no convertir silenciosamente
valores largos a IDs validos. Tenant/actor vienen de contexto confiable, nunca
del JSON. Conservar cadena HostFilter/tenant/contexto; SQL revalida tenant,
sesion vigente, actor activo/verificado y membresia actual, no hostname literal.

Precision contractual C1.P1-Q1, 2026-11-11: validar tipo, longitud completa y
forma canonica de IDs de SESSION_CONTEXT/JSON ANTES de cualquier conversion
acotada. Las firmas CHAR(36) se conservan: dentro del cuerpo del SP se valida
el valor recibido, sin afirmar que puede recuperarse una longitud original ya
perdida en el binding SQL. C2 debe rechazar IDs HTTP no lowercase36 exactos
antes de pasar argumentos al adaptador/RPC, sin trim/substrings/coercion; probar
rechazo y cero llamadas SP para entradas largas. Documentar aparte la limitacion
de llamadas SQL directas a parametros fijos, no marcarlas como negativas
intraprocedimiento si SQL ya trunco el argumento. Sin cambiar firma/ownership.
Base oficial: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
(seccion ANSI_WARNINGS y parametros).

Actor interno ADM/REC sin plataforma ni PAC/RES mixtos, segun roles REALES en
memberships; hp_actor_roles no concede permiso. Para gestion/lectura de edicion
exigir guardas PORTAL, OPEN y tenant TRIAL/ACTIVE (como escritura). Esta lectura
es especifica de gestion, diferente de B readonly que no exige PORTAL.

Mantener bloqueos de actor/sesion/membresia y guardas relevantes hasta completar
la TX, revalidando despues de adquirirlos; no asumir que el filtro HTTP previo
los retiene. Key/range lock para CAS/alta en PK tenant/patient/user. Documentar
orden de locks compatible con operaciones existentes y futura matriz de dos
conexiones. No declarar concurrencia/revocacion probadas por revision estatica.
No reintentar deadlocks o comandos inciertos dentro del SP.

## CAS y comandos estrictos del writer

JSON case-sensitive con claves EXACTAS, sin duplicados, extras, coercion,
valores ausentes/null o tipo incorrecto. active BOOLEAN explicito. UUID userId
canonico lowercase36. expectedRevision JSON INTEGER lexical decimal0..2147483647;
no string/bool/fraccion/exponente/negativo/overflow. No truncamiento silencioso.

Con active=true, contrato exacto de CINCO claves:
{userId,expectedRevision,relationship,active,scopes}.
relationship no vacia tras comprobar espacios, <=80 unidades UTF16; conservar
valor entregado valido sin truncar. scopes ARRAY no vacio, unico, de strings
exactos APPOINTMENTS/DOCUMENTS/BILLING; sin desconocidos/duplicados o conversion.
Conservar el orden suministrado, sin interpretar valores historicos como grants.

Para activar/editar/reactivar, destinatario del mismo tenant con users activo,
email_verified y platform_role NULL, membresia ACTIVE y roles solo PAC/RES
(uno o ambos; ningun rol interno/plataforma mezclado). HUMAN/ANIMAL admiten ambos
roles portal, sin inventar una restriccion de dominio desde defaults de registro.
Revalidar elegibilidad bajo locks en el comando. BILLING conserva regla heredada:
writer exige PORTAL; acceso de saldo sigue exigiendo FINANCE en el consumidor.
Un scope no contrata/habilita un modulo. No cambiar consumidores portal ahora.

Con active=false, contrato exacto de TRES claves:
{userId,expectedRevision,active}.
Es retirada de fila EXISTENTE, no alta inactiva. NO pedir relationship/scopes,
ni exigir elegibilidad actual del destinatario o membresia/rol portal para
retirarlo. Conservar byte a byte relationship/scopes historicos, incluso vacios,
desconocidos o JSON valido no utilizable para una concesion. No borrar historia,
cuenta, membresia o sesiones globales. Siempre exigir autoridad actual del actor.

expectedRevision=0 solo crea una fila ACTIVA ausente y revision1; existencia
con0 produce conflicto. expectedRevision>=1 exige fila existente y version
igual, tanto SET como retirada. Ausente nunca se convierte en alta por version
positiva; retirada ausente es404neutro. Version desigual es409sin cambio/audit
semantico. Alcanzado INTMAX es409antes de aritmetica/mutacion. Todo comando
ACEPTADO incrementa revision, incluso SETidentico o retirada ya inactiva; no-op
no evade CAS. No confundir revision con clave idempotente o confirmacion de un
intento cuya respuesta se perdio. No escribir revision del paciente.

Writer devuelve un unico resultset/una fila, CINCO columnas explicitas:
tenant_id,patient_id,user_id,active,revision. Es ACK del estado/version, sin
proyectar scopes historicos malformados como una concesion o datos normalizados.
Esta respuesta cambia la proyeccion vieja de seis campos; C2 debe migrarla.

## Lectura atomica de edicion y errores

usp_patient_link_edit_get devuelve UNA fila y OCHO columnas explicitas:
tenant_id,patient_id,user_id,user_name,relationship,active,scopes,revision.
Datos/version se leen bajo la misma TX/locks; no emparejar un GET B viejo con
una revision posterior para editar. Incluir vinculo historico aunque destinatario
este inactivo/sin membresia; scopes se conserva como JSON historico, no permiso.
API posterior validara/proyectara esos valores sin ejecutarlos ni renderizar
JSON arbitrario; grant nuevo siempre requiere scopes explicitos validos.
Paciente/vinculo ausente o de otro tenant:404neutro, sin revelar cuenta ajena.

Usar errores HP existentes:51000invalid/400,51001forbidden/403,51002notfound/404,
51003conflict/409 y guardas51004/51005 intactas. Sin errores SQL/PII al cliente.
Ninguna fila parcial o resultado extra de helpers. No manejar error para producir
una respuesta exitosa si TX no es committable; rollback pertenece al caller.

## Auditoria y aceptacion posterior

Cada writer aceptado genera EXACTAMENTE un PORTAL_LINK_CHANGED semantico,
target patient, actor/request/tenant actuales, metadata escalar limitada a
userId,active,previousRevision,revision,operation(SET/DEACTIVATE). No relacion,
scopes crudos, correos, tokens/secretos. Mismo TX que la fila. Cambio fallido,
CASperdedor o rollback no deja evento semantico persistente.
V7 sigue generando eventos de fila segun su proyeccion actual; puede omitir
revision-only/no-op. No exigir ni afirmar una cuota fija de trigger por comando:
la matriz diferencia evento semantico y cambio proyectado. No editar V7.
Lectura edit_get positiva genera1 PATIENT_LINK_EDIT_READ con metadata userId y
target patient; negativas0. Audit fallido revierte todo, sin compensaciones.

Entregar plan de casos TEMP con entradas/salida/error/audit/filas esperados:
crear0,create/create,edit/edit misma version,activar/desactivar/reactivar,
historico vacio/desconocido/no-array/destinatario sin membresia, ausente, stale,
INTMAX/no-op, JSONausente/duplicado/extra/tipos/case, tenant/contexto/rolesforjados/
PACRESmixtos/sesionrevocada/IDENTITY/OPEN/PORTAL/SUSPENDED, ACLruntime/bootstrap,
TXautocommit/doom/auditfallido y lector de edicion. Dos conexiones y revocacion
posterior al commit seran QA real de otro gate, no ejecutarlas en P1.

Verificar offline batches/guards/firmas/proyecciones/objetos/ACL y congelacion
V1-V13; analizador TSQL local si ya existe, sin instalar dependencias. Documentar
que validacion sintactica/estatica no prueba ejecucion del motor. No fabricar
tests de motor ni ejecutar suites no relacionadas para dar un PASS aparente.

TEMP/C1P1-programmer-report.json con IDs, fuente/diff/snapshot/SHA, baseline695
antes y unica adicion owned despues (696), V1-V13/pines726/historia intactos,
casos/guards examinados/comandos/exits/limitaciones y conflictos encontrados.
No edicion supervisor o copia de todo checkout. Si falta informacion, preguntar
por Orca antes de ampliar. worker_done succeeded EN_REVISION solo si preparado;
revision e integracion supervisor y nuevo paquete QA antes de conexion/instalacion.
ACK todos los lotes segun guia instalada antes de worker_done; conservar terminal.
