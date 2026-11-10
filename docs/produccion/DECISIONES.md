# Decisiones y contratos de integracion

## D-87.AB: R3 integrada offline; QA real E4 separada, 2026-11-10

R3 task_a96d20ae95f1/ctx_a3cf0f3b75a2 aceptada: supervisor contrasta 33
artefactos/695 fuentes/726 pines/141 historicos, integra cuatro fuentes por SHA,
check/107 frontend/17 Python PASS. Helper cookie consulta /api/ y exige HttpOnly;
regresion rechaza la consulta raiz. Resto solo namespace/contexto E4 de tres
constantes con manifest identico; transporte/guardas/cleanup intactos. Evidencia
VINCULOS_QA_CORRECCION_R3_20261110.json. Ningun arranque/red/SQL/DPAPI real en R3.

E3 task_90e714865b19/ctx_c5fefc021198 FALLIDA, REVISADA: una ejecucion raw1,
SESSION_MISMATCH/cookie-validation, cero lecturas, una sesion nueva/revocada.
29 artefactos/695 fuentes/726 pines/106 historicos contrastados; negocio/ACL e
historia iguales, cleanup Node/Edge/app/proxy medido0. Defecto de consulta cookie
consistente con fallo confirmado usando filtro Playwright puro, sin navegador.
VINCULOS_QA_FALLO_E3_20261110.json. E2/E3 no se transforman en PASS desde modelos.
Siguiente UNA QA real readonly E4 segun PAC-01-B5-E4.md, epoch fresco y cuatro
queries admin de conservacion/correlacion, sin reintentos o escrituras de negocio.

## D-87.AA: E3 fallida revisada; correccion de alcance de cookie, 2026-11-10

R3 delegada task_a96d20ae95f1 / ctx_a3cf0f3b75a2 como follow_up del programador
retenido. No nueva ejecucion real hasta review; supervisor preserva fuentes.

task_90e714865b19/ctx_c5fefc021198 failed, msg_fb546901b79c: una ejecucion
raw1/SESSION_MISMATCH, human-login/cookie-validation/ASSERTION, cero lecturas.
Supervisor contrasta 29 artefactos/695 fuentes/726 pines/106 historicos, cuatro
queries raw0, negocio/ACL/historia iguales y cleanup medido Node/Edge/app/proxy0.
Una sesion nueva/revocada y login/logout1; unexpectedNewSessions1 se conserva:
el template la compara con actores de lecturas observadas, aqui conjunto vacio.
No evidencia positiva API/UI/audit de lecturas ni reintento de E3.

Backend cookie Path=/api; QA nueva consulta context.cookies(origin), que filtra
para raiz /. QA previa aceptada consulta origin+'/api/'. Supervisor verifica
funcion pura filterCookies de Playwright instalado con una cookie sintetica:
raiz0/api1, sin navegador/red/SQL. Defecto determinista de scope en herramienta,
consistente con paso fallido; no inspeccion de cookies reales ni atribucion de
causa al E2 anterior. VINCULOS_QA_FALLO_E3_20261110.json conserva evidencia.

R3 segun PAC-01-B5-R3.md: cuatro herramientas QA, corregir consulta a /api/ con
regresion significativa; nuevo namespace/contexto E4 de tres constantes, resto
R2 intacto. Solo offline, sin secretos, procesos operativos, servicios o QA real;
E4 requiere revision e integracion y encargo posterior. Misma pareja/Run.

## D-87.Z: R2 integrada offline; nueva QA real E3, 2026-11-10

Publicacion revisada be8c03c5d0c9f6a1c0b9e607e683cb3251217734,
origin/health/production-wave0 confirmado. E3 delegada task_90e714865b19 /
ctx_c5fefc021198 como follow_up del programador retenido; supervisor sin trafico
SQL/API/browser concurrente durante QA exclusiva. Espera entrega Orca para review.

R2 task_b571f0e96469/ctx_abcd60b65a34: supervisor verifica 51 artefactos,
695 fuentes, 726 pines y 56 historicos E1/E2, integra solo cuatro herramientas
por SHA y comprueba check/106 frontend/17 Python PASS en root. Transporte browser
same-origin con guardas readonly, diagnosticos cerrados y Job accounting antes
de cerrar handle; contexto nuevo con tres constantes y manifest identico.
Dos fallos unitarios iniciales conservados. Evidencia
VINCULOS_QA_CORRECCION_R2_20261110.json. Sin DPAPI/SQL/HTTP/Edge/probes reales.

E2 task_8fc4de487847/ctx_81f27beb2ebc permanece FALLIDA, REVISADA:
human-login/UNEXPECTED_FAILURE, cero lecturas/sesiones nuevas; negocio/ACL e
historia conservados, app/proxy Jobs0. Conteo Node/Edge no probado y causa
indeterminada. VINCULOS_QA_FALLO_E2_20261110.json conserva limites y artefactos.
Siguiente E3 segun PAC-01-B5-E3.md: una QA real readonly en namespace nuevo,
cuatro consultas admin de evidencia y cleanup numerico cerrado. No implica
aprobar QA real, produccion o todo PAC-01 desde los dobles offline.

## D-87.Y: E2fallida revisada; R2solo QAoffline, 2026-11-10

R2 delegada task_b571f0e96469 / ctx_abcd60b65a34, followUpOf
ctx_81f27beb2ebc. Recibo recuperado sin duplicar envio: input_accepted,
agente live en terminal retenida term_7286bcc6-6224-4d5f-a389-b06a09939ca3.
Supervisor espera entrega para revision independiente; E3 no ejecutada.

msg_135970ff37d8/task_8fc4de487847/ctx_81f27beb2ebc failed:1invocacionraw1,
human-login/UNEXPECTED_FAILURE,0checks/lecturas/sesionesnuevas. Supervisor
congela28artefactos/695SHA/726pines ycontrasta4queries readonly: negocio/ACL e
historia iguales, READauditnuevo0, app/proxyJobs0. Node/Edge0no probado por
resumen generico; no inventar ese conteo. Sin positivoAPI/UI/audit. Evidencia
VINCULOS_QA_FALLO_E2_20261110.json. E2permaneceFALLIDA, sin repetirla ni borrar
sus diarios/directorio,0diagnosticos operativos adicionales por supervisor.

R2segunPAC-01-B5-R2.md prepara4herramientas QA: transporte browserfetch+flags
loopback usadosporQA A previa (hipotesis, causaactualnoexpuesta), categorias/
pasos cerrados sin secretos ycleanuptelemetry observable viajobfactory. Namespace
E3 nuevo fijo ycontextocopia3constantes preservanE1/E2; no ejecucion enR2.
No producto, TLSconfig, datos, SQL oNativeprobes en esta correccionoffline.


## D-87.X: B5P1+R1 aceptadas; E2 readonly real y auditoria, 2026-11-10

R1msg_3710c4373267/task_5b68545267fc/ctx_2954143ce013 succeeded, delta solo
testscope conpaths simulados. Supervisor congela17artefactos,691SHA/726pines
y690fuentes sin delta; integra4fuentes B5exactas (testSHAfinalA8238F9C...),
check/103unitfrontend y14Python propios enrootPASS. P1previa47artefactos y
contexto3constantes/manifestidentico/diariosE1 preservados. Sin ejecutarB5real,
DPAPI oEdge en preparacion. Evidencia VINCULOS_QA_PREPARACION_20261110.json.

Supervisor preflightreadonly confirmaHUMAN1paciente/1link yANIMAL1paciente/0link.
Pre/post plantillaaudit preparada, primero rechazosSQL468/8124 porcollation y
aggregateouterref preservados, corregidos soloTEMPmetadata. Final emptyset
motorreadonlyPASS no es positivo deREADaudit. Template0745D9B0...676CFCD ypre
488152DE...713945 quedanpinneados; E2debe capturar nuevoscutoffs/epoch reales.

Autorizar UNAejecucionB5E2 segun PAC-01-B5-E2.md: contextoB5, login/logout
propios+GETnegocio, sinfixtures/mutacionesnegocio. AdminLPCreadonly4queries
pre/poststable/audit,1eventopor200 y0por401/404, actor/tenant/patient/request/
GETroute/metadata{}exactos, hashhistoria conservada. Auth3sesiones nuevas y
revocadas, auditLOGIN/LOGOUT previstos; no esperar auth/audit globales iguales.
Sinretry/config/certificados/servicios o diagnosticoextra; siFAIL volver a
review sin compensar. E1cerrada ytarget/data/projectscope invariantes. Nada
habilita produccion, escrituras de vinculos o completar todoPAC-01.

Herramientas/contratoE2 publicados ba97e23c06b2563d20574d54154599fbc251be6c, remotoSHA confirmado. E2delegada task_8fc4de487847/ctx_81f27beb2ebc, follow_up ready al mismo programadorretenido. Supervisor sin SQL/API/navegador concurrente duranteQA exclusiva; espera resultadoOrca para revisar evidencias reales.

## D-87.W: B5P1 revision y correccion de prueba de checkout, 2026-11-10

P1msg_095fd1c14336 succeeded EN_REVISION; supervisor congela47artefactos y
verifica691SHA/726pines,687fuentes previas intactas. Contextocopia solo3constantes,
manifestidentico ydiariosE1 conservados. Revision detecta testscope depende
__file__real: esperaPATH_SCOPE_CHANGED pero enrootcanonical devuelvePIN_INVALID
con{}. Reproducido conmoduloinerte/patch enmemoria,0DPAPI/SQL/HTTP/procesos.
No integrar aun. R1SOLO testPython segunPAC-01-B5-P1-R1.md, suitePython ydoscasos
pathsimulados; no repetirfrontend103/check sin cambios. P1no aprobada/E2noejecutada.
Logout autorizado esDELETE de auth/browser/session propio (protocoloexistente),
no DELETEnegocio; aclaraciondecontrato, sin cambiofuncional en las otras fuentes.


R1delegada task_5b68545267fc/ctx_2954143ce013, follow_upready al mismo programadorretenido. Supervisor no edita la fuente de test asignada; espera resultadoOrca.

