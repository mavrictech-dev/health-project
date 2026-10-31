# Verificación del backend

Fecha: 14 de octubre de 2026. Entorno local Windows + Docker Desktop, MySQL 8.4, JDK 21 y Spring Boot 4.1.1.

| Comprobación ejecutada | Resultado |
| --- | --- |
| Construcción Docker con `mvn verify` | Compilación de 52 fuentes Java; 9 pruebas unitarias aprobadas |
| Flyway sobre MySQL real | 8 migraciones aplicadas y posteriormente validadas |
| `backend/scripts/verify-api.py` | 176 comprobaciones aprobadas; ejecución `efcb522a2c` |
| Base nueva aislada con inicializador corregido | `health_app` recibió exclusivamente SELECT y EXECUTE |
| `backend/scripts/verify-persistence.py` | Conteos conservados tras reiniciar; login y validación Flyway correctos |
| Estado al entregar | MySQL y backend saludables; gateway activo en 127.0.0.1:8080 |

Los resultados detallados de desarrollo están en `backend/test-results/api-integration.json` y `backend/test-results/persistence.json`, sin contraseñas ni tokens. Los scripts pueden ejecutarse nuevamente siguiendo el README. Las comprobaciones HTTP se cuentan como aserciones del recorrido; no representan 176 protocolos clínicos ni 176 clases de pruebas unitarias.

## Cobertura comprobada

- Alta de hospitales, veterinaria e independiente; subdominio retornado; duplicados y reservados rechazados; rollback de propietario en alta fallida.
- Catálogo de 241 perfiles; compatibilidad humano/animal; profesional compartido entre clientes con sesiones distintas.
- Aislamiento de tokens y recursos; cabeceras de tenant o host reenviado ignoradas; campos inesperados rechazados; ADM sin permiso automático para historias.
- Asignaciones y sedes; límites de capacidad; invitaciones contabilizadas, aceptación y carreras por la última licencia.
- Contratos vinculados a versiones inmutables; cambios de catálogo sin alterar el precio contratado; actualización explícita y pago SaaS separado de caja clínica.
- Identificación del paciente, revisiones obsoletas y consulta de historia entre sedes del mismo cliente.
- Reservas concurrentes y superposición de un mismo profesional entre clientes; reintentos idempotentes y reutilización inválida de clave.
- Atención humana, anotación odontológica y atención veterinaria; copia del perfil; cierre e impedimento de cambios tardíos.
- Firma interna con hash, adenda, publicación, acceso exclusivo por vínculo y revocación; cambio de contraseña con invalidación de sesión.
- Cargos y pagos; saldo correcto; carreras por devoluciones superiores al pago.
- Recepción de lotes, dispensación vinculada a prescripción y límite concurrente, transferencia y recepción repetida sin duplicación.
- Cama exclusiva con admisiones simultáneas, egreso y rechazo de recursos incompatibles con veterinaria.
- Procesos con transiciones y revisiones; historial preservado; proceso veterinario rechazado en cliente humano.
- Suspensión conserva lectura autorizada y bloquea escritura; baja de membresía y logout revocan acceso.
- La cuenta de aplicación no puede insertar directamente en tablas; persistencia y salud tras reinicio.

Durante estas pruebas se detectaron y corrigieron la ambigüedad SQL de recepción de transferencias y el grant inicial de Docker que dejaba escritura directa. Las correcciones se entregaron en migraciones posteriores, conservando los checksums de versiones aplicadas. La prueba de base nueva utilizó recursos temporales propios, retirados al finalizar.

## Límites de la evidencia

La interfaz de presentación sigue usando mocks y no ha recorrido estos flujos con una sesión del backend. La integración frontend está pendiente. El motor de procesos avanzados cubre persistencia, roles y estados; los protocolos, catálogos y validaciones clínicas completos de cada especialidad siguen pendientes. No se probaron proveedores externos de correo, pagos, firma certificada, fiscalización ni imágenes clínicas.

Estas comprobaciones verifican el comportamiento local del alcance implementado. Todavía no incluyen pruebas de carga, recuperación desde backup, vencimiento de sesión por espera real, auditoría de seguridad externa ni certificación de protocolos asistenciales. La guía mantiene esos trabajos como tareas de preparación operativa y desarrollo por módulo.
