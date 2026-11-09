# PAC-01.A.R1: recuperar un alta rechazada con409

Revision supervisora del9nov sobre task_31e1eebbbecf/ctx_265e4fe4a23b.
La entrega queda DEVUELTA por R-PAC-CREATE409, sin integracion al supervisor.
Continuan vigentes PAC-01-A.md y D-83; no ampliar alcance.

## Hallazgo y reproduccion independiente

POST `/patients` responde409 con JSON valido de rechazo de identificador.
PatientPanel guarda conflict=true y blocked=true para alta y edicion por igual.
Se deshabilitan Confirmar guardado y Volver al borrador. Se pide recargar una
ficha que aun no existe; Comprobar directorio no permite corregir el borrador.
Solo queda descartarlo completo e iniciar otra alta. El conflicto confirmado
no tiene la misma recuperacion que un resultado de escritura desconocido.

Reproduccion Playwright independiente sin API real en
D:/Mavric/Health Project/tmp/pac-01-a-20261109/review/independent-browser.cjs;
JSON y create409-independent.png en el mismo directorio. Snapshot de ocho rutas
con hashes exactos y ownership-proof.json tambien alli. No modificar esa evidencia.

## Correccion solicitada

Para POST409 con respuesta valida: explicar que el servidor rechazo el alta y
permitir volver al borrador sin perder nombre/contacto/fecha/especie. El usuario
puede corregir identificador y revisar/confirmar de nuevo explicitamente. Ningun
reintento automatico, exito ficticio ni GET a un ID inexistente. No incrementar
revision ni tratar ese rechazo confirmado como commit o resultado desconocido.

Conservar PUT409: bloqueo de reenvio y recarga explicita de ficha/revision con
descarte avisado. Mantener bloqueadas las altas inciertas por red/5xx/respuesta
invalida, incluido409 noJSON (transporte lo clasifica como resultado desconocido).
No aflojar guardas de permisos, tenant, dominio, contactos/revision o CSRF.

## Ownership y orden

Solo estas tres rutas en worktree del programador:

- frontend/src/components/runtime-patients.tsx
- frontend/tests/patients.test.ts
- frontend/scripts/patients-live-qa.cjs

Los otros cinco archivos A permanecen iguales a los SHA entregados. Cambiar una
cuarta ruta requiere preguntar primero. Leer instrucciones absolutas
D:/Mavric/Health Project/AGENTS.md, frontend/AGENTS.md y guia Next instalada.
Conservar las87 entradas historicas y baseline inicial de496 archivos; registrar
delta adicional respecto del snapshot revisado. Supervisor unico escritor de docs.

1. Corregir y agregar regresion de POST409: un envio, borrador recuperable con
   datos conservados, identificador corregido y una segunda confirmacion manual
   con respuesta validada. Verificar que no se realice segundo envio antes de esa
   confirmacion. Regresion de PUT409 tras recarga: expectedRevision nuevo, no viejo.
2. Repetir TypeScript, pruebas frontend, build live y harness sintetico actualizado;
   conservar los negativos de alta incierta y409 noJSON. Informar exit y resultados.
3. Ejecutar despues (secuencial, misma cache Next) build:demo y qa:demo con preview
   local separado. Demo debe conservar13 recorridos y0 API reales/errores. No
   modificar scripts existentes de demo ni dependencias para hacerlos pasar.
4. Informe TEMP, hashes, delta, captura sintetica de conflicto recuperable en
   escritorio y movil, limitaciones. Revisar/ack todos los lotes antes de done.

Si una suite falla, corregir dentro de ownership o escalar; no declarar success
ocultando el fallo. No SQL/backend/servicios/certificados/DPAPI operativo ni
escrituras reales. A69 sigue bloqueada por UAC. No commits/push/main ni FactuEz.
Entrega nuevamente EN_REVISION; done no equivale a aceptacion independiente.
