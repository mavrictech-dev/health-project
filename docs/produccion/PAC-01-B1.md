# PAC-01.B1: lectura auditada de vinculos de pacientes por SP

Contrato supervisor, 2026-11-09. A/R1/E1 aceptadas en QA real y entrega revisada
publicada4d461e7094563494aa9098362683cadf0f6fea6b en health/production-wave0.
PAC-01 sigue parcial: no existe lectura administrativa de vinculos para conectar
responsables a la ficha. PatientController solo tiene PUT/{id}/links y GET/history;
PatientService/SqlServerPatientStore llaman usp_patient_link_save para escritura.
Este paquete prepara UNA lectura SQL nueva; no cierra interfaz/API/vinculacion.

## Arquitectura y ownership exclusivo

Crear solo estas dos rutas en worktree separado del programador:

- backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql
- backend/scripts/verify-sqlserver-patient-links-read.sql

Leer D:/Mavric/Health Project/AGENTS.md, TAREAS/DECISIONES (D-09 y D-86) y contrato
actual desde supervisor4d461e7. WorkerHEAD sigue0b24487 con historial sin commit:
NO asumir que contiene V10..V12; consultarlas desde checkout supervisor. Conservar
todas sus fuentes/hashes previos. Supervisor unico escritor de documentos/tablero.
No Java/frontend/config/dependencias ni otras rutas. Consultar antes de ampliar.

NO ejecutar SQL/API/DPAPI/servicios ni pruebas de motor en este Dispatch. Su entrega
es artefacto SQL y prueba de motor preparada, sin aplicarlos. Supervisor revisara
antes de la compilacion/prueba rollback-only posterior, con principal migrador
separado y QA exclusiva. No activar Java ni presentar migracion como aplicada.
No commits/push/main/FactuEz ni limpiar/reset/stash/alterar datos existentes.

## Contrato de la nueva entrada publica de persistencia

Nombre dbo.usp_patient_links_list. Parametros posicionales:

```text
@patient_id char(36), @limit int=50, @offset int=0
```

Una resultset, sin total ni resultsets auxiliares, columnas SQL exactas:

```text
tenant_id char(36), patient_id char(36), user_id char(36),
user_name nvarchar(160), relationship nvarchar(80), active bit, scopes nvarchar(max)
```

scopes es el JSON existente, no strings concatenados ni un segundo contrato.
Adaptacion camelCase/JSON tipado vendra en paqueteJava posterior; no cambiarla ahora.
Orden determinista user_name,user_id; limite1..200 (NULL50, menores1->1, mayores200->200),
offsetNULL/negativo->0. El cliente futuro pedira21 y mostrara20 para siguiente sin
inventar total, igual al directorio. Incluir vinculos activos e inactivos para
administracion; no ocultarlos por estado del usuario o membresia. Usuario global
solo se une a vinculos YA existentes del paciente/tenant; no hay directorio global,
busqueda de identidades ni alta/resolucion de contactos en este paquete.

NO retornar correo, password_hash, credenciales, tokens, sesiones, historias,
documentos ni datos de otros pacientes. Campos limitados a la proyeccion anterior.
La lectura no concede/modifica scopes ni autoriza acceso a historia/portal. Las
cuentas que ya no esten activas pueden seguir figurando como referencias historicas
del vinculo: active describe el vinculo, no una promesa de acceso efectivo al portal.

## Autorizacion y transaccion

Exigir transaccion EXTERNA del llamador (usp_require_transaction) y scopeREQUEST
exacto. Tenant/actor/token provienen de SESSION_CONTEXT configurado por el adaptador,
nunca parametros de tenant/actor, SQL arbitrario o claims de rol del frontend.
Usar helpers existentes usp_clinical_scope/usp_require_actor para validar sesion
y membresia actuales: ADM o REC del mismo tenant, usuario activo/verificado,
sesion vigente y membresiaACTIVE. Rechazar plataforma SAD/SOP y tenantNULL.
Como contrato administrativo del shellA: rechazar tambien si la membresia actual
incluye PAC o RES, incluso combinada conADM/REC. Validar roles reales en DB, nunca
hp_actor_roles declarado. PRO/ASI/AUD/CAJ u otros sinADM/REC no obtienen esta lectura.

Lectura administrativa de datos existentes sin exigir contratoPORTAL activo ni
estado de escritura (debe poder consultarse para administracion en modo suspendido/
readonly). Esto no habilita escrituras o consumo del portal: PUT existente conserva
su guardaPORTAL/estado actual. No usar usp_write_guard en la lectura nueva.

patient_id debe ser UUID canonico minusculo; NULL/formato invalido->51000HP_INVALID.
Paciente inexistente o de otro tenant->51002HP_NOT_FOUND con el mismo mensaje
neutral, sin revelar existencia ajena. Sin sesion/rol/scope->51001HP_FORBIDDEN.
Validar paciente dentro del tenant antes de listar, incluso con resultado vacio.

