# Demo Docker para la reunión: revisión cerrada — 2026-11-16

**Aceptada para presentación local con datos ficticios.** La instalación principal
se descarga de GitHub en `health/production-wave0` y utiliza Git, Docker Desktop
Linux/amd64 y navegador. Frontend normal, API Java 21 y SQL Server 2022 Developer
se compilan/ejecutan en Docker. El ZIP anterior se retira de esta entrega.
Instalación completa y credenciales públicas de ejemplo: [README](../../README.md).
Recorrido: [guion de reunión](../../frontend/GUIA_PRESENTACION.md).

La aceptación corresponde a la demo local; los gates de
[producción](SALIDA_PRODUCCION_20261114.md) siguen abiertos. No se realizó despliegue
remoto, integración en main ni uso de pacientes/destinatarios reales.

## Encargo y revisión de fuentes

Contrato: [DEMO_DOCKER_LAPTOP_20261116.md](DEMO_DOCKER_LAPTOP_20261116.md).
Programador retenido, task `task_5ee0aa4919a6`, dispatch `ctx_fc37233ae5c6`, run
`run_624b9269b491`; entrega `msg_405724745376` revisada por el supervisor.
Identidades efectivas arquitecto/programador verificadas según D-82, por proceso
y `--no-daemon`. El programador no creó commits ni hizo push.

Se contrastaron SHA256/tamaño de las 14 fuentes y los 131 artefactos del trabajador
antes de copiar el paquete al checkout supervisor. De las 821 fuentes de su
baseline, 820 permanecen idénticas; la única existente modificada es
`ProductionProfileTest.java`. Se conserva el trabajo P1/R1 aceptado. El cambio del
test restaura al final de la clase el nivel de logging global que Spring alteraba;
no cambia los 35 casos, expectativas, MonitorService ni Java productivo.

Se revisaron Compose, Dockerfiles, nginx, perfil local, template, helper Java y
runner QA. Las 19 fuentes SQL canónicas son idénticas en ambos worktrees. El helper
valida hashes y orden, separa GO fuera de comentarios/literales, conserva BOM inicial
y ejecuta 277 batches en instalación nueva. Setup administra DDL/marker/catálogo
con un principal separado; los fixtures de negocio se crean mediante SP parametrizados.
Runtime solo recibe EXECUTE sobre SP aprobados, sin credenciales SA/bootstrap.

El gateway publica solo `127.0.0.1:18090`, con redes propias `frontdoor`/`meeting`.
SQL/Java están exclusivamente en la red interna y sin puertos host. Volumen,
contenedores y redes llevan scope `health-meeting-demo-v1`. El perfil `local-demo`
admite certificado SQL autofirmado solo en esta red ficticia; el perfil/guarda de
producción no se modifican. Jobs, migraciones y bootstrap están desactivados en
runtime. `/demo` no sirve la alternativa estática.

## Verificación independiente del supervisor

Evidencia versionada: [directorio](evidencias/demo-docker-laptop-20261116/).
Los logs completos permanecen en `tmp/demo-docker-laptop-supervisor-20261116/review-20261116`;
el directorio versionado contiene resultados, extractos y capturas, sin env local,
cookies, tokens, HAR o perfiles del navegador.

