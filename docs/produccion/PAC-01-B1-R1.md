# PAC-01.B1.R1: corregir transporte de la prueba preparada

Encargo supervisor del 2026-11-09. Continuacion de task_c53c79f7a74c,
ctx_a5d34612a3a6, entrega msg_f58faa64e89c. Resultado de revision: DEVUELTA.
La propuesta V13 supera la lectura estatica del contrato, pero no esta aceptada,
compilada, instalada ni integrada. La matriz SQL sigue pendiente.

## Hallazgos comprobados por el supervisor

El controlador incluido en verify-sqlserver-patient-links-read.sql usa juntos
`-h -1` y `-y 0`. El sqlcmd instalado rechaza esa combinacion antes de conectar:
`The -h and the -y 0 options are mutually exclusive.` Salida1. Conservar -y0
para no truncar JSON largo; eliminar la opcion incompatible y verificar framing.

Con opciones corregidas, el SELECT readonly de metadatos por TCP con Windows
Integrated falla `Cannot generate SSPI context`. La misma consulta por
`lpc:.\HEALTHPROJECTQA` responde instanciaHEALTHPROJECTQA, base aislada esperada,
principaldbo y CONTROL1. Evidencia supervisora local:
tmp/pac-01-b1-20261109/review/transport-probes.json. No se modificaron objetos,
filas, permisos, servicios, certificados ni autenticacion para diagnosticarlo.

## Ownership y restricciones

Leer AGENTS.md absoluto del supervisor D:/Mavric/Health Project, su flujo y los
contratos PAC-01-B1.md/D-87/D-87.A antes de editar. Supervisor unico escritor
de documentos/tablero. Programador recuperapiura@gmail.com en terminal retenida
term_493e985d-a5b9-4230-942c-edd10b53f8ef y su worktree health-programmer.
Preservar las670fuentes anteriores y todas las rutas locales historicas.

Editar SOLO backend/scripts/verify-sqlserver-patient-links-read.sql.
V13__patient_links_read.sql debe conservar SHA256
CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060.
Sin Java/frontend/config/migraciones anteriores ni nuevas rutas de producto.
No commit/push/reset/stash/main/FactuEz, cuentas globales ni sesiones ajenas.

Fijar transporte administrativo Windows Integrated a lpc:.\HEALTHPROJECTQA,
manteniendo DB/marcador/instancia/CONTROL/TX/roles estrictos. Esto NO modifica el
runtime JDBC TCP ni credenciales. No fallback de instancia, servidor remoto,
password/env/DPAPI, cambios SSPI, UAC/TLS, configuracion o servicios.

Conservar fases PRE_APLICACION y AUTOCOMMIT_POST_APLICACION, source pin V13,
40casos, guardas, fingerprint completo y fail-closed de stderr/exits. No relajar
baselines ni aceptar salida truncada o errores no reconocidos para obtener PASS.

## Validacion autorizada en este Dispatch

Revision estatica/AST y regresiones offline del argv REAL construido por invoke:
destinoLPC fijo, DB fija, entorno minimo, sin par -h/-y0 incompatible, sin secretos;
framing largo unicode/malformado/lineas extra y errores se conservan estrictos.
Las pruebas deben observar argumentos de subprocess, no duplicar una lista ideal.
Conservar reporte/harness temporal si hace falta, sin tercera ruta de producto.

Se autoriza UN probe readonly con el invoke corregido y su entorno minimo contra
la misma QA: SELECT metadatos de instancia/base/principal/CONTROL/marcador y una
respuesta JSON sintetica Unicode de mas de4000caracteres para verificar transporte,
decodificacion y frame sin truncado. Sin leer/exportar filas de negocio, sesiones,
tokens o credenciales. Guardar solo metadatos seguros, largo y SHA del payload.
No ejecutar main del controlador ni PRE/POST, CREATE/ALTER/GRANT/INSERT/UPDATE/DELETE,
EXEC de SP de negocio, fixtures, transacciones de instalacion ni aplicacionV13.
Si falla el probe, detener y reportar el error; no reintentos/cambios de entorno.
No suites Java/Next/demo ya aprobadas, al no cambiar su alcance.

## Entrega

Informe TEMP con SHA antes/despues, V13 inmutable, delta de ownership/baseline,
pruebas offline, argv sanitizado y resultado del UNICO probe readonly. Distinguir
READONLY_TRANSPORT_PROBE de NO_V13_SQL_EXECUTED y NO_MATRIX_EXECUTED. Sin reclamar
compilacion/negocio/permisos de motor comoPASS. Procesar/ack lotes antes de done.
Entregar succeeded EN_REVISION si la correccion esta completa y probePASS;
si existe bloqueo real, failed con evidencia y sin ampliar alcance.
Conservar terminal y sesion.
