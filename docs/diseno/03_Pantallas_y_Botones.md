# Pantallas, funciones y botones derivados de los flujos

Estado: arquitectura de información y comportamiento propuestos. No se construye el frontend en esta etapa.

## Orden de diseño

Revisar primero los actores y flujos. Esta especificación deriva las pantallas de sus pasos. Después se diseñarán wireframes de baja fidelidad, se probarán recorridos y se definirá el sistema visual. Las posiciones descritas son estructura funcional, no una elección final de estilo.

## Navegación por espacio y rol

| Espacio / rol | Navegación inicial propuesta |
| --- | --- |
| Profesional | Mi jornada, Agenda, Pacientes, Pendientes, Seguimiento y Configuración autorizada |
| Recepción | Agenda, Llegadas, Pacientes, Solicitudes y Comunicaciones permitidas |
| Administrador | Organización, Equipo, Recursos, Especialidades, Integraciones y Reportes; módulos comerciales según entrega |
| Portal | Inicio, Citas, Documentos, Seguimiento, Vínculos y Mi cuenta; pagos cuando el módulo exista |
| Diagnóstico | Lista de trabajo, Muestras, Resultados y Estudios según permisos |
| Farmacia | Órdenes, Dispensaciones y existencias autorizadas |
| Caja / almacén | Cuentas/Caja/Comprobantes/Honorarios o Compras/Inventario según rol |
| Hospital | Estancias, Recursos, Tareas/Turnos, Cirugía y Urgencias según rol |
| Auditor / soporte | Evidencia autorizada o consola operativa; sin navegación clínica global implícita |

El catálogo de 241 entradas no se convierte en 241 opciones de menú. La especialidad selecciona formularios y componentes dentro de la atención. Los flujos avanzados sí pueden tener espacios de trabajo específicos.

## Componentes comunes de la interfaz

| Componente | Comportamiento |
| --- | --- |
| Cabecera de contexto | Organización, sucursal y rol operativos; cambio aplica F02 |
| Identificación clínica | Paciente/animal, identificador y contexto visibles en captura, firma, orden y entrega |
| Navegación | Mostrar funciones que el rol puede usar; estados de disponibilidad según paquete/release |
| Buscador y filtros | Alcance visible, estado vacío distinto de restricción, conservar filtros al volver |
| Formulario | Campos, unidades, errores junto al campo, desconocido/negado explícitos, guardado real indicado |
| Gráfico | Leyenda, atlas/versión, selección semántica, tabla equivalente, comparación temporal |
| Bandeja | Responsable, estado, siguiente acción y pendientes; envío no equivale a resolución |
| Revisión final | Resumen de objeto/paciente/contexto antes de firma, publicación, pago o cambio de permisos |
| Estado y evidencia | Mostrar autor/fecha/versión/procedencia cuando aplica; sin mensajes falsos de éxito |

## Estados que debe contemplar cada pantalla

Inicial; cargando; contenido disponible; sin resultados; acceso restringido; error recuperable; captura inválida; guardado pendiente; guardado confirmado; conflicto de revisión; sesión vencida; proveedor pendiente; objeto finalizado/cancelado. Solo se aplican los estados pertinentes al proceso. Un fallo en comunicación no borra una operación local confirmada.

## Reglas de botones y acciones

- Una acción principal por etapa; sus verbos describen el efecto: guardar, firmar, finalizar, publicar, reservar o registrar una excepción.
- Un botón se habilita por rol, permiso fino, contexto, estado y datos completos. La interfaz no constituye la autorización del servidor.
- Ocultar funciones ajenas al rol; si un usuario tiene permiso pero el estado impide actuar, explicar la razón junto a la acción deshabilitada.
- Durante envío mostrar progreso y bloquear doble activación; ante respuesta incierta comprobar operación previa antes de reintentar.
- Volver/cerrar un formulario no cancela una cita, una orden o una estancia persistidas. El abandono de cambios locales tiene su propio diálogo.
- Confirmar operaciones con impacto sobre contenido firmado, destinatarios, dinero, identidad, acceso o ocupación. No pedir confirmación para cada apertura o selección reversible.
- La captura y el gráfico deben funcionar con teclado y alternativa textual; estado y selección se indican con texto además de color.
- Los roles de la tabla de botones son candidatos funcionales. Se valida el permiso específico antes de implementar; participar en un flujo no autoriza todos sus botones.
- Un botón de capacidad futura solo entra en un release cuando su flujo/componente esté aceptado. No presentarlo como operativo por estar dibujado.

## Inventario de pantallas

