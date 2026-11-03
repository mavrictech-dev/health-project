# Orquestacion Codex de Health Project

Registro: 2 de noviembre de 2026. Configuracion y auditoria HP-ORCH-01 cerradas.
El encargo directo posterior autoriza ejecutar ARQ-01, ARQ-02, QA-01 y continuar
por dependencias del plan. No autoriza commit, push, integracion en main,
publicacion, gastos ni datos reales. Continuidad: docs/produccion/TAREAS.md.

## Repositorio y ownership

- Supervisor: D:/Mavric/Health Project, rama main.
- Repo Orca: ee1698f8-5503-4327-b680-747877f83eb3.
- Proyecto: github:mavrictech-dev/health-project.
- Base: 0b24487c77055a081f6e76f0b18bc544ce4b1958.
- Worktree programador: C:/Users/maxmo/orca/workspaces/Health Project/health-programmer.
- Rama programador: Maczz09/health-programmer; common-dir del supervisor.
- Instrucciones: [AGENTS](../AGENTS.md), [frontend](../frontend/AGENTS.md),
  [plan del usuario](PLAN_EJECUCION_PRODUCCION.md).

Antes de editar: comprobar raiz, rama, worktree y cambios locales. FactuEz y sus
agentes/archivos/configuracion estan fuera de alcance. No cambiar cuentas
 globales ni sesiones ajenas. Los documentos/scripts del setup siguen sin commit;
el worktree separado no los hereda automaticamente.

README.md y docs/PLAN_EJECUCION_PRODUCCION.md son cambios previos del usuario,
preservados. SHA256 protegidos:

```text
README.md 155FCF62BCFDDCAA66B9C5DDA346DE0D3253CBD0A1093723C900DE0BFE501255
docs/PLAN_EJECUCION_PRODUCCION.md 4788BE3FC537E874CDC72139E8698D361B57B06540A0EA9D69E9EFDCDAB240F4
```

## Cuentas y sesiones confirmadas

| Rol | Cuenta efectiva /status (Plus, openai) | Terminal | Session/thread |
| --- | --- | --- | --- |
| Arquitecto, disenador y supervisor definitivo | recuperapiura@gmail.com | term_709fd00e-0d6c-43a1-a389-50b301fac103 | 01a19e4c-2bd7-70e3-b912-c51552262383 |
| Programador | mendozadeafabisa@gmail.com | term_e7f890b4-e2a1-41d2-a943-417ed772f2ab | 01a19e4c-15af-74e0-a1b9-75fc7093b98f |

La instaladora verifico ambos /status antes de la delegacion. En esta sesion el
supervisor volvio a leer el /status conservado del programador y contrasto su
propio session/thread por entorno, IdentityOnly y procesos. La instaladora sigue
siendo otra conversacion en mendozadeafabisa; no cambio de cuenta ni se presenta
como arquitecto definitivo.

Cuenta administrada Orca: 56f09e5c-eecb-404f-96c1-ac72fa3882f5. Home programador:
C:/Users/maxmo/AppData/Roaming/orca/codex-accounts/56f09e5c-eecb-404f-96c1-ac72fa3882f5/home.
Home supervisor: C:/Users/maxmo/.codex. En cada proceso CODEX_HOME y
ORCA_CODEX_HOME coinciden con su home, ORCA_CODEX_ISOLATE=1. Procesos codex.exe
observados: PID 20992 y 25936, ambos --no-daemon, padres distintos. Son PIDs de
esta observacion, no handles permanentes. No se uso servidor compartido/remoto,
resume, login/logout, copia de credenciales o seleccion global.

## Lanzadores verificados

Orca 1.4.229; Codex 0.166.0. Se leyo `orca skills get orchestration --full`,
incluidas coordinator-loop, low-level-topology, messaging, legacy y recovery.
Un Run actual seleccionado prevalece sobre fallback legacy. El rebind se hizo
desde la nueva terminal, sin takeover-legacy.

[start-health-agent.ps1](../scripts/start-health-agent.ps1) valida origin,
raices, common-dir, colocacion por rol, identidad almacenada y --no-daemon.
Establece variables solo en el proceso y las restaura al salir.
[start-programmer.ps1](../scripts/start-programmer.ps1) conserva el wrapper de
rol programmer. El arranque previo del arquitecto se confirmo en su shell Orca:

```powershell
& 'D:/Mavric/Health Project/scripts/start-health-agent.ps1' -Role architect -WorktreePath 'D:/Mavric/Health Project' -CodexHome 'C:/Users/maxmo/.codex' -ExpectedEmail 'recuperapiura@gmail.com'
```

