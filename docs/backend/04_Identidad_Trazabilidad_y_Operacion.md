# Identidad, trazabilidad y operación

Implementación del 18 de octubre de 2026. Marca de soporte: Mavric Technologies, https://mavrictec.com.

Se conectan a la API las pantallas de acceso, registro, verificación, recuperación, sesiones, soporte, trazabilidad y monitor. Los módulos clínicos de presentación conservan su identificación como demostración hasta su integración específica.

La sesión del navegador utiliza una cookie HttpOnly, limitada al host, con SameSite y protección CSRF para escrituras. Las sesiones Bearer existentes se conservan para clientes de API. Los roles proceden del servidor. Una identidad solo puede registrarse como propietario de su nuevo espacio o como usuario de portal sin vínculo automático a historias. El registro exige verificar el correo; recuperar acceso requiere un token con vencimiento y un único uso. Las contraseñas no se registran en trazabilidad.

La auditoría correlaciona solicitud, actor, acción de negocio y cambios de registros en la misma transacción. Los triggers cubren las tablas de negocio y conservan estados antes/después; notas clínicas, contraseñas, tokens, cuerpos de correo y contactos privados se excluyen o se representan mediante hash. Los intentos rechazados se conservan en el registro de solicitudes. Los eventos no pueden editarse ni borrarse mediante la aplicación. Los eventos históricos previos a esta versión no tendrán contexto que nunca fue capturado.

El monitor toma muestras de base, latencia, memoria y disponibilidad y muestra errores HTTP y correo pendiente. El administrador general puede poner la aplicación en modo abierto, solo lectura o mantenimiento con motivo y revisión. El monitor interno no sustituye a una sonda externa cuando el proceso entero está caído.

Docker incorpora un buzón SMTP local para comprobar mensajes reales de verificación y recuperación sin enviarlos a destinatarios externos. El despliegue público necesita configurar SMTP, dominio y TLS. Soporte registra tickets y su seguimiento; el enlace de Mavric Technologies abre su web, sin inventar un correo o canal de atención.

## Recorridos y estados

Registro en dominio base → identidad sin verificar → tenant TRIAL, contrato, sede y asignaciones → correo de verificación → token válido del mismo host → identidad verificada → login. Registro en un tenant existente → cuenta PAC/RES sin vínculo a pacientes → correo → verificación. No se obtiene un rol clínico o de plataforma mediante el registro del portal.

Recuperación → respuesta uniforme, exista o no la cuenta → correo si corresponde a ese espacio → token válido durante 30 minutos → nueva contraseña → revocación de todas las sesiones. El enlace de verificación vence a las 24 horas. Un enlace consumido, vencido o enviado desde otro host es rechazado. Cinco contraseñas fallidas bloquean temporalmente la identidad durante 15 minutos; la recuperación válida permite restablecer el acceso.

Sesión: activa, vencida o revocada. La cookie se limita al host, es HttpOnly y SameSite=Strict; HTTPS activa Secure. El navegador envía X-CSRF-Token en las escrituras. La lista de sesiones expone identificadores derivados que no sirven para autenticar. El API Bearer existente continúa disponible. El gateway sobrescribe X-Real-IP; el backend solo lo acepta cuando el peer resuelve al gateway configurado de Docker.

Soporte: OPEN → IN_PROGRESS → WAITING_USER/RESOLVED → CLOSED; se permite volver de RESOLVED a IN_PROGRESS. Los cambios requieren revisión y quedan auditados. El cliente puede responder sus tickets; los operadores de plataforma gestionan estado y prioridad. Las solicitudes anónimas entregan referencia, sin permitir consulta pública por correo o referencia predecible.

Aplicación: OPEN habilita las operaciones; READ_ONLY y MAINTENANCE bloquean escrituras de negocio de tenants. Acceso y soporte continúan disponibles. La administración general gestiona el estado con revisión y motivo. Las muestras de base y memoria se conservan siete días. Las solicitudes técnicas registran código HTTP y duración; no registran cuerpos, cookies ni parámetros que contengan credenciales.

## Rutas conectadas

- `/acceso`, `/registro`, `/recuperar`, `/verificar`, `/restablecer`, `/invitacion`.
- `/saas/trazabilidad`, `/saas/monitor`, `/saas/soporte`, `/saas/cuenta` y sus equivalentes `/app/...`; el portal tiene cuenta y soporte con sus propios permisos.
- `/demo` abre expresamente la presentación con datos ficticios; su selector de rol no cambia la identidad autenticada del backend.

API añadida: `/auth/browser/login`, `/auth/browser/session`, `/auth/register`, `/auth/verify/request`, `/auth/verify/complete`, `/auth/recovery/request`, `/auth/recovery/complete`, `/auth/sessions`, `/public/registration`, `/public/support`, `/support`, `/trace/events`, `/trace/requests`, `/monitor`, `/monitor/mode` y `/public/status`.

Verificación reproducible: `python backend/scripts/verify-identity-trace.py`, `python backend/scripts/verify-api.py`, `npm run check`, `npm test`, `npm run build`, y desde `frontend`, `node scripts/identity-qa.cjs`. Las pruebas de identidad y navegador usan exclusivamente cuentas ficticias y el correo local. No se ejecutan simultáneamente las suites que cambian el estado global de la aplicación.

## Resultado verificado

El 18 de octubre se completó la construcción de Docker y la exportación de 82 páginas de Next.js. Pasaron 10 pruebas unitarias del backend, 30 pruebas del frontend, 59 comprobaciones nuevas de identidad/operación y las 176 comprobaciones de regresión del backend clínico/SaaS. Las migraciones V1–V11 están aplicadas; V10 registra INSERT, UPDATE y DELETE en 29 tablas de negocio mediante 87 triggers. Los triggers de auditoría rechazan la edición y el borrado de eventos.

Ocho escenarios de navegador aprobados: login real de administrador, consulta y exportación de trazabilidad, detalle lateral, monitor en blanco/negro/navy, cambios de estado, sesiones y logout, registro con correo y verificación, recuperación mediante enlace y presentación móvil. El buzón de pruebas recibió los mensajes por SMTP. Las capturas se revisaron para comprobar distribución, legibilidad y paneles laterales con desenfoque. El gateway responde también a los segmentos RSC de Next exportados en Windows.

Evidencias locales: `backend/test-results/identity-trace.json`, `backend/test-results/api-integration.json`, `frontend/test-results/identity-ui.json` y capturas `frontend/test-results/identity-*.png`. Los reportes no contienen contraseñas ni tokens. La aplicación queda en OPEN y los servicios MySQL, backend, gateway y correo local están activos.