| ID | Pantalla | Etapa | Objetivo |
| --- | --- | --- | --- |
| [S01](#s01) | Acceso profesional | CE | Identificar cuenta y abrir un contexto de trabajo autorizado. |
| [S02](#s02) | Acceso e invitación del portal | CE | Autenticar cuenta externa y aceptar vínculo verificable. |
| [S03](#s03) | Selector de organización y sucursal | CE | Elegir contexto sin trasladar registros entre organizaciones. |
| [S04](#s04) | Recuperación y aceptación de invitación | CE | Recuperar acceso o resolver alta/invitación sin exponer datos de otra cuenta. |
| [S05](#s05) | Alta y configuración de organización | CE | Preparar un espacio operativo y sus datos de emisión. |
| [S06](#s06) | Equipo, credenciales y permisos | CE | Invitar, revisar y gestionar accesos del equipo. |
| [S07](#s07) | Servicios, precios y emisores | AD | Configurar oferta comercial y datos usados en documentos financieros. |
| [S08](#s08) | Catálogo, plantillas y paquetes de especialidad | TR | Diseñar, revisar, publicar y habilitar capacidades por versión. |
| [S09](#s09) | Directorio de pacientes de la organización | CE | Buscar y seleccionar humano o animal correcto. |
| [S10](#s10) | Ficha administrativa humana | CE | Registrar identidad, contactos, representantes y acceso al portal. |
| [S11](#s11) | Ficha del animal y responsables | CE | Identificar paciente animal y relaciones vigentes. |
| [S12](#s12) | Revisión de identidad y duplicados | TR | Comparar candidatos y resolver identidad con evidencia. |
| [S13](#s13) | Población animal y membresías | AV | Gestionar sujeto colectivo y pertenencias temporales. |
| [S14](#s14) | Agenda operativa | CE | Reservar y modificar citas según profesionales y recursos. |
| [S15](#s15) | Solicitudes y lista de espera | CE | Resolver peticiones de portal/canal asistido y ofrecer intervalos. |
| [S16](#s16) | Recepción y cola | CE | Registrar llegada y mover ingreso a atención sin duplicaciones. |
| [S17](#s17) | Inicio profesional y bandeja clínica | CE | Ver trabajo del día y pendientes con responsable. |
| [S18](#s18) | Espacio de atención clínica | CE | Capturar consulta, revisar y completar contenido sin confundir visita y firma. |
| [S19](#s19) | Expediente y evolución compartida | CE | Consultar evolución de la organización y procedencia por sucursal. |
| [S20](#s20) | Órdenes y resultados pendientes | CE | Emitir órdenes y seguir ejecución/revisión por separado. |
| [S21](#s21) | Lista de trabajo diagnóstico | DI | Asignar y ejecutar tareas autorizadas. |
| [S22](#s22) | Muestras y trazabilidad | DI | Identificar, aceptar, rechazar y entregar muestras con procedencia. |
| [S23](#s23) | Resultados e informe de laboratorio | DI | Registrar, revisar, emitir y corregir resultados. |
| [S24](#s24) | Estudios, imágenes y visor autorizado | DI | Relacionar adquisiciones, revisar estudios e informes. |
| [S25](#s25) | Medicación y receta | CE | Conciliar medicación y emitir prescripción versionada. |
| [S26](#s26) | Farmacia y dispensación | DI | Entregar cantidades/lotes y registrar devoluciones. |
| [S27](#s27) | Administración de medicación | HO | Registrar dosis realmente administradas o no realizadas. |
| [S28](#s28) | Documentos, firma y consentimientos | CE | Revisar, emitir y publicar versiones documentales autorizadas. |
| [S29](#s29) | Inicio del portal | CE | Consultar citas y contenido disponible del paciente/contexto elegido. |
| [S30](#s30) | Citas del portal | CE | Solicitar cita y gestionar cambios permitidos. |
| [S31](#s31) | Documentos publicados en portal | CE | Consultar contenido publicado y descargar versiones autorizadas. |
| [S32](#s32) | Vínculos y delegaciones del portal | CE | Gestionar personas/animales autorizados y vigencia de representación. |
| [S33](#s33) | Seguimiento y comunicaciones | CE | Gestionar tareas y mensajes con responsable, estado y plazo. |
| [S34](#s34) | Presupuestos y etapas de tratamiento | AD | Versionar propuesta comercial y aceptación. |
| [S35](#s35) | Cuenta, pagos y caja | AD | Registrar cargos, pagos, reversos y cierres de caja. |
| [S36](#s36) | Comprobantes y estados externos | AD | Emitir comprobantes y gestionar respuestas/correcciones. |
| [S37](#s37) | Honorarios y liquidaciones | AD | Revisar base contractual, calcular y pagar liquidación. |
| [S38](#s38) | Solicitudes y órdenes de compra | AD | Solicitar, aprobar y recibir compras. |
| [S39](#s39) | Inventario, lotes y transferencias | AD | Conocer existencias y registrar movimientos autorizados. |
| [S40](#s40) | Admisiones y estancias | HO | Admitir y seguir estado clínico/administrativo de estancia. |
| [S41](#s41) | Camas, jaulas y ubicación | HO | Asignar recurso compatible y conservar ocupación histórica. |
| [S42](#s42) | Hoja de estancia y turnos | HO | Registrar cuidados, órdenes, pendientes y entregas de responsabilidad. |
| [S43](#s43) | Caso quirúrgico | HO | Programar y documentar lo previsto y realizado en cirugía. |
| [S44](#s44) | Registro anestésico y recuperación | HO | Conservar evaluación, tiempos, eventos y salida de recuperación. |
| [S45](#s45) | Circuito de urgencias | HO | Registrar llegada, clasificación, atención, reevaluaciones y destino. |
| [S46](#s46) | Cursos y episodios especializados avanzados | AV | Entrar a flujos específicos de curso, transfusión, trasplante o reproducción. |
| [S47](#s47) | Salud poblacional veterinaria | AV | Registrar programas, intervenciones y resultados colectivos. |
| [S48](#s48) | Importaciones y exportaciones | TR | Procesar lotes con alcance, errores y reconciliación. |
| [S49](#s49) | Reportes autorizados | TR | Consultar indicadores con definiciones y alcance. |
| [S50](#s50) | Auditoría y evidencia | TR | Inspeccionar accesos, cambios y autorizaciones. |
| [S51](#s51) | Plan, consumo y soporte del cliente | TR | Gestionar contratación, ayuda y salida de la plataforma. |
| [S52](#s52) | Operación de plataforma MAVRIC | TR | Gestionar soporte, accesos temporales e incidentes sin acceso clínico implícito. |
| [S53](#s53) | Cuenta y preferencias de comunicación | CE | Gestionar canales y preferencias verificadas de la cuenta. |
| [S54](#s54) | Integraciones y tareas externas | TR | Conectar proveedores y resolver estados externos con alcance explícito. |
| [S55](#s55) | Disponibilidad, lugares y recursos | CE | Configurar jornadas y recursos sin alterar reservas silenciosamente. |
| [S56](#s56) | Acceso de operador MAVRIC | TR | Autenticar al operador de plataforma sin conceder acceso clínico de clientes. |

<a id="s01"></a>
## S01. Acceso profesional

**Espacio:** Acceso. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción, Administrador de la organización, Asistente o enfermería, Equipo de diagnóstico, Farmacia, Caja y administración financiera, Compras y almacén, Auditor autorizado.

**Objetivo:** Identificar cuenta y abrir un contexto de trabajo autorizado.

**Información:** RUC del espacio; Usuario; Contraseña; Estado de acceso y recuperación.

**Estructura funcional:** Formulario centrado; una acción principal de ingreso; recuperación visible.

**Flujos relacionados:** [F01](02_Flujos_y_Diagramas.md#f01), [F03](02_Flujos_y_Diagramas.md#f03), [F04](02_Flujos_y_Diagramas.md#f04).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F01_A01` | Ingresar | F01 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F03_A01` | Recuperar acceso | F03 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F03_A02` | Enviar enlace | F03 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F03_A03` | Guardar nueva contraseña | F03 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F03_A04` | Volver al acceso | F03 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F04_A01` | Volver a ingresar | F04 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F04_A02` | Reintentar | F04 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F04_A03` | Comparar versiones | F04 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F04_A04` | Guardar revisión resuelta | F04 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Comparación completada y nueva revisión vigente. | Guarda la resolución explícita sin sobrescribir silenciosamente cambios ajenos. | Mostrar cambios comparados. |
| `F04_A05` | Salir | F04 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s02"></a>
## S02. Acceso e invitación del portal

**Espacio:** Portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Paciente humano, Representante o responsable.

**Objetivo:** Autenticar cuenta externa y aceptar vínculo verificable.

**Información:** Identificador de cuenta; Contraseña o mecanismo acordado; Invitación; Estado de verificación.

**Estructura funcional:** Formulario simple; contexto de la organización si el enlace lo proporciona.

**Flujos relacionados:** [F03](02_Flujos_y_Diagramas.md#f03), [F39](02_Flujos_y_Diagramas.md#f39), [F70](02_Flujos_y_Diagramas.md#f70).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F03_A01` | Recuperar acceso | F03 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F39_A04` | Aceptar vínculo | F39 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F70_A01` | Ingresar al portal | F70 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F70_A02` | Completar invitación | F70 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s03"></a>
## S03. Selector de organización y sucursal

**Espacio:** Acceso. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción, Administrador de la organización, Asistente o enfermería, Equipo de diagnóstico, Farmacia, Caja y administración financiera, Compras y almacén, Auditor autorizado.

**Objetivo:** Elegir contexto sin trasladar registros entre organizaciones.

**Información:** Membresías vigentes; Sucursal operativa; Lugar de atención; Aviso de borrador pendiente.

**Estructura funcional:** Selector de cabecera y diálogo de cambio si existe trabajo pendiente.

**Flujos relacionados:** [F01](02_Flujos_y_Diagramas.md#f01), [F02](02_Flujos_y_Diagramas.md#f02), [F79](02_Flujos_y_Diagramas.md#f79).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F01_A02` | Elegir espacio | F01 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F01_A03` | Continuar | F01 / CE | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F02_A01` | Cambiar espacio | F02 / CE | ADM, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F02_A02` | Cambiar sucursal | F02 / CE | ADM, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F02_A03` | Guardar y cambiar | F02 / CE | ADM, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F02_A04` | Descartar cambios locales | F02 / CE | ADM, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F02_A05` | Seguir aquí | F02 / CE | ADM, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F79_A01` | Cerrar sesión | F79 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s04"></a>
## S04. Recuperación y aceptación de invitación

**Espacio:** Acceso. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción, Administrador de la organización, Paciente humano, Representante o responsable.

**Objetivo:** Recuperar acceso o resolver alta/invitación sin exponer datos de otra cuenta.

**Información:** Canal verificado; Estado del enlace; Requisitos de contraseña; Destino después de completar.

**Estructura funcional:** Pasos cortos; requisitos visibles; estados de enlace usado o vencido.

**Flujos relacionados:** [F03](02_Flujos_y_Diagramas.md#f03), [F06](02_Flujos_y_Diagramas.md#f06).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F06_A02` | Aceptar invitación | F06 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s05"></a>
## S05. Alta y configuración de organización

**Espacio:** Configuración. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Administrador de la organización, Operador o soporte de MAVRIC.

**Objetivo:** Preparar un espacio operativo y sus datos de emisión.

**Información:** Organización/vertical; Emisor; Sucursales y lugares; Pendientes de activación.

**Estructura funcional:** Asistente por pasos con resumen y posibilidad de guardar configuración incompleta.

**Flujos relacionados:** [F05](02_Flujos_y_Diagramas.md#f05).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F05_A01` | Crear organización | F05 / CE | ADM, SOP | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F05_A02` | Guardar y continuar | F05 / CE | ADM, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F05_A03` | Añadir sucursal | F05 / CE | ADM, SOP | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F05_A05` | Activar espacio | F05 / CE | ADM, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s06"></a>
## S06. Equipo, credenciales y permisos

**Espacio:** Configuración. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Administrador de la organización.

**Objetivo:** Invitar, revisar y gestionar accesos del equipo.

**Información:** Miembros y estados; Credenciales y evidencias; Roles/sucursales/alcance clínico; Tareas afectadas por revocación.

**Estructura funcional:** Listado con ficha lateral o página de detalle y resumen de impacto.

**Flujos relacionados:** [F05](02_Flujos_y_Diagramas.md#f05), [F06](02_Flujos_y_Diagramas.md#f06), [F07](02_Flujos_y_Diagramas.md#f07).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F05_A04` | Invitar equipo | F05 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F06_A01` | Invitar profesional | F06 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F06_A03` | Revisar credenciales | F06 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F06_A04` | Activar membresía | F06 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F06_A05` | Reenviar invitación | F06 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F07_A01` | Editar permisos | F07 / CE | ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F07_A02` | Ver impacto | F07 / CE | ADM | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F07_A03` | Guardar cambios | F07 / CE | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F07_A04` | Revocar membresía | F07 / CE | ADM | Administrador autorizado; miembro y alcance identificados. | Retira permisos futuros; conserva autoría y pendientes que requieren reasignación. | Miembro, acceso afectado y pendientes; confirmar. |
| `F07_A05` | Asignar suplente | F07 / CE | ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s07"></a>
## S07. Servicios, precios y emisores

**Espacio:** Configuración. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Administrador de la organización, Caja y administración financiera.

**Objetivo:** Configurar oferta comercial y datos usados en documentos financieros.

**Información:** Servicios y duración; Precio y moneda; Vigencias, descuentos y convenios; Emisores autorizados.

**Estructura funcional:** Tablas de configuración con versiones; separar servicios clínicos de tarifas.

**Flujos relacionados:** [F75](02_Flujos_y_Diagramas.md#f75), [F77](02_Flujos_y_Diagramas.md#f77).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F75_A01` | Crear servicio | F75 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F75_A02` | Crear tarifa | F75 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F75_A03` | Editar emisor | F75 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F75_A04` | Definir vigencia | F75 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F75_A05` | Ver impacto | F75 / AD | ADM, CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F75_A06` | Publicar configuración | F75 / AD | ADM, CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F77_A01` | Crear convenio | F77 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F77_A02` | Verificar cobertura registrada | F77 / AD | ADM, CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F77_A04` | Registrar respuesta | F77 / AD | ADM, CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F77_A05` | Asignar pagador | F77 / AD | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F77_A06` | Ver saldo institucional | F77 / AD | ADM, CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s08"></a>
## S08. Catálogo, plantillas y paquetes de especialidad

**Espacio:** Configuración. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Profesional clínico.

**Objetivo:** Diseñar, revisar, publicar y habilitar capacidades por versión.

**Información:** Paquetes y alcance; Versiones/estados; Campos y componentes; Evidencias de validación.

**Estructura funcional:** Listado de paquetes, detalle de versión y vista de ejemplo con perfil de paciente.

**Flujos relacionados:** [F08](02_Flujos_y_Diagramas.md#f08).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F08_A01` | Nueva versión | F08 / TR | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F08_A02` | Vista de ejemplo | F08 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F08_A03` | Enviar a revisión | F08 / TR | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F08_A04` | Publicar versión | F08 / TR | ADM | Versión revisada y evidencias de capacidades obligatorias completas. | Publica versión inmutable para nuevas capturas habilitadas. | Versión, alcance y evidencias; confirmar publicación. |
| `F08_A05` | Habilitar paquete | F08 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F08_A06` | Retirar versión | F08 / TR | ADM | Versión existente y facultad de gestión. | Retira para nuevas capturas según política; conserva lectura histórica. | Uso e impacto en paquetes; confirmar. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s09"></a>
## S09. Directorio de pacientes de la organización

**Espacio:** Pacientes. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Profesional clínico, Asistente o enfermería.

**Objetivo:** Buscar y seleccionar humano o animal correcto.

**Información:** Búsqueda permitida; Coincidencias; Identificadores; Acciones según rol.

**Estructura funcional:** Búsqueda y listado con dominio visible; ficha seleccionada antes de acciones clínicas.

**Flujos relacionados:** [F10](02_Flujos_y_Diagramas.md#f10), [F11](02_Flujos_y_Diagramas.md#f11), [F15](02_Flujos_y_Diagramas.md#f15), [F16](02_Flujos_y_Diagramas.md#f16), [F20](02_Flujos_y_Diagramas.md#f20).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F10_A01` | Buscar paciente | F10 / CE | REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F10_A02` | Registrar humano | F10 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F10_A03` | Seleccionar existente | F10 / CE | REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F10_A04` | Añadir representante | F10 / CE | REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F10_A05` | Guardar paciente | F10 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F11_A01` | Registrar animal | F11 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F11_A02` | Buscar responsable | F11 / CE | REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F11_A03` | Añadir responsable | F11 / CE | REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F11_A04` | Guardar animal | F11 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F11_A05` | Enviar verificación | F11 / CE | REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F15_A01` | Buscar | F15 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F15_A02` | Abrir ficha | F15 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s10"></a>
## S10. Ficha administrativa humana

**Espacio:** Pacientes. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Profesional clínico, Administrador de la organización.

**Objetivo:** Registrar identidad, contactos, representantes y acceso al portal.

**Información:** Identificación y nacimiento; Contactos locales; Representantes/pagador; Relaciones y verificaciones.

**Estructura funcional:** Secciones de filiación, contactos y relaciones; acceso clínico como acción autorizada aparte.

**Flujos relacionados:** [F10](02_Flujos_y_Diagramas.md#f10), [F12](02_Flujos_y_Diagramas.md#f12), [F15](02_Flujos_y_Diagramas.md#f15), [F39](02_Flujos_y_Diagramas.md#f39).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F10_A02` | Registrar humano | F10 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F12_A01` | Editar relación | F12 / CE | REC, ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F12_A02` | Verificar relación | F12 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F12_A03` | Establecer vigencia | F12 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F12_A04` | Revocar acceso | F12 / CE | REC, ADM | Actor autorizado a gestionar la relación y vínculo identificado. | Retira alcance de la relación correspondiente, sin borrar historia. | Vínculo y acceso afectado; confirmar. |
| `F12_A05` | Confirmar cambio | F12 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F15_A03` | Ver historia | F15 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F39_A01` | Invitar al portal | F39 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F39_A02` | Definir alcance | F39 / CE | REC, ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F39_A03` | Verificar identidad | F39 / CE | ADM, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F39_A05` | Revocar delegación | F39 / CE | REC, ADM | Facultad verificada para revocar ese vínculo. | Retira acceso del representante al alcance definido y conserva evidencia. | Persona, paciente/animal, alcance y motivo; confirmar. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s11"></a>
## S11. Ficha del animal y responsables

**Espacio:** Pacientes. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Profesional clínico, Administrador de la organización.

**Objetivo:** Identificar paciente animal y relaciones vigentes.

**Información:** Especie, perfil y nacimiento; Microchip opcional; Responsables y pagador; Historial de relaciones.

**Estructura funcional:** Resumen animal destacado; personas responsables en sección separada con alcance y vigencia.

**Flujos relacionados:** [F11](02_Flujos_y_Diagramas.md#f11), [F12](02_Flujos_y_Diagramas.md#f12), [F15](02_Flujos_y_Diagramas.md#f15), [F39](02_Flujos_y_Diagramas.md#f39).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F11_A01` | Registrar animal | F11 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F12_A01` | Editar relación | F12 / CE | REC, ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F12_A04` | Revocar acceso | F12 / CE | REC, ADM | Actor autorizado a gestionar la relación y vínculo identificado. | Retira alcance de la relación correspondiente, sin borrar historia. | Vínculo y acceso afectado; confirmar. |
| `F15_A03` | Ver historia | F15 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F39_A01` | Invitar al portal | F39 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s12"></a>
## S12. Revisión de identidad y duplicados

**Espacio:** Pacientes. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Profesional clínico.

**Objetivo:** Comparar candidatos y resolver identidad con evidencia.

**Información:** Fichas candidatas; Diferencias; Referencias afectadas; Motivo y revisión.

**Estructura funcional:** Comparación en dos columnas; resumen explícito del impacto antes de confirmar.

**Flujos relacionados:** [F13](02_Flujos_y_Diagramas.md#f13).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F13_A01` | Comparar fichas | F13 / TR | ADM, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F13_A02` | Elegir ficha conservada | F13 / TR | ADM, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F13_A03` | Ver impacto | F13 / TR | ADM, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F13_A04` | Confirmar fusión | F13 / TR | ADM | Mismo tenant; evidencia de identidad y permiso especial; impacto revisado. | Consolida referencias conservando originales y trazabilidad. | Identidad, ficha conservada, impacto y motivo; confirmar expresamente. |
| `F13_A05` | Solicitar corrección | F13 / TR | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s13"></a>
## S13. Población animal y membresías

**Espacio:** Veterinaria avanzada. **Etapa base:** Capacidades especializadas avanzadas.

**Usuarios de la pantalla:** Profesional clínico, Recepción.

**Objetivo:** Gestionar sujeto colectivo y pertenencias temporales.

**Información:** Tipo de población; Responsable; Individuos/denominador; Ingresos, traslados y bajas.

**Estructura funcional:** Ficha poblacional con línea de tiempo de membresías y acceso a individuos autorizados.

**Flujos relacionados:** [F14](02_Flujos_y_Diagramas.md#f14), [F60](02_Flujos_y_Diagramas.md#f60).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F14_A01` | Crear población | F14 / AV | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F14_A02` | Añadir individuo | F14 / AV | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F14_A03` | Registrar traslado | F14 / AV | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F14_A04` | Registrar baja | F14 / AV | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F14_A05` | Guardar pertenencias | F14 / AV | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s14"></a>
## S14. Agenda operativa

**Espacio:** Agenda. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Profesional clínico, Administrador de la organización.

**Objetivo:** Reservar y modificar citas según profesionales y recursos.

**Información:** Día/semana; Profesional y sucursal; Disponibilidad y recursos; Detalle de cita.

**Estructura funcional:** Calendario con alternativa en lista; creación/detalle en panel, paciente/contexto siempre visibles.

**Flujos relacionados:** [F09](02_Flujos_y_Diagramas.md#f09), [F16](02_Flujos_y_Diagramas.md#f16), [F18](02_Flujos_y_Diagramas.md#f18), [F52](02_Flujos_y_Diagramas.md#f52).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F16_A01` | Nueva cita | F16 / CE | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F16_A02` | Ver disponibilidad | F16 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F16_A03` | Reservar cita | F16 / CE | PRO, REC | Identidad/servicio/contexto elegidos y disponibilidad vigente. | Crea reserva confirmada; si el recurso cambió, conserva captura y ofrece alternativas. | Resumen previo de paciente, lugar, profesional y horario. |
| `F16_A04` | Ver confirmación | F16 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F16_A05` | Enviar recordatorio | F16 / CE | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F18_A01` | Confirmar asistencia | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A02` | Reprogramar | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A03` | Cancelar cita | F18 / CE | PAC, PRO, REC, RES | Rol autorizado; cita en estado cancelable. | Cancela reserva y libera recursos aplicables; conserva motivo/historial. | Resumen de cita y condiciones; motivo cuando lo requiera política. |
| `F18_A04` | Guardar cambio | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A05` | Conservar cita | F18 / CE | PAC, PRO, REC, RES | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s15"></a>
## S15. Solicitudes y lista de espera

**Espacio:** Agenda. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción.

**Objetivo:** Resolver peticiones de portal/canal asistido y ofrecer intervalos.

**Información:** Solicitudes y antigüedad; Preferencias; Ofertas/vigencia; Responsable y siguiente paso.

**Estructura funcional:** Bandeja de pendientes con detalle y acción de resolución; no aparentar reserva inexistente.

**Flujos relacionados:** [F17](02_Flujos_y_Diagramas.md#f17), [F19](02_Flujos_y_Diagramas.md#f19), [F63](02_Flujos_y_Diagramas.md#f63).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F19_A01` | Añadir a espera | F19 / CE | REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F19_A02` | Ofrecer intervalo | F19 / CE | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F19_A05` | Salir de espera | F19 / CE | PAC, REC, RES | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F63_A01` | Revisar solicitud asistida | F63 / AD | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F63_A05` | Derivar a recepción | F63 / AD | REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s16"></a>
## S16. Recepción y cola

**Espacio:** Agenda. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Asistente o enfermería, Profesional clínico.

**Objetivo:** Registrar llegada y mover ingreso a atención sin duplicaciones.

**Información:** Citas esperadas; Ingresos directos; Colas por servicio; Llamada, retiro y preparación.

**Estructura funcional:** Lista por estado; acciones por fila y detalle suficiente para confirmar identidad.

**Flujos relacionados:** [F20](02_Flujos_y_Diagramas.md#f20).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F20_A01` | Registrar llegada | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F20_A02` | Ingreso sin cita | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F20_A03` | Enviar a cola | F20 / CE | ASI, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F20_A04` | Llamar paciente | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F20_A05` | Registrar retiro | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F20_A06` | Iniciar atención | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s17"></a>
## S17. Inicio profesional y bandeja clínica

**Espacio:** Clínica. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería.

**Objetivo:** Ver trabajo del día y pendientes con responsable.

**Información:** Atenciones del día; Borradores propios; Resultados por revisar; Seguimientos y suplencias.

**Estructura funcional:** Bandejas priorizadas por estado operativo con acceso directo a atención o pendiente.

**Flujos relacionados:** [F20](02_Flujos_y_Diagramas.md#f20), [F21](02_Flujos_y_Diagramas.md#f21), [F34](02_Flujos_y_Diagramas.md#f34), [F41](02_Flujos_y_Diagramas.md#f41).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F20_A06` | Iniciar atención | F20 / CE | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F21_A01` | Iniciar atención | F21 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F21_A02` | Guardar borrador | F21 / CE | ASI, PRO | Atención o nota editable; datos capturados; revisión esperada vigente. | Guarda una revisión editable. No firma ni termina la visita. | Sin diálogo; mostrar confirmación del guardado real. |
| `F21_A03` | Revisar resumen | F21 / CE | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F21_A04` | Finalizar visita | F21 / CE | PRO | Profesional autorizado, resumen revisado y pendientes asignados. | Finaliza la visita; no convierte resultados pendientes en revisados. | Resumen de paciente, contexto y pendientes; confirmar finalización. |
| `F21_A05` | Dejar pendiente | F21 / CE | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F34_A01` | Revisar resultado | F34 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F34_A03` | Asignar seguimiento | F34 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F34_A04` | Reasignar pendiente | F34 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F34_A05` | Solicitar aclaración | F34 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s18"></a>
## S18. Espacio de atención clínica

**Espacio:** Clínica. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería.

**Objetivo:** Capturar consulta, revisar y completar contenido sin confundir visita y firma.

**Información:** Cabecera paciente/contexto; Resumen clínico autorizado; Formulario/gráfico de especialidad; Órdenes, receta, documentos y pendientes.

**Estructura funcional:** Cabecera persistente; navegación por secciones; zona principal de captura; acciones de guardado y revisión visibles.

**Flujos relacionados:** [F21](02_Flujos_y_Diagramas.md#f21), [F22](02_Flujos_y_Diagramas.md#f22), [F23](02_Flujos_y_Diagramas.md#f23), [F24](02_Flujos_y_Diagramas.md#f24), [F25](02_Flujos_y_Diagramas.md#f25), [F26](02_Flujos_y_Diagramas.md#f26), [F27](02_Flujos_y_Diagramas.md#f27), [F30](02_Flujos_y_Diagramas.md#f30), [F35](02_Flujos_y_Diagramas.md#f35), [F61](02_Flujos_y_Diagramas.md#f61), [F72](02_Flujos_y_Diagramas.md#f72), [F76](02_Flujos_y_Diagramas.md#f76).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F22_A01` | Abrir sección | F22 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F22_A02` | Añadir medición | F22 / CE | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F22_A03` | Marcar dato desconocido | F22 / CE | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F22_A04` | Guardar borrador | F22 / CE | ASI, PRO | Atención o nota editable; datos capturados; revisión esperada vigente. | Guarda una revisión editable. No firma ni termina la visita. | Sin diálogo; mostrar confirmación del guardado real. |
| `F22_A05` | Comparar versiones | F22 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F23_A01` | Elegir vista anatómica | F23 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F23_A02` | Marcar región | F23 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F23_A03` | Añadir hallazgo | F23 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F23_A04` | Vincular procedimiento | F23 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F23_A05` | Deshacer cambio local | F23 / CE | PRO | Cambio aún no confirmado del borrador actual. | Deshace ese cambio local; no elimina hechos firmados de otras visitas. | Sin confirmación para cambio local reversible. |
| `F24_A01` | Seleccionar pieza | F24 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F24_A02` | Seleccionar cara | F24 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F24_A03` | Registrar condición | F24 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F24_A04` | Registrar procedimiento | F24 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F24_A05` | Ver cambios | F24 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A01` | Añadir medición | F25 / CE | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F25_A02` | Elegir unidad | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A03` | Aplicar instrumento | F25 / CE | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F25_A04` | Ver referencia | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A05` | Ver tendencia | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A06` | Ver tabla | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F26_A01` | Adjuntar archivo | F26 / CE | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F26_A02` | Ver vista previa | F26 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F26_A03` | Comparar imágenes | F26 / CE | DIA, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F26_A04` | Descargar autorizado | F26 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F26_A05` | Retirar asociación | F26 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F27_A01` | Revisar documento | F27 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F27_A02` | Firmar revisión | F27 / CE | PRO | Autor habilitado, revisión exacta guardada y requisitos completos. | Firma/cierra esa revisión y conserva evidencia; el contenido original queda sin edición. | Paciente, emisor, contenido y revisión; confirmar firma. |
| `F27_A03` | Volver al borrador | F27 / CE | PRO | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F61_A01` | Iniciar dictado | F61 / TR | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F61_A02` | Detener dictado | F61 / TR | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F61_A03` | Revisar transcripción | F61 / TR | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F61_A04` | Aceptar selección | F61 / TR | PRO | Propuesta IA revisada por el profesional; campos elegidos. | Incorpora solo selección confirmada a borrador, sin firma automática. | Comparación y valores seleccionados visibles. |
| `F61_A05` | Descartar propuesta | F61 / TR | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F72_A01` | Abrir componente | F72 / TR | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F72_A02` | Elegir estructura | F72 / TR | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F72_A03` | Añadir registro | F72 / TR | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F72_A04` | Ver tabla equivalente | F72 / TR | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F72_A05` | Comparar visitas | F72 / TR | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F72_A06` | Revisar cambios | F72 / TR | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F76_A01` | Ver historial preventivo | F76 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F76_A02` | Registrar actuación preventiva | F76 / CE | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F76_A03` | Registrar no realizada | F76 / CE | PRO, ASI | Actuación/dosis identificada; motivo y responsable de revisión definidos. | Conserva excepción; no marca actuación como realizada. | Mostrar motivo y siguiente responsable. |
| `F76_A05` | Programar próximo control | F76 / CE | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s19"></a>
## S19. Expediente y evolución compartida

**Espacio:** Clínica. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería, Auditor autorizado.

**Objetivo:** Consultar evolución de la organización y procedencia por sucursal.

**Información:** Línea de tiempo; Episodios/problemas/antecedentes; Comparación de gráficos; Versiones, adendas y origen.

**Estructura funcional:** Resumen longitudinal y eventos filtrables; indicar restricciones y distinguirlos de ausencia de datos.

**Flujos relacionados:** [F15](02_Flujos_y_Diagramas.md#f15), [F23](02_Flujos_y_Diagramas.md#f23), [F24](02_Flujos_y_Diagramas.md#f24), [F25](02_Flujos_y_Diagramas.md#f25), [F28](02_Flujos_y_Diagramas.md#f28), [F29](02_Flujos_y_Diagramas.md#f29), [F72](02_Flujos_y_Diagramas.md#f72), [F76](02_Flujos_y_Diagramas.md#f76).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F15_A03` | Ver historia | F15 / CE | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F15_A04` | Filtrar por fecha | F15 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F15_A05` | Ver procedencia | F15 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F23_A06` | Comparar evolución | F23 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F24_A06` | Comparar odontogramas | F24 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A05` | Ver tendencia | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F25_A06` | Ver tabla | F25 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F28_A01` | Crear adenda | F28 / CE | PRO | Registro original firmado visible y permiso de corrección. | Abre borrador nuevo referenciado al original. | Sin cierre inmediato; exigir motivo en el formulario. |
| `F28_A02` | Ver original | F28 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F28_A03` | Revisar corrección | F28 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F28_A05` | Ver versiones | F28 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F29_A01` | Crear episodio | F29 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F29_A02` | Añadir antecedente | F29 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F29_A03` | Registrar problema | F29 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F29_A04` | Registrar alergia | F29 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F29_A05` | Vincular atención | F29 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F29_A06` | Actualizar estado | F29 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F76_A01` | Ver historial preventivo | F76 / CE | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s20"></a>
## S20. Órdenes y resultados pendientes

**Espacio:** Diagnóstico. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Equipo de diagnóstico.

**Objetivo:** Emitir órdenes y seguir ejecución/revisión por separado.

**Información:** Órdenes y estados; Tareas/ejecutores; Informes/versiones; Responsable de revisión.

**Estructura funcional:** Lista de órdenes con detalle de etapas; pestañas o secciones para ejecución e informe.

**Flujos relacionados:** [F30](02_Flujos_y_Diagramas.md#f30), [F34](02_Flujos_y_Diagramas.md#f34).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F30_A01` | Nueva orden | F30 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F30_A02` | Elegir servicio | F30 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F30_A03` | Emitir orden | F30 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F30_A04` | Generar remisión | F30 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F30_A05` | Ver tareas | F30 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F30_A06` | Cancelar orden | F30 / CE | PRO | Permiso vigente y estado de orden cancelable. | Detiene nuevas tareas de la orden; conserva ejecuciones parciales y resultados previos. | Ver tareas/ejecuciones afectadas y registrar motivo. |
| `F34_A01` | Revisar resultado | F34 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F34_A02` | Registrar revisión | F34 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s21"></a>
## S21. Lista de trabajo diagnóstico

**Espacio:** Diagnóstico. **Etapa base:** Diagnóstico interno y farmacia.

**Usuarios de la pantalla:** Equipo de diagnóstico, Profesional clínico.

**Objetivo:** Asignar y ejecutar tareas autorizadas.

**Información:** Pendientes/aceptadas; Paciente y orden; Intentos; Responsable y tiempos.

**Estructura funcional:** Bandeja de tareas; aceptar antes de ejecutar; estado de identidad y orden destacado.

**Flujos relacionados:** [F31](02_Flujos_y_Diagramas.md#f31), [F33](02_Flujos_y_Diagramas.md#f33).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F31_A01` | Aceptar tarea | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s22"></a>
## S22. Muestras y trazabilidad

**Espacio:** Diagnóstico. **Etapa base:** Diagnóstico interno y farmacia.

**Usuarios de la pantalla:** Equipo de diagnóstico, Asistente o enfermería, Profesional clínico.

**Objetivo:** Identificar, aceptar, rechazar y entregar muestras con procedencia.

**Información:** ID y origen de muestra; Obtención/entregas; Aceptación/rechazo; Vínculo a orden/caso.

**Estructura funcional:** Ficha de muestra y cronología de custodia; operaciones de entrega con receptor identificado.

**Flujos relacionados:** [F31](02_Flujos_y_Diagramas.md#f31), [F32](02_Flujos_y_Diagramas.md#f32), [F53](02_Flujos_y_Diagramas.md#f53), [F59](02_Flujos_y_Diagramas.md#f59).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F31_A02` | Registrar obtención | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F31_A03` | Imprimir identificación | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F31_A04` | Aceptar muestra | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F31_A05` | Rechazar muestra | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F31_A06` | Registrar entrega | F31 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s23"></a>
## S23. Resultados e informe de laboratorio

**Espacio:** Diagnóstico. **Etapa base:** Diagnóstico interno y farmacia.

**Usuarios de la pantalla:** Equipo de diagnóstico, Profesional clínico.

**Objetivo:** Registrar, revisar, emitir y corregir resultados.

**Información:** Valores, unidades y referencias; Métodos/procedencia; Informe preliminar/final; Correcciones y revisión clínica.

**Estructura funcional:** Resultados estructurados y documento de informe; versión y estado siempre visibles.

**Flujos relacionados:** [F32](02_Flujos_y_Diagramas.md#f32), [F34](02_Flujos_y_Diagramas.md#f34), [F57](02_Flujos_y_Diagramas.md#f57), [F60](02_Flujos_y_Diagramas.md#f60).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F32_A01` | Registrar resultados | F32 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F32_A02` | Guardar preliminar | F32 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F32_A03` | Emitir informe | F32 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F32_A04` | Corregir informe | F32 / DI | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F32_A05` | Ver trazabilidad | F32 / DI | DIA | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F34_A02` | Registrar revisión | F34 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s24"></a>
## S24. Estudios, imágenes y visor autorizado

**Espacio:** Diagnóstico. **Etapa base:** Diagnóstico interno y farmacia.

**Usuarios de la pantalla:** Equipo de diagnóstico, Profesional clínico.

**Objetivo:** Relacionar adquisiciones, revisar estudios e informes.

**Información:** Lista de estudios; Paciente/orden/adquisición; Imagen/serie o adjunto; Informe y procedencia.

**Estructura funcional:** Lista de estudios y zona de visualización; identificación persistente y acceso al informe asociado.

**Flujos relacionados:** [F26](02_Flujos_y_Diagramas.md#f26), [F33](02_Flujos_y_Diagramas.md#f33), [F34](02_Flujos_y_Diagramas.md#f34), [F72](02_Flujos_y_Diagramas.md#f72).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F26_A01` | Adjuntar archivo | F26 / CE | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F26_A03` | Comparar imágenes | F26 / CE | DIA, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F33_A01` | Abrir estudio | F33 / DI | DIA, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F33_A02` | Vincular adquisición | F33 / DI | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F33_A03` | Guardar informe | F33 / DI | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F33_A04` | Firmar informe | F33 / DI | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F33_A05` | Ver imágenes | F33 / DI | DIA, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F33_A06` | Solicitar conciliación | F33 / DI | DIA, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F34_A02` | Registrar revisión | F34 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s25"></a>
## S25. Medicación y receta

**Espacio:** Clínica. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico.

**Objetivo:** Conciliar medicación y emitir prescripción versionada.

**Información:** Medicación referida y fuentes; Items de receta; Pauta registrada; Emisor y versión.

**Estructura funcional:** Conciliación separada de la receta nueva; vista previa antes de cierre.

**Flujos relacionados:** [F35](02_Flujos_y_Diagramas.md#f35).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F35_A01` | Conciliar medicación | F35 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F35_A02` | Añadir medicamento | F35 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F35_A03` | Guardar receta en borrador | F35 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F35_A04` | Revisar receta | F35 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F35_A05` | Emitir receta | F35 / CE | PRO | Prescriptor habilitado, datos y emisor revisados. | Emite receta versionada; no registra administración. | Vista previa de paciente, items y emisor; confirmar emisión. |
| `F35_A06` | Ver versiones | F35 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s26"></a>
## S26. Farmacia y dispensación

**Espacio:** Farmacia. **Etapa base:** Diagnóstico interno y farmacia.

**Usuarios de la pantalla:** Farmacia.

**Objetivo:** Entregar cantidades/lotes y registrar devoluciones.

**Información:** Orden y cantidades pendientes; Productos y lotes; Entrega parcial/total; Devoluciones y stock.

**Estructura funcional:** Cola de órdenes y detalle de entrega con revisión de lote/cantidad.

**Flujos relacionados:** [F36](02_Flujos_y_Diagramas.md#f36), [F48](02_Flujos_y_Diagramas.md#f48).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F36_A01` | Preparar entrega | F36 / DI | FAR | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F36_A02` | Elegir lote | F36 / DI | FAR | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F36_A03` | Registrar entrega parcial | F36 / DI | FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F36_A04` | Confirmar dispensación | F36 / DI | FAR | Permiso de farmacia; cantidades y lote válidos; orden verificada. | Registra entrega y movimiento de stock vinculado, una sola vez. | Resumen de paciente, producto, lote y cantidad. |
| `F36_A05` | Registrar devolución | F36 / DI | FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s27"></a>
## S27. Administración de medicación

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Asistente o enfermería, Profesional clínico.

**Objetivo:** Registrar dosis realmente administradas o no realizadas.

**Información:** Orden vigente; Programación; Registro real; Excepciones y revisión.

**Estructura funcional:** Hoja temporal con acción de verificación; no permitir marcar varias dosis como realizadas sin evidencia individual.

**Flujos relacionados:** [F37](02_Flujos_y_Diagramas.md#f37), [F54](02_Flujos_y_Diagramas.md#f54), [F57](02_Flujos_y_Diagramas.md#f57).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F37_A01` | Verificar orden | F37 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F37_A02` | Registrar administración | F37 / HO | ASI, PRO | Actor competente y asignado; orden vigente, paciente y datos reales verificados. | Registra administración realizada con ejecutor y tiempos; reintento no duplica. | Revisar identidad, orden y datos de la actuación antes de registrar. |
| `F37_A03` | Registrar no realizada | F37 / HO | ASI, PRO | Actuación/dosis identificada; motivo y responsable de revisión definidos. | Conserva excepción; no marca actuación como realizada. | Mostrar motivo y siguiente responsable. |
| `F37_A04` | Solicitar revisión | F37 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F37_A05` | Ver historial de dosis | F37 / HO | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s28"></a>
## S28. Documentos, firma y consentimientos

**Espacio:** Clínica. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción.

**Objetivo:** Revisar, emitir y publicar versiones documentales autorizadas.

**Información:** Tipo y plantilla; Vista previa; Firma/decisión/evidencia; Publicación y destinatario.

**Estructura funcional:** Listado documental y vista previa; separar estado de firma de estado de publicación.

**Flujos relacionados:** [F26](02_Flujos_y_Diagramas.md#f26), [F27](02_Flujos_y_Diagramas.md#f27), [F28](02_Flujos_y_Diagramas.md#f28), [F38](02_Flujos_y_Diagramas.md#f38), [F40](02_Flujos_y_Diagramas.md#f40), [F55](02_Flujos_y_Diagramas.md#f55), [F76](02_Flujos_y_Diagramas.md#f76).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F26_A01` | Adjuntar archivo | F26 / CE | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F27_A01` | Revisar documento | F27 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F27_A02` | Firmar revisión | F27 / CE | PRO | Autor habilitado, revisión exacta guardada y requisitos completos. | Firma/cierra esa revisión y conserva evidencia; el contenido original queda sin edición. | Paciente, emisor, contenido y revisión; confirmar firma. |
| `F27_A04` | Ver evidencia de firma | F27 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F28_A01` | Crear adenda | F28 / CE | PRO | Registro original firmado visible y permiso de corrección. | Abre borrador nuevo referenciado al original. | Sin cierre inmediato; exigir motivo en el formulario. |
| `F28_A04` | Firmar adenda | F28 / CE | PRO | Adenda revisada y vinculada al original; permiso vigente. | Emite corrección nueva sin reemplazar el original firmado. | Original, motivo y contenido de corrección; confirmar. |
| `F28_A05` | Ver versiones | F28 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F38_A01` | Nuevo documento | F38 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F38_A02` | Ver vista previa | F38 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F38_A03` | Registrar consentimiento | F38 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F38_A04` | Registrar decisión | F38 / CE | PAC, PRO, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F38_A05` | Cerrar documento | F38 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F38_A06` | Elegir entrega | F38 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F40_A01` | Preparar publicación | F40 / CE | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F40_A02` | Ver como destinatario | F40 / CE | PRO | Permiso de preparar publicación. | Muestra exactamente la versión y alcance que se propone compartir; no publica. | Sin confirmación; vista claramente identificada como previa. |
| `F40_A03` | Publicar documento | F40 / CE | PRO | Versión emitida, permiso de publicación y destinatario verificado. | Hace accesible esa versión al destinatario definido y conserva auditoría. | Mostrar vista del destinatario, versión y alcance; confirmar. |
| `F40_A04` | Ver entregas | F40 / CE | PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F40_A05` | Retirar publicación | F40 / CE | PRO | Permiso de retirar y publicación existente. | Impide accesos futuros conforme a reglas; conserva documento e historial de publicación. | Destinatario, motivo e impacto; confirmar retiro. |
| `F55_A03` | Emitir resumen | F55 / HO | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F76_A04` | Emitir constancia | F76 / CE | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s29"></a>
## S29. Inicio del portal

**Espacio:** Portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Paciente humano, Representante o responsable.

**Objetivo:** Consultar citas y contenido disponible del paciente/contexto elegido.

**Información:** Paciente/animal y organización; Próxima cita; Documentos publicados; Seguimiento; saldos cuando exista módulo.

**Estructura funcional:** Inicio sencillo adaptado a móvil; contexto y selector de paciente claros, sin chrome interno de clínica.

**Flujos relacionados:** [F17](02_Flujos_y_Diagramas.md#f17), [F41](02_Flujos_y_Diagramas.md#f41), [F42](02_Flujos_y_Diagramas.md#f42), [F44](02_Flujos_y_Diagramas.md#f44), [F63](02_Flujos_y_Diagramas.md#f63), [F70](02_Flujos_y_Diagramas.md#f70), [F71](02_Flujos_y_Diagramas.md#f71), [F79](02_Flujos_y_Diagramas.md#f79).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F17_A01` | Solicitar cita | F17 / CE | PAC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F17_A02` | Elegir paciente | F17 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F17_A03` | Ver horarios | F17 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F17_A04` | Enviar solicitud | F17 / CE | PAC, RES | Vínculo de portal vigente y elección completa. | Crea solicitud; su estado inicial no afirma una reserva si requiere revisión. | Mostrar fecha solicitada y política de confirmación. |
| `F17_A05` | Aceptar alternativa | F17 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F42_A05` | Registrar aceptación | F42 / AD | CAJ, PAC, PRO, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F63_A04` | Pagar anticipo | F63 / AD | PAC, RES | Servicio/cita y condiciones de pago revisados. | Inicia pago; acredita únicamente con confirmación verificable del proveedor. | Monto, concepto, condiciones y destinatario del pago. |
| `F70_A03` | Elegir paciente | F70 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F70_A04` | Elegir organización | F70 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F70_A05` | Ver mis citas | F70 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F79_A01` | Cerrar sesión | F79 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s30"></a>
## S30. Citas del portal

**Espacio:** Portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Paciente humano, Representante o responsable.

**Objetivo:** Solicitar cita y gestionar cambios permitidos.

**Información:** Servicio/sede/profesional; Horarios publicables; Estado de solicitud/reserva; Política de cambio y oferta.

**Estructura funcional:** Paso de elección y confirmación; presentar solicitado y confirmado como estados diferentes.

**Flujos relacionados:** [F17](02_Flujos_y_Diagramas.md#f17), [F18](02_Flujos_y_Diagramas.md#f18), [F19](02_Flujos_y_Diagramas.md#f19), [F63](02_Flujos_y_Diagramas.md#f63).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F18_A01` | Confirmar asistencia | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A02` | Reprogramar | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A03` | Cancelar cita | F18 / CE | PAC, PRO, REC, RES | Rol autorizado; cita en estado cancelable. | Cancela reserva y libera recursos aplicables; conserva motivo/historial. | Resumen de cita y condiciones; motivo cuando lo requiera política. |
| `F18_A04` | Guardar cambio | F18 / CE | PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F18_A05` | Conservar cita | F18 / CE | PAC, PRO, REC, RES | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F19_A03` | Aceptar oferta | F19 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F19_A04` | Rechazar oferta | F19 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F19_A05` | Salir de espera | F19 / CE | PAC, REC, RES | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F63_A02` | Continuar reserva | F63 / AD | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F63_A03` | Ver condiciones | F63 / AD | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F63_A04` | Pagar anticipo | F63 / AD | PAC, RES | Servicio/cita y condiciones de pago revisados. | Inicia pago; acredita únicamente con confirmación verificable del proveedor. | Monto, concepto, condiciones y destinatario del pago. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s31"></a>
## S31. Documentos publicados en portal

**Espacio:** Portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Paciente humano, Representante o responsable.

**Objetivo:** Consultar contenido publicado y descargar versiones autorizadas.

**Información:** Documento y fecha; Emisor; Versión/correcciones; Estado de acceso.

**Estructura funcional:** Lista y detalle legibles en móvil; procedencia y versión visibles antes de descarga.

**Flujos relacionados:** [F38](02_Flujos_y_Diagramas.md#f38), [F71](02_Flujos_y_Diagramas.md#f71).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F38_A04` | Registrar decisión | F38 / CE | PAC, PRO, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F71_A01` | Ver documento | F71 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F71_A02` | Ver versión actual | F71 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F71_A03` | Descargar documento | F71 / CE | PAC, RES | Vínculo y publicación autorizados al momento de entrega. | Entrega versión publicada y registra descarga. | Sin confirmación adicional; identificar emisor y versión. |
| `F71_A04` | Ver emisor | F71 / CE | PAC, RES | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s32"></a>
## S32. Vínculos y delegaciones del portal

**Espacio:** Portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Recepción, Administrador de la organización, Paciente humano, Representante o responsable.

**Objetivo:** Gestionar personas/animales autorizados y vigencia de representación.

**Información:** Vínculos verificados; Invitaciones pendientes; Alcance y vigencia; Revocación y evidencia.

**Estructura funcional:** Listado de relaciones; las acciones dependen de facultades comprobadas y contexto interno/externo.

**Flujos relacionados:** [F12](02_Flujos_y_Diagramas.md#f12), [F39](02_Flujos_y_Diagramas.md#f39), [F70](02_Flujos_y_Diagramas.md#f70).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F12_A01` | Editar relación | F12 / CE | REC, ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F12_A04` | Revocar acceso | F12 / CE | REC, ADM | Actor autorizado a gestionar la relación y vínculo identificado. | Retira alcance de la relación correspondiente, sin borrar historia. | Vínculo y acceso afectado; confirmar. |
| `F12_A06` | Solicitar revocación | F12 / CE | PAC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F39_A01` | Invitar al portal | F39 / CE | REC, ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F39_A04` | Aceptar vínculo | F39 / CE | PAC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s33"></a>
## S33. Seguimiento y comunicaciones

**Espacio:** Clínica y portal. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción, Paciente humano, Representante o responsable.

**Objetivo:** Gestionar tareas y mensajes con responsable, estado y plazo.

**Información:** Tareas y responsable; Canal/autorización; Mensajes/respuestas; Próxima actuación.

**Estructura funcional:** Bandeja interna y vista externa diferenciadas; mostrar horarios/tiempos del canal acordado.

**Flujos relacionados:** [F41](02_Flujos_y_Diagramas.md#f41), [F55](02_Flujos_y_Diagramas.md#f55).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F41_A01` | Programar control | F41 / CE | PAC, PRO, REC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F41_A02` | Crear pendiente | F41 / CE | PAC, PRO, REC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F41_A03` | Asignar responsable | F41 / CE | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F41_A04` | Enviar mensaje | F41 / CE | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F41_A05` | Registrar respuesta | F41 / CE | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F41_A06` | Resolver tarea | F41 / CE | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F41_A07` | Enviar respuesta | F41 / CE | PAC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F55_A06` | Programar control | F55 / HO | PAC, PRO, REC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s34"></a>
## S34. Presupuestos y etapas de tratamiento

**Espacio:** Finanzas. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Profesional clínico, Caja y administración financiera, Paciente humano, Representante o responsable.

**Objetivo:** Versionar propuesta comercial y aceptación.

**Información:** Servicios y etapas; Precios/descuentos; Condiciones; Aceptación y versiones.

**Estructura funcional:** Presupuesto detallado con total y condiciones; revisión externa separada del editor interno.

**Flujos relacionados:** [F42](02_Flujos_y_Diagramas.md#f42).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F42_A01` | Crear presupuesto | F42 / AD | CAJ, PAC, PRO, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F42_A02` | Añadir etapa | F42 / AD | CAJ, PAC, PRO, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F42_A03` | Solicitar descuento | F42 / AD | CAJ, PAC, PRO, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F42_A04` | Enviar presupuesto | F42 / AD | CAJ, PAC, PRO, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F42_A05` | Registrar aceptación | F42 / AD | CAJ, PAC, PRO, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F42_A06` | Crear nueva versión | F42 / AD | CAJ, PAC, PRO, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s35"></a>
## S35. Cuenta, pagos y caja

**Espacio:** Finanzas. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Caja y administración financiera.

**Objetivo:** Registrar cargos, pagos, reversos y cierres de caja.

**Información:** Cuenta/pagador; Cargos y saldos; Pagos y asignaciones; Caja y conciliación.

**Estructura funcional:** Cuenta con movimientos; cobro en formulario; caja como ámbito operativo separado.

**Flujos relacionados:** [F43](02_Flujos_y_Diagramas.md#f43), [F44](02_Flujos_y_Diagramas.md#f44), [F77](02_Flujos_y_Diagramas.md#f77).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F43_A01` | Añadir cargo | F43 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F43_A02` | Revisar cargos propuestos | F43 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F43_A03` | Confirmar cargo | F43 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F43_A04` | Ajustar cargo | F43 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F43_A05` | Revertir cargo | F43 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F43_A06` | Ver cuenta | F43 / AD | CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F44_A01` | Abrir caja | F44 / AD | CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F44_A02` | Registrar pago | F44 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F44_A03` | Asignar anticipo | F44 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F44_A04` | Conciliar pago | F44 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F44_A05` | Solicitar devolución | F44 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F44_A06` | Confirmar devolución | F44 / AD | CAJ | Pago original verificado, monto permitido y autorización aplicable. | Registra reverso financiero vinculado; no borra el pago. | Monto, medio, referencia, motivo y actor autorizante. |
| `F44_A07` | Cerrar caja | F44 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F77_A03` | Solicitar autorización | F77 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s36"></a>
## S36. Comprobantes y estados externos

**Espacio:** Finanzas. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Caja y administración financiera.

**Objetivo:** Emitir comprobantes y gestionar respuestas/correcciones.

**Información:** Emisor y numeración; Vista previa; Estado fiscal/evidencia; Errores y correctivos.

**Estructura funcional:** Lista de documentos y detalle de respuesta; acciones condicionadas al estado real del comprobante.

**Flujos relacionados:** [F45](02_Flujos_y_Diagramas.md#f45).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F45_A01` | Preparar comprobante | F45 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F45_A02` | Ver vista previa | F45 / AD | CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F45_A03` | Emitir comprobante | F45 / AD | CAJ | Emisor, cargos, datos y numeración revisados. | Emite un documento y sigue su respuesta externa sin duplicación. | Vista previa fiscal y resumen antes de emitir. |
| `F45_A04` | Consultar estado | F45 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F45_A05` | Gestionar rechazo | F45 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F45_A06` | Crear documento correctivo | F45 / AD | CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s37"></a>
## S37. Honorarios y liquidaciones

**Espacio:** Finanzas. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Caja y administración financiera, Administrador de la organización, Profesional clínico.

**Objetivo:** Revisar base contractual, calcular y pagar liquidación.

**Información:** Acuerdo/vigencia; Periodo y partidas; Ajustes/aprobación; Pago y detalle.

**Estructura funcional:** Resumen y partidas auditables; profesional consulta solo su detalle autorizado.

**Flujos relacionados:** [F46](02_Flujos_y_Diagramas.md#f46).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F46_A01` | Generar propuesta | F46 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F46_A02` | Ver detalle | F46 / AD | ADM, CAJ, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F46_A03` | Registrar ajuste | F46 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F46_A04` | Aprobar liquidación | F46 / AD | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F46_A05` | Registrar pago | F46 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F46_A06` | Entregar detalle | F46 / AD | CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s38"></a>
## S38. Solicitudes y órdenes de compra

**Espacio:** Almacén. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Compras y almacén, Administrador de la organización.

**Objetivo:** Solicitar, aprobar y recibir compras.

**Información:** Necesidad/productos; Proveedor; Aprobación/orden; Recepciones y diferencias.

**Estructura funcional:** Bandeja por etapa y detalle con cantidades solicitadas/ordenadas/recibidas.

**Flujos relacionados:** [F47](02_Flujos_y_Diagramas.md#f47).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F47_A01` | Nueva solicitud | F47 / AD | ADM, ALM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F47_A02` | Aprobar compra | F47 / AD | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F47_A03` | Emitir orden | F47 / AD | ALM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F47_A04` | Registrar recepción | F47 / AD | ALM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F47_A05` | Registrar discrepancia | F47 / AD | ALM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F47_A06` | Ver pendientes | F47 / AD | ADM, ALM | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s39"></a>
## S39. Inventario, lotes y transferencias

**Espacio:** Almacén. **Etapa base:** Operación administrativa posterior o piloto acotado.

**Usuarios de la pantalla:** Compras y almacén, Farmacia, Administrador de la organización.

**Objetivo:** Conocer existencias y registrar movimientos autorizados.

**Información:** Stock por almacén/lote; Vencimientos; Movimientos y referencias; Tránsito y discrepancias.

**Estructura funcional:** Listado y ficha de producto/lote; movimientos con origen, cantidad, destino y motivo.

**Flujos relacionados:** [F36](02_Flujos_y_Diagramas.md#f36), [F48](02_Flujos_y_Diagramas.md#f48).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F48_A01` | Registrar consumo | F48 / AD | ADM, ALM, FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F48_A02` | Transferir stock | F48 / AD | ADM, ALM, FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F48_A03` | Confirmar recepción | F48 / AD | ADM, ALM, FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F48_A04` | Solicitar ajuste | F48 / AD | ADM, ALM, FAR | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F48_A05` | Aprobar ajuste | F48 / AD | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F48_A06` | Registrar reverso | F48 / AD | ADM, ALM, FAR | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s40"></a>
## S40. Admisiones y estancias

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Recepción, Profesional clínico, Asistente o enfermería.

**Objetivo:** Admitir y seguir estado clínico/administrativo de estancia.

**Información:** Solicitud e identidad; Unidad/plaza; Estado de estancia; Alta y egreso.

**Estructura funcional:** Bandeja de ingresos y detalle de estancia con transición y responsables.

**Flujos relacionados:** [F49](02_Flujos_y_Diagramas.md#f49), [F55](02_Flujos_y_Diagramas.md#f55).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F49_A01` | Solicitar ingreso | F49 / HO | ASI, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F49_A04` | Confirmar admisión | F49 / HO | ASI, PRO, REC | Identidad, indicación y plaza compatible confirmadas. | Activa estancia/ocupación con protección de concurrencia. | Paciente, unidad, plaza y equipo receptor. |
| `F49_A06` | Cancelar solicitud | F49 / HO | ASI, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F55_A05` | Confirmar egreso | F55 / HO | REC, ASI | Alta clínica disponible y salida física realmente producida. | Finaliza ocupación y conserva pendientes de seguimiento. | Paciente, salida y destino; no asociar al cierre de caja. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s41"></a>
## S41. Camas, jaulas y ubicación

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Recepción, Asistente o enfermería, Profesional clínico.

**Objetivo:** Asignar recurso compatible y conservar ocupación histórica.

**Información:** Unidad y plazas; Disponible/reservada/ocupada/limpieza; Compatibilidad; Movimientos.

**Estructura funcional:** Vista de recursos con etiquetas y alternativa en tabla; confirmar disponibilidad antes de asignar.

**Flujos relacionados:** [F49](02_Flujos_y_Diagramas.md#f49), [F50](02_Flujos_y_Diagramas.md#f50).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F49_A02` | Ver plazas | F49 / HO | ASI, PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F49_A03` | Reservar plaza | F49 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s42"></a>
## S42. Hoja de estancia y turnos

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Asistente o enfermería, Profesional clínico.

**Objetivo:** Registrar cuidados, órdenes, pendientes y entregas de responsabilidad.

**Información:** Paciente/ubicación; Observaciones y tareas; Órdenes y administraciones; Entrega, traslados y alta.

**Estructura funcional:** Hoja longitudinal/temporal con bandeja de pendientes; entrega requiere receptor.

**Flujos relacionados:** [F37](02_Flujos_y_Diagramas.md#f37), [F49](02_Flujos_y_Diagramas.md#f49), [F50](02_Flujos_y_Diagramas.md#f50), [F55](02_Flujos_y_Diagramas.md#f55).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F49_A05` | Registrar recepción | F49 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F50_A01` | Registrar cuidado | F50 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F50_A02` | Registrar excepción | F50 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F50_A03` | Preparar traslado | F50 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F50_A04` | Preparar entrega de turno | F50 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F50_A05` | Aceptar entrega | F50 / HO | ASI, PRO | Equipo receptor autorizado y pendientes recibidos. | Registra aceptación de responsabilidad y tareas transferidas. | Resumen de paciente, órdenes y pendientes; confirmar recepción. |
| `F50_A06` | Ver pendientes | F50 / HO | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F55_A01` | Preparar alta | F55 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F55_A02` | Asignar pendientes | F55 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F55_A04` | Registrar entrega | F55 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s43"></a>
## S43. Caso quirúrgico

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería, Recepción.

**Objetivo:** Programar y documentar lo previsto y realizado en cirugía.

**Información:** Caso/procedimiento/región; Equipo y sala; Preparación/consentimientos; Parte, implantes y muestras.

**Estructura funcional:** Caso con etapas; planificación separada del registro de ejecución.

**Flujos relacionados:** [F52](02_Flujos_y_Diagramas.md#f52), [F53](02_Flujos_y_Diagramas.md#f53).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F52_A01` | Proponer cirugía | F52 / HO | ASI, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F52_A02` | Ver disponibilidad | F52 / HO | ASI, PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F52_A03` | Ver preparación | F52 / HO | ASI, PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F52_A04` | Programar caso | F52 / HO | ASI, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F52_A05` | Reprogramar caso | F52 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F52_A06` | Cancelar programación | F52 / HO | ASI, PRO, REC | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |
| `F53_A01` | Verificar caso | F53 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F53_A02` | Iniciar procedimiento | F53 / HO | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F53_A03` | Registrar implante | F53 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F53_A04` | Registrar muestra | F53 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F53_A05` | Registrar interrupción | F53 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F53_A06` | Cerrar parte | F53 / HO | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s44"></a>
## S44. Registro anestésico y recuperación

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería.

**Objetivo:** Conservar evaluación, tiempos, eventos y salida de recuperación.

**Información:** Caso y evaluación; Observaciones/administraciones; Eventos; Recuperación/destino.

**Estructura funcional:** Hoja temporal vinculada al caso; mostrar estado de actuación y recuperación por separado.

**Flujos relacionados:** [F54](02_Flujos_y_Diagramas.md#f54).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F54_A01` | Registrar evaluación | F54 / HO | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F54_A02` | Iniciar registro | F54 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F54_A03` | Añadir observación | F54 / HO | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F54_A04` | Registrar administración | F54 / HO | PRO, ASI | Actor competente y asignado; orden vigente, paciente y datos reales verificados. | Registra administración realizada con ejecutor y tiempos; reintento no duplica. | Revisar identidad, orden y datos de la actuación antes de registrar. |
| `F54_A05` | Registrar evento | F54 / HO | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F54_A06` | Confirmar salida de recuperación | F54 / HO | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s45"></a>
## S45. Circuito de urgencias

**Espacio:** Hospital. **Etapa base:** Hospitalización, urgencias y cirugía.

**Usuarios de la pantalla:** Recepción, Asistente o enfermería, Profesional clínico.

**Objetivo:** Registrar llegada, clasificación, atención, reevaluaciones y destino.

**Información:** Identidad provisional/confirmada; Clasificaciones con fecha; Estado de atención; Destino/aceptación.

**Estructura funcional:** Bandeja de urgencias con tiempos y estado textual; acceso inmediato a paciente correcto.

**Flujos relacionados:** [F51](02_Flujos_y_Diagramas.md#f51).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F51_A01` | Registrar urgencia | F51 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F51_A02` | Registrar clasificación | F51 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F51_A03` | Añadir reevaluación | F51 / HO | ASI, PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F51_A04` | Indicar destino | F51 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F51_A05` | Confirmar transferencia | F51 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F51_A06` | Resolver identidad | F51 / HO | ASI, PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s46"></a>
## S46. Cursos y episodios especializados avanzados

**Espacio:** Especialidades avanzadas. **Etapa base:** Capacidades especializadas avanzadas.

**Usuarios de la pantalla:** Profesional clínico, Equipo de diagnóstico, Asistente o enfermería, Recepción.

**Objetivo:** Entrar a flujos específicos de curso, transfusión, trasplante o reproducción.

**Información:** Tipo y alcance del paquete; Plan y etapas; Participantes/recursos/muestras; Resultados y seguimientos.

**Estructura funcional:** Entrada común con subpantallas propias por flujo; no mezclar datos ni estados de procesos diferentes.

**Flujos relacionados:** [F56](02_Flujos_y_Diagramas.md#f56), [F57](02_Flujos_y_Diagramas.md#f57), [F58](02_Flujos_y_Diagramas.md#f58), [F59](02_Flujos_y_Diagramas.md#f59).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F56_A01` | Crear curso | F56 / AV | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F56_A02` | Versionar plan | F56 / AV | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F56_A03` | Programar sesión | F56 / AV | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F56_A04` | Registrar sesión | F56 / AV | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F56_A05` | Registrar interrupción | F56 / AV | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F56_A06` | Cerrar curso | F56 / AV | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F57_A01` | Solicitar componente | F57 / AV | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F57_A02` | Revisar verificaciones | F57 / AV | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F57_A03` | Registrar entrega | F57 / AV | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F57_A04` | Registrar actuación | F57 / AV | PRO, ASI | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F57_A05` | Registrar evento | F57 / AV | ASI, DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F57_A06` | Conciliar unidad | F57 / AV | ASI, DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F58_A01` | Crear episodio especializado | F58 / AV | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F58_A02` | Registrar evaluación | F58 / AV | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F58_A03` | Ver requisitos | F58 / AV | PRO, REC | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F58_A04` | Coordinar etapa | F58 / AV | PRO, REC | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F58_A05` | Registrar actuación | F58 / AV | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F58_A06` | Programar seguimiento | F58 / AV | PRO, REC | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F59_A01` | Crear ciclo | F59 / AV | PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F59_A02` | Vincular participantes | F59 / AV | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F59_A03` | Registrar custodia | F59 / AV | DIA | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F59_A04` | Revisar etapa | F59 / AV | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F59_A05` | Registrar actuación | F59 / AV | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F59_A06` | Suspender ciclo | F59 / AV | DIA, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s47"></a>
## S47. Salud poblacional veterinaria

**Espacio:** Veterinaria avanzada. **Etapa base:** Capacidades especializadas avanzadas.

**Usuarios de la pantalla:** Profesional clínico, Asistente o enfermería.

**Objetivo:** Registrar programas, intervenciones y resultados colectivos.

**Información:** Población/periodo; Denominador y método; Actuaciones/muestras; Informe y pendientes.

**Estructura funcional:** Programa y eventos grupales con referencias a individuos; tabla y tendencia cuando corresponda.

**Flujos relacionados:** [F14](02_Flujos_y_Diagramas.md#f14), [F60](02_Flujos_y_Diagramas.md#f60).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F60_A01` | Crear intervención | F60 / AV | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F60_A02` | Seleccionar población | F60 / AV | ASI, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F60_A03` | Registrar denominador | F60 / AV | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F60_A04` | Registrar actuación grupal | F60 / AV | ASI, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F60_A05` | Emitir informe poblacional | F60 / AV | PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F60_A06` | Crear seguimiento | F60 / AV | ASI, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s48"></a>
## S48. Importaciones y exportaciones

**Espacio:** Administración. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Operador o soporte de MAVRIC.

**Objetivo:** Procesar lotes con alcance, errores y reconciliación.

**Información:** Operación/formato; Vista previa; Rechazos y totales; Manifiesto/entrega.

**Estructura funcional:** Asistente de lote y historial de ejecuciones; confirmación solo después de vista previa.

**Flujos relacionados:** [F64](02_Flujos_y_Diagramas.md#f64), [F68](02_Flujos_y_Diagramas.md#f68).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F64_A01` | Nueva importación | F64 / TR | ADM, SOP | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F64_A02` | Seleccionar formato | F64 / TR | ADM, SOP | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F64_A03` | Ver vista previa | F64 / TR | ADM, SOP | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F64_A04` | Confirmar lote | F64 / TR | ADM | Vista previa de importación reconciliada y permiso vigente. | Procesa lote identificado y reporta totales/rechazos sin duplicar reimportaciones. | Origen, totales, rechazo e impacto; confirmar. |
| `F64_A05` | Solicitar exportación | F64 / TR | ADM | Permiso y finalidad de exportación; alcance revisado. | Crea una exportación privada con manifiesto y entrega autorizada. | Ámbito, contenido y destinatario; confirmar solicitud. |
| `F64_A06` | Descargar manifiesto | F64 / TR | ADM, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s49"></a>
## S49. Reportes autorizados

**Espacio:** Administración. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Caja y administración financiera, Profesional clínico, Auditor autorizado.

**Objetivo:** Consultar indicadores con definiciones y alcance.

**Información:** Tipo de reporte; Filtros; Definición de medidas; Resultados y permiso de exportación.

**Estructura funcional:** Filtros y resultado en tabla/gráfico según finalidad; mostrar periodo y procedencia.

**Flujos relacionados:** [F65](02_Flujos_y_Diagramas.md#f65).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F65_A01` | Ver reporte | F65 / TR | ADM, AUD, CAJ, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F65_A02` | Aplicar filtros | F65 / TR | ADM, AUD, CAJ, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F65_A03` | Ver definición | F65 / TR | ADM, AUD, CAJ, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F65_A05` | Exportar autorizado | F65 / TR | ADM, AUD, CAJ, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s50"></a>
## S50. Auditoría y evidencia

**Espacio:** Administración. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Auditor autorizado, Administrador de la organización.

**Objetivo:** Inspeccionar accesos, cambios y autorizaciones.

**Información:** Actor/acción/recurso; Contexto y fecha; Versiones relacionadas; Finalidad y exportación autorizada.

**Estructura funcional:** Eventos filtrables y detalle de evidencia; lectura sin acciones de modificación clínica.

**Flujos relacionados:** [F07](02_Flujos_y_Diagramas.md#f07), [F65](02_Flujos_y_Diagramas.md#f65).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F65_A04` | Inspeccionar evento | F65 / TR | ADM, AUD | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F65_A05` | Exportar autorizado | F65 / TR | ADM, AUD, CAJ, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s51"></a>
## S51. Plan, consumo y soporte del cliente

**Espacio:** SaaS. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Profesional clínico, Caja y administración financiera.

**Objetivo:** Gestionar contratación, ayuda y salida de la plataforma.

**Información:** Plan y derechos reales; Consumo/estado comercial; Casos de soporte; Entrega/baja autorizada.

**Estructura funcional:** Secciones de contratación y ayuda separadas; acceso de profesionales limitado a sus casos permitidos.

**Flujos relacionados:** [F62](02_Flujos_y_Diagramas.md#f62), [F66](02_Flujos_y_Diagramas.md#f66), [F67](02_Flujos_y_Diagramas.md#f67), [F68](02_Flujos_y_Diagramas.md#f68).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F66_A01` | Crear caso | F66 / TR | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F66_A02` | Añadir evidencia | F66 / TR | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F66_A03` | Autorizar acceso temporal | F66 / TR | ADM | Responsable con facultad; caso, alcance y duración revisados. | Concede acceso limitado a soporte, auditable y revocable. | Finalidad, datos, actor y vencimiento; confirmar. |
| `F66_A04` | Rechazar acceso | F66 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F66_A05` | Ver actividad | F66 / TR | ADM, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F66_A06` | Cerrar caso | F66 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F67_A01` | Ver plan | F67 / TR | ADM, CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F67_A02` | Ver consumo | F67 / TR | ADM, CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F67_A03` | Solicitar cambio | F67 / TR | ADM, CAJ | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F67_A04` | Revisar condiciones | F67 / TR | ADM, CAJ | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F67_A05` | Confirmar contratación | F67 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F67_A06` | Ver estado de pago | F67 / TR | ADM, CAJ | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F68_A01` | Solicitar baja | F68 / TR | ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F68_A02` | Ver impacto | F68 / TR | ADM | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F68_A03` | Preparar entrega | F68 / TR | ADM | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F68_A04` | Confirmar recepción | F68 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F68_A05` | Confirmar cierre | F68 / TR | ADM | Baja autorizada y entrega/política revisadas. | Cierra servicio conforme al acuerdo; no elimina datos sin política aplicable. | Resumen de recepción de datos, accesos y conservación. |
| `F68_A06` | Cancelar solicitud | F68 / TR | ADM | Existe operación/vista correspondiente; estado permite salida o cancelación. | Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido. | Confirmar si hay cambios locales sin guardar o impacto persistido. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s52"></a>
## S52. Operación de plataforma MAVRIC

**Espacio:** SaaS. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Operador o soporte de MAVRIC.

**Objetivo:** Gestionar soporte, accesos temporales e incidentes sin acceso clínico implícito.

**Información:** Clientes y estado técnico; Casos y autorizaciones; Incidentes/recuperación; Evidencia de acciones.

**Estructura funcional:** Consola operativa separada del espacio clínico; ninguna vista global de historias por defecto.

**Flujos relacionados:** [F66](02_Flujos_y_Diagramas.md#f66), [F67](02_Flujos_y_Diagramas.md#f67), [F68](02_Flujos_y_Diagramas.md#f68), [F69](02_Flujos_y_Diagramas.md#f69), [F78](02_Flujos_y_Diagramas.md#f78), [F79](02_Flujos_y_Diagramas.md#f79).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F69_A01` | Registrar incidente | F69 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F69_A02` | Ver impacto | F69 / TR | SOP | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F69_A03` | Registrar recuperación | F69 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F69_A04` | Adjuntar evidencia | F69 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F69_A05` | Confirmar retorno | F69 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F69_A06` | Crear acción pendiente | F69 / TR | SOP | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F78_A03` | Abrir caso operativo | F78 / TR | SOP | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F79_A01` | Cerrar sesión | F79 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s53"></a>
## S53. Cuenta y preferencias de comunicación

**Espacio:** Cuenta. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Profesional clínico, Recepción, Administrador de la organización, Paciente humano, Representante o responsable.

**Objetivo:** Gestionar canales y preferencias verificadas de la cuenta.

**Información:** Identidad de cuenta; Canales verificados; Preferencias/consentimientos; Sesiones y recuperación.

**Estructura funcional:** Configuración de cuenta diferenciada de filiación clínica; cambios de canal exigen verificación.

**Flujos relacionados:** [F03](02_Flujos_y_Diagramas.md#f03), [F74](02_Flujos_y_Diagramas.md#f74), [F79](02_Flujos_y_Diagramas.md#f79).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F74_A01` | Editar cuenta | F74 / CE | ADM, PAC, PRO, REC, RES | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F74_A02` | Cambiar canal | F74 / CE | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F74_A03` | Verificar nuevo canal | F74 / CE | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F74_A04` | Guardar preferencias | F74 / CE | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F74_A05` | Revisar sesiones | F74 / CE | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F79_A01` | Cerrar sesión | F79 / TR | ADM, ALM, ASI, AUD, CAJ, DIA, FAR, PAC, PRO, REC, RES, SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F79_A02` | Guardar y salir | F79 / TR | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F79_A03` | Descartar cambios locales y salir | F79 / TR | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F79_A04` | Seguir trabajando | F79 / TR | ADM, PAC, PRO, REC, RES | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s54"></a>
## S54. Integraciones y tareas externas

**Espacio:** Configuración. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Administrador de la organización, Profesional clínico.

**Objetivo:** Conectar proveedores y resolver estados externos con alcance explícito.

**Información:** Proveedor y permisos; Cuenta/contexto vinculado; Estado y prueba; Tareas/reintentos/conciliación.

**Estructura funcional:** Tarjetas o listado de conexiones y detalle de tareas; autorización vinculada al actor correcto.

**Flujos relacionados:** [F61](02_Flujos_y_Diagramas.md#f61), [F62](02_Flujos_y_Diagramas.md#f62), [F63](02_Flujos_y_Diagramas.md#f63), [F73](02_Flujos_y_Diagramas.md#f73).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F62_A01` | Ver integración | F62 / TR | ADM | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F62_A02` | Ver tarea fallida | F62 / TR | ADM | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F62_A03` | Reintentar operación | F62 / TR | ADM | Operación fallida reintentable y permiso sobre integración. | Reintenta la misma operación identificada sin duplicar efecto. | Mostrar operación y resultado previo. |
| `F62_A04` | Resolver discrepancia | F62 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F62_A05` | Desconectar integración | F62 / TR | ADM | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F73_A01` | Conectar proveedor | F73 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F73_A02` | Revisar permisos | F73 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F73_A03` | Probar conexión | F73 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F73_A04` | Activar integración | F73 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F73_A05` | Revocar conexión | F73 / TR | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s55"></a>
## S55. Disponibilidad, lugares y recursos

**Espacio:** Configuración. **Etapa base:** Consulta externa y portal.

**Usuarios de la pantalla:** Administrador de la organización, Profesional clínico.

**Objetivo:** Configurar jornadas y recursos sin alterar reservas silenciosamente.

**Información:** Profesional/lugar; Horarios y excepciones; Recursos y duración; Impacto en citas existentes.

**Estructura funcional:** Editor horario con resumen de excepciones y vista de impacto antes de publicación.

**Flujos relacionados:** [F05](02_Flujos_y_Diagramas.md#f05), [F09](02_Flujos_y_Diagramas.md#f09).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F09_A01` | Añadir horario | F09 / CE | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F09_A02` | Bloquear intervalo | F09 / CE | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F09_A03` | Añadir recurso | F09 / CE | ADM, PRO | Rol y contexto permitidos; objeto en estado que admite la acción. | Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido. | Según impacto; no confirmar solo apertura de formulario. |
| `F09_A04` | Ver impacto | F09 / CE | ADM, PRO | Recurso visible en el contexto y alcance autorizado. | Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola. | Sin diálogo; conservar contexto y filtros. |
| `F09_A05` | Publicar disponibilidad | F09 / CE | ADM, PRO | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

<a id="s56"></a>
## S56. Acceso de operador MAVRIC

**Espacio:** SaaS. **Etapa base:** Transversal; profundidad según release.

**Usuarios de la pantalla:** Operador o soporte de MAVRIC.

**Objetivo:** Autenticar al operador de plataforma sin conceder acceso clínico de clientes.

**Información:** Cuenta de operador; Comprobaciones definidas por política; Estado de acceso; Ayuda de cuenta.

**Estructura funcional:** Acceso específico a consola operativa; el destino no es un expediente global.

**Flujos relacionados:** [F78](02_Flujos_y_Diagramas.md#f78).

| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |
| --- | --- | --- | --- | --- | --- | --- |
| `F78_A01` | Ingresar a consola | F78 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |
| `F78_A02` | Completar comprobación | F78 / TR | SOP | Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación. | Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado. | Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos. |

**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.

## Wireframes funcionales de referencia

Estos esquemas definen jerarquía; no son pantallas implementadas ni diseño visual final.

### Atención clínica

```text
[Organización] [Sucursal/lugar] [Rol]                         [Mi cuenta]
[Paciente/animal confirmado] [Identificador] [Atención y estado]
----------------------------------------------------------------------
Resumen autorizado | Secciones de atención | Pendientes de esta atención
Antecedentes        | Formulario/gráfico    | Órdenes y resultados
Problemas/alergias   | Leyenda + tabla       | Receta y documentos
Historia/episodio    | Validaciones          | Seguimiento
----------------------------------------------------------------------
[Guardar borrador] [Revisar contenido] [Finalizar visita]
Firma por revisión documental: acción separada, con resumen previo.
```

### Agenda y recepción

```text
[Organización/sucursal] [Día/semana] [Profesional/recurso]
[Calendario o lista]             [Detalle: paciente + intervalo]
[Nueva cita]                     [Reservar / Reprogramar / Cancelar]
Recepción: [Esperados] [Llegaron] [En espera] [En atención] [Retiro]
Cada ingreso conserva su vínculo con cita y atención, si existen.
```

### Portal

```text
[Organización] [Paciente o animal autorizado]              [Mi cuenta]
[Inicio] [Citas] [Documentos] [Seguimiento] [Vínculos]
Próxima cita: estado real                 [Solicitar / Gestionar cita]
Documentos publicados: emisor + versión   [Ver / Descargar autorizado]
Pendientes de seguimiento: responsable/canal y próxima actuación
```

## Validación del diseño antes de desarrollo

1. Recorrer cada flujo con su actor principal y sus alternativas.
2. Verificar que cada paso humano tiene pantalla/acción o interacción externa documentada.
3. Comprobar estados, mensajes, permisos finos y responsabilidades en cada transición.
4. Revisar cada gráfico con profesionales de su área y contrastarlo con datos guardados.
5. Probar wireframes con paciente humano, animal/responsable y profesional itinerante.
6. Resolver decisiones pendientes y versionar el diseño aceptado antes de construir frontend/backend.
