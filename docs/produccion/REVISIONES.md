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

## SAAS-01.A+R1 - ACEPTADA para UI/contrato frontend

Informe inicial msg_3df67242d824, worker_done msg_be0077533632; task_c8012881a8b2 / ctx_883d9a5e2c94. La primera lectura por salida PowerShell sugirio mojibake. El programador pregunto y el supervisor respondio por Orca (question msg_0eeca985a307, reply msg_1ae78039732a): la decodificacion de la salida era incorrecta; conservar los bytes UTF-8. La verificacion estricta posterior confirmo cero marcadores U+00C3/U+00C2/U+00E2+U+20AC/U+FFFD, sin cambios de fuente. R1 task_3b502d417304 / ctx_50459c870b25, worker_done msg_14ab0f547f65, confirmo hashes iguales para los ocho archivos y estado Git sin delta R1.

Revision independiente: Requests.Tenant, UserInput, PlatformService y V2__saas_procedures confirman payload propietario-nuevo, enums, cuotas, oferta/perfiles y limites de clave (12 caracteres, 72 bytes UTF-8). Alta exige revision/confirmacion, bloquea doble envio, no reintenta POST ambiguo y usa lookup sin inferir inexistencia de una lista limitada. Detalle consulta tenant y configuration. No se editan contratos existentes, ni se cobran pagos; los perfiles requieren validacion clinica.

Supervisor repitio npm test (55/55), npm run check y saas-live-qa (9 grupos; 7 HTTP + 1 red esperados; errores inesperados 0). view_image: revision sin password, detalle API y revision movil con acentos legibles. Reporte declara red interceptada, mysqlVerified=false, persistenceOrRollbackVerified=false y un navegador Chromium/Playwright. Ocho archivos SHA256 comparados e integrados localmente en health/production-wave0. SAAS-01.A aceptada para UI/contrato; SAAS-01 parent sigue pendiente de MySQL, persistencia, rollback, duplicados y cupos reales. Worker retained por solicitud del usuario. Sin commit, push ni publicacion.

### ORG-01.A - ACEPTADA para lectura/alta de sedes frontend

Informe msg_5be7c5f63145, worker_done msg_eb44f21bc1ff; task_8d397ccb04b9 / ctx_071961765824. Reutiliza /app/configuracion/organizacion existente, conserva routes.json/generador y 81 rutas. Componente limitado a ADM tenant y host/sesion coincidentes. Lee /tenant/configuration, calcula cuotas con predicados SQL y presenta sedes; crea sede propia mediante Requests.Branch exacto y autoridad atomica del SP. No edita equipo/suscripcion, ni envia correo. 409 conserva borrador/recarga; red/5xx/2xx malformado no repite POST sin consulta y reconocimiento explicito.

Una alerta inicial del supervisor cuestiono tenantId en el JSON; se resolvio cotejando SELECT t.id,...,s.* con subscriptions.tenant_id y Sql.camel: la respuesta incluye tanto id como tenantId. No era defecto y no se recodifico fuente. Supervisor ejecuto 62/62, check, organization QA9, shell16 y demo13. Los builds live/demo de 85 paginas se repitieron en supervisor; /app/configuracion/organizacion existe en out y out-demo. La primera repeticion de QA del supervisor no encontro preview porque todavia no se habia generado out; tras los builds la suite completa paso. Inspeccion visual independiente de configuracion, confirmacion GET, movil navy y revision movil: textos legibles, estados claros, 390px sin overflow de documento. Reporte usa fixtures/red interceptada; mysql/persistencia/rollback/concurrencia no comprobados. Siete archivos integrados por hash; 25 archivos previos QA/INT/SAAS comparados sin variacion. Worker retained; tarea aceptada a nivel frontend, ORG-01 parent parcial. Sin commit/push/publicacion.

### ORG-01.B - ACEPTADA para equipo tenant en lectura frontend

Informe msg_6a4f34c8f065 y worker_done msg_4850ce6bf1da; task_c2c5c52550b6 / ctx_c27357954da9. La entrega quedo en cinco archivos autorizados. El parser valida el contrato de OrganizationService.configuration (miembros, catalogo de especialidades y asignaciones), rechaza campos/tipos/roles/estados invalidos y referencias duplicadas; la proyeccion de pantalla muestra nombre, roles, estado, propietario y nombres asignados, sin correo, credencial o IDs. No agrega escrituras de equipo/invitacion/correo. El contrato Java confirma campos de identidad/contacto en respuesta; la UI los descarta.

Revision visual con view_image de organization-intercepted-team-desktop.png, organization-intercepted-team-unavailable-references.png y variantes mobile-light/dark/navy: tabla legible en desktop, tarjetas sin overflow en 390px, etiquetas seguras para referencias ausentes y tres temas coherentes. Fixtures enteramente sinteticos. Supervisor comparo hashes contra los cinco archivos del worktree y verifico cero divergencias en archivos previos solapados; integro solo esos cinco archivos.

Ejecucion independiente, despues de integrar: npm test 68/68; npm run check exit0; build live y build:demo exit0, 85 rutas cada uno; organization-live-qa 12, posts8, HTTP esperados8, red esperada1, errores JS0 y mysqlVerified=false; live-shell-qa 16 sin errores; demo-qa 13, apiRequests0, errores0. git diff --check sin errores. La aprobacion es UI/contrato frontend con red interceptada, no runtime real. MySQL, persistencia, rollback, concurrencia y envio de invitaciones no verificados; ORG-01 parent conserva bloqueo runtime. Worker retenido por solicitud, sin commit/push/main/publicacion.


## SQL-01.A1 - ACEPTADA esquema y semilla en SQL Server real

Task task_d86c4f01f587; primer Dispatch ctx_3e53d11c30f7 failed con semilla parcial; reintento ctx_2c5b075abc04 succeeded, worker_done msg_2559fbe158e4. Tras revisar matriz completa y fuente, supervisor verifico hashes V1 ed1dcb3e6bd4f2ac1f9b11de9aa7d1053db0e71ca3610e21801cc60d51fe4a0a / V2 f672c8856ab6a150ae1967e85b8baf9df07f2615f4db8445263f11f322a1a885 e integro solo2 archivos nuevos.

Se aplicaron V1/V2 con sqlcmd -E -C -b -f65001 en health_project_sqlserver_qa_20261103, envueltos en transaccion: exit0 y37 tablas reales. Prueba independiente: multiples encounters FINALIZED y admissions DISCHARGED permitidos con uno vigente; rechazo de9 casos (slug/roles/JSON/domain, paciente/sede ajenos, segundo encuentro activo, recurso ocupado y paciente ya admitido); rollback comprobado sin fixture residual. SELECT administrativo del catalogo comparado por Python contra hexUTF8 de migracion fuente:241 nombres/domains/dental/perfilesJSON completos iguales. Archivo de prueba tmp/sqlserver-schema-review.sql y logs tmp/sqlserver-apply-a1.log, tmp/sqlserver-schema-review.log. Esta aceptacion solo cubre esquema/semilla, no SP ni runtimeJava. Worker retained antes de ack delivery_d0ed732c1637; siguiente paquete A2 identidad/infraestructura delegado.


## SQL-01.A2 - ACEPTADA familia SP identidad/infraestructura en motor

