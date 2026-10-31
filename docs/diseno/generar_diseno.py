"""Herramienta de autoría: genera especificaciones, no desarrolla Health Project."""
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

BASE = Path(__file__).resolve().parent
ACTOR_LABELS = {}

# Una acción puede aparecer en varios contextos, con permisos y estado vigentes.
ROUTING = {
 ('F01','Elegir espacio'):['S03'],('F01','Continuar'):['S03'],
 ('F03','Recuperar acceso'):['S01','S02'],('F04','Volver a ingresar'):['S01'],
 ('F05','Invitar equipo'):['S06'],('F05','Añadir sucursal'):['S05'],
 ('F06','Aceptar invitación'):['S04'],
 ('F10','Buscar paciente'):['S09'],('F10','Registrar humano'):['S09','S10'],
 ('F11','Registrar animal'):['S09','S11'],
 ('F12','Editar relación'):['S10','S11','S32'],('F12','Revocar acceso'):['S10','S11','S32'],
 ('F15','Buscar'):['S09'],('F15','Abrir ficha'):['S09'],('F15','Ver historia'):['S10','S11','S19'],
 ('F15','Filtrar por fecha'):['S19'],('F15','Ver procedencia'):['S19'],
 ('F18','Confirmar asistencia'):['S14','S30'],('F18','Reprogramar'):['S14','S30'],
 ('F18','Cancelar cita'):['S14','S30'],('F18','Guardar cambio'):['S14','S30'],('F18','Conservar cita'):['S14','S30'],
 ('F19','Aceptar oferta'):['S30'],('F19','Rechazar oferta'):['S30'],('F19','Salir de espera'):['S15','S30'],
 ('F20','Iniciar atención'):['S16','S17'],
 ('F21','Iniciar atención'):['S17'],
 ('F23','Comparar evolución'):['S19'],('F24','Comparar odontogramas'):['S19'],
 ('F25','Ver tendencia'):['S18','S19'],('F25','Ver tabla'):['S18','S19'],
 ('F26','Adjuntar archivo'):['S18','S24','S28'],('F26','Comparar imágenes'):['S18','S24'],
 ('F27','Revisar documento'):['S18','S28'],('F27','Firmar revisión'):['S18','S28'],
 ('F27','Ver evidencia de firma'):['S28'],('F28','Crear adenda'):['S19','S28'],
 ('F28','Firmar adenda'):['S28'],('F28','Ver versiones'):['S19','S28'],
 ('F31','Aceptar tarea'):['S21'],('F31','Registrar obtención'):['S22'],
 ('F31','Imprimir identificación'):['S22'],('F31','Aceptar muestra'):['S22'],
 ('F31','Rechazar muestra'):['S22'],('F31','Registrar entrega'):['S22'],
 ('F34','Revisar resultado'):['S17','S20'],('F34','Registrar revisión'):['S20','S23','S24'],
 ('F38','Registrar decisión'):['S28','S31'],
 ('F39','Invitar al portal'):['S10','S11','S32'],('F39','Aceptar vínculo'):['S02','S32'],
 ('F40','Preparar publicación'):['S28'],('F40','Publicar documento'):['S28'],
 ('F42','Registrar aceptación'):['S34','S29'],
 ('F49','Ver plazas'):['S41'],('F49','Reservar plaza'):['S41'],
 ('F49','Registrar recepción'):['S42'],('F55','Preparar alta'):['S42'],
 ('F55','Emitir resumen'):['S28'],('F55','Confirmar egreso'):['S40'],
 ('F55','Programar control'):['S33'],
 ('F63','Continuar reserva'):['S30'],('F63','Ver condiciones'):['S30'],
 ('F63','Pagar anticipo'):['S30','S29'],
 ('F65','Inspeccionar evento'):['S50'],('F65','Exportar autorizado'):['S49','S50'],
 ('F69','Registrar incidente'):['S52'],
 ('F70','Ingresar al portal'):['S02'],('F70','Completar invitación'):['S02'],
 ('F70','Elegir paciente'):['S29'],('F70','Elegir organización'):['S29'],('F70','Ver mis citas'):['S29'],
 ('F76','Ver historial preventivo'):['S18','S19'],('F76','Emitir constancia'):['S28'],
 ('F77','Crear convenio'):['S07'],('F77','Solicitar autorización'):['S35'],
 ('F78','Ingresar a consola'):['S56'],('F78','Completar comprobación'):['S56'],
 ('F78','Abrir caso operativo'):['S52'],
 ('F79','Cerrar sesión'):['S53','S03','S29','S52'],
}

