# Presentación y verificación del frontend mock

Estado: recorridos y comprobaciones **planeados**. Ningún recorrido está marcado como implementado o aprobado todavía.

## 1. Datos y controles para presentar

La demo abrirá con datos ficticios suficientes para que las pantallas tengan contexto: citas de varios estados, una cola, visitas anteriores, notas firmadas de demo, resultados pendientes, un pago parcial, un lote de farmacia, plazas ocupadas/libres y documentos publicados y privados.

Los controles de presentación permiten cambiar rol, elegir escenario, reiniciar datos y simular un fallo. Se agrupan en un acceso “Demostración” para no llenar cada pantalla de opciones técnicas. Cambiar rol conserva los datos del recorrido; reiniciar requiere revisión en Sheet y restaura el escenario de manera completa.

Los roles seleccionables son ADM, REC, PRO, ASI, DIA, FAR, CAJ, ALM, PAC, RES, AUD y SOP. SYS y EXT representan participantes simulados. La demo distingue administración organizacional, profesional clínico y consola MAVRIC, con visibilidad según acción y contexto.

## 2. Recorridos de principio a fin

| ID | Actores y recorrido | Resultado observable |
|---|---|---|
| P01 | REC registra humano → cita → llegada → PRO consulta y registra gráfico anatómico/medición → firma demo → publica → PAC consulta | El expediente, agenda, cola y portal muestran el mismo recorrido y versión |
| P02 | REC reserva odontología → PRO selecciona dentición, pieza y cara → registra condición y procedimiento → compara → receta/documento → CAJ cobra ficticiamente | Odontograma semántico, historia por pieza y saldo actualizado |
| P03 | REC registra animal y responsable → verifica vínculo demo → cita → PRO usa atlas y captura por especie → prevención → RES recibe contenido | Se distinguen animal, persona responsable, vínculo y datos de especie |
| P04 | PRO atiende en sucursal A → cambia a B de la misma organización → abre historia → cambia a otra organización o espacio propio | La historia interna es compartida y conserva origen; otra organización consulta sus propios registros |
| P05 | PAC o RES solicita cita → REC ofrece alternativa → acepta → reprograma o cancela → lista de espera | Estados y disponibilidad cambian sin duplicar reservas |
| P06 | PRO emite orden → DIA acepta tarea y muestra → registra resultado → firma informe demo → PRO revisa y asigna seguimiento | Una orden genera tareas trazables y la revisión resuelve el pendiente apropiado |
| P07 | PRO emite receta → FAR elige lote y entrega parcial → completa entrega → registra devolución | Entregas, saldo pendiente de dispensación y stock consistente |
| P08 | PRO crea presupuesto → CAJ confirma cargos y pago parcial → emite comprobante demo rechazado → corrige/reintenta → devolución ficticia | El saldo del paciente permanece correcto y el estado externo del comprobante es independiente |
| P09 | REC admite humano o animal → ASI confirma recepción/cuidado → traslado/turno → PRO alta → egreso | Una sola ocupación activa, recurso liberado y pendientes de alta asignados |
| P10 | PRO/ASI recorre caso quirúrgico → verificación → anestesia/observaciones → parte → recuperación → entrega | Fases y registros enlazados; excepciones se conservan como eventos |
| P11 | PRO recorre curso, transfusión, trasplante o reproducción según perfil → registra etapa → incidencia → seguimiento | La especialidad avanzada tiene modelo y estados propios, accesibles desde S46 |
| P12 | PRO/ASI selecciona población veterinaria → denominador → intervención → informe y seguimiento | Separación entre individuo, pertenencia temporal y actuación grupal |
| P13 | ADM importa CSV ficticio → vista previa con rechazo → confirma válidos → AUD filtra eventos → exporta | Se identifican filas inválidas; lote sin duplicación y descarga local verificable |
| P14 | ADM configura proveedor demo → simula fallo → reintenta → solicita soporte y concede acceso temporal → SOP abre caso → revoca | Trabajo identificado, acceso con alcance/vigencia y eventos de demo visibles |
| P15 | PRO escribe borrador → cambia espacio o cierra sesión → revisa salida → fallo/conflicto de guardado → resuelve y reanuda | La captura no desaparece silenciosamente ni sobrescribe otra revisión |
| P16 | ADM/PRO busca cada entrada del catálogo → abre perfil → usa todos sus componentes requeridos → compara/tabla equivalente | Cobertura de 241 perfiles y 31 familias, separada de validación clínica |
| P17 | ALM solicita compra → aprobación → recepción con lote y discrepancia → transferencia → recepción → ajuste/reverso | Cantidades, lotes y estados ligados; no se inventa stock al reintentar |
| P18 | CAJ liquida honorarios → PRO consulta detalle → ADM revisa suscripción, baja/entrega de datos e incidente demo | Operación comercial y de plataforma completa, con revisiones y estados propios |

