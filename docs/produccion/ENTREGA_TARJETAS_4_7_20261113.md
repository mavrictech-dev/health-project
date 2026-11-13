# Entrega local: acceso, catálogo, pacientes e historia clínica

El usuario autorizó al coordinador a implementar directamente por falta de cuota
del programador. Se conservó su worktree y se recuperaron 35 archivos de RUC con
comparación de hashes y respaldo. Esta entrega corresponde a las tarjetas
solicitadas y está validada localmente; la comprobación en Somee sigue pendiente.

| Recorrido | Implementación y evidencia |
| --- | --- |
| Acceso | RUC de 11 dígitos + correo + contraseña; `POST /api/v1/auth/login`; elección de sucursal; `GET /api/v1/negocios/{ruc}/sucursales` |
| Seguridad | JWT HS256 con usuario, tenant, branchId, permisos y vencimiento; cookie HttpOnly/SameSite; CSRF; sesión revocable en SQL y membresía comprobada en cada solicitud |
| RUC del tenant | Alta pública y SAD, persistencia única y obligatoria, edición de nombre/RUC/zona con revisión; resolución segura del subdominio por RUC |
| HP4 DEV-CATALOG | Servicios y precios en PEN, convenios porcentuales, alta/edición/desactivación con revisión y auditoría; escritura ADM y lectura de roles internos autorizados |
| HP5 DEV-PACIENTE | Filiación, registro, búsqueda por DNI en el directorio del negocio compartido entre sedes; antecedentes append-only, versión vigente e historial con autor y fecha |
| HP6 DEV-HISTORIA-TXT | Anamnesis, examen físico, diagnóstico, tratamiento; paciente/sucursal/profesional; guardado idempotente; cita opcional con revisión y actualización atómica a Atendido/Pendiente/Cancelado/No asistió |
| HP7 DEV-HISTORIA-VOICE | Micrófono por campo, texto agregado sin reemplazar el manual; aislamiento del campo activo; escritura manual ante permisos denegados o navegador sin reconocimiento |

El checklist pegado para HP4 repetía el de acceso. Se completaron tanto ese
recorrido como el catálogo indicado por el título de la tarjeta.

## Validación realizada

- Maven `verify`: **1.118 pruebas, 0 fallos, 0 errores**, y JAR generado.
- Frontend: **114 pruebas**, TypeScript y builds estáticos de producción y demo.
- Herramienta Docker: **43 pruebas** después de corregir BOM de cabecera.
- **62 comprobaciones HTTP reales** de Java contra SQL Server 2022, usando datos
  sintéticos y un principal runtime con EXECUTE sobre SP, sin SELECT directo ni DDL.
- Alta pública con RUC y retorno 202 neutro; alta/edición SAD, revisión obsoleta y
  RUC duplicado; selección de sede única/múltiple; RUC ajeno; aislamiento entre
  negocios; alta de paciente; antecedentes 1/2 sin sobrescritura y rechazo CAS;
  consultas idempotentes, cuatro resultados de cita y revisión concurrente;
  tarifario y convenio, edición y límites; cierre/revocación de sesión.
- Prueba explícita de denegación de tablas y DDL al runtime y comprobación de los
  **241 perfiles JSON** del catálogo en el motor.
- Playwright con Chrome: recorridos de las capturas, dictado simulado por campo,
  permiso denegado, navegador sin voz, alta, guardado y móvil sin desbordamiento.
  No se utilizó audio de pacientes ni un servicio de voz de pago.

Las capturas usan la API de demostración y datos ficticios. La comprobación
Java/SQL es independiente y queda registrada en
`docs/produccion/evidencias/TARJETAS_4_7_20261113.json`.

## SQL y configuración

SQL Server 2022 / compatibilidad 160. Aplicar V1–V18 en orden con un principal de
migración separado; todas las lecturas/escrituras runtime pasan por SP
parametrizados. V15 exige un mapeo autorizado si existen tenants anteriores sin
RUC: **no genera un relleno ficticio**. El entorno QA es exclusivamente
`health_project_c1_docker_qa_20261112` en el contenedor propio de Health Project.

Se corrigieron las comparaciones de collation del preflight V14, variantes
exactas CREATE/ALTER que SQL Server conserva en sus definiciones y errores de
compilación del avance V15. Los hashes canónicos del verificador se actualizaron.
El transporte consume exclusivamente el BOM inicial de cada archivo y conserva
los literales. El instalador local lee archivos SQL verificados por hash.

- V15: RUC/perfil y autenticación del tenant.
- V16: antecedentes inmutables y consultas.
- V17: catálogo y codificación de la proyección de alergias conforme al executor.
- V18: enlace opcional a cita y resultado atómico, incluido `NO_SHOW`.

Configurar `health.sqlserver.mode=runtime` y el datasource SQL Server. Para
conservar JWT entre reinicios/instancias, definir `HEALTH_JWT_SECRET` con al menos
32 bytes secretos. Sin él se usa una clave aleatoria del proceso y los JWT deben
renovarse al reiniciar. Usar HTTPS y certificados verificados en el entorno
publicado. La excepción de confianza de certificado se utilizó únicamente en el
loopback del QA Docker y no cambia la configuración productiva.

## Capturas y código

Carpeta: `entregables/trello/capturas`. Índice:
[`entregables/trello/README.md`](../../entregables/trello/README.md).

Código en la rama autorizada:
[health/production-wave0](https://github.com/mavrictech-dev/health-project/tree/health/production-wave0).
No se integra en main ni se ejecuta despliegue.

Queda por comprobar el guardado en una **base propia de Health Project en Somee**
cuando se proporcione su conexión. AgendlyCitas está excluida.
