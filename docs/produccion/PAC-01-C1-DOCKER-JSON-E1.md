# PAC-01.C1.DOCKER.JSON.E1: evaluar expresiones del catalogo, solo lectura

Supervisor 2026-11-13. Continuidad local autorizada; NO es instalacion.
Leer AGENTS, docs/agent-workflow.md, TAREAS y D-87.BF CANONICOS ROOT
D:/Mavric/Health Project. Misma pareja/cuentas por proceso/--no-daemon/
terminal/sesion/worktree retenidos; IDs NUEVOS del preambulo. Supervisor
unico escritor docs/tablero/revisiones. No pedir nueva confirmacion al usuario.

## Hechos aceptados y objetivo

APPLY.DIAG.E1 task_2a2555a90d6a/ctx_108e83113ca0 termino succeeded como
DIAGNOSTICO, msg_4fc37fd15775. Informe TEMP/C1DockerApplyDiagE1-programmer-report.json
SHAE98C85F85F10C8B73F00A7A70F58FD2888649F5A927B58D5940F3C921CF38C51.
Supervisor588artefactos/717fuentes freshhash, ledgers56263iguales,21journal,
10comandos/2SQL. Reproduce EXACTAMENTE278bytes/SHA
AA1A92E5C466F995A1045341C80DF8EC67763BC253A2E3EA5065DA1E37F75338,
Msg547 CHECK CK_specialties_profile_json, NO FK. Regla canonica V1line129:
profile IS NULL OR ISJSON(profile,VALUE)=1. POST valido observa esquema vacio,
configuracion propia y Dockerfinalconforme; no COMMIT, no recibo deROLLBACK
explicito, no instalacion lista ni huella completa para cuatro hashesNULL.

No atribuir fila desde nativeLine18: mapping no acreditado. No atribuir causa
a BOM/truncamiento o modificar V1/V2 para forzar PASS. Supervisor reconstruyo
COMPLETAS las241expresionesprofile (todos los literales, no el primer segmento
de1000chars); las241 son JSON estricto valido en Python. Esa observacion no
prueba evaluacion en SQL Server ni semantica del CHECK al insertar.

Objetivo NUEVO: UNA consulta sin escrituras que evalua en SQL Server las241
expresiones profile EXACTAS del seed, compara DATALENGTH/huella UTF16/ISJSON y
separa posible cambio de valor durante evaluacion de validacion del motor.
Medir todas evita seleccionar una fila por numero de linea incierto.

## Ownership, conservacion y destino

Solo TEMP NUEVOS C1DockerJsonE1-* y evidencia NUEVA create-only
ROOT/tmp/C1Docker-JsonE1-20261113-run01. Cero cambios de producto/tests/
configuracion/migraciones/docs/herramientas existentes/evidencia previa.
Preservar717fuentes y pines/canonicas/artefactos operativos relevantes antes/
despues. No repetir suites, parseos previos o rehash general del historial56k
sin motivo: freshhash717fuentes y referencias concretas del encargo bastan;
artefactos viejos no se editan. No sync/reset/commit/push/main/despliegue/gastos.

Root driver C65743A57479BE15BC27D821D682478367C5DF2AE93F550E31CEC84E89A951A6,
test C85FF9D231212B9DDC95C5169C537F1F5B209158ABAD1E10D5F57C2DAD2C0B06,
V1 ED1DCB3E6BD4F2AC1F9B11DE9AA7D1053DB0E71CA3610E21801CC60D51FE4A0A,
V2 F672C8856AB6A150AE1967E85B8BAF9DF07F2615F4DB8445263F11F322A1A885.
Resto pines CLI/imagen/inner/canonicas en ROOT/tmp/c1docker-r2-complete-20261112/
reviewed-complete-manifest.json SHA
665C9ED529EF24B1A0737086DD273F32280A237CC7896D284AE0F8DA42DB9E29.
Es referencia, NO ejecutar su PROVISION ni reusar approval consumido del probe.

CID UNICO4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
nombre/hostnamehealthproject-c1qa-20261112, volumenhealthproject-c1qa-20261112-data,
runlabela52e4ded46af4fe29d9f16a28b938719, DBhealth_project_c1_docker_qa_20261112,
marker original, loopback127.0.0.1:14436->1433, bridge/restart=no/privilegedfalse/
bindsnull/unico mount rw /var/opt/mssql. Validacion completa fisica/pines como
SCHEMA-E1; contexto desktop-linux/endpointnpipe/daemon29.8.2 linuxamd64.
No Windows SQL/Somee/AgendlyCitas/FactuEz/otros recursos o pin-container.

## Preparacion offline acotada

Extraer code y expresionprofile de cada INSERTspecialties en V2 por AST o parser
estricto de columnas/parentesis/comillas SQL. Exigir241codigos unicos/whitelist;
no reemplazar CAST, operadores, literales, encoding, Unicode o collation de la
expresion original. Guardar inventario con lineas fuente, numero de segmentos,
longitud UTF16 esperada y SHA256 de bytes UTF16LE de valor reconstruido completo.
No confundir UTF8SHA con huella SQLnvarchar/varbinary. Parsear JSON estricto
offline (sin NaN/Infinity), no usar un segmento como documento completo.
Comparar offsets/bytes del extractor con fuente; no generar JSON de nuevo.

