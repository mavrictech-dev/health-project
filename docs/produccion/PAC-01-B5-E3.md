# PAC-01.B5.E3: una QA real readonly de vinculos y auditoria

Supervisor2026-11-10. Continuidad autorizada, Run run_624b9269b491, programador
recuperapiura, terminal/sesion/worktree retenidos --no-daemon. Leer AGENTS.md
absoluto/flujo/TAREAS/D-87.Z, contratoB5P1+R1 y esteencargo. Nuevos IDs del
preambulo. Supervisor unico escritor docs/tablero/veredicto. QA exclusiva.

R2 task_b571f0e96469/ctx_abcd60b65a34 aceptada e integrada por SHA:
51 artefactos/695 fuentes/726 pines/56 archivos historicos contrastados;
691 fuentes fuera de ownership intactas. Supervisor check/106 unit frontend y
17 Python PASS en root. Solo cuatro herramientas QA; producto/base helper igual.
Contexto TEMP B5R2-environment.py con tres constantes distintas del B4 original;
manifest B5R2-reviewed-pins.json identico a B4, 726 pines. Nueva salida/diarios E3.
La E2 anterior task_8fc4de487847/ctx_81f27beb2ebc sigue FAILED: human-login,
UNEXPECTED_FAILURE, cero lecturas/sesiones nuevas, causa indeterminada. Conservar
sus cuatro diarios/directorio y todo E1/E2/R2; no reintentar E2 ni borrar salidas.
La nueva herramienta alinea browser fetch/flags locales con QA anterior e informa
pasos/categorias cerrados y cleanup observado; R2 offline no demuestra QA real.
Baseline conjunta actual: 695 fuentes, con las cuatro integraciones legitimas R2
en root; capturar nuevo before, no exigir SHA anteriores ni revertir integracion.

## Scope autorizado

UNA invocacion real de scripts/run-patient-links-real-qa.py --execute-readonly,
desde D:/Mavric/Health Project. El mismo contextoB5R2 mantiene backend/proxy durante
Edge y cierra solo sus Jobs despues. Usuario-runtimeSQL por helperDPAPI aprobado;
appmanifestCurrentUser trescuentas sinteticas por wrapper aprobado, solo memoria
yNode stdin trasJob. No passwordargv/env/log/archivo, token/cookie/HAR/video/trace.
Solo login propio POSTauth/browser/login, logoutpropio DELETEauth/browser/session
yGET de negocio/rutas previstas; ningun DELETEnegocio/POSTpatients/PUT/fixture/
roles/estado, email o globalaccount. Navegacion real sin route.fulfill/mocks.

Source/manifest pines de argv estructurado (sin shellbuilt):

```text
C:/Users/maxmo/AppData/Local/Programs/Python/Python311/python.exe -B
D:/Mavric/Health Project/scripts/run-patient-links-real-qa.py --execute-readonly
--approved-launcher-sha256 7CDFB57014A9CA84694E07429AC145B55ED162CFDA54AFB07D9CAC1A161359F2
--approved-runner-sha256 3D0A86B22EB6BED912104B830860C0C8598CA400A7DB514CE8923472269B1359
--approved-environment-sha256 E1589AA904E274DCFD3E0E63D32D715CF732036E5ECA01B4A461305690C2BFD5
--approved-manifest-sha256 6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6
```

PythonlaunchercontextB5 180s, Nodecontained120s. Pins726/jar85D8.../store7988...
sin cambios. Directorio de reporte NO debe existir:
frontend/test-results/patient-links-real-qa/pacqa-20261109-a1/b5-readonly-e3.
DiariosB5-E3-readonly-attempt/completed yB5-E3-browser-attempt/completed en
TEMP/B4P1-prepared deben estar ausentes. Reservar TEMPB5E3-attempt propio una vez;
no borrar/reusar diarios/directorio ni reintentar tras fallo. Probespublicos
internos del contexto son preflight de ESTAoperacion, no rerun deP1 oA69.

Ownership fuentes NINGUNA: solo NUEVOS TEMP B5E3 para harness/capturas/reportes
ypaths de salida del runner ya revisado. No modificar scripts/backend/frontend/
SQL/config/deps/docs ni los inputs/historial. Si falta input/fixture, FAIL ySTOP,
sin aprovisionar ni consultar otro checkpoint/credencial. No TLSApply/UAC/
certificados/servicios/bootstrap/migraciones/grants/Docker/FactuEz/main/push/gasto.
SQLQA debe estar Running loopback14335 ypuertos18080/18300 libres antes de secreto;
no arrancar/reiniciar SQL ni cerrar procesos ajenos para facilitar prueba.