ACTION_ROLES = {
 ('F06','Invitar profesional'):['ADM'],('F06','Activar membresía'):['ADM'],
 ('F06','Revisar credenciales'):['ADM'],('F06','Reenviar invitación'):['ADM'],
 ('F07','Revocar membresía'):['ADM'],('F07','Guardar cambios'):['ADM'],
 ('F08','Publicar versión'):['ADM'],('F08','Habilitar paquete'):['ADM'],('F08','Retirar versión'):['ADM'],
 ('F12','Confirmar cambio'):['REC','ADM'],('F12','Revocar acceso'):['REC','ADM'],
 ('F12','Editar relación'):['REC','ADM'],('F12','Verificar relación'):['REC','ADM'],
 ('F12','Establecer vigencia'):['REC','ADM'],('F12','Solicitar revocación'):['PAC','RES'],
 ('F21','Finalizar visita'):['PRO'],('F21','Iniciar atención'):['PRO'],
 ('F27','Firmar revisión'):['PRO'],('F28','Firmar adenda'):['PRO'],
 ('F30','Emitir orden'):['PRO'],('F30','Cancelar orden'):['PRO'],
 ('F32','Emitir informe'):['DIA'],('F32','Corregir informe'):['DIA'],
 ('F33','Firmar informe'):['PRO'],
 ('F39','Invitar al portal'):['REC','ADM'],('F39','Definir alcance'):['REC','ADM'],
 ('F39','Revocar delegación'):['REC','ADM'],
 ('F41','Asignar responsable'):['PRO','REC'],('F41','Resolver tarea'):['PRO','REC'],
 ('F41','Enviar mensaje'):['PRO','REC'],('F41','Registrar respuesta'):['PRO','REC'],
 ('F41','Enviar respuesta'):['PAC','RES'],
 ('F46','Generar propuesta'):['CAJ'],('F46','Registrar ajuste'):['CAJ'],
 ('F46','Aprobar liquidación'):['ADM'],('F46','Registrar pago'):['CAJ'],('F46','Entregar detalle'):['CAJ'],
 ('F47','Aprobar compra'):['ADM'],('F47','Emitir orden'):['ALM'],
 ('F47','Registrar recepción'):['ALM'],('F47','Registrar discrepancia'):['ALM'],
 ('F48','Aprobar ajuste'):['ADM'],
 ('F53','Iniciar procedimiento'):['PRO'],('F53','Cerrar parte'):['PRO'],
 ('F54','Registrar evaluación'):['PRO'],('F54','Confirmar salida de recuperación'):['PRO'],
 ('F55','Emitir resumen'):['PRO'],('F55','Confirmar egreso'):['REC','ASI'],
 ('F56','Crear curso'):['PRO'],('F56','Versionar plan'):['PRO'],('F56','Cerrar curso'):['PRO'],
 ('F57','Solicitar componente'):['PRO'],('F57','Revisar verificaciones'):['DIA','PRO'],
 ('F57','Registrar entrega'):['DIA'],('F57','Registrar actuación'):['PRO','ASI'],
 ('F58','Registrar evaluación'):['PRO'],('F58','Registrar actuación'):['PRO'],
 ('F59','Crear ciclo'):['PRO'],('F59','Registrar custodia'):['DIA'],
 ('F60','Emitir informe poblacional'):['PRO'],
 ('F64','Solicitar exportación'):['ADM'],('F64','Confirmar lote'):['ADM'],
 ('F66','Autorizar acceso temporal'):['ADM'],('F66','Rechazar acceso'):['ADM'],
 ('F67','Confirmar contratación'):['ADM'],('F68','Confirmar cierre'):['ADM'],
 ('F69','Confirmar retorno'):['SOP'],
}

IMPORTANT_ACTIONS = {
 'Guardar borrador':('Atención o nota editable; datos capturados; revisión esperada vigente.','Guarda una revisión editable. No firma ni termina la visita.','Sin diálogo; mostrar confirmación del guardado real.'),
 'Guardar revisión resuelta':('Comparación completada y nueva revisión vigente.','Guarda la resolución explícita sin sobrescribir silenciosamente cambios ajenos.','Mostrar cambios comparados.'),
 'Finalizar visita':('Profesional autorizado, resumen revisado y pendientes asignados.','Finaliza la visita; no convierte resultados pendientes en revisados.','Resumen de paciente, contexto y pendientes; confirmar finalización.'),
 'Firmar revisión':('Autor habilitado, revisión exacta guardada y requisitos completos.','Firma/cierra esa revisión y conserva evidencia; el contenido original queda sin edición.','Paciente, emisor, contenido y revisión; confirmar firma.'),
 'Firmar adenda':('Adenda revisada y vinculada al original; permiso vigente.','Emite corrección nueva sin reemplazar el original firmado.','Original, motivo y contenido de corrección; confirmar.'),
 'Crear adenda':('Registro original firmado visible y permiso de corrección.','Abre borrador nuevo referenciado al original.','Sin cierre inmediato; exigir motivo en el formulario.'),
 'Emitir receta':('Prescriptor habilitado, datos y emisor revisados.','Emite receta versionada; no registra administración.','Vista previa de paciente, items y emisor; confirmar emisión.'),
 'Registrar administración':('Actor competente y asignado; orden vigente, paciente y datos reales verificados.','Registra administración realizada con ejecutor y tiempos; reintento no duplica.','Revisar identidad, orden y datos de la actuación antes de registrar.'),
 'Registrar no realizada':('Actuación/dosis identificada; motivo y responsable de revisión definidos.','Conserva excepción; no marca actuación como realizada.','Mostrar motivo y siguiente responsable.'),
 'Confirmar dispensación':('Permiso de farmacia; cantidades y lote válidos; orden verificada.','Registra entrega y movimiento de stock vinculado, una sola vez.','Resumen de paciente, producto, lote y cantidad.'),
 'Publicar documento':('Versión emitida, permiso de publicación y destinatario verificado.','Hace accesible esa versión al destinatario definido y conserva auditoría.','Mostrar vista del destinatario, versión y alcance; confirmar.'),
 'Retirar publicación':('Permiso de retirar y publicación existente.','Impide accesos futuros conforme a reglas; conserva documento e historial de publicación.','Destinatario, motivo e impacto; confirmar retiro.'),
 'Confirmar fusión':('Mismo tenant; evidencia de identidad y permiso especial; impacto revisado.','Consolida referencias conservando originales y trazabilidad.','Identidad, ficha conservada, impacto y motivo; confirmar expresamente.'),
 'Revocar membresía':('Administrador autorizado; miembro y alcance identificados.','Retira permisos futuros; conserva autoría y pendientes que requieren reasignación.','Miembro, acceso afectado y pendientes; confirmar.'),
 'Revocar delegación':('Facultad verificada para revocar ese vínculo.','Retira acceso del representante al alcance definido y conserva evidencia.','Persona, paciente/animal, alcance y motivo; confirmar.'),
 'Revocar acceso':('Actor autorizado a gestionar la relación y vínculo identificado.','Retira alcance de la relación correspondiente, sin borrar historia.','Vínculo y acceso afectado; confirmar.'),
 'Reservar cita':('Identidad/servicio/contexto elegidos y disponibilidad vigente.','Crea reserva confirmada; si el recurso cambió, conserva captura y ofrece alternativas.','Resumen previo de paciente, lugar, profesional y horario.'),
 'Enviar solicitud':('Vínculo de portal vigente y elección completa.','Crea solicitud; su estado inicial no afirma una reserva si requiere revisión.','Mostrar fecha solicitada y política de confirmación.'),
 'Cancelar cita':('Rol autorizado; cita en estado cancelable.','Cancela reserva y libera recursos aplicables; conserva motivo/historial.','Resumen de cita y condiciones; motivo cuando lo requiera política.'),
 'Cancelar orden':('Permiso vigente y estado de orden cancelable.','Detiene nuevas tareas de la orden; conserva ejecuciones parciales y resultados previos.','Ver tareas/ejecuciones afectadas y registrar motivo.'),
 'Confirmar devolución':('Pago original verificado, monto permitido y autorización aplicable.','Registra reverso financiero vinculado; no borra el pago.','Monto, medio, referencia, motivo y actor autorizante.'),
 'Emitir comprobante':('Emisor, cargos, datos y numeración revisados.','Emite un documento y sigue su respuesta externa sin duplicación.','Vista previa fiscal y resumen antes de emitir.'),
 'Confirmar admisión':('Identidad, indicación y plaza compatible confirmadas.','Activa estancia/ocupación con protección de concurrencia.','Paciente, unidad, plaza y equipo receptor.'),
 'Aceptar entrega':('Equipo receptor autorizado y pendientes recibidos.','Registra aceptación de responsabilidad y tareas transferidas.','Resumen de paciente, órdenes y pendientes; confirmar recepción.'),
 'Confirmar egreso':('Alta clínica disponible y salida física realmente producida.','Finaliza ocupación y conserva pendientes de seguimiento.','Paciente, salida y destino; no asociar al cierre de caja.'),
 'Confirmar lote':('Vista previa de importación reconciliada y permiso vigente.','Procesa lote identificado y reporta totales/rechazos sin duplicar reimportaciones.','Origen, totales, rechazo e impacto; confirmar.'),
 'Solicitar exportación':('Permiso y finalidad de exportación; alcance revisado.','Crea una exportación privada con manifiesto y entrega autorizada.','Ámbito, contenido y destinatario; confirmar solicitud.'),
 'Autorizar acceso temporal':('Responsable con facultad; caso, alcance y duración revisados.','Concede acceso limitado a soporte, auditable y revocable.','Finalidad, datos, actor y vencimiento; confirmar.'),
 'Confirmar cierre':('Baja autorizada y entrega/política revisadas.','Cierra servicio conforme al acuerdo; no elimina datos sin política aplicable.','Resumen de recepción de datos, accesos y conservación.'),
 'Publicar versión':('Versión revisada y evidencias de capacidades obligatorias completas.','Publica versión inmutable para nuevas capturas habilitadas.','Versión, alcance y evidencias; confirmar publicación.'),
 'Retirar versión':('Versión existente y facultad de gestión.','Retira para nuevas capturas según política; conserva lectura histórica.','Uso e impacto en paquetes; confirmar.'),
 'Aceptar selección':('Propuesta IA revisada por el profesional; campos elegidos.','Incorpora solo selección confirmada a borrador, sin firma automática.','Comparación y valores seleccionados visibles.'),
 'Pagar anticipo':('Servicio/cita y condiciones de pago revisados.','Inicia pago; acredita únicamente con confirmación verificable del proveedor.','Monto, concepto, condiciones y destinatario del pago.'),
 'Ver como destinatario':('Permiso de preparar publicación.','Muestra exactamente la versión y alcance que se propone compartir; no publica.','Sin confirmación; vista claramente identificada como previa.'),
 'Descargar documento':('Vínculo y publicación autorizados al momento de entrega.','Entrega versión publicada y registra descarga.','Sin confirmación adicional; identificar emisor y versión.'),
 'Reintentar operación':('Operación fallida reintentable y permiso sobre integración.','Reintenta la misma operación identificada sin duplicar efecto.','Mostrar operación y resultado previo.'),
 'Deshacer cambio local':('Cambio aún no confirmado del borrador actual.','Deshace ese cambio local; no elimina hechos firmados de otras visitas.','Sin confirmación para cambio local reversible.'),
}

