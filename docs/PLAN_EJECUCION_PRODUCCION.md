# Health Project — guía del agente de arquitectura y ejecución

Fecha de elaboración: 2 de noviembre de 2026.

Este documento es un encargo de coordinación: el agente de arquitectura debe inspeccionar el proyecto, convertir el plan en tareas acotadas, delegar programación y pruebas, revisar las entregas e integrar avances comprobados. No basta con entregar otro plan. Debe empezar por la primera tarea desbloqueada y continuar por dependencias.

## 1. Objetivo y alcance

Preparar Health Project para una primera operación real de consulta externa humana, odontología y veterinaria, con administración SaaS, organizaciones, sedes, profesionales, pacientes y responsables, agenda, atención, documentos y portal.

Conservar el alcance completo del producto en el backlog. Hospitalización y procesos avanzados corresponden a una etapa posterior; no presentarlos como completos por disponer de pantallas o estados genéricos. No habilitar una especialidad para uso asistencial hasta cerrar sus requisitos y validación.

El catálogo incluye 241 perfiles. Su existencia y sus gráficos de presentación no constituyen validación clínica de cada especialidad. Los módulos necesitan desarrollo y aprobación específicos para su habilitación progresiva.

La salida a producción requiere evidencias funcionales, de aislamiento, seguridad, recuperación y aceptación del piloto. Una compilación o una demo navegable no bastan para aprobarla.

## 2. Contexto confirmado y restricciones

- Repositorio: https://github.com/mavrictech-dev/health-project, rama de trabajo habitual `main`. Comprobar la rama y los cambios actuales antes de operar.
- Workspace conocido: `D:\Mavric\Health Project`.
- Demo publicada: https://health-project-demo.vercel.app. Debe seguir funcionando con datos ficticios, sin APIs reales ni credenciales del servidor.
- Backend: Java 21, Spring Boot, monolito modular, MySQL y procedimientos almacenados. MySQL es la decisión vigente; referencias antiguas a SQL Server son históricas.
- Frontend: Next.js, TypeScript, shadcn/ui, temas blanco, negro y navy, paneles por la derecha con fondo desenfocado. Preservar el diseño existente.
- El tenant se resuelve desde el host validado. El paciente pertenece al tenant; la historia se comparte entre sedes de ese tenant según permisos y con auditoría.
- Una identidad profesional puede tener membresías en varios tenants. No copiar ni mezclar historias entre ellos.
- Planes configurables por tipo de cliente, sedes, profesionales, especialidades y módulos. Las suscripciones conservan la versión de condiciones aceptada.
- El dominio comercial aún no está definido. Desarrollo usa `health.localhost`; no inventar un dominio adquirido ni anunciar DNS público configurado.
- Soporte: **Mavric Technologies**, https://mavrictec.com. No inventar correo, teléfono ni integración de envío al proveedor.

## 3. Lectura e inspección obligatorias

Leer las instrucciones aplicables `AGENTS.md` y los siguientes documentos. Si discrepan con la implementación, registrar la diferencia y comprobar el comportamiento; no elegir silenciosamente una versión.

1. [README del proyecto](../README.md).
2. [Arquitectura del backend](backend/01_Plan_Arquitectura_y_Construccion.md).
3. [Contratos HTTP y recorridos](backend/02_API_y_Recorridos.md).
4. [Verificación histórica del backend](backend/03_Verificacion_del_Backend.md).
5. [Identidad, trazabilidad y operación](backend/04_Identidad_Trazabilidad_y_Operacion.md). Complementa los contratos iniciales de autenticación; el navegador utiliza cookie HttpOnly y CSRF.
6. [Ejecución del backend](../backend/README.md) y [Compose local](../compose.yaml).
7. [Diseño SaaS](frontend-demo/07_SaaS_Multitenant.md) y [modo de presentación](frontend-demo/08_Demo_Vercel.md).
8. [Diseño funcional](Diseno_Funcional_Health_Project.md), [mapa de especialidades](Mapa_Especialidades_Health_Project.md) y [flujos](diseno/README.md).
9. [Reglas de Next.js](../frontend/AGENTS.md). Consultar la documentación de la versión instalada antes de modificar el frontend.

Inspeccionar como mínimo:

