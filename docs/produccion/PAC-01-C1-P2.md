# PAC-01.C1.P2: verificador SQL PRE con rollback, preparacion offline

Contrato supervisor, 2026-11-12. Continuidad autorizada por el usuario mientras
se crea otra base Somee. No acceso Somee/AgendlyCitas. Preparar herramientas
revisables, NO ejecutar SQL, instalar V14 o validar negocio ahora.

Leer AGENTS/flujo/TAREAS y PAC-01-C1-P1/Q1/R1, PAC-01-C2-P1 y este contrato
CANONICOS D:/Mavric/Health Project. Run run_624b9269b491, cuenta programador
recuperapiura por proceso/--no-daemon, misma sesion/terminal/worktree retenidos;
arquitecto mendozadeafabisa. Nuevos IDs del preambulo.

## Dependencias aceptadas y limites de evidencia

V14 fuenteR1 B6E34ACA24F95874692C7A0C27F8A967D8E9FB8BFB604E22A976BA04E15C1B52
integrada pero NO instalada. C2.P1 task_6a5942e84695/ctx_4e0c7835e695 completa
con done msg_1fe981349166; supervisor verifica62artefactos/13referencias/deltas
y14archivos integrados por SHA. Maven independiente ROOT1082/0fail/0error/0skip,
72suites;707fuentes postintegracion/pines726/historia301/migraciones25 intactos
salvo deltas autorizados de API. VINCULOS_API_C2P1_20261112.json. Esto acredita
APIoffline, no SQL/CAS/ACL/concurrencia/JDBC/authreal. V14 sigue pendiente.

C1.P1 plan100casos y R1 plan38casos son criterios NO EJECUTADOS. Este paquete
construye solo el verificador secuencial PRE; casos que necesiten V14 instalada,
fixturescommitted/2conexiones o JDBC quedan pendientes explicitos.

## Ownership exclusivo: TRES rutas NUEVAS

1. backend/scripts/verify-sqlserver-patient-link-management.sql
2. scripts/verify-patient-link-management-sql.py
3. scripts/tests/test_patient_link_management_sql_verifier.py

Mas TEMP NUEVOS C1P2-* para baseline/parser/diff/snapshots/reportes/tests.
No editar migraciones V1-V14, Java/API/UI/config/deps/AGENTS/docs/herramientas
previas ni runners readonly E5/B1. Consultar antes de ampliar. Supervisor unico
escritor docs/tablero y checkout principal. Baseline fresh707fuentes/25migraciones
(dosV14),726pines/301historicos/21snapshots y artefactos anteriores; conservar
los informes/planes/fallos/logs originales y evidencia de integracion independiente.

## Herramienta futura y fronteras

Nuevo Python separado carga SQL por secciones y compone batches para UNA fase
por conexion. Guardar el SQL generado en TEMP propio para parser/review; sin
datos o secretos reales. SQL entero ejecutado directamente debe fallar cerrado,
indicando usar controlador revisado. Validar comando EXACTO PRE_APLICACION;
no implementar apply/commit/repair/post real ni modos que muten sin rollback.
Plan de POST/JDBC/concurrencia queda documento TEMP, sin ejecutor operativo.

Transporte futuro EXCLUSIVO Windows integrado -E y LPC lpc:.\HEALTHPROJECTQA,
base health_project_sqlserver_qa_isolated_20261105. SQL2022/compat160 y marker
health_project_scope EXACTO ya aceptado: Health Project isolated JDBC QA;
provisioned 2026-11-05; no real data (es una sola cadena, ver B1 literal).
Principal CONTROL separado y sin rol runtime/bootstrap; dbo SQL o Windows
legitimo, sin cambiar owner/autenticacion. No TCP/remoto/fallback/login/password.
El codigo de este Dispatch NO puede invocar ese transporte real ni probes.

Reutilizar por lectura patrones revisados de B1/SQLcmd, no sus globals/matriz:
- Argumentos sin shell, entradaUTF8, SQLcmd -b -V11 -r1 -f65001 -y0 -w65535
  -x -X1, conexion/comando/proceso con plazos limitados; nunca defaults de DB.