def text_label(value):
    return str(value).replace('&','&amp;').replace('"', '&quot;').replace('<','&lt;').replace('>','&gt;').replace('\n',' ')

def cell(value):
    return str(value).replace('|','/').replace('\n',' ')

def graph(flow):
    lines=['flowchart TD',f'    START(["{text_label(flow["trigger"])}"]) --> N1']
    decisions=set(flow.get('decisions',[]))
    for i,step in enumerate(flow['steps'],1):
        actor,label=step.split('|',1)
        caption=text_label(ACTOR_LABELS[actor]+': '+label)
        lines.append(f'    N{i}'+ ('{"'+caption+'"}' if i in decisions else '["'+caption+'"]'))
    last=len(flow['steps'])
    lines.append(f'    END(["{text_label(flow["end"])}"])')
    for i in range(1,last+1):
        target=f'N{i+1}' if i<last else 'END'
        suffix=''
        if i in decisions:
            positive_branch=any(b['step']==i and b['label'].startswith('Sí') for b in flow.get('branches',[]))
            label='No' if positive_branch else 'Sí'
            if flow['id']=='F20' and i==2: label='Cita sin llegada previa'
            suffix=f' -->|"{label}"| '
        else: suffix=' --> '
        lines.append(f'    N{i}{suffix}{target}')
    for j,b in enumerate(flow.get('branches',[]),1):
        lines.append(f'    N{b["step"]} -->|"{text_label(b["label"])}"| A{j}["{text_label(b["action"])}"]')
        if 'resume' in b:
            lines.append(f'    A{j} --> N{b["resume"]}')
        else:
            lines.append(f'    A{j} --> E{j}(["{text_label(b["terminal"])}"])')
    return '\n'.join(lines)+'\n'

def default_action(label,flow):
    if label.startswith(('Ver ','Abrir ','Comparar ','Inspeccionar ','Buscar','Filtrar','Aplicar filtros','Elegir ','Seleccionar ')):
        return ('Recurso visible en el contexto y alcance autorizado.','Abre o actualiza la vista/selección indicada; no modifica el registro por sí sola.','Sin diálogo; conservar contexto y filtros.')
    if label.startswith(('Cancelar','Conservar','Volver','Seguir aquí','Salir')):
        return ('Existe operación/vista correspondiente; estado permite salida o cancelación.','Ejecuta la alternativa definida en el flujo; distingue abandonar formulario de cancelar un objeto persistido.','Confirmar si hay cambios locales sin guardar o impacto persistido.')
    if label.startswith(('Solicitar','Enviar','Crear','Nueva','Nuevo','Añadir','Preparar','Proponer','Definir','Editar','Programar','Asignar','Reasignar')):
        return ('Rol y contexto permitidos; objeto en estado que admite la acción.','Abre o completa captura/solicitud descrita por el flujo; revisar resumen antes de confirmar cambio persistido.','Según impacto; no confirmar solo apertura de formulario.')
    return ('Precondiciones del flujo cumplidas; permiso vigente y estado del objeto permite esta operación.','Ejecuta la acción nombrada siguiendo sus validaciones y alternativas del flujo referenciado.','Mostrar resumen si cambia estado, entrega información, dinero o permisos; motivo en reversos.')

