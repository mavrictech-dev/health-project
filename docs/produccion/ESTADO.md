# Estado de produccion

Baseline inspeccionada el 2 de noviembre de 2026 sobre HEAD
0b24487c77055a081f6e76f0b18bc544ce4b1958. Supervisor en main sin integrar producto;
implementaciones en Maczz09/health-programmer. La coordinacion paso despues a
health/production-wave0 para integrar solo archivos revisados, sin commits/main.
README y plan del usuario preservados.

## Actualizacion supervisora, 2026-11-05

SQL-01.A1-A44 implementacion aceptada en health/production-wave0. A44 FinanceService
paso verificacion independiente con 797 pruebas, cero fallos/errores/skips y jar
PASS. Los adaptadores SQL Server siguen aislados. A36.R1 tuvo 8/8 fases de motor
sintetico; esto no acredita JDBC/HTTP de la aplicacion completa. Pendientes:
consumidores restantes, cableado runtime, grants y QA SQL Server/JDBC/HTTP real,
mas validacion visual de recorridos reales. main permanece intacta.

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
  migraciones usan MySQL 8.4. Esta decision de mantenerlo fue sustituida por D-09: el usuario confirma SQL Server y 100 % SP como objetivo; la implementacion heredada debe migrarse.
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
| F05 Dar de alta y configurar una organización | S05 /app/configuracion/organizacion; S06 /app/configuracion/equipo; S55 /app/configuracion/agenda | ADM,SOP | /platform/tenants; sp_tenant_create | Alta rica mock; listado real | S; H API; M SaaS; SAAS-01.A alta/listado/detalle frontend interceptados; MySQL y persistencia pendientes |
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


## Hito revisado ORG-01.B

Frontend tenant de equipo en lectura integrado localmente tras revision independiente: 68 tests, check, builds live/demo85 rutas, QA de organizacion12, shell16 y demo13. El detalle de aceptacion y evidencia esta en REVISIONES.md/VALIDACION.md. No habilita invitaciones ni uso asistencial; MySQL y persistencia siguen sin verificar.


## Correccion de conformidad de persistencia - 2026-11-03

El estado observado es MySQL y lecturas directas desde JDBC, mientras la arquitectura requerida por el usuario es SQL Server y 100 % SP. Consultar D-09 y MIGRACION_SQLSERVER.md. Este inventario distingue implementacion existente de arquitectura objetivo; las comprobaciones frontend y reportes historicos no prueban conformidad SQL Server.

### Continuacion SQL-01.A5, 2026-11-03

Familias V1-V6 presentes en el checkout de coordinacion; 133 SP aplicados en
SQL Server 2022 QA exclusivo. Operaciones de caja, stock, hospital y procesos
aceptadas en motor con 29 comprobaciones del supervisor y tres carreras reales.
Esto no cambia todavia el backend activo MySQL: faltan auditoria completa,
permisos finales, adaptador JDBC y conversion de servicios/configuracion.
No se habilita producto ni uso asistencial. Siguiente entrega: triggers SQL Server
de cambios multirregistro y proteccion de auditoria (SQL-01.A6).

### Hito SQL-01.A6.R1 aceptado

V7 corregida integrada por SHA c5657fa2...f1f y aplicada solo a QA sintetica:
31 triggers/133 SP/0 usuarios. Supervisor 21+4 pruebas reales PASS, incluida
regresion UTF8 largo/CJK/emoji; defecto original documentado y corregido.
Backend activo sigue MySQL/direct SQL; siguiente paquete son permisos por SP,
despues adaptador JDBC y conversion Java. No validacion HTTP ni habilitacion
clinica. No nueva evidencia visual para este cambio exclusivo de persistencia.

### Hito A7.R1 - permisos aceptados en motor, despliegue runtime pendiente

V8 y verificador integrados localmente con10fases independientes PASS;
562ACL sinhistorial/571conhistorial representativo. Ambos roles sin acceso
directoCRUD; metadata solo objeto historia/runtime; monitor SAD/SOP y rechazo
anonimo/tabla desconocida comprobados. Baseline persistente sigue133SP/31triggers/
37tablas/0users, sin roles ni historial: V8 se probo exclusivamente rollback-only.
A7 no acredita login/JDBC/Flyway/HTTP real. Backend activo sigueMySQL/directSQL;
A8 prepara adaptador aislado con pruebas unitarias y sin activacion parcial.

