# RUC-01: tenant con RUC y acceso RUC + correo + contrasena

Arquitectura/aceptacion del supervisor, 2026-11-13. Requisito directo del
usuario por dos capturas: registrar tenant con RUC, conservarlo en SQL Server,
editar datos del tenant y utilizar RUC para iniciar sesion. Aclaracion expresa
del usuario: RUC + CORREO + CONTRASENA; no crear nombre de usuario independiente.
Este trabajo se suma a la continuidad SQL local, no la cancela. Somee y
AgendlyCitas siguen fuera de alcance; sin publicacion/despliegue o datos reales.

## Hallazgos del repositorio

- V1 dbo.tenants tiene9columnas, slugunico y ningun RUC/revision de perfil.
- Requests.Tenant y AccountLifecycleService.Register no reciben RUC.
- AuthController.Login recibe email/password y tambien se reutiliza en
  invitaciones; evitar exigir RUC accidentalmente a otro tipo de operacion.
- HostFilter fija health.tenant desde hostname; IdentityService.loginSql
  separa plataforma SAD/SOP y memberships de tenant. No sustituir esa frontera
  con un tenantId enviado libremente por el navegador.
- PlatformController permite crear/consultar tenant y cambiar estado, pero
  carece de endpoint para editar nombre/RUC/zona horaria.
- AuthAccess/SessionProvider/mock y runtime-clients/platform-types/platform
  omiten RUC. La captura /saas/acceso corresponde al acceso central; la nueva
  entrada de clientes debe mostrar claramente RUC, correo y contrasena.
- spec.json S01 ya menciona RUC del espacio; eso no acredita implementacion.

## Reglas de dominio y persistencia

RUC de Peru: identificador textual de11digitos ASCII, sin conversion a numero,
exponentes, espacios internos, guiones o digitosUnicode. Formato confirmado en
fuente primaria: https://centrovirtual.sunat.gob.pe/tramites/inscribete-ruc .
Validacion local de formato, NO afirmar verificacion SUNAT/estado tributario
ni llamar servicios externos o cargar padrones. Datos QA estrictamente ficticios.

Decision de producto: un RUC identifica un tenant; sus sedes comparten ese
tenant. RUC obligatorio para TODO tenant nuevo, tanto alta publica como SAD.
Unicidad y formato en BD, ademas de validacion API/UI; conflictos de alta/edicion
deben ser atomicos, tambien en dos solicitudes concurrentes. Idtenant UUID,
slug, sesiones, roles, especialidades, suscripcion y pacientes no se reasignan
al cambiar nombre/RUC. RUC no reemplaza correo ni contrasena.

Nueva migracion incremental SQL Server despues de V14 (V15 si sigue libre al
iniciar). No editar V1-V14 ni sus hashes/pines para anadir columnas. Columna
ruc VARCHAR(11) NOT NULL con CHECKASCII/DATALENGTH11 y UNIQUE; revision de
perfil INT>=1/default1 para CAS de edicion. Ningun RUC inventado/default de
relleno para tenants previos: si hay filas sin mapeo real autorizado, preflight
de migracion debe abortar antes de DDL/datos y reportar BACKFILL_REQUIRED.
Tratamiento de legacy separado con datos autorizados; no borrar tenants o
pasarlos silenciosamente por validos. La DB Docker nueva se prepara sin tenants.

100% acceso de datos runtime por SP parametrizados, incluidas lecturas,
resolucion RUC, validacion de acceso, alta/edicion y auditoria. Runtime EXECUTE
solo SP aprobados, sin tablas/DDL/CONTROL. Migracion con principal separado.
La migracion debe partir de V14 exacta o fallar antes de cambios; compatibilidad
dejarse explicita, nunca activar backend parcial como migracion completa.

## Contratos API/seguridad

Alta: /api/auth/register (alta de espacio en host plataforma) y
POST /api/platform/tenants reciben ruc:string requerido; creacion atomica con
owner/sede/suscripcion/specialties y audit existente. Respuestas/listados/detalle
incluyen ruc y revision sin filtrar secretos. No convertir alta de usuario
portal en alta de tenant ni exigir RUC a invitacion/recuperacion por reutilizar DTO.
Excepcion HTTP publica expresa D-87.BM: POST /api/auth/register conserva202
y mensaje neutro constante en aceptacion/emailExists, tanto alta publica como
portal. No devolver ruc/revision/tenantId o ACK de creacion en esa respuesta;
no inventar revision1 desde el borrador. PersistenciaRUC/revision se acredita
en SP/CreatedTenant interno real y altaSAD/listado/detalle/contexto autorizado.
Errores400/403/404/409/500 vigentes no se convierten en202 para ocultar fallos.
La UI distingue solicitud aceptada de tenantcreado, y no navega/autentica por202.

