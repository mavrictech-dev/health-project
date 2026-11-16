# DEMO.DOCKER.LAPTOP — contrato de implementación y aceptación

Petición vigente del usuario, 16nov2026: «sube a github nomas sin zip pq ejecutare
en mi laptop para la reunion de pruebas» y «con el docker y todo».

## Objetivo

Una instalación local reproducible desde clone limpio para reunión de pruebas:
frontend runtime, backend Java21 y SQL Server2022, con esquema completo V1–V19 y
fixtures sintéticos. Git + Docker Desktop Linux containers/Compose son los únicos
requisitos del host. No Node/Java/Python/SQL instalados manualmente en la laptop.
La demo estática ya aprobada puede conservarse como alternativa secundaria, pero
NO sustituye este recorrido conectado. No ZIP en la nueva entrega al usuario.

El supervisor escribe README, guion, tablero, decisiones, revisión y evidencias
versionadas. Programador implementa/prueba exclusivamente en su worktree retenido.
Raíz supervisor e44b9d7; worker8a6a6ae +P1/R1 locales aceptadas; fuentes de producto
normalizadas comparadas iguales antes del encargo. No reset/checkout/merge sobre
su trabajo. Leer AGENTS del root y frontend/AGENTS/Next instalada antes de editar.

Identidad efectiva comprobada por/status: arquitecto mendozadeafabisa/sesión
01a1da95-cbb4-7f21-bcf2-47d3ea8d9937, programmer recuperapiura/sesión
01a1d797-f52b-70e2-90bc-66a6b1a23e51; --no-daemon por proceso. Terminalprogrammer
term_ae4c0cb7-c0b2-41a0-8b93-659defa95453. El supervisor reconoció su propio handle
term_0823e94e-6aa6-46c6-a331-25e99606501a por/session exacto y lo usa como --from;
run-use del Run existente funciona. No cuenta global ni identidad ajena.

## Arquitectura y restricciones

1. Crear Compose NUEVO `compose.demo.yaml`, proyecto aislado
   `health-meeting-demo`, puerto gateway loopback18090 configurable. Backend/SQL
   sin puertos host; red/volumen propios, sin external networks/volumes o mounts
   a .env, DPAPI, bases, secretos o datos existentes. No main/Vercel/prod/Somee,
   AgendlyCitas, FactuEz ni otros proyectos. NO iniciar/parar/reconfigurar los
   contenedores health-project heredados o QA previos. Solo recursos propios del
   proyecto nuevo y labels de scope para comprobar antes de operar.
2. Frontend `npm ci` + build NORMAL dentro de imagen, modo runtime; servir estático
   y proxy /api por mismo origen/Host para login/subdominios/cookies/CSRF. No mocks
   en la verificación conectada ni apuntar a API simulada. Node24 y Java21 en
   build multietapa. Evitar copiar tmp/node_modules/.env/credenciales al contexto:
   COPY allowlist o dockerignore revisado. No cambiar lockfiles/dependencias.
3. SQL Server2022 Developer Linux para pruebas locales sintéticas, EULA según
   imagen oficial. Documentar requisito x86_64/recursos del motor sin fingir
   soporte nativo AppleSilicon. Bootstrap/migración ONE-SHOT en servicio separado,
   con principal de setup separado del runtime. Runtime EXECUTE-only sobre SP
   aprobados; negar tablas/DDL/privados/bootstrap. Todas las lecturas/escrituras
   de negocio, sesiones/audit/salud/fixtures pasan por SP parametrizados.
4. Aplicar fuentes canónicas V1–V19 exactas, en orden y con transacción externa,
   setup controlado y sin editar SQL/pines aplicados. GO/batches deben conservar
   literales/BOM y propiedades ANSI. Es instalación NUEVA: comprobar huella/scope,
   objetos/versiones y marker antes de modificar. Nunca reaplicar/destruir una
   base no vacía por fallo de transporte. Resultado ambiguo exige reconciliación
   readonly, sin reintentar mutación automáticamente. Arranques siguientes deben
   reconocer instalación completa y preservar datos; versión inesperada falla.
5. Sembrar tenant ficticio/RUC válido de formato, sucursal, profesional con
   asignación, paciente y acceso para presentación usando SP y cuentas de prueba
   separadas. Contraseñas de demo pueden ser ejemplos locales explícitos, jamás
   credenciales reales. No volcar secretos a logs/argv de procesos o commits.
   Variables reales solo en nuevo archivo `.env.demo` ignorado o secretos nuevos
   locales. JWT estable entre reinicios, ningún migrador/bootstrap en backend.
6. Perfil `local-demo` nuevo puede usar TLS SQL con confianza de certificado
   AUTOFIRMADO SOLO en red privada de este stack: etiquetar claramente la
   excepción local, sin cambiar ProductionProfileGuard/application-production.
   RuntimeModeGuard conserva SP/health/jobsfalse/migrationsfalse. Base-domain
   health.localhost y public-origin http://health.localhost:18090; navegador
   usa subdominio del tenant. No TLS productivo ni datos asistenciales reales.
7. Arranque desde raíz con comandos explícitos revisables:
   copiar template `.env.demo.example` -> `.env.demo`; ejecutar
   `docker compose --env-file .env.demo -f compose.demo.yaml up -d --build`.
   ps/logs/restart/stop/down de SOLO este proyecto; down sin-v para preservar.
   Evitar `docker system prune`, down-v, borrar volumes o cleanup masivo.
   No instalar dependencias en host. Si un paso requiere setup host adicional,
   preguntar con evidencia antes de ampliar requisitos.

## Ownership exclusivo del programador

Solo en C:/Users/maxmo/orca/workspaces/Health Project/health-programmer-hp8-review:

