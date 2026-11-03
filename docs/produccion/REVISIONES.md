# Revisiones del supervisor

## HP-ORCH-01 — VALIDADA, auditoria de lectura

Dispatch ctx_06e3adc9a15a, worker_done msg_66a6758649a4 succeeded. Revision
independiente de arquitectura, contratos, scripts/reportes, capturas, Git e
identidades/procesos. Worktree limpio, cero cambios del trabajador. Retencion
user_requested antes de ack. No aprobacion de integracion real/produccion.

## ARQ-01 — VALIDADA

Matriz baseline en ESTADO.md, contrastada con componentes live/demo, DTO y
servicios/SP. Plan completo leido; referencias de arquitectura, API, verificacion
historica, identidad, SaaS/demo, diseño funcional, mapa y flujos consultadas.
Las pruebas historicas se distinguen de actuales. Corregida en la matriz la
referencia a sesion: el procedimiento real es sp_session_save. Riesgos de
arranque, Compose compartido, QA antigua y paridad TS/Java conservados.

## QA-01.A — EN_CURSO

task_8b7838194d4f / ctx_0bd0eb8dcc3f. Ownership: compose.qa.yaml,
scripts/health-qa.py y tests; configurabilidad acotada de suites de API/identidad.
Sin edicion de negocio ni docs del supervisor. La entrada de Orca quedo en draft
[Pasted Content 9266 chars]; se verifico por terminal read --screen y se envio
solo Enter, sin repetir Task/Dispatch ni relanzar proceso. Revision pendiente.

### Entrega inicial y defecto R1

Informe msg_393227f665f1 y worker_done msg_834766b9459c succeeded; siete archivos
en ownership, sin commits. Supervisor leyo todos los cambios y ejecuto18/18 tests
offline, config real OK, status exit1 QA_DAEMON_UNAVAILABLE y lock liberado.
No ejecuto APIs reales ni modifico el stack.

**DEVUELTA PARA CORRECCION**: tmp/qa/run.lock estaba separado por worktree, pero
nombre Compose/puertos/volumen son iguales. Repos enlazados podian competir.
R1 en task_4cd67d5ac714 / ctx_b4ecc5d368e4, solo runner/tests, exige lock comun
por Git common-dir y prueba de dos worktrees y repos independientes. Terminal
reutilizada antes de ack delivery_e249c61c5fd8. Ningun defecto se corrigio por el
supervisor dentro del ownership del programador.

### R1 revisada

Informe msg_f2e6955fadbf: solo runner/tests cambiaron. Supervisor leyo resolucion
de common-dir (raiz exacta, Git overrides saneados, HEAD/objects existentes),
lock propietario y tests de dos worktrees/repos separados. Ejecucion independiente:
23/23 OK en3.018s. Worker_done msg_619019aef4ee succeeded recibido; defecto cerrado.
QA-01.A **VALIDADA en alcance offline/configuracion**. Siete archivos comparados
por SHA256 e integrados como cambios locales en health/production-wave0, sin commit
ni secretos. Parent QA-01 no esta validada en runtime: daemon ausente. Terminal
reutilizada para INT-01.A antes de ack delivery_64873c253956.

## INT-01.A — EN_CURSO

task_652695c6018f / ctx_f90d4127fb47. Ownership de shell/sesion/api/preferencias,
politica de rutas, tests y QA con transporte interceptado. No editar QA anterior.
El worker-start dejo preambulo en composer [Pasted Content 9379 chars], comprobado
en pantalla; se envio solo Enter sin duplicar Dispatch. Revision y pruebas pendientes.

Revision preliminar msg_a254f09e73bd: catch de login podia borrar CSRF de una
sesion mas reciente por respuesta fuera de orden; acceso al getter localStorage
quedaba fuera del catch del helper de preferencias. Se devolvieron ambos puntos
al programador dentro del mismo Dispatch; verificar correccion y evidencia final.

msg_fc63e18865bc devolvio una regresion: se habia reemplazado ClientsView real por
aviso futuro; debe conservarse listado/detalle SAD y bloquearse SOP. Tambien se
detectaron signos ? literales en textos nuevos por perdida de acentos UTF8;
verificar correccion en fuentes y captura. No integrar ese snapshot.

