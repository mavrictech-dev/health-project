# Matriz de pantallas y acciones del frontend

**Plan propuesto; ninguna acción marcada como implementada o verificada.**

Se conservan 79 flujos, 56 pantallas y 429 acciones contextuales del diseño. Los 32 controles comunes están separados. Rutas, componentes, contratos, resultados y criterios ampliados se encuentran en [Plan_Frontend.json](Plan_Frontend.json).

Los IDs de query son ilustrativos y serán valores del store. Varias pantallas pueden compartir una ruta; una ruta compartida no elimina su alcance o contrato. S03 es un panel global. Las superficies de portal filtran por vínculo y no dan acceso interno a caja, expedientes o equipo.

## Pantallas y componentes

| ID | Pantalla | Ruta o superficie | Feature | Lote | Componentes shadcn |
|---|---|---|---|---|---|
| S01 | Acceso profesional | /acceso | identity | D02 | Field, Input, Button, Alert |
| S02 | Acceso e invitación del portal | /portal/acceso | portal-access | D02 | Field, Input, Input OTP, Button |
| S03 | Selector de organización y sucursal | panel global: contexto | context | D02 | Sheet, Combobox, Radio Group, Badge |
| S04 | Recuperación y aceptación de invitación | /recuperar<br>/invitacion | identity | D02 | Field, Input, Input OTP, Button, Alert |
| S05 | Alta y configuración de organización | /app/configuracion/organizacion | organizations | D02 | Tabs, Table, Sheet, Field |
| S06 | Equipo, credenciales y permisos | /app/configuracion/equipo | memberships | D02 | Table, Badge, Sheet, Checkbox |
| S07 | Servicios, precios y emisores | /app/configuracion/servicios | services-pricing | D06 | Tabs, Table, Sheet, Date Picker |
| S08 | Catálogo, plantillas y paquetes de especialidad | /app/configuracion/especialidades | specialty-configuration | D04 | Combobox, Table, Tabs, Sheet |
| S09 | Directorio de pacientes de la organización | /app/pacientes | patients | D03 | Input, Table, Dropdown Menu, Sheet |
| S10 | Ficha administrativa humana | /app/pacientes?paciente=id&tab=ficha&dominio=humano | patients-human | D03 | Tabs, Field, Sheet, Badge |
| S11 | Ficha del animal y responsables | /app/pacientes?paciente=id&tab=ficha&dominio=animal | patients-animal | D03 | Tabs, Combobox, Sheet, Table |
| S12 | Revisión de identidad y duplicados | /app/pacientes/duplicados | patient-identity | D03 | Table, Sheet, Radio Group, Alert |
| S13 | Población animal y membresías | /app/veterinaria/poblaciones | animal-populations | D08 | Table, Sheet, Date Picker, Tabs |
| S14 | Agenda operativa | /app/agenda | scheduling | D03 | Calendar, Toggle Group, Popover, Sheet |
| S15 | Solicitudes y lista de espera | /app/agenda/solicitudes | booking-requests | D03 | Tabs, Table, Badge, Sheet |
| S16 | Recepción y cola | /app/recepcion | reception-queue | D03 | Table, Badge, Button, Sheet |
| S17 | Inicio profesional y bandeja clínica | /app/inicio | clinical-inbox | D04 | Tabs, Table, Card, Badge |
| S18 | Espacio de atención clínica | /app/atencion?atencion=id | encounters | D04 | Tabs, Accordion, Sheet, Field |
| S19 | Expediente y evolución compartida | /app/pacientes?paciente=id&tab=historia | longitudinal-record | D04 | Tabs, Date Picker, Table, Sheet |
| S20 | Órdenes y resultados pendientes | /app/ordenes | orders-followup | D04 | Tabs, Table, Badge, Sheet |
| S21 | Lista de trabajo diagnóstico | /app/diagnostico/trabajo | diagnostic-work | D07 | Table, Combobox, Badge, Sheet |
| S22 | Muestras y trazabilidad | /app/diagnostico/muestras | specimens | D07 | Table, Badge, Sheet, Field |
| S23 | Resultados e informe de laboratorio | /app/diagnostico/laboratorio | laboratory | D07 | Table, Field, Sheet, Tabs |
| S24 | Estudios, imágenes y visor autorizado | /app/diagnostico/imagenes | imaging | D07 | Tabs, Resizable, Sheet, Table |
| S25 | Medicación y receta | /app/atencion?atencion=id&tab=medicacion | prescriptions | D04 | Table, Combobox, Sheet, Field |
| S26 | Farmacia y dispensación | /app/farmacia | dispensing | D07 | Table, Combobox, Sheet, Badge |
| S27 | Administración de medicación | /app/hospital/medicacion | medication-administration | D07 | Table, Sheet, Field, Badge |
| S28 | Documentos, firma y consentimientos | /app/documentos | documents-consents | D04 | Table, Tabs, Sheet, Alert |
| S29 | Inicio del portal | /portal/inicio | portal-dashboard | D05 | Card, Item, Badge, Button |
| S30 | Citas del portal | /portal/citas | portal-booking | D05 | Calendar, Table, Sheet, Badge |
| S31 | Documentos publicados en portal | /portal/documentos | portal-publications | D05 | Table, Sheet, Badge, Button |
| S32 | Vínculos y delegaciones del portal | /portal/vinculos<br>/app/pacientes?paciente=id&tab=vinculos | portal-relationships | D05 | Table, Sheet, Checkbox, Date Picker |
| S33 | Seguimiento y comunicaciones | /app/seguimiento<br>/portal/seguimiento | followup-messages | D05 | Tabs, Table, Textarea, Sheet |
| S34 | Presupuestos y etapas de tratamiento | /app/finanzas/presupuestos<br>/portal/pagos?tab=presupuestos | estimates | D06 | Table, Sheet, Tabs, Field |
| S35 | Cuenta, pagos y caja | /app/finanzas/caja<br>/portal/pagos | cash-payments | D06 | Tabs, Table, Sheet, Field |
| S36 | Comprobantes y estados externos | /app/finanzas/comprobantes | fiscal-documents-demo | D06 | Table, Badge, Sheet, Alert |
| S37 | Honorarios y liquidaciones | /app/finanzas/honorarios | professional-settlements | D06 | Table, Date Picker, Sheet, Badge |
| S38 | Solicitudes y órdenes de compra | /app/compras | purchasing | D06 | Tabs, Table, Sheet, Field |
| S39 | Inventario, lotes y transferencias | /app/inventario | inventory | D06 | Table, Combobox, Sheet, Badge |
| S40 | Admisiones y estancias | /app/hospital/admisiones | admissions | D08 | Table, Sheet, Combobox, Badge |
| S41 | Camas, jaulas y ubicación | /app/hospital/recursos | occupancy | D08 | Toggle Group, Card, Table, Sheet |
| S42 | Hoja de estancia y turnos | /app/hospital/estancias | inpatient-care | D08 | Tabs, Table, Sheet, Chart |
| S43 | Caso quirúrgico | /app/cirugia | surgery | D08 | Tabs, Table, Sheet, Checkbox |
| S44 | Registro anestésico y recuperación | /app/anestesia | anesthesia | D08 | Tabs, Chart, Table, Sheet |
| S45 | Circuito de urgencias | /app/urgencias | emergency | D08 | Table, Sheet, Badge, Field |
| S46 | Cursos y episodios especializados avanzados | /app/especialidades?proceso=sesiones<br>/app/especialidades?proceso=transfusion<br>/app/especialidades?proceso=trasplante<br>/app/especialidades?proceso=reproduccion | advanced-episodes | D08 | Tabs, Table, Sheet, Progress |
| S47 | Salud poblacional veterinaria | /app/veterinaria/programas | veterinary-population-health | D08 | Table, Sheet, Chart, Field |
| S48 | Importaciones y exportaciones | /app/configuracion/datos | import-export | D09 | Table, Progress, Sheet, Alert |
| S49 | Reportes autorizados | /app/reportes | reports | D09 | Chart, Table, Date Picker, Sheet |
| S50 | Auditoría y evidencia | /app/auditoria | demo-audit | D09 | Table, Combobox, Date Picker, Sheet |
| S51 | Plan, consumo y soporte del cliente | /app/plataforma | subscription-support | D09 | Tabs, Table, Sheet, Progress |
| S52 | Operación de plataforma MAVRIC | /operacion/inicio | platform-operations | D09 | Tabs, Table, Sheet, Badge |
| S53 | Cuenta y preferencias de comunicación | /app/cuenta<br>/portal/cuenta<br>/operacion/cuenta | account | D02 | Tabs, Field, Switch, Sheet |
| S54 | Integraciones y tareas externas | /app/configuracion/integraciones | integration-jobs | D09 | Tabs, Table, Sheet, Badge |
| S55 | Disponibilidad, lugares y recursos | /app/configuracion/agenda | availability-resources | D03 | Calendar, Table, Sheet, Field |
| S56 | Acceso de operador MAVRIC | /operacion/acceso | operations-access | D02 | Field, Input, Input OTP, Button |

## Patrones de interacción

| Código | Patrón | Comportamiento |
|---|---|---|
| A | Acceso ficticio · AUTH_DEMO | validar identidad ficticia y activar sesión de demo |
| N | Ruta o pestaña con contexto · NAV_ROUTE | abrir destino y conservar contexto y filtros de origen |
| I | Filtro en la pantalla · FILTER_INLINE | cambiar consulta y resultados visibles sin escritura de negocio |
| S | Selección o cambio de vista · SELECT_CONTROL | seleccionar un valor compatible o una vista sin confirmación persistida implícita |
| G | Gráfico y selección semántica · GRAPH_CONTROL | seleccionar estructura o vista y mostrar su equivalencia textual |
| F | Captura en panel derecho · FORM_SHEET_RIGHT | abrir captura; guardar aplica la operación descrita cuando no sea solo borrador de otra acción |
| W | Pasos en un panel derecho · WIZARD_SHEET_RIGHT | avanzar entre pasos conservando captura y confirmar al final cuando corresponda |
| V | Detalle o comparación en panel derecho · DETAIL_SHEET_RIGHT | mostrar evidencia, detalle o comparación sin alterar los registros consultados |
| R | Revisión y confirmación en panel derecho · REVIEW_SHEET_RIGHT | presentar alcance e impacto; aplicar el comando únicamente al confirmar |
| C | Comando en el contexto activo · COMMAND_STATE | validar y cambiar estado o guardar captura; si falta formulario, abrir el pertinente |
| J | Trabajo o envío simulado · MOCK_JOB | crear o avanzar trabajo ficticio identificado y mostrar su resultado o error |
| L | Volver o conservar contexto · CLOSE_OR_RETURN | volver o cerrar; revisar borrador cuando exista antes de abandonar |
| B | Deshacer cambios locales · UNDO_LOCAL | revertir solo estado local pendiente y actualizar representación |
| X | Descarga local · EXPORT_LOCAL | generar o descargar archivo ficticio local con contexto y nombre reconocible |
| P | Impresión local · PRINT_CLIENT | abrir vista de impresión de material ficticio con identidad y versión |

F/W abren captura o pasos. La confirmación explícita aplica el comando del flujo; si el resultado dice que prepara un borrador, el cambio definitivo pertenece a la acción de confirmación correspondiente. R muestra revisión lateral y aplica la operación al confirmar. V solo consulta. C guarda o cambia estado desde el contexto activo. Ninguna operación se considera completa por mostrar un toast.

## Acciones por flujo

### F01 · Ingresar al espacio profesional

**Lote:** D02 · **Estado mock:** `identity-session` · **Contrato:** `F01_INPUT`.

**Campos del flujo:** personaDemo, membresia, sucursal. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Identidad ficticia activa; membresía vigente; elegir solo sucursales del espacio.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F01_A01 | Ingresar | S01 | A | identity.login | Inicia sesión con una persona ficticia y muestra sus espacios permitidos. |
| F01_A02 | Elegir espacio | S03 | S | identity.selectWorkspace | Selecciona una membresía de demo válida y muestra sus sucursales. |
| F01_A03 | Continuar | S03 | C | identity.enterWorkspace | Activa contexto y abre el inicio correspondiente al rol elegido. |

**Salida del proceso:** Sesión activa en contexto explícito; no se inicia una atención.

### F02 · Cambiar organización o sucursal

**Lote:** D02 · **Estado mock:** `workspace-context` · **Contrato:** `F02_INPUT`.

**Campos del flujo:** organizacion, sucursal, borrador, decisionSalida. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Resolver captura pendiente; no cambiar de custodio el encuentro ya creado.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F02_A01 | Cambiar espacio | S03 | F | context.chooseWorkspace | Abre selección de organización y resuelve antes los borradores abiertos. |
| F02_A02 | Cambiar sucursal | S03 | F | context.chooseBranch | Abre selección de sucursal dentro de la organización activa. |
| F02_A03 | Guardar y cambiar | S03 | R | context.saveAndSwitch | Guarda borrador válido, cambia contexto y vuelve a consultar vistas del destino. |
| F02_A04 | Descartar cambios locales | S03 | R | context.discardDraft | Descarta solo cambios locales tras revisión; conserva registros ya guardados. |
| F02_A05 | Seguir aquí | S03 | L | context.keepCurrent | Cierra la revisión de cambio y conserva contexto y captura actuales. |

**Salida del proceso:** Nuevo contexto seleccionado; no se copian pacientes ni historias.

### F03 · Recuperar acceso

**Lote:** D02 · **Estado mock:** `access-recovery` · **Contrato:** `F03_INPUT`.

**Campos del flujo:** cuentaFicticia, codigoDemo, paso. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No almacenar credenciales reales; código preparado y vigencia simulada.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F03_A01 | Recuperar acceso | S01, S02 | N | identity.openRecovery | Abre la ruta de recuperación con cuenta ficticia de ejemplo. |
| F03_A02 | Enviar enlace | S01 | J | identity.requestRecovery | Crea un trabajo simulado y muestra un enlace o código de recuperación de demo. |
| F03_A03 | Guardar nueva contraseña | S01 | C | identity.completeRecovery | Actualiza el estado de recuperación demo sin almacenar una contraseña real. |
| F03_A04 | Volver al acceso | S01 | N | identity.returnToLogin | Vuelve al acceso de origen preservando la elección profesional o portal. |

**Salida del proceso:** Acceso recuperado; el usuario vuelve al login.

### F04 · Reanudar trabajo tras expiración o fallo de guardado

**Lote:** D02 · **Estado mock:** `draft-resolution` · **Contrato:** `F04_INPUT`.