Task task_8d67b6111fbd / ctx_382d876e53f5, worker_done msg_153bd9a5602a; V3 SHA256 b4ebe83471354e2027315d95e1657afde72ad2c19c508e2ef764c2356f940ce0. Se revisaron54 contratos y contexto, bootstrap separado, operaciones/lecturas de identidad, sesiones, tenancy, mail outbox, salud, monitor, auditoria y soporte. Revisiones durante implementacion: NULL metadata, collation BIN2, Flyway ausente, bootstrap principal real y ambiguedadSMTP, incorporadas por trabajador.

Supervisor aplico snapshot final por sqlcmd transaccional: exit0 y54 SP. Pruebas independientes tmp/review-sqlserver-a2.py:16/16 PASS; salud sin tablas, sesion actual, resolve de host ajeno vacio, auditoria tenant, outbox ambiguo sin replay/SENTredactado, rol falsificado rechazado, sesion revocada, TX externa obligatoria, claim obsoleto, NULLmetadata, scope invalido, auxiliar privado sin permiso, SELECT/UPDATE directos denegados, bootstrap denegado aun con scope y grant de prueba. Cleanup exit0 sin fixtures/principal de prueba residuales. Conexion administrativa Windows; parte de permisos bajo EXECUTE AS USER WITHOUT LOGIN especifico, no autentica cuenta runtime desplegada. No prueba HTTP/JDBC ni concurrencia de dos procesos SMTP.

Solo V3 se integro por SHA, sin commit. V1/V2 y34 hashes previos conservados. Parent SQL-01 permanece EN_CURSO: aun faltan familias SaaS/organizacion/clinica/operaciones, Java y configuracion. Worker retained antes de ack delivery_86c6eee89627.


## SQL-01.A3 - ACEPTADA familia SP SaaS/organizacion en motor

Task task_a1762a54ecca / ctx_1184a57710c9; worker_done msg_83f0226f60e1. V4 final27SP SHA9640cd1215f27eb6789e7b79c11291aa37bc89f61b2112f678d364c2112654dc aplicado transaccionalmente exit0 (81 SP totales); solo ese archivo integrado. Defecto detectado por preflight real: external sin delimitacion, Msg156; programador corrigio SQLidentificadores sin alterar clavesJSON; snapshot corregido y final compilan. Tambien se ajusto dominio opcional de propietario noDOCTOR segun contrato.

Pruebas independientes tmp/review-sqlserver-a3.py + config-probe.ps1:14/14 PASS y cleanup0. Cobertura: sede/limite de cupo/ultima sede, camposDTO extra, tenantajeno/SOP/anonimo/ADM sin privilegio plataforma, registropublico con cuotas derivadas y unicoPROowner, propietarioCLINIC con identidadclinica opcional sinPROautomatico, reutilizacion de membership rechazada, slugduplicado, versiones de planes con contrato anterior inmutable,8resultsets/roottenant/tiposBIT eINT/asignaciones/perfilJSON exactoSHA contrahexoriginal. Dos probes iniciales ajustados por evidencia: ultima sede es HP_INVALID400 en fuente original (no409); H_FAMILY mide3095 caracteres y se compara por SHAexacto, no por presuncion >4000. No fueron defectos de producto. Todas las operaciones de casos se revierten y fixtures se limpian.

No Java/datasource/HTTP migrados aun, ni validacion de todas las carreras concurrentes o login runtime desplegado. APIs SaaS sin expectedRevision conservan brecha conocida. Parent SQL-01 sigue en curso con familias clinicas/operaciones y conversion Java/configuracion pendientes. Retain antes de ack final delivery_7b4cb6acdf05.


## SQL-01.A4 + correccion en A5 - ACEPTADA familia clinica en motor

Task task_f11829784540 / ctx_8e043211cc7d, worker_done msg_0f9fb2a25e72, entrega26SP SHAoriginal3ee201991c7dd5bc38b592f8396188ffbb67ad798537b558123bf3411458a46e aplicada:107SPtotales. Se retorno defecto real: whitelist LIKE de requestkey rechazaba guion valido de Java/HTTP (probe key_bad1). Extensionprecisa autorizada por msg_93edafd175d2 al DispatchA5 ctx_9881ceca91d1: solo3patrones V5requestKey/specialty_code. Worker msg_9d1d848c2f67 corrigio; supervisor verifico igualdad exacta con esas3sustituciones, hashfinal d2352d8fe6a6f8f84c62179f7a643027866a17229064b9b0ce3d96f60fcd9ece. ReaplicacionQA mediante snapshotCREATE OR ALTER enTX exit0; futura migracionfresca verificaraCREATEoriginal.

Pruebas tmp/review-sqlserver-a4.py:16/16 PASS incluyendo idempotency mismo/diferentepayload, duraciontranscurrida nofronteras, revisionobsoleta, pacienteajeno/plataformasinautoridad, unencuentroactivo, autor, entradafinalizada, firmadoinmutable, originalmismopaciente, adendapreserva, SHAUTF8de6000caracteresconacentos/emojis y publicacion/retirada/revocacion, y carreraREALde2conexiones en2tenantsconmismoPRO:un ganador/otroconflicto. FixturesUUIDsinteticos y cleanup0. Primer cleanup fallo por QUOTED_IDENTIFIER delharness, recuperado con opcionescorrectas y0usuariosfixture; no fue defectoSP.

A4aceptada solo para SP/motor;26contratos/limites/snapshots se conservan sin certificar perfilesclinicos y sinHTTP/JDBC. V5seintegro solo trascorreccion/probes; V1-V4intactos. Java yotrasfamilias siguenpendientes. Retainantesdeackfinal; A5independienteV6 se ejecuta simultaneo a revision sin compartirDBconworker.

## SQL-01.A5 - ACEPTADA familia de operaciones en motor

Revision independiente del 2026-11-03. Task task_2ebe7d0da31b / Dispatch
ctx_9881ceca91d1; informe msg_da682ebaaa05 y worker_done msg_743d4873e4f9
recibidos y procesados por el coordinador al retomar el Run. El trabajador
entrego 26 SP (20 publicos y 6 auxiliares) de finanzas, inventario, hospital y
procesos. Se cotejaron DTO y servicios Java vigentes, guards V3/V4, limites de
rol/tenant/sede, resultsets, transacciones y las transiciones persistidas.

V6 SHA256 5b007234afce7a435fe9220111249e537a22b467ed922cfdb45c3bec69949458
aplicado en transaccion exclusivamente a la base marcada
health_project_sqlserver_qa_20261103: 133 SP totales. Harness del supervisor
tmp/review-sqlserver-a5.py: 29/29 PASS, cleanupExit 0 y consulta posterior sin
usuarios fixture. Incluye caja CAJ sin PRO, clave repetida y payload distinto,
sobrepago/devolucion, aislamiento de paciente y roles, cantidades exactas 0.001,
precision/overflow, dispensacion vinculada al paciente/medicamento/unidad y
cantidad prescrita, transferencia recibida una sola vez, ocupacion/egreso con
revision, historial de procesos con Unicode largo y transiciones invalidas.
Tres carreras reales de dos conexiones (devolucion, cama y dispensacion del
ultimo 0.001 prescrito) produjeron un ganador y un conflicto 51003.

La primera ejecucion del nuevo harness entrecomillaba claves como JSON y omitia
el flag create de branch_save: se corrigio el harness, sin cambiar V6, y se
repitio. No se presentaron esos fallos de preparacion como defectos del producto.
V1-V5 comparados por SHA y sin divergencias; solo V6 se copio del snapshot
revisado al checkout supervisor, fuera de main. Sin commit ni push.