### Hito A8 - adaptador JDBC aislado aceptado

4clases nuevas de persistenciaSQLServer,2suites y2dependenciaspom integradas
localmente tras revision y49/49tests independientes. Catalogo inicial12SP y
contexto interno; sinregistrobeans ni consumidores activos. VersionesBOM:
mssql-jdbc13.4.0.jre11/Flyway12.4.0. Backendactivo sigueMySQL ylecturasdirectas;
A9 completa catalogo necesario antes de conversion porfamilias. No Flyway,
login/conexionJDBC,poolreal oHTTP acreditados por esosmocks. Demo intacta.

### Hito A9 - catalogo completo aceptado, consumidores pendientes

108 operaciones tipadas (106 runtime y 2 bootstrap) y contexto interno, con
169 pruebas independientes y compilacion/empaquetado PASS. Cuatro archivos
integrados por hash; no beans ni consumidores SQL Server activados. Backend
actual conserva MySQL/lecturas directas: A10 inicia conversion de host y sesion
con camino explicito, sin modificar la configuracion actual. No se acredita
JDBC conectado, pool, Flyway, HTTP real ni habilitacion del producto.

### Hito A10 - host y sesion con camino SQL explicito aceptados

Cinco archivos integrados tras218/218 pruebas independientes y empaquetado.
Filtros disponen de constructor SQL y store de cinco SP; configuracion vigente
sigue usando camino legado. No estan desplegados datasource/roles runtime SQL.
A11 convierte IdentityService con store transaccional; restantes consumidores,
bootstrap separado y validacion JDBC/Flyway/HTTP reales siguen pendientes.
No nueva evidencia visual ni activacion de producto.

### Bloqueo A11 por cuota del programador

A10 sigue ultimo corte integrado. A11 tiene borrador de seis archivos en
worktree separado y snapshot independiente249/249PASS, sin aprobacion/integracion
por falta de entrega final: programador alcanzo cuota, CLI indica03:35.
Sesion y cuenta retenidas, Dispatch original abierto, sin reintento automatico
ni cambio de roles/cuentas. Pendiente cierre del mismo trabajador tras recuperar
cuota; no se avanzan consumidores dependientes ni se activa backend parcial.

### A11 reanudada tras recuperacion de Orca

Misma Task, cuenta, conversacion y worktree del programador; nuevo handle/
Dispatch tras perdida de terminal en recovery. Turno confirmado por mensaje
Orca. Borrador sin cambios respecto a249pruebas independientes; cierre de
programador pendiente, A10 sigue ultimo corte integrado. Sin activar backend.

### Hito A11 - identidad SQL explicita aceptada

Seis archivos integrados tras cierre del mismo trabajador restaurado y
confirmacion de249 pruebas independientes. Creacion/login/password/logout/
accept tienen camino tipado; registro anonimo requiere entrada explicita y TX
externa, sin cambiar AccountLifecycle. Wiring actual permanece legado.
A12 cubre sesiones de navegador; falta conversion restante, bootstrap separado
y validacion JDBC/Flyway/HTTP real. No nueva evidencia visual ni activacion.


## Continuidad y push autorizado - 2026-11-04

El usuario autoriza continuar pendientes y hacer push a la rama de trabajo.
El corte aceptado sigue en SQL-01.A11 (249 pruebas unitarias/modeladas, sin
wiring SQL activo); frontend68/68 y TypeScript verificados nuevamente.
A12 no tiene entrega: Orca recupero ctx_fc719f716d1e como abandoned por terminal
ausente. Conversacion original del programador restaurada y ambas cuentas
efectivas verificadas; misma Task se retomara con Dispatch nuevo.
No implica SQL Server conectado, validacion HTTP real ni salida a produccion.


## Corte SQL-01.A12 aceptado - 2026-11-04

