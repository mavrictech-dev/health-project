# Reunión local conectada con Docker

Solo datos ficticios. No es una instalación productiva ni permite pacientes reales.
Requisitos del host: Git y Docker Desktop con contenedores Linux/Compose; navegador
normal para las pruebas. Node 24, Java 21, npm, Maven y SQL Server se ejecutan en
Docker. SQL Server 2022 Developer requiere plataforma x86_64 y recursos suficientes:
reservar al menos 6–8 GB para Docker, además del sistema host. No se acredita soporte
nativo Apple Silicon; la emulación no es una garantía de funcionamiento del motor.

## Inicio desde la raíz

1. Copiar `.env.demo.example` a `.env.demo` (por ejemplo `Copy-Item` en PowerShell
   o `cp` en una shell). Son ejemplos de credenciales ficticias para uso local.
   No reutilizar contraseñas reales. `.env.demo` queda ignorado por Git y fuera
   del contexto de build. Conservarlo para mantener las claves en los reinicios.
2. Comprobar que el puerto 18090 está disponible y que no existe otro proyecto
   `health-meeting-demo`. Si se cambia `DEMO_PORT`, usar ese puerto en las URLs.
3. Ejecutar:

```text
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml up -d --build
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml ps -a
```

El primer build puede tardar varios minutos al descargar imágenes/dependencias.
`sql` debe quedar healthy, `setup` finaliza con exit 0 y después arranca Java.
El gateway espera la sonda de aplicación (SP de salud). No publica puertos SQL o
Java; el único acceso del host es el gateway en IPv4 loopback.
El gateway conecta también a una red `frontdoor` propia para publicar ese puerto:
Docker no publica puertos en una red exclusivamente `internal`. SQL y Java solo
pertenecen a `meeting`, que sigue siendo interna; no pueden salir a correo.

## Acceso para la reunión

- URL: `http://reunion.health.localhost:18090/acceso/`.
- RUC ficticio: `20000000001`.
- Correo: `profesional@example.test`.
- Contraseña de ejemplo: `Meeting_App_2026_Only!` (o el valor local de
  `DEMO_APP_PASSWORD` usado en el primer arranque).
- Elegir **Sede principal · ejemplo** o **Segunda sede · ejemplo**. La cuenta
  tiene PRO/REC para reservar, consultar y registrar cobros manuales ficticios.
- Otra identidad ficticia: `admin@example.test`, misma contraseña de ejemplo,
  administradora del negocio. Plataforma ficticia: `plataforma@example.test`
  desde `http://health.localhost:18090/acceso/`.

La ficha inicial se llama **Paciente ficticio de reunión**, identificador
`DEMO-001`. Reservar un horario futuro, revisar los datos y confirmar; registrar
un cobro ficticio y comprobar el arqueo del día de registro. No se conecta a
pasarelas, servicios de voz de pago ni correo saliente. Los jobs de correo y
bootstrap están desactivados en el runtime y la red del stack es interna.

## Persistencia y diagnóstico

```text
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml logs setup
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml logs --tail 80 backend
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml restart backend
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml up -d
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml run --rm --no-deps setup --verify
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml stop
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml start
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml down
```

Operar solo sobre este archivo/proyecto, comprobando labels
`com.docker.compose.project=health-meeting-demo` y
`com.mavric.health.scope=health-meeting-demo-v1`. `down` **sin `-v`** conserva
el volumen SQL propio. No usar prune, down-v o acciones generales sobre Docker.
No se modifican los contenedores legacy `health-project` ni los QA anteriores.

El instalador reconoce el marker COMPLETE, hashes de las 19 fuentes, catálogo y
roles; los arranques posteriores no reaplican SQL, siembran ni cambian claves.
Cambiar las contraseñas del archivo tras instalar no rota credenciales almacenadas;
fallará la comprobación y requiere un procedimiento separado, nunca reset automático.

Ante un error de transporte/commit, base no marcada, esquema parcial o huella
inesperada: conservar volumen y logs. El instalador falla y no reintenta mutaciones
automáticamente; `--verify` solo permite comprobar una instalación completa y
rechaza la parcial sin modificarla. Pedir reconciliación readonly al supervisor.
No repetir setup a ciegas ni vaciar una base para ocultar un fallo.

