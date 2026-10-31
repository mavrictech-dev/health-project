# Health Project: diseño de flujos y frontend

Fecha: 13 de octubre de 2026. Estado: propuesta de diseño, sin desarrollo de la aplicación. Los comportamientos nuevos son propuestas revisables; se conservan las decisiones ya confirmadas sobre organización, sucursales, especialidades y portal.

El diseño sigue este orden:

1. [Actores, alcance y reglas](01_Actores_y_Reglas.md).
2. [Flujos de principio a fin](02_Flujos_y_Diagramas.md), con condiciones, alternativas y diagramas Mermaid.
3. [Pantallas, funciones y botones](03_Pantallas_y_Botones.md), derivados de los flujos.
4. [Trazabilidad del diseño](Trazabilidad_Diseno.json), para relacionar actores, procesos, pantallas y acciones.

El [diseño de interacción de los gráficos](04_Graficos_de_Especialidad.md) conecta las 241 entradas con sus familias de componentes y flujos de captura.

Los [estados y recorridos entre actores](05_Estados_y_Recorridos.md) muestran los ciclos de los objetos, la colaboración entre roles y el mapa de navegación.

Los diagramas están también como archivos `.mmd` en `diagramas/`. La especificación se mantiene en `fuente_diseno.json`; `generar_diseno.py` produce los documentos. Son herramientas para documentar el diseño, no código de Health Project.

Se distinguen el alcance de consulta externa, la operación administrativa y los procesos avanzados. Las pantallas futuras permanecen identificadas como futuras; no representan funciones disponibles.

Este paquete define comportamiento y estructura de navegación. El [plan del frontend de presentación](../frontend-demo/README.md) deriva todas sus pantallas y acciones y propone Next.js con mocks, shadcn/ui, temas blanco/negro/navy y paneles desde la derecha con desenfoque. Incluye también los módulos de fases posteriores para poder presentar el sistema completo; su disponibilidad real sigue dependiendo de las fases de producción.

Antes de implementar cada área se revisará su flujo y se construirán sus wireframes sobre el sistema visual propuesto. Las decisiones pendientes se explicitan para resolverlas sobre un diseño concreto.