Probe independiente tmp/review-api-race.cjs (fake fetch, cero red): login antiguo
pendiente → nueva sesion/CSRF → respuesta401 antigua → POST posterior. Resultado
newSessionCsrfPreserved=false, exit1. El helper api borraba CSRF sin distinguir
generacion; guardia del catch de login sola no bastaba. msg_c8a1564f9b60 solicita
corregir expiracion/clear de respuestas antiguas y regresiones401 vieja/actual.
Repetir este probe tras correccion; build previo no cierra el defecto.

### Entrega inicial NO APROBADA; R1 activa

Informe msg_85e2dac2ac12 y worker_done msg_1fe54d1fcd40 succeeded (41 tests,
live/demo85, live14/demo13) no resolvieron las correcciones posteriores: el
trabajador repetia delivery_3ef6447d0e98 sin ack y no avanzaba FIFO. Aviso de
atencion por terminal existente, sin reinicio, confirmo que ya habia asentado el
Dispatch. Ningun cambio INT se integro en supervisor.

R1 self-contained: task_89d4926715b6 / ctx_5772d4b60029, misma terminal reutilizada
antes de ack delivery_85c75e67cbca. Incluye los defectos pendientes y protocolo
de procesar/ack de cada Delivery del trabajador antes de leer siguiente lote.
Las instrucciones viejas quedan reemplazadas por este encargo; no reutilizar sus
IDs asentados. El preambulo quedo en composer8306chars; solo Enter observado,
worker-start termino ready/turnStart observed.

Estado R1 msg_9fe309a84ed5: el programador reprodujo cinco casos antes del fix
(login/protected401 viejos, token identico con generacion nueva, body401 tardio y
cancelacion); 46 tests/check pasan. Se restauro ClientsView y se añadieron casos
de listado/detalle y getters storage bloqueados; builds/navegador finales pendientes.
El probe independiente del supervisor ya paso con la correccion, sin editarlo.

### R1 final — VALIDADA en frontend/offline; integrada localmente

Informe msg_67808267e091, worker_done msg_8e84c9094a64 succeeded. Cambio R1 solo
en cinco archivos; el lote worker delivery_5d036df15c23 se proceso y reconocio,
con check posterior vacio. Supervisor comprobo ClientsView restaurado, UTF8,
guardas de storage, version de CSRF y abort, y ausencia de frase tecnica.

Ejecucion independiente sobre fuentes finales: npm test46/46, npm run check,
probe CSRF exit0 y node scripts/live-shell-qa.cjs16/16, errors/blocked vacios,
mysqlVerified=false. Se inspeccionaron por view_image detalle de clientes,
movil navy y storage bloqueado: panel derecho/fondo desenfocado, controles
legibles y sin overflow. El detalle conservado de baseline aun usa etiquetas
tecnicas; SAAS-01.A lo sustituira por rotulos de negocio y consulta de configuracion.

Los14 archivos INT completos se compararon por SHA256 e integraron como cambios
locales en health/production-wave0. Sin commit, dependencias o codigo QA alterados.
Terminal reutilizada para SAAS-01.A antes de ack delivery_ce6474247464. La
aprobacion cubre shell y contrato frontend probado con transporte interceptado;
no MySQL, SMTP, persistencia real ni produccion.

## SAAS-01.A — EN_CURSO

task_c8012881a8b2 / ctx_883d9a5e2c94. Tras aceptar INT, mismo programador y
worktree. Ownership: nuevo componente clientes, DTO/helpers, CSS, tests y QA
interceptada; conexion acotada del shell y fixtures live-shell. Contratos y
aceptacion en Task/D-05. Sin editar API/sesion/QA backend ni activar pagos.

## ARQ-02 — VALIDADA para contratos del primer corte

DTO/servicios de plataforma/organizacion/identidad/agenda/documentos contrastados.
Contratos en DECISIONES D-04/05; programador acuso lectura y acuerdo en
msg_393227f665f1. Cambios de planes/suscripciones sin expectedRevision se conservan
como brecha, excluidos del primer corte. Sin aprovacion de integracion real.
