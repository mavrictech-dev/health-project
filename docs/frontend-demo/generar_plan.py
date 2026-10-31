"""Genera documentación del plan; no implementa la aplicación de Health Project."""
import json
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
DOCS = HERE.parent
design = json.loads((DOCS / 'diseno/Trazabilidad_Diseno.json').read_text(encoding='utf-8'))
catalog = json.loads((DOCS / 'catalogs/Catalogo_Especialidades_Health_Project.json').read_text(encoding='utf-8'))

PATTERNS = {
    'A': ('AUTH_DEMO', 'Acceso ficticio', ['Button', 'Field', 'Input'], 'validar identidad ficticia y activar sesión de demo'),
    'N': ('NAV_ROUTE', 'Ruta o pestaña con contexto', ['Button', 'Breadcrumb', 'Tabs'], 'abrir destino y conservar contexto y filtros de origen'),
    'I': ('FILTER_INLINE', 'Filtro en la pantalla', ['Input', 'Combobox', 'Date Picker'], 'cambiar consulta y resultados visibles sin escritura de negocio'),
    'S': ('SELECT_CONTROL', 'Selección o cambio de vista', ['Select', 'Combobox', 'Tabs', 'Toggle Group'], 'seleccionar un valor compatible o una vista sin confirmación persistida implícita'),
    'G': ('GRAPH_CONTROL', 'Gráfico y selección semántica', ['Button', 'Toggle Group', 'Tooltip'], 'seleccionar estructura o vista y mostrar su equivalencia textual'),
    'F': ('FORM_SHEET_RIGHT', 'Captura en panel derecho', ['Sheet', 'Field', 'Input', 'Select', 'Button'], 'abrir captura; guardar aplica la operación descrita cuando no sea solo borrador de otra acción'),
    'W': ('WIZARD_SHEET_RIGHT', 'Pasos en un panel derecho', ['Sheet', 'Progress', 'Field', 'Button'], 'avanzar entre pasos conservando captura y confirmar al final cuando corresponda'),
    'V': ('DETAIL_SHEET_RIGHT', 'Detalle o comparación en panel derecho', ['Sheet', 'Tabs', 'Table', 'Scroll Area'], 'mostrar evidencia, detalle o comparación sin alterar los registros consultados'),
    'R': ('REVIEW_SHEET_RIGHT', 'Revisión y confirmación en panel derecho', ['Sheet', 'Alert', 'Button'], 'presentar alcance e impacto; aplicar el comando únicamente al confirmar'),
    'C': ('COMMAND_STATE', 'Comando en el contexto activo', ['Button', 'Spinner', 'Alert'], 'validar y cambiar estado o guardar captura; si falta formulario, abrir el pertinente'),
    'J': ('MOCK_JOB', 'Trabajo o envío simulado', ['Button', 'Progress', 'Badge', 'Alert'], 'crear o avanzar trabajo ficticio identificado y mostrar su resultado o error'),
    'L': ('CLOSE_OR_RETURN', 'Volver o conservar contexto', ['Button', 'Sheet'], 'volver o cerrar; revisar borrador cuando exista antes de abandonar'),
    'B': ('UNDO_LOCAL', 'Deshacer cambios locales', ['Button', 'Tooltip'], 'revertir solo estado local pendiente y actualizar representación'),
    'X': ('EXPORT_LOCAL', 'Descarga local', ['Button', 'Progress'], 'generar o descargar archivo ficticio local con contexto y nombre reconocible'),
    'P': ('PRINT_CLIENT', 'Impresión local', ['Button'], 'abrir vista de impresión de material ficticio con identidad y versión'),
}

