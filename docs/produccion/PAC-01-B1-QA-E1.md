# PAC-01.B1.QA.E1: matriz SQL real previa a instalacion

Encargo supervisor 2026-11-09. R1 task_c4c2ade2df22/ctx_2cfd21810392 aceptada
SOLO como transporte y prueba preparada. Supervisor reviso el diff, ownership672
(670historicas mas2propuestas), argv real mediante mock y framing negativo/Unicode;
contrasto hash del probe unico real y payload8000caracteres. V13 no esta instalada,
compilada ni aceptada en motor. No presentar esos controles offline como negocio.

Leer AGENTS.md y PAC-01-B1.md/D-87/D-87.A/B/R1 desde el checkout supervisor
D:/Mavric/Health Project. Programador recuperapiura en su misma terminal/sesion;
supervisor unico escritor de documentos/tablero/revision. No fuentes asignadas:
este paquete es EJECUCION QA, sin cambios de codigo.

## Entradas congeladas y destino

Usar como directorio de trabajo QA (NO checkout para editar):
D:/Mavric/Health Project/tmp/pac-01-b1-20261109/r1-review

Dos archivos revisados bajo ese directorio:

- backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql,
  SHA256 CB57FAD4A4F639F5F442C2AC8ADAFFC92001B9953A108FF1DEF4CF861D5CC060.
- backend/scripts/verify-sqlserver-patient-links-read.sql,
  SHA256 D1CDE92664B7875029421F84E6C74968366602DA206678BFC24139AC351AC970.

Comprobar ambos SHA y contexto Git supervisor/worker antes de ejecutar; conservar
672SHA del baseline R1 (el unico delta aceptado es el SQL de prueba). No editar ni
copiar fuentes a producto. Informes/harness nuevos solo TEMP con nombre B1E1.

SQL existente HEALTHPROJECTQA, base EXACTA
health_project_sqlserver_qa_isolated_20261105, marcador exacto en COMMON.
Transporte administrativo LPC Windows Integrated lpc:.\HEALTHPROJECTQA, CONTROL
separado de runtime/bootstrap; runtime del test se impersona al usuario temporal
WITHOUT LOGIN dentro de la transaccion. Sin password, DPAPI, API ni secretos.
No cambiar transporte, cuentas, servicios, ACL globales o TLS. Si no hay acceso o
servicio, detenerse: no arrancar, reconfigurar ni reintentar UAC/TLS.

## Unica fase autorizada

Ejecutar UNA vez el controlador B1_RUNNER extraido EXACTAMENTE del archivo SQL,
con argumento PRE_APLICACION y cwd del directorio congelado anterior. El codigo
usa Path.cwd para localizar las dos entradas; no exige copiar a raiz de producto.
Extraer/leer con UTF8 desde Python o archivo UTF8: evitar recodificar literales
Unicode mediante stdin de PowerShell. No ejecutar el SQL completo ni SQL ad hoc.
Se permite harness TEMP que extraiga el bloque, asigne sys.argv y ejecute su main
sin alterar su logica. Capturar salida y exit completos en TEMP sin imprimir SQL,
filas, contrasenas o tokens. Fuentes permanecen byte a byte iguales.

PRE_APLICACION autoriza solo las mutaciones transitorias de las40fases revisadas:
V13,2ACL,usuarios temporales WITHOUT LOGIN y fixtures nuevas dentro de TX EXTERNAS
que se revierten. Ningun COMMIT, instalacion persistente, login, setup/reapply de
V1..V12, borrado de compensacion o uso/modificacion de los25pacientes PACQA.
Preservar tambien todas las demas filas/sesiones/auditoria existentes. Gaps de
allocators identity son propiedad conocida del rollback y no se presentan como
filas persistidas ni se corrigen con reseed.

El supervisor mantiene esta QA exclusiva: no otros workers, browser/API, sondeos
HTTP o fixtures concurrentes durante la matriz. Backend previo jobsfalse puede
permanecer sin trafico; no matar ni reiniciar procesos para lograr exclusividad.
La comparacion estricta de fingerprints desde conexiones nuevas debe detectar
cualquier deriva. No relajar filtros, baselines, ACL o stderr ante discrepancia.

El controlador realiza baseline inicial y antes/despues de cada fase, usa nueva
conexion por fase, prueba5positivos y35negativos, y se detiene al primer fallo.
Registrar exactamente fases terminadas, exit, codigo y limites. Un exit no0,
drift, error de compilacion/framing/guardas o estado incierto hace failed; NO
repetir la matriz ni subsanar codigo/SQL/fixtures. Conservar evidencia local y
consultar por Orca para correccion posterior. Si hay fallo de motor, puede
capturarse diagnostico seguro del mismo intento via wrapper TEMP alrededor de
invoke (sin cambiar respuesta/controlador): guardar solo numeros de Msg/Level/
State/Line, exit y estado, omitiendo SQL, filas, nombres/UUID o valores sensibles.
No nuevas conexiones/reproducciones para diagnosticar tras el fallo.

## Aceptacion y entrega

Exigir PASS real de40fases (5positivas con11lecturas cada una y35negativas),
ACL exacta562->564 dentro de cada TX y regreso562, V13 ausente y fingerprints
restaurados desde conexion nueva, sin ignorar errores3998 salvo el patron exacto
revisado. Auditoria/transaccion/paginacion/orden/scopes se prueban en los SP reales,
no por conteos de permisos. Conservar modo global observado: OPEN no prueba modo
READ_ONLY, aunque las fixtures de tenant SUSPENDED sinPORTAL prueban esa condicion.

NO ejecutar AUTOCOMMIT_POST_APLICACION: sigue pendiente de decision posterior
de instalacion supervisada. No fabricar PASS de esa fase, no instalar para probarla.
No repetir suites Java/Next/demo ni activar API/UI de vinculos.

Informe TEMP con inputSHA, contexto, invocacion/cwd, start/end, exit/resultado
completo seguro, fases/cantidades, baselines y limites; ownership/hash finales.
No exportar valores de tablas, sesiones ni credenciales. Supervisor revisara de
forma independiente antes de aceptar/aplicar. Procesar y ack lotes si corresponde
y enviar worker_done con outcome real y report-path; EN_REVISION no requiere
aceptacion previa para enviar done. Mantener terminal/sesion, sin commit/push,
main/FactuEz/cuentas globales ni shutdown.
