# DEMO.DOCKER.LAPTOP — entrega del programador

Fecha: 2026-11-16. Task task_5ee0aa4919a6 / Dispatch ctx_fc37233ae5c6.
Resultado técnico del paquete: completado, con verificaciones finales exit0; requiere revisión independiente del supervisor antes de integrar/publicar. No acredita Somee ni producción.

## Bases y ownership

- Worktree único: C:/Users/maxmo/orca/workspaces/Health Project/health-programmer-hp8-review.
- HEAD sin cambios: 8a6a6aeab6c40a3ec114e0175289b75e7a3022e4, rama Maczz09/health-programmer-hp8-review, más P1/R1 locales previamente aceptadas.
- Base supervisor consultada: e44b9d7954a990ab8e14f85aa19f27ae1c2c5644. AGENTS, contrato completo, frontend/AGENTS y guía Next instalada leídos antes de implementar.
- 14 archivos entregados: 13 nuevos dentro del ownership y ProductionProfileTest.java, ampliación explícita autorizada por msg_50ce8d47d514 y contrato actualizado. Hash exacto y tamaño de cada archivo: source-manifest.json; diff completo informativo: delivery.patch; diff aislado del test: production-test.diff.
- Baseline de 821 archivos: 820 permanecen byte a byte; único existente cambiado, el test autorizado. Los ocho cambios P1, R1 productivo, SQL V1–V19, lockfiles y fuentes de producto restantes se preservaron. Evidencia: source-baseline.json, baseline-comparison.json, preservation-summary.json.
- Sin commit/push/merge/despliegue, escrituras al checkout supervisor, cuentas globales, host Node/Java/Python/SQL, instalación de BD ajena ni control de servicios existentes.

## Implementación

Compose nuevo, nombre explícito health-meeting-demo. SQL Server2022 Developer fijado por digest y volumen propio; setup Java separado de una sola ejecución; runtime Java21 no root, filesystem readonly, jobs/migraciones/bootstrap desactivados; frontend Node24 npm ci y build normal live dentro de Docker, servido por Nginx con /api al backend real.

Gateway publica únicamente 127.0.0.1:18090. Solo gateway conecta a frontdoor propia además de meeting interna; SQL/backend permanecen únicamente en meeting, sin puertos host. Todos los recursos propios llevan label com.mavric.health.scope=health-meeting-demo-v1. QA opcional usa esa misma red interna, ningún puerto host, socket Docker ni perfil del escritorio.

El helper verifica SHA256 de las 19 fuentes canónicas, orden, BOM inicial y splitter GO con estados de literales/comentarios; 277 batches. Instalación inicial nueva protegida por scope/marker y transacción externa. Verifica SQL major16, 43 tablas, 152 SP y 34 triggers; conserva huella de catálogo/permisos/roles y manifest. No modifica fuentes/pines ni registra una migración aplicada alternativa. Una instalación parcial/commit ambiguo falla conservando volumen; nunca reaplica automáticamente. Arranques posteriores COMPLETE comprueban huellas y no repiten fixtures.

SA solo reside en setup; bootstrap usa login propio; backend recibe exclusivamente hp_meeting_runtime. Usuarios, sesiones, tenant/RUC, dos sucursales, profesional PRO/REC asignado, paciente y auditoría se crean mediante SqlServerExecutor y SP parametrizados. No hay INSERT/SELECT de negocio directo para sembrar. Las consultas de catálogo/markers/DDL de instalación se limitan al principal setup. Las lecturas directas de negocio del negativo se deniegan y no devuelven datos.

Perfil local-demo confía en el certificado SQL autofirmado exclusivamente dentro de esta red sintética. ProductionProfileGuard y application-production no cambian. .env.demo local está ignorado y excluido del build; no se entrega. El template público .env.demo.example queda ignorado por la regla preexistente .env.*: el supervisor debe incluirlo explícitamente, sin cambiar .gitignore. compose-config.json fue redactado; artifact-secret-audit.json no detecta valores de entradas locales en logs/reportes.

## Requisito → evidencia

