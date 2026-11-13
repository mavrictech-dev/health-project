# RUC-01.P1: SQL Server y API para RUC de tenant

Contrato de implementacion OFFLINE, supervisor2026-11-13. Requisito directo y
aclaracionusuario: RUC + correo + contrasena. Leer AGENTS/flujo/TAREAS y
RUC-01-CONTRATO.md CANONICOS en D:/Mavric/Health Project; ese documento define
reglas/errores/limites de negocio y seguridad. Misma pareja/cuentas por proceso/
--no-daemon/worktree/terminal/sesion retenidos; IDs NUEVOS del preambulo.
Supervisor unico escritor docs. No pedir otra confirmacion al usuario.

No iniciar mientras task_7a1bed038dbc/ctx_14ff3400841b siga abierta o tenga
ownership de fuentes congeladas. Supervisor despacha al quedar libre el
programador; si TaskDocker falla debe revisarla antes de cambiar dependencia.
Actualizacion D-87.BK: esa TaskDocker ya terminoFAILED y fue revisada; schema
Docker vacio y fuentes intactas. Ownership liberado y RUC.P1 puestaREADY
explicitamente para implementacionOFFLINE, sin dependencia tecnica de que la
instalacion Docker haya pasado. No reintentar Docker ni corregirBOM aqui.

## Ownership permitido en worker

- NUEVA migracion SQL Server V15__tenant_ruc.sql si numero libre; verificar
  antes. Si ya existe una migracionV15 ajena, consultar sin sobrescribirla.
- backend/src/main/java/com/mavric/health/saas/domain/Requests.java
- backend/src/main/java/com/mavric/health/saas/api/PlatformController.java
- backend/src/main/java/com/mavric/health/saas/application/PlatformService.java
- backend/src/main/java/com/mavric/health/identity/AccountLifecycleService.java
- backend/src/main/java/com/mavric/health/identity/AuthController.java
- backend/src/main/java/com/mavric/health/identity/BrowserSessionController.java
- backend/src/main/java/com/mavric/health/identity/SessionFilter.java
  (D-87.BL: solo skip POST exacto /api/public/tenant-space despues de limpiar
  actor/context, sin autenticar/tocar cookie/token previo)
- backend/src/main/java/com/mavric/health/identity/IdentityService.java
- backend/src/main/java/com/mavric/health/tenancy/TenantRef.java
- backend/src/main/java/com/mavric/health/tenancy/HostFilter.java
- backend/src/main/java/com/mavric/health/persistence/sqlserver/SqlServerPlatformStore.java
- backend/src/main/java/com/mavric/health/persistence/sqlserver/SqlServerAccountLifecycleStore.java
- backend/src/main/java/com/mavric/health/persistence/sqlserver/SqlServerIdentityStore.java
- backend/src/main/java/com/mavric/health/persistence/sqlserver/SqlServerSecurityStore.java
- backend/src/main/java/com/mavric/health/persistence/sqlserver/SqlServerProcedure.java
- Helpers NUEVOS acotados RUC/DTO bajo shared/identity si necesitan compartir
  validacion; reportar rutas y no refactorizar codigo ajeno.
- Pruebas nuevas y ajustes estrictamente necesarios en tests de esas clases
  bajo backend/src/test/java; no cambiar aserciones para ocultar regresiones.
- backend/src/test/java/com/mavric/health/identity/SessionFilterRucSpaceTest.java
  (ampliacion explicita D-87.BL para probar ruta anonima exacta y no bypass)
- backend/src/test/java/com/mavric/health/identity/AccountLifecycleControllerSqlServerTest.java
  (D-87.BM: conservar202neutro/casosduplicados/errores originales; no se amplia
  ownership del controlador de produccion para cambiar esa respuesta)

Mas TEMP NUEVOS HealthRucP1-* para snapshot/diff/SQL/modelos/reporte. Si otro
archivo es necesario, consultar supervisor antes de ampliar. No frontend/docs/
AGENTS/config/deps/V1-V14/rendererDocker/verificadorLPC/artefactosprevios.
No SQL real/JDBC/HTTP/runtime/Flyway/servicios/Docker/Somee/AgendlyCitas.
No commit/push/main/publicacion/gastos/datosreales/credencialesglobales.