**Campos del flujo:** borrador, revisionBase, revisionRemota, camposResueltos. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No sobrescribir revisión diferente sin comparación explícita.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F04_A01 | Volver a ingresar | S01 | A | identity.resumeLogin | Reanuda identidad ficticia manteniendo un borrador local separado. |
| F04_A02 | Reintentar | S01 | J | drafts.retrySave | Reintenta el mismo guardado simulado sin duplicar la revisión. |
| F04_A03 | Comparar versiones | S01 | V | drafts.compareRevisions | Muestra versión base, local y remota ficticia y sus diferencias. |
| F04_A04 | Guardar revisión resuelta | S01 | R | drafts.saveResolution | Confirma la combinación elegida y crea una revisión resuelta explícita. |
| F04_A05 | Salir | S01 | L | drafts.leaveEditor | Revisa salida con captura pendiente y vuelve a una ruta segura. |

**Salida del proceso:** Trabajo reanudado sobre una revisión confirmada o detenido con motivo.

### F05 · Dar de alta y configurar una organización

**Lote:** D02 · **Estado mock:** `organizations` · **Contrato:** `F05_INPUT`.

**Campos del flujo:** nombre, tipo, identificadorFicticio, sucursales, zonaHoraria. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Campos de configuración esenciales; ID único; zona de sucursal válida.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F05_A01 | Crear organización | S05 | W | organization.beginSetup | Abre alta guiada de organización ficticia con datos y pasos esenciales. |
| F05_A02 | Guardar y continuar | S05 | C | organization.saveSetupStep | Guarda el paso válido del alta y avanza conservando el resumen. |
| F05_A03 | Añadir sucursal | S05 | F | organization.addBranch | Añade sucursal con zona horaria y datos de atención al espacio de demo. |
| F05_A04 | Invitar equipo | S06 | F | membership.inviteTeam | Captura integrantes y crea invitaciones simuladas visibles en el equipo. |
| F05_A05 | Activar espacio | S05 | R | organization.activate | Activa organización configurada y habilita su contexto en los selectores. |

**Salida del proceso:** Espacio configurado para iniciar recorridos habilitados.

### F06 · Invitar y asignar a un profesional

**Lote:** D02 · **Estado mock:** `memberships` · **Contrato:** `F06_INPUT`.

**Campos del flujo:** personaFicticia, rol, sucursales, credencialesDemo, alcance. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Invitación y membresía únicas; revisión explícita de alcance.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F06_A01 | Invitar profesional | S06 | F | membership.inviteProfessional | Crea invitación demo con rol, sucursales y alcance propuestos. |
| F06_A02 | Aceptar invitación | S04 | R | membership.acceptInvitation | Vincula la identidad ficticia invitada y registra aceptación. |
| F06_A03 | Revisar credenciales | S06 | V | membership.reviewCredentials | Muestra credenciales ficticias y estado de revisión del integrante. |
| F06_A04 | Activar membresía | S06 | R | membership.activate | Activa membresía según revisión y recalcula sus acciones disponibles. |
| F06_A05 | Reenviar invitación | S06 | J | membership.resendInvitation | Crea un intento de envío simulado para la misma invitación, sin otra membresía. |

**Salida del proceso:** Una identidad tiene una nueva membresía, sin duplicar sus otras cuentas.

### F07 · Cambiar permisos o revocar membresía

**Lote:** D02 · **Estado mock:** `permission-assignments` · **Contrato:** `F07_INPUT`.

**Campos del flujo:** membresia, accionesPermitidas, sucursales, suplente, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Administrador demo con alcance; suplente vigente; conservar autoría anterior.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F07_A01 | Editar permisos | S06 | F | permissions.editDraft | Abre edición de alcance y permisos de la membresía seleccionada. |
| F07_A02 | Ver impacto | S06 | V | permissions.previewImpact | Muestra vistas, sucursales y tareas afectadas por el cambio propuesto. |
| F07_A03 | Guardar cambios | S06 | R | permissions.commit | Aplica los permisos demo revisados y actualiza la disponibilidad por acción. |
| F07_A04 | Revocar membresía | S06 | R | membership.revoke | Revoca acceso futuro conservando autoría y muestra pendientes a reasignar. |
| F07_A05 | Asignar suplente | S06 | F | membership.assignSubstitute | Reasigna pendientes elegidos a un miembro vigente del mismo espacio. |

**Salida del proceso:** Permisos actualizados y auditados; los registros clínicos conservan autoría.

### F08 · Diseñar, publicar y habilitar una plantilla de especialidad

**Lote:** D04 · **Estado mock:** `specialty-templates` · **Contrato:** `F08_INPUT`.

**Campos del flujo:** perfil, version, campos, atlas, paquete, alcance. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Versión publicada inmutable; capturas anteriores conservan su esquema.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F08_A01 | Nueva versión | S08 | F | templates.createRevision | Crea borrador de una versión con campos, perfil y atlas referenciados. |
| F08_A02 | Vista de ejemplo | S08 | V | templates.preview | Muestra formulario y gráficos con respuestas ficticias de ejemplo. |
| F08_A03 | Enviar a revisión | S08 | R | templates.submitReview | Pasa el borrador a revisión demo con responsable y evidencia preparada. |
| F08_A04 | Publicar versión | S08 | R | templates.publishRevision | Publica versión inmutable para nuevas capturas sin cambiar visitas anteriores. |
| F08_A05 | Habilitar paquete | S08 | R | templates.enablePackage | Habilita el paquete revisado para especialidades y sucursales indicadas. |
| F08_A06 | Retirar versión | S08 | R | templates.retireRevision | Retira una versión de nuevas capturas y conserva su lectura histórica. |

**Salida del proceso:** Paquete utilizable solo dentro de su alcance validado; historia anterior sin reinterpretación.

### F09 · Definir disponibilidad y recursos de agenda

**Lote:** D03 · **Estado mock:** `availability` · **Contrato:** `F09_INPUT`.

**Campos del flujo:** profesional, recurso, sucursal, inicio, fin, zonaHoraria. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Intervalo válido; bloqueos y citas revisados; capacidad y conflictos.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F09_A01 | Añadir horario | S55 | F | availability.addSchedule | Añade horario de profesional con sucursal, lugar y zona horaria. |
| F09_A02 | Bloquear intervalo | S55 | F | availability.blockInterval | Registra bloqueo y muestra las reservas afectadas antes de confirmarlo. |
| F09_A03 | Añadir recurso | S55 | F | availability.addResource | Añade consultorio o recurso con capacidad y dominio apropiado. |
| F09_A04 | Ver impacto | S55 | V | availability.previewImpact | Presenta citas, recursos y conflictos de los cambios pendientes. |
| F09_A05 | Publicar disponibilidad | S55 | R | availability.publish | Publica disponibilidad ficticia y actualiza horarios ofrecidos en agenda y portal. |

**Salida del proceso:** Agenda disponible con reservas existentes conservadas o reprogramadas explícitamente.

### F10 · Registrar un paciente humano

**Lote:** D03 · **Estado mock:** `human-patients` · **Contrato:** `F10_INPUT`.

**Campos del flujo:** identificadores, nombre, fechaNacimiento, contactos, representante. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Dominio humano; búsqueda de coincidencias; no datos reales para presentar.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F10_A01 | Buscar paciente | S09 | I | patients.searchHuman | Filtra humanos de la organización por identidad, contacto o identificador ficticio. |
| F10_A02 | Registrar humano | S09, S10 | F | patients.beginHuman | Abre alta humana con búsqueda de coincidencias y borrador administrativo. |
| F10_A03 | Seleccionar existente | S09 | S | patients.selectExisting | Usa la ficha existente seleccionada y evita crear un duplicado. |
| F10_A04 | Añadir representante | S09 | F | relationships.addRepresentative | Captura relación y alcance del representante en el borrador o ficha elegidos. |
| F10_A05 | Guardar paciente | S09 | C | patients.saveHuman | Guarda paciente humano y relaciones válidas; aparece en directorio y selectores. |

**Salida del proceso:** Paciente humano registrado en la organización.

### F11 · Registrar un animal y sus responsables

**Lote:** D03 · **Estado mock:** `animal-patients` · **Contrato:** `F11_INPUT`.

**Campos del flujo:** identificacion, nombre, especie, raza, sexo, fechaNacimiento, responsables. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Especie explícita; persona responsable y animal diferenciados.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F11_A01 | Registrar animal | S09, S11 | F | patients.beginAnimal | Abre alta de animal con especie, identificación y datos específicos. |
| F11_A02 | Buscar responsable | S09 | I | relationships.searchResponsible | Busca personas responsables ficticias dentro del alcance permitido. |
| F11_A03 | Añadir responsable | S09 | F | relationships.addResponsible | Captura una relación diferenciada de propiedad, autorización y contacto. |
| F11_A04 | Guardar animal | S09 | C | patients.saveAnimal | Guarda animal y relaciones; permite seleccionarlo en la agenda veterinaria. |
| F11_A05 | Enviar verificación | S09 | J | relationships.requestVerification | Crea verificación de demo pendiente y muestra su resultado simulado. |

**Salida del proceso:** Animal registrado; persona responsable y paciente conservan identidades distintas.

### F12 · Actualizar o revocar una relación de responsable

**Lote:** D03 · **Estado mock:** `responsible-relationships` · **Contrato:** `F12_INPUT`.

**Campos del flujo:** paciente, persona, tipo, alcance, inicioVigencia, finVigencia, evidenciaDemo, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Vigencia y alcance coherentes; revocación no borra historia.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F12_A01 | Editar relación | S10, S11, S32 | F | relationships.editDraft | Abre relación seleccionada con alcance, tipo y datos actuales. |
| F12_A02 | Verificar relación | S10 | R | relationships.verify | Marca verificación ficticia con actor, fecha y evidencia de ejemplo. |
| F12_A03 | Establecer vigencia | S10 | F | relationships.setValidity | Captura fechas de vigencia en el borrador de relación. |
| F12_A04 | Revocar acceso | S10, S11, S32 | R | relationships.revoke | Revoca la relación y recalcula contenido accesible del portal demo. |
| F12_A05 | Confirmar cambio | S10 | R | relationships.commitChange | Guarda los cambios revisados de alcance y vigencia sin borrar historia. |
| F12_A06 | Solicitar revocación | S32 | F | relationships.requestRevocation | Crea solicitud de revocación visible para el rol interno correspondiente. |

**Salida del proceso:** Relaciones y accesos consistentes con alcance verificado.

### F13 · Revisar y fusionar pacientes duplicados

**Lote:** D03 · **Estado mock:** `identity-merge` · **Contrato:** `F13_INPUT`.

**Campos del flujo:** fichaFuente, fichaConservada, camposConservados, referencias, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Mismo dominio y organización; revisar discrepancias; preservar originales.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F13_A01 | Comparar fichas | S12 | V | patients.compareDuplicates | Muestra fichas, documentos identificadores ficticios y referencias lado a lado. |
| F13_A02 | Elegir ficha conservada | S12 | S | patients.chooseSurvivor | Selecciona la ficha conservada en una propuesta de fusión, sin fusionar aún. |
| F13_A03 | Ver impacto | S12 | V | patients.previewMerge | Muestra atenciones, citas y relaciones que se consolidarán y discrepancias. |
| F13_A04 | Confirmar fusión | S12 | R | patients.merge | Consolida referencias en la misma organización y conserva fichas fuente y evento. |
| F13_A05 | Solicitar corrección | S12 | F | patients.requestCorrection | Registra solicitud de corrección con motivo sin ejecutar una fusión dudosa. |

**Salida del proceso:** Identidad consolidada con procedencia y trazabilidad.

### F14 · Registrar población animal y pertenencias

**Lote:** D08 · **Estado mock:** `animal-population-memberships` · **Contrato:** `F14_INPUT`.

**Campos del flujo:** poblacion, tipo, animal, inicio, fin, destino, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Pertenencia temporal; no sustituir la identidad individual.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F14_A01 | Crear población | S13 | F | populations.create | Crea población veterinaria con tipo, alcance y ubicación ficticios. |
| F14_A02 | Añadir individuo | S13 | F | populations.addIndividual | Añade individuo con inicio y fin de pertenencia, sin duplicar paciente. |
| F14_A03 | Registrar traslado | S13 | F | populations.recordTransfer | Registra salida y entrada de pertenencia con fechas y poblaciones. |
| F14_A04 | Registrar baja | S13 | F | populations.recordExit | Registra baja de pertenencia y motivo; conserva historia del individuo. |
| F14_A05 | Guardar pertenencias | S13 | C | populations.commitMemberships | Guarda intervalos revisados y actualiza integrantes de la población. |

**Salida del proceso:** Población identificada y membresías temporales registradas.

### F15 · Buscar paciente y abrir historia compartida

**Lote:** D03 · **Estado mock:** `record-queries` · **Contrato:** `F15_INPUT`.

**Campos del flujo:** paciente, identificador, dominio, rangoFechas, procedencia. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Misma organización y alcance; compartir entre sucursales autorizadas.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F15_A01 | Buscar | S09 | I | patients.search | Filtra por identificadores y dominio dentro de la organización activa. |
| F15_A02 | Abrir ficha | S09 | N | patients.openProfile | Abre ficha del ID elegido, conservando lista y filtro de origen. |
| F15_A03 | Ver historia | S10, S11, S19 | N | record.openHistory | Abre historia longitudinal compartida entre sucursales autorizadas del espacio. |
| F15_A04 | Filtrar por fecha | S19 | I | record.filterDates | Filtra eventos por rango sin modificar el expediente. |
| F15_A05 | Ver procedencia | S19 | V | record.showProvenance | Muestra organización custodio, sucursal de origen, autor y versiones del evento. |

**Salida del proceso:** Historia visible dentro del tenant con alcance explícito.

### F16 · Reservar una cita desde la clínica

**Lote:** D03 · **Estado mock:** `appointments` · **Contrato:** `F16_INPUT`.

**Campos del flujo:** paciente, servicio, profesional, sucursal, lugar, recurso, inicio, fin. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Intervalo disponible, dominio compatible y operación idempotente.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F16_A01 | Nueva cita | S14 | F | appointments.beginBooking | Abre borrador de cita con paciente, servicio, profesional y contexto. |
| F16_A02 | Ver disponibilidad | S14 | V | appointments.showAvailability | Muestra horarios calculados desde disponibilidad, bloqueos y reservas demo. |
| F16_A03 | Reservar cita | S14 | R | appointments.reserve | Confirma reserva única y actualiza agenda; si hay conflicto mantiene captura. |
| F16_A04 | Ver confirmación | S14 | V | appointments.showConfirmation | Muestra reserva, paciente, horario, lugar y estado confirmados. |
| F16_A05 | Enviar recordatorio | S14 | J | appointments.sendReminder | Crea un recordatorio simulado y muestra estado de entrega en la cita. |

**Salida del proceso:** Cita reservada con organización, profesional y lugar identificados.

### F17 · Solicitar una cita desde el portal

**Lote:** D03 · **Estado mock:** `portal-booking-requests` · **Contrato:** `F17_INPUT`.

