# Estados, colaboración entre actores y navegación

Estado: diseño de comportamiento. Las transiciones requieren actor, permiso y condición del flujo correspondiente. Los nombres son propuestas de producto; no representan implementación ni protocolo clínico.

## Consulta externa entre actores

```mermaid
flowchart TB
    subgraph PERSONA[Paciente o responsable]
        P1[Solicita atención y confirma identidad]
        P2[Recibe documentos publicados y seguimiento]
    end
    subgraph RECEPCION[Recepción]
        R1[Registra paciente y cita o ingreso directo]
        R2[Registra llegada y cola]
    end
    subgraph CLINICO[Profesional clínico]
        C1[Confirma contexto y abre historia autorizada]
        C2[Registra atención y gráfico específico]
        C3[Revisa documentos y finaliza visita]
        C4[Revisa resultado posterior y seguimiento]
    end
    subgraph SISTEMA[Sistema]
        S1[Valida disponibilidad, identidad y permisos]
        S2[Guarda versiones y asigna pendientes]
        S3[Entrega solo publicaciones autorizadas]
    end
    P1 --> R1 --> S1 --> R2 --> C1 --> C2 --> S2 --> C3 --> S3 --> P2
    S2 --> C4 --> S3
```

La revisión de un resultado posterior no impide terminar una visita si su pendiente tiene responsable y se cumplen las reglas de cierre. Las cajas administrativas no determinan la decisión clínica.

## Reserva desde portal y resolución por recepción

```mermaid
sequenceDiagram
    actor P as Paciente o responsable
    participant S as Sistema
    actor R as Recepción
    P->>S: Selecciona contexto, servicio e intervalo
    S->>S: Verifica vínculo y disponibilidad vigente
    alt Confirmación automática habilitada
        S->>S: Confirma reserva sin duplicación
        S-->>P: Cita confirmada y condiciones
    else Revisión de recepción requerida
        S-->>P: Solicitud recibida, aún sin cita confirmada
        S->>R: Asigna solicitud pendiente
        R->>S: Confirma u ofrece alternativa
        S-->>P: Estado real y siguiente acción
    end
```

## Cita

```mermaid
stateDiagram-v2
    [*] --> SOLICITADA
    SOLICITADA --> CONFIRMADA: Reserva validada
    SOLICITADA --> RECHAZADA: Motivo registrado
    SOLICITADA --> CANCELADA: Actor autorizado
    CONFIRMADA --> CONFIRMADA: Reprogramación con historial
    CONFIRMADA --> CANCELADA: Regla de cambio y motivo
    CONFIRMADA --> AUSENCIA: Ausencia registrada
    CONFIRMADA --> ATENDIDA: Atención realizada y vinculada
    ATENDIDA --> [*]
    AUSENCIA --> [*]
    CANCELADA --> [*]
    RECHAZADA --> [*]
```

Llegada/cola y atención conservan sus estados aparte. Un botón de confirmar asistencia no registra atención realizada.

## Atención y documento: dos ciclos diferentes

```mermaid
stateDiagram-v2
    [*] --> PREPARADA
    PREPARADA --> EN_CURSO: Profesional inicia
    EN_CURSO --> PENDIENTE: Interrupción documentada
    PENDIENTE --> EN_CURSO: Retomar con permiso
    EN_CURSO --> FINALIZADA: Resumen y pendientes revisados
    PREPARADA --> ANULADA: Motivo documentado
    EN_CURSO --> ANULADA: Conservar hechos previos y motivo
    FINALIZADA --> [*]
    ANULADA --> [*]
```

```mermaid
stateDiagram-v2
    [*] --> BORRADOR
    BORRADOR --> EN_REVISION: Solicitar cierre
    EN_REVISION --> BORRADOR: Corregir antes de firma
    EN_REVISION --> FIRMA_PENDIENTE: Mecanismo externo requerido
    FIRMA_PENDIENTE --> FIRMADA: Evidencia confirmada
    FIRMA_PENDIENTE --> EN_REVISION: Fallo resuelto sin firma
    EN_REVISION --> FIRMADA: Cierre autorizado confirmado
    FIRMADA --> [*]
```

La adenda es otro documento con su ciclo de borrador/revisión/firma, vinculado al original. El original firmado no vuelve a borrador. Una visita terminada puede conservar otras tareas, resultados e informes pendientes.

## Orden, tarea e informe

```mermaid
stateDiagram-v2
    [*] --> BORRADOR
    BORRADOR --> ACTIVA: Emitir orden
    ACTIVA --> SUSPENDIDA: Suspensión autorizada
    SUSPENDIDA --> ACTIVA: Reanudación autorizada
    ACTIVA --> COMPLETADA: Cumplimiento registrado
    ACTIVA --> CANCELADA: Cancelación con motivo
    BORRADOR --> CANCELADA: Descartar solicitud
    COMPLETADA --> [*]
    CANCELADA --> [*]
```