A5 aceptada para estos SP en motor. No acredita despliegue runtime con cuenta
restringida, HTTP/JDBC, triggers completos ni todo protocolo hospitalario/clinico.
Se registro worker-keep-open por solicitud vigente del usuario. Proximo paquete:
A6, auditoria de cambios multirregistro e inmutabilidad; ownership solo V7 nuevo.

## SQL-01.A6 - primera entrega DEVUELTA: hash UTF8 incorrecto sobre columnas

Entrega task_f3b982860225 / ctx_4d330d95d46d, worker_done msg_a30f37b48fe3.
Informe final msg_810c58fd188f y matrices msg_6d74cee6a663/msg_74b6fc07e0ad
procesados completos. SHA56a0a6ad1c9ec2d6172085394d532c17d22d5cc45ecf4929d4fbaae9933d41a0
coincide con el preflight. Estado completed de Orca es entrega, no aprobacion.

Supervisor ejecuto tmp/review-sqlserver-a6.py: 20/21 PASS en SQL2022 real.
Pasan I/U/D multirregistro, MERGE mixto, no-op, diferencias caso/acento/espacios,
NULL/vacio/texto null, PK compuestas, cambio PK/tenant como DELETE+INSERT,
tenant por ticket, contexto, inmutabilidad y llamada SP bajo usuario restringido
sin grants de tablas; SELECT/INSERT directo y helper privado denegados. Un
escenario sintetico dispara los 29 triggers de negocio; no equivale a I/U/D
exhaustivos por cada tabla/columna. Todas las instalaciones/fixtures/principal
de prueba revierten: 0 triggers, 0 usuarios fixture y 133 SP despues.

Defecto bloqueante: la expresion CONVERT(varchar(max),columna COLLATE UTF8)
en esta instancia pierde la codificacion exigida al operar sobre columnas con
collation no UTF8. Para contact JSON sintetico largo (24028 bytes UTF16), Python
SHA256 UTF8 esperado 9cd5937d4dd981f187d3e6ddeb66693cbe982d11c2cb8fea7435ae735b2fb6a1;
trigger observado 5c13f699d069fb2282366a52c38263d70df4c96a075b4819bc00715b7631aba5.
Reproduccion minima usa columna nvarchar(max) BIN2 con U+00C1/U+4E2D/U+1F9B7:
UTF16 almacenado C1002D4E3ED8B7DD; conversion actual C13F3F3F en vez de
UTF8 C381E4B8ADF09FA6B7. Probar solo literales/variables no reproducia el problema.
Agregar COLLATE solamente a la salida tampoco recupero todos los caracteres:
no aceptar ese arreglo sin regresion de CJK/emojis y largos.

Evidencia: tmp/sqlserver-a6-tests.json/.log y
tmp/sqlserver-a6-utf8-reproduction.sql/.json. Se devolvera correccion acotada
a V7: pipeline de hashes debe preservar UTF8 completo de columnas reales;
no cambiar collation de DB, cuenta ni semantica del contrato. V7 no integrada.
Errores iniciales de harness (UPDATE sin cambio en una de las membresias,
collation del EXCEPT de cobertura, manejo de REVERT tras error de permisos e
invoice fixture omitida) se corrigieron antes del resultado 20/21. No se
contabilizaron como defectos de V7 ni se flexibilizo el hash esperado.

## SQL-01.A6.R1 - ACEPTADA tras regresion independiente

Entrega final msg_e7929313fcb5 y worker_done msg_29df9770e5be,
task_3c91c4fb9c77 / ctx_840acbdaeb78. SHA256 corregido
c5657fa2329ab306d93ddda99efce52f95285575c8437295666b35670dbadf1f
coincide entre worker, snapshot probado y V7 integrado. Revisado delta de
materializacion UTF8 local: 14 tablas variables, 40 hashes, sin helper
persistente/grants/cambio de contrato. V1-V6 identicos por SHA entre worktrees.

Supervisor: matriz completa corregida 21/21 PASS y regresion adicional 4/4
PASS sobre pacientes multirregistro (seis hashes antes/despues), documentos
largos, comentarios largos movidos entre tenants y credenciales sinteticas
CJK/emoji. Referencia Python UTF8 independiente; no solo literales SQL.
Los primeros fallos del harness adicional se debian a LF convertido a CRLF por
textmode Windows y a filtro de privacidad que coincidia con el nombre permitido;
se corrigieron fixtures/asercion, sin modificar V7 ni relajar hashes esperados.
El defecto original queda corregido. Conservar evidencia original 20/21.

Todas las pruebas fueron rollback-only; baseline 0 triggers/133 SP/0 usuarios
antes de integrar. Despues se copio V7 byte a byte y se aplico exclusivamente
en la base QA marcada en una transaccion: exit0, 31 triggers/133 SP/0 usuarios.
Evidencia tmp/sqlserver-a6-r1-tests.json/.log,
tmp/sqlserver-a6-r1-unicode-tests.json/.log y
tmp/sqlserver-a6-r1-acceptance.json, tmp/sqlserver-a6-r1-install.sql/.log.
No se acredita login runtime, JDBC/HTTP, cobertura I/U/D exhaustiva en cada
columna o validacion visual nueva. No cambios frontend, commit, push ni main.

## SQL-01.A7 - matrices recibidas, revision estatica provisional

Procesados cuatro mensajes msg_2727b6c656aa/msg_5b03e1a90ed6/
msg_f1d34c6ac7da/msg_b4cfba3f76e3: cubren133 SP de V3-V6 con motivo/fuente.
Runtime aqui es capacidad del adaptador servidor, no permiso HTTP anonimo.
Supervisor contrasta archivos:107 runtime,2bootstrap,24helpers privados;110GRANT
y452DENY objeto, incluidas4denegaciones sobre cada una de37tablas por rol.
usp_request_context compartida produce107grants runtime y3bootstrap.
Ambos ALTER bootstrap revierten exactamente al cuerpo V3 al retirar unica
condicion nueva de D-15.A. V1-V7 identicas entre worktrees.

Evidencia tmp/review-sqlserver-a7-provisional.py y
tmp/sqlserver-a7-provisional-review.json. SHA provisional V8
e9bdd250eff88a9d7075cc63fdfd642882cba1060bd05b6c856d8fd9c8d1eb4e.
Errores iniciales del checker fueron encoding utf8-sig mal escrito y regex que
no expandia las cuatro DENY agrupadas por tabla; corregidos en harness sin
cambios de producto. Esta revision es solo estatica y provisional: no se
instalo V8 ni se ejecuto DB desde supervisor mientras worker conserva ownership
de QA. Falta informe final/worker_done y evidencia de todas las fases D-15.B.
No nueva evidencia visual: alcance exclusivo SQL/permisos.

## SQL-01.A7 - DEVUELTA por compatibilidad de historial

Informe final msg_4590913ed19e y done msg_6a6e6b19278c procesados. Dos archivos
exactos congelados en tmp/sqlserver-a7-final-snapshot. SHA V8 e9bdd250...d1eb4e
y verificador520b466061a6b351c6a3b36554f3a72c4dc0a370078c21ab206f11524b1e3b2a
coinciden. Supervisor reviso permisos y ambos cuerpos ALTER (delta D-15.A
exacto), ejecuto7/7fases sobre SQL2022: normal exit0,6negativos exit1 esperados
con unica3998 tras aserciones262/15517/51001. Catalogo/effective562 y308errores229
PASS. Baseline4E96A8D4...99874 identico en todas las conexiones pre/post; sin
roles/usuarios/fixtures residuales. No es login/JDBC/HTTP real.