**Campos del flujo:** vinculo, paciente, organizacion, servicio, horarios, alternativa. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Vínculo vigente; solicitud y reserva diferenciadas; oferta no vencida.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F17_A01 | Solicitar cita | S29 | W | requests.beginPortalBooking | Abre solicitud desde portal para vínculos vigentes de la persona ficticia. |
| F17_A02 | Elegir paciente | S29 | S | requests.choosePatient | Selecciona el paciente o animal autorizado y actualiza servicios disponibles. |
| F17_A03 | Ver horarios | S29 | V | requests.showSlots | Muestra horarios de la organización y perfil de solicitud elegidos. |
| F17_A04 | Enviar solicitud | S29 | R | requests.submit | Crea solicitud revisada visible en portal y bandeja de recepción. |
| F17_A05 | Aceptar alternativa | S29 | R | requests.acceptAlternative | Acepta oferta vigente y crea la reserva enlazada a la solicitud. |

**Salida del proceso:** Cita confirmada o solicitud pendiente con estado explícito.

### F18 · Confirmar, reprogramar o cancelar una cita

**Lote:** D03 · **Estado mock:** `appointment-changes` · **Contrato:** `F18_INPUT`.

**Campos del flujo:** cita, nuevoIntervalo, motivo, decision. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Estado permite cambio; nueva disponibilidad; no liberar cita al abrir captura.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F18_A01 | Confirmar asistencia | S14, S30 | R | appointments.confirmAttendance | Registra confirmación de asistencia y actualiza estado en clínica y portal. |
| F18_A02 | Reprogramar | S14, S30 | F | appointments.beginReschedule | Abre nueva selección de horario conservando la cita original hasta confirmar. |
| F18_A03 | Cancelar cita | S14, S30 | R | appointments.cancel | Cancela con motivo, libera intervalo y conserva historial de la cita. |
| F18_A04 | Guardar cambio | S14, S30 | R | appointments.commitReschedule | Mueve la reserva si el horario sigue libre y registra cambio de fecha. |
| F18_A05 | Conservar cita | S14, S30 | L | appointments.keepBooking | Cierra propuesta sin modificar la reserva ni liberar su intervalo. |

**Salida del proceso:** Cita actualizada con historial; no borrar atención ya realizada.

### F19 · Gestionar lista de espera

**Lote:** D03 · **Estado mock:** `waitlist` · **Contrato:** `F19_INPUT`.

**Campos del flujo:** paciente, servicio, preferencias, oferta, vencimiento, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Una oferta vigente; intervalo aún libre al aceptar; estado de espera válido.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F19_A01 | Añadir a espera | S15 | F | waitlist.add | Registra necesidad, prioridad de ejemplo y disponibilidad aceptable del paciente. |
| F19_A02 | Ofrecer intervalo | S15 | F | waitlist.offerSlot | Crea oferta con intervalo y vigencia y la muestra al destinatario demo. |
| F19_A03 | Aceptar oferta | S30 | R | waitlist.acceptOffer | Convierte oferta vigente en cita sin reservar dos veces el recurso. |
| F19_A04 | Rechazar oferta | S30 | R | waitlist.rejectOffer | Registra rechazo y libera la oferta conservando posición según regla demo. |
| F19_A05 | Salir de espera | S15, S30 | R | waitlist.leave | Cierra participación con motivo sin cancelar otras citas del paciente. |

**Salida del proceso:** Solicitud convertida en cita o mantenida/cerrada con motivo.

### F20 · Registrar llegada, cola y atención sin cita

**Lote:** D03 · **Estado mock:** `arrival-queue` · **Contrato:** `F20_INPUT`.

**Campos del flujo:** paciente, cita, servicio, profesional, llegada, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Una cola activa por llegada; identidad verificada en demo; retiro explícito.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F20_A01 | Registrar llegada | S16 | F | queue.recordArrival | Registra llegada ligada a cita y verifica paciente y contexto. |
| F20_A02 | Ingreso sin cita | S16 | F | queue.beginWalkIn | Captura ingreso sin cita y servicio sin inventar una reserva anterior. |
| F20_A03 | Enviar a cola | S16 | C | queue.enqueue | Crea entrada de cola única y la muestra a recepción y profesional asignado. |
| F20_A04 | Llamar paciente | S16 | C | queue.call | Cambia entrada a llamada y muestra quién la llamó y cuándo. |
| F20_A05 | Registrar retiro | S16 | R | queue.recordWithdrawal | Registra retiro con motivo y resuelve su entrada de cola. |
| F20_A06 | Iniciar atención | S16, S17 | C | encounters.startFromQueue | Crea o abre atención ligada a la llegada sin duplicar un encuentro activo. |

**Salida del proceso:** Paciente preparado para atención o retiro registrado.

### F21 · Realizar una consulta y finalizar la visita

**Lote:** D04 · **Estado mock:** `encounters` · **Contrato:** `F21_INPUT`.

**Campos del flujo:** paciente, origen, profesional, especialidad, borrador, resumen, pendientes. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Contexto y autoría; no duplicar encuentro activo; revisar antes de cierre.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F21_A01 | Iniciar atención | S17 | C | encounters.start | Activa atención del paciente elegido con profesional y sucursal de origen. |
| F21_A02 | Guardar borrador | S17 | C | encounters.saveDraft | Guarda respuestas y anotaciones como borrador de una revisión clínica. |
| F21_A03 | Revisar resumen | S17 | V | encounters.reviewSummary | Presenta contenido, pendientes, documentos y campos faltantes antes del cierre. |
| F21_A04 | Finalizar visita | S17 | R | encounters.finalize | Cierra la visita revisada y conserva pendientes asignados y versiones de documentos. |
| F21_A05 | Dejar pendiente | S17 | C | encounters.keepPending | Mantiene atención pendiente con motivo o tarea sin declarar cierre satisfactorio. |

**Salida del proceso:** Visita finalizada; notas y tareas conservan sus estados reales.

### F22 · Capturar un formulario de especialidad

**Lote:** D04 · **Estado mock:** `form-responses` · **Contrato:** `F22_INPUT`.

**Campos del flujo:** plantillaVersion, seccion, respuestas, observacion, estadoDesconocido. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Validar contra esquema elegido; desconocido no equivale a negativo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F22_A01 | Abrir sección | S18 | S | forms.openSection | Activa sección de la plantilla versionada y conserva el resto de respuestas. |
| F22_A02 | Añadir medición | S18 | F | forms.addMeasurement | Captura observación con unidad, fecha, método y origen cuando corresponde. |
| F22_A03 | Marcar dato desconocido | S18 | S | forms.markUnknown | Distingue dato desconocido o no disponible de un valor negativo o normal. |
| F22_A04 | Guardar borrador | S18 | C | forms.saveDraft | Guarda respuestas contra su versión de esquema sin cambiar la plantilla original. |
| F22_A05 | Comparar versiones | S18 | V | forms.compareVersions | Muestra diferencias de respuestas y esquema entre versiones o visitas elegidas. |

**Salida del proceso:** Captura versionada vinculada a atención, sin firma automática.

### F23 · Marcar un hallazgo en un mapa anatómico

**Lote:** D04 · **Estado mock:** `anatomical-annotations` · **Contrato:** `F23_INPUT`.

**Campos del flujo:** atlasVersion, vista, estructura, lateralidad, hallazgo, procedimiento. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Estructura válida de atlas; semántica además del color; dominio y especie.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F23_A01 | Elegir vista anatómica | S18 | G | anatomy.chooseView | Cambia atlas o vista compatible con órgano, dominio y especie. |
| F23_A02 | Marcar región | S18 | G | anatomy.selectRegion | Selecciona una estructura con ID semántico y lateralidad; se resalta y anuncia. |
| F23_A03 | Añadir hallazgo | S18 | F | anatomy.addFinding | Captura hallazgo ligado a estructura y visita con estado y descripción. |
| F23_A04 | Vincular procedimiento | S18 | F | anatomy.linkProcedure | Vincula procedimiento registrado a la anotación sin marcarlo realizado por defecto. |
| F23_A05 | Deshacer cambio local | S18 | B | anatomy.undoLocal | Revierte el último cambio local antes de guardar, sin alterar versiones confirmadas. |
| F23_A06 | Comparar evolución | S19 | V | anatomy.compareEvolution | Compara anotaciones equivalentes en visitas con leyenda y tabla de cambios. |

**Salida del proceso:** Hallazgo localizado y reproducible; dibujo y dato clínico relacionados.

### F24 · Registrar odontograma y evolución dental humana o animal

**Lote:** D04 · **Estado mock:** `odontogram` · **Contrato:** `F24_INPUT`.

**Campos del flujo:** denticion, especie, pieza, cara, condicion, procedimiento, revision. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Pieza/cara válidas; dentición compatible; diferenciar observado y realizado.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F24_A01 | Seleccionar pieza | S18 | G | dental.selectTooth | Selecciona pieza válida de la dentición humana o atlas de especie elegido. |
| F24_A02 | Seleccionar cara | S18 | G | dental.selectSurface | Selecciona cara disponible y muestra pieza, cara y leyenda activas. |
| F24_A03 | Registrar condición | S18 | F | dental.recordCondition | Captura condición semántica por pieza/cara con fecha y estado registrado. |
| F24_A04 | Registrar procedimiento | S18 | F | dental.recordProcedure | Registra procedimiento y su estado, vinculado al hallazgo y atención. |
| F24_A05 | Ver cambios | S18 | V | dental.showChanges | Muestra cambios locales o de revisión con tabla por pieza/cara. |
| F24_A06 | Comparar odontogramas | S19 | V | dental.compareOdontograms | Compara denticiones y versiones compatibles y muestra diferencias de registros. |

**Salida del proceso:** Evolución dental guardada por pieza y cara, sin sustituir hechos previos por colores.

### F25 · Registrar mediciones, curvas y escalas

**Lote:** D04 · **Estado mock:** `observations-instruments` · **Contrato:** `F25_INPUT`.

**Campos del flujo:** parametro, valor, unidad, fecha, referencia, instrumentoVersion, respuestas. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Unidades y referencias compatibles; resultados identificados como demostración.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F25_A01 | Añadir medición | S18 | F | observations.add | Captura valor, unidad, tiempo y origen de medición sin convertir datos desconocidos. |
| F25_A02 | Elegir unidad | S18 | S | observations.chooseUnit | Selecciona unidad permitida y explica cualquier conversión de demo aplicada. |
| F25_A03 | Aplicar instrumento | S18 | F | instruments.apply | Abre instrumento versionado con respuestas y resultado de demostración identificado. |
| F25_A04 | Ver referencia | S18 | V | observations.showReference | Muestra referencia, población, unidad y origen del ejemplo sin inferir diagnóstico. |
| F25_A05 | Ver tendencia | S18, S19 | S | observations.showTrend | Cambia a serie temporal filtrada del mismo parámetro y unidad compatible. |
| F25_A06 | Ver tabla | S18, S19 | S | observations.showTable | Presenta los mismos valores, fechas y unidades en tabla equivalente. |

**Salida del proceso:** Valores y referencias conservados; gráficos reconstruibles.

### F26 · Adjuntar y comparar archivos clínicos

**Lote:** D04 · **Estado mock:** `clinical-attachments` · **Contrato:** `F26_INPUT`.

**Campos del flujo:** archivoFicticio, tipo, tamano, contexto, fecha, asociacion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Validación local de tipo/tamaño; conservar referencias; liberar URLs temporales.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F26_A01 | Adjuntar archivo | S18, S24, S28 | F | attachments.attachLocal | Selecciona archivo ficticio, valida tipo/tamaño y lo asocia a la visita al guardar. |
| F26_A02 | Ver vista previa | S18 | V | attachments.preview | Muestra el archivo local de ejemplo y sus metadatos sin enviarlo a un proveedor. |
| F26_A03 | Comparar imágenes | S18, S24 | V | attachments.compareImages | Presenta dos imágenes ficticias elegidas con fecha y controles de comparación. |
| F26_A04 | Descargar autorizado | S18 | X | attachments.download | Descarga el archivo local permitido por contexto de demo. |
| F26_A05 | Retirar asociación | S18 | R | attachments.detach | Retira asociación revisada sin borrar otras referencias o versiones que la usan. |

**Salida del proceso:** Archivo privado identificado y vinculado con procedencia.

### F27 · Revisar y firmar una nota o documento clínico

**Lote:** D04 · **Estado mock:** `document-signatures-demo` · **Contrato:** `F27_INPUT`.

**Campos del flujo:** documento, revision, autor, contenido, decision. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Firmar solo revisión vigente; evidencia ficticia e inmutabilidad posterior.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F27_A01 | Revisar documento | S18, S28 | V | documents.review | Muestra revisión concreta, autor, contenido y comprobaciones antes de firma demo. |
| F27_A02 | Firmar revisión | S18, S28 | R | documents.signRevisionDemo | Fija la revisión como firmada de demostración con evidencia ficticia visible. |
| F27_A03 | Volver al borrador | S18 | L | documents.returnToDraft | Vuelve a edición si la revisión aún no está firmada y conserva captura. |
| F27_A04 | Ver evidencia de firma | S28 | V | documents.showSignatureEvidence | Muestra identidad, instante y versión de la firma simulada, rotulada como demo. |

**Salida del proceso:** Revisión firmada y conservada; finalizar visita es una acción separada.

### F28 · Corregir contenido firmado mediante adenda

**Lote:** D04 · **Estado mock:** `document-addenda` · **Contrato:** `F28_INPUT`.

**Campos del flujo:** original, motivo, correccion, revision, autor. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Original firmado de demo; adenda enlazada y motivo obligatorio.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F28_A01 | Crear adenda | S19, S28 | F | documents.beginAddendum | Abre adenda vinculada al documento firmado y exige motivo de corrección. |
| F28_A02 | Ver original | S19 | V | documents.showOriginal | Muestra revisión original inmutable de demo junto a su procedencia. |
| F28_A03 | Revisar corrección | S19 | V | documents.reviewCorrection | Compara original, motivo y contenido de adenda antes de confirmar. |
| F28_A04 | Firmar adenda | S28 | R | documents.signAddendumDemo | Fija adenda simulada y actualiza cadena de versiones sin sobrescribir original. |
| F28_A05 | Ver versiones | S19, S28 | V | documents.showVersions | Presenta revisión original y adendas en orden con estado y autor. |

**Salida del proceso:** Corrección trazable; ninguna versión firmada sobrescrita.

### F29 · Mantener episodios, problemas y antecedentes longitudinales

**Lote:** D04 · **Estado mock:** `longitudinal-episodes` · **Contrato:** `F29_INPUT`.