- `frontend/src/components/health-app.tsx`, `runtime-workspace.tsx`, `auth-session.tsx`, `saas.tsx`, `clinical.tsx`, `patients.tsx`, `agenda.tsx`.
- `frontend/src/lib/api.ts`, `app-mode.ts`, `frontend/src/store/demo.ts` y `frontend/src/mocks/`.
- Los módulos de `backend/src/main/java/com/mavric/health/` y las migraciones de `backend/src/main/resources/db/migration/`.
- Las suites existentes de `frontend/tests/`, `frontend/scripts/` y `backend/scripts/`.

Los documentos contienen resultados de ejecuciones anteriores. No presentarlos como pruebas recién ejecutadas. Verificar versiones, herramientas y entorno disponibles al empezar.

## 4. Estado de partida: verificar antes de modificar

| Área | Base existente | Brecha conocida |
| --- | --- | --- |
| Demo | Presentación independiente con mocks y persistencia local | Mantenerla aislada de producción durante la integración |
| Identidad y operación | Login, registro, verificación, recuperación, sesiones, soporte, auditoría y monitor con API real en modo normal | Endurecimiento, correo público e integración con todos los recorridos reales |
| Administración SaaS | APIs de clientes, planes, contratos, cupos, membresías y estados | Gran parte de las pantallas de administración todavía usa el store de demo |
| Clínica | APIs de pacientes, citas, consultas, entradas, documentos y portal | Conectar las pantallas y completar validaciones clínicas por perfil |
| Procesos avanzados | Estados e historial como base | Protocolos, reglas y conectores especializados pendientes |
| Archivos | Documentos de texto con firma interna y hash | Adjuntos privados, imágenes y PDFs clínicos |
| Despliegue | Entorno Docker de desarrollo y frontend demo en Vercel | Plataforma de producción, DNS/TLS, secretos, restauración, alertas y entrega controlada |

## 5. Forma de trabajo y delegación

El agente de arquitectura es responsable de contratos, prioridades, dependencias, revisión e integración. Puede delegar implementación en agentes de frontend, backend, calidad, seguridad y operación cuando el entorno permita subagentes. Si no están disponibles, ejecutar los mismos paquetes secuencialmente y conservar las revisiones y evidencias.

No abrir múltiples encargos para editar los mismos archivos compartidos sin coordinación. `health-app.tsx`, `api.ts`, `auth-session.tsx`, el shell, los tipos compartidos, las migraciones y las dependencias necesitan un responsable de integración.

Trabajar en entregas verticales: un recorrido con pantalla, API, permisos, persistencia, auditoría y pruebas. Evitar un frontend completo sobre contratos supuestos o un backend nuevo que duplique servicios existentes.

### 5.1 Arranque

1. Comprobar `git status`, rama, instrucciones y procesos existentes. Preservar cambios del usuario.
2. Auditar el alcance real y crear `docs/produccion/ESTADO.md` con evidencias y discrepancias.
3. Crear un tablero `docs/produccion/TAREAS.md` a partir de los IDs de este documento. Todos empiezan **POR_VERIFICAR**; no marcar lo existente como terminado sin inspección.
4. Definir el contrato y reparto de la primera entrega; delegar paquetes independientes.
5. Revisar, integrar y verificar cada entrega antes de abrir sus dependientes.

### 5.2 Plantilla obligatoria de encargo

Cada tarea delegada debe incluir:

```text
ID y objetivo concreto:
Recorrido inicial → resultado esperado:
Actor, tenant, sede y roles implicados:
Dependencias y contratos acordados:
Archivos/módulos asignados y archivos compartidos que no puede editar:
Operaciones existentes que debe reutilizar:
Reglas de validación, permisos, revisión e idempotencia:
Criterios de aceptación observables:
Pruebas requeridas y entorno de datos ficticios:
Entregables y evidencia esperada:
Fuera de alcance y decisiones pendientes:
```

### 5.3 Estados del tablero

`POR_VERIFICAR → LISTA → EN_CURSO → EN_REVISION → INTEGRADA → VALIDADA`.

`BLOQUEADA` requiere identificar qué falta, su responsable y qué trabajos independientes pueden continuar. Un bloqueo en proveedor o aprobación clínica no detiene tareas ajenas.

Cada fila conserva: ID, responsable, dependencias, estado, archivos o commit, evidencia de pruebas, hallazgos abiertos y siguiente acción. Una tarea solo queda VALIDADA cuando el coordinador comprueba su aceptación e integración.