Defecto R-A7-HISTORY bloquea integracion: V8 exige exactamente37tablasdbo,
pero V3 usp_monitor_migrations contempla dbo.flyway_schema_history. Supervisor
creo representante sintetico dentroTX y ejecuto V8:51000 Expected exactly37
approved dbo tables. Rollback confirmado por fingerprint independiente.
No es ejecucion del migrador real: prueba precisa de incompatibilidad con su
tabla de infraestructura prevista en contrato existente. V8 no integrada ni
aplicada permanentemente; se devuelve correccion limitada a los mismos2archivos.

Evidencia tmp/sqlserver-a7-final-review.json/.log,
tmp/sqlserver-a7-history-reproduction.sql/.json; comandos/harness en tmp.
D-15.C admite exclusivamente historial opcional, manteniendo denegaciones
y rechazo de tablas desconocidas. Exigir regresiones con570ACL si existe
historial,8DMLdenegados,lecturaSP autorizada y caso de tabla desconocida.

## SQL-01.A7.R1 - ACEPTADA tras10fases independientes

Informe msg_240473aedb25 y done msg_3a6e0b2a0d1f procesados completos.
SHA V8 63ca532ad7f16650dfd27891a7093ea4b0cee3c264ca35537d81a9100c067f4e;
verificador76c9d3caff0ad2751f20d92759df0841844673c43c9dd172dbcf053ea6d2217a.
Supervisor revisa diff exacto contra entrega rechazada: conjunto cerrado37+
historial opcional,8DENYCRUD condicionales y unico GRANTmetadata D-15.D.
Solo2ALTERbootstrap D-15.A, V1-V7 byte a byte identicas entre worktrees.

python -B tmp/review-sqlserver-a7-final.py --r1: exit0,10/10fases PASS desde
snapshot congelado por SHA. Normal562ACL/308negativos229; historia571ACL/
317negativos229 (incl8CRUDhistorial+bootstrapmonitor), filas sinteticas leidas
por SAD y SOP autenticados viaSP. Metadata limitada al objeto/runtime.
Tabla desconocida rechazada51000 antes de roles/permisos/SP; monitor sinactor
51001 aun con metadata visible. Siete fases doomed tienen rawexit1/3998
ESPERADOS tras aserciones de error/estado; no se presentaron como rawexit0.
20checks en conexiones nuevas conservan baseline4E96A8D4...99874 identico.

Dos archivos copiados byte a byte al checkout supervisor tras pasar revision.
V8 NO se instala permanentemente: conservar baseline y harness reproducible
hasta el paquete de migracion real; los roles runtime no estan desplegados.
Motor real SQL2022 + EXECUTE AS WITHOUT LOGIN + historial representativo,
no Flyway/JDBC/login/HTTP real. Ambos defectos R-A7-HISTORY/metadata quedan
corregidos para este contrato; migracion completa SQL-01 sigue EN_CURSO.
Evidencia tmp/sqlserver-a7-r1-review.json/.log, snapshot y acceptance.json.
No nuevas capturas: solo SQL, frontend intacto; evidencia visual previa sigue
interceptada. Siguiente paquete A8 prepara adaptador aislado, sin activacion.

## SQL-01.A8 - avance y lectura preliminar, aun sin entrega final

msg_ef70d90309d4 comunica49testsPASS(39nuevos con doblesJDBC+10previos) y
dependencytreegestionado. Supervisor lee Context/Procedure/Executor/Errors,
pom y escenarios de tests:12SPcerradas,10paramcontexto,validacion local,
recorridoRS/updatecounts,limpieza e invalidacion,errores seguros. Cambios pom
observados solo2dependenciasSQLServer; clases sinregistrobeans ni llamadas
desde servicios por este encargo. Esta lectura no cierra revision de recursos
y pool real: los tests comunicados usan mocks, no conexionSQLServer.

Programador aun prepara hashes y preservacion finales. No ejecutar build del
supervisor ni integrar borrador antes de informe final/snapshot verificable.
No nueva evidencia visual, DB o HTTP en este avance. A8 permanece EN_CURSO.

## SQL-01.A8 - ACEPTADA: adaptador aislado,49/49 tests independientes

Entrega final msg_6986dedd6c0e, hashes msg_cd5b9f34dfdc y done
msg_3892ecfd5247, task_8e112036e806/ctx_8c9925bf4026. Siete hashes exactos
congelados en tmp/sqlserver-a8-review-manifest.json y snapshotbackend.
Supervisor revisa4clases,2suites y pom:12SPcerradas,10campos contexto porSP,
proposito separado runtime/bootstrap,binds tipados/UTCproleptico,RS multiples
ycontadores,reseteo finally,invalidation y mapeo errores seguros. No beans ni
consumidores nuevos. Pom solo agrega2dependenciasSQLServer gestionadas porBOM.

Desde snapshot con fuentes base del supervisor y siete deltas exactos:
.\mvnw.cmd -B -ntp verify exit0,49tests/0fail/0errors/0skipped,jar/repackagePASS.
Executor22+Errors17 nuevas (MOCKS),existentes10. dependency:tree dirigido exit0:
mssql-jdbc13.4.0.jre11,Flyway12.4.0,HikariCP7.0.2,Boot4.1.1,MySQL9.7.0.
No repetir suites sin cambios/fallos. Snapshot difiere de algunos archivos
base del worktree solo en LF/CRLF preexistentes; se comprobaron equivalencia
y hashes exactos del checkout supervisor, sin normalizar sus archivos. Primer
checker rechazaba esa diferencia de EOL: corregido solo harness, no producto.

Integrados7archivos por bytes/SHA tras pasar review.86fuentesbase conservadas
byte a byte; pom es unico archivo existente modificado conforme ownership.
Manifest verifica87archivosbase antes de integrar y7entregables; acceptance.json
recoge5reportsSurefire y versiones. Sin DB/app/migrador/HTTP/contactoJDBC real,
ni poolHikari real,Frontend o capturas nuevas. No activar backend parcial.
A8 aceptada solo para adaptador aislado; SQL-01 sigueEN_CURSO. A9 completa
catalogo108operaciones (106runtime+2bootstrap), dejando contexto interno.

## SQL-01.A9 - matrices y lectura provisional

Procesados4mensajes de matrices: msg_9ec1b49b5117/msg_0fd93764c77d/
msg_97d0d4e1097f/msg_ea14976d039e,46+21+21+20=108contratos.
Lectura supervisor de suiteContrato: deriva nombres/propositos de matrizV8 y
firmasV3-V6,tokeniza comentarios/literales/defaults/tipos completos;compara
nombres deparametros/orden/longitud/tipo/defaults y ejecuta casos de parser
malformado. Solo prueba recursosSQLoffline,no interpreta cuerpos ni motor.

Inspeccion provisional fuenteJava:108entradas exactas,106runtime+2bootstrap,
contextointerno y helpersfuera; nombres12originales preservados. DeltaExecutor
contraA8 solo2bindings tipados setInt/setLong; Context/Errors/pom/V1-V8 siguen
byteidenticos. Evidencia tmp/sqlserver-a9-provisional-review.json; SHA provisional
catalogo7ee51887aea2479185222a2cdf130b3b4a2918181770dae45a254a6edf390d48.
No es snapshotfinal ni aceptacion; faltan reporte de build/tests/hashes/done y
verificacionindependiente. No se integro ni ejecuto DB/HTTP/UI en esteavance.

