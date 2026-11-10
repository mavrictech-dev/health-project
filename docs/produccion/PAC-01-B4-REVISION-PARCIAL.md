# PAC-01.B4.P1: revision parcial y continuidad del mismo Dispatch

2026-11-10. Task task_131aca7351c3 / Dispatch ctx_4fcac67b4740, Run
run_624b9269b491, programador recuperapiura, terminal/sesion/worktree retenidos.
Escalacion msg_stop_6bc70500149e3db2f663a2eb: limite del proveedor, reintento
anunciado14:06 hora local. No worker_done ni entrega completa; no cerrar,
abandonar, recrear Task/Run o cambiar cuentas/modelos para eludir la cuota.

Supervisor conserva15archivos parciales en tmp/pac-01-b4-20261110/stopped-review,
con SHA y reporte de auditoria.687fuentes previas verificadas intactas. Java
javacraw0 no es prueba de backend/TLSruntime. Primera suite offline18tests:
17PASS/1FAIL, fallo preservado en B4P1-tests-attempt1.log. No aprobar B4P1
ni invocar --execute-readiness. Correcciones siguen dentro del ownershipTEMP.

## Correcciones requeridas antes de entrega

1. Guardas ZIP: en Windows ZipInfo transforma barra inversa a slash y trunca
   NUL antes de exponer filename. PurePosixPath tambien elimina segmentos '.'
   y vacios. Auditoria pura sin extraer/ejecutar reproduce aceptacion indebida de
   x\y,./a.class,//a.class y a\0.class. Validar metadata ORIGINAL
   orig_filename frente a filename, controles/NUL y segmentos crudos antes de
   normalizar; mantener rechazo de traversal, rutas Windows/reservadas/reparse,
   colisiones casefold y file/dir. Aplicar coherentemente a validated_members
   y helper de preparacion, con pruebas que ejerzan ZipInfo real de Windows.
   No debilitar expectativa del test. La extraccion ACTUAL proviene de jar
   pinneado y se conserva: no volver a ejecutar prepare sobre carpeta existente.

2. Carrera de proxy: await_readiness consulta backend inmediatamente tras
   spawn del proxy. Si backend responde200 antes de que Node emita su linea
   startup, validate_proxy recibe stdoutvacio y falla PROXY_REJECTED. Auditoria
   con dobles reproduce este fallo con0conexionesHTTP reales. Esperar arranque
   completo de proxy de forma acotada y verificando vida/salida exacta; distinguir
   vacio/parcial todavia pendiente de salida mala, timeout o earlyexit. No aceptar
   vacio como listo ni omitir validacion. Pruebas deterministas delayed output,
   partial/full, earlyexit/timeout y stderr/malformed. No arrancar app/proxy real.

3. Recursos en error: NativeJob crea tres pares os.pipe en una expresion y solo
   despues los agrega a self.pipes. Si falla segundo/tercer os.pipe, los FD ya
   creados quedan fuera del cleanup. Registrar cada par inmediatamente al crear,
   cerrar todos los propios ante fallo y demostrar error inyectado2/3 con prueba
   significativa. No kill global/PIDs ajenos ni cambio del orden Job/suspend/
   assign/resume/stdin. Inspeccion estatica; no se consumio probe nativo por esto.

## Retomar y cerrar P1

Mismos Task/Dispatch y limites de PAC-01-B4-PREPARACION.md; no nuevas fuentes de
producto. Primero preservar snapshots parciales y fallo1, corregir y ejecutar
suite offline. Completar pins finales/manifest y compilacion si cambian clases.
Los dos probes permitidos por P1 (publicinspect y timeout inocuo) siguen sujetos
a su limite original: documentar consumo real y no repetir uno ya ejecutado.
No hay evidencia de ellos en la entrega parcial; no inventar PASS o consumos.
No DPAPI/SQL/API/backend/servicios/certificados/UAC ni --execute-readiness.
Informe final con hash/delta/suite/probes/activos0 y limites; consultar/ack lotes
antes de worker_done. Entrega succeeded sera EN_REVISION y requiere veredicto
supervisor antes de E1. Cuota es bloqueo temporal, no abandono del objetivo.