## 6. Backlog por dependencias

Las dependencias indican un orden lógico. El coordinador puede dividir un paquete en subtareas, manteniendo su ID padre, o adelantar trabajo independiente después de acordar los contratos. No convertir todo el backlog en un único encargo.

### Ola 0 — base de integración

| ID | Paquete y responsable sugerido | Dependencias | Aceptación mínima |
| --- | --- | --- | --- |
| ARQ-01 | Auditoría y matriz de cobertura — arquitectura | Ninguna | Por cada recorrido: pantalla, API/procedimiento existente, rol, estado real/mock, prueba y brecha. Registrar discrepancias entre documentos y código |
| ARQ-02 | Contratos y límites de integración — arquitectura + backend/frontend | ARQ-01 | Contratos por recurso con ejemplos ficticios, errores, paginación, revisión e idempotencia; sesión y selección de tenant acordadas; decisiones registradas |
| QA-01 | Base reproducible de pruebas — calidad | ARQ-01 | Entorno de prueba separado, datos ficticios, comandos y resultados actuales; pruebas que modifican el estado global se ejecutan sin competir entre sí |

### Ola 1 — SaaS y organización reales

| ID | Paquete y responsable sugerido | Dependencias | Aceptación mínima |
| --- | --- | --- | --- |
| INT-01 | Infraestructura de frontend real — frontend | ARQ-02 | Navegación, sesión, errores, carga y permisos reales. Separación explícita live/mock. Las operaciones reales no leen ni escriben datos de negocio en el store de demo |
| SAAS-01 | Clientes, planes y suscripciones — frontend + backend | INT-01 | Administrador general crea y configura clientes desde la UI; cambios persisten tras recargar y desde otro navegador; duplicados y cupos fallan sin cambios parciales; aislamiento del administrador técnico respecto de historias clínicas |
| ORG-01 | Sedes, áreas, especialidades y equipo — frontend + backend | SAAS-01 | Altas/asignaciones/estados desde la UI; cuotas verificadas por servidor; una identidad participa en varios tenants con permisos propios; no se mezclan pacientes |
| IAM-01 | Invitaciones y correo público — backend + operación/frontend | ARQ-02, ORG-01 para el circuito completo | Invitación por enlace con vencimiento y uso único, aceptada en el tenant correcto; verificar y recuperar acceso con un proveedor de prueba; revocación y errores sin filtrar existencia de cuentas ni secretos |

### Ola 2 — recorrido asistencial inicial

| ID | Paquete y responsable sugerido | Dependencias | Aceptación mínima |
| --- | --- | --- | --- |
| PAC-01 | Pacientes, animales, responsables y vínculos — frontend + backend | INT-01, ORG-01 | Crear/editar/buscar con persistencia y paginación; revisiones evitan sobrescrituras; diferencias humano/animal y vínculos explícitos; cuentas de portal no obtienen historias automáticamente |
| AGE-01 | Agenda y recepción reales — frontend + backend | PAC-01, ORG-01 | Reserva, cambio, cancelación y recepción desde UI; zona horaria definida; disponibilidad por asignación; solicitudes simultáneas no duplican reserva ni solapan al mismo profesional entre tenants |
| CLI-01 | Consulta e historia compartida — frontend + backend | PAC-01, AGE-01 | Iniciar, guardar, recuperar y cerrar consulta; historia entre sedes del mismo tenant con permisos; conflictos visibles sin pérdida de borrador; cierre conserva historia y corrección posterior según contrato |
| ESP-01 | Evaluaciones y gráficos persistentes — frontend + backend | CLI-01 | Selecciones, estructuras, superficies, hallazgos, unidades y revisiones sobreviven a recarga y nueva sesión; servidor rechaza componentes incompatibles; perfil utilizado queda versionado |
| ESP-02 | Matriz de habilitación clínica — arquitectura + calidad + responsables clínicos | ARQ-01; ESP-01 para validar cada implementación | Para cada perfil: campos, gráficos, reglas, pruebas, revisión profesional y estado de habilitación. Desarrollar progresivamente los 241 perfiles; bloquear en servidor lo aún no aprobado para uso real |
| DOC-01 | Documentos, PDFs y adjuntos privados — backend + frontend | CLI-01; contrato de almacenamiento acordado | Borrador, firma interna, adenda y publicación con versiones; PDF reproducible; adjuntos privados con límites, validación y controles de seguridad; otra identidad/tenant no descarga por conocer el ID o URL |
| POR-01 | Portal real — frontend + backend | PAC-01, AGE-01, DOC-01 | Paciente o responsable autorizado consulta citas y documentos publicados; retiro y revocación de vínculo eliminan acceso; no se expone documentación interna |
| AUD-01 | Trazabilidad de recorridos integrados — backend + calidad/frontend | ARQ-02; se verifica con cada entrega | Actor real, tenant, sede cuando corresponda, recurso, momento, correlación y cambios disponibles; lecturas sensibles auditadas; sin contraseñas, tokens ni cargas sensibles innecesarias en logs |