## SQL-01.A9 - ACEPTADA tras 169 pruebas independientes

Informe msg_9c03ea854782 y done msg_070f9bc35f5e procesados. Cuatro hashes
verificados, fuentes congeladas en tmp/sqlserver-a9-review/backend; manifiesto
y resultados en tmp/sqlserver-a9-review-manifest.json y acceptance.json.
Supervisor revisa el catalogo y el parser de contratos: 108 entradas exactas
(106 runtime, 2 bootstrap), contexto interno y 24 helpers excluidos. Parametros
con nombre, orden, tipo, longitud/MAX/precision y defaults contrastados con
V3-V6 y matriz V8 desde recursos independientes. Executor difiere de A8 solo
en dos bindings setInt/setLong; el resto del adaptador permanece identico.

Desde snapshot: .\mvnw.cmd -B -ntp verify exit 0; 169 tests, 0 fallos, errores
u omisiones, jar y repackage PASS. Contrato 113, Executor 29, Errors 17 y
10 pruebas previas. No son pruebas de SQL Server conectado: recursos SQL
estaticos y dobles JDBC, sin validar cuerpos TSQL o persistencia/HTTP reales.

Cuatro archivos integrados byte a byte despues de revision. Se comprobaron
93 archivos base antes de integrar; 90 fuera de ownership siguen intactos,
3 cambios existentes autorizados y 1 archivo nuevo. Se conservaron LF/CRLF
preexistentes de cada checkout, sin normalizar fuentes ajenas. Context, Errors,
pom y V1-V8 preservados. Sin activacion ni nueva evidencia visual. A10 convierte
el primer corte host/sesion con seleccion explicita por constructor y sin
cambiar SecurityConfiguration, que seguira usando el camino actual hasta
el cierre de la conversion. La retirada del camino legado queda pendiente.

## SQL-01.A10 - avance y lectura preliminar

msg_d98f86eb990a informa 216 pruebas preliminares y una regresion adicional
para conservar actor ya autenticado cuando downstream devuelve error, mientras
fallos de touch eliminan candidato sin autenticar. Supervisor leyo HostFilter,
SessionFilter y SqlServerSecurityStore: seleccion explicita por constructor,
cinco descriptores, contexto desde atributos internos, scopes acordados, RS
validados dentro de TransactionOperations y ninguna TX sobre FilterChain.

La lectura observa CSRF/estado antes de touch, autenticacion tras touch y
tratamiento D-18.A de errores. Conservacion de atribucion downstream requiere
revisar la regresion final. No es aun snapshot aceptado; faltan informe, hashes,
worker_done y ejecucion independiente. Los 216 PASS son comunicados por worker,
con HTTP/TX simulados; no prueban datasource comun, JDBC, pool o motor reales.
No integracion, app, DB ni nueva evidencia visual en este avance.

## SQL-01.A10 - ACEPTADA tras 218 pruebas independientes

Informe msg_def53e7f44cb, precision de preservacion msg_573947eb3b58 y done
msg_40b15b6a1727 procesados completos. Se distingue lo comunicado por worker:
49 hashes de trabajo local previo preservados; archivos antes limpios como
SecurityConfiguration/IdentityService seguian sin diff, no eran parte de esas49.
Supervisor compara toda su base backend fuera del ownership con el worktree
(equivalencia LF/CRLF preexistente) y protege sus hashes antes de integrar.

Cinco SHA exactos congelados en tmp/sqlserver-a10-review-manifest.json.
Revision de filtros/store y suites: camino por constructor, cinco SP, scopes
IDENTITY/REQUEST, validacion de contexto/RS dentro del callback transaccional,
ninguna TX sobre downstream, sin fallback. Se conservan 401/403/500 de D-18.A,
CSRF, estado503 e identidad de servidor; actor autenticado sigue atribuible
cuando downstream devuelve error, candidato no se autentica ante fallo de touch.

En snapshot independiente .\mvnw.cmd -B -ntp verify: exit0, BUILD SUCCESS
17.664s,218tests/0failures/0errors/0skipped,jar y repackage PASS. Filters37,
SecurityStore12 y169 anteriores. Simulacion HTTP, executor y manager dobles con
TransactionTemplate real: no prueba DB, datasource comun ni pool/HTTP reales.

Integrados cinco archivos byte a byte: dos filtros existentes y tres nuevos.
94 archivos base verificados antes de integrar,92 fuera de ownership intactos.
SecurityConfiguration sigue usando constructores legados; camino SQL no activo.
Sin DB/app/Flyway/navegador ni nuevas capturas. ReportesSurefire del snapshot y
tmp/sqlserver-a10-acceptance.json. Aceptacion limitada al camino implementado
y probado con dobles, no a SQL-01 completo. Siguiente A11: IdentityService.

## SQL-01.A11 - borrador revisado, bloqueo de cuota sin entrega final

Escalation msg_stop_17ebeb1751d822e44021b9c2 stopReason=errored comunica limite
de uso del programador, no worker_done. Guia Orca de recovery consultada: no
reset, nuevo agente o suposicion de salida. worker-show prueba terminal/sesion
live retenida y Dispatch ready/input_accepted, aun abierto. CLI indica reintento
a las03:35; sin cambio de cuenta ni intento automatico mientras limite vigente.

Worker-read muestra primera verify fallida y correccion de fixture Mockito
(doReturn para evitar stubbing anidado); segundo Maven en background ya termino:
reports249/0fallos y jar reciente, sin java Maven activo del worktree.
Supervisor congelo seis archivos como BORRADOR, SHA observados propios en
tmp/sqlserver-a11-draft-review-manifest.json, no hashes finales declarados.

Lectura de IdentityService/IdentityStore/tests: nueve SP, REQUIRED/REQUIRES_NEW/
MANDATORY, creacion explicita, sincronizacion afterCommit y validacion de request
segun D-19/A. Snapshot independiente .\mvnw.cmd -B -ntp verify exit0,249tests
sin failures/errors/skips y empaquetado PASS18.808s;31 nuevas (20 servicio,11
store) y218previas. Conservar resultado como revision provisional, pues el
programador no ha cerrado revision/preservacion ni entregado informe final.
No se modificaron archivos de implementacion del trabajador desde supervisor.

No aprobada/integrada A11. Los97archivosbase backend del supervisor mantienen
hashes; cuenta/sesion/worktree del programador intactos. Reanudar mismo Dispatch
cuando cuota permita, exigir informe y volver a contrastar hashes; si no cambia
contenido probado, reutilizar evidencia sin repetir suites. Sin DB ni HTTP real.

### A11: sesion recuperada, revision final reanudada

Usuario solicito continuar. Se cargo guia Orca vigente y recovery; runtime
actual4e94a7d3-45cf-4d02-bbf6-d591222d0517 habia dejado intento original
abandoned/terminal_missing. Se comprobo inventario del worktree sin agentes
y terminales, procesos y metadatos de sesion guardada antes de restaurar; no
se dio por cerrado un proceso solo por liveness unverifiable.