```mermaid
stateDiagram-v2
    [*] --> PENDIENTE
    PENDIENTE --> ASIGNADA: Responsable designado
    ASIGNADA --> EN_CURSO: Aceptar e iniciar
    ASIGNADA --> PENDIENTE: Rechazo o reasignación registrada
    EN_CURSO --> COMPLETADA: Evidencia de ejecución
    EN_CURSO --> FALLIDA: Motivo y responsable
    FALLIDA --> PENDIENTE: Nuevo intento identificado
    PENDIENTE --> CANCELADA: Orden y estado lo permiten
    ASIGNADA --> CANCELADA: Cancelación autorizada
    COMPLETADA --> [*]
    CANCELADA --> [*]
```

```mermaid
stateDiagram-v2
    [*] --> PRELIMINAR
    PRELIMINAR --> FINAL: Revisión y emisión autorizada
    FINAL --> [*]
```

Corregir un informe final crea otra revisión relacionada; el original sigue conservado. La nueva revisión produce su propio pendiente de revisión clínica. Completar una tarea técnica, emitir un informe y revisarlo clínicamente son tres acontecimientos diferentes.

## Pago y estado externo

```mermaid
stateDiagram-v2
    [*] --> PROPUESTO
    PROPUESTO --> PENDIENTE_CONFIRMACION: Medio externo
    PROPUESTO --> CONFIRMADO: Medio registrado y validado
    PENDIENTE_CONFIRMACION --> CONFIRMADO: Respuesta verificable
    PENDIENTE_CONFIRMACION --> FALLIDO: Rechazo verificado
    CONFIRMADO --> REEMBOLSO_PARCIAL: Reverso vinculado
    CONFIRMADO --> REEMBOLSADO: Reverso total autorizado
    REEMBOLSO_PARCIAL --> REEMBOLSADO: Completar reverso autorizado
    FALLIDO --> [*]
    REEMBOLSADO --> [*]
```

Un pago confirmado puede permanecer confirmado sin necesidad de un reembolso. Los reversos son objetos/movimientos vinculados, no eliminación del pago original. El estado fiscal del comprobante tiene su propio ciclo y evidencias externas.

## Plaza de hospitalización

```mermaid
stateDiagram-v2
    [*] --> DISPONIBLE
    DISPONIBLE --> RESERVADA: Reserva autorizada
    RESERVADA --> OCUPADA: Admisión y recepción
    RESERVADA --> DISPONIBLE: Liberación de reserva
    OCUPADA --> LIMPIEZA: Egreso o traslado registrado
    LIMPIEZA --> DISPONIBLE: Preparación confirmada
    DISPONIBLE --> BLOQUEADA: Motivo operativo
    BLOQUEADA --> DISPONIBLE: Habilitación autorizada
```

La estancia y el recurso son objetos distintos. El alta clínica no libera por sí sola una cama/jaula físicamente ocupada. Cada ocupación/traslado conserva su intervalo.

## Publicación y vínculo del portal

```mermaid
stateDiagram-v2
    [*] --> PREPARADA
    PREPARADA --> PUBLICADA: Destinatario y versión autorizados
    PUBLICADA --> RETIRADA: Revocar publicación con motivo
    RETIRADA --> [*]
```

El documento puede seguir firmado internamente aunque su publicación se retire. El vínculo del destinatario se verifica en cada acceso. Una corrección se publica como nueva versión identificada; una descarga realizada anteriormente queda registrada y no se presume recuperable.

## Mapa de navegación funcional

```mermaid
flowchart LR
    ACC[Acceso] --> CTX[Contexto y rol]
    CTX --> AG[Agenda y recepción]
    CTX --> PAT[Pacientes]
    PAT --> HC[Expediente compartido]
    AG --> ENC[Atención]
    HC --> ENC
    ENC --> ESP[Formulario y gráfico de especialidad]
    ENC --> ORD[Órdenes y resultados]
    ENC --> DOC[Documentos y publicación]
    ORD --> PEN[Bandeja y seguimiento]
    DOC --> PORT[Portal autorizado]
    CTX --> CFG[Configuración]
    CTX --> ADM[Operación administrativa por fase]
    CTX --> HOSP[Hospital y capacidades avanzadas por fase]
```

Este mapa indica enlaces funcionales. Cada pantalla concreta y cada acción se relacionan con un flujo en `Trazabilidad_Diseno.json`. El portal y la consola MAVRIC usan navegación y permisos propios.