| Requisito | Evidencia y resultado |
| --- | --- |
| Git + Docker, sin runtimes host | Dockerfiles multietapa y qa/Dockerfile; build-attempt3 exit0. Se usaron PowerShell/Git/Docker y el navegador contenido; no Node/Java/Python/SQL host. |
| Frontend normal runtime | build-attempt1.log contiene npm ci, npm run check y next build normal con NEXT_PUBLIC_APP_MODE=live; capas reutilizadas en build-attempt3 exit0. /demo devuelve404 y el login no muestra acceso simulado. |
| Java21 / pruebas backend | build-attempt3.log: par ProductionProfileTest antes de MonitorServiceSqlServerTest, misma JVM forkCount1/reuseForkstrue, 43/0/0/0; después mvn verify 1162/0/0/0. Mantiene35 casos de producción. |
| Setup offline antes de SQL | build-attempt3.log: offline PASS,19 fuentes, 277 batches,sqlExecuted=false; javac helper exit0. |
| SQL 2022 completo y canónico | up-first exit0; setup-first.log INSTALLED,19 fuentes; canonical-sql-comparison.json: V1–V19 idénticos en bytes al supervisor. No instalación SQL fallida/parcial en este recorrido. |
| Runtime EXECUTE-only real | Setup verifica salud e identidad por SP, luego SELECT pacientes / CREATE TABLE / bootstrap / helper privado: cuatro denegaciones efectivas SQL 229/262. setup-first.log y setup-d-repeat.log. |
| Salud real por SP | Backend y SQL healthy; health-after-restart.json contiene únicamente status UP; configuración runtime conserva EXEC dbo.usp_health_ready. |
| RUC/correo/password/sucursal | Chromium141.0.7390.37 en Docker, Playwright1.56.1 fijado por digest; login real RUC 20000000001 + profesional@example.test, dos sucursales y selección de sede principal. Captura01 final. Cookies/CSRF/Origin reales en URL canónica http://reunion.health.localhost:18090. |
| Reserva futura con revisión | Corrida d: 2026-11-17 10:00 America/Lima, paciente DEMO-001; cero POST de reserva antes de revisión explícita; POST real posterior guarda id12a57050-fc44-4658-b941-19871d8b8f6c. Capturas03–05. |
| Cobro y arqueo persistidos | Corrida d: pago manual ficticio YAPE 9550 céntimos; baseline19100/2 recibos →28650/3 recibos. API/SP y UI coinciden, capturas06–07. Las tres citas/cobros acumulados provienen de QA b/c/d deliberadas, no de duplicación de fixtures. |
| CSRF real | POST con cookie real pero sin X-CSRF-Token devuelve403; registrado en result.json. No mutó sucursal. |
| Desktop/móvil | 11 capturas finales en browser/worker-20261116-d, desktop1600×1100 y viewport móvil390×844. Semana/día sin desbordamiento del documento. Móvil es emulación de viewport, no teléfono físico; sin audio físico probado. |
| Restart propio / JWT estable | backend-d-before-restart.json y backend-d-after-restart.json: mismo contenedor, StartedAt cambiado y healthy; backend-d-restart exit0. Misma sesión Chromium, sin nuevo login, recupera por ID la misma cita PAID/YAPE 9550 y paciente único. Captura10. |
| Segundo up sin reaplicar | up-d-repeat exit0; setup-d-repeat ALREADY_COMPLETE, fixturesRepeated=false y cuatro denegaciones. Misma sesión/cita/paciente siguen persistidos, captura11. c también pasó sobre volumen usado; d repitió con otro horario libre y baseline creciente. |
| QA repetible y evidencia protegida | RunId y output parametrizables, carpeta nueva obligatoria; negativo de carpeta existente esperadoexit1, hash previo intacto, sin conexión BD. qa-output-existing-negative.json. Harness final incorporado a imagen: final-qa-source-image.json. |
| Recursos anteriores conservados | Los siete contenedores Health Project iniciales conservan ID/imagen/status/StartedAt/RestartCount exactos: existing-health-before.txt = existing-health-after.txt. No se sondeó FactuEz. Labels/redes/puertos/volumen propios: scope-final.json, networks-final.txt, volume-final.txt. |

La corrida final d terminó exit0 y result.json PASS, pageErrors=[], serverErrors=[], expectedDowntime=[], mockedRequests=false. c también terminó exit0/PASS sobre los datos conservados. No se interceptaron APIs ni se simuló voz. Los tests frontend completos previos no se repitieron porque frontend/src y lockfiles no cambiaron; Docker sí ejecutó typecheck y build normal. No se presentó la primera alternativa estática como validación conectada.

