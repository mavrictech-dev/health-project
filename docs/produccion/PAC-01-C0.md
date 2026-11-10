# PAC-01.C0: cerrar brechas para gestionar vinculos y responsables

Supervisor 2026-11-10. Continuidad del objetivo autorizado de terminar pendientes
por dependencias. Mismo Run run_624b9269b491/programador recuperapiura,
terminal term_7286bcc6-6224-4d5f-a389-b06a09939ca3, sesion/worktree retenidos,
cuenta por proceso --no-daemon. Nuevos Task/Dispatch del preambulo. Leer AGENTS.md
absoluto, flujo, PLAN_EJECUCION_PRODUCCION.md, TAREAS.md, D-87.AE y este contrato.
Supervisor unico escritor docs/tablero/diseno/aceptacion.

## Dependencia aceptada y objetivo concreto

PAC-A administrativo ya aceptado. B lectura de vinculos termina en E5
task_c91a2e2ed153/ctx_5ae9ea240b92 VALIDADA LOCAL REAL tras review independiente:
7 controles,18 lecturas (15x200/2x401/1x404),15 auditorias exactas,3 nuevas
sesiones revocadas,0violaciones. Supervisor35artefactos/695fuentes/726pines/
252historicos,baseline fresco SQL/sistema iguales y8capturas inspeccionadas.
PACIENTES_VINCULOS_QA_REAL_20261110.json. UI21lookahead no ejercitada con fixture
real pequena; SQL/sintetica anterior aparte. E2-E4 fallidas preservadas.

Falta gestionar vinculos y responsables desde interfaz con persistencia segura;
no se cierra todo PAC-01 por aceptar lectura. Antes de modificar contratos,
C0 debe entregar un analisis verificable de las brechas y el paquete minimo
siguiente para decision de arquitectura. NO implementacion aun, sin simulacion
de validacion real desde analisis.

## Preguntas tecnicas que debe resolver con fuentes exactas

1. Inventariar ruta PUT /api/patients/{id}/links, DTO Requests.Link,
PatientService.link, SqlServerPatientStore.link, descriptor PATIENT_LINK_SAVE,
SP real heredado y migraciones V1-V13, guardas de sesion/tenant/rol/modulo/estado,
auditoria y consumidores portal. Citar archivo:linea y hashes; no inferir estado
de SQL instalado desde codigo (no consultar motor ahora).
2. Tabla patient_links: clave, columnas/revision si existe, unique/FK/checks,
principal runtime y ACL, transaccion externa/locks, reactivacion/desactivacion,
ambiguedad de escritura concurrente. Identificar por que API PUT actual basta
o no para edicion con expectedRevision/409; no asumir revision del paciente
protege un vinculo separado. Contratos GET siete campos ya aceptados se conservan.
3. Identidad candidata de vinculo: donde se crean/consultan usuarios PAC/RES,
scope tenant y roles reales; distinguir cuenta de portal de responsable sin
cuenta. Determinar si existe busqueda apta y parametrizada por SP con paginacion
y proyeccion minima. No lookup global por email, no inventar cuentas/invitaciones
o duplicar el paciente. Historicos inactivos no prueban acceso actual.
4. UX minima dentro de ficha existente: rol ADM/REC y modulo PORTAL/guardas de
escritura para gestionar, consulta readonly separada sin PORTAL obligatorio;
seleccion segura de candidato, relacion, alcances explicitos, confirmacion,
desactivacion sin borrar historia, conflicto con borrador conservado, resultado
desconocido sin reenvio automatico, retorno/refresco, teclado/movil/temas.
No proponer modal sobre modal o exponer UUID/email tecnico a cualquier rol.
5. Proponer matriz de aceptacion por capas y ownership secuencial: SQL/SP y
concurrencia/rollback/ACL/audit, DTO/API/errores neutros y autorizacion, UI
sintetica/regresionA+B, preparacion y futura QA integrada aislada. Separar
alta/edicion de responsables sin cuenta de la concesion de acceso portal.
Datos reales, invitaciones/correo, cambios TLS/servicios, produccion fuera.

## Decisiones de arquitectura que no se pueden relajar

SQL Server y100%SP parametrizados para toda lectura/escritura, runtime EXECUTE
solo SP aprobados sin tablas/DDL, principal migracion separado. No alterar V1-V13
ya instaladas; cualquier cambio futuro en migracion NUEVA y no ejecutada en C0.
No perder siete campos GET o semantica historica/orden/paginacion/roles. Edicion
futura necesita control explicito de concurrencia, revalidacion SQL de autoridad,
audit atomico y revocacion efectiva; no atribuir permisos desde texto o listado.
No portal/historia automaticos por crear paciente, responsable o relacion.
Si propuesta cambia API existente o modelo, documentar compatibilidad, consumidores
y alternativas; supervisor define contrato final antes de delegar implementacion.

## Ownership y evidencia

SOLO nuevos TEMP B5C0-* (analisis, hashes y reportes); ningun archivo versionado o
fuente supervisor/trabajador se edita, sin git reset/sync/commit/push. Comparar
baseline 695 fuentes con hashes legitimos actuales antes/despues y 726 pines;
preservar todo historico/contextos/diarios E1-E5/R2-R4, capturas y datos existentes.
Puede leer fuentes, pruebas y documentos necesarios; sin lanzar suites aprobadas,
compilar/build, Node/Edge/procesos operativos, SQL/HTTP/DPAPI/credenciales o servicios.
No FactuEz/cuentas globales/gastos/main/despliegue/shutdown. Nada de mockups que
se confundan con producto integrado; diagramas contractuales TEMP opcionales.

TEMP/B5C0-programmer-report.json con IDs, resumen, referencias archivo:linea y SHA,
hallazgos clasificados confirmado/inferencia/falta de informacion, propuesta de
paquetes y ownership/aceptacion, bloqueos reales y opciones, baseline/pines/historia
sin delta. Analisis legible adicional TEMP/B5C0-analysis.md. No copiar secretos
ni valores de usuarios/datos operativos. Si completo: succeeded EN_REVISION,
sin marcar gestion implementada. Si insuficiente: preguntar por Orca sin ampliar
alcance. Procesar/ACK lotes antes de worker_done, mantener terminal/sesion.
