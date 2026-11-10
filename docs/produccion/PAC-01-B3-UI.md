# PAC-01.B3: consulta de vinculos en la ficha de pacientes

Encargo del arquitecto 2026-11-10, continuidad del Run run_624b9269b491.
B1 SQL validada localmente (PRE40/POST1/instalacion unica) y B2 Java/API
revisada e integrada: Maven verify supervisor1007/1007. No repetir SQLB1 o
suites Java. Esta entrega es UI y pruebas sinteticas; QA HTTP/SQL real con
runtime SQL Server TLS estricto se delegara despues de review. No presentar
interceptaciones de Playwright como persistencia, auditoria o SQL real.

Programador retenido recuperapiura@gmail.com, term_7286bcc6-6224-4d5f-a389-b06a09939ca3,
sesion01a1c5c7-d534-7d01-ac3a-c18bf31075ec, worktree health-programmer propio,
--no-daemon. Usar nuevos Task/Dispatch de preambulo. Leer AGENTS.md del supervisor,
docs/agent-workflow.md, TAREAS, frontend/AGENTS.md y guias INSTALADAS Next16.4.3
en frontend/node_modules/next/dist/docs/01-app/03-api-reference/01-directives/use-client.md
y 01-app/01-getting-started/05-server-and-client-components.md. No usar APIs de
otra version por memoria. Supervisor unico escritor de docs/tablero/veredicto.

## Ownership: seis rutas frontend

- src/components/runtime-patients.tsx (existente, integracion minima)
- src/components/runtime-patient-links.tsx (nueva)
- src/lib/patient-link-types.ts (nueva)
- src/styles/live-patients.css (existente, estilos locales)
- tests/patient-links.test.ts (nueva)
- scripts/patient-links-live-qa.cjs (nueva, QA sintetica independiente)

Prefijo frontend/. Fuentes originales de runtime-patients y CSS coinciden byte
entre supervisor y worker al delegar. Baseline exacta en
tmp/pac-01-b2-20261110/b3-input-baseline.json. Preservar fuentes/ediciones previas
de ambos worktrees y todos los archivos backendB2. No copiar checkout ni resetear.
Supervisor integro legitimamente las ocho rutas B2 despues de su entrega; refrescar
baseline conjunto reconociendo esas siete actualizaciones y una adicion del
supervisor, sin revertirlas ni compararlas como delta de B3. Los hashes finales
B2 de ambas copias coinciden y constan en la evidencia API versionada.
Pedir por Orca antes de ampliar ownership. Artefactos de QA solo TEMP o
frontend/test-results excluido de Git; ningun documento operativo modificado.

## Producto y acceso

En ficha existente ya cargada y fuera de edicion/revision, ADM/REC ve boton
"Ver vinculos" (texto final con tildes). Al abrir, mostrar seccion "Vinculos del
paciente" dentro del mismo Sheet y "Volver a la ficha"; conservar "Cerrar ficha".
No segundo modal, URL nueva ni deep linking en este paquete. Vista inicial
sigue siendo ficha. No disparar GETlinks al abrir ficha/directorio: solo al pedir
esta vista. Al volver/cerrar/cambiar paciente desmontar y abortar consultas de
vinculos. Edicion/alta/revision/conflicto y descartes de A siguen funcionando;
no permitir que cambiar de vista descarte un borrador ni escribir al consultar.

Permiso especifico patientLinksAccess: reutilizar patientAccess y exigir ADM o
REC adicional. Coincidencia sesion/host/tenant y dominio HUMAN/ANIMAL, nunca
SAD/SOP/PAC/RES incluso mezclados, ni PRO/ASI/AUD/CAJ solos. No reutilizar
writable para esta capacidad: PRO puede editar ficha pero no leer vinculos.
No condicionar lectura a PORTAL/modulos/estado writable; ADM/REC en SUSPENDED
conserva consulta. La autoridad definitiva es API/SP. Ningun endpoint de
vinculos ni texto de terceros en roles sin acceso. Cambio de tenant/host/usuario/
roles invalida estado y peticiones, aprovechando key/contexto existente de A.

Mostrar nombre, relacion, estado DEL VINCULO y alcances. "Vinculo activo" o
"Vinculo inactivo", y aclaracion: "El estado corresponde al vinculo y no confirma
el acceso actual al portal." Nombre/relacion vacios historicos tienen etiqueta
"Nombre sin registrar"/"Relacion sin registrar". scopes conocidos APPOINTMENTS,
DOCUMENTS,BILLING se traducen a Citas,Documentos,Facturacion; vacio "Sin alcances
registrados". Desconocidos son referencias historicas, texto escapado seguro,
sin convertirlos en permisos actuales ni ocultar silenciosamente el dato.
Conservar orden/duplicados de scopes; usar keys de indice para ese caso.
No mostrar userId/tenantId/patientId ni correo/hash/tokens o campos extras.
No exportaciones, directorio global, alta/edicion/revocacion de vinculos o
controles ficticios de esas capacidades. Esta entrega es consulta administrativa.