## D-87.V: readiness real backend estricto aceptada; B5 QAreadonly, 2026-11-10

msg_c93624d27935/task_a5de78616b7f/ctx_7444a0818a45 succeeded. Supervisor
congela15artefactos,contrasta687SHA/726pines ycodigo/harness1invocacion,raw0
READY_FOR_QA/12.172s/pollHTTP1. CompletionambosJobsactivos0 ypuertosappcerrados;
SQLQA Running14335/PID13304. Workerpre/postbase/huella iguales; baseline fresco
independiente igual alantesE1/B1POST, installed1/ACL564/OPEN; protecciona04...af
independiente igual. No reejecutar readiness. Aceptar LOCALBACKEND positivo con
configJDBC encrypttrue/trustfalse/truststore dedicado; no TLSproductivo/negativos
nuevos ni contarSQLdesdeunpoll. productTLSValidatedfalse del launcher inmutable.
Evidencia BACKEND_TLS_READINESS_20261110.json. APInegocio/UI de vinculos no probados.

B5P1 prepara cuatro archivosQA y contextoTEMP nuevo para futura operacionreal
readonly con fixtures existentes; contrato PAC-01-B5-PREPARACION.md. SinDPAPI/
SQL/HTTP/browser/probes enP1. CopiaB4env con SOLOmanifest/ledger/completion nuevos
ymanifest726identico conservaE1consumido; no es retry de gatefallido ni borrar
historia. FuturaE2 mantendra contexto durantebrowser, login/logout propios yGET
negocio; sin crear datos/cambiar roles o permisos. Review antes de ejecucion.
Fixturesmissing/mutadas se informan prerequisitofallido, no se fabrican ni
se atribuye21filasreales a la evidenciaSQL/sintetica anterior. PAC-01 parcial.

E1aceptada publicada bf7e2a9fe7f6dce474d82f2df551d4cb2b7d9eff, remotoSHA confirmado. B5P1delegada task_2a13d59328f9/ctx_4e58d4bba3bf, follow_up ready en programadorretenido. Cuatro rutas nuevas yTEMP exclusivos, sin QAreal en preparacion; supervisor no modifica ownership y espera avisoOrca para review.

## D-87.U: B4P1 aceptada offline; gate E1 real acotado, 2026-11-10

msg_8b8dbe4fad02/task_131aca7351c3/ctx_4fcac67b4740 succeeded tras retomar
misma cuenta/sesion/Task. Supervisor congela73artefactos,contrasta726pines y
687SHA sin cambios; recompila3classes y coincide exacto,26tests propiosPASS.
Revisa codigo completo/correccionesZIP/proxy/FD y dos resultados nativos:
publicinspectraw0/155guardas ytimeoutinocuo1.016s/raw1esperado,ambosactivos0.
No repite probes ni modifica producto. Fallos18/1 y23/1+11 se preservan;26final
no sustituye historial. Evidencia BACKEND_TLS_PREPARACION_20261110.json.
P1 VALIDADA PREPARACION, no backend/TLSruntime/SQL/API/UI real ni produccion.

Autorizar E1UNA invocacion --execute-readiness con launcherF5CD650F...3E1B41B0
y manifest6BF5A987...1E35FA6 inmutables; contrato PAC-01-B4-E1.md. Publicinspect
interno E1 una vez antes de load runtimepassword, ChildWindowsJobs ydefault
targets127.0.0.1 SQL14335/backend18080/proxy18300,trustfalse/encrypttrue.
Solo readiness real y teardown propios, no APInegocio/login/fixture oTLSapply.
Prebaseline supervisor igual al B1POST(installed1/564ACL/OPEN), huella protegida
a04d8236...ae8ca2af igual; SQLQA Running. Worker pre/post readonly hashes/huella
yactivos0, sinretry oSQLdiagnostico. E1failed vuelve a review sin compensacion.
No nuevo UAC/certificados/servicios/migraciones/DPAPIrecreado/bootstrap/main.

Preparacionrevisada y contratoE1 publicados ca92570a0d848ac6325c5079be138fd3e593295c, remotoSHA confirmado. E1delegada task_a5de78616b7f/ctx_7444a0818a45, follow_up ready al programadorretenido. Supervisor sin SQL/API/trafico concurrente durante el unico execute autorizado; espera resultadoOrca para revision independiente.

## D-87.T: cuota programador y revision parcial B4P1, 2026-11-10

Escalacion msg_stop_6bc70500149e3db2f663a2eb por limite proveedor, reintento
anunciado14:06 local. Dispatchctx_4fcac67b4740/Tasktask_131aca7351c3 siguen
abiertos yterminal live retenido; no worker_done/abandon/retryTasknuevo. Sin
cambiar cuentas/globales/modelos ni gasto. B4P1 no aceptada; tableroBLOQUEADA
por cuota y correcciones pendientes. B1/B2/B3 aceptadas conservan su alcance.

Supervisor congela15archivos parciales,687SHA previos intactos,18tests con1fallo
real preservado. Auditoria pura identifica ZipInfoWindows normaliza slash/NUL
antes de validacion, reproduce carrera stdoutproxy aun vacio conbackend200
sinHTTPreal, y revisa fuga deFD si os.pipe2/3 falla antes de tracking. Correccion
al mismo programador segun PAC-01-B4-REVISION-PARCIAL.md, no editar su ownership.
No app/proxy/SQL/DPAPI oprobesnativos por supervisor. Javacraw0 no implica runtime
validado. Evidencia BACKEND_TLS_PREPARACION_PARCIAL_20261110.json. Sin E1 hasta
P1completa yreview, y sin declarar cancelado el objetivo por este limite temporal.

Correccion enviada al Dispatch abierto mediante msg_6abef3b426ce. Nueva escalacion msg_stop_a0001f251f4a701c1bdbd71a confirma la misma cuota14:06, sin nueva implementacion/worker_done. No reenviar repetidamente ni crear otro agente: conservar mensaje en cola y retomar mismo contexto cuando proveedor permita.

Usuario ordena continuar16:14, pasado14:06 anunciado. Estado Orca conserva Task/Dispatch abierto, terminalretained y livenessunverifiable; pantalla muestra ultimo limite, no prueba cuota actual ni salida. IdentityOnly recuperapiura coincide. Se envia continuacion msg_703200f4cf9f al MISMOctx_4fcac67b4740, reciboaceptado, sinstop/abandon/retryTasknuevo. Capacidad/inicio efectivo pendientes de resultado; no afirmar ya corregido o listo. Mantener alcanceP1 y esperar avisoOrca, sinpolling.

## D-87.S: B3 UI aceptada sintetica; preparacion backend estricto, 2026-11-10

msg_147fd4ee42df/task_70d39caaf8e6/ctx_7e6db58956df succeeded. Supervisor
congela141artefactos,683SHA y2bundles444archivos cadauno; revisa6fuentes y15
capturas desktop1440/mobile390/temas/estados. Integra6rutas por SHA exacta,
check94unit/build85PASS y8controles Playwright independientes sobre bundle
integrado,0writes/0errores. Consulta opt-in ADM/REC sinPAC/RES mixtos, sin
cambiar operacionesA. Worker29links/28regresionA/demo13PASS son sinteticos;
15writes del runnerA son interceptadas y separadas de0writes de links.
Evidencia PACIENTES_VINCULOS_UI_20261110.json y16capturas versionadas/revisadas.
Aceptada INTEGRADA SINTETICA, no HTTP/SQLreal, auditoria o persistencia.

Siguiente B4P1 prepara TEMP-only launcher/contextmanager de entorno backendQA
con truststorePUBLICO ya aceptado, trustServerCertificatefalse/encrypttrue,
jarB2supervisor pinneado y proxy existente. Contrato PAC-01-B4-PREPARACION.md.
Sin arrancar backend/proxy/SQL ni DPAPI en P1; solo compilacion/tests yUNA
inspeccionpublicaJVM+UNprobeinocuoJobtimeout permitidos. EjecucionreadinessE1
posterior a review separada. No tocar certificados/binding/servicios/globaltrust
o repetir A69/B1. PAC-01general siguePARCIAL y gestionar vinculos sigue pendiente.

B3 publicada en origin/health/production-wave0:49339a6e5bb0d1bac15c6473468882ad3cd1c58f, remotoSHA confirmado. B4P1delegada task_131aca7351c3/ctx_4fcac67b4740, follow_up ready al mismo programador. OwnershipTEMP-only y2probespublicos sinsecretos; no modificar producto o generar traficoQA concurrente. Supervisor espera resultado para revisar antes de E1.

## D-87.R: B2 API integrada offline; gate B3 UI, 2026-11-10

msg_c002ce76f938/task_b79ceb263c47/ctx_233b5c88077b succeeded EN_REVISION.
Supervisor congela117artefactos+10build,678SHA,7modificaciones+1alta exclusivas;
lee4diffs producto y4tests, contratos V8historicos conservados/V13delta explicito.
Integra8fuentes por SHA exacta y ejecuta Maven verify propio JDK21:1007tests,
0fails/errors/skips, raw0BUILD SUCCESS.68XMLworker y68XMLsupervisor contrastados.
Aceptada INTEGRADA OFFLINE, no HTTP/SQLreal/UI ni backendtruststore configurado.
Evidencia PACIENTES_VINCULOS_API_20261110.json. Fallos auxiliares de agregacion
(prefijoXML y codificacionUTF16logPowerShell) retenidos, sin reejecutar tests ni
confundirlos con fallos de producto. B1 no se repite ni se reaplica.

Siguiente B3consulta UI, seis rutas explicitas PAC-01-B3-UI.md, mismo programador.
Entrada opt-in desde ficha, ADM/REC separados de writable,20+lookahead21,
sin nueva escritura/directorioglobal; abort/invalidation de contexto y errores
seguros. Playwright interceptado y regresionA/democomo pruebas sinteticas;
QA real HTTP/SQL/TLSruntime separado posterior a review. No certificados/UAC/
servicios/DPAPI en B3. PAC-01 completo conserva estadoPARCIAL.