| Comprobación | Resultado |
| --- | --- |
| Build desde el checkout supervisor | `up -d --build` exit 0. Maven verify: **1.162 pruebas, cero fallos/errores/omisiones**. Par ProductionProfileTest antes de MonitorServiceSqlServerTest: **43 pruebas**, misma JVM, alphabetical/forkCount=1/reuseForks=true. |
| Frontend | Typecheck y build normal Docker acreditados por el trabajador y repetidos por el supervisor desde el snapshot limpio de Git: compilación y 87 páginas completadas. Los 126 tests frontend del cierre previo mantienen su fecha y no se suman como una suite nueva de esta entrega. |
| Copia limpia de Git | Snapshot del índice, sin configuración privada ni ZIP retirado; template público incluido, 24 enlaces locales válidos y Compose config exit 0. Checkout Windows conserva contenido de las 14 fuentes salvo normalización de finales de línea; las 19 SQL permanecen byte a byte y SHA exactas. Nuevo build Docker completo exit 0: 43/1.162 tests, frontend check/build y helper offline 19 fuentes/277 batches PASS. Los metadatos de cierre añadidos después no alteran esas fuentes de aplicación. |
| SQL nuevo y permisos | Trabajador: instalación nueva completa, 19 fuentes, 43 tablas, 152 SP, 34 triggers. Supervisor: `setup --verify` exit 0, ALREADY_COMPLETE, fixturesRepeated=false y cuatro denegaciones reales: SELECT de tabla, CREATE TABLE, bootstrap y helper privado. |
| Puerto real del host | PowerShell a `127.0.0.1:18090`, Host canónico: 200/contexto RUC correcto. Host desconocido: 421. No depende solo del túnel del runner. |
| Acceso y reserva | Chromium real/Playwright en Docker, RUC/correo/contraseña, dos sucursales y sede principal; revisión explícita antes de POST. Cita futura 17/11/2026 11:00 America/Lima, id `4c2158f5-1ad0-4c0e-8fbd-96d469f70773`. |
| Cobro y arqueo | PAID/YAPE 9.550 céntimos, delta de arqueo 28.650 → 38.200 y recibos 3 → 4. Registro manual ficticio; no hubo pago externo. |
| CSRF | Petición con cookie real y sin token CSRF: 403; sin mutación. |
| Reinicio | Restart scoped de backend exit 0, mismo ID/StartedAt distinto, vuelve a healthy y host 200. La misma sesión de navegador recupera la misma cita y cobro. |
| Segundo arranque | `up -d` exit 0, setup ALREADY_COMPLETE sin repetir fixtures; misma sesión/cita/paciente conservados. |
| Administrador y plataforma | Login real ADM/admin@example.test y SAD/plataforma@example.test; roles comprobados en sesión. Organización/sedes y clientes SaaS se recuperan desde API/SQL. Desktop y viewport móvil sin errores de página o 5xx. |
| Paciente e historia | Ficha DEMO-001; nueva versión de antecedente ficticio con autor/fecha; consulta escrita guardada por UI y recuperada por ID tras recarga y API. Sin cita vinculada, sin modificar las reservas anteriores. |
| Evidencia visual | 19 capturas propias: 11 agenda/persistencia, 4 administración y 4 paciente/historia. Viewport móvil 390×844; no es un teléfono físico. Inspección visual propia de revisión de reserva, semana móvil, persistencia desktop, organización desktop, clientes móvil y consulta móvil. |
| Preservación | Los siete contenedores Health previos conservan ID/imagen/estado/StartedAt/RestartCount exactos antes/después. Main permanece `0b24487c77055a081f6e76f0b18bc544ce4b1958`; otros proyectos quedan fuera de alcance. |

El navegador no interceptó ni sustituyó respuestas API. El runner usa un forwarder
TCP dentro de su contenedor para conservar Host/Origin/cookies y las URLs canónicas;
solo conecta a su gateway, sin puertos host, socket Docker o perfil del escritorio.
Los runners terminaron y se retiraron mediante `--rm`. SQL/backend quedan healthy,
gateway activo y volumen conservado para presentar.

## Incidencias conservadas y límites

Los intentos iniciales del trabajador se conservan en su
[informe](evidencias/demo-docker-laptop-20261116/worker-INFORME.md): logging compartido
del test, tipo long del helper, publicación de puertos en red interna y sincronización
del harness. Todos se corrigieron y verificaron antes de aceptar las fuentes finales.
El orden reversealphabetical inicial era incorrecto por nombre completo de clase;
el contrato se corrigió a alphabetical y el log demuestra el orden real.

En QA independiente hubo **un 502 de `/api/public/status` durante el reinicio
deliberado**. Está conservado tanto en serverErrors como en expectedDowntime del
resultado; el resto del recorrido no tuvo 5xx ni errores de página. No se comunica
como cero errores HTTP absoluto. La primera invocación del build QA del supervisor
fue interrumpida por PowerShell al interpretar el progreso stderr de Docker; no
capturó un exitcode concluyente. La repetición capturó exit 0. Los mensajes
NativeCommandError de stderr no sustituyen el código de salida Docker.

Las cuatro citas/cobros conservadas corresponden a tres corridas del trabajador y
una independiente; no son fixtures duplicados. El antecedente y consulta son ejemplos
adicionales deliberados. Se conserva la BD usada para comprobar repetibilidad; no
se borraron datos para que las pruebas pasaran.

Esta evidencia acredita Docker Linux/amd64 en este equipo, no una segunda laptop
física. La instalación de la reunión requiere Git y Docker/Desktop x86_64, Internet
para la primera descarga y recursos suficientes. No se verificaron ARM nativo,
micrófono/audio físico, correo real, pasarelas ni un destino productivo. La entrada
manual permite completar el guion probado. No hay pendientes de esta revisión local;
la puesta en producción mantiene su aceptación separada.