P01, P02 y P03 forman la presentación inicial; los demás completan la demostración del sistema. No constituyen una reducción del alcance.

## 3. Fallos preparados

| Caso | Comportamiento esperado |
|---|---|
| Horario ya ocupado | Conserva paciente y servicio, explica conflicto y ofrece horarios alternativos |
| Rol sin alcance | Acción deshabilitada o vista restringida con motivo; no cambia entidades |
| Relación de portal pendiente o revocada | No muestra documentos fuera del vínculo válido en esa sesión demo |
| Nota ya firmada de demo | Lectura y adenda; no edición directa de la revisión |
| Guardado fallido o versión diferente | Borrador conservado, reintento o comparación explícita |
| Muestra rechazada o dosis no realizada | Estado de excepción y motivo; no marca realización satisfactoria |
| Pago/comprobante externo pendiente o rechazado | Estado simulado visible; no repite el cobro por reintentar comprobante |
| Lote insuficiente o vencido según fixture | No dispensa esa selección; conserva captura y explica alternativa |
| Plaza ocupada | No confirma segunda ocupación; muestra opciones válidas |
| CSV inválido | Errores por fila/campo y resumen antes de aplicar; no altera nada al cancelar |
| Doble clic en confirmación | Una sola operación y un solo resultado persistido en el mock |
| Cerrar panel con cambios | Revisión dentro del Sheet con conservar, descartar o guardar cuando corresponde |

## 4. Criterios de cobertura

| Unidad | Cómo se cuenta | Cuándo se considera verificada |
|---|---|---|
| Pantalla | ID S01–S56, aunque varias compartan ruta | Contenido, acciones, rol, tres temas, responsive y estados revisados |
| Acción de negocio | ID de la matriz, no texto del botón | Disponibilidad, apertura/efecto, validación, cancelación y resultado observable |
| Control común | ID UX independiente de las 429 acciones | Tema, navegación, Sheet, filtros, demo y estados cumplen su contrato |
| Perfil de especialidad | Código del catálogo | Perfil abre y cada componente/flujo requerido se puede ejercitar con fixture |
| Familia de componente | Una de las 31 familias | Renderizador, variantes necesarias, interacción semántica y tabla/alternativa accesible |
| Recorrido | ID P01–P18 y variantes | Resultado final consistente en todas las áreas involucradas |

La cobertura planeada no significa cobertura implementada. Los estados de acciones serán `PLANNED`, `IMPLEMENTED`, `VERIFIED` o `NEEDS_FIX`, y los de verificación `NOT_RUN`, `PASS` o `FAIL`; aquí comienzan en `PLANNED` y `NOT_RUN`. El catálogo clínico conserva su estado y revisión profesional independientes.

## 5. Verificación necesaria durante la construcción

Se comprobarán con pruebas de lógica las transiciones que pueden romper coherencia: identidad/contexto, reserva y cola, revisión firmada/adenda, publicación por vínculo, dinero, stock, ocupación y reintentos. Se recorrerán con Playwright los caminos representativos P01–P10, P13–P15 y P17, incluidas variantes con error. No escribir un test que solo confirme la existencia de cada `onClick`.

Un control de cobertura relacionará los IDs de acciones usados por las vistas con el registro y el plan: no puede haber una acción del diseño sin punto de entrada, ni un botón visible sin contrato. Los perfiles del catálogo se ejercitan con un recorrido de galería y sus interacciones; repetir una misma captura genérica no acredita atlas o componentes especializados.

Se revisarán teclado, foco, Escape, cierre con borrador, contraste, movimiento reducido, scroll del panel, tablas, etiquetas largas y pantallas móviles. Habrá capturas representativas de blanco, negro y navy sobre agenda, atención, odontograma, documentos, caja y portal. Las comprobaciones documentales ejecutadas ahora solo verifican integridad del plan.

## 6. Entregables de la futura demo

- Aplicación Next.js y exportación estática navegable, sin backend de producto.
- Fixtures ficticios, escenarios y controles de reinicio/cambio de rol.
- Sistema de componentes shadcn adaptado a los tres temas y paneles derechos con desenfoque.
- Matriz actualizada con evidencias de 56 pantallas, 429 acciones, controles comunes y 241 perfiles.
- Guion de presentación y ejemplos locales de documentos, CSV/JSON e impresión.
- Lista explícita de lo simulado y de lo pendiente para producción.

Las integraciones, pagos, mensajería, dictado, firmas y servicios fiscales se ejecutan como máquinas de estado de demo. Los archivos y exportaciones sí podrán generarse localmente con material ficticio. No se enviarán mensajes, cobros o publicaciones reales como efecto de los botones de presentación.