**Campos del flujo:** episodio, tipo, antecedente, problema, alergia, estado, origen. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Mismo paciente y espacio; fecha/origen; no borrar estados anteriores.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F29_A01 | Crear episodio | S19 | F | episodes.create | Crea episodio longitudinal del paciente con tipo, inicio y responsable. |
| F29_A02 | Añadir antecedente | S19 | F | history.addBackground | Añade antecedente con origen, fecha y grado de certeza registrado. |
| F29_A03 | Registrar problema | S19 | F | problems.record | Registra problema con estado y vínculo a la atención cuando corresponde. |
| F29_A04 | Registrar alergia | S19 | F | allergies.record | Registra alergia o estado desconocido con sustancia, reacción y procedencia. |
| F29_A05 | Vincular atención | S19 | F | episodes.linkEncounter | Vincula atención existente del mismo paciente y espacio al episodio elegido. |
| F29_A06 | Actualizar estado | S19 | F | problems.updateState | Actualiza estado con fecha y motivo, conservando el evento anterior. |

**Salida del proceso:** Datos longitudinales actualizados con origen y fechas.

### F30 · Crear orden de estudio, procedimiento o remisión

**Lote:** D04 · **Estado mock:** `clinical-orders` · **Contrato:** `F30_INPUT`.

**Campos del flujo:** tipo, servicio, paciente, atencion, prioridadEjemplo, destino, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Servicio compatible; emisión crea tareas; no cancela silenciosamente lo realizado.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F30_A01 | Nueva orden | S20 | F | orders.begin | Abre orden de estudio, procedimiento o remisión con paciente y atención. |
| F30_A02 | Elegir servicio | S20 | S | orders.chooseService | Selecciona servicio compatible y muestra requisitos de captura del ejemplo. |
| F30_A03 | Emitir orden | S20 | R | orders.issue | Emite orden demo y genera las tareas requeridas sin declararlas completadas. |
| F30_A04 | Generar remisión | S20 | F | orders.createReferral | Crea remisión con resumen, destino ficticio y entregas previstas. |
| F30_A05 | Ver tareas | S20 | N | orders.showTasks | Abre lista filtrada de tareas y estados ligados a la orden. |
| F30_A06 | Cancelar orden | S20 | R | orders.cancel | Cancela lo permitido con motivo y expone tareas ya realizadas que se conservan. |

**Salida del proceso:** Orden emitida con responsables de ejecución y revisión.

### F31 · Asignar tarea y obtener muestra o adquisición

**Lote:** D07 · **Estado mock:** `diagnostic-tasks-specimens` · **Contrato:** `F31_INPUT`.

**Campos del flujo:** tarea, muestra, tipo, identificador, fecha, actor, receptor, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Identidad y orden conciliadas; aceptación y rechazo distintos; trazabilidad.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F31_A01 | Aceptar tarea | S21 | C | diagnostic.acceptTask | Asigna tarea válida al equipo o persona demo y cambia su estado. |
| F31_A02 | Registrar obtención | S22 | F | specimens.recordCollection | Registra obtención con identificador, tipo, actor, fecha y condiciones de ejemplo. |
| F31_A03 | Imprimir identificación | S22 | P | specimens.printLabel | Abre impresión de identificación ficticia con paciente, orden y muestra. |
| F31_A04 | Aceptar muestra | S22 | R | specimens.accept | Registra aceptación de muestra según revisión, con trazabilidad. |
| F31_A05 | Rechazar muestra | S22 | R | specimens.reject | Registra rechazo y motivo y genera pendiente apropiado sin resultado válido falso. |
| F31_A06 | Registrar entrega | S22 | F | specimens.recordHandoff | Registra entrega y receptor de la muestra manteniendo cadena de eventos. |

**Salida del proceso:** Muestra/adquisición identificada y entrega trazada.

### F32 · Procesar y emitir resultado de laboratorio

**Lote:** D07 · **Estado mock:** `lab-reports` · **Contrato:** `F32_INPUT`.

**Campos del flujo:** muestra, parametro, valor, unidad, referencia, version, estado, correccion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Unidad y estado válidos; preliminar no es final; corrección conserva original.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F32_A01 | Registrar resultados | S23 | F | laboratory.enterResults | Captura valores, unidades, referencias y estado para la muestra elegida. |
| F32_A02 | Guardar preliminar | S23 | C | laboratory.savePreliminary | Guarda versión preliminar identificada sin publicarla como final. |
| F32_A03 | Emitir informe | S23 | R | laboratory.issueReport | Emite informe demo y crea pendiente de revisión para el profesional. |
| F32_A04 | Corregir informe | S23 | F | laboratory.correctReport | Abre corrección vinculada a la revisión emitida conservando su original. |
| F32_A05 | Ver trazabilidad | S23 | V | laboratory.showTrace | Muestra orden, muestra, estados, revisiones y responsables del informe. |

**Salida del proceso:** Informe emitido; revisión clínica aún pendiente.

### F33 · Adquirir estudio de imagen y emitir informe

**Lote:** D07 · **Estado mock:** `imaging-reports` · **Contrato:** `F33_INPUT`.

**Campos del flujo:** orden, estudio, adquisicionFicticia, paciente, informe, revision, discrepancia. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Conciliar identidad; visor de demo; firma simulada sobre revisión vigente.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F33_A01 | Abrir estudio | S24 | N | imaging.openStudy | Abre estudio ficticio con paciente, orden, modalidad y adquisiciones asociadas. |
| F33_A02 | Vincular adquisición | S24 | F | imaging.linkAcquisition | Asocia archivo o adquisición demo tras revisar identidad y orden. |
| F33_A03 | Guardar informe | S24 | C | imaging.saveReport | Guarda borrador del informe de imágenes de la revisión activa. |
| F33_A04 | Firmar informe | S24 | R | imaging.signReportDemo | Firma informe de demostración y crea pendiente clínico de revisión. |
| F33_A05 | Ver imágenes | S24 | V | imaging.viewImages | Muestra visor de material ficticio preparado, metadatos y controles locales. |
| F33_A06 | Solicitar conciliación | S24 | F | imaging.requestReconciliation | Crea tarea por discrepancia de identidad o asociación sin forzar una coincidencia. |

**Salida del proceso:** Estudio e informe vinculados; revisión clínica asignada.

### F34 · Revisar resultados y resolver pendientes clínicos

**Lote:** D04 · **Estado mock:** `result-review` · **Contrato:** `F34_INPUT`.

**Campos del flujo:** resultado, revisionClinica, responsable, fecha, seguimiento, aclaracion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Revisión explícita del profesional; pendiente con responsable vigente.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F34_A01 | Revisar resultado | S17, S20 | V | results.review | Muestra informe, orden y contexto clínico con su versión actual. |
| F34_A02 | Registrar revisión | S20, S23, S24 | F | results.recordReview | Registra revisión explícita del profesional y estado del pendiente. |
| F34_A03 | Asignar seguimiento | S17 | F | results.assignFollowup | Crea seguimiento con responsable y fecha ligado al resultado revisado. |
| F34_A04 | Reasignar pendiente | S17 | F | results.reassignPending | Reasigna pendiente a miembro vigente y conserva responsables anteriores. |
| F34_A05 | Solicitar aclaración | S17 | F | results.requestClarification | Crea solicitud de aclaración ligada al informe y visible al equipo emisor. |

**Salida del proceso:** Resultado revisado o pendiente explícito bajo responsable; recibir no equivale a revisar.

### F35 · Conciliar medicación y emitir receta

**Lote:** D04 · **Estado mock:** `prescriptions` · **Contrato:** `F35_INPUT`.

**Campos del flujo:** paciente, medicaciones, producto, dosis, unidad, via, frecuencia, duracion, version. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Ejemplos ficticios; revisión y versión emitida; sin prescripción automática.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F35_A01 | Conciliar medicación | S25 | F | medication.reconcile | Compara tratamientos registrados y captura conciliación con procedencia. |
| F35_A02 | Añadir medicamento | S25 | F | prescriptions.addItem | Añade medicamento con dosis, unidad, vía, frecuencia y duración de ejemplo. |
| F35_A03 | Guardar receta en borrador | S25 | C | prescriptions.saveDraft | Guarda receta en borrador ligada a la visita y paciente. |
| F35_A04 | Revisar receta | S25 | V | prescriptions.review | Muestra ítems, datos del paciente y alertas registradas antes de emitir. |
| F35_A05 | Emitir receta | S25 | R | prescriptions.issue | Emite receta de demo, fija versión y la habilita para dispensación simulada. |
| F35_A06 | Ver versiones | S25 | V | prescriptions.showVersions | Muestra borradores, receta emitida y correcciones con autor y fecha. |

**Salida del proceso:** Receta emitida o medicación referida registrada como hecho distinto.

### F36 · Dispensar medicamentos y registrar devoluciones

**Lote:** D07 · **Estado mock:** `dispensing` · **Contrato:** `F36_INPUT`.

**Campos del flujo:** receta, producto, lote, cantidad, entrega, motivoDevolucion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Stock disponible; lote habilitado en fixture; entrega única; devolución vinculada.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F36_A01 | Preparar entrega | S26 | F | dispensing.prepare | Abre selección de cantidades y productos para la receta emitida. |
| F36_A02 | Elegir lote | S26 | S | dispensing.chooseLot | Selecciona lote permitido y muestra existencia, vencimiento y cantidades. |
| F36_A03 | Registrar entrega parcial | S26 | R | dispensing.deliverPartial | Registra entrega parcial y movimiento de stock; conserva saldo por dispensar. |
| F36_A04 | Confirmar dispensación | S26 | R | dispensing.confirm | Confirma cantidades revisadas y reduce stock una sola vez por operación. |
| F36_A05 | Registrar devolución | S26 | F | dispensing.return | Registra devolución vinculada a entrega con estado y movimiento correspondiente. |

**Salida del proceso:** Entrega/devolución trazable; dispensar no prueba administración.

### F37 · Registrar administración o dosis no realizada

**Lote:** D07 · **Estado mock:** `medication-administration` · **Contrato:** `F37_INPUT`.

**Campos del flujo:** orden, dosis, hora, actor, estado, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Diferenciar administrada y no realizada; orden vigente y paciente correcto.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F37_A01 | Verificar orden | S27 | V | administration.verifyOrder | Muestra orden vigente, paciente, dosis y verificaciones registradas para revisar. |
| F37_A02 | Registrar administración | S27 | F | administration.recordGiven | Captura dosis administrada, hora y actor y actualiza historial de cuidados. |
| F37_A03 | Registrar no realizada | S27 | F | administration.recordNotGiven | Registra no realizada con motivo; no incrementa dosis administradas. |
| F37_A04 | Solicitar revisión | S27 | F | administration.requestReview | Crea pendiente de revisión de orden o dosis para el profesional. |
| F37_A05 | Ver historial de dosis | S27 | V | administration.showHistory | Presenta dosis realizadas y excepciones con orden y fechas. |

**Salida del proceso:** Hecho de administración o excepción documentado.

### F38 · Preparar documentos y gestionar consentimiento

**Lote:** D04 · **Estado mock:** `documents-consents` · **Contrato:** `F38_INPUT`.

**Campos del flujo:** plantilla, emisor, paciente, contenido, participante, alcance, decision, canal. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Decisión explícita y alcance; cierre no publica por sí solo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F38_A01 | Nuevo documento | S28 | F | documents.createDraft | Abre documento basado en plantilla con emisor, paciente y revisión. |
| F38_A02 | Ver vista previa | S28 | V | documents.preview | Muestra contenido preparado, destinatario y formato de impresión. |
| F38_A03 | Registrar consentimiento | S28 | F | consent.capture | Registra alcance, participante, evidencia ficticia y estado del consentimiento. |
| F38_A04 | Registrar decisión | S28, S31 | F | consent.recordDecision | Registra aceptación, rechazo o retiro con fecha y alcance explícitos. |
| F38_A05 | Cerrar documento | S28 | R | documents.close | Cierra la revisión válida del documento sin confundirla con publicación portal. |
| F38_A06 | Elegir entrega | S28 | F | documents.chooseDelivery | Define canal y destinatario de entrega demo sin envío real automático. |

**Salida del proceso:** Documento/evidencia conservado o decisión pendiente explícita.

### F39 · Vincular portal y conceder delegación verificada

**Lote:** D05 · **Estado mock:** `portal-links` · **Contrato:** `F39_INPUT`.

**Campos del flujo:** persona, paciente, organizacion, alcance, vigencia, evidenciaDemo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Identidad y relación ficticias verificadas; no acceso por nombre o contacto solo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F39_A01 | Invitar al portal | S10, S11, S32 | F | portal.invite | Crea invitación ficticia asociada a una identidad y paciente o animal. |
| F39_A02 | Definir alcance | S10 | F | portal.defineScope | Captura contenido, acciones y vigencia de la delegación propuesta. |
| F39_A03 | Verificar identidad | S10 | R | portal.verifyIdentityDemo | Registra verificación de ejemplo de identidad y relación con evidencia preparada. |
| F39_A04 | Aceptar vínculo | S02, S32 | R | portal.acceptLink | Activa vínculo demo revisado y habilita su selector en el portal. |
| F39_A05 | Revocar delegación | S10 | R | portal.revokeDelegation | Revoca alcance futuro y recalcula citas y publicaciones visibles de la sesión. |

**Salida del proceso:** Cuenta externa vinculada con alcance verificable; no por coincidencia de DNI o correo.

### F40 · Publicar una versión documental para el portal

**Lote:** D05 · **Estado mock:** `portal-publications` · **Contrato:** `F40_INPUT`.

**Campos del flujo:** documentoVersion, destinatarios, alcance, canal, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Versión elegida; vínculos vigentes; retirar visibilidad conserva evidencia.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F40_A01 | Preparar publicación | S28 | W | publication.prepare | Abre selección de versión, destinatarios y alcance de publicación, aún privada. |
| F40_A02 | Ver como destinatario | S28 | V | publication.previewRecipient | Muestra exactamente el contenido que vería el destinatario elegido. |
| F40_A03 | Publicar documento | S28 | R | publication.publish | Publica versión revisada solo a vínculos vigentes y la muestra en el portal. |
| F40_A04 | Ver entregas | S28 | V | publication.showDeliveries | Muestra publicación y trabajos de entrega simulados con estado y destinatarios. |
| F40_A05 | Retirar publicación | S28 | R | publication.withdraw | Retira visibilidad futura de la publicación con motivo y conserva evidencia demo. |

**Salida del proceso:** Publicación concreta autorizada; no abre la historia interna completa.

### F41 · Organizar seguimiento y comunicación

**Lote:** D05 · **Estado mock:** `followup-messages` · **Contrato:** `F41_INPUT`.