# ID | rutas (varias superficies pueden compartir ID) | feature | lote | componentes por pantalla
SCREEN_ROWS = '''
S01|/acceso|identity|D02|Field,Input,Button,Alert
S02|/portal/acceso|portal-access|D02|Field,Input,Input OTP,Button
S03|panel global: contexto|context|D02|Sheet,Combobox,Radio Group,Badge
S04|/recuperar; /invitacion|identity|D02|Field,Input,Input OTP,Button,Alert
S05|/app/configuracion/organizacion|organizations|D02|Tabs,Table,Sheet,Field
S06|/app/configuracion/equipo|memberships|D02|Table,Badge,Sheet,Checkbox
S07|/app/configuracion/servicios|services-pricing|D06|Tabs,Table,Sheet,Date Picker
S08|/app/configuracion/especialidades|specialty-configuration|D04|Combobox,Table,Tabs,Sheet
S09|/app/pacientes|patients|D03|Input,Table,Dropdown Menu,Sheet
S10|/app/pacientes?paciente=id&tab=ficha&dominio=humano|patients-human|D03|Tabs,Field,Sheet,Badge
S11|/app/pacientes?paciente=id&tab=ficha&dominio=animal|patients-animal|D03|Tabs,Combobox,Sheet,Table
S12|/app/pacientes/duplicados|patient-identity|D03|Table,Sheet,Radio Group,Alert
S13|/app/veterinaria/poblaciones|animal-populations|D08|Table,Sheet,Date Picker,Tabs
S14|/app/agenda|scheduling|D03|Calendar,Toggle Group,Popover,Sheet
S15|/app/agenda/solicitudes|booking-requests|D03|Tabs,Table,Badge,Sheet
S16|/app/recepcion|reception-queue|D03|Table,Badge,Button,Sheet
S17|/app/inicio|clinical-inbox|D04|Tabs,Table,Card,Badge
S18|/app/atencion?atencion=id|encounters|D04|Tabs,Accordion,Sheet,Field
S19|/app/pacientes?paciente=id&tab=historia|longitudinal-record|D04|Tabs,Date Picker,Table,Sheet
S20|/app/ordenes|orders-followup|D04|Tabs,Table,Badge,Sheet
S21|/app/diagnostico/trabajo|diagnostic-work|D07|Table,Combobox,Badge,Sheet
S22|/app/diagnostico/muestras|specimens|D07|Table,Badge,Sheet,Field
S23|/app/diagnostico/laboratorio|laboratory|D07|Table,Field,Sheet,Tabs
S24|/app/diagnostico/imagenes|imaging|D07|Tabs,Resizable,Sheet,Table
S25|/app/atencion?atencion=id&tab=medicacion|prescriptions|D04|Table,Combobox,Sheet,Field
S26|/app/farmacia|dispensing|D07|Table,Combobox,Sheet,Badge
S27|/app/hospital/medicacion|medication-administration|D07|Table,Sheet,Field,Badge
S28|/app/documentos|documents-consents|D04|Table,Tabs,Sheet,Alert
S29|/portal/inicio|portal-dashboard|D05|Card,Item,Badge,Button
S30|/portal/citas|portal-booking|D05|Calendar,Table,Sheet,Badge
S31|/portal/documentos|portal-publications|D05|Table,Sheet,Badge,Button
S32|/portal/vinculos; /app/pacientes?paciente=id&tab=vinculos|portal-relationships|D05|Table,Sheet,Checkbox,Date Picker
S33|/app/seguimiento; /portal/seguimiento|followup-messages|D05|Tabs,Table,Textarea,Sheet
S34|/app/finanzas/presupuestos; /portal/pagos?tab=presupuestos|estimates|D06|Table,Sheet,Tabs,Field
S35|/app/finanzas/caja; /portal/pagos|cash-payments|D06|Tabs,Table,Sheet,Field
S36|/app/finanzas/comprobantes|fiscal-documents-demo|D06|Table,Badge,Sheet,Alert
S37|/app/finanzas/honorarios|professional-settlements|D06|Table,Date Picker,Sheet,Badge
S38|/app/compras|purchasing|D06|Tabs,Table,Sheet,Field
S39|/app/inventario|inventory|D06|Table,Combobox,Sheet,Badge
S40|/app/hospital/admisiones|admissions|D08|Table,Sheet,Combobox,Badge
S41|/app/hospital/recursos|occupancy|D08|Toggle Group,Card,Table,Sheet
S42|/app/hospital/estancias|inpatient-care|D08|Tabs,Table,Sheet,Chart
S43|/app/cirugia|surgery|D08|Tabs,Table,Sheet,Checkbox
S44|/app/anestesia|anesthesia|D08|Tabs,Chart,Table,Sheet
S45|/app/urgencias|emergency|D08|Table,Sheet,Badge,Field
S46|/app/especialidades?proceso=sesiones; /app/especialidades?proceso=transfusion; /app/especialidades?proceso=trasplante; /app/especialidades?proceso=reproduccion|advanced-episodes|D08|Tabs,Table,Sheet,Progress
S47|/app/veterinaria/programas|veterinary-population-health|D08|Table,Sheet,Chart,Field
S48|/app/configuracion/datos|import-export|D09|Table,Progress,Sheet,Alert
S49|/app/reportes|reports|D09|Chart,Table,Date Picker,Sheet
S50|/app/auditoria|demo-audit|D09|Table,Combobox,Date Picker,Sheet
S51|/app/plataforma|subscription-support|D09|Tabs,Table,Sheet,Progress
S52|/operacion/inicio|platform-operations|D09|Tabs,Table,Sheet,Badge
S53|/app/cuenta; /portal/cuenta; /operacion/cuenta|account|D02|Tabs,Field,Switch,Sheet
S54|/app/configuracion/integraciones|integration-jobs|D09|Tabs,Table,Sheet,Badge
S55|/app/configuracion/agenda|availability-resources|D03|Calendar,Table,Sheet,Field
S56|/operacion/acceso|operations-access|D02|Field,Input,Input OTP,Button
'''