B2 publicada en origin/health/production-wave0:414d351a79ae71d9cf0a149fc0f1c860ee8629ee, SHA remoto confirmado. B3delegada task_70d39caaf8e6/ctx_7e6db58956df, follow_up ready al retenido. Primera invocacionCLI rechazo argumentos por comillas nativasPowerShell antes de crear Task; envio corregido con argv estructurado al mismoorca.exe, sin duplicar asignacion ni cambiar contrato. Supervisor espera aviso Orca para revision.

## D-87.Q: B1 SQL validada local y continuidad API, 2026-11-10

POST msg_b4a030de36f1/task_a365f58c15b4/ctx_c0ff2493b6d1 succeeded.
Supervisor congela17artefactos y reporte, contrasta677SHA y reinterpreta tres
baseline crudos y el unico resultado autocommit. Error51000 exacto, TX0/state0,
IMPLICITOFF y sin auditoria nueva. Tres capturas iguales al ACK/fresh de
instalacion; otra conexion readonly independiente tambien coincide. Sin retry,
reaplicar V13 o repetir PRE. B1 VALIDADA LOCAL SQL: PRE40/40 y55lecturas previas,
una instalacion supervisada reconciliada, un negativoPOST,134SP/564ACL.
Evidencia PACIENTES_VINCULOS_SQL_20261110.json; historialE1/E2/E3 conservado.

Siguiente dependencia PAC-01.B2: GET /api/patients/{id}/links, solo store SQL
Server y SP tipado nuevo, ADM/REC con rechazo PAC/RES incluso mixtos, lectura
historica sin PORTAL/write guard. Contrato PAC-01-B2-API.md:8rutas exclusivas,
implementacion/pruebas offline por programador retenido, revision independiente.
scopes historicos se muestran como lista de strings, incluidos vacios y valores
desconocidos, sin conceder derechos ni reutilizar validaciones de escritura.
UI/HTTP/SQL reales y backend con truststore dedicado estricto quedan para gate
posterior; no modificar certificados/servicios ni repetir A69 por esta entrega.

B1 publicada en origin/health/production-wave0:677b19d61a270b24965510ac4de6af9645149fd2, SHA remoto confirmado. B2 delegada task_b79ceb263c47/ctx_233b5c88077b al mismo programador retenido, follow_up ready. Supervisor no modifica sus ocho rutas durante implementacion; espera aviso Orca para review.

## D-87.P: instalacion V13 reconciliada, gate POST, 2026-11-10

UNexecute install-v13-reviewed.py--execute:raw0COMMIT_ACKNOWLEDGED, reconexion
freshBaseline igual al ACK, installed1/ACL564. UnaTXexterna bajoEXEAS usuario
hp_qa_isolated_migrator yREVERTantesCOMMIT, ningun setup/logins/owner/negocio.
Checks dePREreutilizadosvalidan oldACL/modulos exactos+1SP+2ACL,7columnas/3params,
hashes de8tablas/columnas/principales/roles/mode iguales antescommit. No retry.

Inspeccionindependiente de definicionUTF16LFtrim coincide
238A044649B952D40ABD1DAADD10AE1C49C596AF34DFDD7724CAD9F73EEF21AA,
134SP,callercontext,ANSI/QUOTEDON,ACLsoloEX/Ghp_runtime yEX/Dhp_bootstrap, grantordbo.
Primerassertmetadatosauxiliarno acepto char4p.type sinRTRIM; proyeccion explicita
RTRIM ycomparacionexactaPASS, sin reiterar instalacion ni cambiarpermisos.
Outcome/SQL/diario conservados en tmp/pac-01-b1-20261110/install.

SoloQA local, backend/Java/UI no activados. Se autoriza POST una vez conmain
AUTOCOMMIT_POST_APLICACION, fuentescanonicas integradas yusuarioSQLruntime real
impersonado, sinfixture/DDL/COMMIT. Esperar51000antesaudit/TX0 y3baselineiguales.
Contrato PAC-01-B1-QA-POST.md. No PREreapply, TLS/servicios/DPAPI o probesextra.

POST delegada task_a365f58c15b4/ctx_c0ff2493b6d1, recibo follow_up ready en
programador retenido; supervisor sin trafico concurrente hasta cierre.

## D-87.O: E4 aceptada, integrar y aplicar V13 soloQA, 2026-11-10

E4msg_4d0afb1b91ad/task_ea32e297d259/ctx_b254a48d7c5c succeeded. Supervisor
congela286artefactos/reporte,675SHA yrevalida salidas CRUD crudas conparserrevisado:
40framesfase,81framesbaseline identicos,5positivas/55lecturas y35negativas reales,
raw16/3998exacto dondecorresponde. Freshbaseline independiente igual a todaslas81,
V13ausente/562ACL;0retries,35.522426s. E1/E2/E3 fallidos se preservan sinrelabelling.

Se acepta PREreal y se integran2fuentes exactas a supervisor:V13667D8C07...E3ACF51
yverificador8DF151ED...BAC15CA1. Decision supervisora de instalacion solo enQA
existente por dependencia cumplida, bajo autorizacion continuada del usuario.
No otro setup/flywayV1..V12, principal/owner/filasnegocio o grantglobal. Aplicar
V13 una vez con hp_qa_isolated_migrator existente separado, unaTXexterna, checks
catalogo/7columnas/firma y delta2ACL reutilizados EXACTOS de PREvalidada, hashes
de datos/columnas/principales/membresias/mode iguales antes de COMMIT. Revertir
impersonacion,COMMITsolo si1/1 yack0/0, reconciliar enconexionnueva, sinretry.

Plan temporal install-v13-reviewed.py/apply-reviewed.sql, payloadSHA
F858C5D926E7D93E2C992C52EC8952E27EF7CFDC10D37ABEA2B0D4E15D8AE488,
unaCREATEPROCEDURE y2ACL. Primera preparacion fallo antesSQL por guardademasiado
amplia que rechazaba INSERT@columns(metadata7descriptores delcheckrevisado);
se permite exactamentedichotarget temporal, ninguna escritura de tablasnegocio.
Historialretenido,0intentosSQL hasta plancompleto. No nuevo UAC/TLS/servicios.
POST/autocommit siguependiente tras instalacion y nuevaQAdelegada. No backend/UI
activados ni consideracion de migracion completa/produccion.

## D-87.N: R4 aceptada y gate E4, 2026-11-10

R4msg_e2e802a7642e/task_973a8f8ea6c5/ctx_5f00ab4aab73 succeeded. Supervisor
congela fuentes/22artefactos,675SHA ydiff exacto5lugares, V13inmutable. Inspecciona
todoPARSEONLYON->SQLgenerado->OFFaislado, salidasraw0vacias ydoomframe/3998raw16.
RegresionindependienteargvrealV11 y7combinacionesinsegurasraw/Msgextra rechazadas.
ProbeSYNTHETIC3998 no se etiquetaSPforeignauthorization ni fingerprintrestored.
Baselineposterior completo igual aE3final,0V13/562ACL. R4VALIDADA SINTAXIS/PROTOCOLO,
noSPcompilado/40casosnegocio. Verificador8DF151ED...BAC15CA1 congelado r4-review,
V13667D8C07...E3ACF51 intacta. Se autoriza E4UNA PRE40fases rollback-only, sin
probesextra/retry/instalacion/POST/COMMIT. Contrato PAC-01-B1-QA-E4.md, QAexclusiva.

E4 delegada task_ea32e297d259/ctx_b254a48d7c5c, recibo follow_up ready en el
retenido. Supervisor sin traficoSQL/API concurrente hasta resultado.

## D-87.M: E3 falla sintaxis QA, R4 acotada, 2026-11-10

E3msg_6c11a3c5dbde failed0/40,Msg156Level15 cerca'off' en @cases. Supervisor
congela reporte/10artefactos y comprueba3baselinesidenticos,V13ausente/562ACL.
Reconstruccionoffline delbatchubica columnaoff ylectura@off=off. Rawsqlcmd0
con-V16 no causaPASS: frameinvalidoconstatoFAIL. No reiterar matriz defectuosa.

Diagnosticos supervisor independientes,sinDDL/DML/negocio: -V11 retorna15 ante
errorSQLseverity15; TXsesionsinteticaTHROW51002/CATCHstate-1 retorna16+solo3998
al rollbackautomaticofinbatch. Protocoloactual no corresponde alraw1 delmodelo.
Se autoriza R4 SOLO verificador:off->page_offset,-V11 yraw16estricto para3998,
mismaframe/error/estado/baselines/40casos. V13/pin667D8C07...E3ACF51 inmutables.
QAmax2probes cerrados:PARSEONLY todoSQLgenerado(noexecute/compile) ydoommetadata
sintetico. Sinmatriz/instalacion/COMMIT hasta revision. Contrato PAC-01-B1-R4.md.
Source oficial de PARSEONLY enlazada en contrato; no NOEXEC o sustitutos que
compilen/ejecuten fixtures. TLSlocalvalidada no se reabre ni se cambia.

R4 delegada task_973a8f8ea6c5/ctx_5f00ab4aab73, recibo follow_up ready en el
programador retenido. Supervisor sin traficoQA concurrente durante los2probes.

## D-87.L: R3 preflight aceptado, gate E3, 2026-11-10

R3 msg_36375b32d969/task_7fe6306bdf1a/ctx_eb857fa274ca succeeded EN_REVISION.
Supervisor congela2fuentes/reporte/artefactos, verifica675SHA y18artefactos,
diffsoloowner/pin y SP+ACL byte-identicos, ejecuta regresion enTEMP independiente
2pares/40negativos/14variantesPASS. ProbeSQLunico0/0->1/1->rollback0/0PASS revisado,
sin repetirlo. BaselineindependienteantesE3 igual al postTLS yE2,0V13/562ACL.
R3 VALIDADA PREFLIGHT, sin compilar/instalarSP o matriz. FalloLF/CRLF previo0SQL
preservado; no tolerancia de pins ni cambioowner real.

