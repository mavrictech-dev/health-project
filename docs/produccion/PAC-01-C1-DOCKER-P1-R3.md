# PAC-01.C1.DOCKER.P1.R3: proteger entrada SQLcmd de lineas largas

Supervisor 2026-11-13. Leer AGENTS/flujo/TAREAS y D-87.BG CANONICOS ROOT
D:/Mavric/Health Project. Misma pareja/cuentas por proceso/--no-daemon/
terminal/sesion/worktree retenidos; IDs NUEVOS del preambulo. Supervisor unico
escritor docs. Implementacion offline y UNA prueba posterior SOLO LECTURA,
autorizadas por este contrato. Sin instalacion ni nuevo gate al usuario.

## Evidencia y decision de arquitectura

JSON-E1 task_d0728d98a4cf/ctx_1770257b71f6 succeeded como diagnostico, done
msg_17266fee53c9. Informe44EA45DBAB3A0F55BFFFE07263605BFA58A837D1D78D7AA1044F2B9C4D3F3FDC.
Supervisor34artefactos/717fuentes/8referencias freshhash,17journal/8calls/1SQL,
frame29476bytes SHA E30D09FF6D15B9348886668B67937A11515541C6A36151EF9543E94B5375D2C1.
241profiles:95cambian longitud+huella,78invalidos3ISJSON,17cambianperoJSONvalido,
146identicosvalidos;2controlesintactos.94deltas+2bytes y1delta+4bytes.

Supervisor reconstruye cada linea de entrada CTE: insertar LF tras cada4095
bytes UTF8 y decodificar con replacement reproduce EXACTAMENTE longitud y
SHAengine de241/241. CasoV_NEURO corta secuenciaUTF8; replacement tambien
coincideexactamente. Tres casos medidos por busqueda de insercion unica LF:
H_INTERV_CARDIO posicionUTF16zero3975, D_CIRUGIA_ORAL_MAXILOFACIAL3984,
D_DOLOR_OROFACIAL3993. No modelo de truncamiento simple: se agregan unidades.
Review ROOT/tmp/c1docker-json-e1-supervisor-20261113/review.json. Es modelo
verificado para este binario/transporte propio, NO limite universal SQLServer.

Corregir representacion de entrada para que ninguna linea enviada a SQLcmd
alcance4095bytes. Mantener catalogo/Unicode/check canonicos, sin editar V1/V2.
Insertar LF solo en limites de whitespace SQL seguros FUERA de literales,
identificadores y comentarios. El renderer no altera ningun byte original:
solo inserta LF y documenta offsets/reconstruccion. Maximo4094bytes por linea
fisica (definir conteo incluyendo CR existente); no normalizar encoding/CRLF/BOM.
No cambiar flags, imagen, SQLcmd, schema, checks o reglas para obtenerPASS.

## Ownership exclusivo de fuentes en worker

- scripts/health-sqlserver-docker-qa.py
  base C65743A57479BE15BC27D821D682478367C5DF2AE93F550E31CEC84E89A951A6
- scripts/tests/test_health_sqlserver_docker_qa.py
  base C85FF9D231212B9DDC95C5169C537F1F5B209158ABAD1E10D5F57C2DAD2C0B06

Mas TEMP NUEVOS C1DockerP1R3-* y evidencia NUEVA create-only
ROOT/tmp/C1Docker-P1R3-20261113-run01 para prueba readonly. ROOTsource queda
intacta hasta integracion supervisora; no copiar/sync/reset. Baseline717 entre
checkouts,2deltasworker permitidos/0adicionesproducto. Freshhash717 y referencias
canonicas/relevantes antes/despues; no rehash general56k ni suites ajenas.
Sin Java/frontend/config/deps/AGENTS/docs, verificadorLPC/plantilla, V1-V14 o
artefactos/approval previos. No cuentasglobales/serviciosWindows/Somee/
AgendlyCitas/FactuEz/otrosrecursos. Sin commit/push/main/despliegue/gastos.

## Cambio de tooling y aceptacion offline

Separar generacion RAW original de render: `sql_raw(data,stage,nonce)` produce
EXACTAMENTE el corpus anterior, luego `sql` retorna payload renderizado.
Nombre de renderer libre pero interfaz pura bytes->bytes, sin proceso/socket/
escritura al importar o planear. Aplicar a TODAS las5fases del driver para que
plan, hash, evidenciaSQL, parser y transporte usen los mismos bytes finales.
No agregar modo CLI que salte renderer, aplique a targetalternativo o permita
un commit no revisado. Provisioner/argv/secretos/guardas/tx/pines siguen iguales.

Lexer bytes UTF8 estricto. Reconocer comillas SQL/dobles escapadas, N-prefix,
identificadores [] con escape ]], identificadores entre comillas, linecomments,
blockcomments anidados. LF solo antes de whitespace exterior ya existente,
conservarlo tambien. Nunca partir UTF8, literal o comentario ni terminar --
activando texto. Conservar directivas SQLcmd y GO completos. Si un token/
comentario/directiva no puede acomodarse, rechazar con codigo fijo antes de
SQL, sin cortar literal, fragmentarlo dinamicamente o reescribir comentario.
Puede agregar codigos Fault acotados para UTF8 invalido/linea no representable.
No devolver textoSQL/errorarbitrario en excepcion. No fallback a payloadoriginal.