Camino explicito browser sessions integrado tras279/279 pruebas independientes,
seis hashes verificados y jar PASS. Cookies/CSRF/lista/revocacion por SP se
prueban con HTTP simulado y TX modeladas, no con backend real. Sigue constructor
legado predeterminado: no hay nueva activacion ni migracion100% completada.
Siguiente paquete A13: controles Access.branch/link por dos SP existentes.


## A13 verificada en snapshot, bloqueada por cuota - 2026-11-04

301/301 pruebas independientes y jarPASS para4archivos Access/store/suites.
Informe final recibido, sin worker_done por cuota. Se conservan hashes/pruebas,
no se integran ni publican archivos A13; A12/da3373a sigue ultimo corte de codigo
aceptado. Resta verificar modelo antes de reanudar: tras wake de Orca la pantalla
muestra Luna medium, distinto del Sol high observado antes. No comprar cuota,
cambiar cuentas ni iniciar agentes sustitutos; mismo Task/Dispatch pendiente.


## A13 aceptada tras cierre - 2026-11-04

Recibido worker_done msg_d0f5e7def244 y4SHA iguales al snapshot301/301+jar.
Access/store/suites integrados sin cambiar configuracion activa; SQL-01 vuelve
aEN_CURSO. Misma cuenta/sesion,Sol medium y cuota disponible verificados.
A14 prepara solo catalogo publico de registro; mutadores de ciclo y Bootstrap
con principal segregado siguen pendientes. SQLServer/JDBC/HTTP real aun no
validado; no nueva evidencia visual ni afirmacion de migracion completa.


## A14 aceptada - 2026-11-04

Catalogo publico de registro por2SP integrado tras316/316 pruebas independientes
y4SHA. Tenants reciben portal:true,plataforma planes/especialidades con tipos
y proyecciones seguras; validacion offline solamente. Guardas impiden usar
mutadores del nuevo constructor incompleto; default activo sigue legado.
Siguiente A15 solicitud/canje de enlaces de identidad y outbox, sin SMTP ni
registro de cuentas, sin activacion del backend. Integracion real pendiente.


## A15 aceptada - 2026-11-04

Solicitud y canje de enlaces de identidad por SP integrados tras331/331 pruebas
independientes y5SHA. Catalogo y legado preservados; outbox/token solo validados
con dobles, sin correo enviado ni SQLServer/JDBC/HTTP conectado. RegisterSQL
aun guardado. Siguiente A16: alta portal de tenant existente; plataforma se
reserva paraA17, sin activacion de configuracion ni afirmacion100%SP.


## A16 aceptada - 2026-11-04

Alta publica del portal de tenant integrada tras343/343 pruebas independientes
y5SHA. Identidad pendiente,membresia y outbox agrupados en TX modelada; roles
y atomicidad en SQLServer real no acreditados. Sin acceso clinico inventado
ni nueva sesion,cookie o correo enviado. Plataforma sigue guardada hastaA17.
Configuracion activa permanece legado; otros consumidores/JDBC/Flyway/HTTP
reales y wiring segregado pendientes. No nueva evidencia visual.


## A17 en correccion de QA - 2026-11-04

352/352 pruebas independientes y jar pasan,pero revision encontro fixture
DOCTORcon4profesionales cuando contratoSP exige1. Se devuelve test para
correccion; no se integra ni sube codigoA17. A16/6446c99 sigue ultimo corte
aceptado de producto. R1 unicamente test de servicio,producto y SQL congelados.
Validacion de motor/conexion/durabilidad y consumidores restantes pendientes.


## A17 aceptada tras corregir QA - 2026-11-04

Hallazgo de cuotaDOCTOR cerrado conR1 y353/353 pruebas independientes. Alta
plataforma y portal del ciclo de cuenta en caminoSQL explicito integrados,
sin activar configuracion ni SMTP. No equivale a recorrido conectado o IAM
integral validado. Otros consumidores y wiringsegregado siguen pendientes.
A18 prepara trazasHTTP finales porSP; sin nueva evidencia visual.


## A18 aceptada - 2026-11-04