Fuentes congeladas r3-review V13667D8C07...E3ACF51 yverificador38F432F1...90344B.
Autorizar E3unaPRE40fases rollback-only, mismo contrato/guardas/fixtures/errores y
parada al primerfallo;QAexclusiva, no TLSrestart/DPAPI,POST o COMMIT. Contrato
PAC-01-B1-QA-E3.md. CuerpoSP/ACL y controladorR2 quedan iguales a lo revisado.

E3 delegada task_8dd7018f8dd2/ctx_60264a630817,recibo follow_up ready en el
programador retenido. Supervisor no genera trafico concurrente durante matriz.

## D-87.K: TLS local validado, retomar guardadbo, 2026-11-10

A69.QA.E1 msg_2f0f72bec751 task_741dbe3719c7/ctx_7829652bd835 succeeded.
UNlauncherexecute-once,raw0COMPLETE,4checks reales(1handshake,1healthSP y2rechazos
CA/hostname),3conexiones/1SPhealth,0retries. Supervisor contrasta675fuentes,
inputs/8artefactos reporte/5salidas nuevas, ledger/completion/result coherentes;
keytoolindependiente confirma1trustedCertEntryCApin y0entradas enstorevacío,
sinprivatekeys. BaselineSQL posterior exacto al E2final previoTLS: negocio,
sesiones/auditoria,modulos/columnas/ACL/principales sin deriva. Huella protegida
a04d8236...ae8ca2af intacta,QA Running. Error de sintaxis del harnessprebaseline
previo queda historico; no se inventa capturaantesJDBCpostrestart.

A69 VALIDADA LOCAL JDBC TLS, evidencia TLS_LOCAL_20261110.json. No TLSproducto,
HTTPSpublico/despliegue ni configuracionTLS del backendlauncher: no se cambiaron
sus propiedades. BindingP1false historico permanece inmutable; nuevo agregado
describe validacion posterior. Diarios/resultados/stores se retienen, sinreissue.

Retomar B1R3:metadata independiente confirma dbo1 WindowsU/auth3/schemaowner1
ySIDigualsys.databases.owner_sid. Solo precondicion propuestaV13 y pinverificador;
paresS/INSTANCE1 oU/WINDOWS3 permitidos con ownershipreal exacto. No cambiarowner
o permisos reales ni cuerpoSP/ACL, no matrices/autocommit/install todavia. Se
autoriza unprobe delprimerbatchpreflight metadata-only enTXexterna revertida,
sinDDL/filasnegocio, despues de diff/regresionoffline. Contrato PAC-01-B1-R3.md.

Entrega TLS revisada publicada ce9b181011f0b1bad16722bb62daf0cb1bfd5c2e en
origin/health/production-wave0, remotoSHA confirmado;17rutas explicitas, sin
tmp/DPAPI/store/privatekeys ni main. R3 delegada task_7fe6306bdf1a /
ctx_eb857fa274ca, recibo follow_up ready en programador retenido, mismo Run.

D-87.K.A pregunta msg_375c136a0188: harnessR3 detuvo pin antes de ledger/SQL
porque hashLF del texto no coincide con bytesCRLF escritos por Windows. Supervisor
contrasta amboshashes ySQLcompleto metadata-only,ledgerreal ausente y2fuentes
propuestasSHAcorrectos. Reply msg_a0c87dff2ba8 autoriza SOLO constantepin del
harnessTEMP al hash real A6EF41B560EB682F771B45C9A63D3CA2AE3AB0B6369167CD51D8F88CDDF90048,
sin normalizar/tolerar diferencias o editarSQL. Preservar fallo previo0conexion;
se permite UNprobe aun no consumido, sin nuevo retry si falla. R3 sigue EN_CURSO,
sin compilacionSP/matriz/instalacion ni aceptar la entrega antes de resultado.

## D-87.J: harness TLS P2 aceptado y gate JDBC real, 2026-11-10

P2 msg_777a4a497b0f succeeded EN_REVISION,0rutasrepo. Supervisor revisa completos
Java,launcher y suites, contrasta675fuentes/pins y32artefactos; recompila8clases
conSHAidentico,53checksJavaoffline y10gruposPython PASS. ProbeJobnativo REAL
inspect-publicPASS y timeout1.016s PROCESS_TIMEOUT sinsecreto/conexion/store.
Solo preparacion, no validacionhandshakeJDBC. Fuentes congeladas p2-review.

El intento auxiliar supervisor de recapturar baseline tras restartTLS fallo por
sintaxisPython antes de SQL. Baseline vigente disponible es E2final previo al
restart, no se afirma igualdad posterior aun. Se verificara despues sin trafico
concurrente; no se requiere repetir probe previo. Se autoriza UN execute-once
del launcher926CCF2E...419FDDF conmanifest572C2F5A...D6B010. Runtimecredential
solo helperpin/Memory/stdin,3conexionesmax y1healthSP,2storesPUBLICOS exclusivos
sin cacerts/Rootglobal; ledgerCreateNew antes de secretos/procesos. No Apply,
reissue/restart/compensacion o retry. Contrato SQL-01-A69-QA-E1.md. BindingP1
historialfalse no se edita; aceptacion final de cadena y negativos aun pendiente.

QA.E1 task_741dbe3719c7/ctx_7829652bd835 recibo follow_up ready; aclaracion sobre
baseline enviada al mismo Dispatch, sin cambiar fuentes/pins o repetir conexiones.

## D-87.I: herramienta TLS revisada y binding real, 2026-11-10

A69P1 msg_426d6b431880/task_967fa9dfa0c7/ctx_a8da76cc5193 succeeded. Supervisor
congela2fuentes/informe, contrasta672fuentes y11artefactos, revisa funciones y suite,
ejecuta15tests independientes25.459s PASS con efectosOSmock. Integra solo script
4663F01F...0E4F9C8F y suite0ED1DC3B...ADEE79A,PlanreadonlyPASS. Fuente/helperpins
comprobados y sin colisiones/reserva/evidencia previa. No otros cambios producto.

Con permiso usuario D-87.H se aplica UNA vez con wrapper pinneado y elevacion
Windows aceptada. Operacion a69-20261110-review001: exit0,bound,ForceEncryption1,
reinicioQA y Running posterior. Huella protegida a04d8236...ae8ca2af igual antes/
despues. CA/leaf soloLocalMachine/My, claves noexportables, ACERead servicioQA
en leaf,exportCERpublicos. Rootstores LocalMachine/CurrentUser0coincidencias
de ambos certificados. Diario global durable finalcompleted/bound retenido.
Supervisor compara resultado/CERhashthumbprints/diario; cadenaJDBC sigueFALSE.

CAthumb00B92464F45C8962A249DF92D6A3019F8E377A2F,leafD398CD5FC7AC5F4F8892FF9ABE69103B1CC0D86A.
Evidencia local tmp/tls-a69-20261110-review001 y tmp/a69-20261110/application.
No otra Apply/reissue/restart; no confianzaOSglobal, credenciales o servicios ajenos.
Siguiente P2 prepara harnessJDBC/truststoreexclusivo y negativos CA/hostname solo
offline para revision, sin DPAPI/SQL ahora. Contrato SQL-01-A69-P2.md. V13 no
instalada, E2failed0/40 y correcciondboWindows separada siguen pendientes.

P2 delegada task_e86914ae1c26/ctx_d8511b025406, recibo follow_up ready en el
mismo programador. Supervisor mantiene QA sin actividad concurrente.

## D-87.H: E2 devuelta y nuevo permiso TLS local, 2026-11-10

Usuario responde "ya" tras explicacion de reintentoTLS/UAC; supervisor explicita
interpretacion como permiso TLSLOCALQA. Restriccion anterior de no reintentarTLS
se sustituye por esta autorizacion acotada; Windows aun debe aceptar elevacion
al aplicar. No produccion ni confianza global OS ni efectos en otros proyectos.

E2 worker_done failed msg_5ed2e2138e6a, task_091da7344237/ctx_622d6efdec77. Un
intento0/40, primerpositive_adm Msg51000 Line17 en V13, errorframe invalido porque
la guarda impidio ejecutar la fase. Supervisor contrasta9artefactosSHA,3baselines
identicos desde conexiones nuevas y valores0installed/562ACL. Huellas negocio,
catalogo,principales yACL exactas al baseline readonly propio previo. Se conserva
fallo y no se repite matriz. Diagnostico supervisor metadata-only: dbo principal1
es WINDOWS_USER(typeU), schemaOwner1,133SP. Propuesta V13 exigia typeS aunque
contrato solo exige dbo propietario esperado; correccion R3 SQL aun no asignada.

Primero A69.P1 actualiza herramientaTLS para estadoactual y pruebas offline,
ownership scripts/configure-isolated-sqlserver-tls.ps1 y suite nueva. Script6nov
tiene baseline/ruta fija historica: no ejecutar Apply tal cual. Plan/Apply deben
ser cerrados, fingerprint explicito, evidencia nueva/diario/guardas previas y
ninguna mutacion en worker; supervisor revisara antes de aplicar. ReinicioQA no
solapa pruebasSQL porque E2settledfailed. Contrato SQL-01-A69-P1.md. Cuenta/Run
sin cambios; ningun reintentoSQL o accionTLS se ha ejecutado por este permiso aun.

A69 parentTask task_7e312870e8d4 pasa ready por nueva autorizacion; preparacion
hija task_967fa9dfa0c7/ctx_a8da76cc5193 ready/keptOpen en terminal retenida.
No se cambia status de E2failed ni se marca cadenaTLS como validada.

## D-87.G: QA arrancada, baseline R2 real PASS y gate E2, 2026-11-10

Usuario reitera terminar pendientes y comunica Docker levantado. Inspeccion
readonly confirma ComposeHealth heredado MySQL, no destinoSQLServer. No tocar
otros proyectos/contenedores. Reintento de arranque exclusivo QA por nuevo encargo:
wrapper identico revisado cambia SOLO outputdir environment-attempt2, Windows
acepta elevacion y finaliza exit0/os_verified; no TLS/binding/config cambios.
HEALTHPROJECTQA RunningManual PID19056 observado, loopback14335/DAC61409, huella
protegida a04d8236...ae8ca2af identica antes/despues. No otros servicios modificados.

