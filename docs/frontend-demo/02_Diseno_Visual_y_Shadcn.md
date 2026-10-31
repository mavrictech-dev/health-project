# Diseño visual y componentes shadcn/ui

Estado: propuesta visual para construir la demo; sin interfaz implementada. “Navi” se interpreta como **navy / azul marino**.

## 1. Dirección visual

Interfaz minimalista, con controles suaves, bordes discretos, superficies limpias y espacio entre bloques. Los tres temas mantienen la misma jerarquía. El contenido clínico se organiza mediante pestañas, listas y tablas; las tarjetas se reservan para resúmenes concretos y no sustituyen cada fila o sección.

El [catálogo oficial de componentes shadcn/ui](https://ui.shadcn.com/docs/components) será la referencia para los componentes comunes. Se usarán los que resuelvan una necesidad del flujo; los gráficos clínicos y la agenda completa necesitan composición propia.

| Elemento | Propuesta |
|---|---|
| Tipografía | Geist Sans; cuerpo 14 px, texto auxiliar 12–13 px, título de página 24 px, encabezado de sección 16–18 px |
| Espaciado | Escala 4/8/12/16/24/32 px; bloques principales con 24 px en escritorio, 16 px en móvil |
| Controles | Botones e inputs de 36–40 px en escritorio; áreas táctiles de al menos 44 px en móvil |
| Esquinas | 10 px en controles, 16 px en tarjetas, 20 px en el borde izquierdo del panel lateral |
| Iconos | 16–18 px, trazo consistente; botones de solo icono con nombre accesible y Tooltip |
| Sombras | Muy suaves en superficies flotantes; sombra lateral discreta en Sheet |
| Estados | Texto y símbolo, además del color; badges pequeños, sin colorear toda la ficha |
| Movimiento | Entrada del panel de 180–240 ms; feedback breve; respetar movimiento reducido |
| Densidad | Cómoda por defecto, opción compacta para tablas; nunca ocultar el contexto del paciente para ganar espacio |

## 2. Blanco, negro y navy

Los colores siguientes son tokens de diseño propuestos. Se aplican con variables semánticas; los componentes no incrustan colores específicos por página. shadcn documenta ese esquema en [Theming](https://ui.shadcn.com/docs/theming).

| Token | Blanco `light` | Negro `dark` | Navy `navy` |
|---|---|---|---|
| Fondo de aplicación | `#F8FAFC` | `#09090B` | `#081426` |
| Tarjeta y panel | `#FFFFFF` | `#121216` | `#0E2038` |
| Texto principal | `#172033` | `#F4F4F5` | `#E8F0FF` |
| Texto secundario | `#475569` | `#A1A1AA` | `#AABBD2` |
| Bordes de separación | `#E2E8F0` | `#27272A` | `#274260` |
| Botón principal | `#172033` | `#F4F4F5` | `#D7E5FF` |
| Texto en botón principal | `#FFFFFF` | `#111113` | `#0A1830` |
| Foco | `#2563EB` | `#93C5FD` | `#8AB4FF` |
| Desenfoque del fondo | 8 px | 8 px | 8 px |
| Capa oscura del fondo | Negro al 35% | Negro al 50% | Negro al 50% |

Se completarán también `secondary`, `accent`, `muted`, `destructive`, `input`, `ring`, `popover`, `sidebar` y `chart-*`, incluidos estados hover, seleccionado y deshabilitado. Los bordes de tabla pueden ser sutiles; los inputs y el foco necesitan señal suficiente para distinguir controles, sin depender de esos bordes de separación.

El selector presenta tres opciones con muestra visual: **Blanco · Negro · Navy**. La opción elegida persiste al recargar. Navy utiliza `color-scheme: dark` y las variantes oscuras de controles. Se propone `data-theme` como atributo único y un proveedor con tres temas; el primer render debe evitar destellos o discrepancias de hidratación. La [guía de modo oscuro de shadcn para Next.js](https://ui.shadcn.com/docs/dark-mode/next) sirve de base; navy requiere tokens propios.

La impresión usa siempre fondo blanco, texto oscuro y leyendas legibles. Los documentos, tablas, calendarios, gráficos, portales y paneles deben revisarse en los tres temas; cambiar únicamente el fondo del shell no completa un tema.

## 3. Estructura de pantalla

### Área profesional

```text
┌──────────────────┬─────────────────────────────────────────────────────┐
│ Health Project   │ Organización / Sucursal   Buscar   Tema   Cuenta     │
│ Contexto         ├─────────────────────────────────────────────────────┤
│                  │ Migas de navegación                                  │
│ Inicio           │ Agenda                          Filtros  + Nueva cita│
│ Agenda           │                                                       │
│ Pacientes        │ Vista del área: tabla / calendario / atención        │
│ Atención         │                                                       │
│ ...según rol     │                                                       │
│                  │                                                       │
│ Configuración    │                                                       │
└──────────────────┴─────────────────────────────────────────────────────┘
```

Sidebar de unos 244 px, colapsable a 72 px; encabezado de unos 64 px. Organización y sucursal siempre visibles. La cuenta indica rol demo y acceso al cambio de tema. El menú se agrupa por atención, operación y configuración según permisos; no presenta todas las acciones de una vez.

### Espacio de atención

Encabezado fijo con identidad, dominio humano/animal, especie cuando corresponde, alertas registradas, profesional, procedencia y estado de atención. Debajo: **Resumen · Historia · Evaluación · Gráficos · Órdenes · Medicación · Documentos · Seguimiento**. La pestaña mantiene contexto al abrir un panel.

La evaluación contiene secciones por especialidad con progreso de captura. “Guardar borrador”, “Revisar resumen” y “Finalizar visita” son visibles, con disponibilidad determinada por el estado. El gráfico ocupa el espacio de trabajo; el hallazgo o procedimiento se captura a la derecha. La ficha humana y la animal comparten estructura, pero sus campos y relaciones son distintos.

### Portal y consola

Portal con navegación breve: **Inicio · Citas · Documentos · Seguimiento · Pagos · Vínculos · Cuenta**. El selector identifica para quién actúa la persona, la organización y el alcance. La consola de operación es otra área con su acceso ficticio y vistas operativas; no reutiliza como contenido clínico el dashboard de un profesional.

### Adaptación

A partir del espacio disponible, las tablas permiten desplazamiento horizontal y las acciones esenciales permanecen accesibles. En móvil se usa un Sheet desde la derecha para la navegación, y formularios a ancho completo. En tablet la sidebar puede estar colapsada. No se ocultarán datos esenciales del paciente ni acciones detrás de hover.

## 4. Paneles desde la derecha con desenfoque

El componente base será **Sheet** y su contenido se configurará con `side="right"`. La dirección es una capacidad documentada de [Sheet de shadcn](https://ui.shadcn.com/docs/components/sheet); el desenfoque y el estilo suave del overlay son una personalización de Health Project.

```text
Pantalla de origen desenfocada               Panel derecho nítido
┌──────────────────────────────────┬───────────────────────────────────┐
│                                  │ Nueva cita                     ×  │
│ Agenda que conserva sus filtros  │ Paciente y contexto               │
│                                  ├───────────────────────────────────┤
│ Capa oscura + blur de 8 px        │ Paciente     [Seleccionar]        │
│                                  │ Profesional  [Seleccionar]        │
│                                  │ Servicio     [Seleccionar]        │
│                                  │ Fecha/hora   [Disponibilidad]     │
│                                  │                                   │
│                                  │ Resumen / errores por campo       │
│                                  ├───────────────────────────────────┤
│                                  │ Cancelar          Reservar cita   │
└──────────────────────────────────┴───────────────────────────────────┘
```

| Variante de panel | Anchura orientativa | Uso |
|---|---|---|
| Compacto | 440 px | Confirmación, vínculo, cambio de estado, filtros avanzados |
| Estándar | 560 px | Paciente, cita, medicamento, pago, hallazgo y cargo |
| Amplio | 760 px | Documento, formulario largo, permisos y revisión de impacto |
| Comparación | 960 px | Versiones, duplicados y comparación de imágenes |

Siempre se limita al viewport; en móvil ocupa el ancho disponible. Cabecera y pie quedan visibles; solo el cuerpo desplaza. El panel tiene superficie opaca para que los datos permanezcan nítidos. El overlay bloquea interacción con el fondo. Si no se soporta blur o se prefiere reducir transparencia, se conserva una capa opaca suficiente.

### Reglas de apertura, avance y cierre

1. La acción guarda el elemento que la abrió, la ruta, los filtros y el paciente activo.
2. Un único `OverlayHost` controla el panel; seleccionar un paciente desde “Nueva cita” cambia a un paso de búsqueda dentro del mismo panel. Volver conserva lo capturado.
3. Los formularios guardan borrador o confirman con una acción explícita. Cerrar, hacer clic en el overlay o Escape no ejecuta comandos.
4. Con cambios sin guardar, el panel muestra una etapa de decisión: **Seguir editando · Descartar cambios locales · Guardar borrador**, cuando guardar sea válido. Volver atrás permite corregir sin perder datos.
5. Las acciones de publicación, dinero, permisos, fusión, firma demo o egreso muestran revisión dentro del mismo Sheet con alcance, estado y motivo pertinente.
6. Durante confirmación se evita doble envío. El error mantiene formulario y foco útil; el éxito actualiza las vistas y deja un enlace al resultado.
7. Al cerrar se devuelve foco al disparador; si ya no existe, a un destino lógico de la lista. Encabezado y descripción identifican el panel, con orden de tabulación y foco contenidos.

Las confirmaciones no abrirán un diálogo centrado adicional. Se implementarán como una etapa del Sheet con resumen claro y botones explícitos. Selectores y calendarios pueden usar Popover anclado dentro de esa composición, coordinando foco y Escape con el panel. El visor clínico extenso puede ser una ruta completa; sus anotaciones se editan desde la derecha.

## 5. Componentes y función en el producto

| Componente o composición | Aplicación |
|---|---|
| Sidebar, Breadcrumb, Collapsible | Navegación por rol y ubicación dentro del área |
| Button, Button Group, Tooltip | Acción principal, secundaria, contextual y controles por icono |
| Sheet, Scroll Area, Separator | Todos los paneles modales desde la derecha y su jerarquía |
| Field, Label, Input, Textarea | Captura identificada y errores cerca del campo |
| Select, Combobox, Command | Catálogos, búsqueda de paciente, profesional, pieza, servicio y estructura |
| Calendar, Date Picker, Popover | Selección de fecha y filtros; la agenda completa es una composición propia |
| Checkbox, Radio Group, Switch | Selección, respuestas excluyentes y preferencias; permisos sensibles se guardan tras revisión |
| Table + TanStack Table, Pagination | Directorios, órdenes, caja, stock, tareas y auditoría demo |
| Tabs, Accordion | Secciones de expediente, atención y capturas largas |
| Avatar, Badge, Card, Item | Identidad, estado y resúmenes breves |
| Dropdown Menu | Menú de acciones secundarias por fila, con las mismas reglas que el botón directo |
| Chart + Recharts | Tendencias, series y reportes, con leyenda y tabla equivalente |
| Toggle Group, Slider, Resizable | Vista anatómica, zoom y distribución de gráficos cuando el flujo lo requiere |
| Skeleton, Spinner, Progress | Carga, operación pendiente e importación simulada |
| Empty, Alert, Toast | Estado vacío, error persistente y feedback de una operación ya reflejada |
| Input OTP | Comprobaciones ficticias de acceso o canal, sin verificación externa real |
| Componentes propios de dominio | Odontograma, periodontograma, anatomía, agenda, documentos, hospital y señales |

La referencia de [Sidebar](https://ui.shadcn.com/docs/components/sidebar) permite componer navegación y colapso. La de [Chart](https://ui.shadcn.com/docs/components/chart) orienta series estadísticas. Su estilo se integra con los tres temas del proyecto.

## 6. Botones: reglas compartidas

Cada página tiene una acción principal según el flujo. Los secundarios se mantienen cercanos al objeto y los poco frecuentes van al menú de fila. Acciones peligrosas usan texto concreto: “Revocar vínculo”, “Confirmar devolución” o “Cancelar cita”; “Aceptar” se reserva para situaciones en que el resumen deja claro el objeto.

La deshabilitación muestra su motivo sin depender de hover: faltan campos, no hay permiso demo, el objeto está cerrado o se está procesando. El estado sin permiso tiene una explicación y navegación útil. Las cargas muestran lo que está ocurriendo y los errores indican cómo continuar.

Las acciones de guardar tienen validación en línea. Los cambios financieros, clínicos definitivos y de acceso requieren un resumen legible; no un diálogo genérico para todos los clics. La revisión de firma se rotula como simulada. No se guardan contraseñas reales ni se solicitan tarjetas o credenciales externas para presentar.

## 7. Wireframes antes de desarrollar cada área

La matriz de pantallas define ruta, componentes y acciones. Para cada pantalla se prepararán cuatro vistas de diseño: estado inicial con datos, vacío, error o acceso restringido, y panel derecho principal. El wireframe marcará información fija, pestañas, selección, filtros, acción principal, secundarios, campos, revisión y salida del proceso.

Los primeros wireframes serán: shell, agenda con “Nueva cita”, directorio con alta humana/animal, atención con gráfico y hallazgo, revisión de documento, cobro ficticio y portal del destinatario. Después se aplica el mismo sistema visual a las 56 pantallas y se revisan las excepciones de diagnóstico, hospital y consola.

El contraste, el foco, los tres temas, las tablas densas, las etiquetas largas en español y el panel en móvil se verifican sobre vistas reales durante la implementación. Este documento fija dirección y comportamiento; no afirma que esa revisión visual ya se haya hecho.