**Campos del flujo:** paciente, tarea, responsable, fecha, conversacion, mensaje, resultado. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Ámbito del vínculo; no comunicaciones reales; resolver con resultado.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F41_A01 | Programar control | S33 | F | followup.scheduleControl | Programa control o solicitud con fecha y vínculo a la atención o resultado. |
| F41_A02 | Crear pendiente | S33 | F | followup.createTask | Crea pendiente con propósito, prioridad de ejemplo y vencimiento. |
| F41_A03 | Asignar responsable | S33 | F | followup.assignOwner | Asigna pendiente a un responsable vigente y lo muestra en su bandeja. |
| F41_A04 | Enviar mensaje | S33 | F | messages.sendDemo | Guarda mensaje en conversación de demo y crea entrega simulada con destinatario. |
| F41_A05 | Registrar respuesta | S33 | F | messages.recordReply | Registra respuesta recibida ficticia y la vincula a conversación y tarea. |
| F41_A06 | Resolver tarea | S33 | R | followup.resolve | Resuelve tarea con resultado y conserva su historial y seguimiento asociado. |
| F41_A07 | Enviar respuesta | S33 | F | messages.replyDemo | Añade respuesta del paciente o responsable autorizado, visible a la bandeja interna. |

**Salida del proceso:** Seguimiento resuelto o pendiente trazable; no confundir mensaje enviado con atención realizada.

### F42 · Preparar plan comercial y presupuesto

**Lote:** D06 · **Estado mock:** `estimates` · **Contrato:** `F42_INPUT`.

**Campos del flujo:** paciente, pagador, etapas, partidas, tarifa, descuento, condiciones, version. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Importes en unidades menores; aceptar versión concreta; no cargo automático.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F42_A01 | Crear presupuesto | S34 | F | estimates.create | Crea presupuesto versionado con paciente, servicios y pagador propuestos. |
| F42_A02 | Añadir etapa | S34 | F | estimates.addStage | Añade etapa, partidas y condiciones de ejemplo sin crear cargos automáticamente. |
| F42_A03 | Solicitar descuento | S34 | F | estimates.requestDiscount | Crea solicitud de descuento y estado de aprobación, sin aplicarlo aún. |
| F42_A04 | Enviar presupuesto | S34 | R | estimates.sendDemo | Fija versión enviada, registra entrega simulada y la muestra al destinatario portal. |
| F42_A05 | Registrar aceptación | S34, S29 | R | estimates.recordAcceptance | Registra aceptación de una versión concreta con actor, fecha y condiciones. |
| F42_A06 | Crear nueva versión | S34 | F | estimates.newRevision | Copia una versión a un borrador nuevo conservando condiciones anteriores. |

**Salida del proceso:** Presupuesto aceptado/versionado; ejecución clínica todavía independiente.

### F43 · Registrar cargos y cuenta por cobrar

**Lote:** D06 · **Estado mock:** `charges-accounts` · **Contrato:** `F43_INPUT`.

**Campos del flujo:** cuenta, servicio, importe, moneda, origen, ajuste, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Cargo único; saldo derivado de movimientos; reverso conserva fuente.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F43_A01 | Añadir cargo | S35 | F | charges.addDraft | Captura cargo, servicio, precio y procedencia ligado a la cuenta del paciente. |
| F43_A02 | Revisar cargos propuestos | S35 | V | charges.reviewProposals | Muestra cargos sugeridos por actuaciones sin contabilizarlos automáticamente. |
| F43_A03 | Confirmar cargo | S35 | R | charges.confirm | Confirma cargo revisado y actualiza cuenta y saldo por cobrar. |
| F43_A04 | Ajustar cargo | S35 | F | charges.adjust | Registra ajuste con motivo y recalcula saldo preservando la partida anterior. |
| F43_A05 | Revertir cargo | S35 | R | charges.reverse | Crea reverso ligado al cargo y motivo, sin eliminar evidencia del movimiento. |
| F43_A06 | Ver cuenta | S35 | N | accounts.open | Abre cuenta con cargos, pagos, anticipos y saldo derivado de movimientos. |

**Salida del proceso:** Cuenta actualizada sin acreditar automáticamente pago ni atención.

### F44 · Cobrar, conciliar caja y devolver pagos

**Lote:** D06 · **Estado mock:** `payments-cash` · **Contrato:** `F44_INPUT`.

**Campos del flujo:** caja, cuenta, importe, moneda, medioFicticio, anticipo, devolucion, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Pago y devolución ficticios; saldo suficiente; evitar doble aplicación.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F44_A01 | Abrir caja | S35 | F | cash.open | Abre caja demo con sucursal, responsable y saldo inicial de ejemplo. |
| F44_A02 | Registrar pago | S35 | F | payments.recordDemo | Registra pago ficticio revisado y asignación a cuenta; actualiza saldo y caja. |
| F44_A03 | Asignar anticipo | S35 | F | payments.allocateAdvance | Asigna anticipo disponible sin exceder su saldo ni duplicar aplicación. |
| F44_A04 | Conciliar pago | S35 | R | payments.reconcileDemo | Registra conciliación de un pago simulado y conserva diferencias explícitas. |
| F44_A05 | Solicitar devolución | S35 | F | payments.requestRefund | Crea solicitud de devolución con movimiento original, cantidad y motivo. |
| F44_A06 | Confirmar devolución | S35 | R | payments.confirmRefundDemo | Confirma devolución ficticia y su reverso de saldo/caja una sola vez. |
| F44_A07 | Cerrar caja | S35 | R | cash.close | Cierra caja con arqueo, resumen y diferencias registradas. |

**Salida del proceso:** Pago/devolución y caja conciliados o pendientes reales visibles.

### F45 · Emitir comprobante y tratar rechazo o corrección

**Lote:** D06 · **Estado mock:** `invoices-demo` · **Contrato:** `F45_INPUT`.

**Campos del flujo:** emisor, destinatario, cargos, serieFicticia, importe, trabajo, respuesta, correccion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Comprobante rotulado demo; estado fiscal independiente del pago.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F45_A01 | Preparar comprobante | S36 | F | invoices.prepareDemo | Prepara comprobante ficticio con emisor, destinatario y cargos elegidos. |
| F45_A02 | Ver vista previa | S36 | V | invoices.preview | Muestra contenido e importes del comprobante antes de emisión simulada. |
| F45_A03 | Emitir comprobante | S36 | R | invoices.issueDemo | Crea comprobante y trabajo externo demo pendiente, sin cambiar por sí solo el cobro. |
| F45_A04 | Consultar estado | S36 | J | invoices.checkDemoStatus | Avanza o consulta trabajo fiscal simulado y muestra respuesta preparada. |
| F45_A05 | Gestionar rechazo | S36 | F | invoices.handleRejection | Abre revisión del rechazo y correcciones permitidas conservando el intento original. |
| F45_A06 | Crear documento correctivo | S36 | F | invoices.createCorrection | Crea documento correctivo ficticio ligado al comprobante y su motivo. |

**Salida del proceso:** Estado fiscal y evidencia conservados; pago permanece independiente.

### F46 · Calcular y pagar honorarios profesionales

**Lote:** D06 · **Estado mock:** `professional-settlements` · **Contrato:** `F46_INPUT`.

**Campos del flujo:** profesional, periodo, reglasDemo, actuaciones, ajuste, importe, pagoFicticio. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Propuesta revisada; partidas trazables; no transferencia real.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F46_A01 | Generar propuesta | S37 | C | settlements.generateProposal | Genera propuesta desde actuaciones y reglas ficticias del periodo seleccionado. |
| F46_A02 | Ver detalle | S37 | V | settlements.showDetail | Muestra partidas, regla, base y ajustes de honorarios de la propuesta. |
| F46_A03 | Registrar ajuste | S37 | F | settlements.adjust | Registra ajuste justificado sin modificar actuaciones clínicas fuente. |
| F46_A04 | Aprobar liquidación | S37 | R | settlements.approve | Fija liquidación aprobada con importe y periodo revisados. |
| F46_A05 | Registrar pago | S37 | F | settlements.recordPaymentDemo | Registra pago ficticio de liquidación sin efectuar transferencia externa. |
| F46_A06 | Entregar detalle | S37 | X | settlements.deliverDetail | Genera detalle local de la liquidación y registra entrega de demo. |

**Salida del proceso:** Liquidación revisada y pago identificado o saldo pendiente.

### F47 · Solicitar, comprar y recibir productos

**Lote:** D06 · **Estado mock:** `purchasing` · **Contrato:** `F47_INPUT`.

**Campos del flujo:** solicitud, proveedorFicticio, productos, cantidades, orden, lote, vencimiento, discrepancia. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Aprobación antes de orden; recepción crea stock; diferencias explícitas.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F47_A01 | Nueva solicitud | S38 | F | purchasing.createRequest | Crea solicitud con productos, cantidades y motivo para aprobación. |
| F47_A02 | Aprobar compra | S38 | R | purchasing.approve | Aprueba compra revisada dentro del alcance demo y conserva solicitud fuente. |
| F47_A03 | Emitir orden | S38 | R | purchasing.issueOrder | Emite orden de compra ficticia con proveedor y condiciones de ejemplo. |
| F47_A04 | Registrar recepción | S38 | F | purchasing.receive | Registra recepción, lote, vencimiento y cantidades; crea entrada de stock. |
| F47_A05 | Registrar discrepancia | S38 | F | purchasing.recordDiscrepancy | Registra diferencia entre pedido y recepción sin forzar cumplimiento. |
| F47_A06 | Ver pendientes | S38 | N | purchasing.showPending | Abre solicitudes, órdenes y recepciones pendientes filtradas. |

**Salida del proceso:** Recepción trazable y cantidades pendientes explícitas.

### F48 · Mover, consumir, transferir o ajustar inventario

**Lote:** D06 · **Estado mock:** `inventory-movements` · **Contrato:** `F48_INPUT`.

**Campos del flujo:** producto, lote, origen, destino, cantidad, actuacion, motivo, aprobacion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No stock negativo por operación; transferencia y recepción idempotentes.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F48_A01 | Registrar consumo | S39 | F | inventory.consume | Registra consumo ligado a actuación o motivo y reduce lote disponible. |
| F48_A02 | Transferir stock | S39 | F | inventory.transfer | Prepara transferencia de cantidades entre almacenes y estado en tránsito. |
| F48_A03 | Confirmar recepción | S39 | R | inventory.confirmReceipt | Confirma recepción de transferencia y actualiza ambos almacenes una sola vez. |
| F48_A04 | Solicitar ajuste | S39 | F | inventory.requestAdjustment | Crea ajuste propuesto con cantidad, lote, evidencia ficticia y motivo. |
| F48_A05 | Aprobar ajuste | S39 | R | inventory.approveAdjustment | Aplica ajuste revisado y recalcula existencias con evento de trazabilidad. |
| F48_A06 | Registrar reverso | S39 | R | inventory.reverseMovement | Crea movimiento reverso permitido sin borrar historial ni crear stock duplicado. |

**Salida del proceso:** Stock trazable o movimiento en tránsito/revisión con responsable.

### F49 · Admitir paciente y asignar cama o jaula

**Lote:** D08 · **Estado mock:** `admissions-occupancy` · **Contrato:** `F49_INPUT`.

**Campos del flujo:** paciente, dominio, solicitud, recurso, unidad, intervalo, receptor. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Recurso compatible y libre; una ocupación activa; reservar no es admitir.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F49_A01 | Solicitar ingreso | S40 | F | admissions.request | Crea solicitud con paciente, indicación, dominio y necesidades de recurso. |
| F49_A02 | Ver plazas | S41 | V | occupancy.showPlaces | Muestra camas o jaulas compatibles y ocupaciones vigentes. |
| F49_A03 | Reservar plaza | S41 | R | occupancy.reserve | Reserva plaza compatible sin solapamiento de ocupación. |
| F49_A04 | Confirmar admisión | S40 | R | admissions.confirm | Crea estancia y ocupación activas para la solicitud revisada. |
| F49_A05 | Registrar recepción | S42 | F | admissions.recordReception | Registra recepción en unidad con responsable y comprobaciones de ejemplo. |
| F49_A06 | Cancelar solicitud | S40 | R | admissions.cancelRequest | Cancela solicitud o reserva permitida y libera recurso; conserva motivo. |

**Salida del proceso:** Estancia activa con ubicación y equipo responsable.

### F50 · Registrar cuidados, traslado y entrega de turno

**Lote:** D08 · **Estado mock:** `care-transfers-handover` · **Contrato:** `F50_INPUT`.

**Campos del flujo:** estancia, cuidado, orden, fecha, excepcion, destino, receptor, pendientes. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Estancia vigente; aceptación de entrega; excepción no completada.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F50_A01 | Registrar cuidado | S42 | F | care.record | Registra cuidado con fecha, actor, orden o propósito y observaciones. |
| F50_A02 | Registrar excepción | S42 | F | care.recordException | Conserva excepción y motivo, sin marcar cuidado completado. |
| F50_A03 | Preparar traslado | S42 | W | transfers.prepare | Prepara traslado con origen, destino, receptor y pendientes de la estancia. |
| F50_A04 | Preparar entrega de turno | S42 | W | handover.prepare | Construye resumen de turno con tareas, medicación y eventos registrados. |
| F50_A05 | Aceptar entrega | S42 | R | handover.accept | Registra aceptación por receptor demo y entrega de responsabilidades revisadas. |
| F50_A06 | Ver pendientes | S42 | N | care.showPending | Abre bandeja filtrada de cuidados, resultados y tareas de la estancia. |

**Salida del proceso:** Cuidados registrados y responsabilidad transferida solo con recepción confirmada.

### F51 · Recibir urgencia, reevaluar y decidir destino

**Lote:** D08 · **Estado mock:** `emergency` · **Contrato:** `F51_INPUT`.

**Campos del flujo:** identidadConocidaOTemporal, encuentro, clasificacionRegistrada, reevaluacion, destino. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No algoritmo clínico real; preservar identidad temporal y reevaluaciones.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F51_A01 | Registrar urgencia | S45 | F | emergency.register | Registra urgencia y encuentro con identidad conocida o temporal explícita. |
| F51_A02 | Registrar clasificación | S45 | F | emergency.classify | Captura clasificación realizada por profesional; no calcula prioridad clínica real. |
| F51_A03 | Añadir reevaluación | S45 | F | emergency.reevaluate | Añade reevaluación fechada sin reemplazar la inicial. |
| F51_A04 | Indicar destino | S45 | F | emergency.setDestination | Registra destino propuesto y sus requisitos de recepción. |
| F51_A05 | Confirmar transferencia | S45 | R | emergency.confirmTransfer | Confirma entrega al destino demo y actualiza estado sin duplicar estancia. |
| F51_A06 | Resolver identidad | S45 | F | emergency.resolveIdentity | Concilia identidad temporal con ficha revisada y preserva referencias originales. |

**Salida del proceso:** Destino registrado y transferencia confirmada o pendiente explícito.

### F52 · Proponer y programar un caso quirúrgico

**Lote:** D08 · **Estado mock:** `surgery-plans` · **Contrato:** `F52_INPUT`.