## Límites y controles

- Runtime SQL `hp_meeting_runtime` solo pertenece a `hp_runtime_executor`; setup
  y bootstrap usan principales separados. Usuarios/paciente/organización se crean
  con SP parametrizados mediante el executor aprobado, no INSERT directo.
- V1–V19 se leen byte por byte y se valida su SHA256 antes de una transacción
  externa. El splitter reconoce GO fuera de strings/comentarios y consume únicamente
  el BOM inicial de cada archivo. Se preservan literales, propiedades ANSI y pines.
- El perfil `local-demo` confía en el certificado SQL autofirmado únicamente en
  esta red privada y ficticia. Producción conserva TLS estricto y su guarda intacta.
- Los hashes/marker y verificaciones de permisos se hacen con setup separado;
  el runtime no recibe control, DDL ni lectura de tablas. El helper prueba denegaciones
  efectivas de SELECT, CREATE TABLE, bootstrap y helper privado antes de declarar listo.
- Frontend build normal/runtime, API Java real y SQL real. `/demo` está bloqueado;
  no montar ni publicar `out-demo`. La alternativa estática anterior no demuestra
  persistencia ni sustituye esta prueba conectada.
- Los ejemplos son públicos y locales. No exponer el gateway, usar un host remoto,
  conectar Somee/AgendlyCitas ni cargar datos o destinatarios reales.

## QA conectado opcional para revisión

El servicio `qa` solo arranca con el perfil `qa`. Usa Playwright 1.56.1 y una
imagen Chromium fijada por digest, sin Node instalado en el host. Solo conecta a
la red interna `meeting`; no publica puertos, usa sockets Docker, perfiles ajenos
ni credenciales del escritorio. Un forwarder TCP dentro del runner conserva las
URLs `health.localhost` y `reunion.health.localhost`, puerto, Host, Origin y cookies
reales. No intercepta ni sustituye respuestas HTTP.

```text
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml --profile qa build qa
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml --profile qa run --rm --no-deps -e QA_RUN_ID=revision-nueva-unica -e QA_WAIT_RESTART=true qa
```

Usar un `QA_RUN_ID` nuevo en cada corrida (minúsculas, números y guiones). Si ya
existe su carpeta, falla antes de abrir conexiones y no sobrescribe evidencias.
`DEMO_QA_OUTPUT` permite elegir el directorio host de artefactos; el valor por
defecto es `tmp/demo-docker-laptop-20261116/browser`. Cada corrida añade una cita y
un cobro ficticio, conserva los datos previos, busca un horario libre y acredita
delta Yape +9550 céntimos y +1 recibo sobre el arqueo anterior.

Para comprobar persistencia conservando la misma sesión de navegador, mantener
ese runner abierto y usar otra terminal, siempre desde la raíz:

1. Esperar `browser/<runId>/after-restart.json`. Comprobar labels del backend,
   ejecutar el comando scoped `restart backend` anterior y esperar su `healthy`.
   Crear el archivo vacío `browser/<runId>/resume-after-restart` dentro del
   directorio de artefactos (por ejemplo `New-Item -ItemType File` o `touch`).
2. Esperar `after-second-up.json`. Ejecutar el comando scoped `up -d` y comprobar
   `setup` exit0/`ALREADY_COMPLETE`; crear `resume-after-second-up` en esa carpeta.
3. El runner relee la cita por ID desde SQL mediante API/SP, comprueba cobro,
   sesión, paciente único y escribe `result.json`, capturas desktop y viewport
   móvil 390×844. Ningún audio físico se prueba en este recorrido.

El checkpoint expira a los 15 minutos sin borrar ni reparar datos. El sondeo
`/api/public/status` puede devolver 502 durante el paro deliberado del backend:
se registra como indisponibilidad esperada solo en esa fase. Cualquier otro 5xx
o error de página falla la prueba. Sin `QA_WAIT_RESTART=true`, la salida indica
`PASS_BROWSER_ONLY` y no acredita reinicios. No guardar cookies ni HAR con tokens
en los artefactos; el runner mantiene la sesión únicamente en memoria.