## Datos, paginacion y estados

api('/patients/'+id+'/links?limit=21&offset=...') con helper existente y
AbortController, cookie/no-store/expiracion401 vigentes. Sin fetch alternativo,
authmanual, cachepersistente/localStorage ni cambios a api.ts/auth-session.
Pagina20 y lookahead21, offset avanza20; Anterior/Siguiente inequívocos en esta
vista, disabled correctamente, sin total supuesto. No ordenar en JS (SQLcollation).
Paginacion/reload limpian inmediatamente filas anteriores; responses tardias no
pueden repoblar paciente/contexto/pagina vieja. Key con tenant+patient+offset+
refresh y verificacion de abort/current antes de publicar estado. Cada consulta
explicita produce como maximo una solicitud efectiva; sin autoretry/polling.

readPatientLinkPage valida antes de pintar: array<=21, una fila por userId
canonico sin duplicados, tenant/patient esperados canonicos y coincidentes,
userName String<=160,relationship String<=80 (vacios permitidos), active boolean,
scopes array solo String (incluye[],desconocidos y duplicados). Copia/proyeccion
explicita SOLO siete claves de B2 y scopes independientes, inmutables. Rechazar
null/objetos/escalars/tiposincorrectos/IDsajenos o no canonicos; no renderparcial.
Path no admite IDsinvalidos ni offsetfuera de entero0..2147483647, no inyeccion.
Evitar overflow de offset en siguiente. DTO camelCase exacto descrito en B2.

Carga role=status "Cargando vinculos..."; vacio exitoso especifico "Este paciente
no tiene vinculos registrados"; pagina posterior vacia "No hay vinculos en esta
pagina" con Anterior. Error403 permisos,404 paciente no disponible,5xx/red/forma
invalida mensaje seguro con boton "Volver a consultar vinculos"; no mostrar
vacioexitoso ni filas previas.401 delega expiracion existente y borra datos.
No imprimir detalles deApiError del servidor: mensajes locales saneados y
requestId solo con politica existente. Error no debe bloquear volver/cerrar.

## Presentacion, pruebas y evidencia

Respetar tokens/tipografia/componentes existentes en temas blanco/negro/navy.
Vista desktop1440 y movil390 dentro de Sheet: nombres/relaciones/scopes largos
se parten sin overflow de pagina ni controles cortados; filas/lista semantica o
tabla con desplazamiento INTERNO con nombre y foco. Botones/labels/role=status/
alert operables por teclado, foco visible. No depender solo de color para estado.

Unitarias significativas de permisos (incluidos mixtos/SUSPENDED/PRO), contrato,
proyeccion defensiva, []/21/22/duplicados, scopes historicos, path/paginacion.
Runner Playwright NUEVO sintetico, sin backend, route interceptado y deny de
API no prevista; servidor preview solo propio con cleanup acotado, msedge.
Cubrir vista por accion,20+lookahead/siguiente/anterior, vacio/carga/error403/404/
503/forma y401, reload, abort/repuesta tardia al cambiar paciente/cerrar,
roles ADM/REC vs PRO/ASI/AUD ymixtos, HUMAN/ANIMAL, SUSPENDED/sinPORTAL,
0 escrituras,0emails o datos extras, desktop/movil/temas/teclado. Capturas
sinteticas de cargando/vacio/error/lista/paginacion y moviltemas, paths/SHA en
reporte. No ocultar errores iniciales ni simular prueba que no se haya ejecutado.

Ejecutar npm run check, npm test, npm run build y runner nuevo; tambien runner
existente patients-live-qa.cjs como regresion de A que comparte componente.
No editarlo para facilitar el nuevo comportamiento: consulta links es opt-in.
Builddemo + qa:demo13 justificadas por cambio de importacion compartida, manteniendo
demo sin API; reportar por separado. Sin suites backend/SQL/TLS/QAreal.

Informe TEMP B3-programmer-report.json: IDs, seis rutas exactas, SHAbefore/
after, baselineconjunto preservado, comandos/exits/conteos, capturas y artefactos
con SHA, fallos iniciales y limites. No fuentes supervisor modificadas, docs,
backend/scripts/deps/config/AGENTS u otras rutas. Sin servicios SQL/certificados/
UAC/DPAPI/TLS/secretos/Docker/gastos/datosreales/FactuEz/commit/push/main/shutdown.
Procesar/ack todos lotes Orca antes de worker_done; conservar terminal/sesion.
Entrega succeeded queda EN_REVISION hasta review independiente.