def load():
    source=json.loads((BASE/'fuente_diseno.json').read_text(encoding='utf-8'))
    flows=[]
    for name in sorted(BASE.glob('flujos_*.json')):
        flows.extend(json.loads(name.read_text(encoding='utf-8')))
    flows.sort(key=lambda f:int(f['id'][1:]))
    screens=json.loads((BASE/'pantallas.json').read_text(encoding='utf-8'))
    screens.append({'id':'S56','name':'Acceso de operador MAVRIC','area':'SaaS','phase':'TR','actors':['SOP'],'purpose':'Autenticar al operador de plataforma sin conceder acceso clínico de clientes.','contents':['Cuenta de operador','Comprobaciones definidas por política','Estado de acceso','Ayuda de cuenta'],'flows':['F78'],'layout':'Acceso específico a consola operativa; el destino no es un expediente global.'})
    source['flows']=flows; source['screens']=screens
    by_flow={f['id']:f for f in flows}; by_screen={s['id']:s for s in screens}
    internal=['PRO','REC','ADM','ASI','DIA','FAR','CAJ','ALM','AUD']
    by_flow['F01']['actors']=internal+['SYS']
    by_flow['F03']['actors']=internal+['PAC','RES','SYS']
    by_flow['F04']['actors']=internal+['SYS']
    by_flow['F20']['steps'][1]='SYS|¿Qué tipo de ingreso corresponde?'
    by_flow['F12']['actors']=list(dict.fromkeys(by_flow['F12']['actors']+['PAC']))
    by_flow['F65']['actors']=list(dict.fromkeys(by_flow['F65']['actors']+['CAJ']))
    by_flow['F48']['actors']=list(dict.fromkeys(by_flow['F48']['actors']+['ADM']))
    by_screen['S39']['actors']=list(dict.fromkeys(by_screen['S39']['actors']+['ADM']))
    by_screen['S47']['actors']=['PRO','ASI']
    by_flow['F41']['buttons'].append('Enviar respuesta')
    by_flow['F12']['buttons'].append('Solicitar revocación')
    by_flow['F73']['steps'][6]='ADM|Elegir conservar conexión o solicitar revocación'
    ROUTING[('F12','Solicitar revocación')]=['S32']
    actor_ids={a['id'] for a in source['actors']}
    flow_ids={f['id'] for f in flows}; screen_ids={s['id'] for s in screens}
    assert len(flow_ids)==len(flows) and len(screen_ids)==len(screens)
    for f in flows:
        assert all(a in actor_ids for a in f['actors']),f['id']
        assert all(s in screen_ids for s in f['screens']),f['id']
        assert all(h in flow_ids for h in f['handoffs']),f['id']
        for step in f['steps']: assert step.split('|',1)[0] in actor_ids,(f['id'],step)
        for b in f.get('branches',[]):
            assert 1<=b['step']<=len(f['steps']),f['id']
            assert ('resume' in b) != ('terminal' in b),f['id']
            if 'resume' in b: assert 1<=b['resume']<=len(f['steps']),f['id']
        assert f['trigger'] and f['end'] and f['preconditions'] and f['steps'],f['id']
    for s in screens:
        assert all(f in flow_ids for f in s['flows']),s['id']
        assert all(a in actor_ids for a in s['actors']),s['id']
    return source

