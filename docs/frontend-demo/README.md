# Health Project: plan del frontend de presentación

Fecha: 13 de octubre de 2026. Estado: **diseño documentado y frontend de presentación implementado con mocks locales**.

La demo abarca el sistema mediante datos ficticios y operaciones en el navegador: medicina humana, odontología, veterinaria, portal, administración, diagnóstico, farmacia, hospitalización, cirugía y operación de la plataforma. El código está en [frontend](../../frontend/README.md); el informe de implementación detalla el alcance real.

1. [Arquitectura y orden de implementación](01_Arquitectura_y_Plan.md).
2. [Diseño visual, componentes y paneles desde la derecha](02_Diseno_Visual_y_Shadcn.md).
3. [Matriz de todas las pantallas y acciones](03_Pantallas_y_Acciones.md).
4. [Recorridos de presentación y criterios de entrega](04_Presentacion_y_Verificacion.md).
5. [Plan estructurado para implementar](Plan_Frontend.json): pantallas, acciones, controles comunes, contratos de flujo y perfiles de especialidad.
6. [Verificación documental realizada](05_Verificacion_del_Plan.md).
7. [Implementación y verificación del frontend](06_Implementacion_del_Frontend.md).

La matriz conserva los **79 flujos, 56 pantallas y 429 acciones contextuales** del [diseño funcional](../diseno/README.md). Las 241 entradas del catálogo se vinculan con sus formularios, componentes y familias gráficas. Los controles nuevos de interfaz se enumeran aparte; 429 no significa 429 etiquetas diferentes ni 429 botones simultáneos en una pantalla.

Las fases de producción siguen vigentes: primero consulta externa humana, odontológica, veterinaria y portal; después los otros módulos. En la demo, todos se podrán recorrer. Un comportamiento simulado no acredita disponibilidad clínica, firma real, integración fiscal o seguridad de producción.

`generar_plan.py` y `fuente_acciones.txt` son herramientas de documentación. No son código de la aplicación ni desarrollan el frontend.