## Pre/post readonly de conservacion y auditoria

Autorizadas SOLO cuatro invocaciones adminSQL readonly de evidencia (LPCWindows
Integrated al destino/marcadorQA fijo, no cuentaSQLruntime):

1. Baseline()B1 revisada, NUNCAmain/PRE/POST/fixtures. Capturar estado estable.
2. Query preaudit supervisora ya comprobada enmotor:
   tmp/pac-01-b5-20261110/pre-audit-query.sql SHA256
   488152DE7D41E5598917437A4DD1A3145A34800A6B36103B25B944F0AA713945.
   Es COMMONguard+SELECTB5_PRE, devuelve maxauditID/cutoffs/hasheshistoricos y
   conteosfixture sin valores/nombres/passwords/CSRF. Revalidar antes de ejecutar;
   supervisoractual humanPatients1/humanLinks1/animalPatients1/animalLinks0.
   Exigir esos prerequisitos (humanLinks>=1) antes de wrapper; capturar epochREAL,
   no reutilizar timestamp/maxID del probe supervisor como si fuese capturaE3.
3. Tras retornar launcher/teardown, misma baseline()B1 de nueva conexion.
4. Postaudit usando plantilla supervisora tmp/pac-01-b5-20261110/post-audit-template.sql
   SHA2560745D9B0F615E767C1F4A0334FFB30C3B108E9DFED889C0B150499712676CFCD,
   prefijada SOLO con COMMONguard del verificador8DF151ED...BAC15CA1.

Construir postaudit exclusivamente con maxIDint>=0, cutoffsISO datetime2(6)
regexestricto, y filas del reporte cerrado validado por launcher. Cada observed
read UUIDcanonico/statusint/actorUUIDonull/tenantUUID/patientUUID; deduplicar con
rechazo a conflicto. Sustituir placeholders exactos __AUDIT_MAX__,__SESSION_CUTOFF__,
__TRACE_CUTOFF__,__OBSERVED_ROWS__; ultima sustitucion SOLO INSERT @seen con
valoresUUIDcanonical/int/NULL. No cadenas arbitrarias, phases/filas/secretos
interpolados ni comandos externos. @seen es variablemetadata local, no tabla
de negocio. Con0lecturas no INSERT. n.invoke SQLcmd fijoLPC/-V11/parserframe
revisados, stderrvacio/raw0/frameB5_PRE oPOSTexacto; no ocultar erroresSQL.

Template fue validada con conjunto observado VACIO ymotorreadonly, no como
positivo de auditoriareal. Dos errores iniciales de preparacion (Msg468 collation
y8124 aggregateouterref) estan preservados; plantillaFINAL tiene collationBIN2
explicita y dosconteoscorrelacionados. No editarlos/repetir sus versiones fallidas.
La prueba positiva de correlacion es ESTA E3 tras lecturasreales; no contar el
emptytest como lecturasAPI o negocio.

Comparar exactos antes/despues: users,tenants,memberships,patients,patient_links,
application_state,modules,columns,acl,principals,role_memberships,installed,
role_acl_count,optional_history,application_mode. installed1/ACL564/OPEN esperados.
Los hashesglobales auth_sessions/audit_events PUEDEN cambiar por operaciones
autorizadas; contrastar oldAuditHash/oldSessionsHash/oldTracesHash usando los
maxID/cutoffs precapturados. No exportar valores/token_hashs/csrf ni reseedIDs.

Si runnerPASS: auditViolations0, unobservedNewLinkAuditCount0,
newLinkAuditCount=successfulReads=conteo observed status200, observedReads igual
alreporte ynegativeReads resto (401/404). Cada200 exacto1audit conactor/tenant/
target/requestrouteGET/metadata{}; negativas ninguno. Hasheshistoricos iguales,
newSessions3, newSessionsRevoked3, unexpectedNewSessions0, loginAuditCount3,
logoutAuditCount3, unexpectedNewAuditActions0. Si runnerFAIL, capturar postestado
ypostaudit autorizados disponibles con sus limites, sinforzar esoscuposdePASS
ni compensar; overallFAIL yreview. Si reporte falta/malformado, no inventar
lecturas; conjunto vacio para evidencia limitada yFAIL, no diagnosticosSQLextra.