## Comandos y códigos

Todos los archivos mencionados son relativos a tmp/demo-docker-laptop-20261116, salvo rutas fuente. Logs completos conservados; *.exit.txt registra códigos reales. Las advertencias de PowerShell NativeCommandError del progreso stderr de Compose no sustituyen el exitcode de Docker.

| Comando efectivo | Exit / evidencia |
| --- | --- |
| docker compose --env-file .env.demo -f compose.demo.yaml build --progress plain (intento1) | 1 / build-attempt1.log |
| Mismo build, intento2 | 1 / build-attempt2.log |
| docker compose --progress plain --env-file .env.demo -f compose.demo.yaml build (intento3) | 0 / build-attempt3.log |
| Dentro del build: mvn -B -ntp -Dtest=ProductionProfileTest,MonitorServiceSqlServerTest -Dsurefire.runOrder=alphabetical -DforkCount=1 -DreuseForks=true test; después mvn -B -ntp verify | 0 y0 / build-attempt3.log,43 y1162 pruebas |
| java ... DemoSetup --self-test /demo-data dentro del build | 0 / build-attempt3.log |
| docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml up -d --build | 0 / up-first.log |
| ... up -d --no-deps gateway (corrección frontdoor) | 0 / gateway-port-fix.log; HTTP host/acceso200 posterior |
| ... --profile qa build qa (imagen final) | 0 / qa-build-d.log |
| ... --profile qa run --rm --no-deps -e QA_RUN_ID=worker-20261116-a -e QA_WAIT_RESTART=true qa | 1 / qa-run-a.log |
| Mismo comando QA_RUN_ID=worker-20261116-b | 1 / qa-run-b.log |
| Mismo comando QA_RUN_ID=worker-20261116-c | 0 / qa-run-c.log |
| Mismo comando QA_RUN_ID=worker-20261116-d, fuentes finales | 0 / qa-run-d.log |
| ... restart backend; esperar healthy; ... up -d | 0 y0 / backend-d-restart.log, up-d-repeat.log |
| ... --profile qa run --rm --no-deps --entrypoint sha256sum qa /qa/run.cjs | 0 / qa-source-in-image.log; hash igual a fuente final |
| ... --profile qa run con runId ya existente | 1 esperado; verificación envolvente0 / qa-output-existing-negative.json |
| ... config --quiet final | 0 / compose-final-config.exit.txt |

El orden reversealphabetical inicialmente pedido ejecutó Monitor antes de Production por FQN de paquetes (build-attempt2). Se comunicó y el supervisor corrigió el contrato; alphabetical acredita el orden necesario en la misma JVM. Los primeros builds usaron el nombre top-level del compose; tras la aclaración todos los comandos operativos usan -p health-meeting-demo explícito.

## Hallazgos y correcciones conservados

| Severidad | Hallazgo reproducible | Corrección y prueba final |
| --- | --- | --- |
| Alta, test compartido previo | ProductionProfileTest inicializaba SpringApplication con root OFF y no restauraba; verify Linux fallaba Monitor expected1WARN/actual0. | BeforeAll conserva nivel ORIGINAL; AfterAll restaura después de ejecutables dinámicos. Ningún assert ni caso omitido; par ordenado y1162 de verify verdes. |
| Media, helper nuevo | javac: getLineNumber retorna long; variable int impedía compilar setup. | long para número de línea; javac/offline/install reales exit0. |
| Alta, infraestructura nueva | Docker29 conservaba PortBindings pero no publicaba el puerto en NetworkSettings cuando gateway solo estaba en red internal; host HTTP no conectaba. | Nueva frontdoor propia solo para gateway; backend/SQL continúan internos; host200 y navegador real exitoso. |
| Media, QA nuevo | APIRequestContext Node no resolvía health.localhost, EAI_AGAIN, antes de mutaciones. | extra_hosts solo del runner a loopback y forwarder TCP a gateway; destinos/Host/Origin canónicos preservados. |
| Media, QA nuevo | Tras reload, seleccionar fecha antes de carga de contexto era sobrescrito por Hoy; b agotó espera de cita. Tuvo un502 de public/status durante paro deliberado. | Esperar opciones del contexto antes de fecha, localizar por hora exacta + ID en API. c/d PASS, cero 5xx; solo502 del sondeo durante checkpointrestart se podría registrar como downtime esperado, cualquier otro falla. |
| Baja, QA nuevo | c completó checks, pero sockets keepalive retrasaban salida; finalmente terminóexit0. | Dispose del API context, cierre browser y túneles propios antes de escribirPASS; d terminóexit0 sin retención. |
| Media, repetibilidad QA | Riesgo de baseline fijo, selector de paciente ambiguo y sobreescritura de carpeta previa. | Delta+9550 y+1recibo, horario libre/locator exacto, mkdir exclusivo antes de red. c/d sobre volumen conservado; negativo de carpeta existente mantiene hash. |
| Bloqueo de herramienta, resuelto con autorización | Computer Use no pudo verificar URL ChromeWindows y detuvo interacción. | Se informó y envió completion_summary; supervisor autorizó expresamente Chromium Docker propio, sin usar otro control del escritorio. |

