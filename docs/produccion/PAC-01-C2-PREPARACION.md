# PAC-01.C2: contrato de API para revision y retirada de vinculos

Diseno supervisor, 2026-11-12. Preparado mientras el programador corrige
C1.P1.R1 (task_ab40e0008138/ctx_ea90d3f41027). NO es un Dispatch ni autoriza
edicion simultanea de fuentes. Activar el paquete solo despues de revisar R1
y fijar el hash final V14. No instalar V14 ni arrancar backend contra API vieja.
El orden vigente es R1 -> API compatible offline -> verificador/QA SQL revisados
-> instalacion reconciliada -> UI/QA integrada, con gates propios.

AGENTS/PAC-01-C1-P1/Q1/D-87.AI/AJ vigentes; SQLServer2022 y 100%SP. Sin Somee,
AgendlyCitas, secretos, datos reales, despliegue o servicios en esta preparacion.
Los contactos sin cuenta y candidatos requieren contratos SQL posteriores.

## Recursos y datos de entrada

Conservar PUT /api/patients/{id}/links y endurecer su unica via de escritura.
Nuevo GET /api/patients/{id}/links/{userId} para snapshot de edicion V14.
GET /api/patients/{id}/links conserva siete campos, paginacion/orden/autoridad B.

PUT exige objeto JSON estricto con conjunto de claves condicionado por active:

```json
{"userId":"dd000000-0000-4000-8000-000000000001","expectedRevision":0,"relationship":"TITULAR","active":true,"scopes":["DOCUMENTS","APPOINTMENTS"]}
```

```json
{"userId":"dd000000-0000-4000-8000-000000000001","expectedRevision":3,"active":false}
```

SET tiene exactamente5claves; retirada exactamente3, ni relationship/scopes
presentes con null. Faltantes/null/extra/duplicados/tipo/case incorrectos fallan
400 antes de RPC. active boolean EXPLICITO, nunca defaultfalse. expectedRevision
token JSON entero decimal0..2147483647: rechazar string/bool/fraccion/exponente/
-0/negativo/overflow, sin coercion. JSON invalido/cola adicional tambien400.

No usar Set que borre duplicados de scopes antes de validarlos. Lista ordenada
unica no vacia de APPOINTMENTS/DOCUMENTS/BILLING; sin valores desconocidos/null/
duplicados o espacios anadidos. relationship string no vacia tras comprobar
espacios, <=80unidadesUTF16, conservar valor valido completo. Definir helper
local coherente con whitelist de espacios de V14, incluidas NBSP y separadores
Unicode; no depender solo de String.isBlank. Para retirada no recuperar ni
validar relacion/scopes historicos como requisito de concesion.

Decodificacion estricta limitada a este DTO/ruta. No cambiar ObjectMapper
global ni la semantica de todos los otros controladores. Un Map/JsonNode
construido despues de perder duplicados o texto numerico no acredita rechazo
original. El decoder debe examinar tokens/nombres duplicados antes de colapsar
la entrada, usando bibliotecas Jackson ya instaladas. No nuevas dependencias.
Validar tambien la entrada de llamadas Java directas al store; el HTTP decoder
no sustituye el limite de persistencia ni el SP.

Todos los IDs de ambos paths y userId del body: string ASCII lowercase36 con
forma UUID canonica EXACTA, sin trim/substrings/coercion; antes de adaptador/RPC.
Q1 obliga negativos con UUIDvalido+sufijo y cero llamadas. No basta CHAR36
parametrizado. Contexto/request/tenant/actor/hash de sesion siguen confiables;
errores de contexto interno no se reinterpretan como ID del usuario invalido.

## Autoridad, SP y resultados

Ambos recursos requieren sesion/host/tenant/dominio concordantes, actor ADM/REC
sin SAD/SOP/PAC/RES mezclados, PORTAL y TRIAL/ACTIVE. SQL revalida autoridad
real, modo OPEN, sesion/membresia actual y locks. GET edicion requiere guardas
de gestion y difiere de listado B readonly, que conserva sus permisos previos.
No usar permiso PRO de editar ficha para gestionar vinculos.

Conservar firma PATIENT_LINK_SAVE (patient_id CHAR36,input NVARCHARMAX) y anadir
solo descriptor PATIENT_LINK_EDIT_GET para usp_patient_link_edit_get con
patient_id CHAR36,user_id CHAR36. Runtime; ninguna capacidad BOOTSTRAP/IDENTITY
o nombre SQL proporcionado por cliente. Una llamada de negocio por comando o
lectura, contexto/reset internos existentes; sin GET previo, Sql directo o
auditoria Java duplicada. TX Spring/TransactionTemplate, fallo/commit/rollback
saneados y sin retry automatico. Legacy service.link sin store falla cerrado.