En esta sesion se ejercitaron realmente ambos puntos de entrada, sin relanzar:

```powershell
& './scripts/start-health-agent.ps1' -Role architect -WorktreePath 'D:/Mavric/Health Project' -CodexHome 'C:/Users/maxmo/.codex' -ExpectedEmail 'recuperapiura@gmail.com' -IdentityOnly
& './scripts/start-programmer.ps1' -WorktreePath 'C:/Users/maxmo/orca/workspaces/Health Project/health-programmer' -CodexHome 'C:/Users/maxmo/AppData/Roaming/orca/codex-accounts/56f09e5c-eecb-404f-96c1-ac72fa3882f5/home' -ExpectedEmail 'mendozadeafabisa@gmail.com' -IdentityOnly
```

Resultados nuevos: parser sin errores en ambos scripts; identidad correcta en
ambos; rechazo de programador en checkout principal, arquitecto en worktree
separado y correo incorrecto. No fue necesario corregirlos. IdentityOnly acredita
identidad almacenada; /status y Dispatch acreditan la efectiva. Referencia:
[CLI oficial](https://learn.chatgpt.com/docs/cli/reference) y
[CODEX_HOME](https://learn.chatgpt.com/docs/config-file/environment-variables).

worker-start --agent no permite elegir cuenta por invocacion. Por ello se
reutilizo el Codex ya iniciado con lanzamiento personalizado y --terminal,
conforme a low-level-topology; no dispatch --inject, agentes ni worktrees nuevos.

## HP-ORCH-01: entrega y aceptacion independientes

- Run existente: run_624b9269b491, legacy=0, consumer_generation=2.
- Coordinador anterior: term_62da138c-7a85-4e00-b0bb-e279bce69408.
- Coordinador actual: term_709fd00e-0d6c-43a1-a389-50b301fac103.
- Task existente: task_849a0e30b253 (HP-ORCH-01).
- Dispatch unico: ctx_06e3adc9a15a.
- Resource wtr_a7ea72c0fc25: ownershipState external por terminal preexistente.

Comandos realmente utilizados tras leer spec completa:

```powershell
orca orchestration run-use --id run_624b9269b491 --json
orca orchestration task-list --run run_624b9269b491 --json
orca orchestration worker-start --run run_624b9269b491 --task task_849a0e30b253 --worktree 'id:ee1698f8-5503-4327-b680-747877f83eb3::C:/Users/maxmo/orca/workspaces/Health Project/health-programmer' --terminal term_e7f890b4-e2a1-41d2-a943-417ed772f2ab --json
orca orchestration check --run run_624b9269b491 --wait --types 'worker_done,escalation,question' --timeout-ms 45000 --json
orca orchestration worker-show --dispatch ctx_06e3adc9a15a --json
orca orchestration worker-read --dispatch ctx_06e3adc9a15a --source auto --limit 12 --json
orca orchestration worker-list --run run_624b9269b491 --include-remote --json
```

worker-start devolvio outcome_unknown/turn_start_unobserved: entrada aceptada,
inicio no observado en 30 s. No se reintento ni abandono. Fleet, terminal y
transcript demostraron live y trabajo efectivo. Los timeouts fueron checkpoints.
Seguimiento por Dispatch msg_ccb501b28774 solicito evidencia de aislamiento.

Mensajes: inicio msg_21ee2c5145a1; bloques 1-4 msg_d8f0f457f19f,
msg_a2f42fb47031, msg_c3097643a3aa, msg_c961afc36be9; worker_done
msg_66a6758649a4, succeeded, 2026-11-02T22:13:52Z. Task y Dispatch completed
automaticamente; no se hizo task-update completed.

Informe: monolito modular Spring/JDBC/MySQL; Next16.4.3; contratos HTTP/DTO/SP;
separacion mock/live; 30 casos TS mock y 10 Java; suites reales y prerequisitos.
Cero archivos modificados; sin instalaciones, builds, suites o Docker. Git
inicial/final limpio en worktree, base/raiz/common-dir contrastados por supervisor.

Brechas estaticas: Compose monta out sin construir frontend y comparte nombre,
puertos y volumen entre worktrees si no se aisla; QA antigua supone otra entrada;
qa:visual puede registrar errores sin fallar; identity-qa cambia estado global
sin restauracion OPEN en finally; TS mock y DTO live difieren; historia con
limites sin paginacion completa; unitarias no prueban integracion/SQL; setup.ps1
requiere verificar APIs .NET modernas en PowerShell5.1. No se corrigieron durante
setup ni se presentan como resultados de ejecucion.

**Supervisor: VALIDADA exclusivamente la auditoria HP-ORCH-01.** Decision separada
de completed: se contrastaron API, HostFilter, Sql, Idempotency, controladores y
servicios de agenda/sesion, Next instalado, suites, scripts y reportes. No acredita
integracion real ni habilitacion clinica o produccion.

Deliveries procesadas antes de ack: delivery_090717c217e7,
delivery_e6f489cfa80d, delivery_8d106b05efda, delivery_82398e897906 y final
delivery_8581213194bb. La cuarta contenia la ampliacion remitida por instaladora;
el usuario la confirmo despues mediante encargo directo. Antes del ack final:

```powershell
orca orchestration worker-retain --dispatch ctx_06e3adc9a15a --json
orca orchestration check --run run_624b9269b491 --ack delivery_8581213194bb --json
orca orchestration worker-list --run run_624b9269b491 --terminal-state reclaimable --json
```

Retencion efectiva: retained, reason=user_requested, processAction=none,
archive=null, releaseState=retained. Cero reclaimable, buzon vacio al cerrar
setup. Pareja y worktree disponibles; ningun agente/instaladora fue cerrado.

## Evidencia previa frente a esta sesion

| Ejecucion previa de instaladora en este encargo | Resultado |
| --- | --- |
| npm run check | Correcto |
| npm test | 30/30 mock |
| mvnw verify | 10/10 unitarias; cero fallos/errores/omitidas |
| build:demo | 82 paginas |
| qa:demo | 13 recorridos; cero API real/errores JS |
| Smoke | Spinner/disabled, error conserva revision, retry, menu movil y 390/390 |
| Red/consola | Cero console/page errors, HTTP >=400 y fallos no cancelados; 24 ERR_ABORTED registrados aparte |
| Docker | Pipe dockerDesktopLinuxEngine ausente; integracion real no verificada |

El smoke temporal inicial fallo por selector Procesando; se corrigio y repitio,
sin cambios de producto. Preview propio3012 ya estaba detenido. No se inicio ni
reinicio Docker durante HP-ORCH-01.

El supervisor inspecciono con view_image [portada](../frontend/test-results/orchestration/desktop-home.png),
[error](../frontend/test-results/orchestration/desktop-simulated-error.png) y
[movil](../frontend/test-results/orchestration/mobile-patients.png). Portada
legible; panel derecho/fondo desenfocado/error con datos conservados; tabla movil
dentro del ancho, algunos contactos largos recortados. Revision limitada a esas
capturas. Leyo [smoke](../frontend/test-results/orchestration/smoke.json),
[demo QA](../frontend/test-results/review-qa.json) y tres Surefire (3+1+6=10).
No repitio esas suites ni las atribuye a ejecucion nueva. Son comprobaciones
nuevas la lectura independiente, Git, identidades/procesos, parser y casos
negativos del lanzador. Recibo: [architect-setup-result.json](../tmp/architect-setup-result.json).

## Continuidad autorizada

Objetivo → analisis/diseño → contrato/aceptacion → paquete Orca → revision
independiente → correccion → verificacion. Supervisor unico escritor de tablero,
decisiones, revisiones y validacion; programador recibe archivos concretos en su
worktree. Programacion y QA se secuencian cuando comparten archivos/estado.
Usar nuevos Dispatch para encargos posteriores, nunca los IDs ya asentados.
Tanto coordinador como trabajador procesan todo Delivery recibido antes de ack.
En el trabajador: check --terminal <su_handle> --json; si hay deliveryId, atender
todos sus mensajes y despues check --terminal <su_handle> --ack <deliveryId>
--json; repetir hasta vacio. INT-01.A evidencio que un lote sin ack se repetia y
dejaba correcciones nuevas pendientes. Una entrega asentada con defectos se
devuelve mediante nuevo Dispatch; no reutilizar sus IDs.
Mantener monolito, SP parametrizados/transacciones, tenant/roles del servidor,
revision/idempotencia y demo independiente. Consultar Next instalado antes de
escribir frontend. La integracion real exige entorno sintetico aislado; no
atribuir evidencia MySQL a mocks. El nuevo encargo permite preparar ese entorno
local sin afectar datos existentes, otros proyectos o produccion.