No quedan fallos requeridos abiertos en las fuentes finales; todos los intentos fallidos permanecen documentados. No se alteró producto para acomodar la QA.

## Capturas y artefactos

Final: browser/worker-20261116-d/01-desktop-sucursales.png;02-desktop-agenda-inicial.png;03-desktop-reserva-formulario.png;04-desktop-revision-explicita.png;05-desktop-cita-guardada.png;06-desktop-cobro-manual-ficticio.png;07-desktop-arqueo-real.png;08-mobile-semana-real.png;09-mobile-dia-real.png;10-desktop-persistencia-restart.png;11-desktop-persistencia-segundo-up.png. Resultados estructurados en esa misma carpeta/result.json. Capturas b/c y fallos anteriores también conservados.

Se inspeccionaron visualmente revisión desktop y semana móvil de b y persistencia desktop final de d; revisión explícita legible, calendario/arqueo reales y contenido móvil contenido dentro de390 px. No se editaron imágenes ni capturas previas aprobadas.

source-manifest.json enumera las14 fuentes con SHA256 exacto; artifact-manifest.json enumera reportes/logs/capturas (excluye su propio archivo para evitar autorreferencia). canonical-sql-comparison.json contiene hashes de las19 fuentes en ambos worktrees. images-final.txt registra imágenes efectivas. .env.demo y cookies/tokens/HAR no forman parte de los artefactos. delivery.patch contiene únicamente el template público autorizado.

## Acceso y estado dejado

URL http://reunion.health.localhost:18090/acceso/; RUC ficticio20000000001; profesional@example.test; contraseña de ejemplo y alternativa admin/plataforma en docker/demo/GUIA_TECNICA.md y .env.demo.example. Dos sucursales, paciente DEMO-001 y tres citas/cobros ficticios acumulados por QA. Volumen health-meeting-demo_sql-data conservado. SQL/backend healthy, gateway activo loopback18090, setup Exited0; ningún runner QA permanece activo.

Guía técnica incluye arranque, repetición, diagnóstico, stop/start/down sin-v, excepción TLS local, recursos x86_64/6–8GB, runner QA parametrizable y gates para revisión independiente. No se acredita soporte nativo AppleSilicon ni dispositivos/audio físicos.

## Pendientes siguientes, en orden (sin implementar aquí)

1. Supervisor: revisar14 fuentes/diff/hashes, mantener P1/R1 aceptadas y realizar su verificación independiente con runId nuevo sobre el mismo volumen o instalación nueva separada autorizada.
2. Supervisor: integrar archivos revisados; incluir .env.demo.example explícitamente porque la regla existente lo ignora; redactar README/guion/tablero/evidencias versionadas, eliminar ZIP en su checkout y publicar exclusivamente la rama health/production-wave0 según autorización del usuario.
3. Validar clone limpio en la laptop x86_64 de la reunión con Git + Docker Desktop y comandos documentados; no compartir .env.demo, volumen, cookies ni datos de esta máquina. La QA actual acredita este host DockerLinux/amd64, no otra laptop todavía.
4. Mantener cualquier conexión Somee/productiva fuera de este paquete, pendiente de destino exclusivo Health Project, credenciales/contrato y validación separados del supervisor. No hay declaración de proyecto productivo listo.
