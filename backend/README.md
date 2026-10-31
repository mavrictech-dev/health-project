# Health Project — backend

Java 21 + Spring Boot 4.1.1, monolito modular, MySQL 8.4 y procedimientos almacenados. El contrato HTTP y las reglas se encuentran en [la guía de arquitectura](../docs/backend/01_Plan_Arquitectura_y_Construccion.md) y [la referencia de API](../docs/backend/02_API_y_Recorridos.md).

## Ejecutar en Docker

Desde la raíz del proyecto, con Docker Desktop iniciado:

```powershell
.\scripts\setup.ps1
docker compose up -d --build
docker compose ps -a
```

`setup.ps1` genera claves aleatorias en `.env` si todavía no existe. Conserva un archivo existente. El usuario inicial está en `BOOTSTRAP_ADMIN_EMAIL` y su contraseña en `BOOTSTRAP_ADMIN_PASSWORD`; el bootstrap crea el administrador solo si no existe uno. Cambiar ese valor después no cambia una contraseña ya guardada.

| Servicio | Acceso local |
| --- | --- |
| Gateway y API | `http://health.localhost:8080` |
| Cliente creado con slug `aurora` | `http://aurora.health.localhost:8080` |
| MySQL | `127.0.0.1:3307`, base `health_project` |
| Presentación anterior | Sigue en su proceso de `127.0.0.1:3001` |

El gateway sirve la exportación de `frontend/out`. El login, registro, verificación de correo, recuperación, cuenta y sesiones, trazabilidad, monitor y soporte ya utilizan la API real. La presentación clínica sigue disponible de forma explícita en `/demo`; sus datos y operaciones son ficticios. Consulta [Identidad, trazabilidad y operación](../docs/backend/04_Identidad_Trazabilidad_y_Operacion.md).

Accede por `http://health.localhost:8080/acceso/`. El buzón de correo de desarrollo está en `http://127.0.0.1:8025`: allí llegan los enlaces de verificación y recuperación. El correo es capturado localmente; para enviar a destinatarios reales configura las variables SMTP de `.env.example`. El registro en el dominio base crea un cliente y propietario en prueba; el registro en un subdominio existente crea una cuenta de portal sin acceso automático a historias.

El soporte está identificado como **Mavric Technologies**, con el enlace **https://mavrictec.com**. Los tickets y respuestas se guardan en el sistema; el enlace externo no implica una integración de envío al proveedor.

Si tu equipo no resuelve subdominios de `.localhost`, puedes probar la API sin cambiar DNS:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/api/public/context -Headers @{Host='health.localhost'}
```

## Dominio configurable

Por ahora se usa `HEALTH_BASE_DOMAIN=health.localhost` y `HEALTH_PUBLIC_ORIGIN=http://health.localhost:8080`. Para un dominio comprado, configura ambos valores y un registro DNS wildcard hacia tu gateway; añade HTTPS en el despliegue. El alta reserva el slug y crea el cliente, contrato, propietario, sede y especialidades en una transacción. No requiere un contenedor por cliente ni llama a un proveedor DNS en cada alta.

El tenant se obtiene del `Host` real, se comprueba contra la base y se vincula a la sesión. La API no acepta `tenantId` para elegir el cliente. Las claves de migración se suministran únicamente al proceso `migrate`. `health_app` tiene `SELECT` y `EXECUTE`; todas las escrituras de negocio pasan por procedimientos con parámetros y transacciones de Spring.

## Compilar y verificar

Sin instalar Maven globalmente, con JDK 21:

```powershell
cd backend
.\mvnw.cmd -B -ntp verify
cd ..
python backend/scripts/verify-api.py
python backend/scripts/verify-identity-trace.py
python backend/scripts/verify-persistence.py
```

La prueba de integración requiere el stack Docker saludable. Utiliza la biblioteca estándar de Python y crea clientes, usuarios y pacientes ficticios con prefijo `QA`, correos `example.test` y un identificador aleatorio por ejecución. No borra datos. Deja el resultado sin credenciales en `backend/test-results/api-integration.json`. Debe ejecutarse contra una base de desarrollo.

La prueba de persistencia reinicia únicamente los servicios de este proyecto, compara cantidades de registros y vuelve a validar login y migraciones. Guárdala para un momento sin trabajo activo en este entorno local.

Prueba aislamiento de host y sesión, alta atómica, asignaciones, cupos, revisiones, reservas de un profesional entre clientes, documentos firmados y portal, caja, stock y prescripciones, transferencias, ocupación y egreso, estados de procesos y revocación. Incluye solicitudes simultáneas para detectar reservas, devoluciones y dispensaciones duplicadas.

## Base de datos y operación

Las migraciones están en `src/main/resources/db/migration`. Flyway valida sus checksums; después de aplicar una migración, las correcciones van en una versión posterior. `scripts/generate-catalog.py` produjo el catálogo inicial de 241 perfiles; no debe reescribir V5 en una base ya migrada. Una actualización del catálogo se entrega en una nueva migración. Las atenciones y sus entradas conservan una copia del perfil utilizado.

Para detener y volver a iniciar conservando datos:

```powershell
docker compose stop
docker compose start mysql backend gateway
```

Para actualizar el código y ejecutar nuevas migraciones, usa `docker compose up -d --build`. Los datos permanecen en `health-project_mysql_data`. Las credenciales de `.env` deben conservarse junto con ese entorno; cambiar la contraseña del archivo no cambia automáticamente la del usuario MySQL existente.

Los errores usan `application/problem+json`. Los conflictos de revisión, estados, cupos e idempotencia devuelven 409; datos inválidos 400, autenticación 401, permisos 403 y referencias de otro cliente 404. Una consulta de historia devuelve hasta 200 atenciones, 1000 entradas y 200 documentos e informa sus límites; consultas históricas extensas requieren paginación adicional en la etapa de integración.

## Alcance de esta implementación

Incluye SaaS y contratos versionados, identidades y membresías, organización, pacientes humanos y animales, agenda, consulta externa con perfiles y anotaciones, documentos con firma interna/hash y adendas, portal por vínculos, caja, lotes y dispensación, transferencias, recursos hospitalarios y un motor de procesos con historial. Los planes iniciales y precios son ejemplos configurables del producto.

Los procesos de laboratorio, imagen, cirugía, anestesia, urgencias, terapias, transfusión, trasplante, reproducción y población veterinaria tienen estados e historial. Sus protocolos clínicos completos, catálogos y validaciones específicas se desarrollan por módulo antes de uso asistencial. No equivalen a una implementación clínica exhaustiva por tener un tipo de proceso.

Registro y recuperación ya emiten mensajes por SMTP y usan tokens de un solo uso con vencimiento. Docker captura esos mensajes en Mailpit. Para correo público se debe configurar un proveedor SMTP. La entrega por correo de invitaciones de equipo sigue pendiente; su aceptación exige las credenciales de la identidad y el subdominio correcto. Pagos externos, comprobantes fiscales, firma certificada, archivos/PACS/DICOM y otros proveedores requieren integración específica. La publicación de documentos permite consultar texto firmado; todavía no genera PDFs clínicos.

El entorno actual es local. El despliegue deberá incorporar DNS y TLS, secretos administrados, copias con restauración probada, observabilidad, políticas de conservación y revisión de los permisos clínicos de cada organización.
