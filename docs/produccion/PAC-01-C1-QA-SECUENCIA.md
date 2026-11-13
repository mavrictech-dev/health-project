# PAC-01.C1: secuencia de QA e instalacion tras preparacion offline

Arquitectura supervisor, 2026-11-12. NO es encargo de ejecucion, permiso de
instalacion o consulta al motor. C1.P2 task_de0b6f78d791/ctx_49d75d51c681 esta
activa preparando tres herramientas offline. Mantener su ownership y esperar
entrega/revision antes de asignar otra tarea al mismo programador.

Somee/AgendlyCitas siguen fuera de alcance. Todos los pasos siguientes son
futuros, locales y sinteticos, con contrato/IDs/hash/ownership propios.
No simular que un gate posterior ya paso ni reusar la etiqueta PASS de API.

## Estado de partida y observabilidad

V14R1 y C2 API aceptadas como fuente offline, API1082tests propios PASS.
V14 NO instalada ni ejecutada en este corte. Jar operativo previo sigue
pinneado y NO contiene la nueva API; no debe usarse como escritor compatible.
No se consulto el estado actual del motor para este documento. Conteos y datos
de E5/V13 son antecedentes, no baselines frescas.

Cada entrega distingue: fuente preparada, SQL compilado/ejecutado, transaccion
finalizada, permisos efectivos, autoridad de negocio, HTTP real y UI real.
Un resultset ACK no confirma commit; un estado observado igual al borrador no
identifica un envio anterior. Stop al primer fallo y resultado incierto sin
reintento automatico. Preservar fallos, comandos y artefactos originales.

## Gate 1: verificador C1.P2 revisado

Antes de delegar una ejecucion PRE: revisar las tres fuentes, hashes/pines,
SQL generado COMPLETO de cada fase, corpus de parser y pruebas de transporte;
comprobar que solo existe modo PRE_APLICACION, sin apply/commit/post operativo.
Contrastar fases contra planes100+38 y marcar cada cobertura parcial/pendiente.
El resultado de pruebas con subprocess doblado valida el controlador, no SQL.

Revisar conservacion de las37tablas y toda metadata requerida, no solo conteos
de SP/ACL. Negativas deben correlacionar error/estado/frame y hashfresh tras
cierre, incluidos timeout/rawexit/doom. Confirmar que una falla de preflight
en un batch no permite ejecutar los siguientes. No aceptar stderr ignorado
por raw0 ni mensajes del motor como prueba de la asercion de negocio.

## Gate 2: UNA ejecucion PRE local y rollback-only

Nuevo contrato de ejecucion acota target/marker/principal, instancias protegidas,
version/compatibilidad, baseline y archivos congelados. No arrancar servicios
desde el runner ni otorgar permisos para solventar un preflight. Si el entorno
no esta preparado, reportar prerrequisito, no conectarse a otra base.

Una sola invocacion PRE autorizada; cada fase usa V14 exacta en TX externa
transient, principals/fixtures propios, SP bajo usuario limitado y rollback.
Baselines nuevas antes/despues y al final deben concordar. No continuidad tras
drift, sintaxis/error inesperado, resultado incierto o falta de cleanup medido.
Supervisor revisa respuestas crudas y deriva una baseline final independiente
acotada para resolver conservacion; no repetir toda QA por rutina.

Es evidencia SQL real secuencial con rollback. No acredita carreras,
persistencia trascommit, frontera contador0 de R1, driverJDBC, pool, auth/CSRF
ni UI. Si falla por representacion de definicion/metadata, congelar evidencia,
diagnosticar por lectura y encargar correccion exacta; nunca relajar hashes
o reparar/aplicar V14 para forzar un PASS.

## Gate 3: backend compatible y aplicacion unica revisada

Solo despues de PRE aceptada preparar un jar compatible en namespace NUEVO,
sin sobrescribir jar/pines de E5. Codigo API exacto validado, migraciones y
dependencias congeladas, startup/flyway/jobs controlados y sin activacion aun.
Preparacion/empaquetado requiere ownership propio y conservar artefactos viejos.
Comprobar procesos antes de aplicar: no dejar escritor viejo activo ni asumir
que el estado de procesos de otra fecha sigue vigente.