# ID | dominio de estado | campos del contrato de flujo | reglas específicas de validación
FLOW_ROWS = '''
F01|identity-session|personaDemo,membresia,sucursal|Identidad ficticia activa; membresía vigente; elegir solo sucursales del espacio.
F02|workspace-context|organizacion,sucursal,borrador,decisionSalida|Resolver captura pendiente; no cambiar de custodio el encuentro ya creado.
F03|access-recovery|cuentaFicticia,codigoDemo,paso|No almacenar credenciales reales; código preparado y vigencia simulada.
F04|draft-resolution|borrador,revisionBase,revisionRemota,camposResueltos|No sobrescribir revisión diferente sin comparación explícita.
F05|organizations|nombre,tipo,identificadorFicticio,sucursales,zonaHoraria|Campos de configuración esenciales; ID único; zona de sucursal válida.
F06|memberships|personaFicticia,rol,sucursales,credencialesDemo,alcance|Invitación y membresía únicas; revisión explícita de alcance.
F07|permission-assignments|membresia,accionesPermitidas,sucursales,suplente,motivo|Administrador demo con alcance; suplente vigente; conservar autoría anterior.
F08|specialty-templates|perfil,version,campos,atlas,paquete,alcance|Versión publicada inmutable; capturas anteriores conservan su esquema.
F09|availability|profesional,recurso,sucursal,inicio,fin,zonaHoraria|Intervalo válido; bloqueos y citas revisados; capacidad y conflictos.
F10|human-patients|identificadores,nombre,fechaNacimiento,contactos,representante|Dominio humano; búsqueda de coincidencias; no datos reales para presentar.
F11|animal-patients|identificacion,nombre,especie,raza,sexo,fechaNacimiento,responsables|Especie explícita; persona responsable y animal diferenciados.
F12|responsible-relationships|paciente,persona,tipo,alcance,inicioVigencia,finVigencia,evidenciaDemo,motivo|Vigencia y alcance coherentes; revocación no borra historia.
F13|identity-merge|fichaFuente,fichaConservada,camposConservados,referencias,motivo|Mismo dominio y organización; revisar discrepancias; preservar originales.
F14|animal-population-memberships|poblacion,tipo,animal,inicio,fin,destino,motivo|Pertenencia temporal; no sustituir la identidad individual.
F15|record-queries|paciente,identificador,dominio,rangoFechas,procedencia|Misma organización y alcance; compartir entre sucursales autorizadas.
F16|appointments|paciente,servicio,profesional,sucursal,lugar,recurso,inicio,fin|Intervalo disponible, dominio compatible y operación idempotente.
F17|portal-booking-requests|vinculo,paciente,organizacion,servicio,horarios,alternativa|Vínculo vigente; solicitud y reserva diferenciadas; oferta no vencida.
F18|appointment-changes|cita,nuevoIntervalo,motivo,decision|Estado permite cambio; nueva disponibilidad; no liberar cita al abrir captura.
F19|waitlist|paciente,servicio,preferencias,oferta,vencimiento,motivo|Una oferta vigente; intervalo aún libre al aceptar; estado de espera válido.
F20|arrival-queue|paciente,cita,servicio,profesional,llegada,motivo|Una cola activa por llegada; identidad verificada en demo; retiro explícito.
F21|encounters|paciente,origen,profesional,especialidad,borrador,resumen,pendientes|Contexto y autoría; no duplicar encuentro activo; revisar antes de cierre.
F22|form-responses|plantillaVersion,seccion,respuestas,observacion,estadoDesconocido|Validar contra esquema elegido; desconocido no equivale a negativo.
F23|anatomical-annotations|atlasVersion,vista,estructura,lateralidad,hallazgo,procedimiento|Estructura válida de atlas; semántica además del color; dominio y especie.
F24|odontogram|denticion,especie,pieza,cara,condicion,procedimiento,revision|Pieza/cara válidas; dentición compatible; diferenciar observado y realizado.
F25|observations-instruments|parametro,valor,unidad,fecha,referencia,instrumentoVersion,respuestas|Unidades y referencias compatibles; resultados identificados como demostración.
F26|clinical-attachments|archivoFicticio,tipo,tamano,contexto,fecha,asociacion|Validación local de tipo/tamaño; conservar referencias; liberar URLs temporales.
F27|document-signatures-demo|documento,revision,autor,contenido,decision|Firmar solo revisión vigente; evidencia ficticia e inmutabilidad posterior.
F28|document-addenda|original,motivo,correccion,revision,autor|Original firmado de demo; adenda enlazada y motivo obligatorio.
F29|longitudinal-episodes|episodio,tipo,antecedente,problema,alergia,estado,origen|Mismo paciente y espacio; fecha/origen; no borrar estados anteriores.
F30|clinical-orders|tipo,servicio,paciente,atencion,prioridadEjemplo,destino,motivo|Servicio compatible; emisión crea tareas; no cancela silenciosamente lo realizado.
F31|diagnostic-tasks-specimens|tarea,muestra,tipo,identificador,fecha,actor,receptor,motivo|Identidad y orden conciliadas; aceptación y rechazo distintos; trazabilidad.
F32|lab-reports|muestra,parametro,valor,unidad,referencia,version,estado,correccion|Unidad y estado válidos; preliminar no es final; corrección conserva original.
F33|imaging-reports|orden,estudio,adquisicionFicticia,paciente,informe,revision,discrepancia|Conciliar identidad; visor de demo; firma simulada sobre revisión vigente.
F34|result-review|resultado,revisionClinica,responsable,fecha,seguimiento,aclaracion|Revisión explícita del profesional; pendiente con responsable vigente.
F35|prescriptions|paciente,medicaciones,producto,dosis,unidad,via,frecuencia,duracion,version|Ejemplos ficticios; revisión y versión emitida; sin prescripción automática.
F36|dispensing|receta,producto,lote,cantidad,entrega,motivoDevolucion|Stock disponible; lote habilitado en fixture; entrega única; devolución vinculada.
F37|medication-administration|orden,dosis,hora,actor,estado,motivo|Diferenciar administrada y no realizada; orden vigente y paciente correcto.
F38|documents-consents|plantilla,emisor,paciente,contenido,participante,alcance,decision,canal|Decisión explícita y alcance; cierre no publica por sí solo.
F39|portal-links|persona,paciente,organizacion,alcance,vigencia,evidenciaDemo|Identidad y relación ficticias verificadas; no acceso por nombre o contacto solo.
F40|portal-publications|documentoVersion,destinatarios,alcance,canal,motivo|Versión elegida; vínculos vigentes; retirar visibilidad conserva evidencia.
F41|followup-messages|paciente,tarea,responsable,fecha,conversacion,mensaje,resultado|Ámbito del vínculo; no comunicaciones reales; resolver con resultado.
F42|estimates|paciente,pagador,etapas,partidas,tarifa,descuento,condiciones,version|Importes en unidades menores; aceptar versión concreta; no cargo automático.
F43|charges-accounts|cuenta,servicio,importe,moneda,origen,ajuste,motivo|Cargo único; saldo derivado de movimientos; reverso conserva fuente.
F44|payments-cash|caja,cuenta,importe,moneda,medioFicticio,anticipo,devolucion,motivo|Pago y devolución ficticios; saldo suficiente; evitar doble aplicación.
F45|invoices-demo|emisor,destinatario,cargos,serieFicticia,importe,trabajo,respuesta,correccion|Comprobante rotulado demo; estado fiscal independiente del pago.
F46|professional-settlements|profesional,periodo,reglasDemo,actuaciones,ajuste,importe,pagoFicticio|Propuesta revisada; partidas trazables; no transferencia real.
F47|purchasing|solicitud,proveedorFicticio,productos,cantidades,orden,lote,vencimiento,discrepancia|Aprobación antes de orden; recepción crea stock; diferencias explícitas.
F48|inventory-movements|producto,lote,origen,destino,cantidad,actuacion,motivo,aprobacion|No stock negativo por operación; transferencia y recepción idempotentes.
F49|admissions-occupancy|paciente,dominio,solicitud,recurso,unidad,intervalo,receptor|Recurso compatible y libre; una ocupación activa; reservar no es admitir.
F50|care-transfers-handover|estancia,cuidado,orden,fecha,excepcion,destino,receptor,pendientes|Estancia vigente; aceptación de entrega; excepción no completada.
F51|emergency|identidadConocidaOTemporal,encuentro,clasificacionRegistrada,reevaluacion,destino|No algoritmo clínico real; preservar identidad temporal y reevaluaciones.
F52|surgery-plans|paciente,procedimiento,sitio,recursos,fecha,preparacion,motivo|Revisar recursos y preparación; cambios conservan historia del caso.
F53|operative-cases|caso,verificaciones,procedimiento,implante,lote,muestra,interrupcion,parte|Casos vigentes; no asumir verificaciones; cerrar con pendientes explícitos.
F54|anesthesia-recovery|caso,evaluacion,observaciones,dosis,eventos,recuperacion,receptor|Registro ficticio fechado; transición revisada; no recomendación automática.
F55|discharge|estancia,resumen,medicacion,pendientes,responsables,entregas,control|Alta y egreso diferenciados; liberar plaza al egreso confirmado.
F56|specialized-courses|perfil,curso,planVersion,sesiones,recursos,actuacion,interrupcion|Sesión ligada a plan vigente al realizarla; conservar versiones.
F57|blood-transfusion-demo|solicitud,componente,unidad,lote,verificacionesDemo,eventos,destino|Solo trazabilidad de ejemplo; no certificación clínica de compatibilidad.
F58|transplant-episodes|episodio,participantes,evaluacion,requisitosDemo,etapa,actuacion,seguimiento|Proceso y requisitos ficticios; no cálculo de elegibilidad clínica.
F59|reproductive-cycles|ciclo,dominio,participantes,relaciones,muestras,custodia,etapa,motivo|Dominio humano/animal explícito; cadena de custodia; suspensión conserva registro.
F60|veterinary-population-health|poblacion,fecha,denominador,criterios,actuacion,excepciones,informe|Pertenencias al momento del evento; individuo y grupo diferenciados.
F61|dictation-demo|audioPreparado,transcripcionFicticia,fragmentos,borrador|Sin envío de audio ni inferencia real; revisión humana antes de copiar.
F62|integration-jobs|conexion,trabajo,operationId,payloadFicticio,estado,error,resolucion|Reintento sobre mismo trabajo; no duplicar efectos de negocio.
F63|assisted-booking-demo|solicitud,paciente,horario,condiciones,anticipoFicticio,resultado,tarea|Propuesta no confirmada; sin tarjeta real; resolución o entrega a recepción.
F64|local-import-export|archivoFicticio,formato,esquema,filas,errores,lote,contenido,manifiesto|Validar antes de aplicar; lote idempotente; solo descargas locales.
F65|reports-demo-audit|reporte,definicion,periodo,filtros,ambito,eventos,formato|Reporte derivado del ámbito permitido; exportar lo filtrado; no auditoría forense real.
F66|support-access|caso,evidenciaFicticia,finalidad,datos,operador,vencimiento,decision|Concesión explícita, limitada y revocable; cerrar revoca acceso del caso.
F67|subscription-demo|plan,periodo,consumoFicticio,propuesta,condiciones,pagoFicticio|Contratación y cobro simulados; revisar vigencia e importe.
F68|offboarding-demo|organizacion,motivo,fecha,impacto,paquete,recepcion,conservacion|Confirmar entrega y cierre; no eliminación silenciosa de datos.
F69|incidents-recovery-demo|incidente,ambito,impacto,recuperacion,evidenciaFicticia,tareas|Escenario ficticio; retorno revisado; pendientes posteriores con responsable.
F70|portal-session|personaFicticia,invitacion,vinculo,paciente,organizacion|Solo vínculos vigentes; volver a consultar contenido al cambiar selección.
F71|portal-reading|publicacion,documentoVersion,vinculo,emisor,archivoFicticio|Lectura de versión publicada accesible; registrar descarga de demo.
F72|specialty-renderers|perfil,componente,estructura,atlasVersion,esquemaVersion,registro,visitas|Componente adecuado; tabla equivalente; comparación de variantes compatibles.
F73|connections-demo|proveedor,finalidad,alcance,permisosDemo,prueba,trabajos|Sin OAuth real; activación revisada y revocación conserva evidencia.
F74|account-preferences|usuarioFicticio,datos,canalFicticio,codigoDemo,preferencias,sesiones|No credenciales reales; canal pendiente hasta comprobación de demo.
F75|services-pricing-issuers|servicio,dominio,duracion,recursos,tarifa,moneda,emisor,vigencia|Importes/versiones válidos; nueva configuración no modifica usos históricos.
F76|preventive-events|paciente,dominio,actuacion,producto,lote,fecha,estado,motivo,control|Realizada y no realizada distintas; fecha de control registrada por usuario.
F77|payer-agreements-demo|convenio,paciente,servicio,coberturaFicticia,autorizacion,respuesta,pagador,importe|No consulta real a aseguradora; condiciones y saldo institucional explícitos.
F78|operator-session|operadorFicticio,codigoDemo,caso,alcance|Acceso consola separado; datos de caso según concesión y función demo.
F79|logout|sesion,borradores,trabajosPendientes,decisionSalida|No pérdida silenciosa; guardar válido antes de salir; descarte solo local.
'''