Consulta: engine_guard(DATABASE)+configured_guard()+empty_guard() EXACTOS de
ROOT revisada, luego opciones SET de sesion de la cabeceraV1 relevantes a los
INSERT conservadas (ANSI_NULLS/QUOTED_IDENTIFIER/ANSI_PADDING/ANSI_WARNINGS/
CONCAT_NULL_YIELDS_NULL/ARITHABORT ON y NUMERIC_ROUNDABORT OFF). Sin BEGIN/COMMIT/
ROLLBACK, DDL/DML/EXEC/SP, tablas temporales/variables o acceso tablas de usuario.
Puede usar CTE/VALUES/UNION ALL y SELECT sobre constantes y metadata guardada.
No insertar ni una fila para reproducir el CHECK en este encargo.

Evaluar241expresiones completas en una relacion derivada, manteniendo cada
expresion byteexacta; aplicar collation de columna canonica de V1 al argumento
de validacion de forma explicita y documentada sin cambiar el valor literal.
Por cada codigo fuente aprobado devolver SOLO code, DATALENGTH(profile) como
entero, SHA256 de CONVERT(varbinary(max),profile) HEX64, resultados de
ISJSON(profile,VALUE), ISJSON(profile) e ISJSON(profile,OBJECT) como bool/int
cerrados. Si algun valor NULL se observa, conservarlo con tipo/schema explicito,
nunca fabricar0/hash. Comparar contra inventario esperado OFFLINE en reporte.

Incluir controles constantes separados: objeto vacio y objeto JSON valido de
mas4000unidadesUTF16 construido como nvarchar(max), longitud/huella/ISJSON
medidos y esperados; sirven para distinguir validacion generica de expresiones
del seed. Reportar opciones de sesion como mascara int si ayuda. No variar
compat/collation/base/parametros de servidor ni opciones de transporte.

Un frame JSON C1JSON con nonce32hexnuevo, identity cerrado, readinessAuthorizedfalse,
exactamente241filas ordenadas por codeBIN2/whitelist y controles cerrados.
No retornar perfiles, nombres de personas, definiciones, valores de negocio,
nombres arbitrarios o otras DB. El campo code es enum de241 literales canonicos
publicos. Mantenerframe<=64KiB: no duplicar hashesesperados en frame porque ya
estan en inventario local. Documentar keys/tipos/orden/nullpolicy antes del
unico transporte. Parser rechaza clavesextras/duplicados/ruido/colas/nonce,
codigos faltantes/extra/duplicados y tipos incorrectos. ValoresISJSONfalse o
hashesdistintos son diagnostico valido, no fallo de protocolo o permiso para fix.

Modelos offline necesarios: extractor conserva241expresiones y joins completos,
hashUTF16 consistente, parserpositivo y negativos de duplicado/faltante/nonce/
tipos, limite64KiB con frame maximo, modelos de comando unico y errorcapturado
antes del parser con primaria/secundaria. run/Popen/socket doblados. Solo
validar sintaxis local de NUEVA SQL si se dispone de parser instalado; no
repetir parseos de payloads previos/Maven/frontend. Modelos no son prueba motor.

## Ejecucion readonly autorizada UNA vez por este contrato

Tras preparar/congelar SQL/schema/plan/helper y enviar estado con SHA por Orca,
puede ejecutar sin otro gate, manteniendo restricciones anteriores. Si surge
ambiguedad de extractor/limite/alcance, ask supervisor y STOP, no improvisar.
Hasta8comandos: contexto/daemon/imagen/volumen/CIDrunning/innerpin/UNASQL/
inspectfinal. Todos readonly. Si preflight falla STOP, sin start/repair.

Mismo argvSQL de SCHEMA-E1: exec --interactive CID /bin/sh -c SQL_SHELL c1sql
-S tcp:127.0.0.1,1433 -U sa -d DB -C -b -V11 -r1 -f65001 -y0 -w65535 -x -X1
-l30 -t120; NO-h/-W/-P. Native shell=False/binario, SQLtimeout180/inspect30.
SA propio solo setup/lectura; secretoexport dentro contenedor, no Config.Env,
passwordargv/archivo/envhost/envglobal o nuevas credenciales.
Guardar rawstdout/stderr BIN locales <=64KiB/canal antes de parsear; nunca
imprimir buffers arbitrarios o cuerposprofile en terminal/reportes al usuario.
Hash/longitud/exit/headers numericos o frases controladas en resumen. Si buffer
excede, guardar solo hash/longitud y fallar sin volcar. Captura externa sin
timeoutcorto/kill/retry. Journal durable antes/despues, preservar primaria y
secundarias. Tras SQLintentada solo inspectfinal preautorizada; ninguna segunda
consulta, reparacion o repeticion para conseguirPASS. Timeout/recibo incierto
UNKNOWN, recursos conservados.

Informe TEMP/C1DockerJsonE1-programmer-report.json con IDs/pines/extractor/
SQL/schema/plan/8calls/frames/conservacion y comparacion fila241/controles:
cuantas expresiones cambian longitud/huella, cualescodigoscanonicos fallan
cadaISJSON y si coinciden esas observaciones. No atribuir fallo de INSERT a
una fila sin demostrar mapping o reproducir su semantica. Si todas pasan,
informar que SELECT no reproduce CHECK en INSERT, no arreglado/DBlista.
Succeeded si diagnostico completo valido, aun con ISJSONfalse; transporte o
frame fallidos => failed/UNKNOWN sinretry. EN_REVISION y deploymentReadyfalse.
ACKdeliveryId y todos lotes antes de worker_done. Mantener terminal/sesion.