Edicion: PUT /api/platform/tenants/{id}/profile, SOLO SAD, DTO cerrado
{name,ruc,timezone,expectedRevision}. No permitir slug/id/kind/domain/owner/
roles/estado/cuotas por este endpoint. expectedRevision entero estricto y
coincidente, actualizacion atomica revision+1 y evento TENANT_PROFILE_UPDATED
con identidad/antes/despues relevante; conflicto409 sin cambios ni audit de
exito. RUC duplicado409, formato400, noSAD403. No ampliar acceso de ADM/portal
al panel global. Editor de datos propio del tenant fuera de este primer paquete.

Login de tenant: JSON {ruc,email,password}. FormatoRUC y correo validados sin
modificar password; RUC se contrasta via SP contra tenant resuelto por servidor
antes de crear sesion. Correo/password validos en otro tenant NO autentican.
RUC incorrecto y credenciales incorrectas tienen respuesta generica de acceso;
rate limit y auditoria existentes, no devolver hash/roles de otro tenant.
ChequeoRUC/membership/estado y alta de sesion quedan en la misma frontera
transaccional, evitando carrera con cambio deRUC. La sesion se vincula al UUID
estable; no se cambia su tenant por editar o enviar otro RUC. Tras cambio deRUC,
el anterior no inicia nuevas sesiones; el nuevo funciona con la misma cuenta.

Entrada central: resolver RUC mediante SP preauth acotado y endpoint de
resolucion de espacio que devuelve SOLO destino canonico bajo baseDomain.
Contrato HTTP: POST /api/public/tenant-space, entrada cerrada {ruc}, salida
cerrada {hostname}, solo en hostplataforma y sin autenticar/tocar sesion previa
(D-87.BL). El salto a hostcanonico no establece sesion ni devuelve credenciales.
Identificar espacio ANTES de recoger/enviar contrasena; continuar al host del
tenant y alli completar RUC+correo+contrasena. No llevar password/token en
URL/localStorage, no autenticar el tenant como plataforma, no openredirect ni
relajar CORS/cookies/CSRF/HostFilter para simular acceso central. En presentacion
mock puede resolver/switch-context en navegador con mismo contrato visible.
Acceso administrativo SAD/SOP conserva una opcion explicita separada, sin
RUC ficticio de cliente ni privilegios tenant; no es la entrada de clientes.
Portal, invitaciones y recovery conservan sus propias reglas de identidad.

## Pantallas y comportamiento visual

Mantener disenio/colores/jerarquia de la captura. Campo RUC visible encima de
correo en acceso de clientes y junto al nombre del espacio en registro.
Etiqueta usuario: Correo electronico (usuario). RUCinput textual/inputMode
numeric, limite11, accesible por label, errores junto al formulario; no type
number. En entrada central mostrar paso de identificar espacio sin recoger
password antes; en tenant los3campos visibles y contexto claro.

Clientes SaaS: RUC visible en listado/detalle/busqueda/revision de alta y editor
Editar datos (nombre/RUC/zona horaria). Guardar -> recargar muestra persistencia;
cancelar no cambia nada; duplicado/formato/revision tienen mensajes claros sin
perder borrador. Permitir corregir RUC por SAD con audit, no reemplazar tenant.
Mock y runtime comparten nombres de campos y validacion, no presentar demo como
autenticacion real. No anadir terminos de SP/migraciones a la UI.

## Paquetes secuenciales y aceptacion

RUC-01.P1 SQL/API offline: migracion incremental y SP/ACL, DTO/store/services/
controllers/contexto y pruebas de dominio/transaccion/contrato; sin instalar o
activar runtime. Ver RUC-01-P1.md para ownership. Primero finalizar/conciliar
la Task Docker activa task_7a1bed038dbc, porque el programador es unico y sus
paquetes de instalacion tienen fuentes congeladas. Ese orden es de ownership,
no razon para perder el nuevo requisito. Si Docker falla, supervisor revisa
y puede liberar P1 offline conservando el fallo, sin forzar instalacion.

RUC-01.P2 frontend/mock: SOLO despues de P1 revisada/integrada. Ownership
AuthAccess/SessionProvider/runtime-clients/tipos/utilidades/mock y pruebas
relevantes; leer frontend/AGENTS y docsNext instaladas antes de codigo.
Verificar registro/RUC+correo+password/editar y errores desktop+movil con
capturas locales, sin publicar Vercel ni responder al comentario externo.

RUC-01.QA real: contrato propio posterior a V14 y migracionRUC revisadas,
backend compatible y entorno local sintetico. Demostrar en SQL real y API:
crear conRUC, leertrasconexionfresh, editarCAS/audit, persistencia trascommit,
duplicate/race/validacionnegativa, logincorrecto, RUCequivocado/hostequivocado/
otrotenant denegados, RUCviejo deja deentrar/nuevoentra y permisosSADintactos.
Luego QAvisual independiente. Unit/mock/build no sustituyen esta prueba.
Preservar datos previos, sin datos/destinatarios reales, gastos, Somee o deploy.

Pendiente de implementacion: este contrato fija decisiones, no afirma que
el campo, la migracion o el loginRUC ya esten disponibles.
