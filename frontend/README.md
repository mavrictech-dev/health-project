# Health Project · frontend de presentación

Demo interactiva en español de un sistema para medicina humana, odontología y veterinaria. Frontend con datos ficticios: Next.js, TypeScript, shadcn/ui sobre Base UI y Tailwind CSS. Incluye temas blanco, negro y navy; formularios en paneles derechos con fondo desenfocado.

La consola **Administración SaaS** permite crear clientes independientes, hospitales, clínicas, veterinarias y centros de especialidad; configurar planes y contratos por sedes, profesionales, especialidades y módulos; y abrir el espacio de cada tenant. Un profesional puede tener membresías en varias organizaciones. La agenda usa los profesionales activos asignados a la sede y el cliente comienza con su propio directorio.

El modo de presentación tiene una entrada para elegir vista SaaS, medicina humana, odontología, veterinaria, portal o monitor. [Publicar en Vercel](../docs/frontend-demo/08_Demo_Vercel.md) · [Diseño SaaS](../docs/frontend-demo/07_SaaS_Multitenant.md).

## Ejecutar

Requiere Node.js compatible con la versión de Next instalada y npm. El proyecto se comprobó con Node 24.

```powershell
cd "D:\Mavric\Health Project\frontend"
npm ci
npm run dev:demo
```

Abre http://localhost:3000. El comando selecciona `NEXT_PUBLIC_APP_MODE=mock`. Los datos ficticios ya vienen preparados y no se necesitan credenciales ni APIs.

Para presentar la exportación estática:

```powershell
npm run build:demo
npm run preview:demo
```

Abre http://127.0.0.1:3002. `preview:demo` sirve los archivos de `out-demo`. Vercel publica esa versión mediante `vercel.json`; al importar el repositorio selecciona `frontend` como directorio raíz. Las compilaciones normales (`build`, `dev`) conservan el modo real por defecto y la salida `out` de Docker.

## Recorrer la demo

- Inicio, agenda, recepción, pacientes, historia compartida entre sucursales y atención clínica.
- Evaluaciones y componentes para las 241 entradas del catálogo: 152 humanas, 30 odontológicas y 59 veterinarias.
- Odontogramas, mapas anatómicos, periodoncia, endodoncia, oclusión, series, señales, visión y registros estructurados.
- Diagnóstico, farmacia, documentos, portal de pacientes y responsables, finanzas, compras e inventario.
- Hospitalización, cirugía, anestesia, urgencias, procesos avanzados y operación de plataforma.
- Configuración, organización, sucursales, equipo, servicios, reportes, auditoría e importación/exportación.

Al final de cada pantalla, **Procesos y acciones de esta área** permite recorrer sus acciones del diseño. Los controles cambian según el rol. Abre **Espacio de demostración** para cambiar rol, restaurar consulta, odontología o veterinaria y preparar un fallo simulado.

[Guion de presentación](GUIA_PRESENTACION.md) · [Informe de implementación](../docs/frontend-demo/06_Implementacion_del_Frontend.md) · [Diseño y trazabilidad](../docs/frontend-demo/README.md)

## Estado y límites

Se implementaron 64 pantallas, 16 comandos SaaS, 79 flujos clínicos y los controles de las 429 acciones del plan, con captura y transiciones locales. Los circuitos centrales incluyen reglas específicas; otros procesos utilizan ciclos de registros estructurados para mostrar captura, revisión y avance. La presentación también incluye acceso, registro, recuperación, verificación, sesiones, soporte, trazabilidad y monitor simulados. No necesita el backend Java/MySQL. La autenticación, firmas, cobros y mensajería de este modo son ficticios.

Los datos, preferencias y borradores se guardan en `localStorage`, clave `health-project-demo-v1`. Restaurar un escenario reemplaza los cambios locales. Los adjuntos se mantienen en memoria durante la sesión y deben seleccionarse otra vez después de recargar; su metadata puede permanecer en la demo. Las exportaciones son CSV/JSON y documentos HTML imprimibles.

Los gráficos son esquemáticos y las señales son ejemplos preparados. Las plantillas, catálogos y reglas requieren revisión profesional antes de un uso clínico. El catálogo mantiene su estado de diseño; renderizarlo no lo convierte en un catálogo clínicamente validado.

## Verificar

```powershell
npm run check
npm test
npm run build:demo
npm run qa:demo
```

Con el servidor local iniciado, los scripts de navegador usan Edge instalado:

```powershell
npm run qa:visual
npm run qa:routes
npm run qa:specialties
```

Para comprobar la exportación, establece `$env:HEALTH_PREVIEW_URL = 'http://127.0.0.1:3001'`. Las capturas y reportes se guardan en `test-results/`. La revisión de rutas comprueba presencia y navegación de controles; no ejecuta todas las combinaciones de las 429 operaciones.

## Estructura

```text
src/app          Rutas y exportación estática
src/components   Pantallas, paneles, gráficos y componentes shadcn/ui
src/data         Catálogo, especificación, perfiles, formularios y atlas
src/store        Contexto, preferencias y estado de la demo
src/mocks        Datos ficticios y motor de comandos locales
src/lib          Contratos, filtros, archivos y presentación de referencias
src/styles       Tokens y distribución adaptable
scripts          Generación de especificación, preview y QA
tests           Pruebas de reglas de los flujos centrales
```

`npm run generate:spec` actualiza la especificación compacta desde los documentos de diseño existentes. La futura integración puede sustituir el motor de comandos por un adaptador de API del monolito Spring Boot, manteniendo los contratos de las vistas.