def actor_doc(source):
    actors=source['actors']; phases=source['phases']; flows=source['flows']
    lines=['# Actores, alcance y reglas de diseño','','Estado: propuesta de diseño del 13 de octubre de 2026. No se desarrolla la aplicación en esta etapa.','',
        '## Decisiones confirmadas','']+[f'- {d}.' for d in source['confirmedDecisions']]
    lines+=['','## Actores y alcance','','| ID | Actor | Alcance |','| --- | --- | --- |']
    lines += [f'| `{a["id"]}` | {a["name"]} | {a["scope"]} |' for a in actors]
    lines+=['','Un actor es una función, no necesariamente una cuenta diferente. Una persona puede desempeñar varios roles y pertenecer a varias organizaciones. El perfil clínico depende de competencia y permisos; el nombre de una especialidad no concede acceso. Paciente humano y animal son sujetos de atención: el animal no inicia sesión, lo hace su responsable verificado.','',
        '## Diagrama de actores y casos de uso principales','','```mermaid',
        'flowchart LR',
        '    ADM[Administrador] --> CFG[Configurar organización, equipo y capacidades]',
        '    REC[Recepción] --> AG[Registrar pacientes, citas y llegadas]',
        '    PRO[Profesional] --> CL[Atender, registrar, firmar y revisar pendientes]',
        '    ASI[Asistencia] --> CT[Capturas y tareas autorizadas]',
        '    DIA[Diagnóstico] --> DX[Ejecutar estudios y emitir informes]',
        '    FAR[Farmacia] --> MED[Dispensar y conservar trazabilidad]',
        '    CAJ[Caja] --> FIN[Cargos, cobros y comprobantes]',
        '    ALM[Almacén] --> INV[Compras y movimientos]',
        '    PAC[Paciente o responsable] --> PORT[Citas y publicaciones del portal]',
        '    AUD[Auditor] --> AUDIT[Inspeccionar evidencia autorizada]',
        '    SOP[Soporte MAVRIC] --> OPS[Soporte, contratos e incidentes]',
        '    EXT[Proveedor externo] --> INTEG[Operaciones externas autorizadas]',
        '```','',
        'Este diagrama es una vista de casos de uso. Las actividades y decisiones detalladas están en el documento de flujos; no se presenta como un diagrama UML de notación estricta.','',
        '## Participación por dominio','','| Dominio | Actor iniciador principal de referencia | Participantes | Responsable del cierre |','| --- | --- | --- | --- |']
    groups=defaultdict(list)
    for f in flows: groups[f['group']].append(f)
    for group,items in groups.items():
        ids=sorted({a for f in items for a in f['actors'] if a not in ['SYS','EXT']})
        lines.append(f'| {group} | {ACTOR_LABELS[items[0]["actors"][0]]} | '+', '.join(ACTOR_LABELS[a] for a in ids)+' | Según objeto: actor autorizado; el sistema registra resultado y pendientes |')
    lines+=['','El iniciador de referencia no convierte a todos los participantes en autorizantes. Por ejemplo, un paciente puede solicitar cita y recepción confirmarla; un informe técnico necesita su revisión profesional; soporte no autoriza su propio acceso excepcional. La matriz por botón precisa el contexto, y los permisos finos todavía se validarán antes de desarrollo.','',
        '## Límites y fases','','| Código | Etapa |','| --- | --- |']
    lines += [f'| `{c}` | {n} |' for c,n in phases.items()]
    lines+=['','CE identifica consulta externa y portal. AD/DI/HO/AV son capacidades posteriores o pilotos expresamente acotados. TR atraviesa las fases, con profundidad según la versión. Diseñar un flujo futuro no lo declara implementado.','',
        '## Reglas compartidas de todos los flujos','',
        '1. Confirmar organización, paciente, sucursal operativa y lugar cuando correspondan antes de escribir. El expediente pertenece a la organización; la atención conserva su sucursal de origen.',
        '2. Historia compartida entre sucursales solo mediante permisos y auditoría; no hay unión automática entre organizaciones por DNI, microchip o cuenta profesional.',
        '3. Distinguir acciones del usuario, validaciones del sistema, tareas de otros actores y respuestas externas.',
        '4. Cada operación finaliza, queda pendiente con responsable o termina con cancelación/rechazo explícitos. Un error no puede anunciar éxito.',
        '5. Guardar borrador, firmar documento, finalizar visita y cerrar episodio son acciones diferentes.',
        '6. Una orden, resultado recibido, resultado revisado, receta, entrega y administración son hechos diferentes.',
        '7. Los reintentos conservan identidad de operación y verifican resultado previo. Las ediciones concurrentes no sobrescriben silenciosamente.',
        '8. Conservar lo ejecutado antes de cancelar; corrección clínica firmada mediante adenda, reverso económico mediante movimiento vinculado.',
        '9. El portal ve publicaciones/versiones autorizadas; vínculos y representación requieren verificación y vigencia.',
        '10. Las decisiones clínicas corresponden al profesional; estos diagramas modelan operación y documentación, no protocolos de diagnóstico o tratamiento.','',
        '## Decisiones de producto pendientes de validación','',
        '| Tema | Propuesta visible en el diseño | Qué debe cerrarse |','| --- | --- | --- |',
        '| Reserva desde portal | Soportar solicitud revisada o confirmación automática según configuración | Política por servicio, recursos y organización |',
        '| Cambios de citas | Reprogramación/cancelación con historial | Plazos, anticipos y devoluciones |',
        '| Representación | Vínculos verificables con alcance/vigencia | Facultades de menores, familiares y responsables animales |',
        '| Firma | Revisión precisa y evidencia; proveedor cuando aplique | Tipos documentales y mecanismo con alcance aplicable |',
        '| Acceso clínico | Permisos de organización y contenido sensible | Relación asistencial, excepciones y roles finos |',
        '| Recursos avanzados | Verificaciones definidas por equipo especializado | Camas/jaulas, cirugía, radioterapia y otros requisitos particulares |',
        '| Soporte/impago/baja | Estados y responsables; exportación y conservación explícitas | Condiciones comerciales y política de custodia |','',
        'Los flujos son revisables sin modificar las decisiones confirmadas. Resolver estas reglas de negocio no exige construir primero la aplicación.','']
    return '\n'.join(lines)

def flow_doc(source):
    lines=['# Flujos y diagramas de principio a fin','','Estado: propuesta de diseño; sin implementación de la aplicación.','','## Cómo leer un flujo','',
        'Cada ficha indica inicio, actores, precondiciones, pasos, decisiones, alternativas y final. El actor de cada paso representa el perfil del recorrido de referencia; los participantes incluyen variantes autorizadas del mismo proceso. Los traspasos son continuaciones posibles, no pasos obligatorios en todos los casos.','',
        'Los rectángulos son acciones; los rombos, decisiones; los extremos redondeados, inicio o final de una ruta. Los diagramas son actividades de producto. La ficha textual define el significado si un estado requiere mayor precisión.','',
        '## Índice de procesos','','| ID | Proceso | Etapa | Inicio | Final |','| --- | --- | --- | --- | --- |']
    for f in source['flows']:
        lines.append('| '+' | '.join(cell(v) for v in [f'[{f["id"]}](#{f["id"].lower()})',f['name'],f['phase'],f['trigger'],f['end']])+' |')
    for f in source['flows']:
        lines += ['',f'<a id="{f["id"].lower()}"></a>',f'## {f["id"]}. {f["name"]}','',
            f'**Dominio:** {f["group"]}. **Etapa:** {source["phases"][f["phase"]]}.', '',
            '**Actores:** '+', '.join(ACTOR_LABELS[a] for a in f['actors'])+'.', '',
            '**Inicio:** '+f['trigger'], '', '**Precondiciones:** '+'; '.join(f['preconditions']), '',
            '| Paso | Actor | Acción o decisión |','| --- | --- | --- |']
        for i,step in enumerate(f['steps'],1):
            actor,label=step.split('|',1)
            lines.append(f'| {i} | {ACTOR_LABELS[actor]} | {cell(label)} |')
        lines+=['','```mermaid',graph(f).rstrip(),'```','',
            '| Desde paso | Condición o alternativa | Respuesta | Resultado |','| --- | --- | --- | --- |']
        for b in f.get('branches',[]):
            result=f'Retomar paso {b["resume"]}' if 'resume' in b else b['terminal']
            lines.append('| '+' | '.join(cell(v) for v in [b['step'],b['label'],b['action'],result])+' |')
        if not f.get('branches'): lines.append('| — | Cancelar antes de confirmar o perder autorización | Conservar estado confirmado anterior y explicar resultado | Sin operación nueva confirmada |')
        lines+=['','**Final de la ruta principal:** '+f['end'], '',
            '**Pantallas relacionadas:** '+', '.join(f['screens'])+'.', '',
            '**Acciones propuestas:** '+', '.join(f['buttons'])+'.', '',
            '**Continuaciones posibles:** '+', '.join(f'[{h}](#{h.lower()})' for h in f['handoffs'])+'.', '',
            f'**Criterio de diseño:** debe poder recorrerse hasta ese final y hasta cada alternativa documentada, manteniendo estados reales y responsables. [Diagrama independiente](diagramas/{f["id"]}.mmd).']
    return '\n'.join(lines)+'\n'