ACK HTTP exactamente5campos: tenantId,patientId,userId,active,revision. Validar
identidad/tenant exactos, active Boolean igual al comando y revision Integer:
crear0->1, modificar n->n+1, comparacion sin overflow. Rechazar resultsets/filas
adicionales, claves inesperadas/faltantes/tipos falsos/inconsistencias como500
saneado y rollback. Ningun relationship/scopes se obtiene del ACK ni se fabrica
con el borrador. expectedRevision=INTMAX llega al SP y produce409; no calcular
un valor entero desbordado ni aceptar confirmacion falsa.

GET edicion exactamente8campos: tenantId,patientId,userId,userName,relationship,
active,scopes,revision. Identidades coinciden con path/tenant; userName String
<=160, relationship String<=80, permitidas cadenas vacias historicas; active
Boolean, revision Integer>=1. scopes es valor JSON historico valido, puede ser
array vacio/desconocido/duplicado, escalar, objeto o null. Copia segura de datos
JSON, sin reinterpretarlo como grant, convertirlo en lista valida ni exigir
elegibilidad actual de destinatario. No incluir correos/hash/datos ajenos.
Ese valor no es HTML ni fuente automatica de alcances del futuro formulario.

Errores conservan mapper SQL aprobado y problem+json:400/401/403/404neutro/409/
500. No inferir que todo409 es CAS, pues puede ser READ_ONLY/deadlock/constraint.
Sin mensajes del motor al cliente. La respuesta solo se entrega despues de
completar la unidad Spring, no presentar ACK previo como prueba de commit.

## Ownership propuesto para Dispatch posterior

Un paquete secuencial, programador unico escritor de estas fuentes en su worktree:

- patients/domain/Requests.java y nuevo decoder local de Link con ruta exacta
  a fijar en Dispatch; patients/api/PatientController.java;
  patients/application/PatientService.java.
- persistence/sqlserver/SqlServerPatientStore.java y SqlServerProcedure.java.
- Suites existentes SqlServerPatientStoreTest, PatientServiceSqlServerTest,
  PatientLinksControllerSqlServerTest y SqlServerProcedureContractTest; nuevos
  tests locales de gestion/decoder con nombres explicitos en el Dispatch.
- backend/scripts/verify-api.py: migrar solo las dos invocaciones del writer,
  crear con expectedRevision0, capturar ACKrevision y retirar con cuerpo de3
  claves/version retornada. NO ejecutarlo en este paquete offline.

Prefijos Java relativos a backend/src/main/java/com/mavric/health y tests a
backend/src/test/java/com/mavric/health. Supervisor conserva docs/tablero.
Si aparecen otros consumidores fuera de estas rutas, consultar ownership antes
de editarlos. No tocar V1-V14, executor, Errors/Checks globales, roles/ACL,
frontend, drivers/config, verificador E5 readonly ni historia de QA.

Catalogo: mantener snapshot V3-V8 cerrado y el delta V13 pinneado. Anadir solo
delta V14 explicito (writer conserva firma y nuevo lector) con hash FINAL R1.
Catalogo pasa109->110descriptores, dos bootstrap; no relajar parser historico
para aceptar ALTER arbitrarios/objetos extra ni reescribir hashes antiguos.

## Aceptacion offline y limites

Pruebas significativas decoder/MockMvc/store/servicio para ambas operaciones:
positivos HUMAN/ANIMAL, alta/edit/reactivar/retirada, revision/campos y una llamada;
actor/tenant/host/rolesmixtos/PORTAL/suspension y errores saneados; entrada estricta
y IDs largos antes de SP, multiples/cero conjuntos/filas/columnas inconsistentes,
rollback/fallo commit, no fallback, historicos heterogeneos en lectura y retirada
sin borrador de concesion. Validar scopes unicos ordenados y UnicodeUTF16.

GET B/A/history y contratos existentes conservados. Suites offline afectadas y
Maven completo una vez con su contexto local autorizado; no Docker/arranque,
fixtures, HTTP real, JDBC/SQL, DPAPI o navegador. No afirmar CAS o concurrencia
probados por mocks. Integracion supervisora por archivos revisados y hashes,
sin activar producto hasta gates posteriores. UI/editor/candidatos, pruebas
de2conexiones, auditreal e instalacion siguen pendientes expresos.