### Ola 3 — seguridad, infraestructura y operación

Iniciar diseño y preparativos en paralelo desde la ola 0. La aceptación integral depende de los recorridos reales.

| ID | Paquete y responsable sugerido | Dependencias | Aceptación mínima |
| --- | --- | --- | --- |
| SEG-01 | Modelo de amenazas y permisos — seguridad + arquitectura | ARQ-02 | Matriz de roles/recursos y revisión de sesión, CSRF, orígenes, limitación de intentos, secretos y operaciones privilegiadas; doble factor para cuentas privilegiadas; pruebas de acceso cruzado y vulnerabilidades con evidencia y corrección |
| DAT-01 | Privacidad y ciclo de datos — arquitectura + responsables del producto | ARQ-01 | Políticas de acceso, consentimiento, representación, retención, exportación, baja de tenant y conservación de auditoría; revisión profesional/legal según países de operación; no inventar plazos o requisitos normativos |
| OPS-01 | Entornos y despliegue — operación | ARQ-02 | Desarrollo, pruebas y producción separados; monolito, MySQL y archivos alojados; DNS/TLS y subdominios; tenant resuelto correctamente a través del proxy; secretos fuera del repositorio; privilegios y red restringidos |
| OPS-02 | Copias y recuperación — operación + calidad | OPS-01, contrato de DOC-01 | Copias cifradas de base y archivos; objetivos de pérdida de datos y tiempo de recuperación definidos; restauración probada en un entorno vacío con consistencia de documentos, vínculos y auditoría |
| OPS-03 | Observabilidad e incidentes — operación + backend | OPS-01, AUD-01 | Sonda externa detecta caída total; alertas de errores, correo, almacenamiento y copias; retención y acceso a logs definidos; responsables y procedimiento de incidentes |
| REL-01 | Entrega automatizada y reversión — operación + arquitectura/calidad | QA-01, OPS-01 | Comprobaciones reproducibles antes del despliegue; migraciones compatibles ensayadas; procedimiento probado de reversión de aplicación y recuperación de datos. No asumir que toda migración se puede deshacer |
| QA-02 | Carga y fallos — calidad + backend/operación | Recorridos integrados, OPS-01 | Objetivos de capacidad/latencia definidos; medir concurrencia, conexiones, consultas, paginación, errores y caídas de dependencias; sin doble cobro, dispensación, reserva ni sobrescritura silenciosa |

### Ola 4 — cierre comercial y piloto

| ID | Paquete y responsable sugerido | Dependencias | Aceptación mínima |
| --- | --- | --- | --- |
| COM-01 | Ciclo comercial y caja del alcance inicial — producto + backend/frontend | SAAS-01 | Condiciones de prueba, renovación, vencimiento, mora, suspensión y cancelación definidas y verificadas. Caja clínica integrada si forma parte del piloto. Separar pagos SaaS de pagos asistenciales |
| EXT-01 | Integraciones contratadas — backend + operación/frontend | COM-01; decisión de proveedor y credenciales de prueba | Pasarela, fiscalización, firma certificada o mensajería solo si se requieren para el lanzamiento. Pruebas de proveedor, reintentos, idempotencia, webhooks autenticados y conciliación según integración. Puede diferirse con decisión explícita y operación manual trazable |
| PIL-01 | Aceptación del piloto y autorización de salida — arquitectura + calidad + producto | Paquetes necesarios del alcance, SEG-01, DAT-01, OPS-01/02/03, REL-01, QA-02 | Acta de aceptación funcional y clínica; incidentes críticos cerrados; recuperación ensayada; usuarios capacitados y soporte preparado; autorización explícita antes de usar pacientes reales |

### Etapa posterior — alcance completo