Finalizacion de trazasHTTP por REQUEST_FINISH integrada tras368/368 pruebas
independientes y4SHA. Transaccion independiente modelada alfinal del filtro,
respuesta preservada ante fallo y contexto limpiado; no validacion durable o
conectada. Constructor legacy actual y SecurityConfiguration intactos.
A19 prepara lecturas de auditoria/trazabilidad; Monitor/Mail/Bootstrap y negocio/
actuator/wiringsegregado y QAreal aun pendientes. No100%SP ni backend activo.


## A19 aceptada - 2026-11-04

Lecturas de auditoria/trazas en caminoSQL explicito integradas tras385/385
pruebas independientes y4SHA. Legacy/default vigentes,roles/paginacion/JSON
probados con dobles; no auditoria/permisos reales acreditados. A20 prepara
estado publico y muestreo de salud; detalles/mode posterioresA21,Mail/Bootstrap/
actuator/negocio/wiring y QAconectada aun pendientes. No backendSQL activado.


A20 ACEPTADA: informe msg_11b7052f1796/done msg_5a2a9bf20f4c,4SHA exactos.
Snapshot independiente verify398/398,0fallos/errores/omisiones,jarPASS22.306s,
2026-11-04T21:54:34-05:00.117bases verificadas,116fueraownership intactas;
1existente+3nuevos integrados. Cuerpos legacy exactos al retirar guardasSQL.
Tres SP tipados,status REQUEST/sample WORKER sin autoridadHTTP,REQUIRED y
WARN estatico revisados personalmente. Evidencia tmp/sqlserver-a20-acceptance.json.
Sin motor/JDBC/HTTP real ni nueva evidencia visual; no backend activo.
A21 siguiente: details/mode por SP en mismos4archivos,secuencia sin solapamiento.


A21 ACEPTADA: informe msg_5d06be4f117a/done msg_afd7844ea41a,4SHAexactos,
verify independiente410/410 sinfallos/errores/omisiones,jarPASS23.115s,
2026-11-04T22:03:41-05:00.120bases verificadas,116ajenas intactas;4existentes
integrados. Legacy y sampler/statusA20 comparados exactos retirando solo ramas
SQL details/mode. Autorizacioncontextual,tenant3SP/plataforma6SP y mode2SP,
nullableversionFlyway,inmutabilidad y TX modeladas revisados. SinJDBC/HTTPreal
ni evidencia visual nueva ni backend activo. Siguiente A22 correo por claim/
complete con SMTPdoble y sinreintento automatico ante resultado ambiguo.


A22 ACEPTADA: informe msg_f0856447bb7a/done msg_98705a30ccac,4SHAexactos,
verify independiente424/424,0fallos/errores/omisiones,jarPASS22.813s,
2026-11-04T22:12:08-05:00.120bases verificadas,119ajenas intactas;1existente+
3nuevos integrados. Cuerpo sendlegacy exacto retirando selectorSQL. Revision
personal confirma claimcommit antes senderfueraTX,AMBIGUOUS paraexcepciones,
completefallido sinreclasificacion/reenvio,logsestaticos y WORKER9NULL.
No SQLServer/JDBC/SMTP/HTTP reales ni nueva evidencia visual. A23 siguiente:
Bootstrap con executor/principal separado,sin configurar ni crearusuarios.


A23 ACEPTADA: informe msg_dc8bc56cebd5/done msg_1d077c1c01ff,4SHAexactos,
verify independiente437/437,0fallos/errores/omisiones,jarPASS23.672s,
2026-11-04T22:20:24-05:00.123bases verificadas,122ajenas intactas;1existente+
3nuevos integrados. Cuerpo legacy exacto retirando selectorSQL; EXISTS antes
hash diferido y CREATE en mismaREQUIRED,BOOTSTRAP9NULL,sinbean/wiring.
Sin usuarios/principales/SQLServer/JDBC/HTTP reales ni evidencia visual nueva.
Siguiente A24 soporte lecturas,escrituras guardadas hasta A25.