Pruebas necesarias, run/Popen/socket siempre doblados: conservar intencion de
37tests actuales; adaptar SOLO aserciones de representacion usando RAW original
cuando corresponde, no quitar controles. Cubrir frontera4094/4095, acentos/
suplementarios, comillas escapadas, --/blockanidado/[]/comillasidentificador,
GO/directivas, CRLF/BOM, tokeninsplittable y errorpreSQL, idempotencia.
Para5fases: RAW byteexacto anterior, rendering solo LFexterior insertado,
reconstruccion byteexacta, cada linea<=4094; guardas/preCOMMITcount1state1 y
canonicas sin cambios semanticos. Validar NUEVO apply completo con ScriptDom160
si disponible: AST/tokenstream semantico igual, sin tratar whitespace como
datos ni normalizar BOMinterior. No repetir112fases/Maven/frontend.

Regresion diagnostica concreta: las241expresiones/inventario E1 permanecen
intactos. Modelo LF4095 aplicado a queryoriginal reproduce95deltas; aplicado a
queryrenderizada no agrega LF y mantiene241hashesfuente. Esto es modelo,
prueba real de entrada vendra en unica consulta siguiente.

## UNA prueba real readonly posterior a preparacion

Usar query E1 TEMP/C1DockerJsonE1-metadata-ready.sql SHA
0F333CB38CFBA1B9C6B2A281F397A74C04E363846CD372F17CDA80561195CA34,
inventario/protocolo E1 congelados y pines. Candidato SOLO nonce nuevo y render
de whitespace fuera tokens. Misma SQLsemantica/241filas/2controles/guards/
opciones/alias/shape, no otras nuevas mediciones o escrituras. Comparar contra
frame E1 guardado sin volver a ejecutar su query original. Token/literal/GO/
collation/value semantics identicas; guardar diff/offsets/hashes antes del envio.

Transportar mediante helperTEMP acotado que importa ROOTdriver anterior
PINNEADO y sus guardas/funciones, NO ejecutar CLI PROVISION de worker o ROOT.
Solo el rendererworker se usa para producir payloadcandidato, nunca para
relajar validacion fisica/manifest de ROOT. Referencia ROOT/tmp/c1docker-r2-complete-20261112/
reviewed-complete-manifest.json SHA
665C9ED529EF24B1A0737086DD273F32280A237CC7896D284AE0F8DA42DB9E29;
se lee para pines, no como nueva aprobacion operativa o permiso PROVISION.

CID UNICO4d599e57d7f605f42385d2ff627f83287366b6a12e2b9825b03222c42a9bec67,
hostname/nombrehealthproject-c1qa-20261112, volumenhealthproject-c1qa-20261112-data,
runlabela52e4ded46af4fe29d9f16a28b938719, DBhealth_project_c1_docker_qa_20261112,
markeroriginal, loopback127.0.0.1:14436->1433, bridge/restart=no/privilegedfalse/
bindsnull/unicomountrw /var/opt/mssql. Imagen/CLI/inner/context/endpoint/daemon y
todos los checks fisicos originales de E1 exactos. Si falla o parado, STOP,
no start/restart/create/rm/prune/pull/compose/repair/adopt ni target alternativo.

Enviar status con2sourceSHA/helper/capture/query/schema/nonce y resultadooffline
antes de ejecutar. Contrato autoriza UNAsecuencia hasta8callsreadonly:
contexto/daemon/imagen/volumen/CIDrunning/innerpin/UNAquery/inspectfinal.
Sin nuevo gate usuario o instalacion. Ante ambiguedad ask/STOP, sin ampliar.
Flags iguales E1 (-C -b -V11 -r1 -f65001 -y0 -w65535 -x -X1 -l30 -t120),
NO-h/-W/-P. SApropio solo consulta, secretoexportinsidecontainer, nunca
Config.Env/passwordargv/envhost/global/archivo. shell=False/capturabinaria,
SQLtimeout180/inspect30, capturaexterna sin timeoutcorto/kill/retry.
Rawstdout/stderrBIN locales<=64KiB/canal antes del parser; no imprimir buffers
arbitrarios/profiles. Journalintento durable/resultados/primaria+secundarias.
Si overflow o fallo capturastorage, STOP. TrasSQL solo inspectfinal, nosegunda
query ni retry paraPASS. Timeout/recibo incierto UNKNOWN, conservar recursos.

Aceptacion requerida: rendereroffline correcto Y frameengine completo con241
longitudes/huellas IGUALES al inventariofuente y241validos3ISJSON,2controles
igualesvalidos, Dockerfinalconforme, ninguna escritura/instalacion. Si aparece
diferencia, reportar failed/UNKNOWN y consultar; no editar canonicas/check,
probarotraestrategia en motor o suprimircaso para cerrar. Ningun PASS de aqui
autoriza aplicarV1-V13/V14: instalacion futura tendra contrato/manifest propio.

Informe TEMP/C1DockerP1R3-programmer-report.json: IDs/2SHA/diff/tests/RAW/render/
lexer/limites/AST/canonicas/modelos y prueba readonly8calls/frame/comparacion241/
conservacion/limitaciones. EN_REVISION, deploymentReadyfalse. ACKdeliveryId y
todos lotes antes de worker_done, mantener terminal. No sourceROOTintegration.