Mantener paquetes separados para hospitalización, camas/jaulas y medicación, cirugía/anestesia, urgencias, diagnóstico/laboratorio/imágenes, farmacia/inventario, terapias y especialidades avanzadas, transfusión, trasplante, reproducción y población veterinaria. Revisar y reutilizar las APIs existentes antes de ampliarlas.

Cada paquete avanzado necesita requerimientos propios, permisos, estados, protocolos, validaciones, integración de UI, pruebas y aprobación clínica. PACS/DICOM, equipos y proveedores no quedan implementados por existir un estado de proceso o una pantalla.

## 7. Reglas técnicas que no se deben romper

1. Mantener el monolito modular. No introducir microservicios ni sustituir la base o el framework sin una decisión justificada y autorizada cuando cambie el alcance acordado.
2. Reutilizar procedimientos y servicios. Las escrituras de negocio pasan por procedimientos parametrizados y transacciones. El usuario de aplicación no debe adquirir permisos de escritura directa para resolver una dificultad de implementación.
3. No modificar migraciones aplicadas. Añadir una versión posterior y probar actualización desde una base existente, además de instalación nueva.
4. Conservar los contratos de errores, revisiones e idempotencia. No reintentar indiscriminadamente escrituras. Guardar claves/revisiones según la operación y mostrar conflictos al usuario.
5. En modo real, roles, tenant, permisos, cuotas y estados proceden del servidor. Un selector de demostración no concede privilegios reales. No aceptar `tenantId` del cliente para elegir una organización arbitraria.
6. Mantener la sesión de navegador con cookie HttpOnly y protección CSRF. No guardar tokens o contraseñas en localStorage. Revisar orígenes, HTTPS y confianza en proxies al cambiar el despliegue.
7. Mantener separados datos demo, datos de prueba y datos reales. Nunca usar localStorage como fuente clínica de producción ni mezclar datos de distintos tenants como solución temporal.
8. El frontend puede permanecer estático mientras el alcance lo permita. No introducir funciones de servidor incompatibles con la exportación sin justificar y probar el cambio de despliegue.
9. Conservar los tres temas, estados de carga/vacío/error/conflicto, accesibilidad básica, navegación móvil y paneles laterales. No reemplazar funcionalidades por avisos de éxito ficticios.
10. No llamar firma certificada, pago procesado, PDF emitido, correo entregado o especialidad validada a una simulación o a una operación interna distinta.

## 8. Revisión obligatoria de cada entrega

El implementador entrega: resumen, archivos o commit, contratos modificados, migraciones, pruebas ejecutadas con resultados, evidencia del recorrido y limitaciones. No pegar secretos ni datos reales en reportes.

El coordinador inspecciona el diff y comprueba:

- Cumplimiento de objetivo y límites del encargo; no se reescribió trabajo ajeno.
- Uso del backend en el modo real y preservación de la demo independiente.
- Autorización en servidor, separación por tenant, membresías y acceso al portal.
- Validaciones, transacciones, revisión, idempotencia y concurrencia aplicables.
- Auditoría y manejo de información sensible.
- Persistencia después de recargar, cerrar sesión y abrir otro navegador, cuando aplique.
- Errores y estados vacíos reales; ausencia de mensajes de éxito que oculten fallos.
- Pruebas suficientes para el riesgo y documentación del contrato actualizada.

Rechazar la entrega con hallazgos concretos cuando falle un criterio. Enviar la corrección al responsable y volver a revisar. Las afirmaciones del implementador no sustituyen la revisión ni la ejecución del recorrido integrado.

Los defectos que permiten acceso entre tenants, pérdida de información, corrupción de historia o duplicación de operaciones críticas bloquean la habilitación del recorrido.

## 9. Verificación reproducible

Ejecutar desde el directorio indicado, después de comprobar dependencias. No repetir suites sin cambios o incidencias que lo justifiquen.

Frontend, desde `frontend`:

```powershell
npm run check
npm test
npm run build
npm run build:demo
```

Las compilaciones Next comparten caché: ejecutarlas secuencialmente. Para comprobar la presentación, iniciar `npm run preview:demo` en otra terminal y después ejecutar `npm run qa:demo`. Se espera que la demo no haga solicitudes a APIs reales.

Backend, desde `backend`, con JDK 21:

```powershell
.\mvnw.cmd -B -ntp verify
```

