# Evidencia de la demo conectada — 2026-11-16

Aceptación y límites: [revisión del supervisor](../../DEMO_DOCKER_LAPTOP_REVISION_20261116.md).

- `worker-INFORME.md`, manifiestos y preservación: entrega original del programador;
  SHA256/tamaños referidos a sus archivos originales, contrastados antes de integrar.
  El manifest de 131 artefactos documenta también logs e intentos conservados en
  su directorio temporal; no todos se duplican aquí.
- `delivery-review.json`: contraste independiente de las 14 fuentes y 131 artefactos.
- `build-test-extract.txt`: extracto del build supervisor, 43 tests ordenados y
  1.162 de verify. Las 35 pruebas de producción están incluidas en ambos recorridos;
  no se suman a 1.162 como pruebas distintas.
- `clean-snapshot-*.json` y `clean-snapshot-build-extract.txt`: segunda construcción
  desde copia limpia del índice con finales de línea Windows, SQL byte a byte,
  template público/config, enlaces y ausencia de ZIP/env privado. Build completo
  43/1.162 tests, frontend check/build y helper offline PASS. El candidateTree es
  el árbol previo a añadir estos resultados de cierre, con las mismas 14 fuentes.
- `host-gateway-result.json`, `independent-*.json`, `setup-verify-extract.json`:
  puerto host, reinicio real, segundo arranque, permisos y recursos anteriores.
- `agenda/result.json` y 11 PNG: corrida independiente `supervisor-20261116`.
  Un 502 del sondeo durante reinicio deliberado aparece en serverErrors y
  expectedDowntime; pageErrors vacío. Mismo navegador/sesión y datos conservados.
- `accounts/result.json` y cuatro PNG: identidades ADM/SAD reales, organización
  y clientes en desktop/viewport móvil; sin errores de página ni 5xx.
- `clinical/result.json` y cuatro PNG: paciente, antecedente nuevo y consulta
  escrita recuperada tras recarga; sin errores de página ni 5xx.
- `additional-accounts.cjs` y `clinical-demo.cjs`: harnesses independientes del
  supervisor, ejecutados dentro de la imagen QA mediante Node en Docker, no en host.
  Solo fixtures sintéticos del proyecto `health-meeting-demo`.

Las capturas no se editaron. Viewport móvil 390×844; sin teléfono/micrófono físico.
No contiene `.env.demo`, credenciales privadas, cookies, tokens, HAR o perfiles de
escritorio. Las credenciales publicadas en el template son ejemplos locales.
No hay entrega ZIP ni validación de destino productivo en este directorio.
