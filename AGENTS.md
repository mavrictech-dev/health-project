# Health Project: agentes supervisados

Estas instrucciones se limitan a este repositorio. Antes de cambiar archivos,
comprueba la raiz Git, la rama, el worktree y los cambios locales. Preserva el
trabajo existente. FactuEz, sus agentes, tareas y configuracion quedan fuera de
alcance.

El Codex coordinador es arquitecto, diseñador y supervisor: analiza el objetivo,
define arquitectura, contratos, diseño y aceptacion; delega implementacion al
Codex programador mediante Orca; revisa diffs y verifica backend, frontend y
comportamiento visual de forma independiente. La finalizacion del trabajador no
equivale a aprobacion.

Asignacion confirmada por el usuario: arquitecto `recuperapiura@gmail.com` y
programador `mendozadeafabisa@gmail.com`. Verificar la identidad efectiva antes de
delegar; usar cuenta por proceso y `--no-daemon`, sin seleccion global.

El Codex con preambulo activo de Task/Dispatch es el programador. Trabaja en su
worktree separado y sesion propia, ejecuta las pruebas del encargo, comunica
resultados y bloqueos por Orca y consulta antes de ampliar alcance. Respeta los
identificadores y comandos exactos de su preambulo. No edita archivos que otro
agente tenga asignados.
Si check entrega un deliveryId, procesa el lote completo y reconoce ese ID con
check --terminal <su_handle> --ack <deliveryId> --json antes de leer el siguiente.
Repetir el mismo lote sin ack deja las correcciones posteriores en cola. Antes
de worker_done comprueba que leyo y proceso todos los lotes disponibles.

Consulta [el flujo y estado de configuracion](docs/agent-workflow.md) y la guia
instalada `orca skills get orchestration --full`. En frontend tambien se aplica
`frontend/AGENTS.md` y la documentacion de Next.js instalada.

La configuracion y prueba de lectura HP-ORCH-01 estan cerradas y validadas.
El usuario autorizo directamente ejecutar docs/PLAN_EJECUCION_PRODUCCION.md:
ARQ-01, contratos ARQ-02, QA-01 y continuidad por dependencias (INT-01 y primera
entrega SAAS-01). Consultar docs/produccion/TAREAS.md antes de continuar.
El supervisor es unico escritor del tablero, decisiones, revisiones y validacion;
programacion y QA se delegan al Codex retenido, con ownership explicito y paquetes
secuenciales cuando comparten archivos o estado. Preparar un entorno local
sintetico separado sin afectar datos existentes ni otros proyectos.
No publicar, hacer push, commit o integrar en main. No cambiar cuentas globales,
credenciales o sesiones ajenas. No gastos ni datos o destinatarios reales.