**Campos del flujo:** paciente, procedimiento, sitio, recursos, fecha, preparacion, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Revisar recursos y preparación; cambios conservan historia del caso.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F52_A01 | Proponer cirugía | S43 | F | surgery.propose | Crea propuesta quirúrgica con paciente, procedimiento y preparación prevista. |
| F52_A02 | Ver disponibilidad | S43 | V | surgery.showAvailability | Muestra salas, equipos y horarios ficticios compatibles y libres. |
| F52_A03 | Ver preparación | S43 | V | surgery.showPreparation | Muestra checklist, documentos y pendientes sin marcar verificaciones no realizadas. |
| F52_A04 | Programar caso | S43 | R | surgery.schedule | Programa caso revisado con recursos y fecha, evitando solapamientos. |
| F52_A05 | Reprogramar caso | S43 | F | surgery.reschedule | Captura nuevo horario y confirma cambio manteniendo historia del caso. |
| F52_A06 | Cancelar programación | S43 | R | surgery.cancelSchedule | Cancela programación con motivo y libera recursos futuros. |

**Salida del proceso:** Caso programado con tareas y responsables.

### F53 · Ejecutar procedimiento quirúrgico y cerrar parte

**Lote:** D08 · **Estado mock:** `operative-cases` · **Contrato:** `F53_INPUT`.

**Campos del flujo:** caso, verificaciones, procedimiento, implante, lote, muestra, interrupcion, parte. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Casos vigentes; no asumir verificaciones; cerrar con pendientes explícitos.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F53_A01 | Verificar caso | S43 | V | surgery.verifyCase | Muestra identidad, procedimiento, sitio, consentimiento y verificaciones registradas. |
| F53_A02 | Iniciar procedimiento | S43 | R | surgery.start | Inicia fase del procedimiento tras revisión de requisitos de demo. |
| F53_A03 | Registrar implante | S43 | F | surgery.recordImplant | Registra dispositivo, lote y ubicación vinculados al caso. |
| F53_A04 | Registrar muestra | S43 | F | surgery.recordSpecimen | Crea registro de muestra quirúrgica y su tarea de entrega. |
| F53_A05 | Registrar interrupción | S43 | F | surgery.recordInterruption | Registra interrupción, motivo y estado sin inventar cierre satisfactorio. |
| F53_A06 | Cerrar parte | S43 | R | surgery.closeReport | Fija parte de demo con actuaciones y pendientes de recuperación. |

**Salida del proceso:** Parte de lo realmente realizado conservado, con recuperación y pendientes.

### F54 · Registrar anestesia y recuperación

**Lote:** D08 · **Estado mock:** `anesthesia-recovery` · **Contrato:** `F54_INPUT`.

**Campos del flujo:** caso, evaluacion, observaciones, dosis, eventos, recuperacion, receptor. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Registro ficticio fechado; transición revisada; no recomendación automática.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F54_A01 | Registrar evaluación | S44 | F | anesthesia.evaluate | Captura evaluación preanestésica de ejemplo con autor y revisión. |
| F54_A02 | Iniciar registro | S44 | C | anesthesia.startRecord | Activa registro anestésico ligado al caso y reloj de demo. |
| F54_A03 | Añadir observación | S44 | F | anesthesia.addObservation | Añade medición u observación fechada a hoja y tendencia. |
| F54_A04 | Registrar administración | S44 | F | anesthesia.recordAdministration | Registra medicamento/dosis de ejemplo ligado a orden y fase. |
| F54_A05 | Registrar evento | S44 | F | anesthesia.recordEvent | Añade evento con instante, descripción y respuesta registrada. |
| F54_A06 | Confirmar salida de recuperación | S44 | R | anesthesia.confirmRecoveryExit | Cierra recuperación revisada con receptor y pendientes, sin recomendación automática. |

**Salida del proceso:** Registro anestésico/recuperación cerrado o activo con estado real.

### F55 · Preparar alta, egreso y seguimiento

**Lote:** D08 · **Estado mock:** `discharge` · **Contrato:** `F55_INPUT`.

**Campos del flujo:** estancia, resumen, medicacion, pendientes, responsables, entregas, control. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Alta y egreso diferenciados; liberar plaza al egreso confirmado.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F55_A01 | Preparar alta | S42 | W | discharge.prepare | Abre preparación de alta con resumen, medicación, entregas y pendientes. |
| F55_A02 | Asignar pendientes | S42 | F | discharge.assignPending | Asigna cada pendiente a responsable y plazo antes del egreso. |
| F55_A03 | Emitir resumen | S28 | R | discharge.issueSummary | Emite resumen de alta demo versionado y ligado a la estancia. |
| F55_A04 | Registrar entrega | S42 | F | discharge.recordDelivery | Registra destinatario, documento y canal de entrega simulada. |
| F55_A05 | Confirmar egreso | S40 | R | discharge.confirmExit | Cierra estancia, libera recurso y conserva tareas de seguimiento asignadas. |
| F55_A06 | Programar control | S33 | F | discharge.scheduleControl | Crea seguimiento o cita propuesta posterior al egreso. |

**Salida del proceso:** Egreso documentado y seguimiento conservado; caja no determina el estado clínico.

### F56 · Planificar y registrar curso de sesiones especializadas

**Lote:** D08 · **Estado mock:** `specialized-courses` · **Contrato:** `F56_INPUT`.

**Campos del flujo:** perfil, curso, planVersion, sesiones, recursos, actuacion, interrupcion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Sesión ligada a plan vigente al realizarla; conservar versiones.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F56_A01 | Crear curso | S46 | F | courses.create | Crea curso de sesiones con perfil, propósito y plan inicial. |
| F56_A02 | Versionar plan | S46 | F | courses.versionPlan | Crea nueva versión del plan conservando sesiones vinculadas a su versión anterior. |
| F56_A03 | Programar sesión | S46 | F | courses.scheduleSession | Reserva sesión y recursos compatibles con el plan seleccionado. |
| F56_A04 | Registrar sesión | S46 | F | courses.recordSession | Registra sesión realizada, observaciones y relación con el plan de demo. |
| F56_A05 | Registrar interrupción | S46 | F | courses.recordInterruption | Registra interrupción con motivo y decisiones de continuidad capturadas. |
| F56_A06 | Cerrar curso | S46 | R | courses.close | Cierra curso con resumen y seguimiento preservando cada sesión. |

**Salida del proceso:** Curso y sesiones trazables; ningún cálculo o protocolo se presume implementado.

### F57 · Gestionar componente sanguíneo y transfusión

**Lote:** D08 · **Estado mock:** `blood-transfusion-demo` · **Contrato:** `F57_INPUT`.

**Campos del flujo:** solicitud, componente, unidad, lote, verificacionesDemo, eventos, destino. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Solo trazabilidad de ejemplo; no certificación clínica de compatibilidad.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F57_A01 | Solicitar componente | S46 | F | transfusion.request | Crea solicitud de componente con paciente, indicación registrada y trazabilidad. |
| F57_A02 | Revisar verificaciones | S46 | V | transfusion.reviewChecks | Muestra verificaciones ficticias de unidad/paciente; no certifica compatibilidad real. |
| F57_A03 | Registrar entrega | S46 | F | transfusion.recordDelivery | Registra unidad, lote, entrega y receptor en cadena de eventos. |
| F57_A04 | Registrar actuación | S46 | F | transfusion.recordActuation | Captura actuación con inicio/fin y verificaciones registradas por usuario demo. |
| F57_A05 | Registrar evento | S46 | F | transfusion.recordEvent | Registra evento y respuesta sin generar indicaciones clínicas automáticas. |
| F57_A06 | Conciliar unidad | S46 | R | transfusion.reconcileUnit | Concilia unidad y destino final, conservando cantidades y eventos. |

**Salida del proceso:** Solicitud, unidad y evento vinculados con trazabilidad.

### F58 · Gestionar episodio de trasplante

**Lote:** D08 · **Estado mock:** `transplant-episodes` · **Contrato:** `F58_INPUT`.

**Campos del flujo:** episodio, participantes, evaluacion, requisitosDemo, etapa, actuacion, seguimiento. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Proceso y requisitos ficticios; no cálculo de elegibilidad clínica.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F58_A01 | Crear episodio especializado | S46 | F | transplant.createEpisode | Crea episodio especializado con participantes y etapas ficticias. |
| F58_A02 | Registrar evaluación | S46 | F | transplant.evaluate | Registra evaluación fechada dentro del episodio. |
| F58_A03 | Ver requisitos | S46 | V | transplant.showRequirements | Muestra checklist y pendientes del ejemplo sin afirmar elegibilidad clínica. |
| F58_A04 | Coordinar etapa | S46 | F | transplant.coordinateStage | Coordina etapa con responsables, recursos y fecha. |
| F58_A05 | Registrar actuación | S46 | F | transplant.recordActuation | Registra actuación ligada al episodio y su etapa. |
| F58_A06 | Programar seguimiento | S46 | F | transplant.scheduleFollowup | Crea controles y tareas de seguimiento enlazados al episodio. |

**Salida del proceso:** Etapa del episodio documentada sin asumir decisiones clínicas o asignación automática.

### F59 · Gestionar ciclo reproductivo y muestras vinculadas

**Lote:** D08 · **Estado mock:** `reproductive-cycles` · **Contrato:** `F59_INPUT`.

**Campos del flujo:** ciclo, dominio, participantes, relaciones, muestras, custodia, etapa, motivo. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Dominio humano/animal explícito; cadena de custodia; suspensión conserva registro.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F59_A01 | Crear ciclo | S46 | F | reproduction.createCycle | Crea ciclo humano o animal según perfil y participantes autorizados. |
| F59_A02 | Vincular participantes | S46 | F | reproduction.linkParticipants | Vincula participantes y relaciones con alcance y vigencia explícitos. |
| F59_A03 | Registrar custodia | S46 | F | reproduction.recordCustody | Registra muestra, identificador, entrega y receptor de custodia ficticia. |
| F59_A04 | Revisar etapa | S46 | V | reproduction.reviewStage | Muestra etapa, documentos, requisitos y estados del ciclo. |
| F59_A05 | Registrar actuación | S46 | F | reproduction.recordActuation | Registra actuación vinculada a etapa, participantes y muestras correspondientes. |
| F59_A06 | Suspender ciclo | S46 | R | reproduction.suspend | Suspende ciclo con motivo y tratamiento explícito de pendientes y custodia. |

**Salida del proceso:** Etapas y sujetos vinculados sin fusionar identidades ni historiales.

### F60 · Registrar intervención sanitaria poblacional veterinaria

**Lote:** D08 · **Estado mock:** `veterinary-population-health` · **Contrato:** `F60_INPUT`.

**Campos del flujo:** poblacion, fecha, denominador, criterios, actuacion, excepciones, informe. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Pertenencias al momento del evento; individuo y grupo diferenciados.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F60_A01 | Crear intervención | S47 | F | populationHealth.createIntervention | Crea intervención veterinaria con población, fecha y propósito. |
| F60_A02 | Seleccionar población | S47 | S | populationHealth.choosePopulation | Selecciona población y pertenencias válidas al momento del evento. |
| F60_A03 | Registrar denominador | S47 | F | populationHealth.recordDenominator | Captura denominador, criterios y fuente del conjunto intervenido. |
| F60_A04 | Registrar actuación grupal | S47 | F | populationHealth.recordActuation | Registra actuación grupal y excepciones por individuo cuando corresponda. |
| F60_A05 | Emitir informe poblacional | S47 | R | populationHealth.issueReport | Emite informe demo con denominador, cobertura, eventos y procedencia. |
| F60_A06 | Crear seguimiento | S47 | F | populationHealth.createFollowup | Crea seguimiento de población y responsables sin reemplazar historias individuales. |

**Salida del proceso:** Intervención trazable con datos colectivos separados de individuos.

### F61 · Dictar y revisar un borrador asistido por IA

**Lote:** D04 · **Estado mock:** `dictation-demo` · **Contrato:** `F61_INPUT`.

**Campos del flujo:** audioPreparado, transcripcionFicticia, fragmentos, borrador. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Sin envío de audio ni inferencia real; revisión humana antes de copiar.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F61_A01 | Iniciar dictado | S18 | J | dictation.startDemo | Activa reproductor de dictado preparado; no envía audio ni requiere micrófono real. |
| F61_A02 | Detener dictado | S18 | C | dictation.stopDemo | Detiene secuencia simulada y presenta transcripción ficticia pendiente de revisión. |
| F61_A03 | Revisar transcripción | S18 | V | dictation.reviewTranscript | Muestra texto propuesto y permite seleccionar fragmentos con contexto. |
| F61_A04 | Aceptar selección | S18 | C | dictation.acceptSelection | Copia solo fragmentos revisados al borrador, sin firmar ni finalizar visita. |
| F61_A05 | Descartar propuesta | S18 | R | dictation.discardProposal | Descarta propuesta de IA demo y conserva la nota previa. |

**Salida del proceso:** Borrador revisado por profesional; sin firma automática ni datos inventados incorporados.

### F62 · Ejecutar integración y resolver fallos

**Lote:** D09 · **Estado mock:** `integration-jobs` · **Contrato:** `F62_INPUT`.

**Campos del flujo:** conexion, trabajo, operationId, payloadFicticio, estado, error, resolucion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Reintento sobre mismo trabajo; no duplicar efectos de negocio.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F62_A01 | Ver integración | S54 | V | integrations.show | Muestra conexión demo, alcance y trabajos de esa integración. |
| F62_A02 | Ver tarea fallida | S54 | V | integrations.showFailure | Muestra fallo preparado, payload ficticio resumido y operación afectada. |
| F62_A03 | Reintentar operación | S54 | J | integrations.retry | Reintenta el mismo trabajo simulado con ID de operación y sin duplicar su efecto. |
| F62_A04 | Resolver discrepancia | S54 | F | integrations.resolveDiscrepancy | Registra resolución explícita de diferencias entre estados ficticios. |
| F62_A05 | Desconectar integración | S54 | R | integrations.disconnect | Desactiva conexión demo, conserva evidencia y explica trabajos pendientes. |

**Salida del proceso:** Estado externo conciliado o pendiente asignado; no deshacer atención por fallo de notificación.

### F63 · Gestionar reserva asistida y cobro anticipado

**Lote:** D06 · **Estado mock:** `assisted-booking-demo` · **Contrato:** `F63_INPUT`.

**Campos del flujo:** solicitud, paciente, horario, condiciones, anticipoFicticio, resultado, tarea. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Propuesta no confirmada; sin tarjeta real; resolución o entrega a recepción.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F63_A01 | Revisar solicitud asistida | S15 | V | assistedBooking.review | Muestra solicitud asistida ficticia y distingue propuesta de cita confirmada. |
| F63_A02 | Continuar reserva | S30 | W | assistedBooking.continue | Reanuda captura de reserva con paciente, disponibilidad y propuesta revisados. |
| F63_A03 | Ver condiciones | S30 | V | assistedBooking.showTerms | Muestra condiciones ficticias de anticipo, cancelación y responsable de pago. |
| F63_A04 | Pagar anticipo | S30, S29 | R | assistedBooking.payAdvanceDemo | Registra anticipo ficticio y resultado de pasarela demo sin datos de tarjeta reales. |
| F63_A05 | Derivar a recepción | S15 | F | assistedBooking.handoffReception | Crea tarea de recepción con captura y motivo cuando la propuesta no se resuelve. |