A24 ACEPTADA: informe msg_812fbd62269b/done msg_40493c72a239,4SHAexactos,
verify independiente452/452,0fallos/errores/omisiones,jarPASS24.483s,
2026-11-04T22:29:00-05:00.126bases verificadas,125ajenas intactas;1existente+
3nuevos integrados. Records/rutas/cuerposlegacyexactos retirando ramasSQL.
Ownershiptenant/autor porfila,proyecciones12/4,nullable y MAX,mapeodentroTX
revisados personalmente. SinSQLServer/JDBC/HTTP reales ni evidencia visual.
Siguiente A25 escrituras soporte,mismos4archivos sin solapamiento.


A25 ACEPTADA: informe msg_a7c3353a8c4f/done msg_529d3a89d58a,4SHAexactos,
verify independiente460/460,0fallos/errores/omisiones,jarPASS24.375s,
2026-11-04T22:39:23-05:00.129bases verificadas,125ajenas intactas;4existentes
integrados. Legacy/list/getA24 comparados exactos retirando ramasSQLwrites.
Requestpublico/rate/receipt5campos y STEP6args2RS sinDETAILextra revisados.
GuardaA24obsoleta reemplazada segunencargo (451previos+9netos=460).
SinSQLServer/JDBC/HTTP reales ni nueva evidencia visual. A26 siguiente:
lecturas plataforma planes/usuarios/especialidades/auditoria sinwiring.


A26 ACEPTADA: informe msg_83b0af00a8fc/done msg_7132631cf5b7,4SHAexactos,
verify independiente476/476,0fallos/errores/omisiones,jarPASS24.161s,
2026-11-04T22:50:23-05:00.129bases verificadas,128ajenas intactas;1existente+
3nuevos integrados. Legacy methods/domain/TENANT_QUERY comparados exactos.
SAD/4SP/proyecciones21/6/5/7/JSONprofundo/nullable revisados personalmente.
SinSQLServer/JDBC/HTTP reales ni nueva evidencia visual. Siguiente A27:
tenants/tenant/status plataforma,mismos4archivos,secuencia sin solapamiento.


A27 ACEPTADA: informe msg_c5143cfe6847/done msg_0828a8d66f1f,4SHAexactos,
verify independiente486/486,0fallos/errores/omisiones,jarPASS24.474s,
2026-11-04T23:00:00-05:00.132bases verificadas,128ajenas intactas;4existentes
integrados. Legacy/A26 comparados exactos retirando3ramasSQL y sqlDomainnuevo.
Proyeccion29+2Settings,DATEcanonico,usageLongsinclamp,status1SP y callbackURL
antescommit revisados personalmente. SinSQLServer/JDBC/HTTP reales ni nueva
visual. Siguiente A28 planesmutadores y createUser plataforma,mismos4archivos.


A28 ACEPTADA: informe msg_f9d280a13f7b/done msg_a044799c9eef,4SHAexactos,
verify independiente496/496,0fallos/errores/omisiones,jarPASS26.359s,
2026-11-04T23:09:10-05:00.132bases verificadas,128ajenas intactas;4existentes
integrados. PlatformService entero comparado exacto retirando2ramasSQL.
Plan1SP/json16/Boolean y USER_CREATE->PLATFORM_USERS mismaREQUIREDmodelada,
proyeccion5campos/nullable,sinpassword revisados personalmente. D-36.Avigente.
SinSQLServer/JDBC/HTTP reales ni nueva visual. A29 siguiente:createTenant/pay,
mismos4archivos para completarPlatformService aislado,sinwiring.


A29 ACEPTADA: informe msg_d32e530bbbf9/done msg_cbed31986756,4SHAexactos,
verify independiente509/509,0fallos/errores/omisiones,jarPASS25.680s,
2026-11-04T23:19:29-05:00.132bases verificadas,128ajenas intactas;4existentes
integrados. PlatformService entero comparado exacto retirando2ramasSQL.
Ownerlookup oUSER_CREATE->TENANT_CREATE mismaREQUIRED/Settingsantescommit y
pago1SP/proyeccion8/nullable revisados personalmente. PlatformServicecompleto
solo constructorSQLaislado,sin wiring. Sinmotor/JDBC/HTTP/cobrosreales ni nueva
visual. Siguiente A30 OrganizationService lecturas simples (5SP).