Antes/despues huella protegida a04d8236d807b3527dce32d8c8168e2e691902c89c0dd3eb79dda933ae8ca2af
con helper3FBC605A...831 dot-source Get-QaProtectedBaseline, no Invoke/Apply/Start.
SQLQA sigueRunning yloopback14335; tras cierre listenersapp/proxy ausentes,
Jobsapp/proxy0 ycontainedNode/Edge cleanup medido segun apartado de captura E3. No asumir activos0 si
faltanevidencia. Capturar tiempos/exits ycada invocacion; outertimeout240s deja
que los120/180 del launcher cierren Job antes. SinSQL/APIextra ni trafico concurrente.

## Adaptacion obligatoria de captura E3 y cleanup

Puede adaptar SOLO un NUEVO TEMP B5E3-harness.py y observe/reportes nuevos desde
el harness E2 preservado. No ejecutar el harness E2, no editar fuentes versionadas.
Fijar ENV=TEMP/B5R2-environment.py y MANIFEST=TEMP/B5R2-reviewed-pins.json,
cuatro hashes de argv arriba, output b5-readonly-e3 y cuatro diarios B5-E3-*.
No copiar a ciegas los validadores E2: launcher ahora devuelve nodeCleanup
anidado y diagnostic opcional de FAIL; browser-completed contiene lo mismo.

Validar output estructurado cerrado, sin stderr: PASS exige el conjunto de claves
PASS previo mas nodeCleanup; FAIL permite status/code/automaticRetry/
credentialsPrinted, nodeCleanup y diagnostic opcionales segun etapa. code debe
pertenecer al enum del wrapper, diagnostic validado por validate_diagnostic y
nodeCleanup por validate_cleanup del wrapper pinneado importado de forma inerte.
Nunca guardar stdout/error arbitrario ni importar helpers que descifren secretos.
FAIL siempre conserva rawExit y observaciones parciales, no se transforma en PASS.
Los diarios del contexto siguen planos; browser-completed se compara al output
validado, permite solo su esquema cerrado anidado, no cualquier dict generico.

PASS requiere nodeCleanup.code=COMPLETE y activeProcessesAfterStop=0 medido en
QueryInformationJobObject tras stop y antes de CloseHandle, assigned/stopAttempted/
jobClosed/processWaited/processDrained/streamsClosed todos true. Mantener contador
null o no cero y codigo de fallo cuando eso sea lo observado; no inferir Node/Edge0
por retorno o EXECUTION_FAILED. Teardown app/proxy tambien exige activos0 y puertos
cerrados. La verificacion es de los Jobs propios; no enumerar ni matar Edge ajeno.

Capturar hashes E1/E2/R2 historicos antes/despues. No suites offline/build/sondas
extra, cambios TLS/servicios, fixtures, cuentas o SQL fuera de las cuatro queries.
Si nueva ejecucion falla, reportar paso/categoria cerrados y evidencia disponible,
worker_done failed y STOP sin retry, correccion o diagnostico operativo adicional.

## Resultado

Informe TEMP/B5E3-programmer-report.json con IDs/UNAinvocacion/exits/checks,
hashesfuentes695/pines726/diariosE1preservados, reportes/capturas/SHAs del runner,
prepostSQL/audit/huella ycleanup, fallos y limites. El runner debeverificar API
yUIreales sin sustitucion parahumanhistoricopositivo/animalvacio/crossTenant404/
anon401/logout401/temasdesktop-movil. Reportar uiPaging21Exercised observado;
si false, no afirmar21filas navegador; manteneralcance de evidenciaSQL/sintetica
previa separado. SQLauditValidated del runner queda false, agregadoE3 refleja
la correlacion SQLposterior cuando se verifique realmente. Nada es produccion.

SiPASS succeededEN_REVISION, supervisor inspeccionara capturas/diffs/evidencia
independiente. SiFAIL failed ySTOP sin retry/correccion de fuentes/fixtures/
credenciales ni SQLdiagnostico fuera de cuatroqueries. ACK lotes completos antes
deworker_done, conservar sesion/terminal. No suitesoffline yaaceptadas o nuevoRun.