**Salida del proceso:** Reserva/pago trazables; canal asistido no accede a historia interna.

### F64 · Importar o exportar datos de una organización

**Lote:** D09 · **Estado mock:** `local-import-export` · **Contrato:** `F64_INPUT`.

**Campos del flujo:** archivoFicticio, formato, esquema, filas, errores, lote, contenido, manifiesto. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Validar antes de aplicar; lote idempotente; solo descargas locales.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F64_A01 | Nueva importación | S48 | W | data.beginImport | Abre importación local de CSV/JSON ficticio con origen y esquema de ejemplo. |
| F64_A02 | Seleccionar formato | S48 | S | data.chooseFormat | Selecciona formato y muestra columnas, límites y archivo ficticio descargable. |
| F64_A03 | Ver vista previa | S48 | V | data.previewImport | Analiza archivo local y muestra filas válidas, errores y coincidencias sin aplicar cambios. |
| F64_A04 | Confirmar lote | S48 | R | data.commitBatch | Aplica filas válidas revisadas una sola vez, guarda resumen y rechazos por fila. |
| F64_A05 | Solicitar exportación | S48 | W | data.prepareExport | Prepara exportación local con contexto, contenido y manifiesto revisados. |
| F64_A06 | Descargar manifiesto | S48 | X | data.downloadManifest | Descarga manifiesto y paquete ficticio autorizado de esa exportación. |

**Salida del proceso:** Lote reconciliado o exportación auditable, incluyendo versiones/documentos y unidades.

### F65 · Consultar reportes y auditar acceso o cambios

**Lote:** D09 · **Estado mock:** `reports-demo-audit` · **Contrato:** `F65_INPUT`.

**Campos del flujo:** reporte, definicion, periodo, filtros, ambito, eventos, formato. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Reporte derivado del ámbito permitido; exportar lo filtrado; no auditoría forense real.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F65_A01 | Ver reporte | S49 | N | reports.open | Abre reporte elegido con definición, filtros, periodo y datos derivados del store. |
| F65_A02 | Aplicar filtros | S49 | I | reports.filter | Recalcula filas y métricas con filtros del ámbito permitido de demo. |
| F65_A03 | Ver definición | S49 | V | reports.showDefinition | Muestra fórmula de reporte, unidad, fuente y fecha de actualización del ejemplo. |
| F65_A04 | Inspeccionar evento | S50 | V | audit.inspectEvent | Muestra actor demo, contexto, acción y referencias del evento seleccionado. |
| F65_A05 | Exportar autorizado | S49, S50 | X | reports.export | Descarga CSV/JSON local del conjunto filtrado y registra exportación demo. |

**Salida del proceso:** Reporte/evidencia consultado con trazabilidad y alcance explícito.

### F66 · Solicitar soporte y conceder acceso temporal

**Lote:** D09 · **Estado mock:** `support-access` · **Contrato:** `F66_INPUT`.

**Campos del flujo:** caso, evidenciaFicticia, finalidad, datos, operador, vencimiento, decision. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Concesión explícita, limitada y revocable; cerrar revoca acceso del caso.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F66_A01 | Crear caso | S51 | F | support.createCase | Crea caso técnico ficticio con propósito y alcance del problema. |
| F66_A02 | Añadir evidencia | S51 | F | support.addEvidence | Adjunta evidencia local ficticia al caso sin abrir acceso clínico automático. |
| F66_A03 | Autorizar acceso temporal | S51 | R | support.authorizeTemporaryAccess | Concede acceso demo al caso con finalidad, datos, actor y vencimiento explícitos. |
| F66_A04 | Rechazar acceso | S51 | R | support.rejectAccess | Rechaza solicitud y mantiene datos fuera del alcance del operador demo. |
| F66_A05 | Ver actividad | S51 | V | support.showActivity | Muestra eventos del caso y de cualquier concesión temporal de demo. |
| F66_A06 | Cerrar caso | S51 | R | support.closeCase | Cierra caso, revoca concesión vinculada y conserva evidencia y resolución. |

**Salida del proceso:** Caso resuelto o pendiente; acceso excepcional terminado y auditado.

### F67 · Gestionar plan, consumo y suscripción SaaS

**Lote:** D09 · **Estado mock:** `subscription-demo` · **Contrato:** `F67_INPUT`.

**Campos del flujo:** plan, periodo, consumoFicticio, propuesta, condiciones, pagoFicticio. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Contratación y cobro simulados; revisar vigencia e importe.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F67_A01 | Ver plan | S51 | V | subscription.showPlan | Muestra plan ficticio vigente, condiciones y capacidades del espacio. |
| F67_A02 | Ver consumo | S51 | V | subscription.showUsage | Muestra consumo de ejemplo por periodo y recurso con definición de límites. |
| F67_A03 | Solicitar cambio | S51 | F | subscription.requestChange | Crea propuesta de cambio de plan con estado pendiente de revisión. |
| F67_A04 | Revisar condiciones | S51 | V | subscription.reviewTerms | Muestra importe ficticio, vigencia, condiciones y efecto del cambio. |
| F67_A05 | Confirmar contratación | S51 | R | subscription.confirmDemo | Activa contratación de demo y trabajo de pago simulado sin cobro externo. |
| F67_A06 | Ver estado de pago | S51 | V | subscription.showPaymentState | Muestra pago de suscripción ficticio y resultado preparado de su trabajo. |

**Salida del proceso:** Plan y derechos trazables; factura SaaS separada de comprobantes de la clínica.

### F68 · Dar de baja organización y entregar sus datos

**Lote:** D09 · **Estado mock:** `offboarding-demo` · **Contrato:** `F68_INPUT`.

**Campos del flujo:** organizacion, motivo, fecha, impacto, paquete, recepcion, conservacion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Confirmar entrega y cierre; no eliminación silenciosa de datos.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F68_A01 | Solicitar baja | S51 | W | offboarding.request | Abre baja guiada con motivo, fecha y entregables de datos de demo. |
| F68_A02 | Ver impacto | S51 | V | offboarding.showImpact | Muestra accesos, actividad, pendientes y conservación previstos para el espacio. |
| F68_A03 | Preparar entrega | S51 | W | offboarding.prepareDelivery | Prepara paquete local y manifiesto de entrega con contenido revisado. |
| F68_A04 | Confirmar recepción | S51 | R | offboarding.confirmReceipt | Registra recepción ficticia del paquete y evidencia de ejemplo. |
| F68_A05 | Confirmar cierre | S51 | R | offboarding.close | Cierra organización en el escenario demo según revisión, sin eliminación silenciosa. |
| F68_A06 | Cancelar solicitud | S51 | R | offboarding.cancelRequest | Cancela proceso de baja pendiente y conserva el estado previo del espacio. |

**Salida del proceso:** Salida documentada con datos entregados y política de conservación aplicada.

### F69 · Gestionar incidente y comprobar recuperación

**Lote:** D09 · **Estado mock:** `incidents-recovery-demo` · **Contrato:** `F69_INPUT`.

**Campos del flujo:** incidente, ambito, impacto, recuperacion, evidenciaFicticia, tareas. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Escenario ficticio; retorno revisado; pendientes posteriores con responsable.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F69_A01 | Registrar incidente | S52 | F | incidents.register | Crea incidente ficticio con alcance, inicio y responsables. |
| F69_A02 | Ver impacto | S52 | V | incidents.showImpact | Muestra servicios, espacios y tareas afectados por el escenario preparado. |
| F69_A03 | Registrar recuperación | S52 | F | incidents.recordRecovery | Registra acciones de recuperación simulada, tiempos y resultados capturados. |
| F69_A04 | Adjuntar evidencia | S52 | F | incidents.attachEvidence | Añade evidencia local de ejemplo a la comprobación de recuperación. |
| F69_A05 | Confirmar retorno | S52 | R | incidents.confirmReturn | Marca retorno revisado del servicio demo y conserva pendientes posteriores. |
| F69_A06 | Crear acción pendiente | S52 | F | incidents.createTask | Crea acción correctiva con responsable, fecha y vínculo al incidente. |

**Salida del proceso:** Operación recuperada con evidencia o incidente activo; no inferir recuperación por existir backup.

### F70 · Ingresar al portal de paciente o responsable

**Lote:** D02 · **Estado mock:** `portal-session` · **Contrato:** `F70_INPUT`.

**Campos del flujo:** personaFicticia, invitacion, vinculo, paciente, organizacion. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Solo vínculos vigentes; volver a consultar contenido al cambiar selección.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F70_A01 | Ingresar al portal | S02 | A | portal.loginDemo | Inicia sesión ficticia de paciente o responsable y muestra vínculos autorizados. |
| F70_A02 | Completar invitación | S02 | W | portal.completeInvitation | Completa invitación demo con identidad, relación y alcance preparados. |
| F70_A03 | Elegir paciente | S29 | S | portal.choosePatient | Selecciona humano o animal de un vínculo vigente sin mezclar sus documentos. |
| F70_A04 | Elegir organización | S29 | S | portal.chooseOrganization | Cambia organización del vínculo y vuelve a consultar contenido publicado para ella. |
| F70_A05 | Ver mis citas | S29 | N | portal.showAppointments | Abre citas del paciente y organización seleccionados. |

**Salida del proceso:** Portal abierto bajo vínculo y contexto verificables; login externo no exige RUC del paciente.

### F71 · Consultar y descargar contenido publicado

**Lote:** D05 · **Estado mock:** `portal-reading` · **Contrato:** `F71_INPUT`.

**Campos del flujo:** publicacion, documentoVersion, vinculo, emisor, archivoFicticio. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Lectura de versión publicada accesible; registrar descarga de demo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F71_A01 | Ver documento | S31 | V | portal.viewDocument | Muestra exclusivamente la revisión publicada accesible por vínculo demo vigente. |
| F71_A02 | Ver versión actual | S31 | V | portal.viewCurrentVersion | Muestra versión publicada actual y su relación con versiones retiradas o corregidas. |
| F71_A03 | Descargar documento | S31 | X | portal.downloadDocument | Descarga archivo o documento HTML local de la versión publicada y registra evento demo. |
| F71_A04 | Ver emisor | S31 | V | portal.showIssuer | Muestra emisor, organización custodio y profesional de la publicación. |

**Salida del proceso:** Contenido entregado al destinatario permitido, sin acceso a notas internas por defecto.

### F72 · Utilizar componente gráfico especializado

**Lote:** D04 · **Estado mock:** `specialty-renderers` · **Contrato:** `F72_INPUT`.

**Campos del flujo:** perfil, componente, estructura, atlasVersion, esquemaVersion, registro, visitas. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Componente adecuado; tabla equivalente; comparación de variantes compatibles.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F72_A01 | Abrir componente | S18 | S | specialty.openComponent | Activa componente requerido del perfil con esquema, atlas y fixture adecuados. |
| F72_A02 | Elegir estructura | S18 | G | specialty.chooseStructure | Selecciona estructura semántica compatible con órgano, especie y vista. |
| F72_A03 | Añadir registro | S18 | F | specialty.addRecord | Captura registro especializado con contexto, unidad y campos propios del perfil. |
| F72_A04 | Ver tabla equivalente | S18 | S | specialty.showEquivalentTable | Muestra los mismos registros del gráfico en una tabla accesible. |
| F72_A05 | Comparar visitas | S18 | V | specialty.compareVisits | Compara visitas y componentes compatibles conservando versiones de esquema y atlas. |
| F72_A06 | Revisar cambios | S18 | V | specialty.reviewChanges | Presenta diferencia de registros especializados antes del guardado de la revisión. |

**Salida del proceso:** Datos especializados persistibles y reproducibles; interacción particular documentada por familia.

### F73 · Conectar o revocar proveedor externo

**Lote:** D09 · **Estado mock:** `connections-demo` · **Contrato:** `F73_INPUT`.

**Campos del flujo:** proveedor, finalidad, alcance, permisosDemo, prueba, trabajos. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Sin OAuth real; activación revisada y revocación conserva evidencia.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F73_A01 | Conectar proveedor | S54 | W | connections.connectDemo | Abre conexión ficticia con proveedor, finalidad y alcance; no realiza OAuth real. |
| F73_A02 | Revisar permisos | S54 | V | connections.reviewPermissions | Muestra datos y operaciones propuestos para el proveedor de demo. |
| F73_A03 | Probar conexión | S54 | J | connections.testDemo | Ejecuta trabajo de prueba con resultado preparado, latencia y error seleccionables. |
| F73_A04 | Activar integración | S54 | R | connections.activateDemo | Activa conexión simulada y habilita sus trabajos en el espacio elegido. |
| F73_A05 | Revocar conexión | S54 | R | connections.revokeDemo | Revoca conexión de demo y conserva historial y trabajos que requieren resolución. |

**Salida del proceso:** Integración conectada con alcance explícito o revocada con pendientes gestionados.

### F74 · Actualizar cuenta, canales y preferencias

**Lote:** D02 · **Estado mock:** `account-preferences` · **Contrato:** `F74_INPUT`.

**Campos del flujo:** usuarioFicticio, datos, canalFicticio, codigoDemo, preferencias, sesiones. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No credenciales reales; canal pendiente hasta comprobación de demo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F74_A01 | Editar cuenta | S53 | F | account.edit | Edita datos ficticios de cuenta, idioma y preferencias del usuario demo. |
| F74_A02 | Cambiar canal | S53 | F | account.changeChannel | Captura nuevo canal ficticio y lo mantiene pendiente de verificación. |
| F74_A03 | Verificar nuevo canal | S53 | J | account.verifyChannelDemo | Muestra código preparado y registra verificación simulada sin enviar mensajes reales. |
| F74_A04 | Guardar preferencias | S53 | C | account.savePreferences | Guarda preferencias y actualiza vistas de cuenta y avisos de demo. |
| F74_A05 | Revisar sesiones | S53 | V | account.reviewSessions | Muestra sesiones ficticias, contexto y estado de la sesión actual. |

**Salida del proceso:** Preferencias/canal confirmados; cuenta y filiación clínica permanecen conceptos diferentes.

### F75 · Configurar servicios, tarifas y emisión documental

**Lote:** D06 · **Estado mock:** `services-pricing-issuers` · **Contrato:** `F75_INPUT`.