FLOW_BATCHES = {
    'D02': [1, 2, 3, 4, 5, 6, 7, 70, 74, 78, 79],
    'D03': [9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20],
    'D04': [8, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 34, 35, 38, 61, 72, 76],
    'D05': [39, 40, 41, 71],
    'D06': [42, 43, 44, 45, 46, 47, 48, 63, 75, 77],
    'D07': [31, 32, 33, 36, 37],
    'D08': [14, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60],
    'D09': [62, 64, 65, 66, 67, 68, 69, 73],
}
batch_by_flow = {f'F{n:02}': batch for batch, nums in FLOW_BATCHES.items() for n in nums}

def rows(value):
    return [line.strip().split('|') for line in value.strip().splitlines() if line.strip()]

routes = {r[0]: r for r in rows(SCREEN_ROWS)}
contracts = {r[0]: r for r in rows(FLOW_ROWS)}
flows_by_id = {f['id']: f for f in design['flows']}
assert set(contracts) == set(flows_by_id) == set(batch_by_flow)
assert set(routes) == {s['id'] for s in design['screens']}

def shell_for_route(route):
    if route.startswith('panel global:'):
        return 'CONTEXT_SHEET'
    if route in ['/acceso', '/recuperar', '/invitacion', '/portal/acceso', '/operacion/acceso']:
        return 'ACCESS'
    if route.startswith('/portal'):
        return 'PORTAL'
    if route.startswith('/operacion'):
        return 'OPERATIONS'
    return 'PROFESSIONAL'