Supervisor ejecuta probe readonly COMMON+baseline con fuenteR2 congelada:raw0,
stderr0, installed0/562ACL/history0/modeOPEN y fingerprints de tablas/modulos/
columnas/principales/ACL obtenidos. Confirma que la guarda corregida acepta el
entorno real, no compila ni instala V13. Evidencia supervisor-baseline.json en
environment-attempt2. Se autoriza E2 PRE una vez,40fases rollback-only desde
snapshot r2-review, sin POST ni COMMIT. Contrato PAC-01-B1-QA-E2.md, misma pareja
de cuentas y mismo Run, no nuevo entorno DB ni setup/reapply.

E2 delegada por follow_up al retenido: task_091da7344237 /
ctx_622d6efdec77, recibo ready. Supervisor no genera trafico SQL/API concurrente.

## D-87.F: R2 aceptada offline y arranque QA preparado, 2026-11-10

Entrega msg_65cb13a6eb51 task_4c1004abeb3d/ctx_9c62d76c4893 succeeded EN_REVISION.
Supervisor congela fuentes/reporte, revisa diff COMMON/PRE/POST, contrasta672SHA
y15artefactos y verifica cuatro puntos de captura frescos. Runner y V13 intactos;
SQL de prueba nuevo8BCAF401111C311297B4E75331DE3E1BC48716029D87D5E5667E2CAAB94B3A61.
125lotes interceptados/11mutaciones son OFFLINE, sin conexiones de motor; R2
VALIDADA OFFLINE, no aceptacion de V13 ni negocio. Historial de dos errores del
harness/reporte worker conservado, no omitido. Evidencia local r2-review.

Plan OS sin elevacion falla INSPECTION_ACCESS_DENIED sin mutacion. Helper QA
conserva SHA3FBC605A...A2BD831. Wrapper Start-only comparado con version9nov:
solo cambia directorio de evidencia, prefijo y huella protegida actual
a04d8236d807b3527dce32d8c8168e2e691902c89c0dd3eb79dda933ae8ca2af. Observacion
actual MSSQLSERVER Running/Auto PID21208,SQLBrowser Stopped/Disabled; huella incluye
estado/PID, no se exige la observacion9nov tras recuperacion externa. Se exige
igualdad actual antes/despues. Wrapper hash B47D97713938ECBD0D6DCFD74FB9BF6CD64AEC2711495D00CDFD8056AC023C60,
exige plan EXACTO una accionStart con QAStopped o aborta sin configurar. No SQL,
TLS/binding/restart ni servicio ajeno. Invocado UNA vez mediante RunAs Windows;
no se asume aceptacion ni arranque hasta artefacto final/os_verified.

Resultado de esa invocacion: launch_failed/System.InvalidOperationException,
sin nativeError disponible en recibo; no se atribuye cancelacion ni causa concreta.
Wrapper no llego a entered, servicio sigueStopped. No retry automatico; el bloqueo
de motor ahora requiere completar arranque local con permisos Windows. No hubo
accionTLS ni ejecucion de SQL, y V13 sigue sin instalarse.

## D-87.E: continuidad tras recuperacion de Orca, 2026-11-10

Usuario reitera continuar pendientes. Mismo Run run_624b9269b491 revinculado;
raiz/rama/worktrees y fuentes propuestas conservados, HEAD4d461e7. Orca recupero
ctx_8d16509fd38f como abandoned/terminal_missing/outcome failed; Task E1 figuraba
ready. Supervisor la asienta failed con informe real0/40 y fallo previo, sin
inventar worker_done ni repetir matriz o cambiar estado de tareas ajenas.

Terminal antiguo stale, se redescubre el reemplazo retenido sin cerrar ventanas:
term_7286bcc6-6224-4d5f-a389-b06a09939ca3, /status recuperapiura@gmail.com,
session01a1c5c7-d534-7d01-ac3a-c18bf31075ec, mismo worktree; --no-daemon confirmado.
Identidades almacenadas de ambos roles verificadas mediante IdentityOnly, sin
cuentas globales. Cuota5h100% y semanal2% observada: no garantia futura. Terminal
coordinador actual term_f04e8b91-4227-4638-a1cf-cce7a8f01802; conversaciones previas
conservadas, sin enviarles tareas ni cerrar terminales.

HEALTHPROJECTQA Stopped/Manual. R2 se limita ahora a codigo/regresiones offline
del verificador; no probeSQL ni servicios/UAC/TLS. Fuentes worker V13 y test SQL
conservan SHA aprobados. Se mantiene arquitectura EXECUTE/SP y gate independiente
de motor posterior. Contrato PAC-01-B1-R2.md actualizado; no activar producto parcial.

R2 iniciada en terminal retenida verificada: task_4c1004abeb3d /
ctx_9c62d76c4893, mismo Run, recibo ready/keptOpen. Implementacion delegada;
aceptacion independiente pendiente. Supervisor mantiene ownership de documentos.

## D-87.D: E1 falla guarda inicial y cierre bloqueado por cuota, 2026-11-09

msg_51ddce127576/msg_stop_fdf88eefd7058a56aaa36d5e: UNICO intento E1 falla
BASELINE_FAILED antes de fases.0/40,sqlcmd16,Msg59999 Line17COMMON; sin instalacion,
fixtures,POST o fingerprint valido. Informe/harness/ledger preservados en
tmp/pac-01-b1-20261109/engine-review. Programador agota cuota antes de worker_done;
Orca Dispatch sigue abierto, no se simula cierre ni se despacha dependiente.

Supervisor diagnostica con dos conexiones de metadatos/session solamente. V13
ausente,133SP/562ACL,0principalesB1. Estado standalone externo0/0, predicado
combinado de estado/permisos rechaza y control separado acepta. Recurre bugA62;
COMMON debe capturar estado fuera de expresiones metadata, conservando permisos.
Diagnostico anterior con count2/state1 inline no prueba TX externa. No hubo retry
de matriz ni cambios de producto/datos persistentes; fingerprint negocio completo
no obtenido, no se inventa igualdad. R2 preparado PAC-01-B1-R2.md, sin despachar
hasta cierre del intento failed. Preservar cuentas/sesion y bloqueoUAC/TLS.

## D-87.C: R1 aceptada para transporte y gate PRE, 2026-11-09

R1 recibida msg_d5d25026633d; el cierre formal requirio guia de recuperacion y
msg_2754383ea860, sin reset/retry/cambio de terminal. Supervisor congela fuentes
e informe, verifica delta exclusivo del SQL de prueba, V13 inmutable y672SHA.
Diff limitado a LPC, -y0 sin-h, alias y parser estricto; argv/input real con mock,
frame Unicode largo y5negativos independientes pasan. Hash del probe readonly
unico y payload8000caracteres contrastados; no repetir conexion para validar R1.
Primer harness supervisor fallo hash por literal Unicode recodificado en stdin
PowerShell; corregido con escapes ASCII, historial preservado y sin probe repetido.

R1 VALIDADA TRANSPORTE; no prueba motor/negocio ni instalaV13. Se autoriza E1
PRE_APLICACION una vez sobre snapshot r1-review, mismas fuentes SHA,40fases
rollback-only con fingerprints antes/despues y runtime impersonado restringido.
QA exclusiva sin trafico API concurrente; parar al primer fallo, sin corregir ni
reintentar. Contrato PAC-01-B1-QA-E1.md. POST/autocommit espera instalacion posterior;
no COMMIT ni aplicacion persistente en este gate, UAC/TLS sigue bloqueada.

E1 delegada al mismo programador, task_5574317f354b / ctx_8d16509fd38f,
Run run_624b9269b491 existente; recibo follow_up state ready.

## D-87.B: revision de B1 devuelta por transporte, 2026-11-09

Entrega task_c53c79f7a74c/ctx_a5d34612a3a6 recibida EN_REVISION. Supervisor
congela2fuentes y reporte, contrasta670fuentes previas sin cambios y V1..V12
inmutables. V13 cumple lectura estatica inicial, no constituye aceptacion de motor.
Controlador combina -h/-y0 incompatibles (sqlcmd exit1 antes de conectar).
Probe readonly posterior: TCP Windows Integrated fallaSSPI; LPC local responde
instancia/base/CONTROL correctos. Sin aplicarV13 ni ejecutar matriz/fixtures.
R1 limita ownership al SQL de prueba, fija LPC administrativo, preserva V13 SHA
CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060 y exige
regresion del argv real. Autoriza solo un probe readonly metadatos/JSON sintetico
largo, no fases PRE/POST ni mutaciones. Contrato PAC-01-B1-R1.md. JDBC runtime,
cuentas, servicios y bloqueoUAC/TLS conservados. No se integra producto aun.

R1 delegada por Orca al mismo programador verificado, task_c4c2ade2df22 /
ctx_2cfd21810392, Run existente run_624b9269b491; recibo follow_up state ready.

## D-87: siguiente lectura administrativa de vinculos, 2026-11-09

Entrega PAC-01.A revisada publicada4d461e7094563494aa9098362683cadf0f6fea6b en
origin/health/production-wave0,40rutas explicitas de codigo/docs/evidencia sintetica;
remoto confirmado en el mismoSHA, sin main/despliegue/secretos/DPAPI/tmp/logs.
PAC-01.B1 task_c53c79f7a74c prepara V13 y prueba SQL, SOLO2rutas nuevas del worker,
sin SQL/API/servicios/credenciales operativos en ese Dispatch. Contrato PAC-01-B1.md.

Nueva entrada propuesta usp_patient_links_list(patient_id,limit,offset), una
proyeccion minima de vinculos existentes con user_name, sin email/credenciales/
contenido clinico o directorio global. Tenant por contexto, scopeREQUEST/TX externa,
ADM/REC actuales sin perfiles plataforma/portal (mixtoADM+PAC tambien denegado),
paciente propio y auditoriaPATIENT_LINKS_READ. Activos/inactivos historicos visibles;
active se refiere al vinculo y no promete acceso efectivo a portal. Lectura
administrativa permitida sin guarda de escritura/contratoPORTAL vigente para
conservar consulta; escritura existente mantiene sus restricciones. No nueva
resolucion de identidades, vinculacion, consentimientos ni habilitacion portal.