A30 ACEPTADA: informe msg_7e0a095350d3/done msg_f9c5704373f7,4SHAexactos,
verify independiente526/526,0fallos/errores/omisiones,jarPASS27.017s,
2026-11-04T23:29:31-05:00.132bases verificadas,131ajenas intactas;1existente+
3nuevos integrados. Legacytarget/metodos comparados exactos retirandoramasSQL.
CincoSP/proyecciones/tenantADMocualquierActor/Access.branchprevio/perfilJSON
profundo revisados personalmente. SinSQLServer/JDBC/HTTP reales ni nueva
visual. Siguiente A31 configuracionorganizacion8RS,sinwiring.


A31 ACEPTADA: informe msg_424f833e4d0f/done msg_a58307547146,4SHAexactos,
verify independiente539/539,0fallos/errores/omisiones,jarPASS27.129s,
2026-11-04T23:40:26-05:00.135bases verificadas,131ajenas intactas;4existentes
integrados. OrganizationService entero comparado exacto retirando rama/helperSQL.
8RS->36root/10member,pairs/FKcoherencia,nullable/profiles/tenantid y31campos
revisados personalmente. SinSQLServer/JDBC/HTTP reales ni nueva visual.
Siguiente A32 suscripcion/sedes/areas/especialidades,mismos4archivos,sinwiring.


A32 ACEPTADA: informe msg_71f05e1a1c40/done msg_fd75823486a6,4SHAexactos,
verify independiente550/550,0fallos/errores/omisiones,jarPASS27.145s,
2026-11-04T23:52:45-05:00.135bases verificadas,131ajenas intactas;4existentes
integrados. OrganizationService entero comparado exacto retirando4ramasSQL.
CuatroSP/flagsPOSTPUT/JSONwhitelist/retorno8RSoretorno1fila/mappers dentroTX
revisados personalmente. SinSQLServer/JDBC/HTTP reales ni nueva visual.
Siguiente A33 miembros para completarOrganizationServiceaislado,sinwiring.


A33 ACEPTADA: informe msg_d311fac232b9/done msg_2b6a57ca0aa1,4SHAexactos,
verify independiente562/562,0fallos/errores/omisiones,jarPASS28.502s,
2026-11-05T00:03:02-05:00.135bases verificadas,131ajenas intactas;4existentes
integrados. OrganizationService entero comparado exacto retirando1ramaSQL.
Existing1SP/newUSER_CREATE->MEMBER_SAVE mismaREQUIRED/proyeccion7 yJSON4
revisados personalmente. OrganizationServicecompleto aislado,sinwiring.
SinSQLServer/JDBC/HTTP reales ni nueva visual. Siguiente A34pacienteslist/get/
save;vinculos/historialporpaquete siguiente,sinfuncionalidadclinicanueva.


A34 ACEPTADA: informe msg_5d34d753067c/done msg_882450fc3223,4SHAexactos,
verify independiente580/580,0fallos/errores/omisiones,jarPASS27.747s,
2026-11-05T00:18:22-05:00.135bases verificadas,134ajenas intactas;1existente+
3nuevos integrados. Legacycuerposlist/get/save/link/history comparados exactos.
Proyeccion11/JSON7/contactodeepinmutable/limits3998y200000/revisionSPI
revisados personalmente. SinSQLServer/JDBC/HTTP reales ni nueva visual.
Siguiente A35 vinculos/historial para completarPatientServiceaislado,sinwiring.


A35 ACEPTADA: informe msg_3c7ca8ecdd84/done msg_204102e38321,4SHAexactos,
verify independiente593/593,0fallos/errores/omisiones,jarPASS28.715s,
2026-11-05T00:29:55-05:00.138bases verificadas,134ajenas intactas;4existentes
integrados. Legacy/A34 publicpaths comparados exactos retirando2ramasSQL.
LinkPORTAL6campos/History4RS13-8-16+limits/contextroles separados yreferencias
fueraTOP200 revisados personalmente. PatientServicecompleto aislado,sinwiring.
SinSQLServer/JDBC/HTTP reales ni nueva visual. Siguiente A36agendalecturas;
reservas/transiciones por paquete posterior,sin ampliar alcance funcional.