Restaurada session original con home administrado y --no-daemon, sin fork ni
cambios globales. /status acredita correo efectivo y sessionID; proceso6384
con resume original/no-daemon y padre propio, distinto del supervisor. Todos
los seis hashes coinciden con snapshot249 ya probado; no se repitio suite desde
supervisor. Task original reabierta por autorizacion del usuario; nuevo Dispatch
ctx_9fce40cb9b8a respondio msg_3667453d1da9. Pendiente reporte final; A11 no
integrada/aprobada por mera recuperacion.

### A11: preservacion y contexto confirmados antes del reporte final

msg_15a5d76e3a1e confirma seis huellas del snapshot probado y95 bases fuera de
ownership preservadas:43 identicas byte a byte,52 con diferencia LF/CRLF entre
checkouts sin contenido distinto, sin normalizarlas. Supervisor contrasta otra
vez seis SHA y compara cuerpos context/truncate originales con la utilidad
extraida: iguales tras cambiar solo nombre/acceso del metodo.

Leidas las11 pruebas de IdentityStore: nueve SP, MANDATORY, REQUIRED y caso
REQUIRES_NEW modelado, cardinalidad/tipos y errores seguros. La suite de249 ya
ejecutada sigue aplicable sin cambios; no se repite. Es simulacion de manager/
executor, no suspension de conexiones ni durabilidad DB. Aun falta reporte
final del trabajador y worker_done; A11 no integrada/aprobada en este avance.

## SQL-01.A11 - ACEPTADA tras cierre y hashes finales

Informe msg_84819ef6a833 y done msg_97855813c3f8 recibidos completos en
ctx_9fce40cb9b8a, misma Task original. Seis SHA declarados coinciden con
manifest del snapshot independiente249/249 y archivos actuales del worker.
Se reutiliza evidencia valida sin repetir Maven; no cambio de implementacion
desde ese build. El informe distingue memoria efimera perdida del cotejo
recuperado de95 bases:43SHA exactos,52 solo EOL. No se afirma un baseline
efimero inexistente ni nueva ejecucion del Dispatch recuperado.

Supervisor reviso IdentityService/store/utilidad y ambas suites: nueve SP,
creacion administrativa y registro MANDATORY explicitos, REQUIRED para login/
accept/password, failed REQUIRES_NEW modelado, actor publicado afterCommit y
rollback/commit fallidos sin candidato. Context/truncate extraidos exactamente.
249 pruebas independientes y jar PASS, sin DB ni durabilidad real.

Integrados seis archivos por bytes/SHA (2 existentes+4 nuevos),97 bases
verificadas antes de integrar,95 fuera de ownership intactas. Informe/resultados
en tmp/sqlserver-a11-acceptance.json y snapshot original. Constructor legado
@Autowired mantiene seleccion actual; no SecurityConfiguration/config ni
AccountLifecycle/Bootstrap modificados. A11 aceptada para camino implementado
y pruebas simuladas, no para migracion completa. A12 convierte browser sessions
con CSRF obtenido del mismo SESSION_SAVE y respuesta sin bearer en body.


## SQL-01.A12 - revision provisional de avance

Msg_d81b4583d988 confirma turno del programador en ctx_296d15f80886, aunque
Orca mantiene start_unknown por observacion de arranque incompleta. No es fallo
de implementacion ni autoriza otro arranque. Supervisor leyo tres clases en
worktree sin modificarlas y confronto SESSION_SAVE/CURRENT/LIST/REVOKE conV3.
Proyecciones HTTP explicitas, loginBrowser inmutable/redactado y store11SP
presentes; cookie SQL diferida hasta afterCommit bajo TX exterior.

No hay suite final ni nuevo test de controller disponible en esta observacion.
No se aprueba un avance. Guidance msg_c4b2bae99c1f requiere verificar ausencia
de cookie antes de commit y tras rollback/fallo, salida sin TX exterior,
CSRF/expiry del mismoRS, bearerA11, constructor Spring legado y hashes6.
SQLServer/JDBC/HTTP conectado y navegador real siguen fuera de esta evidencia.


## SQL-01.A12 - ACEPTADA con279 pruebas independientes

Entrega msg_7298902f71ec y done msg_f73a5d08f955 revisados. Seis SHA coinciden
con los archivos recibidos y snapshot tmp/sqlserver-a12-review/backend.
Supervisor leyo tres clases y las tres suites, contrasto firmas V3, diffs
de servicio/store y preservacion de tests A11 retirando solo secciones anexadas.
verify independiente:279/279,0fail/0error/0skip,BUILD SUCCESS20.765s,jar PASS.

Login browser comparte autenticacion/SAVE con bearer, resultado interno
inmutable/redactado y body explicito; CSRF/expiry del mismoRS. Cookie/actor
tras commit, ausentes en rollback o fallo de commit modelado, incluyendo TX
exterior y logout. Lista con nueve campos seguros, current con tenantIdNULL
y revocacion por id64hex sin rehash. Legado @Autowired sigue seleccionado;
CSRF legado se obtiene antes de cookie para no dejar header ante lectura fallida.

Aceptacion limitada: HTTP MockMvc standalone y TX modeladas, no conexiones
SQLServer/JDBC/Flyway/pool ni navegador reales. Se integran6archivos por bytes,
103 bases verificadas y98 ajenas al ownership intactas. Acceptance y manifests
en tmp/sqlserver-a12-acceptance.json y tmp/sqlserver-a12-review-manifest.json.
Sin defectos abiertos dentro del alcance revisado; backend activo sigue legado.


## SQL-01.A13 - revision independiente PASS; cierre por cuota pendiente

Informe msg_bf193d7c4cb6 declara4SHA/301pruebas. Supervisor leyo Access,
SqlServerAccessStore y ambas suites completas; contrato V3/D-21 consistente.
Solo branch/link nuevos caminos, request inyectado/actor exacto, ADM sin bypass,
REQUEST dosSP, parametros opacos, opcion vacia404 y mapeo estricto dentroTX.
Ocho helpers anteriores Access exactos;103bases fueraownership equivalentes
entre worktrees (solo EOL cuando corresponde),104bases raiz sin cambios.
Snapshot independiente verify301/301 y jarPASS20.295s; cuatro SHA confirmados
antes/despues del build. Sin defectos encontrados en alcance inspeccionado.

No integrar por cierre formal pendiente: quota corto antes de worker_done y
segunda escalacion confirma compactacion bloqueada. Evidencia conservada en
tmp/sqlserver-a13-review/backend y manifest/result.json; no nueva aprobacion
por simple exito de suite. HTTP/DB/JDBC/Flyway/navegador reales no probados.


## SQL-01.A13 - ACEPTADA tras cierre formal

Worker_done msg_d0f5e7def244 completa mismo Task/Dispatch sin nueva implementacion.
Supervisor verifica4SHA contra snapshot independiente301/301 previamente probado,
reports13suites/0fallos/0errores/0omitidas y jar. No repetir verify sin cambio.
python -B tmp/accept-sqlserver-a13.py comprueba104bases y copia4archivos por bytes;
103bases ajenas intactas,1modificado+3nuevos. Acceptance.json registra informe
msg_bf193d7c4cb6 y cierre. Rechazo de aprobacion provisional por cuota queda
sustituido por esta aceptacion acotada, sin borrar historial.

Access/store y dos suites aceptados para camino SQL explicito; igual autoridad
request/principal,2SP tipados,404uniforme D-21,REQUIRED y error seguro. No nuevo
wiring/DB/HTTP/navegador real. /status confirma Sol medium y cuota disponible;
se conserva seleccion actual de la misma cuenta/sesion, no cambio supervisor.


