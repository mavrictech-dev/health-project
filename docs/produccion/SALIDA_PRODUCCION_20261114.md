# Preparación de salida — Health Project

Fecha: 14 de noviembre de 2026. Estado: CANDIDATO LOCAL PREPARADO Y VERIFICADO;
producción NO autorizada y condiciones del destino pendientes.
Este documento define la salida de RUC y HP4–HP8; no convierte el
backlog clínico completo ni los 241 perfiles en funcionalidades habilitadas.

## Alcance del candidato

Acceso RUC/correo/sucursal, catálogo y convenios, pacientes y antecedentes,
consulta escrita con estado de cita, dictado por campo, calendario/reserva,
registro manual de cobros y arqueo. Voz de navegador: evidencia simulada; falta
ensayo físico y decisión de privacidad. El registro de cobro no procesa pagos
ni sustituye contabilidad, conciliación bancaria o comprobantes fiscales.

Código base: 8a6a6ae, rama health/production-wave0. P1 parcial se conserva como
fallida; el nuevo cierre R1 está aceptado e integrado con revisión independiente.
Ver HP8-CIERRE-R1-20261114.md. El candidato se generó del commit de fuentes
revisadas `b29303ff8205e4d6a29e5662f252ef2b66445595`; su recibo registra las
huellas, sin depender del SHA base anterior.

## Paquete concreto

Archivo local, excluido de Git:
`tmp/health-production-candidate-20261114/health-hp8-rc-20261114.zip`.
34.842.200 bytes; 708 archivos con manifest individual SHA256 y verificación de
lectura completa del ZIP. Incluye JAR probado y fuentes backend, frontend runtime,
SQL canónico V1–V19, templates productivos y procedimiento de salida. No contiene
credenciales, almacenes de secretos, node_modules, backups/datos SQL u out-demo.

- SHA256 ZIP: `a689096e7d1686ffc493799e5a857bd4448ed0a79b7b23d5f5bfd2cd0688afab`.
- SHA256 manifest: `7f5d3bc85090a288804046b10ebc44a62e121c753d98c8a058919ad89f5ca3da`.
- Recibo versionado: [HP8_RELEASE_20261114.json](evidencias/HP8_RELEASE_20261114.json).

El ZIP conserva los documentos del commit fuente, anteriores al recibo de
empaquetado; manifest y recibo fijan el resultado final. Las imágenes no se han
construido ni seleccionado y no se ha validado un destino productivo.

## Topología preparada

Navegador → terminador HTTPS del dominio base y subdominios → gateway estático
privado → Java21/Spring Boot → SQL Server2022 dedicado al proyecto.
Frontend exportado en modo runtime, API del mismo origen y backend sin puerto
público. Mantener Host original y bloquear hosts ajenos. La aplicación resuelve
tenant y sucursal en servidor; ningún header de tenant del cliente los sustituye.

SQL runtime: cuenta EXECUTE exclusivamente sobre SP aprobados, sin lectura directa,
escritura de tablas, DDL o privilegios administrativos. Migración/bootstrap usan
principales separados en procesos independientes, nunca en el servicio web.
Conexión JDBC cifrada con validación de CA y hostname; no trustServerCertificate.
JWT estable fuera de Git/imagen y sesiones revocables con cookies Secure/HttpOnly
y CSRF. Mantener separados SQL, archivos, credenciales y tenants de demo/QA/prod.

compose.yaml y compose.qa.yaml son heredados MySQL: NO son el despliegue objetivo.
Se prepara compose.production.yaml separado, sin migrador automático ni servicio
MySQL. Somee es un candidato de SQL externo; alojamiento Java, permisos de SP,
cuotas, TLS, copias y conectividad deben verificarse para la cuenta contratada.
No usar AgendlyCitas ni credenciales de otro proyecto. El dominio/host de Java y
la base exclusiva aún requieren confirmación del propietario.

## Condiciones para autorizar el despliegue