- compose.demo.yaml y .env.demo.example nuevos;
- docker/demo/** nuevos: Dockerfiles, nginx, scripts/helper de setup, fixtures,
  verificadores y guía técnica local;
- backend/src/main/resources/application-local-demo.yml nuevo;
- frontend/.dockerignore nuevo y .dockerignore raíz nuevo solo si es necesario;
- tmp/demo-docker-laptop-20261116/** para QA/informe/hashes/logs/capturas nuevos.

Puede compilar helper Java standalone de setup bajo docker/demo con las
dependencias existentes de la aplicación, sin nuevo main en backend/src que
rompa el empaquetado. Reutilizar SqlServerExecutor/BootstrapStore para contratos
cuando corresponda. No editar V1–V19 ni las fuentes/fixtures/versiones existentes.
No editar frontend/src, backend/src Java, README, guion, tablero/docs supervisor,
backend/Dockerfile, configuraciones productivas/QA o dependencias sin ask explícito.
No commit/push/merge ni archivos del root/otro worktree.

### Ampliación de ownership por fallo real Linux (msg_d3d2b51663d4)

Se autoriza además SOLO
backend/src/test/java/com/mavric/health/ProductionProfileTest.java: guardar y
restaurar el nivel original del logger root que SpringApplication altera por
logging.level.root=OFF. Mantener ConfigData/factory reales, los35casos y todos
los asserts. No cambiar clases productivas, MonitorService ni omitir tests,
forzar forks u ordenar suites para esconder el fallo. La restauración debe
cubrir tests dinámicos de TestFactory: no depender únicamente de BeforeEach/
AfterEach; usar restauración final de clase y/o finally por ejecutable dinámico.
Validar expresamente ProductionProfileTest antes de MonitorServiceSqlServerTest
en la MISMA JVM (elegir el orden por nombre COMPLETO de clase y acreditarlo en
el log; en estos paquetes corresponde alphabetical) y luego Maven completo
en Docker. Conservar build-attempt1.log y dejar documentado el defecto previo.

### QA de navegador Docker (msg_ea9558fd21b5)

Se autoriza navegador Chromium headless NUEVO dentro de un contenedor QA propio,
build/pull del runner necesario con versión fijada y dependencias SOLO dentro
de la imagen. Ownership adicional queda bajo docker/demo/qa/** y tmp asignado.
Única red health-meeting-demo_meeting y único destino el gateway del stack; sin
montar sockets Docker, perfiles Chrome, carpetas de usuario o credenciales ajenas.
Contenedor etiquetado/su nombre propio; salida a un directorio tmp nuevo y sin
puertos host publicados. No Node/Chrome/Python/Java de host como requisito.

Navegar con origen canónico http://reunion.health.localhost:18090 y dominio base
cuando corresponda; no cambiar productos/CSRF/cookies ni falsear respuestas para
adaptar al runner. Puede usar un forwarder TCP LOCAL dentro del runner desde
127.0.0.1:18090 hacia gateway:80: conserva Host/Origin/puerto, DNS .localhost y
todos los bytes reales. Ninguna API interceptada, mockeada o respondida por el QA.
Solo login/citas/cobros/lecturas reales sintéticas; sin audio físico/proveedor.
Capturas desktop/móvil y reporte sin contraseñas o tokens, con runId/ruta de
salida configurables para una repetición independiente sin pisar evidencia.
Si la conectividad falla, conservar diagnóstico; no relajar validación de origen.

## Ejecución y aceptación

Se autoriza build/pull y ejecución de SOLO el nuevo stack local sintético
`health-meeting-demo` después de comprobar nombres/puertos/volúmenes exclusivos
ausentes. Docker actualmente disponible. No ejecutar comandos mutantes generales
ni actuar sobre contenedores ajenos; antes/después inventario de Health Project
existente para acreditar preservación. No sondear/controlar FactuEz.

Primero validar Compose/buildcontext/setup offline y luego arranque REAL. Un
build o test de modelo no acredita stack funcional. Capturar comandos/exit y
errores reales sin secretos. Verificar:

- build frontend/runtime/backend y setup/SQL reales; ready/health porSP;
- acceso por navegador RUC+correo+password -> sucursal -> agenda/paciente;
- crear cita futura/revisión antes de guardar, cobro/archeo o consulta/paciente,
  lectura real persistida sin interceptar API; desktop/móvil sin errores;
- denegación efectiva SELECT/DDL al runtime y acceso viaSP;
- stop/start o restart SOLO backend propio; login/consulta/datos persisten con
  JWT/sesión apropiados. Segundo `up` no duplica esquema/fixtures ni pierde datos;
- sin datos/servicios existentes alterados, datos sintéticos y sin salida a correo;
- doc de acceso exacta (host/RUC/correo/password de prueba), puertos/diagnóstico,
  primer arranque/repetir/detener conservando volumen y limitaciones.

Maven/frontend completos ya aprobados no necesitan repetirse si no cambian
fuentes; el Dockerfile debe compilar/verificar lo pertinente. Si perfil/compilación
cambian, ejecutar suites pertinentes y declarar alcance. Reportar hash exacto de
fuentes nuevas y manifest de artefactos, no secretos. No declarePASS si cualquier
verificación requerida falla; informe parcial/fallido con causa y siguiente paso.
No ampliar producto para arreglar contratos: usar ask para ownership adicional.

Procesar todos los lotes y ack si deliveryId antes de siguiente check/worker_done.
Supervisor revisa diffs, vuelve a verificar integración y navegador de modo
independiente, elimina ZIP del checkout y publica solo entrega revisada en rama
health/production-wave0. Una entrega del trabajador no constituye aceptación.
