# HP8.QA.P1: revision y correcciones del programador

Peticion directa del usuario: «delega al programador». El supervisor conserva
arquitectura, tablero, decisiones, revision e integracion. Este paquete es una
segunda revision de la entrega existente, no una nueva implementacion desde cero.

Base revisada: `8a6a6aeab6c40a3ec114e0175289b75e7a3022e4`, rama
`health/production-wave0`. RUC y HP4-7 ya entregados; HP8 tiene validacion local
documentada. Somee sigue pendiente de conexion exclusiva Health Project.

Programador: recuperapiura@gmail.com, identidad efectiva comprobada en /status,
sesion 01a1d797-f52b-70e2-90bc-66a6b1a23e51; cuota observada 100% de 5h y
84% semanal. Lanzador por proceso con --no-daemon, sin seleccionar cuenta global.
Workspace nuevo creado por Orca desde la entrega actual para preservar el viejo
worktree con cambios locales. No reutilizar el dispatch RUC abandonado ni marcarlo
completado. Terminal nueva: term_6a081686-cdd7-4c83-94fe-740422ddd83c.

## Encargo y aceptacion

1. Leer AGENTS.md, frontend/AGENTS.md y las guias Next instaladas pertinentes.
   Comprobar raiz, rama, worktree, HEAD y estado antes de editar. Leer
   docs/produccion/HP8-AGENDA-20261113.md y entregables/trello/hp8/TAREAS_TRELLO.md.
2. Revisar HP8 contra el pedido: calendario diario/semanal; reserva por horario;
   paciente existente/nuevo; voz Nombres-Apellidos-Nacimiento-Horario; revision
   explicita antes de reservar; cobro pendiente/pagado/medio y arqueo por sucursal.
   Verificar manual cuando falla voz, aislamiento de tenant/sucursal, roles,
   concurrencia, idempotencia y fechas/zona horaria. Revisar regresiones RUC y HP4-7.
3. Corregir defectos reproducibles dentro del ownership, con pruebas que acrediten
   la correccion. No cambiar comportamiento aceptado solo por preferencia.
4. Ejecutar Maven verify offline, pruebas frontend y typecheck/build pertinentes
   en su propio worktree. Capturas desktop/movil de las vistas HP8 y flujos
   corregidos. Voz simulada debe identificarse como tal; no presentarla como audio
   fisico. No repetir pruebas reales de BD ni setup en este primer paquete.
5. Entregar informe con requisito -> evidencia, hallazgos/severidad, diff y pruebas
   con comandos/codigos de salida, rutas de capturas y SHA de base/fuentes.
   Informar fallos reales; un exit distinto de cero en verificaciones requeridas
   deja el paquete fallido o parcial. No declarar Somee ni proyecto productivo listo.

## Ownership exclusivo del programador

Solo su nuevo worktree
`C:/Users/maxmo/orca/workspaces/Health Project/health-programmer-hp8-review`:

- frontend/src/components/runtime-agenda.tsx y agenda-voice.tsx;
- frontend/src/lib/agenda.ts;
- frontend/src/styles/live-agenda.css;
- frontend/src/mocks/agenda-api.ts;
- frontend/tests/agenda.test.ts y agenda-api-transport.test.ts;
- frontend/scripts/agenda-trello-qa.cjs;
- backend/src/main/java/com/mavric/healthcards/AgendaController.java;
- backend/src/test/java/com/mavric/healthcards/AgendaControllerTest.java;
- informes, harnesses y capturas nuevas bajo tmp/hp8-programmer-review/.

Puede leer el resto del repositorio. Instalar dependencias fijadas por lockfile
solo en su worktree y usar caches existentes; no modificar dependencias del root.
Para ampliar archivos de producto o introducir una migracion, enviar ask al
supervisor con motivo y evidencia; no solicitar permiso al usuario para pasos
rutinarios ya autorizados. El supervisor es unico escritor de docs, tablero y
entregables finales; no sobrescribir capturas aprobadas.

## Limites

Sin commit/push/merge/despliegue, sin cambios al checkout supervisor o al viejo
worktree, sin reset/clean, sin otras cuentas/agentes/proyectos. SQL Server2022 y
100% acceso runtime por SP parametrizados, principal EXECUTE-only. No editar
migraciones aplicadas V1-V19. No conectar Somee/AgendlyCitas, instalar/reaplicar BD,
parar servicios o tocar contenedores. Solo datos sinteticos; sin cargos, correo o
destinatarios reales. No volcar secretos ni auth.json. Si necesita QA SQL real,
proponer el paquete y destino al supervisor y finalizar este primer corte.

Comunicar por Orca usando los Task/Dispatch del preambulo. Procesar el lote completo
y ack de cada deliveryId antes de leer otro; antes de worker_done comprobar todos
los lotes. Un resultado del trabajador requiere revision independiente del
supervisor antes de integrarse. Devolver tambien los pendientes siguientes del
plan en orden, sin implementarlos en este paquete.