Integración, desde la raíz y exclusivamente contra un stack de desarrollo/pruebas saludable:

```powershell
python backend/scripts/verify-api.py
python backend/scripts/verify-identity-trace.py
```

Adaptar las pruebas de navegador o crear pruebas específicas de los nuevos recorridos reales. Las pruebas de la demo no prueban la integración clínica real. `frontend/scripts/identity-qa.cjs` cubre el acceso y operación reales existentes; verificar sus precondiciones antes de ejecutarlo.

`backend/scripts/verify-persistence.py` reinicia servicios: usarlo solo en un entorno de pruebas preparado. Una prueba de reinicio no demuestra restauración desde una copia.

Las suites existentes no se deben ejecutar contra producción: crean datos ficticios y algunas cambian el estado global del sistema. No ejecutar en paralelo pruebas que comparten ese estado.

## 10. Criterios de salida de la primera versión

- Un administrador general crea un tenant del tipo contratado, asigna plan y cupos, y el propietario accede al subdominio correcto por HTTPS.
- La organización gestiona sedes, áreas, equipo y perfiles; los límites del plan y permisos se aplican en el servidor.
- Un paciente humano o animal se registra, obtiene una cita, es recibido y recibe atención con el perfil habilitado.
- La atención, gráficos y documentos se conservan y recuperan con sus versiones; cierre, correcciones y publicación respetan reglas y auditoría.
- La historia se comparte entre sedes autorizadas de una organización, y no se filtra a otra organización donde trabaje el mismo profesional.
- El portal muestra únicamente datos autorizados por vínculos vigentes; los permisos se retiran correctamente.
- Las operaciones monetarias o de inventario incluidas en el alcance no se duplican por concurrencia o reintentos.
- La pérdida de un proceso genera alerta; una copia se restaura y el resultado se verifica.
- El piloto y las especialidades habilitadas tienen aceptación documentada; los módulos pendientes se mantienen deshabilitados para uso asistencial.
- Existe autorización explícita de salida. No aprobar producción automáticamente porque las tareas estén marcadas como terminadas.

## 11. Autonomía y límites de ejecución

Continuar con inspecciones, programación local, datos ficticios, correcciones y pruebas del alcance autorizado sin pedir confirmación por decisiones rutinarias. Si falta una preferencia menor, documentar una suposición reversible.

Solicitar decisiones concretas cuando sean necesarias para requisitos clínicos, obligaciones normativas, contratación de proveedor, costos o tratamiento de datos reales. Mientras tanto avanzar en tareas independientes. No inventar respuestas de producto ni aprobación profesional.

Este documento no autoriza gastos, migraciones destructivas en producción, borrado de datos, acceso a pacientes reales, envíos a destinatarios reales ni publicación de una nueva versión asistencial sin autorización aplicable. No modificar la audiencia de servicios publicados ni exponer credenciales. Preparar resultados revisables antes de solicitar aprobaciones finales.

No resetear cambios del usuario ni hacer push forzado. Respetar las autorizaciones vigentes para commits, push y despliegue; no suponer que publicar la demo autorizó una salida clínica a producción.

## 12. Entregables de coordinación y continuidad

El agente de arquitectura mantiene estos archivos conforme haya avances, sin sustituir el backlog por informes repetitivos:

- `docs/produccion/ESTADO.md`: baseline, alcance real, discrepancias, riesgos y brechas verificadas.
- `docs/produccion/TAREAS.md`: tablero con IDs, responsables, dependencias, estados, revisión y evidencia.
- `docs/produccion/DECISIONES.md`: decisiones de contratos, arquitectura y producto, con motivo y consecuencias.
- `docs/produccion/REVISIONES.md`: hallazgos, correcciones y veredicto de cada entrega.
- `docs/produccion/VALIDACION.md`: comandos, entornos, resultados, recorridos y límites de las pruebas.

Cada actualización al usuario debe decir qué recorrido quedó operativo, qué se verificó, qué sigue bloqueado y cuál es la siguiente entrega. No declarar el sistema completo ni listo para producción mientras queden criterios de salida sin evidencia.

Primera acción esperada: ejecutar ARQ-01 y acordar ARQ-02; preparar QA-01 en paralelo si hay capacidad. Después iniciar INT-01 y la primera entrega de SAAS-01. Al retomar el trabajo, leer el tablero existente y continuar sin reiniciar lo ya validado.