A36 DEVUELTA R-A36-SQL-WINDOW: informe msg_423edc262487/done msg_b6a343ead366,
4SHA ysnapshotindependiente610/610,0fallos/errores/omisiones,jarPASS28.776s
2026-11-05T00:39:56-05:00.138bases intactas,sin integrar cuatroentregables.
MotorQAconfirmado markerlocal:SQL_VARIANT_PROPERTY(86400000000)='numeric',
DATEDIFF_BIG(microsecond,93dias23h)/86400000000=93.958333333333 ypredicado>93
rechaza1. JavaDuration.toDays=93loacepta,contratoD-44. DefectopersistenciaV5:137,
nofalloenadaptador. Evidencia tmp/sqlserver-a36-window-defect.txt.
A35 sigueultimocodigoaceptado. Corregir viaV9incremental(noeditarV1-V8),
soloALTERusp_appointments_list yregresionmotorrollback-only;4SHAJavaA36congelados.

A39 aceptada en implementación aislada: verify independiente 692/692 y jar PASS. D-47 y revisión técnica confirman los cuatro SP y preservación de auditoría; no hay QA real de firmas/publicación, SQL Server/JDBC/HTTP o wiring. Siguiente A40 PortalService documental.
SQL-01.A39 DocumentService delegada task_fdc6d0edfca3 / ctx_5da265b27a38,
dependencia A38 settled. A39 aceptada tras revisión independiente, cuatro archivos integrados; sin DB,
wiring, JDBC/HTTP o edición de shared docs/producto. Worktree preservado con
cambios acumulados de tareas anteriores.

SQL-01.A40 preparada para PortalService.documents, con D-48 y ownership secuencial sin solapamiento con A39. A39 integrada en health/production-wave0: 814f3bc. main intacta.

SQL-01.A40 PortalService.documents delegada task_06825ad3435d / ctx_f5dea8dd3f6a,
dependencia A39 settled. Cuenta efectiva verificada; un solo worker y ownership
sin solapamiento, cuatro rutas. En curso, sin wiring ni QA motor.

SQL-01.A41 preparada para PortalService.appointments tras A40 integrada 3b49ab1.
Solo esta lectura y su store/tests; sin SQL/JDBC/HTTP real ni wiring.

SQL-01.A42 preparada para PortalService.patients tras A41 integrada 57fddb7;
solo este listado y su adaptador/tests. Sin vínculo real SQL/JDBC/HTTP ni wiring.

SQL-01.A43 preparada para PortalService.balance tras A42 integrada d6b32c2.
Solo este método/store/tests; vínculos/guards y wiring real quedan pendientes.

SQL-01.A43 PortalService.balance delegada task_52d6d531ea9e / ctx_331ec5fb3ea3,
dependencia A42 settled. Ownership cuatro archivos, cuenta y sesión verificadas.

SQL-01.A44 preparada: FinanceService balance/movements/post; V6 ya contiene SP
parametrizados y grants runtime. Implementación aislada no activa ni valida JDBC.

SQL-01.A44 FinanceService balance/movements/post delegada task_f78192a4223f /
ctx_1ea57539fc82; V6 contract existente; revisión pendiente, sin wiring/SQL real.

A44 cierre efectivo: cuatro archivos integrados y push 9ae3df1 en health/production-wave0. A45 preparada para lecturas de inventario; D-53. SQL-01 sigue EN_CURSO, sin activacion del backend SQL Server.

A45 delegada task_ee48477242f6 / ctx_6d830951f6fc, dependencia A44 settled.
Programador efectivo confirmado por /status: mendozadeafabisa@gmail.com, sesion
01a19e4c-15af-74e0-a1b9-75fc7093b98f; IdentityOnly de ambos roles coincide.
Mismo terminal/worktree y --no-daemon, cuatro rutas de inventario exclusivas.
Estado Orca dispatched; pendiente entrega y revision independiente. No se
activaron SQL Server/JDBC/HTTP ni se modifico main.