V13 futura agrega unSP y ACL exactaGRANTruntime/DENYbootstrap (+2), sin tablas,
columnas,indices,triggers o migraciones previas editadas. Revision de motor antes
de aplicar y adaptador/API/UI por paquetes siguientes. Procedimientos propuestos
no se consideran instalados ni backend parcialmente activado. Los25fixtures A y
todo trabajo historico se conservan; no reejecutar setup por conteos postrafico.

D-87.A: pregunta msg_21e8d28abfea sobre imposibilidad de autocommit mientras el SP
nuevo exista solo dentro de la transaccionDDL rollback-only. Se acuerdan dos fases
en el MISMO archivo: PRE_APLICACION revertida y AUTOCOMMIT_POST_APLICACION con SP
previamente instalado tras revision independiente. Segunda fase conexionnueva,
IMPLICIT_TRANSACTIONS OFF/@@TRANCOUNT0, runtime restringido y51000 antes de
lectura/auditoria; sin instalar/COMMIT/fixtures para facilitarla. Sin SP instalado
queda PENDIENTE_POR_PRERREQUISITO, noPASS. Este Dispatch sigue sin ejecucion SQL,
sin ampliar ownership ni autorizar instalacion. Resultados se documentan separados.

## D-86: directorio/ficha de pacientes aceptados en QA real, 2026-11-09

PAC-01.A queda VALIDADA LOCAL con SQL Server/HTTP/UI real. E1 misma task_c0871e7d4bb8,
ctx_0aba1f82bd60 succeeded: readonly10PASS/3NA solo paginacion y fase mutante26PASS,
25fixtures nuevas (24humanas/1animal), sin reusos ni reanudaciones.26incluye12
capturas y6logins, no se presenta como26escenarios de negocio distintos. Contrato
aceptado: alta/consulta/busqueda/paginacion/edicion revisionada, persistencia tras
recarga y nueva sesion, conflictos sin sobrescritura, contacto opaco/alergias
conservados, separacion de tenants/dominios y rechazo de cookie en otro host.

Supervisor contrasta3reportes/SHA,654fuentes sin cambios,12capturas reales1440/390
inspeccionadas (tema blanco). Verificacion HTTP independiente con3sesiones nuevas:
12controlesPASS,25IDs/contenidos/revisiones finales exactos,21lookahead/offset20,
4negativos404 y host401; revoca sus3sesiones. Cero escrituras de negocio propias;
las trazas/sesiones/auditorias normales de QA se preservan. Huella protegida sigue
79708541...91eb02. Evidencia PACIENTES_QA_REAL_20261109.json y12PNG sinteticos reales.

No repite grants/JDBC, reinicio backend ni cadena TLS; A69 sigue bloqueada y QA
usa trustServerCertificate=true. PAC-01 completo sigue PARCIAL: vinculos y
responsables pendientes, sin aceptar portal/historia/criterios clinicos/productivos.
Siguiente B1 prepara lectura de vinculos por un SP nuevo y pruebas SQL propuestas;
no modifica las migraciones aplicadas ni instala nada hasta revision independiente.

## D-85: herramientas aceptadas y ejecucion QA aislada, 2026-11-09

Runner real/tests de PAC-01.A.QA aceptados tras lectura independiente, baseline501
sin cambios,8SHA A/R1 intactos y12tests integradosPASS raw0. Sintaxis/check/88tests
del worker conservan autoria. Dos fuentes nuevas integradas, sin editar producto.
Evidencia PACIENTES_QA_PREPARACION_20261109.json. Herramienta preparada no equivale
a browser/negocio real ejecutado; se encarga ahora E1 segun contrato especifico.

La elevacion Windows fue aceptada EXCLUSIVAMENTE para Start-only deHEALTHPROJECTQA:
wrapper anterior conservado y copia nueva con pin79708541...91eb02 y directorio
de evidencia actual. Plan exactoStart1, OS/listeners loopback y guardas PASS,
instancia compartida protegida con fingerprint antes/despues identico. Ningun
replay de setup, bootstrap, migracion, cuenta o credencial. Runtime real separado
solo hp_qa_runtime_20261105, jobsfalse, readinessUP; proxy18300 y3HostContext QA
reales contrastados. Manifest de usuarios sinteticos SOLO DPAPI CurrentUser,
wrapper aprobado lo entrega por stdin al runner con SHA pinado. No secretos en
argv/env/config plana/logs/Orca. Se preservaron todos los artefactos historicos.

E1 autoriza dos invocaciones secuenciales: readonly primero, escrituras sinteticas
del runpacqa-20261109-a1 SOLO si la primera pasa. Fixtures deterministas por run,
reconciliacion sin duplicados, detener ante fallo/colision/incertidumbre, sin retry,
cleanup o cambio de runId. Ownership de fuentesNULO; solo reportes/capturas propias.
Supervisor no realiza negocio en paralelo. TLS A69 conserva su bloqueo especifico:
aceptarStartQA no autoriza certificados/binding/ForceEncryption ni valida cadena.
E1 delegada task_c0871e7d4bb8/ctx_e57613f2dc29, ready al mismo terminal retenido;
ningun otro escritor del estado QA. Esperar aviso y revisar resultados independientes.

## D-84: aceptar pacientes offline y preparar QA real, 2026-11-09

PAC-01.A.R1 aceptada en su alcance de frontend/contratos tras revision independiente.
El defecto R-PAC-CREATE409 queda corregido: borrador recuperable, nueva revision/
confirmacion manual, sin retry automatico; PUT409 y altas inciertas siguen bloqueadas.
Ocho archivos integrados localmente por SHA exacto a health/production-wave0,
sin copiar otros cambios historicos del worker ni hacer commit/push.76 pruebas,
build85,28 recorridos sinteticos y demo13/0API/0errores informados por worker;
supervisor confirma ownership, delta3R1/5SHAintactos, inspeccion visual,7 controles
independientes y build85/TypeScript mas7controles sobre exportacion integrada.
Evidencia PACIENTES_CONTRATO_20261109.json. No constituye QA real SQL/HTTP/UI.

Siguiente task_5a7358409b8e prepara SOLO harness real/guardas/tests, dos rutas nuevas
segun PAC-01-A-QA.md. Worker no arranca entorno ni descifra credenciales. Su tarea
no cambia producto ni declara realizadas las pruebas de persistencia. Ejecucion
real se encargara despues de revisar herramienta y preparar entorno supervisado.
Solo datos sinteticos .example.test y SP runtime existentes; sin setup ni replay.

QA observada Stopped/Manual; Plan no elevado devuelve INSPECTION_ACCESS_DENIED,
sin intento de mutacion. Fingerprint protegido actual79708541...91eb02 igual antes/
despues de esa lectura. Difiere del observado6nov6217e698...175e3d: no inferir causa
ni reutilizar guardas antiguas como si fueran baseline actual. Preparacion exige
inspeccion privilegiada revisable y proteccion exacta de la instancia compartida.
TLS A69 sigue con su bloqueo especifico, sin nuevo intento de UAC/certificados.
Dispatch QA ctx_1c94305dd25c ready al mismo terminal retenido, keep-open. No
encargos concurrentes ni ampliacion de ownership del producto; esperar aviso Orca.

## D-83: continuidad y primer paquete de pacientes, 2026-11-09

El usuario confirma retomar pendientes y delegar programacion al agente asignado;
aclara que el traspaso de cuentas no pausa ese objetivo. Supervisor nuevo asume
run_624b9269b491 desde term_6b053e36-a960-4dd8-a63d-45e6c3b6c24a. Commit de
traspaso41f7600 comprobado. Ambas identidades efectivas verificadas en recibos
CUENTAS_ORCA_20261109 y nueva lectura del /status del programador recuperapiura.
Se preservan sus87 rutas locales historicas y la conversacion anterior del usuario.

PAC-01.A task_31e1eebbbecf depende de A68 y conecta directorio/ficha administrativa
al shell live con contratos existentes, sin cambios backend/SQL. Ownership de ocho
rutas frontend, diseno, permisos, paginacion sin total, revision/conflicto y
tratamiento de altas ambiguas en PAC-01-A.md. Lectura ADM/REC/PRO/ASI/AUD;
escritura ADM/REC/PRO sujeta a servidor. No habilita vinculos, historia ni perfiles
clinicos. Backend actual se consulta desde supervisor; no copiar masivamente el
worktree antiguo. Frontend compartido asignado fue comparado igual normalizando
newlines. El informe worker queda EN_REVISION hasta revision independiente.

SQL QA observado Stopped/Manual hoy: paquete de implementacion y QA offline,
recorrido real posterior secuencial con entorno supervisado. No reejecutar setup,
descifrar store operativo, arrancar servicios ni mutar DB en este Dispatch. A69
mantiene bloqueo UAC/TLS; ni este encargo ni cambio de cuentas lo levantan.
Resultados A68 del6nov conservan fecha y alcance, sin repetirlos ni atribuirlos hoy.

Dispatch ctx_265e4fe4a23b iniciado al terminal verificado del programador con
keep-open; Orca worker-list confirma ready/in_progress/live. No se duplico envio.
Baseline previo tmp/pac-01-a-20261109/worker-baseline.json conserva SHA de183
archivos individuales de las87 entradas historicas. Coordinador vinculado con
consumer_generation7, buzon vacio al asumir. Proximo paso al aviso Orca: procesar
preguntas/entrega y revisar delta, pruebas y evidencia antes de integrar.

## D-82: cuentas invertidas por solicitud del usuario, 2026-11-09

Arquitecto/coordinador mendozadeafabisa@gmail.com en checkout supervisor;
programador recuperapiura@gmail.com en worktree separado. Sustituye la asignacion
de cuentas anterior, sin modificar el reparto de responsabilidades ni alcances.
Ambos/status efectivos verificados en sesiones nuevas e independientes --no-daemon:
arquitecto91% semanal, programador15% al observarlas. No seleccion global, login,
logout ni copia de credenciales. Las conversaciones anteriores se preservan.