def actions_for(source):
    by_screen={s['id']:s for s in source['screens']}
    actions=[]
    for f in source['flows']:
        for i,label in enumerate(f['buttons'],1):
            screen_ids=ROUTING.get((f['id'],label),[f['screens'][0]])
            condition,effect,confirmation=IMPORTANT_ACTIONS.get(label,default_action(label,f))
            candidate_roles=sorted({a for sid in screen_ids for a in by_screen[sid]['actors'] if a in f['actors']})
            # Participantes son candidaturas; la acción exige su permiso específico y estado.
            if label.startswith(('Firmar','Emitir receta','Finalizar visita','Publicar documento','Retirar publicación')):
                candidate_roles=['PRO']
            if label=='Confirmar fusión': candidate_roles=['ADM']
            if label in ['Aceptar oferta','Rechazar oferta','Pagar anticipo','Aceptar vínculo','Ingresar al portal']:
                candidate_roles=['PAC','RES']
            if label=='Aceptar invitación' and f['id']=='F06': candidate_roles=['PRO']
            if label in ['Registrar administración','Registrar no realizada']:
                candidate_roles=[a for a in f['actors'] if a in ['PRO','ASI']]
            candidate_roles=ACTION_ROLES.get((f['id'],label),candidate_roles)
            assert candidate_roles,(f['id'],label,screen_ids)
            assert set(candidate_roles)<=set(f['actors']),(f['id'],label,candidate_roles)
            assert set(candidate_roles)<={a for sid in screen_ids for a in by_screen[sid]['actors']},(f['id'],label,screen_ids,candidate_roles)
            actions.append({'id':f'{f["id"]}_A{i:02d}','label':label,'flowId':f['id'],'screenIds':screen_ids,'phase':f['phase'],'actorCandidates':candidate_roles,'permissionStatus':'TO_VALIDATE_FINE_GRAINED','enabledWhen':condition,'effect':effect,'confirmation':confirmation,'businessPreconditions':f['preconditions']})
            for sid in screen_ids:
                if f['id'] not in by_screen[sid]['flows']: by_screen[sid]['flows'].append(f['id'])
    return actions

