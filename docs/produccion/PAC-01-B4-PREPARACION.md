# PAC-01.B4.P1: entorno QA de backend con TLS estricto, preparacion offline

Arquitecto 2026-11-10. Mismo Run run_624b9269b491, programador recuperapiura,
terminal term_7286bcc6-6224-4d5f-a389-b06a09939ca3/sesion
01a1c5c7-d534-7d01-ac3a-c18bf31075ec/worktree health-programmer/--no-daemon.
Leer AGENTS.md absoluto supervisor, flujo/TAREAS y este contrato. Nuevos IDs
del preambulo; supervisor unico escritor docs/tablero y aprobacion.

B1 SQL y B2 API cerradas en sus alcances; B3 UI aceptada sintetica con review
141artefactos/683SHA/15capturas, supervisor94unit/build y8controles propios.
Falta QAreal. La instancia SQLQA YA esta running/ForceEncryption1, con CA/leaf
y A69 JDBC local aceptados; no repetir A69, emitir certificado, instalar trust
global ni reiniciar servicio. Antiguo HealthQaRuntime.java usa trustServerCerttrue
y classpath antiguo: NO ejecutarlo ni modificarlo. Preparar reemplazo verificable.

## Ownership y alcance de este Dispatch

NINGUNA fuente versionada para editar, ningun producto/docs/SQL/frontend/backend
del supervisor ni del worker. Crear solo artefactos NUEVOS con prefijo B4P1 bajo
TEMP y directorio TEMP/B4P1-prepared (no reutilizar/clobber salidas historicas):

- B4P1StrictRuntime.java y classes propias
- B4P1-environment.py
- B4P1-tests.py (y Java tests si aportan cobertura necesaria)
- B4P1-reviewed-pins.json, manifests/reportes/snapshots propios
- B4P1-prepared/app extraida del jar exacto y classpath generado

Fuentes B3 integradas legitimamente al supervisor:2cambios+4adiciones previos
a este nuevo baseline. Refrescar inventario reconociendo integracion, preservar
todo lo demas. No copiar checkout,reset/checkout/stash/deps/commit/push/main.
Si hace falta otra ruta o modificar producto, preguntar por Orca antes.

Esta fase es PREPARACION OFFLINE: escribir, compilar, probar con dobles y revisar
contratos; no arrancar HealthApplication/proxy/backend, no sockets SQL/HTTP,
no cargar DPAPI/store/autenticacion. Se permiten SOLO dos probes nativos SIN
credenciales/conexiones: una inspeccion publica con JVM y un timeout/cleanup
con child inocuo propio bajo WindowsJob. No repetir pruebas reales A69 ni B1.
--execute-readiness debe quedar implementado pero NO invocado en P1; review y
autorizacion de siguiente paquete E1 seran previas a cualquier uso real.

## Entradas inmutables y destino fijo

Canonical supervisor D:/Mavric/Health Project. JDK21
C:/Program Files/Eclipse Adoptium/jdk-21.0.5.11-hotspot/bin/{java,javac}.exe.
Jar supervisor backend/target/health-project-0.1.0.jar SHA256
85D8FEA06D8F572C86B6EA7473066036723F22E8DAF71C036EBB93027D55512F
(B2 compilado/revisado, Maven1007). No usar jar/classes antiguos ni otro checkout.
Extraer SOLO clases/recursos BOOT-INF/classes y libs BOOT-INF/lib con guarda
de rutas absolutas/traversal/reparse/colisiones y manifest SHA exacto; resto
del jar no ejecutable innecesario. No sobrescribir extracciones previas.
Driver incluido mssql-jdbc13.4.0.jre11 SHA256
E36F5237C1267983E5B88DC2169F6B9D7E50ECEEC6DC1CA31018E3877E14AF66.
Verificar presencia exacta de los4class de productoB2 desde jar y firma GETlinks,
sin recompilar app. CP de esa extraccion + launcher propio; import sin efectos.

Truststore publico EXISTENTE tmp/a69-20261110/client-qa/qa-public.p12 SHA256
7988CDDE0249F594CCA47039E04D90F7C3BA43689F3093EA010BE77E6685C037,
PKCS12 una trustedCertEntry, ninguna clave privada. Integridad PUBLICA:
A69P2-public-integrity-only (no es passwordSQL ni secreto). CA DER SHA
5239D56864F2DE648181D9EEA463C4D7EA1341A83ACD5263FBCD25BA020FF606;
leaf DER SHA F433FEAB52E37A78791A42931015A341825FB0AA1FF6F972B40DF5C5DE361B8D,
CERpublicos en tmp/tls-a69-20261110-review001; confirmar nombres desde esa carpeta.
Validar cadena/validez/CA-EKU/SAN IP127.0.0.1 con materialpublico antes de secreto,
sin nuevas conexiones ni stores. No usar cacerts/WindowsRoot/globaltrust.

Target unico runtime SQL127.0.0.1:14335, DB
health_project_sqlserver_qa_isolated_20261105, principal hp_qa_runtime_20261105.
Backend127.0.0.1:18080, proxy127.0.0.1:18300, public-origin
http://health.localhost:18300. Si puerto ocupado en futura ejecucion, FAIL antes
de credenciales, sin matar/probar otros listeners ni cambiar puertos.
SQLQA sigue13304 observado; no usar PIDhistorico como autoridad de proceso.

## Launcher Java y contexto futuro

