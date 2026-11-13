# PAC-01.C2.P1: API compatible con revision y retirada, offline

Encargo supervisor, 2026-11-12. Usuario autoriza continuar pendientes mientras
prepara una base independiente; no acceder a Somee/AgendlyCitas. Este documento
activa SOLO la implementacion API offline del contrato PAC-01-C2-PREPARACION.md.
Su estado inicial de diseno queda historico; semantica completa obligatoria.

Leer CANONICOS D:/Mavric/Health Project/AGENTS.md, docs/agent-workflow.md,
docs/produccion/TAREAS.md, PAC-01-C1-P1.md/Q1, PAC-01-C1-P1-R1.md,
PAC-01-C2-PREPARACION.md y este documento antes de editar. Pareja actual:
arquitecto mendozadeafabisa, programador recuperapiura. Misma cuenta por proceso,
--no-daemon, Run run_624b9269b491, terminal/sesion/worktree retenidos. IDs del
NUEVO preambulo, no usar los IDs historicos siguientes para worker_done.

## Dependencia aceptada

R1 task_ab40e0008138/ctx_ea90d3f41027 con done msg_82730ff23fd2 aceptada en
FUENTE OFFLINE. Supervisor verifica26artefactos/11referencias/696fuentes/
726pines/301historicos/21snapshots/28C0/34primeraentrega. Unico delta de V14:
dos fronteras runtime con helperV10 y guardcommittable, resto/instalacion igual.
Parser160 independiente0errores/5batches;38casos propuestos NO EJECUTADOS.
Evidencia VINCULOS_CORRECCION_C1P1R1_20261112.json. V14 integrada en checkout
principal por bytes exactos B6E34ACA24F95874692C7A0C27F8A967D8E9FB8BFB604E22A976BA04E15C1B52.
NO instalada, sin QA motor/JDBC/gestions. Mantener V14 y migraciones intactas.

## Resultado exigido

PUT /api/patients/{id}/links exige revision y booleanexplicitos, decoder local
JSON estricto con5claves SET/3retirada, rechazo de duplicados/extra/coercion y
tokens numericos no enteros decimales. No default de active/revision ni Set que
oculte scopes duplicados. Validar UTF16/whitespace como V14 y ambos IDs exactos
lowercase36 ANTES de RPC. Sin trim/substrings/truncamiento; negativosQ1 con
UUIDvalido+sufijo deben probar cero interacciones con executor.

Nuevo GET /api/patients/{id}/links/{userId} usa snapshot de edicion V14. PUT
responde solo ACK5; GETedit solo8campos con scopes JSONhistorico seguro/opaco,
incluido escalar/objeto/null. No convertir historia en concesion ni inventar
respuesta desde borrador. Validar revisionInteger/identidades/active/columnas/
resultsets/filas y fallar500saneado/rollback ante contaminacion. Mantener listaB
7campos/orden/clamps/autoridad y A/history sin cambios de comportamiento.

ActorADM/REC, sinSAD/SOP/PAC/RESmezclados, contextoREQUEST/host/tenant/dominio,
PORTAL y TRIAL/ACTIVE; SP valida modo/sesion/membresia actual. Un RPC de negocio
por operacion, TXSpring/context/reset existentes, sin GETcalentamiento/auditJava/
SQLdirecto/retry. Servicio link sin store falla cerrado, no fallbacklegacy.
Descriptor nuevo unico PATIENT_LINK_EDIT_GET con dosCHAR36 en ordenpatient/user;
writer conserva firma y payloadNVARCHARMAX. Contratos SQLV8/V13 pinneados,
deltaV14 explicito con hashfinalR1. No relajar lexer/parserhistorico.

## Ownership exclusivo

SOLO estas rutas del worktree del programador pueden cambiar (prefijo de
produccion backend/src/main/java/com/mavric/health):

- patients/domain/Requests.java
- patients/domain/LinkDeserializer.java NUEVO (decoderlocal de Link, nombre
  de clase puede conservar este aunque la base Jackson3 sea ValueDeserializer).
- patients/api/PatientController.java
- patients/application/PatientService.java
- persistence/sqlserver/SqlServerPatientStore.java
- persistence/sqlserver/SqlServerProcedure.java

Suites existentes, prefijo backend/src/test/java/com/mavric/health:

