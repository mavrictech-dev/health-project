# Health Project

Plataforma clínica SaaS para organizaciones humanas y veterinarias, con identidades que pueden trabajar en varios clientes, sedes y especialidades.

[Abrir presentación interactiva](https://health-project-demo.vercel.app) · datos ficticios, sin credenciales ni backend.

- [Guía de arquitectura y construcción del backend](docs/backend/01_Plan_Arquitectura_y_Construccion.md)
- [API y recorridos para integrar el frontend](docs/backend/02_API_y_Recorridos.md)
- [Ejecutar y probar el backend Docker](backend/README.md)
- [Presentación con mocks y publicación en Vercel](docs/frontend-demo/08_Demo_Vercel.md)
- [Guía del agente de arquitectura: delegación, revisión y avance a producción](docs/PLAN_EJECUCION_PRODUCCION.md)

El frontend está en `frontend`. Acceso, registro, recuperación, trazabilidad, monitor, sesiones y soporte utilizan el backend real. La presentación clínica conserva sus mocks bajo `/demo`. El backend está en `backend`, con Java Spring Boot, MySQL y procedimientos almacenados. `compose.yaml` levanta MySQL, migraciones, monolito, gateway y correo local; el dominio de desarrollo es `health.localhost:8080` y el buzón de prueba está en `127.0.0.1:8025`.

Para compartir una presentación independiente, ejecuta `npm run build:demo` desde `frontend`. Este modo utiliza únicamente datos ficticios y ofrece una entrada con vistas SaaS, humanas, odontológicas, veterinarias y del portal, además de acceso, trazabilidad, monitor y soporte simulados. `frontend/vercel.json` prepara esa versión para Vercel; selecciona `frontend` como directorio raíz al importar el repositorio.