## SQL-01.A14 - ACEPTADA: catalogo publico con316 pruebas

Informe msg_9bdf62bea05a y done msg_bd01e7fa5b10 revisados. Supervisor leyo
servicio/store y ambas suites,confronto V3/DTO con D-22 y verifico4SHA.
Store solo2SP/REQUEST,unidadREQUIRED,proyecciones8/4columnas,inmutabilidad
anidada,INT/BIGINT/BIT exactos,orden/Unicode y sin techo241 preservados.
Host interno coherente y guardas SQL de mutadores funcionan en mocks.
Legacy register/request/redeem/issue/rate comparados exactamente salvo guarda.

Snapshot independiente316/316,0fallos/errores/omisiones,jarPASS25.776s.
Integracion por4SHA,107bases verificadas,106fueraownership intactas;1archivo
existente+3nuevos. Acceptance tmp/sqlserver-a14-acceptance.json. El script de
aceptacion tuvo error inicial de lectura cp1252; corregido a UTF8 antes de
cualquier copia; no defecto de producto ni repeticion de Maven.

Aceptacion offline: no HTTP/SQLServer/JDBC/Flyway/navegador conectado ni prueba
de aislamiento/anonimato de red. Constructor SQL no activado; escrituras de
cuenta siguen guardadas. No se requiere nueva QAvisual de frontend sin cambio.


## SQL-01.A15 - ACEPTADA,331 pruebas independientes

Informe msg_67322efac936 y done msg_6b5cd2c87b5a recibidos. Supervisor leyo
servicio/store y tres suites,contrasto4SP nuevos conV3,5SHA y cuerpo legado.
REQUEST catalogo intacto,IDENTITY lookup/membership(false)/issue/redeem,6SP
totales. Elegibilidad normal no revela cuenta en API; errores de carrera no
se ocultan. Enlaces servidor/fragment/TTL/hash y destinatario resuelto en SP,
registration_tenantNULL. RESET codifica antes del SP,VERIFYpasswordNULL; sin
sesion/cookie/autenticar. RegisterSQL sigue guardado.

Snapshot331/331,0fail/0error/0skip,jarPASS22.257s. Acceptance script inicialmente
exigia header test identico y detecto cleanup adicional de sincronizaciones;
se inspecciono y acepto ese cambio pedido por contrato, sin alterar assertions
ni repetir build. Unica expectativa sustituida: guarda request/redeem anterior.

Integrados5SHA,110bases comprobadas,106ajenas intactas,4existentes+1nuevo.
Acceptance tmp/sqlserver-a15-acceptance.json. Pruebas con dobles/MockMvc/TX
modeladas; no SMTP/SQLServer/JDBC/Flyway/HTTP conectado,anonimato de red,
uso unico/revocacion/rollbackdurable ni concurrencia real. Sin nueva QAvisual
ni activacion de backend; no aprobacion integral IAM por este corte.


## SQL-01.A16 - ACEPTADA con343 pruebas independientes

Informe msg_f167318ad12c y done msg_16d4592647e8 revisados. Supervisor leyo
diffs servicio/store y tres suites;5SHA contra snapshot independiente343/343
y jarPASS25.748s. Unidad REQUIRED llama EMAIL_EXISTS,USER_CREATE por entrada
MANDATORY A11,PENDING,PORTAL_REGISTER eISSUE. Pending/portal MANDATORY propios;
UserInput domain/credentialNULL,contextoanonimo y hostexacto,duplicado sin
crear/encoder/outbox. No Actor/cookie/sesion ni paciente/vinculo fabricado.

Pruebas con IdentityService y stores reales,executor/managerdobles,fallos de
cada etapa y commit,rollback exterior y MVCrequest real de fixture. No prueban
rolesPAC/RES,tenant,atomicidad durable o permisos de motor. Guardas plataforma
500 aun conservadas paraA17. Store suma3SP (9totales),sin cambios deV1-V8.

Accept script compara cuerpo de servicio completo retirando solo helper/selector
register nuevos y prefijos de las tres suites:331casos previos intactos.
111bases comprobadas/106fueraownership intactas,5archivos existentes integrados.
Acceptance tmp/sqlserver-a16-acceptance.json. Sin defectos abiertos en alcance
inspeccionado; sin nuevaQAvisual ni SQLServer/JDBC/HTTP/SMTP real.


## SQL-01.A17 - DEVUELTA por R-A17-DOCTOR-QUOTA

Informe msg_df099376d7f5 y done msg_95914bd2ae33 revisados.5SHA y snapshot
independiente352/352+jarPASS26.307s;111bases supervisor sin cambios. Revision
de servicio/store/SQL y suites: contexto plataforma preservado,11SP,JSON
servidor/resultadovalidado,ISSUEregistro explicito yMANDATORY presentes.

Defecto QA reproducido por lectura de fixture: REGISTRATION_PLAN devuelve
includedProfessionals4 en todos los PlatformFlow. Casos positivos DOCTORHUMAN/
ANIMAL y falloCommitDOCTOR aceptanJSONquota4; V4 plan_save153 y resolve173-176
exigen1 paraDOCTOR. Un double que acepta esa oferta no valida escenario posible
con contratos aprobados. Es defecto de evidencia,no prueba de bug de producto
ni razon para alterarV4 o limitar quotas silenciosamente en Java.

Correccion acotada R1: solo AccountLifecycleServiceSqlServerTest,cuotasfixture
parametrizadas,positivosDOCTOR1,CLINIC/VETERINARY4. Regresion ofertaCLINIC4
seleccionada paraDOCTOR con51000inyectado:400seguro,quota4 sinreescribir,rollback
y sinISSUE/202. Conservar otros4SHA y todasassertions anteriores salvo esas
cuotas de fixture; volver verify. Spec tmp/sql-01-a17-r1-spec.md.
A17 no aceptada/integrada; evidencia inicial conservada en review-result.json.


## SQL-01.A17 - ACEPTADA tras R1 y353 pruebas independientes

R1 informe msg_5ec47062eca4/done msg_28d2d264ae80 cierra R-A17-DOCTOR-QUOTA.
Supervisor revisa diff UN test: fixture offeredProfessionals parametrizado,
DOCTORHUMAN/ANIMAL y casoCommitDOCTOR1,CLINIC/VETERINARY4. Regresion51000
inyectada afirma400seguro,quota4 sinreescribir,rollback y sinISSUE. No motor
real ni simulador de reglas de negocio; otro4SHA A17 congelados/intactos.

Snapshot tmp/sqlserver-a17-r1-review/backend:353/353,0fail/0error/0skip,jar
PASS26.946s. accept-sqlserver-a17-r1.py compara5SHA/baselines,cuerposlegacy,
constructores/options/rate y request/redeem previos; integra5archivosexistentes,
111bases verificadas y106ajenas intactas. Acceptance.json vincula Task/Dispatch
A17original yR1,conservando rechazo/evidencia352 inicial.

Alta plataformaSQL aceptada con11SP/contextoplataforma constante,JSONservidor,
cuotas deplan,resultado creado validado,ISSUEregistro explicitoMANDATORY.
No autenticacion automatica/cookie/hostfalso ni nueva configuracion. Se acepta
implementacion y mocks/TXmodeladas,NO permisos/cupos/rollback/concurrencia
reales ni SQLServer/JDBC/Flyway/HTTP/SMTP conectado. Sin nuevaQAvisual.


