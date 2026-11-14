# Preparación de producción SQL Server

Estos archivos son una propuesta revisable; no despliegan ni aprueban producción.
No combinar `compose.production.yaml` con el Compose MySQL heredado. No ejecutar
`up`, `build`, `pull`, setup ni migraciones como parte de esta revisión.

## Recorrido previsto

`Navegador HTTPS → terminador HTTPS dedicado → 127.0.0.1:18080 → gateway → backend:8080 → SQL Server externo exclusivo`.

El terminador HTTPS se configura y valida por separado en el mismo host. Debe
admitir solo el dominio base y sus subdominios autorizados, conservar el Host
canónico y **sobrescribir** `X-Forwarded-Proto` con `https`, descartando el valor
del cliente. Debe redirigir/rechazar HTTP en su propio listener público. El
gateway solo publica IPv4 loopback; no es un terminador TLS ni debe publicarse
directamente en Internet. Rechaza Host desconocido (421) y ausencia de la marca
HTTPS (400); no confía en cadenas de cabeceras reenviadas hacia Java.

El backend no publica puertos. Comparte una red interna con el gateway y dispone
de una segunda red para salir al SQL externo; no hay servicio, volumen ni imagen
SQL/MySQL en este archivo. El firewall del destino debe permitir únicamente las
salidas aprobadas y restringir el SQL al runtime autorizado. Los límites del host
y la conectividad real se verifican antes de desplegar.

## Artefactos y secretos

- `backend/src/main/resources/application-production.yml` selecciona el root SQL
  Server runtime, desactiva Flyway/SQL-init/jobs/bootstrap y exige entradas externas.
  `ProductionProfileGuard`, registrado automáticamente mediante `spring.factories`,
  valida antes de construir el datasource: JWT configurado, HTTPS/Host coherentes,
  TLS SQL estricto y ausencia de opciones de setup/migración o datasource heredado.
  Fuera del perfil `production` la guarda no actúa. Los errores incluyen códigos
  `HP_PRODUCTION_*`, nunca valores recibidos.
- `production.env.example` contiene únicamente nombres y rutas de archivo. Mantener
  la copia operativa, credenciales y clave JWT fuera del repositorio, contextos de
  build, imágenes y argumentos de procesos. No colocar los valores de las claves
  en `.env`, `environment`, línea de comandos, logs ni en este README.
- Compose monta dos secretos como archivos. Spring importa obligatoriamente el
  config-tree `/run/secrets/`: `health.sqlserver.runtime.password` y
  `HEALTH_JWT_SECRET`. Este último exige al menos 32 bytes UTF-8 y ausencia de
  saltos de línea/control; debe ser una clave aleatoria persistente y compartida
  por todas las réplicas. No hay valor de ejemplo ni fallback aleatorio aceptado
  en este perfil. Acordar rotación y revocación de sesiones por separado.
- Verificar propietario/permisos y lectura de los secretos por el usuario no-root
  de la imagen backend revisada. Los secretos basados en archivos de Compose no
  sustituyen un gestor de secretos ni garantizan por sí solos remapeo de permisos
  del host. Las rutas de la plantilla deben apuntar a archivos protegidos existentes.
- Ambos `image` son obligatorios y deben fijarse a referencias inmutables revisadas
  (por ejemplo, un digest aprobado por el supervisor); no se incluyen digests
  inventados. `pull_policy: never` evita una descarga implícita. La imagen backend
  debe provenir de las fuentes exactas verificadas con sus bytes SQL canónicos.
- La imagen gateway debe ser compatible con la entrada oficial de nginx y su
  sustitución de plantillas, UID/GID `101:101`, escucha 8080, los tmpfs declarados y
  root readonly. Revisar esa compatibilidad en la imagen Linux final antes de usarla.

## SQL Server y frontend

El destino debe ser SQL Server 2022 con base exclusiva Health Project y esquema
aprobado. Usar un principal runtime con **EXECUTE solo sobre SP aprobados**, sin
SELECT/INSERT/UPDATE/DELETE/DDL de tablas ni ejecución de SP de migración/bootstrap.
Un principal separado realizará cualquier migración en su propio paquete futuro.
El perfil no comprueba los grants contra un servidor: esa comprobación efectiva
es un gate pendiente, no una garantía derivada del nombre de usuario.

JDBC exige cifrado y validación de certificado (`trustServerCertificate=false`)
contra el hostname externo. La cadena debe ser confiable para la JVM de la imagen
revisada y el certificado debe incluir el hostname SQL correcto. No se acepta la
excepción de confianza utilizada en antiguos QA loopback. Si el proveedor requiere
CA privada o parámetros adicionales, preparar otro contrato antes de ampliar esto.

El gateway monta **solo `frontend/out`**, generado mediante el build de producción
con `NEXT_PUBLIC_APP_MODE` ausente o `live`; nunca montar `out-demo`, generar el
build mock para producción ni usar un servidor de demostración como backend.
`/api/` siempre se envía al backend; `/demo` y `/demo/` están bloqueados en nginx.
El bundle existente contiene la presentación explícita del producto, pero no se
publica su ruta ni se selecciona el modo mock mediante esta configuración. La
autorización y los datos reales siempre los decide la API.

## Validación sin desplegar

Desde la raíz, con un archivo de valores **ficticios** que señale archivos
sintéticos propios, ejecutar solamente:

```text
docker compose --env-file <archivo-ficticio> -f compose.production.yaml config --format json
```

Inspeccionar la configuración resuelta: dos servicios, ausencia de `build`, SQL,
volúmenes de datos y puertos públicos del backend; una única publicación gateway
en `127.0.0.1`; secretos como rutas, nunca valores; perfil `production`.
No usar el archivo de secretos reales para generar evidencia compartida.

Renderizar únicamente `${HEALTH_BASE_DOMAIN}` de `nginx.conf.template` con un dominio
ficticio bien formado. Las variables propias de nginx (`$host`, `$uri`, etc.) deben
quedar intactas. Validar con `nginx -t` bajo un prefijo temporal propio, sin iniciar
workers ni enviar señales. Una prueba de sintaxis Windows no acredita el arranque
de la imagen Linux, la red Docker, el proxy real o TLS extremo a extremo.

Las pruebas Java del perfil cargan ConfigData y `SpringApplication` con la factory
real, drivers simulados y cero conexiones; comprueban fallos de cada gate antes
del datasource y continuidad de la clave configurada entre contextos sintéticos.
Esas pruebas no validan SQL real, DNS, certificados, permisos efectivos ni entrega
de correo. La sonda readiness futura ejecutará el SP de salud aprobado; no probarla
contra un destino real durante este paquete.

## Gates pendientes

Somee no se presupone proveedor del proceso Java. Comprobar por separado capacidad
de alojamiento del backend/contenedores y terminador HTTPS, y capacidad del destino
SQL (versión, conexión externa cifrada, red, límites y permisos). Solo considerar
una base exclusiva Health Project; AgendlyCitas está fuera de alcance.

Antes de autorizar una salida: cerrar la revisión independiente e integración de
fuentes; elegir destino y credenciales exclusivos; validar imágenes, configuración
final, DNS/TLS/red y grants reales; ensayar actualización/reversión y copia con
restauración; medir carga y seguridad; aprobar el alcance clínico y el piloto.
Esta preparación no cubre esos gates ni permite datos de pacientes reales.