Configurar por proceso antes de HealthApplication.main: perfil sqlserver-qa,
runtime server/port/database/user fijos, trust-server-certificate=false;
javax.net.ssl.trustStore=storepublicofijo, typePKCS12,passwordintegridadPUBLICO.
El datasource existente ya usa encrypttrue. Hostname del server127.0.0.1 coincide
con SAN IP; no override que desactive validacion, fallback a true u otraCA.
Jobs/Flyway/SQLinit/bootstrap deshabilitados,server.address127.0.0.1/port18080 y
origin18300 fijos. No credenciales bootstrap/migrador ni parametros arbitrarios.
Java modo inspect-public valida material y configuracion y emite JSON cerrado
sin entrar en app, datasource/conexiones o leer stdin secreto. Modo runtime
solo acepta frame stdin length-prefix estricto/EOF, guarda bounds/encoding y
longitud aprobados, limpia buffers; ninguna entrada desde argv/env/archivo.
Nunca imprime password,objetosconfig,rawexceptions o detalle driver.

Python default --plan y --inspect-public no importan/cargan loader DPAPI, SQL o
app. Exponer managed_environment() como contextmanager inert hasta entrada
autorizada futura. --execute-readiness futuro lo usa con deadline acotado:
validar pins/material/entorno/puertos, reservar ledger exclusivo, cargar UNICO
runtime password via helper aprobado, arrancar app y proxy revisado y esperar
readiness; al final/timeout/error detener y esperar SOLO sus hijos por Job.
Yield del contexto da un handle/url/report seguro para QA posterior que mantenga
el launcher vivo durante navegador, sin procesos detached al terminar. No
opciones de arbitrary command/path/env/runId ni reutilizar ledger como retry.

Helper aprobado scripts/provision-isolated-sqlserver-logins.py SHA256
4415F6DB8260B000F64023DA6D94E088FB49DE53FC55A9EF4140AA0329740EAD;
solo load_credentials().password_for(runtime) en futura ejecucion explicita.
No leer auth/credenciales globales,tokenfiles o store directamente, ni rotar/
recrear DPAPI/login. Nunca argv/env/log/archivo plano. No copiar secrets/store
a TEMP. Errores/output hijo acotados en memoria; guardar solo resumen seguro
validado o salida redactada tras comprobar secreto, nunca raw driver/startup
exception en archivo/chat. Evitar deadlock por pipe lleno, outputinfinito o
entrada parcial; invalidoutput termina hijos y reporta codigo cerrado.

Base reutilizable de transporte seguro: TEMP/A69P2-launcher.py SHA256
926CCF2E0BAF830CF2017E9F104EC88D366939909EADAE64D0AE6DE04419FDDF
WindowsJobRunner (suspended CreateProcess,handlelist restringida,Job antes de
resume/stdin,kill/waittimeout). Su run actual es sincronico; adaptar COPIA a
contextmanager propio con pruebas si hace falta, nunca editar/reinvocar A69.
No Popen libre que pueda ejecutar antes de containment ni kill por nombre/PID
ajeno; WindowsJob KILL_ON_CLOSE sin breakaway, verificar activos0 al cerrar.
Env minima por proceso, bloquear/remover JAVA_TOOL_OPTIONS,_JAVA_OPTIONS,
JDK_JAVA_OPTIONS,CLASSPATH,SPRING_*,HEALTH_*,SQLCMD* y overrides/debugdiagnosticos.

Proxy existente tmp/patients-real-env-20261109/preview-live.cjs SHA256
0FD50FD17A645212908430353065695C38721152FD64CF6CD8D15F998ECD138D,
root frontend/out actual supervisor. Puede reutilizarse EXACTO con pin y nodert
absoluto; no copiar/editar este archivo ni servir bundle demo. Dominio health.localhost
y subdominios sinteticosexistentes, Hostpreservado a backend ysin mocks. Node
proxy sin secretos y en Jobpropio/mismo Job del contexto, stdout acotada.

## Aceptacion offline y entrega

Probar configuracion efectiva strictfalse/encrypttrue, dataset/target/cp/pins,
default noexecute/noSQL/noDPAPI/noapp; Java inspectpublic0conexiones, parsingstdin
con dobles/sinSQL, errores/bytes/EOF/rechazos, envinyeccion, archivosreparse o
inputs cambiados, puerto ocupado, Jobantesstdin/resume y cleanup timeout/early
exit/outputlimit/contradicciones, redaccion/salida/ledger exclusivo/no retry.
No pruebas que se limiten a buscar strings del propio codigo. Inspeccion nativa
publica UNAvez y probe inocuo timeout UNAvez; capturar rawexit y activos0.
No scripts Winservice/SQL, UAC, Docker, certificados, trustglobal, fixtures,
credenciales/realHTTP o suites Java/Next/demo existentes.

Informe TEMP/B4P1-programmer-report.json: IDs, archivos/classes/manifest/hash y
baseline sin deltas, comandos/exits/conteos/probes, como se ejecutaria E1 tras
review, limites y fallos iniciales preservados. Verdad de P1 es PREPARED_OFFLINE;
no marcar backend/readiness/TLSruntime validados ni activar migracion completa.
Consultar/ack lotes Orca antes de worker_done; succeeded EN_REVISION. Mismo Run,
cuentas/sesion retenidas, sin globalchanges/gastos/datosreales/FactuEz/shutdown.