Cada lectura autorizada/valida registra exactamente UN evento de auditoria mediante
usp_audit_event, actionPATIENT_LINKS_READ,target_id=patient_id,actor/tenant reales.
Metadata minima (paginacion si se necesita), sin nombres, relaciones o scopes.
Audit y lectura en la transaccion del llamador, sin BEGIN/COMMIT/ROLLBACK autonomos.
Ausencia de filas se devuelve como resultsetvacia; no equivale a paciente inexistente.
Sin SQL dinamico, EXECUTEASOWNER o nuevas guardas privadas con permisos adicionales.

## Evolucion de esquema y privilegios

V1..V12 aplicadas se conservan byte a byte. V13 crea SOLO este SP nuevo y su ACL:
GRANT EXECUTE sobre ese objeto a hp_runtime_executor, DENY EXECUTE sobre ese
objeto a hp_bootstrap_executor. Sin GRANT OPTION, roles/usuarios/logins nuevos,
permisos de tabla/DDL/esquema ni cambios a SPs existentes. Runtime solo EXECUTE.
Antes de cualquier DDL/ACL: exigir transaccion externa, CONTROL de principal de
migracion separado, dbo con owner esperado, roles existentes correctos y ausencia
del nuevo objeto. No repurpose objetos/principales ni CREATE OR ALTER silencioso.
Errores de precondicion deben ocurrir antes de mutar. Archivo nunca COMMIT.

La ACL anterior se conserva exacta; delta esperado+2permisos de objeto,562->564
en esta QA sin historialFlyway, o571->573 si existe el historial opcional aceptado
por V8. No reejecutar V8 ni herramientasA66/A67 de setup, no exigir filas de negocio
vacias. No agregar tablas/columnas/indices/triggers ni cambiar firma de otros SP.

## Prueba de motor que debe quedar preparada (NO ejecutarla aun)

SQL de QA con destino exacto health_project_sqlserver_qa_isolated_20261105,
guardas de marcador/base/principal, fixtures unicas .example.test, sin usar o
modificar los25pacientes PACQA de la entregaA. Todo rollback-only, sin datos o DDL
de prueba persistentes; no borrados de compensacion. No crear logins/secretos ni
abrir otra base/instancia. Diseñar fases/conexiones segun XACT_STATE cuando THROW
deja transaccion doomed; no simular negativos ni ocultar errores. Si requiere
tercera ruta o cambio de contrato, preguntar por Orca antes de ampliar.

Matriz: ADM yREC positivos, humano/animal, activos/inactivos y referencia a usuario
inactivo; cero vinculos de paciente existente; paginas/orden/topes/null/offset;
auditoria1por lectura/actor correcto y rollback; rechazo de paciente ajeno,
plataforma,PRO,ASI,AUD,PAC,RES,mixtoADM+PAC, sesion revocada/noverificada/membresia
inactiva/scopeincorrecto/autocommit. Intentos reales de SELECT/INSERT/DDL/directa
a privados denegados al principal runtime; bootstrap no ejecuta entrada nueva.
Contrastar deltaACL+2 y conservacion exacta de562/571 permisos anteriores. Nunca
contar permisos como prueba de negocio ni prueba modelada como motor ejecutado.

## Entrega

Aclaracion D-87.A (pregunta msg_21e8d28abfea): se autorizan dos fases EXPLICITAS
en el mismo archivo de prueba. PRE_APLICACION puede crear V13/fixtures y probar
ACL/lecturas/negativos dentro de transacciones revertidas; no persiste nada.
AUTOCOMMIT_POST_APLICACION exige V13 ya instalada por decision supervisora posterior,
en conexion nueva con @@TRANCOUNT=0 e IMPLICIT_TRANSACTIONS OFF. No instala objeto,
crea fixtures ni hace COMMIT para facilitar el caso. Ejecucion como runtime
restringido, rechazo51000 por guarda transaccional antes de lectura/auditoria,
verificando que no quedaron transaccion ni cambios persistentes. Si el SP no esta
instalado, esta fase es PENDIENTE_POR_PRERREQUISITO, nunca PASS ni omitida en silencio.
El informe separa resultados/fases; ambos siguen NO_SQL_EXECUTED en este Dispatch.
Mantener ownership de las mismas dos rutas. No habilita aplicar V13 o ejecutar
ninguna fase ahora; instalacion y QA real requieren encargo supervisor posterior.

Informe TEMP:2SHA/delta/ownership, contrato y guardas, como ejecutar la prueba
rollback-only despues de review, matriz cubierta y limites. Validar estructura,
revision estatica y fuentes previas; no repetir suites Java/Next/demo sin cambios.
En este TaskNO_SQL_EXECUTED es el resultado esperado de la politica: no presentar
compilacion/matrizSQL comoPASS. Artefactos completos pueden entregarse succeeded
EN_REVISION, pero solo supervisor aceptara tras comprobar motor en etapa posterior.
Procesar/ack todos los lotes antes de done, conservar terminal/sesion.