- Resolver/pinnear executable local esperado. Rechazar entorno SQLCMDhostil y
  pasar entorno acotado. No instalar drivers/dependencias ni buscar otro motor.
- FrameJSON estricto de una linea, UTF8/Unicode largo integro, cabecera/separador
  solo variante exacta conocida; no textoextra, constantesJSON, duplicados o
  salto insertado como exito. Error/estado/phase correlacionados, tipos exactos.
- Raw0 no basta. Esperado510xx no se acepta desde stderr sin frame/estado/baseline.
  Msg3998/raw16 se acepta SOLO con patron exacto conocido y TXdoomed esperada,
  sin otros mensajes y baseline fresca restaurada. Otros exits/errores fallan.
- Timeout/fallo detiene lote sin retry; comprobar cierre/rollback por baseline
  nueva antes de resultado. No REVERT inseguro en TXdoomed; cierre de conexion.
  No compensar/borrar datos ni repetir mutacion de resultado desconocido.

## PRE rollback-only y conservacion

Baseline independiente en conexiones NUEVAS antes/despues de CADA fase y al
final. Validar V13presente/V14ausente/134SP/31triggers/rolesACL564 (o573 con
historiaFlywayopcional), hashescanonicos de V1-V14 y fuentes/verificador.
Estos conteos son PRERREQUISITOS de fuente, no mediciones ejecutadas en P2.
No reaplicar V13. Si V14 esta instalada/collisions, falta marker/CONTROL/OPEN
o hay drift, fallar o indicar prerrequisito; nunca reparar, cambiar owner o
continuar. No permitir que un preflight posterior de V14 sea ignorado por GO.

Cada fase abre UNA TX externa con XACT_ABORT y carga V14 exacta deteniendose
en primer error, crea SOLO fixtures fresh de su namespace y principals WITHOUT
LOGIN transient hp_qa_c1p2_runtime/hp_qa_c1p2_bootstrap con roles correspondientes.
Usuarios/membresias/sesiones/pacientes/tenant/plan/subscripcion propios, UUIDs
lowercasefresh, tokenhashlowercase y correos .example.test; no login real/secretos.
Fixture setup bajo CONTROL, llamadas reales de producto mediante EXECUTE AS
principal limitado; nunca probar negocio como dbo ni otorgar tablas/DDL/helpers.
No reutilizar PACQA/E5/historia u otras filas. Guardar cutoff de audit DESPUES
de fixtures, requests nuevos para comando/lector; no contar audit de preparacion.

Sin COMMIT, cambio global de application_state, DDL de instancia, logins,
backup/restore/servicios/TLS/UAC/Docker/DPAPI/browser/API. ROLLBACK explicito si
committable o por cierre de conexion si doomed; freshbaseline verifica igualdad,
no inferirla desde mensaje de rollback. Comparar hashes en motor, sin exportar
filas/credenciales: TODAS37tablas de negocio por PK, definiciones de todosmodulos,
columnas/default/check/FK/indices/triggers/ACLgrantor/membresias/principals/schema/
owner/marker/compat y Flyway si existe. Excluir solo contadores identityallocator
cuyos huecos SQL no revierte; documentar ese limite, sin reseed/borrado.

## Matriz secuencial ejecutable futura

Mapear cada caso a fase/entrada/error/ACK/filas/audit esperados. Implementar
casos de valor, no inflar conteos por textos distintos; cobertura y pendientes
explicitos frente a planes100+38. Las fases son testsSQL futuros, no dobles de CAS.

- Alta0/editar/reactivar/retirar, SETidentico/retirar inactivo incrementanrevision,
  secuencias stale/createyaexistente/ausente/INTMAX y resultado ACK5/edit8 exactos.
  Stale tras otro comando SECUENCIAL no se llama carrera de dosconexiones.
