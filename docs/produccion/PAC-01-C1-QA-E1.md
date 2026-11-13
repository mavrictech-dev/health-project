# PAC-01.C1.QA.E1: contrato preparado para una ejecucion PRE local

Supervisor, 2026-11-12. Estado BLOQUEADO por entorno; NO Dispatch activo ni
permiso de ejecutar ahora. La elevacion Windows fallo antes de entrar al wrapper,
SQLQA sigue Stopped y no hay baseline SQL actual. Solo activar tras verificar
OS y delegar con Task/Dispatch NUEVOS al programador retenido. No repetir RunAs
automaticamente. Evidencia: VINCULOS_ENTORNO_C1E1_20261112.json, D-87.AQ.

Leer AGENTS.md, docs/agent-workflow.md, TAREAS.md, PAC-01-C1-QA-SECUENCIA.md,
PAC-01-C1-P2.md y PAC-01-C1-P2-R1.md CANONICOS en D:/Mavric/Health Project.
Programador recuperapiura, arquitecto mendozadeafabisa; verificar identidad
efectiva de nuevo antes del Dispatch, cuentas por proceso y --no-daemon.
No Somee/AgendlyCitas, instancias ajenas, credenciales o datos reales.

## Congelacion y prerrequisitos antes de activar

P2R1 integrada por supervisor, tres herramientas revisadas OFFLINE:

| Fuente | SHA256 |
| --- | --- |
| backend/scripts/verify-sqlserver-patient-link-management.sql | 9476CEC9A4C3906AD9E0D17EA964ED63C4B353372F4F879EEAA13049600C1D4D |
| scripts/verify-patient-link-management-sql.py | CEB2C952D04D7E2A56BCED90A19224A747ACDD55A5455C6DB7C8222CBAA0CC22 |
| scripts/tests/test_patient_link_management_sql_verifier.py | 33F2C0552E81879F99221EF7559D272F8BBD19CACF6BDA5EE92097F15320968E |

V14 exacta B6E34ACA24F95874692C7A0C27F8A967D8E9FB8BFB604E22A976BA04E15C1B52.
Manifest root/tmp/c1p2-e1-20261112/review-manifest.json SHA
7BBCE172E2081C8F0F1781BFB57F5F51FB56E17E57EC4541B16AC621630B7107.
Revalidar fuentes/pines originales y conservar snapshot de ambos worktrees,
artefactos historicos y jar anterior antes de la corrida. No sync/reset/copia
de migraciones al worktree del programador; usar fuentes canonicas ROOT.

OS debe acreditar instancia HEALTHPROJECTQA Running, identidad/rutas Microsoft
SQL2022 y dedicada D:/HealthProject-QA/SqlServer, listeners loopback aprobados,
fingerprint protegido igual antes/despues. Arranque es tarea separada del runner:
no configuracion/auth/TLS/UAC/servicios desde el worker de QA. Si falta, BLOCKED
con cero invocaciones; no usar MSSQLSERVER, otra DB o motor como alternativa.

El runner valida en conexiones nuevas el target fijo lpc:.\HEALTHPROJECTQA,
health_project_sqlserver_qa_isolated_20261105, Windows integrada, Shared memory,
major16/compat160 y marker exacto health_project_scope de138bytes UTF16:
Health Project isolated JDBC QA; provisioned 2026-11-05; no real data.
CONTROL debe ser principal separado de runtime/bootstrap. V13 presente/V14
ausente, OPEN,134SP/31triggers/37tablas y564ACL de roles, o38tablas/573ACL si
ya existe Flyway aprobado. Son prerrequisitos codificados, NO mediciones hoy.
No otorgar permisos ni instalar dependencias para corregir un preflight.

## Ownership y una unica invocacion futura

Programador: SOLO evidencia NUEVA en root/tmp/C1P2-E1-20261112-run01 (directorio
inexistente antes de CLI), root/tmp/c1p2-e1-20261112/execution y TEMP C1E1-*.
No editar fuentes, tests, manifests revisados, docs/board, jars, dependencias,
configuracion o evidencia previa. Supervisor unico escritor documental.

Tras activacion explicita por Dispatch y OS verificado, UNA invocacion desde
fuentes ROOT, no desde copia incompleta del worker:

```text
python -B "D:/Mavric/Health Project/scripts/verify-patient-link-management-sql.py" PRE_APLICACION --review-manifest "D:/Mavric/Health Project/tmp/c1p2-e1-20261112/review-manifest.json" --evidence-dir "D:/Mavric/Health Project/tmp/C1P2-E1-20261112-run01"
```

No crear antes el directorio exclusivo. Capturar stdout/stderr de CLI y exit
una sola vez en archivos binarios nuevos externos al evidence-dir, con timeout
externo suficiente para la matriz sin matar fases por un limite de shell corto.
Nunca reintentar por timeout/recibo perdido/rawexit o para obtener PASS.
Transport fijo SQLCMD.EXE170 SHA7220B526AB97B0A5B30ED7B09C497AB7FAD39141090F8801D68691C38FF248DA,
argumentos/entorno/deadlines y todas las guardas originales inmutables.

111fases secuenciales, V14 transient en TX externa por fase con rollback,
principals propios WITHOUT LOGIN y fixtures sinteticas nuevas. Ningun commit,
instalacion permanente, READ_ONLY global, reparacion, reseed o compensacion.
Journal duradero antes de cada transporte y desenlace saneado; baselines nuevas
previas/post/final de37tablas y metadata completa. Solo last_value de identity
puede diferir segun contrato aprobado. No conceder acceso directo al runtime.

## Fallo, entrega y revision independiente

Parar mutaciones al primer fallo. Conservar causa primaria/stage/phase/nonce,
checks parciales, rawexit y hashes/longitudes de salida; cleanup readonly y
errores secundarios separados. No publicar buffers/filas/secretos ni eliminar
evidencia. Final baseline fallida no reemplaza causa inicial. Sin resumen
duradero o conservacion medida nunca PASS. Resultado incierto se reconcilia
por lectura revisada; no otra corrida ni aplicacion. Consultar Orca antes de
ampliar ownership/sondas. Antes de worker_done procesar todos los lotes y ACK
deliveryId si aparece, mantener terminal/sesion.

Informe NUEVO TEMP/C1E1-programmer-report.json: IDs, fuentes/hashes, comando,
tiempos/exits, journal/summary e intentos,111resultados o prefijo parcial,
baseline inicial/final y conservacion de fuentes/artefactos. No atribuir PASS
de SQL a los35unitarios o parser112. Entrega EN_REVISION; supervisor revisa
evidencia y prepara una baseline independiente readonly acotada antes de aceptar.

PRE rollback no prueba primer RPC JDBC con contador0, commit persistente,
autocommit/pool, carreras de2conexiones, revocacionpostcommit, HTTP/auth/CSRF
o UI. Jarcompatible separado, instalacion unica reconciliada y todos esos gates
siguen posteriores. No desplegar/commit/push/main/gasto/FactuEz.