screen_plan = []
for screen in design['screens']:
    _, route, feature, batch, components = routes[screen['id']]
    route_list = route.split('; ')
    shells = sorted({shell_for_route(r) for r in route_list})
    screen_plan.append({
        **screen,
        'routes': route_list,
        'feature': feature,
        'shell': shells[0] if len(shells) == 1 else 'MULTI_SHELL',
        'surfaceContracts': [{'route': r, 'shell': shell_for_route(r), 'actionRule': 'Mostrar solo acciones cuyo rol, contexto y finalidad corresponden a esta superficie; compartir ID de pantalla no comparte privilegios.'} for r in route_list],
        'demoBatch': batch,
        'shadcnComponents': components.split(','),
        'actionIds': [a['id'] for a in design['actions'] if screen['id'] in a['screenIds']],
        'surfaceRule': 'Los query IDs son ejemplos; los IDs reales de demo se obtienen del store. Las superficies portal aplican alcance del vínculo; S35 portal permite anticipo/saldo, no operación interna de caja.',
        'plannedStates': ['WITH_DATA', 'EMPTY', 'PENDING', 'ERROR', 'DEMO_ACCESS_DENIED'],
        'implementationStatus': 'PLANNED',
        'verificationStatus': 'NOT_RUN',
    })

action_specs = {}
for raw in (HERE / 'fuente_acciones.txt').read_text(encoding='utf-8').splitlines():
    if not raw.strip() or raw.startswith('#'):
        continue
    fid, pattern, operation, result = raw.split('|', 3)
    assert fid in contracts and pattern in PATTERNS
    action_specs.setdefault(fid, []).append((pattern, operation, result))

assert set(action_specs) == set(flows_by_id)
action_plan = []
for flow in design['flows']:
    fid = flow['id']
    originals = [a for a in design['actions'] if a['flowId'] == fid]
    specs = action_specs[fid]
    assert len(originals) == len(specs), (fid, len(originals), len(specs))
    _, resource, fields, domain_guard = contracts[fid]
    for original, (short_pattern, operation, result) in zip(originals, specs):
        pattern, surface, components, interaction = PATTERNS[short_pattern]
        roles = [r for r in original['actorCandidates'] if r not in ['SYS', 'EXT']]
        read_only = short_pattern in ['N', 'I', 'S', 'G', 'V', 'X', 'P', 'L', 'B']
        if not read_only:
            roles = [r for r in roles if r != 'AUD']
        critical_form = short_pattern in ['F', 'W'] and (
            fid in {'F07', 'F12', 'F13', 'F36', 'F39', 'F42', 'F43', 'F44', 'F48', 'F64', 'F66', 'F68', 'F73', 'F77'}
            or any(word in operation.lower() for word in ['refund', 'reverse', 'permission', 'revoke', 'payment'])
        )
        confirmation = 'Revisión lateral antes de aplicar, con objeto, alcance, impacto y motivo pertinente.' if short_pattern == 'R' or critical_form else 'Sin revisión extra al abrir o consultar; validar captura y explicar resultado al guardar.'
        action_plan.append({
            'id': original['id'],
            'label': original['label'],
            'flowId': fid,
            'screenIds': original['screenIds'],
            'routes': sorted({r for sid in original['screenIds'] for r in routes[sid][1].split('; ')}),
            'productionPhase': original['phase'],
            'demoBatch': batch_by_flow[fid],
            'sourceActorCandidates': original['actorCandidates'],
            'demoRoles': roles,
            'roleRule': 'Allowlist por ID, contexto y capacidades del rol demo. Administrar no concede escritura clínica; portal requiere vínculo vigente; AUD solo consulta; SOP requiere ámbito del caso. Validar matriz de fixtures al construir.',
            'productionPermissionStatus': original['permissionStatus'],
            'interactionPattern': pattern,
            'surface': surface,
            'panelSide': 'right' if short_pattern in ['F', 'W', 'V', 'R'] else None,
            'panelBackdrop': 'blur-8px-and-dim' if short_pattern in ['F', 'W', 'V', 'R'] else None,
            'shadcnComponents': components,
            'interaction': interaction,
            'mockOperation': operation,
            'stateResource': resource,
            'inputContractId': fid + '_INPUT',
            'inputsRule': 'Usar solo campos pertinentes a esta operación del contrato de flujo; paciente, organización, revisión y selección provienen del contexto. Si la acción abre un borrador, otra confirmación explícita aplica el cambio.',
            'guards': [*original['businessPreconditions'], domain_guard, 'Rol demo permitido, contexto correcto, objeto en estado válido y sin comando duplicado pendiente.'],
            'confirmation': confirmation,
            'expectedVisibleResult': result,
            'refreshRule': 'Recalcular selectores de entidades relacionadas, conservando filtros y selección válida; una consulta no cambia objetos de negocio.',
            'cancelRule': 'No aplicar cambios por abrir/cerrar panel; conservar o descartar solo borrador mediante elección explícita. Un reverso de objeto confirmado es otra operación con motivo.',
            'errorRule': 'Mostrar motivo y alternativa; conservar captura, no crear resultados parciales silenciosos y ofrecer reintento idempotente cuando corresponda.',
            'acceptance': [
                'La acción se encuentra en una de sus pantallas con el rol y estado adecuados.',
                result,
                'Cancelar o usar un rol/estado no permitido no modifica datos confirmados.',
                'El resultado puede comprobarse en la vista o archivo correspondiente; una notificación sola no basta.',
            ],
            'scenarioId': 'DEMO_' + fid,
            'implementationStatus': 'PLANNED',
            'verificationStatus': 'NOT_RUN',
        })

