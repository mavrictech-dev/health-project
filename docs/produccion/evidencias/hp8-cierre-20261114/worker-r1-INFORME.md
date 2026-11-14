# HP8.CIERRE.R1 — entrega para revisión

**Resultado R1: completado para revisión independiente. No autoriza producción.**
Task `task_81906d33c50e`, Dispatch `ctx_38f36396ce9b`, terminal
`term_9914da39-6d36-4e99-8ab4-1b06a48393c6`, 14 de noviembre de 2026.
Base `8a6a6aeab6c40a3ec114e0175289b75e7a3022e4`, rama
`Maczz09/health-programmer-hp8-review`, worktree propio indicado en el contrato.

P1 conserva su resultado histórico failed/parcial; no se sobrescribió su informe
ni sus capturas. Sus ocho fuentes coinciden con el congelado del supervisor.
El contrato actualizado y los mensajes de ampliación autorizaron las restauraciones
binarias, `ProductionProfileGuard.java` y `META-INF/spring.factories`.

## Requisito y evidencia

| Requisito | Resultado y evidencia relativa a este directorio |
| --- | --- |
| Restaurar V13 original sin cambiar pin, BOM o SQL | 4.852 bytes, SHA256 `667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51`; equivalencia CRLF/LF con previo y HEAD. `phase-a-restoration.json` |
| Addendum autorizado V1–V12 y atributos V1–V19 | Restauración binaria exacta desde ROOT; los 19 archivos coinciden con las huellas originales. Dos índices/checkouts aislados con autocrlf true/false verifican 76 comparaciones SHA de blob y checkout. `.gitattributes` protege V1–V19 con `-text`. `phase-a-addendum.json` |
| Preservar P1, índice y configuración Git | Ocho fuentes P1 intactas; índice y configuración Git del usuario conservados byte por byte. No staging del usuario, commits, push ni merge. `baseline.json`, `delivery-manifest.json` |
| Fase A antes de B | A y addendum verdes, sin omitir pruebas; evidencia inicial conservada en `phase-a-summary.json` y `phase-a-addendum-summary.json` |
| Perfil production SQL Server | Perfil separado del Compose MySQL; root runtime completo, TLS SQL estricto, jobs/Flyway/SQL-init/bootstrap desactivados y datasource heredado vacío. Entradas de SQL y secretos obligatorios, sin destinos/usuarios/contraseñas por defecto |
| Validación previa al datasource | Factory real de Spring Boot carga automáticamente ProductionProfileGuard; fuera de production no actúa. Pruebas con ConfigData y SpringApplication reales, drivers simulados y cero conexiones: JWT ausente/vacío/corto/control, HTTPS/host/puerto, SQL ausente, TLS, jobs, setup/bootstrap/migración, datasource heredado, forwarded headers y alias locales `.`/`::`/`[::]`. 35 pruebas finales |
| JWT estable y secretos externos | Config-tree obligatorio; dos contextos sintéticos verifican el token de la misma clave configurada. Secretos como archivos externos, sin valores en Compose, ejemplos, imagen ni argv; no se empaquetan archivos de claves |
| Compose dedicado | Solo backend y gateway, sin build/pull automático, SQL ni volúmenes de datos; backend sin puertos publicados y gateway únicamente `127.0.0.1:18080`. Redes interna/egreso separadas; frontend monta solo `frontend/out`. Config resuelta y 9 rechazos de valores obligatorios ausentes |
| nginx offline | `nginx -t` del validador Windows proporcionado por el supervisor, SHA `53530836391897EA218D8040ACDD467CD4832EFAB597E534D7C670E0E6C94B3C`, exit 0. Render solo del dominio ficticio, filtro semántico exacto y variables nginx preservadas. Host ajeno 421, marca de terminación HTTPS requerida, `/demo` y actuator bloqueados, cabeceras reenviadas descartadas |
| Empaquetado y registro real del JAR | 19 recursos SQL coinciden con hashes originales; perfil/factory exactos y clase de guarda empaquetados. Boot conserva la factory en `META-INF/spring.factories` del archivo. Lanzamiento negativo del JAR real, sin servidor y sin JWT, rechaza con `HP_PRODUCTION_JWT` antes del datasource. `phase-b-final-backend-summary.json` |

La exclusividad de la base, los grants EXECUTE-only, firewall y cadena TLS reales
son condiciones del destino todavía pendientes de comprobar; filtrar hostnames y
validar objetos/configuración no demuestra esos permisos ni conectividad.

## Comandos y salidas

Frontend desde `frontend`, Maven desde `backend`, scripts Python desde la raíz.
Los logs y archivos `.exit.txt` conservan las salidas de cada ejecución.