AGENTS.md y launcher reflejan la asignacion nueva; el launcher rechaza los dos
pares rol/correo anteriores. Pruebas IdentityOnly positivas de ambos perfiles y
/status independientes. La carpeta/titulo del terminal no acredita identidad.
El programador sigue sin ser supervisor ni escritor del tablero. La comprobacion
posterior a reiniciar Orca sigue obligatoria; no se ha probado persistencia de
perfil a traves de reinicios. Evidencia CUENTAS_ORCA_20261109.json y traspaso
TRASPASO_ARQUITECTO_20261109.md. Sin cambios de producto/FactuEz/main.

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


D-68 precision de aceptacion: health raiz puede incluir nombres de grupos
liveness/readiness sin datos de componentes. Comprobador debe exigir status DOWN
y admitir solo groups opcional con esos dos nombres exactos sin duplicados;
rechazar todos los demas campos. Probes mantienen cuerpos exactos. El44/45
original sigue FAIL historico, no se reescribe como PASS. Correccion QA en
follow-up task_7744886e8fdf, producto sin cambios; aceptacion final pendiente.


D-68 resuelta para QA negativa: revision y repeticion independiente47/47 PASS.
Conservar44/45 original, sin modificar producto. No extender aprobacion a JDBC
exitoso, permisos, negocio o visual. Lectura actual confirma WindowsOnly1 y
TCP/NP deshabilitados; no hay autorizacion para cambiar la instancia compartida.


D-69 (2026-11-05): A61 implementa CLI Python de preflight QA de solo lectura,
con dos rutas exclusivas script/suite. Destino fijo local y base sintetica marcada;
SQLcmd administrativo Windows independiente del runtime para metadata unicamente.
Registro solo lectura de la instancia default; sin conectar TCP ni alterar nada.
Estados: exit2 BLOCKED para TCPoff/WindowsOnly incompatible/roles ausentes;
exit1 ERROR scope incorrecto o inspeccion fallida; exit0 READY_FOR_JDBC_TEST
solo precondiciones, nunca validacion JDBC. jdbc_positive_validated false siempre.
No usar adminWindows como runtime ni puerto administrativo, no habilitar/reiniciar
servicio ni autenticacion global. Herramienta prepara una decision revisable sobre
entorno independiente o cambio explicito; setup/migrador siguen pendientes.


D-69 aclaracion: UNA VEZ limita repeticiones sin causa; una correccion comprobada
de flags SQLcmd incompatibles justifica una ejecucion adicional sobre el mismo
destino y lecturas, autorizada por msg_4327632c0100. Conservar first-error y
no repetir suites exitosas sin cambios. No amplia permisos ni scope de datos.


D-69 resuelta: preflight aceptado con36/36 independientes y CLI real exit2
BLOCKED correctamente interpretado. Roles ausentes no son error de herramienta;
setup QA separado puede resolverlos sin modificar transporte/auth de instancia.
No usar esta aceptacion como prueba JDBC ni grants efectivos de un login real.


D-70 (2026-11-05): A62 prepara setup local de permisos V8 inmutable, sin transporte
ni autenticacion global. CLI plan/rehearse/apply, defaultplan sin escrituras;
programador solo ensaya con rollback y fingerprint en conexion nueva, nunca
apply. Dos rutas script/suite, ownership tmp/sql-01-a62-spec.md. FixedQA marcada,
37tablas/133SP/sinhistoria/rolesausentes,principaladminseparado. Postcondiciones
ACL562 EXACTA,owner/tipos/defs y ausencia de cambios ajenos; fuenteV8 SHAaprobado,
ningun usuario/login/dato nuevo. Supervisor revisara ensayo independiente antes
de aplicar permisos persistentes solo en QA autorizada. Esto puede resolver
los dos roles sin tocar SQL compartido a nivel servicio; TCP/auth continuan
bloqueando JDBCpositivo y requieren entorno compatible separado o decisionexplicita.


D-70 aclaracion: correccion comprobada de columna de metadata inexistente
justifica un plan adicional; solo si pasa permite el unico ensayo revertido
original. Preservar error inicial. Esta autorizacion no permite apply/COMMIT
persistente, ampliar scope ni repetir QA exitosa sin cambio.


D-70 correccion de transporte de metadata: prefijo de fragmento debe ser
nvarchar(max) para no truncar hex por promocion de tipos. Autorizar plan
adicional tras regresion que reproduzca chunk truncado con checksum original;
ensayo sigue limitado a uno tras planPASS. HistoricosERROR no se reinterpretan
comoPASS, sin permiso de apply/COMMIT persistente o ampliacion de SQL.


D-70 correccion supervisora de snapshots: colecciones SQL vacias deben emitirse
como[] explicitamente para roles/ACL y arrays aplicables; nunca sustituir NULL
en parser para ocultar falta de fingerprint. Capturar estado transaccional al
inicio del snapshot antes de SELECTmetadata; comparaciones0/0 fuera y1/1 dentro
permanecen estrictas. Diagnostico real readonly comprobo parser+baselinePASS
sin editar gates. Implementacion delegada msg_7fcef7d8a2cf; ensayo aun pendiente.


D-70 guardpreBEGIN debe usar count/state capturados fuera de la expresion
metadata, exigiendo0/0. No se debilitan checks de permisos, colisiones o destino,
ni estado explicito1/1 dentroTX. Ensayo anterior fallo antesBEGIN y nueva
conexion confirmo baseline identico; autorizada correccion y un rehearse adicional
conregresion, no apply/COMMIT persistente.


D-70 normalizacionACL: reutilizar COLLATE DATABASE_DEFAULT del verificadorA7
aprobado para comparar matriz esperada con metadatos sin error468. Ajuste solo
enexpresiones/tablaesperada temporal, no collationglobal ni V8. Mantener matriz
exacta562 y Pythoncaseexact postvalidation; no rebajar igualdad a conteo.
Ensayo adicional tras regresion autorizado; apply sigue reservado al supervisor.


D-70 comparacion de bootstrap: normalizar CR tambien en literal esperado
derivado del V8 inmutable, siguiendo sus prechecks aprobados. Conservar comparacion
binaria exacta del resto de caracteres; no sustituir por comparacion permisiva.
SQLcmd puede normalizar nuevaslineas del literal; regresion LF/CRLF y contenido
diferente requerida. Rehearse adicional autorizado, no apply/COMMIT persistente.


D-70 canonica de declaracion: prueba real comprobo CREATE en catalogo trasALTER.
Reconocer CREATE/ALTER exactos del SP aprobado y normalizar SOLO ese token aCREATE
para snapshot, guard y hashes esperados compartidos. Resto del cuerpo BIN2 exacto
con CR/trimexterno yaaprobados; no sustituir globalmente CREATE/ALTER en el cuerpo.
Headerinvalido oausente falla cerrado. FuenteV8/bodyALTER de ejecucion inmutables;
no debilitar matrizACL ni gateantesCOMMIT. Diagnostico con3rollbacksfreshPASS no
aprueba aun herramienta ni permisos persistentes/JDBCpositivo.


D-70 herramienta/ensayo resueltos:59/59,plan yrehearseindependientesPASS,ACL562
exacta contraA7 yrollback fullsnapshotverificado. Supervisor procede a apply
explicito SOLOQA marcada con principalsetupWindows separado; creacion2roles/ACL
y2ALTERV8aprobados, sin users/logins/datos/servicios/auth. Applyresultado se
registrara aparte; nunca equivale a JDBCpositivo o backendmigradocompleto.


D-70 aplicacion persistente confirmada por supervisor SOLOQA: dosroles/ACL562 y
2ALTERV8. CLIapply1 por lecturavacia posterior a COMMIT; no repetir mutacion ni
inferir rollback. Reconciliacion nuevaConexion verifico estado exacto instalado,
conservando errorautomatico original. Auth/transporte globales no modificados;
JDBC y principalruntime real siguen pendientes.


D-71 (2026-11-05): A63 QA SQL real de roles ya instalados. Usuarios WITHOUTLOGIN
transitorios en TX, impersonacion y probes de permisos/SP con codigos exactos;
ningun login/usuario/fixture persistente. Baseline instalado416017...D285B se
restaura en snapshot COMPLETO desde conexion nueva por fase. No ejecutar de nuevo
A62apply/rehearse ni A7instalador que exigen rolesausentes. Ownership solo tmp,
sin editar producto. Calidad valida autorizacion DB efectiva, no autenticacion
JDBC ni backendHTTP. Transporte/auth de instancia quedan bloqueados sin cambio.
Correcciones rutinarias del harness dentro scope pueden repetirse solo tras
cleanup comprobado, max2; fallo de producto/cleanup/scope exige escalacion.


D-72 (2026-11-05): A64 corrige herramientas SQLcmd ante timeout probado con
exit0. Budget query10s/process20s/login5s, stderr inesperado falla cerrado y
Timeout expired se clasifica SQLCMD_TIMEOUT aunque raw0. A62apply diferencia
not_attempted/mutation_outcome_unverified/commit_acknowledged/commit_verified; fallo
postcommit requiere reconciliacion y prohibe retry_mutation. No auto retries ni
compensacion, no nuevas mutaciones en QA. Cuatro rutas y pruebas segun
 tmp/sql-01-a64-spec.md. A63 original20PASS queda EN_REVISION hasta repeticion
independiente posterior; no es fallo demostrado de permisos ni autorizacion
para alterar SQL Server. TCP/auth y JDBCpositivo siguen pendientes.


D-71 resuelta para QAefectiva:20/20 independientes con A64revisado,fixturesTX
restaurados porfase,scopeWITHOUTLOGIN. No autentica loginSQL niJDBC real.
D-72 artefactos aprobados por revision y65tests/17checks/20fasesindependientes;
cierreTaskA64 pendiente porcuota, no inferirworker_done ni abrir siguienteTask.
Conservar4SHA revisados; sin cuentaalternativa ni compra de creditos.