flow_contracts = []
for flow in design['flows']:
    _, resource, fields, guard = contracts[flow['id']]
    flow_contracts.append({
        'flowId': flow['id'], 'name': flow['name'], 'inputContractId': flow['id'] + '_INPUT',
        'stateResource': resource, 'fieldNames': fields.split(','), 'domainGuard': guard,
        'trigger': flow['trigger'], 'preconditions': flow['preconditions'],
        'expectedEnd': flow['end'], 'sourceScreenIds': flow['screens'],
        'stepsReference': '../diseno/02_Flujos_y_Diagramas.md#' + flow['id'].lower(),
        'demoBatch': batch_by_flow[flow['id']],
        'fixtureRule': 'Crear una instancia satisfactoria y una alternativa preparada coherentes con las precondiciones y ramas del flujo fuente.',
        'implementationStatus': 'PLANNED',
    })

UX_ROWS = '''
UX01|Elegir blanco|SELECT_CONTROL|Cambia todos los tokens a light y persiste la preferencia.
UX02|Elegir negro|SELECT_CONTROL|Cambia todos los tokens a dark y persiste la preferencia.
UX03|Elegir navy|SELECT_CONTROL|Cambia tokens a navy y activa color-scheme oscuro.
UX04|Colapsar navegación|COMMAND_STATE|Alterna sidebar amplia e iconos y conserva nombres accesibles.
UX05|Abrir navegación móvil|FORM_SHEET_RIGHT|Abre menú desde la derecha con foco contenido y backdrop.
UX06|Buscar globalmente|FORM_SHEET_RIGHT|Busca entidades permitidas del contexto y navega al ID seleccionado.
UX07|Abrir notificaciones|DETAIL_SHEET_RIGHT|Muestra avisos ficticios propios y enlaces a su objeto.
UX08|Marcar aviso leído|COMMAND_STATE|Actualiza lectura y contador de la persona demo.
UX09|Cambiar rol de demo|REVIEW_SHEET_RIGHT|Resuelve borrador y cambia identidad/rol preparado conservando datos de escenario.
UX10|Elegir escenario|REVIEW_SHEET_RIGHT|Carga escenario y fecha preparados después de revisar reinicio.
UX11|Reiniciar demo|REVIEW_SHEET_RIGHT|Restaura fixtures, trabajos, borradores y reloj del escenario de forma completa.
UX12|Preparar fallo simulado|SELECT_CONTROL|Activa un error determinista de agenda, guardado, integración o recurso.
UX13|Cerrar panel|CLOSE_OR_RETURN|Cierra Sheet o muestra decisión si hay captura pendiente; restaura foco.
UX14|Volver al paso anterior|COMMAND_STATE|Retrocede en el mismo panel conservando valores y selección.
UX15|Continuar paso|COMMAND_STATE|Valida los campos del paso y avanza sin confirmar negocio prematuramente.
UX16|Confirmar revisión del panel|COMMAND_STATE|Ejecuta el comando asociado al ID de negocio revisado, una sola vez.
UX17|Guardar captura del panel|COMMAND_STATE|Valida y llama la acción de guardado o el comando asociado al flujo; no crea operación genérica sin contrato.
UX18|Cancelar captura|CLOSE_OR_RETURN|Abandona captura tras resolver cambios locales y deja entidades confirmadas intactas.
UX19|Seguir editando|CLOSE_OR_RETURN|Vuelve de la revisión de salida a los valores ya capturados.
UX20|Descartar cambios locales|REVIEW_SHEET_RIGHT|Descarta borrador seleccionado y conserva versiones ya confirmadas.
UX21|Guardar borrador desde salida|COMMAND_STATE|Guarda por la acción de negocio correspondiente antes de volver o cerrar.
UX22|Ordenar, filtrar y paginar tabla|FILTER_INLINE|Cambia conjunto visible con filtros combinables y conserva el ámbito permitido.
UX23|Cambiar pestaña o sección|SELECT_CONTROL|Activa sección válida sin perder contexto ni captura local.
UX24|Cambiar densidad|SELECT_CONTROL|Alterna espaciado de tabla sin ocultar información esencial.
UX25|Abrir acciones de fila|SELECT_CONTROL|Muestra acciones del registro con disponibilidad y motivo por ID.
UX26|Limpiar filtros|FILTER_INLINE|Restaura filtros del área y vuelve a la primera página.
UX27|Zoom y ajuste de gráfico|GRAPH_CONTROL|Ajusta vista del gráfico sin modificar anotaciones; permite reset de vista.
UX28|Mostrar leyenda y tabla accesible|DETAIL_SHEET_RIGHT|Presenta significados, unidades y registros equivalentes del componente.
UX29|Vista de impresión|PRINT_CLIENT|Abre formato blanco del documento o tabla ficticios seleccionados.
UX30|Reintentar carga de pantalla|MOCK_JOB|Reejecuta consulta demo conservando contexto y filtros y sin duplicar comandos.
UX31|Descargar archivo ficticio de ejemplo|EXPORT_LOCAL|Descarga plantilla CSV/JSON o documento local rotulado para demostración.
UX32|Restablecer reloj de escenario|REVIEW_SHEET_RIGHT|Vuelve a la fecha preparada y revisa cualquier reinicio relacionado.
'''
ux_controls = [dict(zip(['id', 'label', 'interactionPattern', 'expectedVisibleResult'], r), implementationStatus='PLANNED', verificationStatus='NOT_RUN') for r in rows(UX_ROWS)]

