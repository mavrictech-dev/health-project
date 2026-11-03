# Estado de produccion

Baseline inspeccionada el 2 de noviembre de 2026 sobre HEAD
0b24487c77055a081f6e76f0b18bc544ce4b1958. Supervisor en main sin integrar producto;
implementaciones en Maczz09/health-programmer. La coordinacion paso despues a
health/production-wave0 para integrar solo archivos revisados, sin commits/main.
README y plan del usuario preservados.

HP-ORCH-01 VALIDADA como auditoria estatica, con informe Orca en cuatro partes
(ctx_06e3adc9a15a). No equivale a validacion del sistema. Nueva autorizacion:
ejecutar la guia por dependencias, con demo independiente y datos sinteticos.

## ARQ-01: matriz por recorrido

Los procedimientos indicados existen en fuentes; no se afirma que esten
aplicados en una base disponible. Prueba H = historica documentada de octubre;
S = fuente inspeccionada; M = mock ejecutado antes del nuevo encargo. Ninguna
fila acredita integracion real actual.

| Recorrido / pantalla | API y procedimiento existente | Actor | Real/mock actual | Prueba / brecha |
| --- | --- | --- | --- | --- |
| Acceso, cuenta, sesiones /acceso, /app/cuenta | /auth/browser/session, /auth/browser/login; sp_session_save/end | Todos por host | UI API real; cookie/CSRF | S,H; repetir aislado, endurecer fallos |
| Registro/verificar/recuperar | /auth/register, /auth/verify/*, /auth/recovery/*; lifecycle/SMTP | Publico con token de un uso | Real o adaptador mock segun build | S,H; correo publico fuera de alcance |
| Clientes /saas/clientes | /platform/tenants; sp_tenant_create/status | SAD plataforma | Listado real; alta remite a registro; gestion rica mock | S,H API; falta alta administrativa integrada |
| Planes /saas/planes | /platform/plans; sp_plan_save | SAD | Pantalla rica mock | S,M,H API; conectar versionado sin alterar contratos |
| Contratos /saas/suscripciones | /platform/tenants/{id}/subscription; sp_subscription_change | SAD, ADM en su host | Mock | S,M,H; persistencia y cuotas reales |
| Sedes/areas/equipo | /tenant/branches, /areas, /members, /specialties; sp_branch_save/area_save/member_save/specialties_save | ADM; SAD por endpoint plataforma | Mock | S,M,H; ORG-01 |
| Pacientes y responsables /app/pacientes | /patients y /links; sp_patient_save/link | REC, ADM, PRO; lectura segun rol | Mock | S,M,H; mapear DTO, paginacion/revision |
| Agenda/recepcion /app/agenda | /appointments; sp_appointment_reserve/change | REC, PRO, ASI; portal limitado | Mock | S,M,H; UTC, conflictos, misma clave al reintentar |
| Consulta/historia /app/atencion | /encounters y /patients/{id}/history; sp_encounter_start/save, sp_audit | PRO; ASI/AUD lectura | Mock | S,M,H; historia truncada 200/1000/200 sin continuacion |
| Evaluaciones/graficos | /encounters/{id}/entries; sp_clinical_entry | PRO asignado | Mock visual; backend parcial | S,M,H; perfiles no habilitados clinicamente |
| Documentos /app/documentos | /documents; sp_document_create/change | PRO; ASI/AUD lectura | Mock UI | S,M,H; sin PDF/adjuntos privados/firma certificada |
| Portal /portal/* | /portal/patients y documentos/citas/saldo; SP agenda y auditoria | PAC/RES con vinculo y alcance | Mock clinico | S,M,H; revocacion e identidad real por vinculo |
| Caja/inventario | /finance, /inventory; SP monetarios/stock | CAJ,FAR,ALM | Mock UI | S,M,H; alcance piloto por decidir, concurrencia real pendiente |
| Hospital/procesos avanzados | /hospital, /workflows; SP estados/recursos | Roles y modulos del servidor | Mock UI, API base | S,H; protocolos completos no implementados |
| Trazabilidad/monitor/soporte | /trace/*, /monitor, /support; SP audit/mode/tickets y triggers V10 | SAD/SOP/ADM/AUD segun recurso | UI API real y adaptador mock separado | S,H,M; QA global serializada |
| Demo raiz y /demo | engine.ts, saas.ts, runtime-api.ts; sin MySQL | Selectores ficticios | Mock explicito | M 30 casos/13 recorridos; no acredita integracion |

## Discrepancias y riesgos verificados

- Guias historicas de especialidades/SaaS mencionan SQL Server; pom, Compose y
  migraciones usan MySQL 8.4. Se mantiene MySQL.
- Documentacion de 14/18 de octubre describe servicios activos y pruebas de
  entonces. Ahora docker version falla por pipe dockerDesktopLinuxEngine ausente.
- runtime-workspace ya lista clientes reales; la brecha SaaS no es ausencia total
  de UI real. Crear/editar planes y administrar contratos sigue sin conectar.
- El Compose original fija nombre health-project, puertos 8080/3307/8025 y volumen.
  Un worktree no aisla esos recursos. No ejecutar suites sobre ese stack.
- Compose monta frontend/out sin construirlo. Preview estatico no proxy de /api.
- QA antigua espera dashboard en raiz; qa:demo usa la portada actual. qa:visual
  registra overflow/errores sin asercion final. identity-qa modifica modo global.
- TS mock usa IDs/estados distintos de DTO Java. No integrar sustituyendo solo URL.
- Unitarias existentes: 30 mock TS y 10 Java tenancy/shared; no prueban servicios,
  SQL, SMTP o persistencia. V1-V11 en fuentes no significa migradas ahora.

Fuentes contrastadas: health-app/auth-session/runtime-workspace, api/app-mode,
pom/Compose, modulos Java y scripts QA. Detalle de baseline y limites en
[flujo](../agent-workflow.md). No hay aceptacion clinica ni de produccion.

## Inventario completo F01-F79

Una fila por flujo de la especificacion; las rutas son del dise?o y no implican
que el shell live las implemente. Roles listados son actores propuestos; las
restricciones efectivas se contrastan por endpoint (tabla anterior/DECISIONES).
S y H mantienen el significado anterior. No hay prueba real actual de estas79
filas; M no significa que todas las acciones del flujo se ejecutaron.

| Flujo | Pantallas/rutas de dise?o | Roles dise?o | API/SP fuente y alcance | Real/mock | Evidencia / brecha |
| --- | --- | --- | --- | --- | --- |
| F01 Ingresar al espacio profesional | S01 /acceso; S03 panel global: contexto | PRO,REC,ADM,ASI,DIA,FAR,CAJ,ALM,AUD | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |
| F02 Cambiar organización o sucursal | S03 panel global: contexto | PRO,REC,ADM | /public/context, /tenant/branches; sesiones por host | Selector demo; API directorio | S; H aislamiento; Navegacion entre hosts con sesiones propias; no selector arbitrario tenant |
| F03 Recuperar acceso | S01 /acceso; S02 /portal/acceso; S04 /recuperar,/invitacion; S53 /app/cuenta,/portal/cuenta,/operacion/cuenta | PRO,REC,ADM,ASI,DIA,FAR,CAJ,ALM,AUD,PAC,RES | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |
| F04 Reanudar trabajo tras expiración o fallo de guardado | S01 /acceso | PRO,REC,ADM,ASI,DIA,FAR,CAJ,ALM,AUD | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |
| F05 Dar de alta y configurar una organización | S05 /app/configuracion/organizacion; S06 /app/configuracion/equipo; S55 /app/configuracion/agenda | ADM,SOP | /platform/tenants; sp_tenant_create | Alta rica mock; listado real | S; H API; M SaaS; SAAS-01 alta administrativa real pendiente |
| F06 Invitar y asignar a un profesional | S04 /recuperar,/invitacion; S06 /app/configuracion/equipo | ADM,PRO | /tenant/members, /auth/invitations/accept; sp_member_save/invitation_accept | Mock UI; API parcial | S; H API; Correo invitacion por enlace no implementado; ORG/IAM |
| F07 Cambiar permisos o revocar membresía | S06 /app/configuracion/equipo; S50 /app/auditoria | ADM | /tenant/members, /auth/invitations/accept; sp_member_save/invitation_accept | Mock UI; API parcial | S; H API; Correo invitacion por enlace no implementado; ORG/IAM |
| F08 Diseñar, publicar y habilitar una plantilla de especialidad | S08 /app/configuracion/especialidades | ADM,PRO | /tenant/specialties; sp_specialties_save | Mock UI; catalogo API | S; M catalogo; Publicacion clinica/validador por perfil y aprobacion profesional pendientes |
| F09 Definir disponibilidad y recursos de agenda | S14 /app/agenda; S55 /app/configuracion/agenda | ADM,PRO | /tenant/branches/professionals; API agenda parcial | Mock UI | S; H API parcial; Horarios/excepciones y recursos del dise?o sin circuito completo |
| F10 Registrar un paciente humano | S09 /app/pacientes; S10 /app/pacientes?paciente=id&tab=ficha&dominio=humano | REC | /patients; sp_patient_save | Mock UI; API real en fuente | S; H API; M motor; PAC-01 DTO humano/animal, persistencia/revision y responsables |
| F11 Registrar un animal y sus responsables | S09 /app/pacientes; S11 /app/pacientes?paciente=id&tab=ficha&dominio=animal | REC,RES | /patients; sp_patient_save | Mock UI; API real en fuente | S; H API; M motor; PAC-01 DTO humano/animal, persistencia/revision y responsables |
| F12 Actualizar o revocar una relación de responsable | S10 /app/pacientes?paciente=id&tab=ficha&dominio=humano; S11 /app/pacientes?paciente=id&tab=ficha&dominio=animal; S32 /portal/vinculos,/app/pacientes?paciente=id&tab=vinculos | REC,ADM,RES,PAC | /patients/{id}/links; sp_patient_link | Mock UI; API vinculos por scopes | S; H API; M motor; Verificacion de representacion/vigencia y UI real pendientes |
| F13 Revisar y fusionar pacientes duplicados | S12 /app/pacientes/duplicados | ADM,PRO | /patients solo directorio; sin API fusion | Mock | S; M demo; Fusion auditada con referencias originales no implementada |
| F14 Registrar población animal y pertenencias | S13 /app/veterinaria/poblaciones; S47 /app/veterinaria/programas | PRO,REC | /workflows VET_POPULATION; SP de estados | Mock; API motor generico | S; H motor; Poblacion/membresias/denominadores y reglas especializadas pendientes |
| F15 Buscar paciente y abrir historia compartida | S09 /app/pacientes; S10 /app/pacientes?paciente=id&tab=ficha&dominio=humano; S11 /app/pacientes?paciente=id&tab=ficha&dominio=animal; S19 /app/pacientes?paciente=id&tab=historia | PRO,REC | /patients/{id}/history; sp_audit | Mock UI; API historia parcial | S; H API; Limites200/1000/200; episodios longitudinales y paginacion pendientes |
| F16 Reservar una cita desde la clínica | S09 /app/pacientes; S14 /app/agenda | REC,PRO | /appointments y /encounters; sp_appointment_reserve/change, sp_encounter_start | Mock UI; API agenda parcial | S; H API; M motor; AGE-01 recepcion/UTC/estados/concurrencia y UI real |
| F17 Solicitar una cita desde el portal | S15 /app/agenda/solicitudes; S29 /portal/inicio; S30 /portal/citas | PAC,RES,REC | /portal/appointments; sp_appointment_reserve | Mock UI; API REQUESTED | S; H API; M motor; Vinculo APPOINTMENTS y confirmacion recepcion UI real |
| F18 Confirmar, reprogramar o cancelar una cita | S14 /app/agenda; S30 /portal/citas | REC,PAC,RES,PRO | /appointments y /encounters; sp_appointment_reserve/change, sp_encounter_start | Mock UI; API agenda parcial | S; H API; M motor; AGE-01 recepcion/UTC/estados/concurrencia y UI real |
| F19 Gestionar lista de espera | S15 /app/agenda/solicitudes; S30 /portal/citas | REC,PAC,RES | /appointments REQUESTED; sin lista de espera completa | Mock; API parcial | S; M demo; Lista de espera/cobro anticipado/proveedor sin implementar |
| F20 Registrar llegada, cola y atención sin cita | S09 /app/pacientes; S16 /app/recepcion; S17 /app/inicio | REC,ASI,PRO | /appointments y /encounters; sp_appointment_reserve/change, sp_encounter_start | Mock UI; API agenda parcial | S; H API; M motor; AGE-01 recepcion/UTC/estados/concurrencia y UI real |
| F21 Realizar una consulta y finalizar la visita | S17 /app/inicio; S18 /app/atencion?atencion=id | PRO,ASI | /encounters/{id}/note/finalize; sp_encounter_save | Mock UI; API consulta | S; H API; M motor; CLI-01 borrador/conflicto/cierre real y sesiones distintas |
| F22 Capturar un formulario de especialidad | S18 /app/atencion?atencion=id | PRO,ASI | /encounters/{id}/entries; sp_clinical_entry | Mock graficos; validacion API parcial | S; H API; M perfiles; ESP-01/02 semantica/version/atlas y revision profesional |
| F23 Marcar un hallazgo en un mapa anatómico | S18 /app/atencion?atencion=id; S19 /app/pacientes?paciente=id&tab=historia | PRO | /encounters/{id}/entries; sp_clinical_entry | Mock graficos; validacion API parcial | S; H API; M perfiles; ESP-01/02 semantica/version/atlas y revision profesional |
| F24 Registrar odontograma y evolución dental humana o animal | S18 /app/atencion?atencion=id; S19 /app/pacientes?paciente=id&tab=historia | PRO | /encounters/{id}/entries; sp_clinical_entry | Mock graficos; validacion API parcial | S; H API; M perfiles; ESP-01/02 semantica/version/atlas y revision profesional |
| F25 Registrar mediciones, curvas y escalas | S18 /app/atencion?atencion=id; S19 /app/pacientes?paciente=id&tab=historia | PRO,ASI | /encounters/{id}/entries; sp_clinical_entry | Mock graficos; validacion API parcial | S; H API; M perfiles; ESP-01/02 semantica/version/atlas y revision profesional |
| F26 Adjuntar y comparar archivos clínicos | S18 /app/atencion?atencion=id; S24 /app/diagnostico/imagenes; S28 /app/documentos | PRO,DIA | /documents texto; sin almacenamiento privado | Mock adjuntos | S; Archivo privado/limites/antimalware/autorizacion y comparacion pendientes |
| F27 Revisar y firmar una nota o documento clínico | S18 /app/atencion?atencion=id; S28 /app/documentos | PRO | /documents; sp_document_create/change | Mock UI; API texto/firma interna | S; H API; M motor; DOC-01 PDF/adjuntos, consentimiento y UI real; no firma certificada |
| F28 Corregir contenido firmado mediante adenda | S19 /app/pacientes?paciente=id&tab=historia; S28 /app/documentos | PRO | /documents; sp_document_create/change | Mock UI; API texto/firma interna | S; H API; M motor; DOC-01 PDF/adjuntos, consentimiento y UI real; no firma certificada |
| F29 Mantener episodios, problemas y antecedentes longitudinales | S19 /app/pacientes?paciente=id&tab=historia | PRO | /patients/{id}/history; sp_audit | Mock UI; API historia parcial | S; H API; Limites200/1000/200; episodios longitudinales y paginacion pendientes |
| F30 Crear orden de estudio, procedimiento o remisión | S18 /app/atencion?atencion=id; S20 /app/ordenes | PRO | /encounters/{id}/entries ORDER/PRESCRIPTION; sp_clinical_entry | Mock UI; API entradas | S; H API; M motor; Orden/conciliacion/vacuna con reglas y seguimiento especializados pendientes |
| F31 Asignar tarea y obtener muestra o adquisición | S21 /app/diagnostico/trabajo; S22 /app/diagnostico/muestras | DIA | /workflows y /steps; motor estados | Mock; API generica | S; H motor; Muestras/adquisicion/resultados/revision profesional/PACS no completos |
| F32 Procesar y emitir resultado de laboratorio | S22 /app/diagnostico/muestras; S23 /app/diagnostico/laboratorio | DIA | /workflows y /steps; motor estados | Mock; API generica | S; H motor; Muestras/adquisicion/resultados/revision profesional/PACS no completos |
| F33 Adquirir estudio de imagen y emitir informe | S21 /app/diagnostico/trabajo; S24 /app/diagnostico/imagenes | DIA,PRO | /workflows y /steps; motor estados | Mock; API generica | S; H motor; Muestras/adquisicion/resultados/revision profesional/PACS no completos |
| F34 Revisar resultados y resolver pendientes clínicos | S17 /app/inicio; S20 /app/ordenes; S23 /app/diagnostico/laboratorio; S24 /app/diagnostico/imagenes | PRO | /workflows y /steps; motor estados | Mock; API generica | S; H motor; Muestras/adquisicion/resultados/revision profesional/PACS no completos |
| F35 Conciliar medicación y emitir receta | S18 /app/atencion?atencion=id; S25 /app/atencion?atencion=id&tab=medicacion | PRO | /encounters/{id}/entries ORDER/PRESCRIPTION; sp_clinical_entry | Mock UI; API entradas | S; H API; M motor; Orden/conciliacion/vacuna con reglas y seguimiento especializados pendientes |
| F36 Dispensar medicamentos y registrar devoluciones | S26 /app/farmacia; S39 /app/inventario | FAR | /inventory/*; SP lotes/movimientos/transferencias | Mock UI; API stock | S; H API; M motor; UI real/carreras/lotes y devoluciones por alcance piloto |
| F37 Registrar administración o dosis no realizada | S27 /app/hospital/medicacion; S42 /app/hospital/estancias | ASI,PRO | /hospital y /workflows parcial | Mock; motor estados | S; H parcial; Turnos/cuidados/administracion y transferencias clinicas pendientes |
| F38 Preparar documentos y gestionar consentimiento | S28 /app/documentos; S31 /portal/documentos | PRO,PAC,RES | /documents; sp_document_create/change | Mock UI; API texto/firma interna | S; H API; M motor; DOC-01 PDF/adjuntos, consentimiento y UI real; no firma certificada |
| F39 Vincular portal y conceder delegación verificada | S02 /portal/acceso; S10 /app/pacientes?paciente=id&tab=ficha&dominio=humano; S11 /app/pacientes?paciente=id&tab=ficha&dominio=animal; S32 /portal/vinculos,/app/pacientes?paciente=id&tab=vinculos | REC,PAC,RES,ADM | /patients/{id}/links; sp_patient_link | Mock UI; API vinculos por scopes | S; H API; M motor; Verificacion de representacion/vigencia y UI real pendientes |
| F40 Publicar una versión documental para el portal | S28 /app/documentos | PRO | /documents; sp_document_create/change | Mock UI; API texto/firma interna | S; H API; M motor; DOC-01 PDF/adjuntos, consentimiento y UI real; no firma certificada |
| F41 Organizar seguimiento y comunicación | S17 /app/inicio; S29 /portal/inicio; S33 /app/seguimiento,/portal/seguimiento | PRO,REC,PAC,RES | /workflows seguimiento/sesion; motor estados | Mock; motor API | S; H parcial; Plan cuidado y responsables, comunicacion y protocolo pendientes |
| F42 Preparar plan comercial y presupuesto | S29 /portal/inicio; S34 /app/finanzas/presupuestos,/portal/pagos?tab=presupuestos | PRO,CAJ,PAC,RES | /workflows presupuesto/compra; motor estados | Mock; API parcial | S; H parcial; Linea comercial/compras y conciliacion con operacion real pendientes |
| F43 Registrar cargos y cuenta por cobrar | S35 /app/finanzas/caja,/portal/pagos | CAJ,PRO | /finance/movements; SP caja | Mock UI; API monetaria | S; H API; M motor; Caja completa/cierre/conciliacion, UI y alcance piloto pendientes |
| F44 Cobrar, conciliar caja y devolver pagos | S29 /portal/inicio; S35 /app/finanzas/caja,/portal/pagos | CAJ,PAC,RES | /finance/movements; SP caja | Mock UI; API monetaria | S; H API; M motor; Caja completa/cierre/conciliacion, UI y alcance piloto pendientes |
| F45 Emitir comprobante y tratar rechazo o corrección | S36 /app/finanzas/comprobantes | CAJ | /finance basica; sin API fiscal/honorarios/convenios completa | Mock | S; Proveedor fiscal/honorarios/pagador y reglas de producto pendientes |
| F46 Calcular y pagar honorarios profesionales | S37 /app/finanzas/honorarios | ADM,CAJ,PRO | /finance basica; sin API fiscal/honorarios/convenios completa | Mock | S; Proveedor fiscal/honorarios/pagador y reglas de producto pendientes |
| F47 Solicitar, comprar y recibir productos | S38 /app/compras | ALM,ADM | /workflows presupuesto/compra; motor estados | Mock; API parcial | S; H parcial; Linea comercial/compras y conciliacion con operacion real pendientes |
| F48 Mover, consumir, transferir o ajustar inventario | S26 /app/farmacia; S39 /app/inventario | ALM,FAR,ASI,ADM | /inventory/*; SP lotes/movimientos/transferencias | Mock UI; API stock | S; H API; M motor; UI real/carreras/lotes y devoluciones por alcance piloto |
| F49 Admitir paciente y asignar cama o jaula | S40 /app/hospital/admisiones; S41 /app/hospital/recursos; S42 /app/hospital/estancias | PRO,REC,ASI | /hospital/resources/admissions/discharge; SP ocupacion/egreso | Mock UI; API base | S; H API; M motor; Alta clinica != egreso; estancia integral y protocolo pendientes |
| F50 Registrar cuidados, traslado y entrega de turno | S41 /app/hospital/recursos; S42 /app/hospital/estancias | ASI,PRO | /hospital y /workflows parcial | Mock; motor estados | S; H parcial; Turnos/cuidados/administracion y transferencias clinicas pendientes |
| F51 Recibir urgencia, reevaluar y decidir destino | S45 /app/urgencias | REC,ASI,PRO | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F52 Proponer y programar un caso quirúrgico | S14 /app/agenda; S43 /app/cirugia | PRO,REC,ASI | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F53 Ejecutar procedimiento quirúrgico y cerrar parte | S22 /app/diagnostico/muestras; S43 /app/cirugia | PRO,ASI | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F54 Registrar anestesia y recuperación | S27 /app/hospital/medicacion; S44 /app/anestesia | PRO,ASI | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F55 Preparar alta, egreso y seguimiento | S28 /app/documentos; S33 /app/seguimiento,/portal/seguimiento; S40 /app/hospital/admisiones; S42 /app/hospital/estancias | PRO,ASI,REC,PAC,RES | /hospital/resources/admissions/discharge; SP ocupacion/egreso | Mock UI; API base | S; H API; M motor; Alta clinica != egreso; estancia integral y protocolo pendientes |
| F56 Planificar y registrar curso de sesiones especializadas | S46 /app/especialidades?proceso=sesiones,/app/especialidades?proceso=transfusion,/app/especialidades?proceso=trasplante,/app/especialidades?proceso=reproduccion | PRO,ASI | /workflows seguimiento/sesion; motor estados | Mock; motor API | S; H parcial; Plan cuidado y responsables, comunicacion y protocolo pendientes |
| F57 Gestionar componente sanguíneo y transfusión | S23 /app/diagnostico/laboratorio; S27 /app/hospital/medicacion; S46 /app/especialidades?proceso=sesiones,/app/especialidades?proceso=transfusion,/app/especialidades?proceso=trasplante,/app/especialidades?proceso=reproduccion | DIA,PRO,ASI | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F58 Gestionar episodio de trasplante | S46 /app/especialidades?proceso=sesiones,/app/especialidades?proceso=transfusion,/app/especialidades?proceso=trasplante,/app/especialidades?proceso=reproduccion | PRO,REC | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F59 Gestionar ciclo reproductivo y muestras vinculadas | S22 /app/diagnostico/muestras; S46 /app/especialidades?proceso=sesiones,/app/especialidades?proceso=transfusion,/app/especialidades?proceso=trasplante,/app/especialidades?proceso=reproduccion | PRO,DIA,PAC,RES | /workflows y /steps; SP de estados | Mock; API motor | S; H motor; Protocolos y recursos de especialidad requieren desarrollo/aceptacion |
| F60 Registrar intervención sanitaria poblacional veterinaria | S13 /app/veterinaria/poblaciones; S23 /app/diagnostico/laboratorio; S47 /app/veterinaria/programas | PRO,ASI,RES | /workflows VET_POPULATION; SP de estados | Mock; API motor generico | S; H motor; Poblacion/membresias/denominadores y reglas especializadas pendientes |
| F61 Dictar y revisar un borrador asistido por IA | S18 /app/atencion?atencion=id; S54 /app/configuracion/integraciones | PRO | /encounters entrada; sin proveedor IA | Mock | S; Dictado/propuesta IA y revision/autoria no implementados como integracion |
| F62 Ejecutar integración y resolver fallos | S51 /app/plataforma; S54 /app/configuracion/integraciones | ADM | /workflows INTEGRATION; sin conector proveedor | Mock; motor parcial | S; Credenciales/outbox/webhooks/reintentos e integracion contratada pendientes |
| F63 Gestionar reserva asistida y cobro anticipado | S15 /app/agenda/solicitudes; S29 /portal/inicio; S30 /portal/citas; S54 /app/configuracion/integraciones | PAC,RES,REC | /appointments REQUESTED; sin lista de espera completa | Mock; API parcial | S; M demo; Lista de espera/cobro anticipado/proveedor sin implementar |
| F64 Importar o exportar datos de una organización | S48 /app/configuracion/datos | ADM,SOP | /platform/tenants/{id}/status parcial; sin exportacion/baja integral | Mock | S; H suspension parcial; Exportacion integral/custodia/retencion/fusion no resueltas; DAT-01 |
| F65 Consultar reportes y auditar acceso o cambios | S49 /app/reportes; S50 /app/auditoria | ADM,AUD,PRO,CAJ | /trace/events/requests, /audit; sp_audit y triggers | Auditoria UI real; reportes generales mock | S; H identidad; M demo; Reportes de negocio reales y pruebas acceso sensible actuales |
| F66 Solicitar soporte y conceder acceso temporal | S51 /app/plataforma; S52 /operacion/inicio | ADM,PRO,SOP | /support y /steps; SP tickets | Soporte UI real; acceso excepcional no habilitado | S; H identidad; M demo; No confundir ticket con concesion acceso clinico temporal |
| F67 Gestionar plan, consumo y suscripción SaaS | S51 /app/plataforma; S52 /operacion/inicio | ADM,CAJ,SOP | /tenant/subscription; sp_subscription_change | Mock gestion comercial; API fuente | S; H API; M SaaS; SAAS/COM: UI real y ciclo comercial, sin revision SaaS actual |
| F68 Dar de baja organización y entregar sus datos | S48 /app/configuracion/datos; S51 /app/plataforma; S52 /operacion/inicio | ADM,SOP | /platform/tenants/{id}/status parcial; sin exportacion/baja integral | Mock | S; H suspension parcial; Exportacion integral/custodia/retencion/fusion no resueltas; DAT-01 |
| F69 Gestionar incidente y comprobar recuperación | S52 /operacion/inicio | SOP,ADM | /monitor y /mode; SP estado | Monitor UI real | S; H identidad; M demo; Sonda externa/restauracion/incidentes no implementados por monitor interno |
| F70 Ingresar al portal de paciente o responsable | S02 /portal/acceso; S29 /portal/inicio; S32 /portal/vinculos,/app/pacientes?paciente=id&tab=vinculos | PAC,RES | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |
| F71 Consultar y descargar contenido publicado | S29 /portal/inicio; S31 /portal/documentos | PAC,RES | /portal/patients/{id}/documents; sp_audit | Portal clinico mock; API publicado | S; H API; M motor; UI real por vinculo, retiro/revocacion; no PDF clinico |
| F72 Utilizar componente gráfico especializado | S18 /app/atencion?atencion=id; S19 /app/pacientes?paciente=id&tab=historia; S24 /app/diagnostico/imagenes | PRO | /encounters/{id}/entries; sp_clinical_entry | Mock graficos; validacion API parcial | S; H API; M perfiles; ESP-01/02 semantica/version/atlas y revision profesional |
| F73 Conectar o revocar proveedor externo | S54 /app/configuracion/integraciones | ADM,PRO | /workflows INTEGRATION; sin conector proveedor | Mock; motor parcial | S; Credenciales/outbox/webhooks/reintentos e integracion contratada pendientes |
| F74 Actualizar cuenta, canales y preferencias | S53 /app/cuenta,/portal/cuenta,/operacion/cuenta | PRO,REC,ADM,PAC,RES | /auth/password/sessions; sp_password_change/session_end | Cuenta UI real; canales parciales | S; H identidad; M demo; Preferencias y canales publicos pendientes; reautenticacion/red actual |
| F75 Configurar servicios, tarifas y emisión documental | S07 /app/configuracion/servicios | ADM,CAJ | /platform/plans NO es catalogo servicios clinicos | Mock servicios | S; M demo; Servicios/precios por sede/emisor fiscal aun sin API especifica completa |
| F76 Registrar vacunación y control preventivo | S18 /app/atencion?atencion=id; S19 /app/pacientes?paciente=id&tab=historia; S28 /app/documentos | PRO,ASI | /encounters/{id}/entries ORDER/PRESCRIPTION; sp_clinical_entry | Mock UI; API entradas | S; H API; M motor; Orden/conciliacion/vacuna con reglas y seguimiento especializados pendientes |
| F77 Gestionar convenio, autorización de pagador y saldo institucional | S07 /app/configuracion/servicios; S35 /app/finanzas/caja,/portal/pagos | ADM,CAJ,REC | /finance basica; sin API fiscal/honorarios/convenios completa | Mock | S; Proveedor fiscal/honorarios/pagador y reglas de producto pendientes |
| F78 Ingresar a la consola de operación MAVRIC | S52 /operacion/inicio; S56 /operacion/acceso | SOP | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |
| F79 Cerrar sesión con trabajo pendiente | S03 panel global: contexto; S29 /portal/inicio; S52 /operacion/inicio; S53 /app/cuenta,/portal/cuenta,/operacion/cuenta | PRO,REC,ADM,ASI,DIA,FAR,CAJ,ALM,AUD,PAC,RES,SOP | /auth/browser/login/session, /auth/recovery/*; sp_session_save/end | UI identidad real; borradores y cambio de contexto parcial | H identidad; S; M demo; Probar expiracion/red/CSRF actual; no seleccion RUC como autenticacion |

Las pantallas SaaS S57-S64 y16 comandos adicionales se conservan en la matriz
de familias y docs/frontend-demo/07: clientes, planes, suscripciones, catalogo,
auditoria, sedes y acceso ficticio. El adaptador rico de esos comandos sigue
mock salvo el listado real existente. Los241 perfiles tienen estado de dise?o,
no de habilitacion clinica.