D-73 (2026-11-05): propuesta ENTORNO_JDBC_QA.md para elegir destino SQL QA
con TCP/login compatible. Recomendar instancia nombrada exclusiva HEALTHPROJECTQA
loopback14335 y base nueva marcada, sin modificar instancia compartida. Inspeccion
actual confirma instaladorcacheado firmado y falta de elevacion, no medio completo
ni instalacion viable aun. Antes de provisionar se necesita eleccion de destino
y elevacion Windows; no modificar recursos existentes ni iniciar otroTask hasta
cierreA64. Esta decision es contrato propuesto, no instalacion ni JDBCvalidado.


D-74 (2026-11-05): usuario autorizo crear instancia HEALTHPROJECTQA y continuar.
A64cerrada enOrca (Taskcompleted), cuatroSHAfinales coinciden8d70803. Medio completo
SQL2022Developer firmado disponibleC:/SQL2022/Developer_ENU. Supervisor preparoINI
sinpassword, instancia nueva/datadirectorioD:/HealthProject-QA/SqlServer, engine
manual/TCP0/NP0/WindowsAuth inicial, operadorWindowsoriginal admin SOLOSQLnueva.
Lanzamiento SETUP viaRunAs puede esperar credencialesOSadmin; no se automatiza
ese dialogo. Configuracionposterior SOLOnuevo namespace cambiaLoginMode2 conSA
inhabilitada, WMIloopback14335 y servicio nuevo. A65 implementa helperPlan/Apply/
Verify ytests, sin workerprivilegiado. Supervisor revisa y aplica; sin modificar
MSSQLSERVER/SQLBrowser ni datos de otros proyectos, no nuevoJDBCvalidado aun.

D-74 revision A65: 86tests CPU no sustituyen arranque real. Apply elevado v2
configuro solo HEALTHPROJECTQA pero fallo antesStart porque PowerShell limpia
no carga System.ServiceProcess. Estado parcial conservado y reconciliado;
no retryApply ni restauracion automatica. Devolver cargaexplicita/testfresh al
programador antes de revisar un nuevo plan y arrancar SOLO servicioQA nuevo.
Fingerprint de instancia compartida/browser igual antes/despues. CompositeVerify
OS elevado + SQL operadororiginal se documenta con alcance exacto; no monolithic
Verify PASS si Parameters queda inaccesible al operadorSQL. JDBCpositivo sigue abierto.

D-75 (2026-11-05): A65 entrega aceptada para configuracion/servicio, OS real y
metadata LPC comprobados; Verify TCP Windows-E bloqueado por SSPI. No cambiar
seguridad global para remediarlo. Setup usara Windows original por LPC hacia
HEALTHPROJECTQA con guardas cerradas; runtime seguira TCP127.0.0.1:14335 con
login SQL separado aun por provisionar. A66 prepara base nueva exacta
health_project_sqlserver_qa_isolated_20261105/marcador aislado, CREATE sin colision
y migraciones V1..V9 inmutables en transaccion bajo principal de migracion DB
WITHOUT LOGIN separado del runtime. Ninguna copia de datos ni Flyway baseline.
Supervisor revisa/aplica; worker solo Plan readonly y pruebas. Logins/bootstrap/
JDBC/HTTP/UI pendientes en paquetes posteriores. Contrato tmp/sql-01-a66-spec.md.

D-75 ejecucion: DB aislada y migraciones persistidas verificadas por fresh lectura
completa, fingerprint CBD9C3CE...74E2AB. Toolcreate historica sigue ERROR por
framing NVARCHAR recortado; conservar diario y prohibir reapply/delete/recreate.
Correccion debe limitarse al transporte y regresion SQL readonly de respuestas
largas. Supervisor no integro aun A66. Nunca degradar checksum ni aceptar raw0
como confirmacion. Siguiente gate despues de corregir A66: principals SQL y
JDBC restringido; no acceso runtime mediante migrador/control/sesion Windows admin.

D-76 (2026-11-05): A67 preparara dos logins/usuarios SQL nuevos en instanciaQA:
hp_qa_runtime_20261105 SOLO hp_runtime_executor y hp_qa_bootstrap_20261105 SOLO
hp_bootstrap_executor. Default DB aislada, policyON/expirationOFF, sin roles de
servidor ni permisos adicionales salvo CONNECT necesario. Preservar migrador,
562ACL, esquema y datos; verificar delta exacto de dos usuarios/dos membresias.
Credenciales aleatorias distintas, almacen fijo tmp/sqlserver-isolated-credentials/
credentials.dpapi bajo supervisorroot, DPAPI CurrentUser/UI forbidden, sin plaintext
ni password en argv/env/SQLfile/log. Crear recursos solo supervisor tras review,
SQL sensible por stdin de proceso con entorno minimo; una TX y diario previo,
no retry/delete/compensacion ante resultados inciertos. Worker solo codigo/test,
Plan readonly y DPAPI ficticio, dos archivos segun tmp/sql-01-a67-spec.md.
A67 no incluye SAD/bootstrap ni prueba JDBC. Posterior QA JDBC usara TCPloopback
con credenciales en memoria, encrypttrue y alcance TLS explicitado; despues HTTP/UI.
A66 catalogo historico espera extraPrincipals0; postA67 se valida deltaexacto2
sin reescribir ni debilitar guards A66 y sin reejecutar sus migraciones.
Referencias: https://learn.microsoft.com/en-us/windows/win32/api/dpapi/nf-dpapi-cryptprotectdata
 y https://learn.microsoft.com/en-us/sql/t-sql/statements/create-login-transact-sql?view=sql-server-ver16.

D-77 (2026-11-05): cuota del programador hasta11nov11:35 deja TaskA67 abierta.
Preservar cuenta/sesion/worktree y errores historicos. La revision independiente
puede ejecutar los artefactos comprobados y QA propia; no sustituye worker_done.
Principales ya instalados/reconciliados; nunca repetir create ni borrar store.
SQLcmd con USE genera avisos por stderr pese a COMMIT correcto: correccion de
transporte pendiente dentro de dos rutas A67. Supervisor solicito autorizacion
expresa para aplicarla por el reparto de roles de AGENTS.md; aun sin respuesta.
No extrapolar a cambios de producto, cuentas globales, gasto ni nuevas mutaciones.
JDBC real17/17 y HTTP real7/7 validados con alcance de evidencia versionada;
trustServerCertificatetrue local QA no valida cadena TLS. El primer trafico anade
3 trazas sinteticas: conservarlas y no debilitar/reaplicar setup por conteos nuevos.

D-78 (2026-11-06): usuario solicita subir todo el trabajo y un informe de avances
pendientes. Se autoriza esta entrega de codigo/documentacion a la rama vigente;
A67 se conserva sin modificaciones como EN_REVISION con defecto SQLcmd conocido.
No se interpreta como aprobacion funcional ni como autorizacion para reejecutar
setup, cambiar cuentas o integrar en main. Se preservan los secretos locales.
El estado Orca observado hoy es dispatchabandoned/terminal_missing; no fabricamos
worker_done ni recuperamos sesiones en el alcance de una subida a GitHub.
Informe consolidado y evidencia de inventario/pruebas quedan versionados.

D-79 (2026-11-06): usuario autoriza ejecutar los pendientes A67, recuperar
programador, bootstrap/login, negocio, visual y cadena TLS con prioridad y calidad.
Se verificaron raiz/rama/worktrees y ausencia de cambios locales del supervisor.
Orca restauro un terminal idle con cuenta arquitecto; no se delego en el ni se
cerro su sesion. Nuevo terminal term_22e64ef3-7ea8-41fc-a042-98e914f4fbf4 usa launcher
programador con home asignado y --no-daemon; /status efectivo verifica
mendozadeafabisa@gmail.com, sesion01a1b189-b4a1-7143-8ac3-c2b08101b604, cuota semanal0
hasta11nov11:35. No enviar trabajo que no puede ejecutar ni comprar/cambiar cuenta.
El usuario solicita completar y la guia PLAN_EJECUCION_PRODUCCION seccion5 permite
los mismos paquetes secuenciales si no hay subagentes disponibles. Se aplica ese
procedimiento alternativo local: supervisor asume temporalmente A67 en checkout
principal, mantiene decisiones/revision/evidencia y no simula worker_done. Ownership
primero SOLO scripts/provision-isolated-sqlserver-logins.py y su suite; trabajador
recuperado idle sin asignacion activa. No cambios simultaneos en su worktree.
Arranque SQL SOLO QA mediante wrapper Start-only revisado, baseline de proteccion
actual6217e698...175e3d tras reboot externo; no reapply ni crear DB/logins/credenciales.
Trabajos siguientes siguen acotados y secuenciales; sin main/produccion/datos reales.


D-80 (2026-11-06): A68 prolonga el fallback secuencial D-79 por cuota0. Ownership
supervisor: migraciones SQL adicionales V10–V12, harnesses QA y script TLS local;
trabajador retenido idle, sin escrituras compartidas. Contratos HTTP, UUID canónico,
autorización SQL y separación runtime/bootstrap/migrador se mantienen. No editar
migraciones V1–V9 ya aplicadas ni usar sus herramientas de setup como sondas después
del tráfico. V10 conserva la unidad transaccional del llamador y prohíbe autocommit;
V11 corrige solo generación canónica y áreas sin dependencias, no remapea lotes
históricos arbitrarios; V12 distingue conflicto409 de dominio inválido400.

Fundamento transacciones: https://learn.microsoft.com/en-us/sql/t-sql/statements/set-implicit-transactions-transact-sql
y https://learn.microsoft.com/en-us/sql/connect/jdbc/understanding-transactions .
La aceptación se basa además en JDBC/HTTP reales y rollback/pool independientes.

D-81 (2026-11-06): TLS local requiere CA/leaf dedicados, sin instalar confianza
global OS, sin exportar claves privadas, ACL de lectura solo para servicio QA
sobre su nueva clave, binding/reinicio exclusivamente HEALTHPROJECTQA y truststore
exclusivo JVM con trustServerCertificate=false. Script preparado, aplicación no
ejecutada por cancelación UAC. Requiere nueva aceptación Windows; no equivale a
TLS productivo/publicCA/HTTPS publicado. Bases oficiales:
https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption
y https://learn.microsoft.com/en-us/sql/connect/jdbc/setting-the-connection-properties .
