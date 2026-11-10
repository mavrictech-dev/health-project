# PAC-01.B1.R2: separar captura de estado transaccional

Contrato preparado el2026-11-09, actualizado por supervisor el2026-11-10 para
continuar por encargo directo del usuario. Orca recupero el Dispatch E1 como
abandoned/terminal_missing/outcome failed; el supervisor asento la Task E1 failed
con su informe existente. No hay worker_done historico ni se lo inventa. El
intento fallido anterior queda cerrado administrativamente, sin repetir su SQL.

Programador retenido actual verificado por /status:
term_7286bcc6-6224-4d5f-a389-b06a09939ca3, recuperapiura@gmail.com,
session01a1c5c7-d534-7d01-ac3a-c18bf31075ec, mismo worktree health-programmer.
Proceso --no-daemon confirmado. Usar SOLO los Task/Dispatch de tu nuevo preambulo,
no los IDs historicos E1/R1. Run existente run_624b9269b491, no crear otro.
Cuota disponible limitada: paquete pequeno y pruebas enfocadas, sin suites ajenas.

## Evidencia y causa

E1 una sola ejecucion PRE_APLICACION,0/40fases, falla BASELINE_FAILED en primer
baseline: SQLcmd exit16,Msg59999 Level16 State1 Line17 de COMMON. No se envio
ninguna fase de instalacion/fixtures, ni POST. Informe TEMP B1E1-programmer-report.
Congelado en tmp/pac-01-b1-20261109/engine-review bajo checkout supervisor.

COMMON mezcla @@TRANCOUNT/XACT_STATE con HAS_PERMS_BY_NAME/IS_ROLEMEMBER en un IF.
Diagnostico supervisor de solo lectura captura estadoexterno0/0; el predicado
combinado rechaza y el mismo control con estado capturado por separado acepta.
Sin quitar CONTROL o guardas de roles. Resultado guard-evaluation-diagnostic.json.
Es la regresion ya descrita para A62 en TAREAS.md: no interpretar estado observado
dentro de expresiones de metadatos como transaccion externa del llamador.

Segundo diagnostico de catalogo confirma V13 ausente,133SP,562ACL y0usuarios B1.
Sus valores inline count2/state1 son del contexto de expresion, no prueba de TX
externa; el estado fiable esta en las variables standalone del diagnostico.
No se obtuvo fingerprint de negocio completo: no afirmar igualdad antes/despues.

## Alcance de la futura correccion

Leer AGENTS.md absoluto, flujo, PAC-01-B1/R1/QA-E1 y D-87 desde supervisor.
Programador mismo worktree; supervisor unico escritor de documentos/tablero.
Ownership SOLO backend/scripts/verify-sqlserver-patient-links-read.sql.
Conservar V13 SHA CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060.
Base SQL de prueba D1CDE92664B7875029421F84E6C74968366602DA206678BFC24139AC351AC970.

Capturar @@TRANCOUNT/XACT_STATE en variables standalone antes de evaluar
consultas de catalogo/permisos o tablas; usar esa captura en la guarda correspondiente.
Revisar COMMON y la guarda runtime/autocommit de POST, ademas de cualquier
assert transaccional combinado con SELECT. Cada captura debe pertenecer al punto
que valida (despues de BEGIN/impersonacion/lectura segun caso), nunca reutilizar
estado antiguo como si fuera actual. No relajar pre0/0,TXexterna1/1,CONTROL,
separacion de roles ni la guarda transaccional del SP. No cambiar V13/helpers
aceptados,40casos,errores,framing,ACL,baseline,fixtures o contrato de permisos.

Regresiones offline deben inspeccionar el SQL realmente generado en COMMON/PRE/
POST y rechazar reintroducir estado inline junto a lecturas/metadata. Mantener
regresiones argvLPC/-y0 y parserestricto. Evidencia TEMP, sin tercera ruta producto.
HEALTHPROJECTQA esta DETENIDA al verificar el10nov. Este Dispatch autoriza SOLO
edicion del verificador y regresiones offline. NO SQL, ni probe readonly ahora,
ni iniciar servicios/UAC. Preparar un probe futuro con COMMON corregido y frame
constante para revisar despues; no ejecutarlo. No PRE/POST/matriz/DDL/DML/COMMIT
ni instalacion. No leer DPAPI/credenciales/API. La falta del entorno de motor es
PENDIENTE conocido, no un PASS ni motivo de falsear prueba de integracion.
Un nuevo intento de motor requerira revision y otro encargo.

Conservar670fuentes historicas/672baseline, rama/worktrees, otros proyectos y
fuentes supervisor congeladas. Sin Java/frontend/config/cuentas/servicios/UAC/TLS,
SQLsetup/DPAPI/secretos/commit/push/main/FactuEz. Informe con hash/delta/regresion
y limites; no afirmar negocio/compilacion V13 comoPASS por corregir una guarda.

## Entrega de este Dispatch

Baseline antes/despues de las672fuentes conocidas, unico delta en SQL de prueba,
sin nuevas rutas producto. Informe TEMP B1R2 con SHA nuevo, diff explicado,
regresiones enfocadas y como extraer/ejecutar el futuro probe sin hacerlo ahora.
Fuentes supervisor congeladas y documentos/tablero no se editan por el worker.
No repetir suites Java/Next/demo. Si codigo/regresiones offline quedan completos,
entregar succeeded EN_REVISION con MOTOR_NO_EJECUTADO; no exige aceptacion previa
del supervisor para enviar worker_done. Si falla la correccion, failed con evidencia.
Procesar/ack todos los lotes antes de done; conservar terminal y sesion.
