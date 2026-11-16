# Health Project — demo portátil para presentación

Este paquete contiene datos ficticios y la demo compilada. No requiere SQL,
Java, Docker, cuentas ni descarga de dependencias. Requisito: Node.js 24.

1. Descomprime TODO el ZIP en una carpeta propia.
2. Abre una terminal en esa carpeta (donde está este LEEME.md).
3. Comprueba: `node --version`.
4. Ejecuta: `node frontend/scripts/preview-static.cjs --demo`.
5. Abre http://127.0.0.1:3002 en el navegador. Mantén la terminal abierta.
6. Para detener: Ctrl+C en esa terminal.

No abras index.html directamente. Si el puerto está ocupado, usa otra terminal
PowerShell: `$env:PORT='3012'`, seguido del mismo comando node; abre entonces
http://127.0.0.1:3012. Para quitar esa variable tras detener: `Remove-Item Env:PORT`.
En Linux/macOS: `PORT=3012 node frontend/scripts/preview-static.cjs --demo`.

Usa una sesión privada nueva para empezar sin cambios de demostraciones anteriores.
No compartas datos clínicos reales. El preview escucha solo en el equipo local.
La voz depende del navegador y sus permisos; continúa escribiendo si falla.
Cobros/firmas/correos son simulados. Esta demo no es una instalación productiva.

Guion: GUIA_PRESENTACION.md. Código e instalación completa:
https://github.com/mavrictech-dev/health-project/tree/health/production-wave0
