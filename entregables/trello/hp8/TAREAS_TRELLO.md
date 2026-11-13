# HP Tarjeta 8: DEV-AGENDA

Agenda Visual y Agendamiento Manual y Guiado por Voz.

Estado: **implementada y validada localmente**. Pendiente comprobación en la base
exclusiva de Health Project en Somee, cuando se proporcione su conexión.

## Lista de chequeo para copiar en Trello

- [x] **HP8-01 · Calendario interactivo diario y semanal.** Navegar por fechas,
  volver a Hoy, filtrar por profesional y consultar las citas de la sucursal
  activa. Mostrar citas superpuestas en columnas independientes y respetar la
  zona horaria del negocio.
- [x] **HP8-02 · Agendamiento manual desde un horario.** Abrir el formulario al
  hacer clic en un espacio, seleccionar un paciente existente o registrar uno
  nuevo, elegir profesional/especialidad, fecha, hora, duración y servicio.
  Revisar antes de confirmar; comprobar disponibilidad y evitar duplicados.
- [x] **HP8-03 · Asistente guiado por voz.** Preguntar en secuencia Nombres →
  Apellidos → Fecha de nacimiento → Horario de cita. Interpretar fechas y horas
  en español, mostrar los datos capturados y permitir corregirlos antes de
  guardar. Para un paciente nuevo, completar también su DNI/identificador en la
  revisión. Conservar la entrada manual si falla el micrófono.
- [x] **HP8-04 · Estado de cobro y medio de pago.** Registrar Pendiente de Pago o
  Pagado, importe en soles y Efectivo, Tarjeta, Transferencia, Yape, Plin u Otro.
  Exigir importe positivo y medio de pago al marcar Pagado. Aplicar permisos de
  recepción, caja o administración, revisión concurrente e idempotencia.
- [x] **HP8-05 · Arqueo por sucursal y fecha.** Mostrar importes netos por medio de
  pago, registros y reversiones. Conservar un historial inmutable de cambios;
  una corrección compensa el pago anterior sin borrarlo. Usar fecha de registro
  del cobro, independiente de la fecha de la cita.
- [x] **HP8-06 · API, SQL y pruebas.** Persistir mediante SP parametrizados de SQL
  Server; comprobar aislamiento por negocio/sucursal, conflictos de horario,
  repetición de solicitudes, revisiones obsoletas, permisos, arqueo y liberación
  de horario cuando una cita queda como No asistió. Entregar capturas de
  escritorio y móvil.
- [ ] **HP8-07 · Comprobación final en Somee.** Ejecutar la validación sobre una
  base exclusiva de Health Project. AgendlyCitas está excluida.

## Evidencia entregada

- 1.124 pruebas Java y 120 pruebas frontend, sin fallos.
- Builds estáticos de producción y demostración completados.
- 40 comprobaciones HTTP contra Java + SQL Server 2022 real, con datos sintéticos.
- 14 capturas en `capturas/`; voz comprobada con reconocimiento y síntesis
  simulados en el navegador, sin audio de pacientes.
- [Informe técnico y límites](../../../docs/produccion/HP8-AGENDA-20261113.md).

## Capturas para adjuntar

| Archivos | Vista |
| --- | --- |
| HP8-01 / HP8-02 | Calendario diario y semanal |
| HP8-03 / HP8-04 / HP8-05 | Formulario, revisión y cita registrada |
| HP8-06 / HP8-07 | Estado Pagado, medio de pago y arqueo |
| HP8-08 / HP8-09 / HP8-10 / HP8-11 | Los cuatro pasos del asistente de voz |
| HP8-12 | Revisión de datos reconocidos |
| HP8-13 | Micrófono denegado y captura manual |
| HP8-14 | Agenda móvil |

[Código en GitHub](https://github.com/mavrictech-dev/health-project/tree/health/production-wave0)
· [Frontend de agenda](https://github.com/mavrictech-dev/health-project/blob/health/production-wave0/frontend/src/components/runtime-agenda.tsx)
· [API](https://github.com/mavrictech-dev/health-project/blob/health/production-wave0/backend/src/main/java/com/mavric/healthcards/AgendaController.java)
· [SQL V19](https://github.com/mavrictech-dev/health-project/blob/health/production-wave0/backend/src/main/resources/db/sqlserver/V19__agenda_collections.sql)