family_plan = []
FAMILY_RENDERERS = {
    'FORM': 'Formulario dinámico contra esquema versionado; no reemplaza el gráfico requerido.',
    'ANATOMY': 'Atlas SVG por órgano/especie con estructura, lateralidad, selección y anotación semántica.',
    'HUMAN_DENTAL': 'Dentición humana temporal/permanente/mixta con pieza/cara, condición y procedimiento.',
    'VET_DENTAL': 'Atlas dental por especie y dentición con nomenclatura propia de cada perfil.',
    'PERIODONTAL': 'Cuadrícula y dibujo por sitio con mediciones, unidad y comparación por diente.',
    'ENDO': 'Raíces y conductos con registros por estructura y procedimiento.',
    'ORTHODONTIC': 'Oclusión y cefalometría de ejemplo con puntos/medidas y versiones.',
    'PROSTHETIC': 'Mapa de piezas, dispositivos y plan protésico con etapas y laboratorio.',
    'GROWTH': 'Curvas y tabla con edad, unidad, referencia y dominio/especie apropiados.',
    'TRENDS': 'Series por parámetro y unidad con filtros y tabla equivalente.',
    'TIMELINE': 'Eventos por tiempo y origen, con detalle y estados.',
    'SCALES': 'Instrumento versionado, respuestas y resultado de demo identificado.',
    'PHOTO': 'Galería ficticia por sitio y fecha con comparación y anotación.',
    'IMAGING': 'Visor de estudios ficticios y metadatos; anotaciones/informe sin integración PACS real.',
    'SIGNAL': 'Trazado/reproductor de señal, audio o vídeo preparado con tiempo y marcadores.',
    'SURGERY': 'Secuencia de caso, sitio, dispositivos y hoja anestésica con eventos.',
    'HOSPITAL': 'Hoja temporal de cuidados, entradas/salidas y tareas por turno.',
    'MEDICATION': 'Lista conciliada, receta y cuadrícula de dosis/administraciones.',
    'REPRODUCTION': 'Ciclo y vínculos de participantes, muestras, descendencia y custodia.',
    'LAB': 'Orden-muestra-resultado, unidades, referencias y trazabilidad.',
    'POPULATION': 'Población, pertenencias, denominador, cobertura y eventos grupales.',
    'FUNCTION': 'Mapa funcional, movilidad/rangos, sesiones y evolución.',
    'RELATIONSHIP': 'Diagrama/lista de vínculos con tipo, vigencia y alcance.',
    'REPORT': 'Documento versionado con emisor, destinatario y impresión.',
    'DEVICE': 'Mapa/lista de dispositivos, ubicación, lote y eventos.',
    'TRIAGE': 'Secuencia de urgencia con clasificación registrada y reevaluaciones, sin algoritmo clínico real.',
    'VISION': 'Registro por ojo, refracción/campo visual y comparación con atlas correspondiente.',
    'HEARING': 'Audiograma o registro de audición/comunicación con lados, unidades y tabla.',
    'GENETICS': 'Pedigrí y registros genéticos ficticios con relaciones y procedencia.',
    'QUALITY': 'Indicadores de ejemplo con fórmula, denominador y eventos fuente.',
    'CONSENT': 'Alcance, decisiones y evidencia ficticia con participantes y vigencia.',
}
assert set(FAMILY_RENDERERS) == {f['code'] for f in catalog['componentFamilies']}
for family in catalog['componentFamilies']:
    family_plan.append({
        'code': family['code'], 'name': family['name'], 'demoRendererContract': FAMILY_RENDERERS[family['code']],
        'demoBatch': 'D04', 'variantRule': 'Revisar todos los perfiles que usan esta familia; compartir renderizador no elimina variantes de órgano, especie, dentición o instrumento.',
        'profileCodes': [e['code'] for e in catalog['entries'] if family['code'] in e['componentFamilies']],
        'implementationStatus': 'PLANNED', 'verificationStatus': 'NOT_RUN',
    })

specialty_plan = [{
    'code': e['code'], 'name': e['name'], 'catalogDomain': e['catalogDomain'], 'patientDomain': e['patientDomain'],
    'capture': e['capture'], 'componentIds': e['components'], 'componentFamilies': e['componentFamilies'],
    'workflowIds': e['workflows'], 'workflowFamilies': e['workflowFamilies'],
    'demoRoute': '/app/atencion?atencion=id&especialidad=' + e['code'],
    'configurationRoute': '/app/configuracion/especialidades?perfil=' + e['code'],
    'fixtureRequirements': 'Respuestas por esquema y ejemplos para cada componente listado; atlas y variantes adecuados al dominio/especie, no solo nombre de especialidad.',
    'demoBatch': 'D04', 'implementationStatus': 'PLANNED', 'verificationStatus': 'NOT_RUN',
    'clinicalImplementationStatus': e['implementationStatus'], 'clinicalValidationStatus': e['clinicalValidationStatus'],
} for e in catalog['entries']]

action_ids = {a['id'] for a in action_plan}
assert len(action_plan) == len(action_ids) == 429
assert action_ids == {a['id'] for a in design['actions']}
assert len(screen_plan) == 56 and len(specialty_plan) == 241
assert all(s['actionIds'] for s in screen_plan)
assert all(a['demoRoles'] for a in action_plan)
assert len({a['mockOperation'] for a in action_plan}) == len(action_plan)
assert len({c['id'] for c in ux_controls}) == len(ux_controls)
assert all(a['screenIds'] and all(sid in routes for sid in a['screenIds']) for a in action_plan)