- persistence/sqlserver/SqlServerPatientStoreTest.java
- persistence/sqlserver/SqlServerProcedureContractTest.java
- patients/application/PatientServiceSqlServerTest.java
- patients/api/PatientLinksControllerSqlServerTest.java

Suites NUEVAS permitidas con ese mismo prefijo:

- patients/domain/LinkDeserializerTest.java
- patients/api/PatientLinkManagementControllerSqlServerTest.java
- persistence/sqlserver/SqlServerPatientLinkManagementStoreTest.java
- patients/application/PatientLinkManagementServiceSqlServerTest.java

Adicional SOLO backend/scripts/verify-api.py: migrar sus2invocacionesPUT de
vinculo, crear con revision0, capturarACKrevision y retirar con tres claves y
esa revision; mantener otras acciones/guardas. NO ejecutar este harness.

TEMP NUEVOS C2P1-* para baseline/snapshot/diff/comandos/informe. No editar docs/
tablero/review/AGENTS/config/deps/mapperglobal/executor/Errors/Checks/migraciones/
frontend ni runnersreadonly E5. Supervisor unico escritor de checkout principal.
Ninguna sincronizacion/reset de worktree. Sus37cambioshistoricos se preservan
fuera del ownership. Los10archivos existentes asignados coinciden semanticamente
con canonical; solo Requests.java difiere en CRLF/LF. No copiar checkout raiz
ni migraciones V10-V12 faltantes; consultar canonical por lectura si se necesita.
Si otro consumidor/source exige cambio fuera de lista, preguntar por Orca ANTES.

## Verificacion obligatoria y cierre

1. Baseline propia nueva incluye ambas copias V14:697fuentes actuales antes de
   C2 (696anteriores+integracion rootV14),23migracioneshistoricas+2copiasV14.
   Leer manifests C1P1R1 y agregar solo esa integracion legitima. Conservar
   fuentes no asignadas y TODOS los artefactos/planes/informes anteriores.
   Pines existentes se comparan indicando si alguna ruta coincide con ownership;
   no afirmar igualdad absoluta si un pin es una fuente asignada modificada.
2. Pruebas offline reales de decoder/MockMvc/store/servicio, usando framework
   existente. PositivosHUMAN/ANIMAL, activepresente, revision y retirada, scopes
   ordenados/unicos, UnicodeUTF16/NBSP, JSONduplicado/null/extra/numeroexponente/
   -0/coercion, IDlargo/sufijo/case antesexecutor, rolesmixtos/tenant/host/modulo,
   error/commit/rollback/resultadofalso, legacycerrado, historicos heterogeneos.
   Son modelos de API/adapter, no SQLreal/CAS/concurrencia ni evidencia de auth
   real desde standaloneMockMvc. Preservar pruebasB/A/history y errores seguros.
3. Suites afectadas y Maven completo OFFLINE una vez despues de corregir fallos
   propios; capturar comandos/exits/conteos. No package/buildjar que cambie el
   pin del runtime anterior; mvn -o test con JDK21 ya instalado, sin depsnuevas.
   Si falta dependencia o el motor del test requiere red, consultar, no instalar
   o arrancar nada. No frontendbuild. Compilar Python del harness sin ejecutarlo
   si se necesita comprobar su sintaxis, con pycache en TEMPpropio.
4. TEMP/C2P1-programmer-report.json con nuevosIDs, ownershipreal, hashesbaseline/
   fuente/snapshots/diff/comandos/exits/pruebas/conservacion y limites. Estado
   EN_REVISION; succeeded solo si API preparada y suitesPASS. No integrar enroot,
   migracion/QA/produccion ni simular datos del motor para decir CASPASS.
5. Procesar todos los lotes y ACKdeliveryId si aparece antes de worker_done;
   conservar terminal. Dudas/bloqueos se consultan antes de ampliar alcance.

Sin SQL/JDBC/HTTPreal/DPAPI/navegador/servicios/TLS/UAC/Docker/Somee/fixtures/
secretos/cuentasglobales/commit/push/main/despliegue/gasto/datosreales/FactuEz.
Fuentes y pruebas offline no autorizan instalacion. Verificador/QA SQL2conexiones,
instalacion reconciliada, candidatos/contactos/UI y QAintegrada son posteriores.