def frontend_doc(source,actions):
    phases=source['phases']
    lines=['# Pantallas, funciones y botones derivados de los flujos','','Estado: arquitectura de información y comportamiento propuestos. No se construye el frontend en esta etapa.','','## Orden de diseño','',
        'Revisar primero los actores y flujos. Esta especificación deriva las pantallas de sus pasos. Después se diseñarán wireframes de baja fidelidad, se probarán recorridos y se definirá el sistema visual. Las posiciones descritas son estructura funcional, no una elección final de estilo.','',
        '## Navegación por espacio y rol','','| Espacio / rol | Navegación inicial propuesta |','| --- | --- |',
        '| Profesional | Mi jornada, Agenda, Pacientes, Pendientes, Seguimiento y Configuración autorizada |',
        '| Recepción | Agenda, Llegadas, Pacientes, Solicitudes y Comunicaciones permitidas |',
        '| Administrador | Organización, Equipo, Recursos, Especialidades, Integraciones y Reportes; módulos comerciales según entrega |',
        '| Portal | Inicio, Citas, Documentos, Seguimiento, Vínculos y Mi cuenta; pagos cuando el módulo exista |',
        '| Diagnóstico | Lista de trabajo, Muestras, Resultados y Estudios según permisos |',
        '| Farmacia | Órdenes, Dispensaciones y existencias autorizadas |',
        '| Caja / almacén | Cuentas/Caja/Comprobantes/Honorarios o Compras/Inventario según rol |',
        '| Hospital | Estancias, Recursos, Tareas/Turnos, Cirugía y Urgencias según rol |',
        '| Auditor / soporte | Evidencia autorizada o consola operativa; sin navegación clínica global implícita |','',
        'El catálogo de 241 entradas no se convierte en 241 opciones de menú. La especialidad selecciona formularios y componentes dentro de la atención. Los flujos avanzados sí pueden tener espacios de trabajo específicos.','',
        '## Componentes comunes de la interfaz','',
        '| Componente | Comportamiento |','| --- | --- |',
        '| Cabecera de contexto | Organización, sucursal y rol operativos; cambio aplica F02 |',
        '| Identificación clínica | Paciente/animal, identificador y contexto visibles en captura, firma, orden y entrega |',
        '| Navegación | Mostrar funciones que el rol puede usar; estados de disponibilidad según paquete/release |',
        '| Buscador y filtros | Alcance visible, estado vacío distinto de restricción, conservar filtros al volver |',
        '| Formulario | Campos, unidades, errores junto al campo, desconocido/negado explícitos, guardado real indicado |',
        '| Gráfico | Leyenda, atlas/versión, selección semántica, tabla equivalente, comparación temporal |',
        '| Bandeja | Responsable, estado, siguiente acción y pendientes; envío no equivale a resolución |',
        '| Revisión final | Resumen de objeto/paciente/contexto antes de firma, publicación, pago o cambio de permisos |',
        '| Estado y evidencia | Mostrar autor/fecha/versión/procedencia cuando aplica; sin mensajes falsos de éxito |','',
        '## Estados que debe contemplar cada pantalla','',
        'Inicial; cargando; contenido disponible; sin resultados; acceso restringido; error recuperable; captura inválida; guardado pendiente; guardado confirmado; conflicto de revisión; sesión vencida; proveedor pendiente; objeto finalizado/cancelado. Solo se aplican los estados pertinentes al proceso. Un fallo en comunicación no borra una operación local confirmada.','',
        '## Reglas de botones y acciones','',
        '- Una acción principal por etapa; sus verbos describen el efecto: guardar, firmar, finalizar, publicar, reservar o registrar una excepción.',
        '- Un botón se habilita por rol, permiso fino, contexto, estado y datos completos. La interfaz no constituye la autorización del servidor.',
        '- Ocultar funciones ajenas al rol; si un usuario tiene permiso pero el estado impide actuar, explicar la razón junto a la acción deshabilitada.',
        '- Durante envío mostrar progreso y bloquear doble activación; ante respuesta incierta comprobar operación previa antes de reintentar.',
        '- Volver/cerrar un formulario no cancela una cita, una orden o una estancia persistidas. El abandono de cambios locales tiene su propio diálogo.',
        '- Confirmar operaciones con impacto sobre contenido firmado, destinatarios, dinero, identidad, acceso o ocupación. No pedir confirmación para cada apertura o selección reversible.',
        '- La captura y el gráfico deben funcionar con teclado y alternativa textual; estado y selección se indican con texto además de color.',
        '- Los roles de la tabla de botones son candidatos funcionales. Se valida el permiso específico antes de implementar; participar en un flujo no autoriza todos sus botones.',
        '- Un botón de capacidad futura solo entra en un release cuando su flujo/componente esté aceptado. No presentarlo como operativo por estar dibujado.','',
        '## Inventario de pantallas','','| ID | Pantalla | Etapa | Objetivo |','| --- | --- | --- | --- |']
    for s in source['screens']: lines.append(f'| [{s["id"]}](#{s["id"].lower()}) | {s["name"]} | {s["phase"]} | {s["purpose"]} |')
    for s in source['screens']:
        related=[a for a in actions if s['id'] in a['screenIds']]
        lines += ['',f'<a id="{s["id"].lower()}"></a>',f'## {s["id"]}. {s["name"]}','',
            '**Espacio:** '+s['area']+'. **Etapa base:** '+phases[s['phase']]+'.', '',
            '**Usuarios de la pantalla:** '+', '.join(ACTOR_LABELS[a] for a in s['actors'])+'.', '',
            '**Objetivo:** '+s['purpose'], '', '**Información:** '+'; '.join(s['contents'])+'.', '',
            '**Estructura funcional:** '+s['layout'], '',
            '**Flujos relacionados:** '+', '.join(f'[{fid}](02_Flujos_y_Diagramas.md#{fid.lower()})' for fid in sorted(s['flows']))+'.','',
            '| ID de acción | Botón / acción | Flujo y etapa | Roles candidatos | Se habilita cuando | Efecto esperado | Confirmación |',
            '| --- | --- | --- | --- | --- | --- | --- |']
        for a in related:
            values=[f'`{a["id"]}`',a['label'],a['flowId']+' / '+a['phase'],', '.join(a['actorCandidates']),a['enabledWhen'],a['effect'],a['confirmation']]
            lines.append('| '+' | '.join(cell(v) for v in values)+' |')
        if not related: lines.append('| — | Navegación a flujos vinculados | Según flujo | Según permiso | Contexto autorizado | Abre el proceso correspondiente | Sin cambio persistido |')
        lines+=['','**Salida y retorno:** volver al punto de entrada conservando filtros/contexto. Si existe trabajo sin confirmar, aplicar el estado de guardado/cancelación del flujo. Los botones de etapas posteriores quedan fuera de la versión hasta que su capacidad sea entregada.']
    lines+=['','## Wireframes funcionales de referencia','',
        'Estos esquemas definen jerarquía; no son pantallas implementadas ni diseño visual final.','',
        '### Atención clínica','',
        '```text',
        '[Organización] [Sucursal/lugar] [Rol]                         [Mi cuenta]',
        '[Paciente/animal confirmado] [Identificador] [Atención y estado]',
        '----------------------------------------------------------------------',
        'Resumen autorizado | Secciones de atención | Pendientes de esta atención',
        'Antecedentes        | Formulario/gráfico    | Órdenes y resultados',
        'Problemas/alergias   | Leyenda + tabla       | Receta y documentos',
        'Historia/episodio    | Validaciones          | Seguimiento',
        '----------------------------------------------------------------------',
        '[Guardar borrador] [Revisar contenido] [Finalizar visita]',
        'Firma por revisión documental: acción separada, con resumen previo.',
        '```','',
        '### Agenda y recepción','',
        '```text',
        '[Organización/sucursal] [Día/semana] [Profesional/recurso]',
        '[Calendario o lista]             [Detalle: paciente + intervalo]',
        '[Nueva cita]                     [Reservar / Reprogramar / Cancelar]',
        'Recepción: [Esperados] [Llegaron] [En espera] [En atención] [Retiro]',
        'Cada ingreso conserva su vínculo con cita y atención, si existen.',
        '```','',
        '### Portal','',
        '```text',
        '[Organización] [Paciente o animal autorizado]              [Mi cuenta]',
        '[Inicio] [Citas] [Documentos] [Seguimiento] [Vínculos]',
        'Próxima cita: estado real                 [Solicitar / Gestionar cita]',
        'Documentos publicados: emisor + versión   [Ver / Descargar autorizado]',
        'Pendientes de seguimiento: responsable/canal y próxima actuación',
        '```','',
        '## Validación del diseño antes de desarrollo','',
        '1. Recorrer cada flujo con su actor principal y sus alternativas.',
        '2. Verificar que cada paso humano tiene pantalla/acción o interacción externa documentada.',
        '3. Comprobar estados, mensajes, permisos finos y responsabilidades en cada transición.',
        '4. Revisar cada gráfico con profesionales de su área y contrastarlo con datos guardados.',
        '5. Probar wireframes con paciente humano, animal/responsable y profesional itinerante.',
        '6. Resolver decisiones pendientes y versionar el diseño aceptado antes de construir frontend/backend.','']
    return '\n'.join(lines)