## SQL-01.A18 - ACEPTADA con368 pruebas independientes

Informe msg_2ffa48cf0b92/done msg_413a740a5390 revisados. Supervisor leyo
TraceFilter/store/dos suites ycontrastoconV3/REQUEST_FINISH. Core filtro,
Origin/gateway/headers y llamada legacy con argumentos identicos; solo nueva
rama store alfinally y cleanup garantizado. Correlacionlocal/contextofinal
validado,SPunico/REQUEST/0RS,REQUIRES_NEWacotado. Respuesta/excepcion original
conservada ante fallopersistenciaRuntime; log seguro soloID,mensajeestatico.

Snapshot368/368,0fail/0error/0skip,jarPASS23.303s. Independentenv gatewayfalse
solo proceso,sinDNS. Se verifican error/cleanup,actoratributos traslimpieza
SecurityContext,mapeos/binds y suspension/reanudacion modelada. No se acredita
conexion/pool/locks/commitdurable por ese modelo.

accept-sqlserver-a18.py verifica4SHA/111bases y core/legacy,integra1existente
+3nuevos;110bases ajenas intactas. Evidencia tmp/sqlserver-a18-acceptance.json.
Sin defectos abiertos en alcance revisado,no nuevaQAvisual ni wiring SQL.


## SQL-01.A19 - ACEPTADA con385 pruebas independientes

Informe msg_80ea187c0939/done msg_a34fb5c8acf0 revisados. Supervisor leyo
AuditService/store/dos suites ycontrastoV1/V3/4SP. Autoridad contextual y
Access.actor coherentes,roles porhost,sin autoridad HTTP;proyecciones6/19/11
campos connullable yJSONVALUEprofundo,inmutables. Paginacionlimit+1 sin
sumarlo enbind,cursorvisibleLong,journey2RS/200steps sin queryadicional.

Snapshot385/385,0fail/0error/0skip,jarPASS23.370s.Baseline114archivos
comprobados en manifest;113ajenos intactos. accept-sqlserver-a19.py compara
legado completo/scope al retirar solo ramasSQL y copia4SHA(1existente+3nuevos).
Permisos/crossTenant/puenteNULL estan modelados,no validados en motor.
No nueva pruebaHTTP/MockMvc en A19(opcional),ni captura/navegador ni cambioUI.
Aceptacion acotada,no auditoria integral enSQLServer/JDBC/HTTP conectado.


A20 ACEPTADA: informe msg_11b7052f1796/done msg_5a2a9bf20f4c,4SHA exactos.
Snapshot independiente verify398/398,0fallos/errores/omisiones,jarPASS22.306s,
2026-11-04T21:54:34-05:00.117bases verificadas,116fueraownership intactas;
1existente+3nuevos integrados. Cuerpos legacy exactos al retirar guardasSQL.
Tres SP tipados,status REQUEST/sample WORKER sin autoridadHTTP,REQUIRED y
WARN estatico revisados personalmente. Evidencia tmp/sqlserver-a20-acceptance.json.
Sin motor/JDBC/HTTP real ni nueva evidencia visual; no backend activo.
A21 siguiente: details/mode por SP en mismos4archivos,secuencia sin solapamiento.


A21 ACEPTADA: informe msg_5d06be4f117a/done msg_afd7844ea41a,4SHAexactos,
verify independiente410/410 sinfallos/errores/omisiones,jarPASS23.115s,
2026-11-04T22:03:41-05:00.120bases verificadas,116ajenas intactas;4existentes
integrados. Legacy y sampler/statusA20 comparados exactos retirando solo ramas
SQL details/mode. Autorizacioncontextual,tenant3SP/plataforma6SP y mode2SP,
nullableversionFlyway,inmutabilidad y TX modeladas revisados. SinJDBC/HTTPreal
ni evidencia visual nueva ni backend activo. Siguiente A22 correo por claim/
complete con SMTPdoble y sinreintento automatico ante resultado ambiguo.


A22 ACEPTADA: informe msg_f0856447bb7a/done msg_98705a30ccac,4SHAexactos,
verify independiente424/424,0fallos/errores/omisiones,jarPASS22.813s,
2026-11-04T22:12:08-05:00.120bases verificadas,119ajenas intactas;1existente+
3nuevos integrados. Cuerpo sendlegacy exacto retirando selectorSQL. Revision
personal confirma claimcommit antes senderfueraTX,AMBIGUOUS paraexcepciones,
completefallido sinreclasificacion/reenvio,logsestaticos y WORKER9NULL.
No SQLServer/JDBC/SMTP/HTTP reales ni nueva evidencia visual. A23 siguiente:
Bootstrap con executor/principal separado,sin configurar ni crearusuarios.


A23 ACEPTADA: informe msg_dc8bc56cebd5/done msg_1d077c1c01ff,4SHAexactos,
verify independiente437/437,0fallos/errores/omisiones,jarPASS23.672s,
2026-11-04T22:20:24-05:00.123bases verificadas,122ajenas intactas;1existente+
3nuevos integrados. Cuerpo legacy exacto retirando selectorSQL; EXISTS antes
hash diferido y CREATE en mismaREQUIRED,BOOTSTRAP9NULL,sinbean/wiring.
Sin usuarios/principales/SQLServer/JDBC/HTTP reales ni evidencia visual nueva.
Siguiente A24 soporte lecturas,escrituras guardadas hasta A25.


A24 ACEPTADA: informe msg_812fbd62269b/done msg_40493c72a239,4SHAexactos,
verify independiente452/452,0fallos/errores/omisiones,jarPASS24.483s,
2026-11-04T22:29:00-05:00.126bases verificadas,125ajenas intactas;1existente+
3nuevos integrados. Records/rutas/cuerposlegacyexactos retirando ramasSQL.
Ownershiptenant/autor porfila,proyecciones12/4,nullable y MAX,mapeodentroTX
revisados personalmente. SinSQLServer/JDBC/HTTP reales ni evidencia visual.
Siguiente A25 escrituras soporte,mismos4archivos sin solapamiento.


A25 ACEPTADA: informe msg_a7c3353a8c4f/done msg_529d3a89d58a,4SHAexactos,
verify independiente460/460,0fallos/errores/omisiones,jarPASS24.375s,
2026-11-04T22:39:23-05:00.129bases verificadas,125ajenas intactas;4existentes
integrados. Legacy/list/getA24 comparados exactos retirando ramasSQLwrites.
Requestpublico/rate/receipt5campos y STEP6args2RS sinDETAILextra revisados.
GuardaA24obsoleta reemplazada segunencargo (451previos+9netos=460).
SinSQLServer/JDBC/HTTP reales ni nueva evidencia visual. A26 siguiente:
lecturas plataforma planes/usuarios/especialidades/auditoria sinwiring.


A26 ACEPTADA: informe msg_83b0af00a8fc/done msg_7132631cf5b7,4SHAexactos,
verify independiente476/476,0fallos/errores/omisiones,jarPASS24.161s,
2026-11-04T22:50:23-05:00.129bases verificadas,128ajenas intactas;1existente+
3nuevos integrados. Legacy methods/domain/TENANT_QUERY comparados exactos.
SAD/4SP/proyecciones21/6/5/7/JSONprofundo/nullable revisados personalmente.
SinSQLServer/JDBC/HTTP reales ni nueva evidencia visual. Siguiente A27:
tenants/tenant/status plataforma,mismos4archivos,secuencia sin solapamiento.
