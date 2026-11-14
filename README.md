# Health Project

Plataforma clínica SaaS para organizaciones humanas y veterinarias, con identidades que pueden trabajar en varios clientes, sedes y especialidades.

**Preparación productiva vigente:** SQL Server y acceso runtime exclusivamente
por procedimientos almacenados parametrizados. Consultar
[salida y reversión](docs/produccion/SALIDA_PRODUCCION_20261114.md) y
[revisión HP8](docs/produccion/HP8-CIERRE-REVISION-20261114.md).
`compose.yaml` y `compose.qa.yaml` conservan el entorno MySQL heredado; no son
la configuración de producción. La salida sigue sujeta a los gates del destino.

[Abrir presentación interactiva](https://health-project-demo.vercel.app) · datos ficticios, sin credenciales ni backend.

- [Guía de arquitectura y construcción del backend](docs/backend/01_Plan_Arquitectura_y_Construccion.md)
- [API y recorridos para integrar el frontend](docs/backend/02_API_y_Recorridos.md)
- [Ejecutar y probar el backend Docker](backend/README.md)
- [Presentación con mocks y publicación en Vercel](docs/frontend-demo/08_Demo_Vercel.md)
- [Guía del agente de arquitectura: delegación, revisión y avance a producción](docs/PLAN_EJECUCION_PRODUCCION.md)

El frontend está en `frontend`; la compilación normal usa API real y la demo
se compila por separado. El backend Java21/Spring Boot tiene composición SQL
Server para runtime y configuración MySQL heredada. Acceso y tarjetas HP4–HP8
tienen validación local documentada; no equivalen al cierre de todo el plan
clínico. El Compose heredado usa `health.localhost:8080` y correo capturado en
`127.0.0.1:8025`; mantenerlo separado de la preparación productiva.

Para compartir una presentación independiente, ejecuta `npm run build:demo` desde `frontend`. Este modo utiliza únicamente datos ficticios y ofrece una entrada con vistas SaaS, humanas, odontológicas, veterinarias y del portal, además de acceso, trazabilidad, monitor y soporte simulados. `frontend/vercel.json` prepara esa versión para Vercel; selecciona `frontend` como directorio raíz al importar el repositorio.
