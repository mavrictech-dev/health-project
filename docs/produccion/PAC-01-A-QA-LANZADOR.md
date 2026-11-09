# PAC-01.A.QA.L1: entorno Windows del lanzador de navegador

Encargo supervisor9nov tras E1 fallida: task_c0871e7d4bb8 / ctx_e57613f2dc29,
readonly rawExit1, attempt1794242208475. No fase de escrituras, login o directorio
completados. Conservar fallo; no reejecutar E1 en este encargo.

## Causa comprobada independientemente

Wrapper supervisor tmp/patients-real-env-20261109/run-qa-reviewed.py utiliza
A66.environment para el proceso Node. Esa allowlist es correcta para SQLcmd pero
omite las rutas Windows de instalacion de Edge. Probe de navegador sin credenciales
ni paginas falla con distributionmsedge notfound, ruta undefined/ProgramFiles.
Agregar SOLO PROGRAMFILES, PROGRAMFILES(X86), LOCALAPPDATA a esa allowlist en el
entorno de ese proceso permite launch/close raw0, sin editar entorno padre ni
helpers SQL. Evidencias browser-launch-probe-*.json en el mismo directorio.
No instalar/reinstalar Edge, Playwright, paquetes o modificar cuentas globales.

## Ownership y resultado esperado

Crear exclusivamente en tu worktree:

- scripts/run-patients-real-qa.py (nuevo)
- scripts/tests/test_patients_real_qa_launcher.py (nuevo)

Leer AGENTS.md absoluto del supervisor, guia Orca y PAC-01-A-QA-EJECUCION.md.
Los622 archivos del baseline E1 y runnerfrontend SHA1BB53685...8FE32,12tests y8SHA
A/R1 permanecen intactos. No editar wrapper temporal del supervisor, documentos,
Java/frontend/SQL/configuracion o otras rutas. Supervisor unico escritor de docs.

Versionar el lanzador revisado, reutilizando el flujo de
D:/Mavric/Health Project/tmp/patients-real-env-20261109/run-qa-reviewed.py completo,
con guardas iguales o mas estrictas y entorno ESPECIFICO para Node/Playwright:

SYSTEMROOT,WINDIR,SYSTEMDRIVE,TEMP,TMP,PATH,COMSPEC,PATHEXT,PROGRAMFILES,
PROGRAMFILES(X86),LOCALAPPDATA. Comparacion de nombres case insensitive; sin
heredar otras variables ni mutar os.environ. Preservar rechazo de variables
SQLCMD hostiles. No cambiar A66.environment ni usar una herencia global completa.
Solo se pasan rutas Windows; nunca passwords, auth, CODEX_HOME o credenciales.

Mantener CLI limitada a --readonly / --allow-synthetic-writes, runner SHA exacto
aprobado1BB53685CF5B375B434D75DABE8BD61260672E167C5EADBC0271B1DBF0D8FE32,
job fijo tmp/patients-real-env-20261109 bajo checkout del propio script (no argv
para seleccionar otra ruta/credenciales), manifiestoDPAPI fijo y su SHA aprobado
en environment-readiness.json, runIdpacqa-20261109-a1 y DB aislada exacta.
No transportar credenciales mediante argv/env/archivos planos/logs. InputNode
solo stdin en memoria, stdout/stderr capturados y filtrados, no volcar errores
crudos; comprobar que ningun password se encuentre en salida antes de publicar
resultado. Cualquier fallo inesperado o timeout raw no cero; preservar attempt.
Cerrar procesos propios ante timeout sin dejar procesos Node/browser del runner;
no matar procesos por nombre ni tocar procesos ajenos. No limpiar datos.
Si garantizar esto exige mas alcance, consultar antes de ampliarlo.

## Validacion offline y entrega

Import inerte sin leer stores/manifiestos operativos o iniciar Node/browser/red.
Pruebas unitarias de allowlist/casing, exclusion de secretos y entorno padre
intacto; flags/rutas/pines/resultado filtrado; hash invalido falla ANTES de DPAPI;
manifestscope invalido o stdoutconsecretos rechazados, salidas/norespuesta/timeout
de modelo. Usar fixtures ficticias e inyeccion/mocks locales. No descifrar DPAPI
operativo ni ejecutar script real contraQA: supervisor lo revisara e integrara
antes de retry de E1 en otro Dispatch. No repetir build/demo/frontend sin cambios.

Informe TEMP: resumen del delta respecto del wrapper revisado,2SHA, baseline y
evidencia de cero cambios fuera de ownership, comandos/exit/resultados, limites.
Conservar sesion, procesar/ack todos los lotes antes de done. Entrega EN_REVISION,
no aprobacion ni QA de negocio. No SQL/servicios/UAC/TLS/main/push/commit/FactuEz.
