# Revisión independiente HP8 — 14 de noviembre de 2026

Estado final: REVISIÓN CERRADA Y VALIDADA LOCALMENTE. R1 aceptada e integrada tras
revisión independiente; configuración productiva preparada, sin aprobación de
despliegue o piloto clínico. La entrega P1 failed no se reescribe.

## Fuentes y revisión

Base 8a6a6ae, rama health/production-wave0. Trabajador P1 task_03a2c125e1f5 /
ctx_b8f875be5131; informe msg_ece3df8dee17. Supervisor contrastó 166 artefactos
con su manifest: cero discrepancias. Congeló ocho fuentes, revisó todos sus diffs
y las integró provisionalmente por SHA exacta, con backup del checkout anterior
en tmp/hp8-supervisor-20261114/root-before. No se recuperó trabajo del viejo
worktree ni se modificaron sus archivos. Documentación previa se conserva.

| Hallazgo | Revisión supervisora | Resultado funcional |
| --- | --- | --- |
| F1: horario ambiguo de 30 minutos | Conversión compara offsets de ambos lados del cambio, además de validar hora inexistente; prueba Lord Howe negativa y hora válida | CORREGIDO LOCAL |
| F2: voz → manual perdía datos | Cancelación del asistente entrega borrador parcial; conserva fecha/hora elegida y requiere revisión antes de reservar | CORREGIDO LOCAL |
| F3: filtro y paciente seleccionado incoherentes | Ficha seleccionada se conserva fuera de los resultados; alta y recuperación de respuesta desconocida conservan la misma identidad | CORREGIDO LOCAL |
| F4: mock de cobro e idempotencia | Clave vinculada a cita/cuerpo; replay devuelve recibo original; valida medio, revisión, límites, rol y sucursal | CORREGIDO EN DEMO |
| F5: V13 no reproducible tras checkout | V1–V19 preservan los bytes canónicos; índices y checkouts aislados true/false verificados por supervisor; SQL y pines originales intactos | CORREGIDO LOCAL |

El controller Java productivo no cambió: sus pruebas adicionales verifican campos
obligatorios, selección de sede/roles antes del store, parámetros y conflicto409.
Ningún cambio al acceso SQL runtime o a permisos se deriva de estas correcciones.

## Verificación propia del supervisor

Pruebas ejecutadas sobre fuentes integradas, Java21, en el checkout principal:

| Verificación | Resultado |
| --- | --- |
| backend/mvnw.cmd -o clean verify, P1 integrada | 1.127 pruebas, 0 fallos, 0 errores, 0 omitidas; exit0 |
| backend/mvnw.cmd -o clean verify, R1 completa integrada | 1.162 pruebas, 0 fallos, 0 errores, 0 omitidas; exit0, JAR final generado |
| ProductionProfileTest, incluido en suite final | 35 pruebas con ConfigData/SpringApplication/factory reales, drivers simulados y cero conexiones; JWT estable entre contextos y rechazos antes del datasource |
| frontend/npm.cmd test | 126/126; exit0 |
| frontend/npm.cmd run check | TypeScript exit0 |
| frontend/npm.cmd run build:demo | exit0 |
| frontend/npm.cmd run build, sin APP_MODE=mock | runtime estático exit0 |
| Regresiones de borrador/selector en navegador | Nombres Ana/Rojas y hora13:30 conservados; ficha seleccionada coherente; desktop/móvil; exit0 |
| Runtime con HTTP interceptado sintético | 6 grupos: revisión sin escritura, reintento con misma clave/cuerpo, cobro/409, recuperación de alta, 7 roles; exit0 |
| Recorrido HP8 demo | calendario/reserva/voz/cobro/arqueo/móvil; exit0 |
| Regresión RUC/HP4–HP7 demo | acceso, sucursal, catálogo, antecedentes, consulta y dictado; exit0 |
| git diff --check | exit0 |
| Cleanup | solo dos previews propios detenidos; listeners18428/18429 ausentes |
| Compose dedicado, valores ficticios | exit0; backend privado, gateway loopback, secretos por archivos, dos servicios; sin daemon |
| nginx1.28.0 -t | exit0 con plantilla final exacta; solo sintaxis Windows, sin servidor |
| JAR ejecutable real sin JWT | exit1 ESPERADO, HP_PRODUCTION_JWT, sin iniciar servidor; configuración/contraseña exclusivamente sintéticas |

Los tres harnesses P1 se ejecutaron desde copia local del supervisor; el de HTTP
solo adapta18329→18429 para no competir por puertos. Salidas, fuentes, comandos y
42 capturas NUEVAS en evidencias/hp8-cierre-20261114. Los scripts usan fixtures
sintéticos y voz simulada; no se atribuyen a Java/SQL real ni a micrófono físico.
Artefactos crudos y logs completos permanecen en tmp/hp8-supervisor-20261114.

Inspección visual directa del supervisor: calendario semanal, error de revisión
de cobro, paciente seleccionado con filtro vacío, borrador tras permiso denegado,
esas dos vistas en móvil, agenda runtime móvil e historia clínica móvil. Texto y
campos legibles, estados coherentes y scroll interno de formularios/calendario;
sin desbordamiento horizontal de página ni errores JavaScript en los harnesses.
No se afirma inspección manual individual de las 42 capturas completas.

## Límites y siguiente aceptación

Las 62 comprobaciones HTTP reales de HP4–HP7 y las 40 de HP8 conservan su fecha
13nov; no se reejecutó SQL en este corte. Los 241 perfiles y permisos no se
revalidan desde screenshots o tests mockeados. Fuente canónica de migraciones
permanece sin cambios de SQL; solo se corrige su conservación binaria en Git.

R1 task_81906d33c50e / ctx_38f36396ce9b terminó succeeded/settled mediante
msg_8dbdf027d49f. Supervisor verificó 36 huellas de fuentes y 171 artefactos, sin
discrepancias o cambios fuera de ownership, e integró las ocho fuentes B exactas.
Los checks propios anteriores corresponden a esas mismas fuentes finales.

El guard de production se registra por META-INF/spring.factories, mecanismo
contrastado en el jar instalado y [documentación de Spring Boot](https://docs.spring.io/spring-boot/how-to/application.html).
Rechaza JWT ausente/corto/control, HTTP/host/puerto inválidos, entradas SQL
ausentes, TLS relajado y configuración de migración/bootstrap/jobs/legacy insegura.
Fuera de production es inactivo. No se cambian selector, Settings o BranchTokens.
Secretos por config-tree obligatorio; no hay clave aleatoria aceptada en production.

Conservación binaria: V1–V19 y pins originales intactos; equivalencia LF del SQL
previo/HEAD/canónico. Ambos índices/checkouts propios compararon 19 blobs y 19
archivos cada uno; índice/config Git reales permanecieron intactos durante el QA.

Se conservan fallos de desarrollo corregidos: harness inicial de contexto, dos
entradas SQL que Binder dejaba como placeholders (guard corregido sin debilitar
negativos), representación del filtro Compose, directorio temporal de nginx y
ubicación de factory en el JAR. El primer nginx-t supervisor pasó sintaxis pero
falló por directorio temporal ausente; corregido solo el harness y repetido exit0.
No se presenta como una pasada ininterrumpida. Informe/manifiesto del trabajador
y resultados propios en evidencias/hp8-cierre-20261114.

Fuentes de preparación aceptadas; empaquetado y huellas se registran en
SALIDA_PRODUCCION_20261114.md. Imágenes Linux/destino, backup/restauración,
carga/seguridad y aceptación clínica/productiva siguen pendientes. No Somee,
datos reales, main o despliegue.
