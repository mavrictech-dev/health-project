# Implementación del frontend de presentación

Fecha: 13 de octubre de 2026. Estado: **demo local implementada; validación clínica y conexión de producción pendientes**.

El código está en `../../frontend`. La demo utiliza Next.js, TypeScript, Tailwind CSS, componentes oficiales de shadcn/ui sobre Base UI, Zustand, React Hook Form, Zod y Recharts. Los procesos externos se representan con estados simulados. No incorpora servicios clínicos ni conexión a SQL Server.

## Cobertura implementada

| Elemento del diseño | Implementación de presentación |
| --- | --- |
| 56 pantallas | Rutas, panel global de contexto y variantes por pestaña o proceso |
| 79 flujos / 429 acciones | Controles contextuales con captura, revisión, detalle, navegación, filtros, descargas o cambios locales de estado |
| 241 entradas de especialidad | Evaluación específica y familias del perfil: 152 humanas, 30 odontológicas y 59 veterinarias |
| 31 familias de componentes | Anatomía, dentición, series, señales, visión, relaciones, imagen y registros estructurados |
| 22 atlas esquemáticos | 224 regiones seleccionables, anotación, zoom y lista alternativa |
| 12 roles seleccionables | Administración, recepción, profesional, asistencia, diagnóstico, farmacia, caja, almacén, paciente, responsable, auditor y operador |
| Contextos | Organización y sucursal; historial común dentro de una organización con procedencia visible |
| Temas | Blanco, negro y navy; preferencia local persistente |
| Paneles | Sheet desde la derecha, fondo desenfocado, revisión previa y protección de captura al cerrar |

Los módulos incluyen agenda, recepción, pacientes humanos y animales, responsables, duplicados, expediente, atención, órdenes, muestras, laboratorio, imágenes, receta, dispensación, administración de medicación, documentos, portal, seguimiento, presupuestos, caja, comprobantes, honorarios, compras, inventario, hospitalización, cirugía, anestesia, urgencias, sesiones, transfusión, trasplante, reproducción, programas poblacionales, reportes, auditoría, datos, integraciones y operación de plataforma.

La navegación, captura y estados son interactivos. Los circuitos centrales tienen reglas locales específicas: solapamientos de agenda, límites de inventario, reserva de camas, versiones documentales, publicación por vínculo vigente, separación por organización, revisión de notas finalizadas, pagos en unidades monetarias menores y deduplicación. Otros procesos utilizan ciclos de registros estructurados para presentar su captura, revisión y avance. La presencia de un control no implica que su lógica futura de servidor esté implementada.

## Organización del código

- `src/app`: rutas y exportación estática.
- `src/components`: navegación, pantallas, gráficos, paneles y componentes oficiales de shadcn/ui.
- `src/data`: especificación generada, catálogo, perfiles, contratos de captura y atlas SVG.
- `src/store/demo.ts`: contexto, temas, persistencia, borradores y comandos simulados.
- `src/mocks/fixtures.ts`: escenarios ficticios.
- `src/mocks/engine.ts`: reglas y transiciones locales; frontera para sustituir por un adaptador de API.
- `src/lib`: tipos, referencias, filtros, archivos y contratos.
- `src/styles`: tokens visuales y distribución adaptable.
- `tests` y `scripts`: comprobaciones, exportación y revisión en navegador.

El backend futuro mantiene el monolito modular Spring Boot y procedimientos almacenados de SQL Server definidos en el diseño. Esta entrega implementa el frontend de presentación.

## Límites de esta versión

Accesos, roles, firmas, comprobantes, mensajes, tareas externas y auditoría son simulados. Ilustraciones, trazados y valores preparados son ejemplos. Formularios y catálogos necesitan revisión profesional antes de utilizarse con pacientes reales. No se ejecutan inferencias diagnósticas ni cálculos clínicos normativos. La persistencia del navegador facilita la presentación y no constituye una frontera de seguridad de producción. Los adjuntos viven en memoria durante la sesión; se descargan documentos HTML imprimibles y datos CSV o JSON.

Las restricciones del motor local deben aplicarse de forma independiente en cada operación del servidor futuro. La fase productiva inicial sigue siendo consulta externa humana, odontología, veterinaria y portal; los demás módulos tienen espacio de presentación.

## Comprobaciones

- TypeScript y lint: sin errores ni advertencias.
- Motor local: 17 pruebas funcionales pasadas; agenda, aislamiento, documentos, dinero, lotes, camas, importación y versiones.
- Navegación en Edge: 56 pantallas en 66 visitas, HTTP 200, sin errores JavaScript ni acciones ausentes; aparecen los 429 controles contextuales.
- Especialidades: 241 perfiles y 31 familias renderizados, sin errores JavaScript; dentición felina y conservación de captura al cancelar el cierre comprobadas. Búsqueda del portal limitada a vínculos vigentes y búsqueda del operador sin pacientes clínicos.
- Selección de pieza, atlas cardíaco y deshacer de selección local: comprobados en la exportación estática.
- Revisión visual: tres temas, panel derecho de 580 px en escritorio, desenfoque de 8 px y móvil de 390 px sin desbordamiento horizontal.
- Exportación estática generada en `frontend/out`.

Estas comprobaciones no acreditan haber ejecutado todas las combinaciones de las 429 acciones ni validación clínica. Los resultados se guardan en `frontend/test-results` al ejecutar los scripts de QA.

Referencias: [shadcn/ui](https://ui.shadcn.com/docs/components), [Sheet](https://ui.shadcn.com/docs/components/sheet). La numeración veterinaria se contrastó con [AVDC: nomenclatura y sistema Triadan](https://avdc.org/avdc-nomenclature/).