- Retirada historica preserva BYTES relationship/scopes (vacio/desconocido/
  duplicado/noarray/cuenta inactiva/noverificada/sinmembresia/rolescambiados).
  SET revalida elegibilidad actual PAC/RES1o2, sin roles internos/plataforma,
  con activo/verificado/membresia ACTIVE. HUMAN/ANIMAL, orden de scopes yBILLING.
- JSON5/3 estricto, clavesduplicadas/extra/case/tipos, activefaltante/null,
  revisionlexical/fraction/exponent/string/bool/-0/overflow; UnicodeUTF16/espacios/
  limites; IDs completos contexto/JSON validados antesdeconversion. Q1sobre
  longitud original de parametrosCHAR sigue pendienteHTTP, no fingir casoSQL.
- Actor ADM/REC real, sinPACRESmixtos ni plataforma, rolesdeclarados falsos no
  conceden/revocan autoridad, tenant/paciente cruzado, sesionrevocada/expirada,
  usuarios/membresias inactivos, REQUEST/contextoincompleto/case/IDENTITY/WORKER,
  sinPORTAL/tenantSUSPENDED sobre fixturepropia. ModoOPEN soloobservado.
- Denegacion runtime tablas/DML/DDL/privados/bootstrap y bootstrap->nuevolector/
  writer; exacto delta+1SP/+2ACL, writerfirmaigual y lectorfirma2CHAR36, proyecciones
  ACK5/edit8 por metadata/captura real, V13/B7 y V7 sin delta. RolesACL566/575 solo
  dentro de TXtransient que incluye V14, no permisosamplios.
- Audit: cada comando aceptado1PORTAL_LINK_CHANGED con5metadatascalars exactos;
  lectorpositivo1PATIENT_LINK_EDIT_READ; negativas0semantico y sin fila parcial.
  TriggerV7 cuota segun proyeccion, no cuota fija de total. Falloaudit inducido
  SOLO con fixtureauxiliartransient nueva despues de instalarV14 enTX; preservar
  helper/trigger originales. Doom y rollback prueban ausencia persistente por
  freshbaseline, no exito/aplicacion parcial.

## Casos que PRE NO puede acreditar

V14 no confirmada solo es visible en TX de su instalacion: @@TRANCOUNTya>0.
Por ello no etiquetar como probadas primeras llamadasR1 con contador0,
autocommitnuevoSP, ni misma conexion JDBC trascommit/rollback. No cerrar TX
de migracion para intentarlo. Reservarlos para POST separado con V14instalada
y fixtures/credenciales/principales propios preparados por otrogate. Toggle
IMPLICIT dentro de TX yaabierta no prueba frontera inicialR1 ni driverJDBC.

Dosconexiones/CAS/revocaciondespuescommit/locks/pool y READ_ONLYglobal tambien
pendientes. Proponer plan TEMP con barreras, permisos, timeout/deadlock y
observabilidad; sin codigo de instalacion o fixturecommitted en este paquete.
No simular esos casos para aumentar cobertura ni darPASS a prerrequisitos ausentes.

## Verificacion offline y entrega

Pythonunittest propia de generacion/transporte/frame/conservacion con subprocess
doblado, ninguno real. Probar comandos/targets/env/frames largos Unicode,
erroresestderr/raw0/3998/exits/timeout y stop-on-error/freshbaseline; estos tests
NO prueban SQL. ParserTSQL160 local sobre SQL generado COMPLETO por fase (incluida
V14), sin motor/SET PARSEONLY/probes/instalaciondeps. py_compile enTEMPpropio.
No Maven/frontend ni suites aceptadas no relacionadas. No ejecutar main real.

TEMP/C1P2-programmer-report.json: nuevosIDs,3fuentes/SHA/diff/snapshots/casos
implementados vs pendientes, comandos/exits, parser/templates/framing ybaseline
de preservacion. succeeded significa HERRAMIENTA OFFLINE EN_REVISION, no engine
PASS. Antes de worker_done procesar todoslotess/ACKdeliveryId si aparece;
conservar terminal. Sin commit/push/main/gastos/datosreales/FactuEz.