plan = {
    'schemaVersion': '1.0.0', 'date': '2026-10-13', 'status': 'FRONTEND_DEMO_PLAN_NO_APP_IMPLEMENTATION',
    'sourceDesign': '../diseno/Trazabilidad_Diseno.json', 'sourceCatalog': '../catalogs/Catalogo_Especialidades_Health_Project.json',
    'scope': 'FULL_PRODUCT_PRESENTATION_CLIENT_MOCKS',
    'themes': ['light', 'dark', 'navy'], 'modalDefault': {'component': 'Sheet', 'side': 'right', 'backdropBlurPx': 8, 'singleOverlayHost': True},
    'productionPhaseRule': 'Las fases CE/AD/DI/HO/AV/TR del diseño siguen siendo de producción. Todos los flujos están incluidos en esta demo.',
    'summary': {'flows': len(flow_contracts), 'screens': len(screen_plan), 'businessActions': len(action_plan), 'commonControls': len(ux_controls), 'specialtyProfiles': len(specialty_plan), 'componentFamilies': len(family_plan)},
    'batchActionCounts': dict(sorted(Counter(a['demoBatch'] for a in action_plan).items())),
    'patternCounts': dict(sorted(Counter(a['interactionPattern'] for a in action_plan).items())),
    'actors': design['actors'], 'screenPlan': screen_plan, 'flowContracts': flow_contracts,
    'actionPlan': action_plan, 'commonControls': ux_controls, 'componentFamilyPlan': family_plan, 'specialtyProfilePlan': specialty_plan,
    'readiness': 'Solo se valida integridad documental. Implementación, pruebas de UI y validación clínica todavía no realizadas.',
}
(HERE / 'Plan_Frontend.json').write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def md(value):
    return str(value).replace('|', '\\|').replace('\n', ' ')

doc = [
    '# Matriz de pantallas y acciones del frontend', '',
    '**Plan propuesto; ninguna acción marcada como implementada o verificada.**', '',
    'Se conservan 79 flujos, 56 pantallas y 429 acciones contextuales del diseño. Los 32 controles comunes están separados. Rutas, componentes, contratos, resultados y criterios ampliados se encuentran en [Plan_Frontend.json](Plan_Frontend.json).', '',
    'Los IDs de query son ilustrativos y serán valores del store. Varias pantallas pueden compartir una ruta; una ruta compartida no elimina su alcance o contrato. S03 es un panel global. Las superficies de portal filtran por vínculo y no dan acceso interno a caja, expedientes o equipo.', '',
    '## Pantallas y componentes', '',
    '| ID | Pantalla | Ruta o superficie | Feature | Lote | Componentes shadcn |',
    '|---|---|---|---|---|---|',
]
for s in screen_plan:
    doc.append('| ' + ' | '.join(md(v) for v in [s['id'], s['name'], '<br>'.join(s['routes']), s['feature'], s['demoBatch'], ', '.join(s['shadcnComponents'])]) + ' |')
doc += ['', '## Patrones de interacción', '', '| Código | Patrón | Comportamiento |', '|---|---|---|']
for short, (pattern, surface, components, behavior) in PATTERNS.items():
    doc.append('| ' + ' | '.join(md(v) for v in [short, surface + ' · ' + pattern, behavior]) + ' |')
doc += ['', 'F/W abren captura o pasos. La confirmación explícita aplica el comando del flujo; si el resultado dice que prepara un borrador, el cambio definitivo pertenece a la acción de confirmación correspondiente. R muestra revisión lateral y aplica la operación al confirmar. V solo consulta. C guarda o cambia estado desde el contexto activo. Ninguna operación se considera completa por mostrar un toast.', '', '## Acciones por flujo', '']
for f in flow_contracts:
    doc += [f"### {f['flowId']} · {f['name']}", '',
            f"**Lote:** {f['demoBatch']} · **Estado mock:** `{f['stateResource']}` · **Contrato:** `{f['inputContractId']}`.", '',
            '**Campos del flujo:** ' + ', '.join(f['fieldNames']) + '. Cada operación utiliza los pertinentes, no obliga a llenar todos a la vez.', '',
            '**Regla:** ' + f['domainGuard'], '',
            '| ID | Botón | Pantallas | Patrón | Operación mock | Resultado que se comprobará |',
            '|---|---|---|---|---|---|']
    for a in action_plan:
        if a['flowId'] == f['flowId']:
            short = next(k for k, v in PATTERNS.items() if v[0] == a['interactionPattern'])
            doc.append('| ' + ' | '.join(md(v) for v in [a['id'], a['label'], ', '.join(a['screenIds']), short, a['mockOperation'], a['expectedVisibleResult']]) + ' |')
    doc += ['', '**Salida del proceso:** ' + f['expectedEnd'], '']
doc += ['## Controles comunes adicionales', '', '| ID | Control | Patrón | Resultado previsto |', '|---|---|---|---|']
for u in ux_controls:
    doc.append('| ' + ' | '.join(md(v) for v in [u['id'], u['label'], u['interactionPattern'], u['expectedVisibleResult']]) + ' |')
doc += ['', '## Familias y perfiles gráficos', '',
        'Los 241 perfiles mantienen la relación con todos sus componentes del catálogo; su lista completa está en el plan JSON y en [Gráficos de especialidad](../diseno/04_Graficos_de_Especialidad.md). Los 31 contratos siguientes no son una reducción a 31 pantallas idénticas: cada familia tiene variantes requeridas por perfil.', '',
        '| Familia | Nombre | Renderizador previsto |', '|---|---|---|']
for f in family_plan:
    doc.append('| ' + ' | '.join(md(v) for v in [f['code'], f['name'], f['demoRendererContract']]) + ' |')
doc += ['', '## Conteo por lote de implementación', '', '| Lote | Acciones contextuales |', '|---|---|']
for batch, count in plan['batchActionCounts'].items():
    doc.append(f'| {batch} | {count} |')
doc += ['', 'Estos conteos validan el plan. Los estados permanecen `PLANNED` y `NOT_RUN`; no acreditan implementación de botones, gráficos o pruebas de navegador.', '']
(HERE / '03_Pantallas_y_Acciones.md').write_text('\n'.join(doc), encoding='utf-8')
print(json.dumps(plan['summary'], ensure_ascii=False))
print('Integridad de IDs, pantallas, flujos, roles demo no vacíos y operaciones: PASS')