| Comando | Exit final | Evidencia |
| --- | --- | --- |
| `python tmp/hp8-close-r1/phase_a_restore.py` | 0 | `restoration.log`, `phase-a-restoration.json` |
| `.\mvnw.cmd -o clean verify` fase A | 0 | 1.127/1.127; `phase-a-maven.log` |
| `npm.cmd test` | 0 | 126/126; `phase-a-frontend-test.log` |
| `npm.cmd run check` | 0 | `phase-a-frontend-check.log` |
| `npm.cmd run build`, luego `npm.cmd run build:demo` | 0 / 0 | `phase-a-build-production.log`, `phase-a-build-demo.log` |
| `python tmp/hp8-close-r1/phase_a_addendum.py` | 0 | 19 fuentes, dos checkouts; `addendum-restoration.log` |
| `.\mvnw.cmd -o clean verify` addendum A | 0 | 1.127/1.127; `phase-a-addendum-maven.log` |
| `.\mvnw.cmd -o '-Dtest=ProductionProfileTest' test` corregido | 0 | 33/33 en `phase-b-profile-test-r3.log`; dos casos de puerto posteriores incluidos en la suite completa final de 35 |
| `.\mvnw.cmd -o clean verify` final B | **0** | **1.162 pruebas, 0 fallos, 0 errores, 0 omitidas**; `final-maven-clean-verify.log` |
| `python tmp/hp8-close-r1/validate_production_artifacts.py` | 0 | `phase-b-offline-config-r3.log`, `phase-b-offline-config-summary.json` |
| `docker compose --project-directory <worktree> --env-file <fixture> -f compose.production.yaml config --format json` | 0 | `phase-b-compose-config.stdout.txt`; Compose 5.6.0, sin daemon |
| `nginx.exe -v` y `nginx.exe -t -p <tmp propio> -c <config propia>` | 0 / 0 | `nginx-version.stderr.txt`, `phase-b-nginx-test.stderr.txt` |
| `python tmp/hp8-close-r1/verify_packaging.py` | 0 | `packaging-verification.log`; lanzamiento negativo del JAR exit 1 **esperado**, con código seguro JWT y sin servidor |
| `git --no-optional-locks diff --check` | 0 | Sin errores de whitespace; no cambia el índice |

JAR verificado, no imagen construida:
`backend/target/health-project-0.1.0.jar`, SHA256
`5884FBE58B671A338433A1946353A0C2DCA2A024CD3956AA2ABF98C1E8534055`.

## Fallos previos conservados y corregidos

- `phase-b-profile-test.log`, exit 1: 30 pruebas, 19 fallos y 1 error porque el
  contexto de prueba inicialmente no exponía BeanFactory antes de refresh. Se
  cambió solo el harness a GenericWebApplicationContext, manteniendo ConfigData,
  SpringApplication y factory reales; ningún servidor embebido se inicia.
- `phase-b-profile-test-r2.log`, exit 1: dos negativos de SQL database/user ausentes
  revelaron que Binder aceptaba un placeholder literal. La guarda ahora resuelve
  estrictamente las cuatro entradas SQL antes de bind; se conservaron los negativos.
- `phase-b-offline-config.log`, exit 1: comparación demasiado estricta de la
  representación del dólar en Compose. Se verifica la semántica del filtro y la
  conservación de variables, sin relajar la sustitución a otros nombres.
- `phase-b-offline-config-r2.log`, exit 1: nginx pasó sintaxis pero faltaba el
  directorio temporal padre de su prefijo Windows. Se creó solo bajo el tmp propio;
  el stderr original se conserva en `phase-b-nginx-test-attempt1.stderr.txt`.
- Una inspección auxiliar del JAR asumió la factory bajo BOOT-INF/classes y produjo
  KeyError; el empaquetador la ubica en META-INF. La verificación final compara sus
  bytes en esa ubicación y prueba su carga mediante el lanzamiento negativo real.

Todos esos fallos están resueltos en las comprobaciones finales indicadas; no se
presenta el trabajo como una pasada ininterrumpida ni se borran evidencias fallidas.

## Fuentes y límites de entrega

`delivery-manifest.json` incluye SHA256 por cada fuente B, atributos, las 19
migraciones y las ocho fuentes P1, junto con huellas de logs/artefactos. El código
de preparación y verificadores propios está únicamente bajo este tmp.
El manifiesto conserva la base, las autorizaciones y los resultados de A/B.

No hubo SQL real, setup/reapply, Somee/AgendlyCitas, DNS o TLS reales, servicios
externos, arranque del daemon Docker, imagen nueva, compose up/build/pull,
despliegue ni ZIP final del proyecto. nginx Windows valida sintaxis y apertura
de archivos; no acredita la imagen Linux, proxy/red ni TLS del destino.
Se utilizó el validador del supervisor sin modificar sus archivos.

La preparación usa el mecanismo documentado de [registro de initializers de Spring Boot](https://docs.spring.io/spring-boot/how-to/application.html);
la limitación de la propiedad antigua se contrastó con el jar instalado. El alcance
de `nginx -t` está descrito en sus [parámetros oficiales](https://nginx.org/en/docs/switches.html).

Pendientes en orden: revisión e integración independiente del supervisor;
selección de imágenes y destino exclusivos y compatibilidad Linux; credenciales,
grants SQL efectivos y DNS/TLS/red; comprobación separada de capacidades de Somee
y alojamiento Java/contenedores; actualización/reversión y copia/restauración;
carga/seguridad; aceptación del alcance clínico y autorización final del piloto.
La preparación R1 no cierra esos gates ni habilita pacientes reales.