Contrato de instalacion fija baseline fresca, hash V14, principal migrador
separado y UNA TX/UNA aplicacion con stop-on-error. No reapply/repair ni retry
ante recibo perdido: reconciliar desde NUEVA conexion y evidencia de definicion/
esquema/ACL/datos antes de decidir otra accion. No ejecutar codigo de pruebas
que incluya instalaciones por efecto lateral.

Delta esperado: +revisionINTNOTNULL/default1/check>=1, ALTERwriter, nuevolector
y2ACL por objeto. Validar firmas/resultsets/definiciones y todos permisos previos.
Para patient_links existentes, comparar la proyeccion de los SEIS campos
anteriores byte a byte y verificar revision1; su hash SELECT* cambiara por la
nueva columna y no puede exigirse igual al hash del esquema anterior. Claves/
filas/scopes/relationship/active previos conservados, resto37tablas igual.
No borrar trazas o reseed de identity para aparentar igualdad.

## Gate 4: R1/POST real, JDBC y persistencia

Contrato/harness separados y revisados. Solo aqui, con V14 instalada y fixtures
propias preparadas por otro gate, puede probarse RPC como primera llamada con
JDBC setAutoCommit(false) y contador0. No anteponer SELECTtabla/SP de negocio
que materialice TX antes del RPC. Instalar/limpiar contexto no debe ocultar el
estado inicial que se pretende medir. Probar writer y edit_get tras commit y
rollback, TX explicita, autocommit y doom con conexiones frescas, reutilizacion
fisica del pool y errores de reset. No inferir propiedades del driver a partir
de toggles SQL dentro de una transaccion ya abierta.

Usar runtime/bootstrap existentes solo con identidad/permisos efectivos
verificados y credenciales protegidas por mecanismos ya aprobados; nunca en
argv/log/env global o runtimeconCONTROL. Fixtures propias con IDs/requests/
cutoffs nuevos, sin reutilizar E5/PACQA. Si hay commits sinteticos, conservar
el historial y definir su postestado esperado: no prometer baseline totalmente
igual ni cleanup por borrado de auditoria. Sesiones propias se revocan segun
contrato; filas previas quedan protegidas por hashes/proyecciones separadas.

## Gate 5: dos conexiones y revocacion despues de commit

Misma expectedRevision con dos conexiones independientes, create/create,
edit/edit y retirar/reactivar: una aceptacion y un conflicto sin cambios/audit
semantico del perdedor. Registrar TX/requests/version/filas/eventos y limites
de timeout/deadlock; no retry oculto ni llamar carrera al caso secuencial stale.

Contrato de barreras debe observar que la segunda llamada llego al servidor
mientras la primera retiene locks antes del commit, no solo una tarea cliente
programada o un sleep. Una sonda administrativa readonly de solicitudes/esperas
puede servir si sus permisos YA existen y quedan verificados. No otorgar VIEW
STATE u otro permiso de instancia implicitamente; sin observabilidad requerida,
marcar la limitacion o bloquear ese control, no afirmar bloqueo probado.

Probar cambios actuales de usuario/sesion/membresia/plan/estado de fixture en
fronteras definidas. READ_ONLYglobal necesita gate propio y restauracion exacta
del estado de entorno; no modificarlo desde PRE ni contar OPEN como negativo.

Para revocacion: nuevas autorizaciones portal posteriores al commit deben negar
los consumidores pertinentes (pacientes/documentos/citas/saldo/reserva y demas
enumerados en C0) con guardas de modulos independientes. No afirmar retirada
de copias descargadas ni cancelacion retroactiva de operacion ya autorizada.
Definir fixtures propias y contrato de cambios antes de ejecutar esos flujos.

## Gate 6: HTTP y gestion visual

Jar nuevo + datasource runtime limitado + TLS local ya aprobado, sin cambiar
la instancia. Auth/cookie/CSRF reales, errores/versiones y auditoria por request,
conservacion de datos previos y cleanup de procesos medidos. MockMvc sigue
siendo evidencia aparte. UI/candidatos/contactos necesitan contratos/ownership
propios; alta de responsable no crea automaticamente identidad o permiso portal.

La secuencia no cierra ninguno de estos gates por si misma. Produccion, Somee,
publicacion/main/gastos/datos o destinatarios reales permanecen sin autorizacion.