**Campos del flujo:** servicio, dominio, duracion, recursos, tarifa, moneda, emisor, vigencia. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Importes/versiones válidos; nueva configuración no modifica usos históricos.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F75_A01 | Crear servicio | S07 | F | services.create | Crea servicio con dominio, duración, especialidad y recursos de ejemplo. |
| F75_A02 | Crear tarifa | S07 | F | pricing.create | Crea tarifa con importe en unidades menores, moneda y vigencia. |
| F75_A03 | Editar emisor | S07 | F | issuers.edit | Edita emisor ficticio y datos mostrados en documentos de demo. |
| F75_A04 | Definir vigencia | S07 | F | services.setValidity | Define vigencia en el borrador de servicio, tarifa o emisor elegido. |
| F75_A05 | Ver impacto | S07 | V | services.previewImpact | Muestra agenda, documentos y presupuestos afectados por la configuración propuesta. |
| F75_A06 | Publicar configuración | S07 | R | services.publish | Publica configuración para operaciones nuevas conservando versiones usadas antes. |

**Salida del proceso:** Configuración versionada para operaciones nuevas.

### F76 · Registrar vacunación y control preventivo

**Lote:** D04 · **Estado mock:** `preventive-events` · **Contrato:** `F76_INPUT`.

**Campos del flujo:** paciente, dominio, actuacion, producto, lote, fecha, estado, motivo, control. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Realizada y no realizada distintas; fecha de control registrada por usuario.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F76_A01 | Ver historial preventivo | S18, S19 | V | prevention.showHistory | Muestra actuaciones y excepciones preventivas según dominio y paciente. |
| F76_A02 | Registrar actuación preventiva | S18 | F | prevention.recordActuation | Registra actuación con producto/lote cuando corresponda, fecha y profesional. |
| F76_A03 | Registrar no realizada | S18 | F | prevention.recordNotDone | Registra no realizada con motivo sin marcar protección o actuación completada. |
| F76_A04 | Emitir constancia | S28 | R | prevention.issueCertificate | Emite constancia ficticia versionada y lista para entrega revisada. |
| F76_A05 | Programar próximo control | S18 | F | prevention.scheduleControl | Crea control propuesto según fecha registrada, sin recomendación clínica automática. |

**Salida del proceso:** Evento preventivo trazable y seguimiento/documento definidos.

### F77 · Gestionar convenio, autorización de pagador y saldo institucional

**Lote:** D06 · **Estado mock:** `payer-agreements-demo` · **Contrato:** `F77_INPUT`.

**Campos del flujo:** convenio, paciente, servicio, coberturaFicticia, autorizacion, respuesta, pagador, importe. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No consulta real a aseguradora; condiciones y saldo institucional explícitos.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F77_A01 | Crear convenio | S07 | F | payers.createAgreement | Crea convenio ficticio con partes, servicios, reglas y vigencia. |
| F77_A02 | Verificar cobertura registrada | S07 | V | payers.checkRecordedCoverage | Muestra cobertura registrada del ejemplo; no consulta aseguradora real. |
| F77_A03 | Solicitar autorización | S35 | F | payers.requestAuthorizationDemo | Crea solicitud y trabajo simulado ligado a servicio, convenio y paciente. |
| F77_A04 | Registrar respuesta | S07 | F | payers.recordResponse | Registra respuesta preparada con condiciones y estado de autorización. |
| F77_A05 | Asignar pagador | S07 | F | payers.assign | Asigna pagador y distribución de importe revisados en la cuenta seleccionada. |
| F77_A06 | Ver saldo institucional | S07 | N | payers.showBalance | Abre saldo institucional derivado de cargos, asignaciones y pagos ficticios. |

**Salida del proceso:** Responsabilidad económica y autorización registradas con seguimiento.

### F78 · Ingresar a la consola de operación MAVRIC

**Lote:** D02 · **Estado mock:** `operator-session` · **Contrato:** `F78_INPUT`.

**Campos del flujo:** operadorFicticio, codigoDemo, caso, alcance. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** Acceso consola separado; datos de caso según concesión y función demo.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F78_A01 | Ingresar a consola | S56 | A | operations.loginDemo | Inicia acceso ficticio a consola separado del contexto clínico profesional. |
| F78_A02 | Completar comprobación | S56 | C | operations.completeCheckDemo | Completa comprobación preparada y habilita el rol operador en la consola. |
| F78_A03 | Abrir caso operativo | S52 | N | operations.openCase | Abre caso operativo permitido y solo datos incluidos en su alcance demo. |

**Salida del proceso:** Operador autenticado en consola técnica; datos clínicos requieren autorización excepcional aparte.

### F79 · Cerrar sesión con trabajo pendiente

**Lote:** D02 · **Estado mock:** `logout` · **Contrato:** `F79_INPUT`.

**Campos del flujo:** sesion, borradores, trabajosPendientes, decisionSalida. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.

**Regla:** No pérdida silenciosa; guardar válido antes de salir; descarte solo local.

| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |
|---|---|---|---|---|---|
| F79_A01 | Cerrar sesión | S53, S03, S29, S52 | R | identity.reviewLogout | Revisa borradores y operaciones pendientes antes de terminar sesión demo. |
| F79_A02 | Guardar y salir | S53 | R | identity.saveAndLogout | Guarda borradores válidos, termina sesión y vuelve al acceso correspondiente. |
| F79_A03 | Descartar cambios locales y salir | S53 | R | identity.discardAndLogout | Descarta solo cambios locales tras revisión y termina sesión ficticia. |
| F79_A04 | Seguir trabajando | S53 | L | identity.keepWorking | Cierra revisión de salida y restaura foco en el trabajo actual. |

**Salida del proceso:** Sesión cerrada; trabajo confirmado conservado y vista clínica retirada.

## Controles comunes adicionales

| ID | Control | Patrón | Resultado previsto |
|---|---|---|---|
| UX01 | Elegir blanco | SELECT_CONTROL | Cambia todos los tokens a light y persiste la preferencia. |
| UX02 | Elegir negro | SELECT_CONTROL | Cambia todos los tokens a dark y persiste la preferencia. |
| UX03 | Elegir navy | SELECT_CONTROL | Cambia tokens a navy y activa color-scheme oscuro. |
| UX04 | Colapsar navegación | COMMAND_STATE | Alterna sidebar amplia e iconos y conserva nombres accesibles. |
| UX05 | Abrir navegación móvil | FORM_SHEET_RIGHT | Abre menú desde la derecha con foco contenido y backdrop. |
| UX06 | Buscar globalmente | FORM_SHEET_RIGHT | Busca entidades permitidas del contexto y navega al ID seleccionado. |
| UX07 | Abrir notificaciones | DETAIL_SHEET_RIGHT | Muestra avisos ficticios propios y enlaces a su objeto. |
| UX08 | Marcar aviso leído | COMMAND_STATE | Actualiza lectura y contador de la persona demo. |
| UX09 | Cambiar rol de demo | REVIEW_SHEET_RIGHT | Resuelve borrador y cambia identidad/rol preparado conservando datos de escenario. |
| UX10 | Elegir escenario | REVIEW_SHEET_RIGHT | Carga escenario y fecha preparados después de revisar reinicio. |
| UX11 | Reiniciar demo | REVIEW_SHEET_RIGHT | Restaura fixtures, trabajos, borradores y reloj del escenario de forma completa. |
| UX12 | Preparar fallo simulado | SELECT_CONTROL | Activa un error determinista de agenda, guardado, integración o recurso. |
| UX13 | Cerrar panel | CLOSE_OR_RETURN | Cierra Sheet o muestra decisión si hay captura pendiente; restaura foco. |
| UX14 | Volver al paso anterior | COMMAND_STATE | Retrocede en el mismo panel conservando valores y selección. |
| UX15 | Continuar paso | COMMAND_STATE | Valida los campos del paso y avanza sin confirmar negocio prematuramente. |
| UX16 | Confirmar revisión del panel | COMMAND_STATE | Ejecuta el comando asociado al ID de negocio revisado, una sola vez. |
| UX17 | Guardar captura del panel | COMMAND_STATE | Valida y llama la acción de guardado o el comando asociado al flujo; no crea operación genérica sin contrato. |
| UX18 | Cancelar captura | CLOSE_OR_RETURN | Abandona captura tras resolver cambios locales y deja entidades confirmadas intactas. |
| UX19 | Seguir editando | CLOSE_OR_RETURN | Vuelve de la revisión de salida a los valores ya capturados. |
| UX20 | Descartar cambios locales | REVIEW_SHEET_RIGHT | Descarta borrador seleccionado y conserva versiones ya confirmadas. |
| UX21 | Guardar borrador desde salida | COMMAND_STATE | Guarda por la acción de negocio correspondiente antes de volver o cerrar. |
| UX22 | Ordenar, filtrar y paginar tabla | FILTER_INLINE | Cambia conjunto visible con filtros combinables y conserva el ámbito permitido. |
| UX23 | Cambiar pestaña o sección | SELECT_CONTROL | Activa sección válida sin perder contexto ni captura local. |
| UX24 | Cambiar densidad | SELECT_CONTROL | Alterna espaciado de tabla sin ocultar información esencial. |
| UX25 | Abrir acciones de fila | SELECT_CONTROL | Muestra acciones del registro con disponibilidad y motivo por ID. |
| UX26 | Limpiar filtros | FILTER_INLINE | Restaura filtros del área y vuelve a la primera página. |
| UX27 | Zoom y ajuste de gráfico | GRAPH_CONTROL | Ajusta vista del gráfico sin modificar anotaciones; permite reset de vista. |
| UX28 | Mostrar leyenda y tabla accesible | DETAIL_SHEET_RIGHT | Presenta significados, unidades y registros equivalentes del componente. |
| UX29 | Vista de impresión | PRINT_CLIENT | Abre formato blanco del documento o tabla ficticios seleccionados. |
| UX30 | Reintentar carga de pantalla | MOCK_JOB | Reejecuta consulta demo conservando contexto y filtros y sin duplicar comandos. |
| UX31 | Descargar archivo ficticio de ejemplo | EXPORT_LOCAL | Descarga plantilla CSV/JSON o documento local rotulado para demostración. |
| UX32 | Restablecer reloj de escenario | REVIEW_SHEET_RIGHT | Vuelve a la fecha preparada y revisa cualquier reinicio relacionado. |

## Familias y perfiles gráficos

Los 241 perfiles mantienen la relación con todos sus componentes del catálogo; su lista completa está en el plan JSON y en [Gráficos de especialidad](../diseno/04_Graficos_de_Especialidad.md). Los 31 contratos siguientes no son una reducción a 31 pantallas idénticas: cada familia tiene variantes requeridas por perfil.

| Familia | Nombre | Renderizador previsto |
|---|---|---|
| FORM | Formularios clínicos versionados | Formulario dinámico contra esquema versionado; no reemplaza el gráfico requerido. |
| ANATOMY | Mapas anatómicos versionados | Atlas SVG por órgano/especie con estructura, lateralidad, selección y anotación semántica. |
| HUMAN_DENTAL | Odontograma humano por pieza y cara | Dentición humana temporal/permanente/mixta con pieza/cara, condición y procedimiento. |
| VET_DENTAL | Odontograma veterinario por especie | Atlas dental por especie y dentición con nomenclatura propia de cada perfil. |
| PERIODONTAL | Periodontograma y tejidos de soporte | Cuadrícula y dibujo por sitio con mediciones, unidad y comparación por diente. |
| ENDO | Raíces y conductos dentales | Raíces y conductos con registros por estructura y procedimiento. |
| ORTHODONTIC | Ortodoncia, oclusión y cefalometría | Oclusión y cefalometría de ejemplo con puntos/medidas y versiones. |
| PROSTHETIC | Prótesis, implantes y trabajos de laboratorio | Mapa de piezas, dispositivos y plan protésico con etapas y laboratorio. |
| GROWTH | Desarrollo, antropometría y crecimiento | Curvas y tabla con edad, unidad, referencia y dominio/especie apropiados. |
| TRENDS | Mediciones y series temporales | Series por parámetro y unidad con filtros y tabla equivalente. |
| TIMELINE | Evolución y seguimiento por eventos | Eventos por tiempo y origen, con detalle y estados. |
| SCALES | Escalas e instrumentos versionados | Instrumento versionado, respuestas y resultado de demo identificado. |
| PHOTO | Fotografías y lesiones seriadas | Galería ficticia por sitio y fecha con comparación y anotación. |
| IMAGING | Estudios, imágenes e informes | Visor de estudios ficticios y metadatos; anotaciones/informe sin integración PACS real. |
| SIGNAL | Señales, audio y videos | Trazado/reproductor de señal, audio o vídeo preparado con tiempo y marcadores. |
| SURGERY | Registros quirúrgicos y anestésicos | Secuencia de caso, sitio, dispositivos y hoja anestésica con eventos. |
| HOSPITAL | Hojas de cuidados y monitorización | Hoja temporal de cuidados, entradas/salidas y tareas por turno. |
| MEDICATION | Medicaciones y administración | Lista conciliada, receta y cuadrícula de dosis/administraciones. |
| REPRODUCTION | Gestación, reproducción y vínculos de descendencia | Ciclo y vínculos de participantes, muestras, descendencia y custodia. |
| LAB | Muestras, resultados y trazabilidad | Orden-muestra-resultado, unidades, referencias y trazabilidad. |
| POPULATION | Poblaciones, programas y ambiente | Población, pertenencias, denominador, cobertura y eventos grupales. |
| FUNCTION | Función, movilidad y rehabilitación | Mapa funcional, movilidad/rangos, sesiones y evolución. |
| RELATIONSHIP | Responsables y relaciones | Diagrama/lista de vínculos con tipo, vigencia y alcance. |
| REPORT | Informes y documentos | Documento versionado con emisor, destinatario y impresión. |
| DEVICE | Dispositivos, materiales y lotes | Mapa/lista de dispositivos, ubicación, lote y eventos. |
| TRIAGE | Triaje y secuencia de urgencia | Secuencia de urgencia con clasificación registrada y reevaluaciones, sin algoritmo clínico real. |
| VISION | Registro visual y refracción | Registro por ojo, refracción/campo visual y comparación con atlas correspondiente. |
| HEARING | Audición y comunicación | Audiograma o registro de audición/comunicación con lados, unidades y tabla. |
| GENETICS | Pedigrí y datos genéticos | Pedigrí y registros genéticos ficticios con relaciones y procedencia. |
| QUALITY | Indicadores y revisión de calidad | Indicadores de ejemplo con fórmula, denominador y eventos fuente. |
| CONSENT | Consentimiento y alcance de acceso | Alcance, decisiones y evidencia ficticia con participantes y vigencia. |

## Conteo por lote de implementación

| Lote | Acciones contextuales |
|---|---|
| D02 | 49 |
| D03 | 57 |
| D04 | 93 |
| D05 | 21 |
| D06 | 60 |
| D07 | 27 |
| D08 | 77 |
| D09 | 45 |

Estos conteos validan el plan. Los estados permanecen `PLANNED` y `NOT_RUN`; no acreditan implementación de botones, gráficos o pruebas de navegador.