## Implementacion y pruebas

Migracion exige V14exacta/CONTROLseparado/TXexterna, checks de forma/unicidadRUC
y revisionCAS. Abortar antesDDL si legacy sin mapeo; no inventarRUC/default,
borrar tenant, editar canonicalprevio o instalar parcial. Nuevos y ALTERSP
deben conservar autoridad/transacciones/auditoria y contrato de resultsets de
campos previos; actualizar lectores/runtimeEXECUTEsolo aprobados. No SQLdirecto
en Java, ni fallback MySQLnuevo. ResolverRUC/validarlo/leerlo/editarlo viaSP.
Preservar host-versus-tenant/sessioncontext contra input no confiable.

Implementar ruc requerido en ambas altas de tenant, retorno RUC/revision,
PUTperfil SAD conCAS y evento, y login de tenant RUC+email+password con DTO
contextual separado de invitacion/portal/administracion. Resolver central por
SP con salida hostnamecanonico acotada, sin cookies sesion antes de login real.
No usar password en resolucion de espacio ni crear endpoint de autologin.
Excepcion publica D-87.BM: AccountLifecycleController NO cambia su contrato
202+mensaje neutro de aceptacion/emailExists ni se expone RUC/revision/tenantId.
Ampliacion SOLO de su test existente para comprobar compatibilidad. SP y
CreatedTenant interno retornan valores reales RUC/revision y se comprueban;
altaSAD/listado/detalle/contexto autorizado los exponen. No fabricarACK o
revision1 cuando no se creo nada. Preservar errores400/403/404/409/500 y rollback
de fallos como hoy, sin capturar cualquier excepcion para devolver202. La
validacionRUC obligatoria de alta tenant se aplica uniformemente antes de
emailExists; portal conserva contrato propio y no crea tenant por incluirRUC.
Contrato de resolver acordado D-87.BL: POST /api/public/tenant-space, DTOcerrado
{ruc}, salida SOLO {hostname} canonico validado bajo Settings.baseDomain,
solo hostplataforma/preauth. SessionFilter ignora sesion previa SOLO para POST
en esa ruta exacta, despues de limpiar health.actor/SecurityContextHolder;
sin resolve/touch/membership/sessionRPC ni necesidad deCSRF de sesion previa.
La ruta ya es publica en configuraciones existentes: no ampliarlas. Exigir
guardasHost/SP/canonico y limite de solicitudes anonimas del flujo. Probar cookie
vieja/tokenvalido/malformado ignorados en esa operacion, cero RPCsesion/actor/
SetCookie, y rutas vecinas/otrosmetodos sin ese skip. No leer password enresolver.

Pruebas significativas: rechazo faltante/numerico/Unicode/masmenos11digitos,
duplicado, CASstale e inputextra; alta publica ySAD atomicas; edicion soloSAD/
tenantID estable/audit; login RUCincorrecto/otrohost/otromembership deniega sin
sesion; login valido crea sesion tenant correcta; plataforma e invitaciones
no se confunden. Verificar orden de llamadas SP/contexto/transaccion y firmas
runtimeEXECUTE. ParserSQL160 del NUEVO archivo comprueba sintaxis, no motor.
Maven apropiado al alcance, registrar tests nuevos y regresion completa una
vez si pasan; no repetirfrontend/QA ajena. No empaquetar/activar backend nuevo.

Antes de editar comprobar root/rama/worktree/status y baseline de fuentes;
preservar cambios existentes y ownership. Entregar TEMP/HealthRucP1-programmer-report.json
con IDs, rutas/SHA/diff, firmas/columnas/ACL exactas y cambios API, pruebas,
conservacion y limitaciones. EN_REVISION: fuenteOFFLINE no prueba migracion,
sesionSQLreal o UIlista. Ask al ampliar y STOP en bloqueoreal, sin improvisar
target/backfill. ACKdeliveryId y todoslotes antes de worker_done; mantenerterminal.
