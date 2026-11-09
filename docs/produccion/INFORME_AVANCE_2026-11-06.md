# Health Project: avance comprobado al 6 de noviembre de 2026

Actualizacion de cuentas del9nov: el usuario asigno mendozadeafabisa@gmail.com
al arquitecto y recuperapiura@gmail.com al programador. Nuevas sesiones/status
verificados, cuotas semanales91%/15% al observarlas. Este cambio sustituye las
cuentas y cuota0 historicas de abajo; no cambia los resultados tecnicos del6nov.
Ver TRASPASO_ARQUITECTO_20261109.md y evidencias/CUENTAS_ORCA_20261109.json.

A67 está corregida y aceptada. Bootstrap, login, negocio SQL/HTTP y los recorridos
live de acceso/SaaS/organización ya tienen evidencia real. **TLS estricto sigue
pendiente de la elevación de Windows**; el proyecto no está aprobado para producción.

Rama autorizada: `health/production-wave0` en
[GitHub](https://github.com/mavrictech-dev/health-project/tree/health/production-wave0).
No se integra en main ni se despliega.

| Entrega | Resultado comprobado |
| --- | --- |
| A67 | Fix SQLcmd `-m1`;124 pruebas y avisos/error SQL reales. Sin repetir creación de logins ni credenciales. Task original cerrada por revisión del supervisor. |
| Programador | Recuperado en worktree/sesión propios y cuenta `mendozadeafabisa@gmail.com`; cuota semanal0% hasta11nov11:35. Arquitecto `recuperapiura@gmail.com`. Esta entrega fue ejecutada secuencialmente por el supervisor D-79; no por el trabajador bloqueado. |
| SQL local | HEALTHPROJECTQA arrancada, TCP127.0.0.1:14335. Base aislada sintética;133SP finales coinciden con V1–V12;37tablas/31triggers/562permisos sin ampliación runtime. Instancia compartida intacta. |
| Correcciones de negocio | V10 abre la transacción implícita ya seleccionada por JDBC antes de la primera escritura; V11 genera UUID canónico; V12 conserva conflicto409 para segundo profesional DOCTOR. Migrador separado; V1–V9 intactas. |
| Bootstrap/login | SAD sintético creado con login bootstrap separado e idempotencia. Login por navegador, cookie HttpOnly/SameSite, CSRF, logout y revocación contra backend real. Credenciales DPAPI excluidas de Git. |
| API real |177 comprobaciones: tenants, rollback, host/rol, cupos, concurrencia, pacientes, agenda, historia, documentos, portal, caja, inventario y operaciones. Solo datos .example.test. |
| JDBC/pool |8 controles reales: primera escritura, autocommit rechazado, rollback, una transacción física y limpieza/reutilización de la misma conexión. |
| Persistencia |7 controles tras reiniciar backend: sesión/tenant/sedes/historia/saldo persisten, aislamiento y secretos ausentes del log. |
| Navegador real |16 controles de navegación/estados y6 de CSRF/revocación. Alta real de cliente y sede, refresco de cupos y409 por límite.18capturas inspeccionadas en escritorio1440 y móvil390. Sin JavaScript de página ni HTTP5xx inesperados en las pasadas finales. |
| Offline |Maven990/990 y package PASS; frontend TypeScript/68pruebas/build85rutas PASS; herramientas124/124 PASS. Son pruebas unitarias/modelos además de la integración real diferenciada arriba. |
| Demo |Build independiente y13 recorridos PASS, cero llamadas API y cero errores. No se convierte en backend real ni se usa como prueba de integración. |
| TLS |Script local preparado, parser y plan PASS. Windows canceló UAC antes de ejecutarlo: sin nuevos certificados ni binding, ForceEncryption0. Encrypt=true/trustServerCertificate=true solo QA; cadena/hostname/negativos sin validar. Pregunta de nueva aceptación pendiente. |

La prueba de API se reanudó mediante checkpoints cifrados después de corregir
defectos; no fue una pasada ininterrumpida desde vacío. Se preservaron también los
fallos de espera/selectores del harness y las altas ya confirmadas, sin duplicarlas.
El último probe MySQL/Docker se excluyó; JDBC negativo y562ACL SQL tienen evidencia
separada. Las capturas del monitor conservan el500 histórico del defecto corregido.

Falta cerrar A69 con aceptación UAC, certificado/truststore dedicados, conexión
JDBC trust=false y negativos de CA/hostname. El script solo afecta HEALTHPROJECTQA;
no instala confianza global. Después quedan los módulos clínicos del frontend por
etapas y los gates del plan: correo/adjuntos, backup-restauración, carga, seguridad,
aceptación profesional/legal y autorización de piloto/producción. API clínica
positiva no significa interfaz clínica integrada ni habilitación asistencial.

La evidencia anterior JDBC17/HTTP7 del5nov se conserva fechada; no se presenta
como repetida por estas pruebas. Las fuentes/hashes/resultados y18capturas están
en [CIERRE_LOCAL_20261106.json](evidencias/CIERRE_LOCAL_20261106.json).
Seguimiento: [tablero](TAREAS.md), [validación](VALIDACION.md),
[revisiones](REVISIONES.md) y [decisiones](DECISIONES.md).

Se conservan los183 archivos locales del worktree del programador. No se publican
DPAPI/.env/sesiones/logs/tmp/bases/dependencias/binarios. Sin datos reales, gastos,
destinatarios externos, FactuEz, merge en main ni despliegue.