| Condición | Evidencia necesaria | Responsable / estado inicial |
| --- | --- | --- |
| Cierre HP8 | Diff aprobado, Maven clean verify1162/0, frontend126/check/build y 42capturas propias | Supervisor + programador; VALIDADA LOCAL |
| Reproducibilidad V1–V19 | SHA canónica preservada, índices y checkouts true/false; SQL y pins sin alterar | Supervisor + programador; VALIDADA LOCAL |
| Paquete de aplicación | 708archivos/ZIP34.842.200bytes; manifest SHA256/roundtrip exactos; HP8_RELEASE_20261114.json | Supervisor; PREPARADO Y VERIFICADO LOCAL |
| Destino exclusivo | Host Java21/Docker, dominio base y subdominios, SQL Server y red/almacenamiento identificados | Propietario/operación; PENDIENTE |
| SQL instalado | Motor/compatibilidad, versión y huellas, permisos EXECUTE-only y seed241; sin reaplicar a ciegas | Migrador + QA; validación LOCAL previa, destino PENDIENTE |
| HTTPS y JDBC | Certificados válidos del destino, cookies Secure, CA/hostname negativos, aislamiento de proxy | Operación + QA; destino PENDIENTE |
| Secretos y acceso | JWT estable, rotación, runtime sin bootstrap y permisos; cuentas privilegiadas protegidas | Operación + seguridad; PENDIENTE |
| Recuperación | Backup cifrado previo y restauración en base vacía aislada; RPO/RTO acordados y medidos | Operación + QA; PENDIENTE |
| Reversión | Aplicación anterior compatible con esquema actual, parada de escrituras y ensayo documentado | Operación + QA; PENDIENTE |
| Carga/observabilidad | Objetivos acordados, concurrencia sin doble reserva/cobro, sondas y responsables de alertas | QA + operación; PENDIENTE |
| Alcance del piloto | Revisión clínica/privacidad, funciones habilitadas y usuarios/soporte preparados | Producto + responsables clínicos; PENDIENTE |
| Autorización final | Aceptación expresa del candidato/destino y uso de datos reales | Usuario/propietario; NO OTORGADA |

Los checks locales y las capturas sintéticas no satisfacen las condiciones del
destino. No se inventan objetivos de carga, plazos de retención, RPO/RTO o
aprobación clínica. Una dependencia pendiente no bloquea preparar artefactos.

## Secuencia operativa para ejecutar posteriormente

1. Fijar candidato revisado y SHA del manifest; registrar persona responsable,
   ventana, destino, alcance habilitado y criterios de aborto. Verificar que el
   paquete contiene frontend runtime, no la exportación demo ni archivos locales.
2. Inventariar el SQL destino en lectura y comprobar que es exclusivo de Health
   Project. Separar instalación nueva de actualización: no ejecutar V1–V19 sobre
   una base existente ni cambiar migraciones aplicadas. Exigir mapping autorizado
   para tenants legacy sin RUC (V15); no rellenarlos con identificadores ficticios.
3. Ensayar instalación/actualización en una copia sintética aislada con la misma
   versión/configuración. Guardar resultado, catálogo/permisos y baseline; revisar
   antes de autorizar el cambio productivo. El runtime no instala esquema.
4. Probar backup/restauración y reversión en entorno vacío. Antes del cambio,
   comprobar backup verificado, secretos, certificados y conectividad del destino.
   Mantener las credenciales de migración fuera del proceso y contenedor web.
5. Aplicar solo versiones nuevas revisadas mediante principal separado y protocolo
   de una ejecución, con resultado y verificación fresca. Ante resultado ambiguo,
   detenerse y reconciliar por lectura; no repetir una mutación por un timeout.
6. Publicar el candidato fijado en entorno de preproducción; probar liveness y
   readiness por separado, login/sucursal/CSRF/revocación, RUC duplicado, aislamiento
   tenant/sucursal, cita concurrente, revisiones/idempotencia, cobro/compensación y
   persistencia tras reiniciar. Usar solo fixtures autorizados y sintéticos.
7. Revisar evidencias y cerrar condiciones pendientes. Solicitar la autorización
   final sobre el candidato y destino concretos; recién entonces ejecutar la
   salida y monitorizar con umbrales previamente acordados.

## Reversión y criterios de aborto

Abortar si falla identidad del destino, huellas/versiones, backup/restauración,
readiness, TLS, aislamiento, permisos, integridad clínica, sesión o idempotencia.
Pausar escrituras y preservar logs sin secretos. Un error de transporte no prueba
que una migración no se aplicó: revisar catálogo y diario antes de actuar.

Volver a la aplicación anterior solo si su compatibilidad con el esquema vigente
se ensayó. No ejecutar DROP, migraciones descendentes, reset de volúmenes ni
reaplicación de V1–V19 como mecanismo de reversión. Si se necesita recuperar datos,
restaurar primero en una base nueva aislada, comprobar integridad/ACL/auditoría y
reconciliar las escrituras posteriores al backup; el cambio de conexión necesita
revisión y autorización operativa. Conservar la base original y la evidencia.

Este turno prepara y verifica localmente; no conecta Somee, modifica DNS, crea
infraestructura, inicia despliegues o utiliza destinatarios/pacientes reales.