def graphics_doc():
    catalog=json.loads((BASE.parent/'catalogs/Catalogo_Especialidades_Health_Project.json').read_text(encoding='utf-8'))
    family_names={x['code']:x['name'] for x in catalog['componentFamilies']}
    lines=['# Gráficos de especialidad: flujos e interacción','','Estado: requisitos de diseño; los gráficos clínicos todavía no están implementados.','','## Contrato común de un gráfico','',
        'Entrada: atención, paciente/perfil, especialidad, componente y versión autorizados. Interacción: selección de estructura, captura semántica y revisión junto a tabla. Salida: datos y revisión vinculados a la historia. Firmar sigue F27; corregir una revisión firmada sigue F28.','',
        '| Familia | Selección e información | Acción y salida | Flujo |','| --- | --- | --- | --- |',
        '| Odontograma humano/veterinario | Pieza, cara, dentición y nomenclatura apropiadas al perfil | Hallazgo/procedimiento fechado y evolución por pieza; leyenda y tabla | F24 |',
        '| Periodontograma | Pieza/sitio, medida/unidad, fecha y método aplicables | Medidas estructuradas y comparación; atlas y sitios específicos se validan | F72 + F25 |',
        '| Raíces y conductos | Pieza/raíz/conducto, datos y etapa registrada | Registro semántico ligado a atención y actuación; vistas del componente | F72 |',
        '| Ortodoncia/oclusión/cefalometría | Estructuras, relaciones, estudio y puntos/medidas implementados | Mediciones y evolución; no se presume análisis automático | F72 + F25 |',
        '| Prótesis/implantes | Pieza/región, dispositivo/trabajo, etapas e identificadores | Plan y procedimiento separado; trazabilidad de dispositivo/laboratorio | F72 + F42 |',
        '| Mapa anatómico corporal, cardíaco, neurológico u órgano | Región, lado, vista y versión de atlas | Hallazgo/medición/procedimiento vinculado; coordenadas solo visuales | F23 |',
        '| Función/movilidad/rehabilitación | Región, función, medida o instrumento y sesión | Observaciones/objetivos y comparación temporal | F72 + F25 |',
        '| Visual/ocular y audición | Ojo/oído, lateralidad, eje o parámetro del estudio | Datos estructurados y gráfico con escala/tabla apropiada | F72 + F25 |',
        '| Crecimiento/antropometría | Edad/perfil, valores originales y referencia válida | Curva con referencia/versión; explicar indicador no calculable | F25 |',
        '| Tendencias y escalas | Medición/instrumento, unidad, momento y versión | Series, tabla y cálculo validado cuando corresponda | F25 |',
        '| Fotografía y lesión seriada | Región, fecha, consentimiento y procedencia | Comparación enlazada al mismo hallazgo sin alterar originales | F26 + F23 |',
        '| Estudio, señal, audio o video | Identidad, orden, adquisición, documento y capacidad del visor | Visualización e informe; interpretación profesional separada | F26 + F33 |',
        '| Genética y relaciones | Sujetos distintos, vínculo, evidencia y resultado | Representación y documento con acceso específico; sin unión de historiales | F72 + F29 |',
        '| Gestación, reproducción y descendencia | Ciclo, sujetos, fecha y etapas autorizadas | Evolución del ciclo y relaciones separadas | F25 + F59 |',
        '| Hojas hospitalarias/quirúrgicas | Tiempos, paciente, caso, recurso y eventos | Actuaciones reales, excepciones, responsables y evolución | F50 + F53 + F54 |',
        '| Poblaciones y programas | Grupo, periodo, denominador y unidad | Indicadores con contexto; enlace a individuos autorizados | F14 + F60 |','',
        'Las familias comparten infraestructura de captura pero no sus reglas clínicas. Cada componente del catálogo requiere una ficha con anatomía/dimensiones, gestos o selección, campos, estados, validaciones, leyenda, comparación, salida documental y casos de aceptación. El mapa siguiente conecta las 241 entradas con las familias ya previstas.','',
        '## Relación completa por especialidad','','| Código | Área | Componentes funcionales previstos | Flujos base de captura |','| --- | --- | --- | --- |']
    for e in catalog['entries']:
        families=e['componentFamilies']
        routes=['F22']
        for family in families:
            if family in ['HUMAN_DENTAL','VET_DENTAL']: routes.append('F24')
            elif family=='ANATOMY': routes.append('F23')
            elif family in ['GROWTH','TRENDS','SCALES']: routes.append('F25')
            elif family in ['PHOTO','IMAGING','SIGNAL']: routes.append('F26')
            elif family!='FORM': routes.append('F72')
        lines.append('| '+' | '.join(cell(x) for x in [e['code'],e['name'],'; '.join(family_names[f] for f in families),', '.join(dict.fromkeys(routes))])+' |')
    lines+=['','Los flujos base no sustituyen las actividades especializadas del paquete. Una imagen adjunta no acredita un visor/algoritmo; una plantilla publicada no habilita una capacidad aún pendiente. Las fases avanzadas conservan sus recorridos clínicos correspondientes.','']
    return '\n'.join(lines)

def main():
    source=load()
    ACTOR_LABELS.update({a['id']:a['name'] for a in source['actors']})
    actions=actions_for(source)
    assert len({a['id'] for a in actions})==len(actions)
    ids={s['id'] for s in source['screens']}
    assert all(set(a['screenIds'])<=ids for a in actions)
    (BASE/'fuente_diseno.json').write_text(json.dumps(source,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    diagram_dir=BASE/'diagramas'; diagram_dir.mkdir(exist_ok=True)
    for flow in source['flows']: (diagram_dir/(flow['id']+'.mmd')).write_text(graph(flow),encoding='utf-8')
    for name,content in [
        ('01_Actores_y_Reglas.md',actor_doc(source)),
        ('02_Flujos_y_Diagramas.md',flow_doc(source)),
        ('03_Pantallas_y_Botones.md',frontend_doc(source,actions)),
        ('04_Graficos_de_Especialidad.md',graphics_doc())]:
        (BASE/name).write_text(content,encoding='utf-8')
    for mdname,prefix in [('01_Actores_y_Reglas.md','ACTORES'),('05_Estados_y_Recorridos.md','ESTADOS')]:
        p=BASE/mdname
        if p.exists():
            for i,diagram in enumerate(re.findall(r'```mermaid\s*\n([\s\S]*?)\n```',p.read_text(encoding='utf-8')),1):
                (diagram_dir/f'{prefix}_{i:02d}.mmd').write_text(diagram+'\n',encoding='utf-8')
    trace={'version':source['version'],'date':source['date'],'status':source['status'],'confirmedDecisions':source['confirmedDecisions'],'actors':source['actors'],'phases':source['phases'],'flows':source['flows'],'screens':source['screens'],'actions':actions,'summary':{'flows':len(source['flows']),'screens':len(source['screens']),'actions':len(actions),'specialtyEntries':241},'note':'Las acciones son propuestas; roles candidatos no conceden permisos. No hay frontend ni backend implementado por estos documentos.'}
    (BASE/'Trazabilidad_Diseno.json').write_text(json.dumps(trace,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(trace['summary'],ensure_ascii=False))

if __name__=='__main__': main()
