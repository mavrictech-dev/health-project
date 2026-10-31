import { flowLicenseReason, runSaasCommand, tenantProfessionals, tenantSpecialties } from '@/lib/saas';
import formsData from '@/data/action-forms.json';
import { actionById, flowById } from '@/lib/spec';
import { patientScopedFlows } from '@/lib/scope';
import type { ActionForm, Context, DemoData, FormValues, Patient, RecordItem } from '@/lib/types';
import { DEMO_DATE, getOrganizations, isVeterinary } from './fixtures';

export interface CommandTarget { recordId?: string; appointmentId?: string; documentId?: string; bedId?: string; stockId?: string; structure?: string; surface?: string; component?: string; operationId?: string; time?: string; date?: string; professional?: string; }
export interface CommandResult { data: DemoData; context: Context; targetId?: string; message: string; }
export const formSpecs = formsData as Record<string, ActionForm>;
export const uid = (prefix: string) => `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
export const money = (amount: number) => new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(amount / 100);
export function balance(data: DemoData, org: string, patient: string) {
  return data.movements.filter(m => m.org === org && m.patient === patient).reduce((total, m) => total + (['charge', 'refund'].includes(m.kind) ? m.amount : -m.amount), 0);
}
export function portalLinked(data: DemoData, context: Context, patient = context.patient) {
  return data.records.some(r => r.org === context.org && r.patient === patient && r.resource === 'portal-links' && ['Vigente', 'Activo', 'Activa', 'Aceptada'].includes(r.status) && (!r.data.inicioVigencia || String(r.data.inicioVigencia) <= DEMO_DATE) && (!r.data.finVigencia || String(r.data.finVigencia) >= DEMO_DATE));
}
export function actionAvailability(id: string, data: DemoData, context: Context) {
  const action = actionById[id];
  if (!action) return 'Esta acción no está disponible.';
  if (['organization.beginSetup', 'organization.activate'].includes(action.operation)) return 'El alta y estado del cliente se gestionan en Administración SaaS, con su plan y capacidad.';
  const license = flowLicenseReason(data, context, action.flow, action.pattern); if (license) return license;
  if (!action.roles.includes(context.role)) return `Disponible para ${action.roles.map(r => ({ ADM: 'Administración', REC: 'Recepción', PRO: 'Profesional', ASI: 'Enfermería', DIA: 'Diagnóstico', FAR: 'Farmacia', CAJ: 'Caja', ALM: 'Almacén', PAC: 'Paciente', RES: 'Responsable', AUD: 'Auditoría', SOP: 'Operación' }[r] || r)).join(', ')}.`;
  if (['PAC', 'RES'].includes(context.role) && !['F03', 'F70', 'F74', 'F79'].includes(action.flow) && !portalLinked(data, context)) return 'El vínculo de este paciente requiere verificación o fue revocado.';
  if (['F14', 'F60'].includes(action.flow) && !isVeterinary(data, context.org)) return 'Este proceso corresponde a una organización veterinaria.';
  const closedEncounter = data.encounters.find(e => e.id === context.encounter && e.org === context.org)?.status === 'Finalizada';
  if (closedEncounter && ['F22', 'F23', 'F24', 'F25', 'F26'].includes(action.flow) && ['FORM_SHEET_RIGHT', 'WIZARD_SHEET_RIGHT', 'COMMAND_STATE'].includes(action.pattern)) return 'La visita está finalizada. Inicia otra atención o utiliza una adenda para corregir el documento.';
  return '';
}
const statusLabels: Record<string, string> = {
  sesion_activa: 'Sesión activa', activa: 'Activa', activo: 'Activo', aceptada: 'Aceptada', revocada: 'Revocada',
  borrador: 'Borrador', en_revision: 'En revisión', publicada: 'Publicada', retirada: 'Retirada', verificada: 'Verificada · demo',
  reservada: 'Reservada', pendiente: 'Pendiente', confirmada: 'Confirmada', cancelada: 'Cancelada', reprogramada: 'Reprogramada',
  ofertada: 'Oferta enviada', rechazada: 'Rechazada', cerrada: 'Cerrada', llegada: 'Llegada registrada', en_espera: 'En espera',
  llamada: 'Llamada', en_atencion: 'En atención', finalizada: 'Finalizada', firmada_demo: 'Firmado · demo', emitida: 'Emitida · demo',
  asignada: 'Asignada', preliminar: 'Preliminar', emitido: 'Emitido · demo', firmado_demo: 'Firmado · demo', parcial: 'Entrega parcial',
  entregada: 'Entregada', administrada: 'Administrada', no_realizada: 'No realizada', resuelta: 'Resuelta', enviada: 'Enviada · demo',
  confirmado: 'Confirmado', reversado: 'Reversado', abierta: 'Abierta', registrado: 'Registrado', conciliado: 'Conciliado',
  devuelto: 'Devuelto · demo', pendiente_demo: 'Pendiente · demo', aprobada: 'Aprobada', pagada_demo: 'Pagada · demo', recibida: 'Recibida',
  en_transito: 'En tránsito', solicitada: 'Solicitada', trasladada: 'Trasladada', programada: 'Programada', iniciada: 'En curso',
  cerrado: 'Cerrado', egresada: 'Egresada', suspendido: 'Suspendido', desconectada: 'Desconectada', autorizado: 'Autorizado',
  rechazado: 'Rechazado', activa_demo: 'Activa · demo', recuperado: 'Recuperado', sesion_operador: 'Sesión de operador', sesion_cerrada: 'Sesión cerrada',
};

function text(v: FormValues, ...keys: string[]) { for (const key of keys) if (v[key] !== undefined && v[key] !== '') return String(v[key]); return ''; }
function amount(v: FormValues) { const value = Number(v.importe ?? v.cantidad ?? v.valor ?? 0); if (!Number.isFinite(value)) throw new Error('Introduce un número válido.'); return value; }
function chosenPatient(data: DemoData, context: Context, values: FormValues) {
  const reference = text(values, 'paciente', 'animal');
  const patient = reference ? data.patients.find(p => p.org === context.org && (p.id === reference || p.name === reference)) : data.patients.find(p => p.id === context.patient && p.org === context.org);
  if (!patient) throw new Error('Selecciona un paciente de esta organización.');
  return patient;
}
function statusFor(actionId: string, operation: string) {
  const explicit = formSpecs[actionId]?.targetStatus;
  if (explicit) return statusLabels[explicit] || explicit.replaceAll('_', ' ').replace(/^./, c => c.toUpperCase());
  if (/revoke/.test(operation)) return 'Revocada';
  if (/cancel|withdraw/.test(operation)) return 'Cancelada';
  if (/reject/.test(operation)) return 'Rechazada';
  if (/approve/.test(operation)) return 'Aprobada';
  if (/close|finalize|confirmExit/.test(operation)) return 'Finalizada';
  if (/publish/.test(operation)) return 'Publicada';
  if (/issue/.test(operation)) return 'Emitida · demo';
  if (/accept/.test(operation)) return 'Aceptada';
  if (/save|begin|Draft/.test(operation)) return 'Borrador';
  return 'Registrado';
}

export function runCommand(input: DemoData, current: Context, id: string, supplied: FormValues = {}, target: CommandTarget = {}): CommandResult {
  const unavailable = actionAvailability(id, input, current);
  if (unavailable) throw new Error(unavailable);
  const action = actionById[id];
  if (target.operationId && input.events.some(event => event.org === current.org && event.operationId === target.operationId)) return { data: input, context: current, message: 'Esta operación ya estaba confirmada.' };
  if (['PAC', 'RES'].includes(current.role) && !['F03', 'F70', 'F74', 'F79'].includes(action.flow)) {
    const requested = text(supplied, 'paciente', 'animal');
    const related = [requested ? input.patients.find(p => p.id === requested || p.name === requested)?.id : undefined, input.records.find(r => r.id === target.recordId)?.patient, input.documents.find(d => d.id === target.documentId)?.patient, input.appointments.find(a => a.id === target.appointmentId)?.patient];
    if (related.some(patient => patient && !portalLinked(input, current, patient))) throw new Error('El paciente seleccionado no tiene un vínculo vigente para este portal.');
  }
  const data = structuredClone(input);
  data.organizations = structuredClone(getOrganizations(data));
  const organizations = data.organizations;
  const context = { ...current };
  for (const [referenceId, collection] of [[target.recordId, [...data.records, ...data.jobs]], [target.documentId, data.documents], [target.appointmentId, data.appointments], [target.bedId, data.beds], [target.stockId, data.stock]] as const) {
    if (referenceId && collection.some(item => item.id === referenceId && item.org !== current.org)) throw new Error('El registro pertenece a otro espacio. Selecciona uno de esta organización.');
  }
  const operation = action.operation;
  const patient = data.patients.find(p => p.id === current.patient && p.org === current.org);
  let targetId = target.recordId;
  const reference = data.records.find(r => r.id === target.recordId && r.org === current.org) || data.records.find(r => r.resource === action.resource && r.org === current.org && (!r.patient || r.patient === current.patient));
  const values: FormValues = { ...reference?.data, ...supplied };
  const safeValues = Object.fromEntries(Object.entries(values).filter(([key]) => !/contrase|password|secreto|apiKey|tokenAcceso/i.test(key)));
  const appointment = data.appointments.find(a => a.id === target.appointmentId && a.org === current.org) || data.appointments.find(a => a.patient === current.patient && a.org === current.org && !['Cancelada', 'Finalizada'].includes(a.status));
  const selectedDocument = text(supplied, 'original', 'documentoOriginal', 'documento', 'documentoVersion') || target.documentId || text(values, 'original', 'documentoOriginal', 'documento', 'documentoVersion');
  const document = selectedDocument ? data.documents.find(d => d.org === current.org && d.id === selectedDocument) : data.documents.find(d => d.patient === current.patient && d.org === current.org && d.status === 'Borrador') || data.documents.find(d => d.patient === current.patient && d.org === current.org);
  const encounter = data.encounters.find(e => e.id === current.encounter && e.org === current.org) || data.encounters.find(e => e.patient === current.patient && e.org === current.org && e.status !== 'Finalizada');
  const updateRecord = () => {
    const newStatus = statusFor(id, operation);
    const creates = /\.(create|add|record|begin|request|prepare|propose|invite|generate|enter|capture|evaluate|coordinate|schedule)/i.test(operation) || !reference;
    const label = text(values, 'nombre', 'titulo', 'servicio', 'descripcion', 'hallazgo', 'mensaje', 'resultado', 'motivo') || action.label;
    if (creates) {
      const record: RecordItem = { id: uid('record'), org: current.org, resource: action.resource, flow: action.flow, patient: patientScopedFlows.has(action.flow) ? patient?.id : undefined, parent: reference?.id, title: label, status: newStatus, date: text(values, 'fecha') || DEMO_DATE, revision: 1, data: { ...safeValues, operacion: action.label } };
      data.records.unshift(record); targetId = record.id;
    } else {
      reference!.history = [...(reference!.history || []), { revision: reference!.revision, status: reference!.status, data: { ...reference!.data } }];
      reference!.status = newStatus; reference!.data = { ...safeValues, ultimaAccion: action.label }; reference!.revision += 1; targetId = reference!.id;
    }
  };
  if (['DETAIL_SHEET_RIGHT', 'NAV_ROUTE', 'SELECT_CONTROL', 'FILTER_INLINE', 'GRAPH_CONTROL', 'EXPORT_LOCAL', 'PRINT_CLIENT', 'CLOSE_OR_RETURN', 'UNDO_LOCAL'].includes(action.pattern)) {
    return { data, context, targetId, message: action.label };
  } else if (operation === 'organization.beginSetup') {
    const name = text(values, 'nombre', 'nombreOrganizacion');
    if (!name) throw new Error('Escribe el nombre de la organización.');
    const org = { id: uid('org'), name, initials: name.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase(), type: text(values, 'tipo') || 'Medicina humana', branches: [{ id: uid('branch'), name: 'Sede principal' }] };
    data.organizations.push(org); targetId = org.id; updateRecord();
    context.org = org.id; context.branch = org.branches[0].id; context.patient = ''; context.encounter = ''; context.specialty = /veterinar/i.test(org.type) ? 'V_GENERAL' : 'H_GENERAL_MEDICINE';
  } else if (operation === 'organization.addBranch') {
    const org = organizations.find(o => o.id === current.org)!;
    const name = text(values, 'nombre', 'nombreSucursal');
    if (!name) throw new Error('Escribe el nombre de la sucursal.');
    if (org.branches.some(b => b.name.toLowerCase() === name.toLowerCase())) throw new Error('Ya existe una sucursal con ese nombre.');
    const changed = runSaasCommand(data, current, 'branch.create', { branchName: name });
    data.organizations = changed.data.organizations; data.saas = changed.data.saas; updateRecord();
  } else if (operation === 'patients.merge') {
    const source = data.patients.find(p => p.org === current.org && p.id === values.fichaFuente);
    const kept = data.patients.find(p => p.org === current.org && p.id === values.fichaConservada);
    if (!source || !kept || source.id === kept.id || source.domain !== kept.domain) throw new Error('Selecciona dos fichas distintas del mismo dominio y organización.');
    if (source.mergedInto || kept.mergedInto) throw new Error('Una ficha ya está consolidada. Revisa su procedencia.');
    if (!text(values, 'motivo')) throw new Error('Registra el motivo y revisa la identidad antes de consolidar.');
    source.mergedInto = kept.id;
    for (const collection of [data.appointments, data.encounters, data.documents, data.observations, data.annotations, data.movements, data.beds]) for (const item of collection) if (item.org === current.org && item.patient === source.id) item.patient = kept.id;
    for (const record of data.records) if (record.org === current.org && record.patient === source.id) { record.patient = kept.id; record.data.fichaOrigen = source.id; }
    context.patient = kept.id; context.specialty = kept.specialty; updateRecord();
  } else if (operation === 'orders.issue') {
    updateRecord();
    data.records.unshift({ id: uid('task'), org: current.org, resource: 'diagnostic-tasks-specimens', flow: 'F31', patient: current.patient, parent: targetId, title: `Tarea · ${text(values, 'servicio') || 'Orden emitida'}`, status: 'Pendiente', date: DEMO_DATE, revision: 1, data: { orden: targetId || '', servicio: text(values, 'servicio'), prioridad: text(values, 'prioridad') || 'Registrada' } });
  } else if (operation === 'dictation.stopDemo') {
    updateRecord();
    const transcript = data.records.find(r => r.id === targetId)!;
    transcript.data.transcripcion = 'Texto ficticio de demostración. Paciente acude a control; registrar evolución y revisar los antecedentes de esta visita.';
    transcript.status = 'Pendiente de revisión';
  } else if (operation === 'dictation.acceptSelection') {
    if (!encounter || encounter.status === 'Finalizada') throw new Error('Abre una atención activa para incorporar el texto.');
    const selected = text(values, 'textoSeleccionado', 'fragmentos', 'seleccion', 'contenido', 'transcripcion');
    if (!selected) throw new Error('Selecciona o escribe el fragmento revisado.');
    encounter.note += (encounter.note ? '\n\n' : '') + selected; encounter.revision += 1; updateRecord();
  } else if (operation === 'forms.saveDraft') {
    const response: RecordItem = { id: uid('form'), org: current.org, resource: 'form-responses', flow: 'F22', patient: current.patient, title: `Evaluación · ${current.specialty}`, status: 'Borrador', date: DEMO_DATE, revision: (data.records.filter(r => r.flow === 'F22' && r.org === current.org && r.patient === current.patient && r.data.perfil === values.perfil).length + 1), data: { ...supplied, perfil: text(supplied, 'perfil') || current.specialty, plantillaVersion: text(supplied, 'plantillaVersion') || 'demo-1' } };
    data.records.unshift(response); targetId = response.id;
  } else if (operation === 'data.commitBatch') {
    const hash = text(values, 'hashImport');
    if (!hash) throw new Error('Selecciona un archivo y revisa la vista previa antes de aplicar el lote.');
    if (data.records.some(r => r.org === current.org && r.flow === 'F64' && r.data.hashImport === hash && r.status === 'Completado')) throw new Error('Este lote ya fue aplicado. No se duplicarán sus filas.');
    const rows = JSON.parse(text(values, 'filasJson') || '[]') as Record<string, string>[];
    let accepted = 0; let rejected = 0;
    for (const row of rows) {
      const name = row.nombre || row.name; const identity = row.identificacion || row.identifier || `DEMO-IMP-${hash}-${accepted}`;
      if (values.esquema === 'Pacientes') {
        if (!name || data.patients.some(p => p.org === current.org && p.identifier === identity)) { rejected++; continue; }
        data.patients.push({ id: uid('patient'), org: current.org, name, domain: current.org === 'org-vet' ? 'ANIMAL' : 'HUMAN', species: current.org === 'org-vet' ? row.especie || 'Canino' : undefined, age: row.edad || 'Sin registrar', identifier: identity, phone: row.telefono || '', email: row.correo || '', avatar: name.slice(0, 2).toUpperCase(), color: 'sage', specialty: current.org === 'org-vet' ? 'V_GENERAL' : 'H_GENERAL_MEDICINE', allergies: [], created: DEMO_DATE }); accepted++;
      } else if (values.esquema === 'Inventario') {
        if (!name || !Number.isFinite(Number(row.cantidad)) || Number(row.cantidad) < 0) { rejected++; continue; }
        data.stock.push({ id: uid('stock'), org: current.org, name, lot: row.lote || `DEMO-${hash}`, expiry: row.vencimiento || '2027-10-13', quantity: Number(row.cantidad), unit: row.unidad || 'unidades', category: 'Importado' }); accepted++;
      } else {
        const p = data.patients.find(p => p.org === current.org && [p.id, p.name, p.identifier].includes(row.paciente));
        if (!p || !/^\d{4}-\d{2}-\d{2}$/.test(row.fecha || '') || !/^\d{2}:\d{2}$/.test(row.hora || '') || data.appointments.some(a => a.org === current.org && a.branch === current.branch && a.date === row.fecha && a.time === row.hora && a.status !== 'Cancelada')) { rejected++; continue; }
        data.appointments.push({ id: uid('appointment'), org: current.org, branch: current.branch, patient: p.id, professional: 'pro-mateo', service: row.servicio || 'Consulta general', specialty: p.specialty, date: row.fecha, time: row.hora, duration: 30, status: 'Reservada', note: 'Importación ficticia' }); accepted++;
      }
    }
    data.records.unshift({ id: uid('import'), org: current.org, resource: action.resource, flow: 'F64', title: `Importación · ${values.archivo}`, status: 'Completado', date: DEMO_DATE, revision: 1, data: { hashImport: hash, archivo: text(values, 'archivo'), aceptados: accepted, rechazados: rejected, esquema: text(values, 'esquema') } });
  } else if (/^patients\.(beginHuman|beginAnimal|saveHuman|saveAnimal)$/.test(operation)) {
    const name = text(values, 'nombre', 'nombrePaciente', 'nombreAnimal', 'nombres');
    if (!name && /^patients\.begin/.test(operation)) throw new Error('Escribe el nombre del paciente.');
    if (name) {
      const animal = /Animal/.test(operation);
      if (isVeterinary(data, current.org) !== animal) throw new Error('Elige el registro humano o animal que corresponde a este espacio.');
      const identifier = text(values, 'identificador', 'identificacion', 'numeroDocumento', 'documento') || `DEMO-${data.patients.length + 1001}`;
      if (data.patients.some(p => p.org === current.org && p.identifier === identifier)) throw new Error('Ya existe una ficha con ese identificador. Revisa coincidencias.');
      const next: Patient = { id: uid('patient'), org: current.org, name, domain: animal ? 'ANIMAL' : 'HUMAN', species: animal ? text(values, 'especie') || 'Canino' : undefined, age: text(values, 'edad') || 'Sin registrar', identifier, phone: text(values, 'telefono', 'contacto'), email: text(values, 'correo', 'email'), responsible: text(values, 'responsable'), avatar: name.split(' ').slice(0, 2).map(n => n[0]).join('').toUpperCase(), color: 'sage', specialty: animal ? 'V_GENERAL' : 'H_GENERAL_MEDICINE', allergies: [], created: DEMO_DATE };
      data.patients.unshift(next); context.patient = next.id; context.specialty = next.specialty; targetId = next.id;
    } else if (!patient) throw new Error('No hay una ficha para guardar. Abre primero el alta.');
  } else if (/appointments\.(reserve|beginBooking)$/.test(operation) || /requests\.(submit|acceptAlternative)$/.test(operation) || operation === 'waitlist.acceptOffer') {
    const selected = chosenPatient(data, current, values);
    const time = text(values, 'inicioHora', 'hora', 'inicio', 'horario') || '10:30';
    const date = text(values, 'fecha') || DEMO_DATE;
    const professional = text(values, 'profesional') || current.professional || tenantProfessionals(data, current.org, current.branch)[0]?.id || '';
    const bookingBranch = organizations.find(o => o.id === current.org)?.branches.find(b => [b.id, b.name].includes(text(values, 'sucursal')))?.id || current.branch;
    if (organizations.find(o => o.id === current.org)?.branches.find(b => b.id === bookingBranch)?.status === 'Inactiva') throw new Error('Selecciona una sede activa para reservar.');
    const assigned = tenantProfessionals(data, current.org, bookingBranch).find(p => p.id === professional);
    if (!assigned) throw new Error('El profesional necesita una membresía activa asignada a esta sede.');
    const requestedSpecialty = text(values, 'especialidad');
    if (requestedSpecialty && !assigned.membership.specialties.includes(requestedSpecialty)) throw new Error('La especialidad debe estar asignada al profesional en este cliente.');
    const minutes = (t: string) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
    const endTime = text(values, 'finHora');
    const duration = endTime ? minutes(endTime) - minutes(time) : Number(values.duracion || 30);
    if (duration <= 0 || duration > 480) throw new Error('La hora de fin debe ser posterior al inicio dentro del mismo día.');
    if (!/^\d{2}:\d{2}$/.test(time)) throw new Error('Elige una hora válida.');
    if (data.appointments.some(a => a.professional === professional && a.date === date && a.status !== 'Cancelada' && minutes(time) < minutes(a.time) + a.duration && minutes(time) + duration > minutes(a.time))) throw new Error('Ese horario ya está ocupado. Conservamos tus datos; elige otra hora.');
    const item = { id: uid('appointment'), org: current.org, branch: bookingBranch, patient: selected.id, professional, service: text(values, 'servicio') || (selected.domain === 'ANIMAL' ? 'Consulta veterinaria' : 'Consulta general'), specialty: requestedSpecialty || assigned.membership.specialties[0], date, time, duration, status: operation === 'requests.submit' ? 'Solicitud pendiente' : 'Reservada', note: text(values, 'observacion', 'motivo') };
    data.appointments.push(item); context.patient = selected.id; targetId = item.id;
  } else if (/appointments\.(confirmAttendance|cancel|commitReschedule|beginReschedule)$/.test(operation)) {
    if (!appointment) throw new Error('Selecciona una cita vigente.');
    if (operation.endsWith('cancel')) { appointment.status = 'Cancelada'; appointment.note = text(values, 'motivo'); }
    else if (operation.endsWith('confirmAttendance')) appointment.status = 'Confirmada';
    else if (text(values, 'inicioHora', 'hora', 'inicio')) {
      const nextTime = text(values, 'inicioHora', 'hora', 'inicio'); const nextDate = text(values, 'fecha') || appointment.date;
      if (data.appointments.some(a => a.id !== appointment.id && a.org === current.org && a.professional === appointment.professional && a.date === nextDate && a.time === nextTime && a.status !== 'Cancelada')) throw new Error('El nuevo horario está ocupado. La cita original se conserva.');
      appointment.time = nextTime; appointment.date = nextDate; appointment.status = 'Reprogramada';
    }
    targetId = appointment.id;
  } else if (/^queue\./.test(operation)) {
    if (!appointment && operation !== 'queue.beginWalkIn') throw new Error('Selecciona una cita o registra un ingreso sin cita.');
    if (appointment) { appointment.status = operation.endsWith('call') ? 'Llamada' : operation.endsWith('recordWithdrawal') ? 'Retirado' : 'En espera'; targetId = appointment.id; }
    updateRecord();
  } else if (/encounters\.start/.test(operation)) {
    const selected = chosenPatient(data, current, values);
    let active = data.encounters.find(e => e.org === current.org && e.patient === selected.id && e.status !== 'Finalizada');
    if (!active) { const professional = appointment?.professional || current.professional || tenantProfessionals(data, current.org, current.branch)[0]?.id; const member = tenantProfessionals(data, current.org, current.branch).find(p => p.id === professional); if (!member) throw new Error('Asigna un profesional activo a esta sede antes de iniciar la atención.'); const specialty = tenantSpecialties(data, current.org).find(s => s.code === current.specialty && member.membership.specialties.includes(s.code))?.code || member.membership.specialties[0]; active = { id: uid('encounter'), org: current.org, branch: current.branch, patient: selected.id, professional: professional!, date: DEMO_DATE, specialty, status: 'En curso', note: '', revision: 1 }; data.encounters.push(active); }
    active.status = 'En curso'; context.encounter = active.id; context.patient = selected.id; context.specialty = active.specialty; if (appointment) appointment.status = 'En atención'; targetId = active.id;
  } else if (/encounters\.(saveDraft|finalize|keepPending)$/.test(operation)) {
    if (!encounter || encounter.status === 'Finalizada') throw new Error('Abre una atención activa; las visitas finalizadas se conservan.');
    if (operation.endsWith('saveDraft')) { encounter.note = text(values, 'resumen', 'contenido', 'observacion') || encounter.note; encounter.revision += 1; }
    if (operation.endsWith('finalize')) { encounter.status = 'Finalizada'; if (appointment) appointment.status = 'Finalizada'; }
    if (operation.endsWith('keepPending')) encounter.status = 'Pendiente';
    targetId = encounter.id;
  } else if (/anatomy\.(addFinding|linkProcedure)|dental\.(recordCondition|recordProcedure)|specialty\.addRecord/.test(operation)) {
    if (!patient) throw new Error('Selecciona un paciente antes de registrar.');
    const structure = target.structure || text(values, 'estructura', 'pieza', 'region');
    if (!structure) throw new Error('Selecciona primero una estructura en el gráfico.');
    data.annotations.push({ id: uid('annotation'), org: current.org, patient: patient.id, encounter: encounter?.id || '', component: target.component || (/dental/.test(operation) ? patient.domain === 'ANIMAL' ? 'VET_DENTAL' : 'HUMAN_DENTAL' : 'ANATOMY'), structure, surface: target.surface || text(values, 'cara'), condition: text(values, 'condicion', 'hallazgo', 'descripcion', 'estado') || 'Registro especializado', procedure: text(values, 'procedimiento'), value: values.valor !== undefined && values.valor !== '' ? Number(values.valor) : undefined, unit: text(values, 'unidad') || undefined, date: text(values, 'fecha') || DEMO_DATE });
    updateRecord();
  } else if (/observations\.add|forms\.addMeasurement|anesthesia\.addObservation/.test(operation)) {
    if (!patient) throw new Error('Selecciona un paciente.');
    data.observations.push({ id: uid('observation'), org: current.org, patient: patient.id, parameter: text(values, 'parametro', 'medicion', 'nombre') || 'Medición registrada', value: amount(values), unit: text(values, 'unidad') || 'unidad', date: text(values, 'fecha') || DEMO_DATE }); updateRecord();
  } else if (/documents\.(createDraft|beginAddendum)|prescriptions\.issue|laboratory\.issueReport|imaging\.signReportDemo|prevention\.issueCertificate|discharge\.issueSummary/.test(operation)) {
    if (!patient) throw new Error('Selecciona un paciente.');
    const isAddendum = operation.endsWith('beginAddendum');
    if (isAddendum && (!document || !document.signed)) throw new Error('Elige una revisión firmada de demo para crear una adenda.');
    const issued = !/createDraft|beginAddendum/.test(operation);
    const title = text(values, 'titulo', 'nombre') || (isAddendum ? `Adenda · ${document!.title}` : action.label.replace(/^(Emitir|Firmar|Nuevo) /, ''));
    const next = { id: uid('document'), org: current.org, patient: patient.id, title, type: action.flow === 'F35' ? 'Receta' : isAddendum ? 'Adenda' : 'Documento clínico', status: issued ? 'Firmado · demo' : 'Borrador', version: isAddendum ? document!.version + 1 : 1, content: text(values, 'contenido', 'correccion', 'resumen', 'observacion') || encounter?.note || 'Documento ficticio para la presentación.', signed: issued ? 'Profesional de demostración' : undefined, published: false, date: DEMO_DATE, original: isAddendum ? document!.id : undefined };
    data.documents.unshift(next); updateRecord(); targetId = next.id;
    if (issued && ['F32', 'F33'].includes(action.flow)) data.records.unshift({ id: uid('pending'), org: current.org, resource: 'result-review', flow: 'F34', patient: patient.id, parent: next.id, title: `Revisar ${next.title}`, status: 'Pendiente', date: DEMO_DATE, revision: 1, data: { documento: next.id } });
    if (action.flow === 'F35') data.records.unshift({ id: uid('dispensing'), org: current.org, resource: 'dispensing', flow: 'F36', patient: patient.id, parent: next.id, title: `Dispensación · ${patient.name}`, status: 'Pendiente', date: DEMO_DATE, revision: 1, data: { receta: next.id, descripcion: 'Entrega pendiente de revisión de farmacia.' } });
  } else if (/documents\.(signRevisionDemo|signAddendumDemo)|publication\.(publish|withdraw)|documents\.close/.test(operation)) {
    if (!document) throw new Error('Selecciona un documento de esta organización.');
    if (/sign/.test(operation)) { if (document.signed) throw new Error('Esta revisión ya está firmada. Usa una adenda para corregirla.'); document.signed = 'Dr. Mateo Mendoza · demo'; document.status = 'Firmado · demo'; }
    if (operation.endsWith('publish')) { if (!document.signed) throw new Error('Revisa y firma la versión de demo antes de publicarla.'); if (!portalLinked(data, current, document.patient)) throw new Error('El destinatario no tiene un vínculo vigente de portal.'); document.published = true; document.withdrawn = false; }
    if (operation.endsWith('withdraw')) { document.published = false; document.withdrawn = true; }
    if (operation.endsWith('close')) document.status = 'Cerrado';
    targetId = document.id;
  } else if (/^charges\.(confirm|adjust|reverse)$|^payments\.(recordDemo|confirmRefundDemo)$|assistedBooking\.payAdvanceDemo/.test(operation)) {
    if (!patient) throw new Error('Selecciona la cuenta de un paciente.');
    const value = Math.round(amount(values) * 100);
    if (value <= 0) throw new Error('El importe debe ser mayor que cero.');
    const kind = /Refund/.test(operation) ? 'refund' : /reverse/.test(operation) ? 'reversal' : /^charges/.test(operation) ? 'charge' : 'payment';
    if (kind === 'refund' && value > data.movements.filter(m => m.org === current.org && m.patient === patient.id).reduce((sum, m) => sum + (m.kind === 'payment' ? m.amount : m.kind === 'refund' ? -m.amount : 0), 0)) throw new Error('La devolución supera los pagos disponibles de esta cuenta.');
    data.movements.push({ id: uid('movement'), org: current.org, patient: patient.id, kind, amount: value, title: text(values, 'descripcion', 'servicio', 'medioFicticio', 'motivo') || action.label, date: DEMO_DATE, parent: text(values, 'movimientoOriginal') || undefined }); updateRecord();
  } else if (operation === 'inventory.transfer') {
    const source = data.stock.find(s => s.org === current.org && (s.id === target.stockId || [s.id, s.lot, s.name].includes(text(values, 'producto', 'lote'))));
    const quantity = Number(values.cantidad);
    const destination = text(values, 'destino');
    if (!source || !destination || !Number.isFinite(quantity) || quantity <= 0) throw new Error('Selecciona producto, destino y cantidad válidos.');
    if (source.quantity < quantity) throw new Error('El origen no tiene existencias suficientes.');
    let receiver = data.stock.find(s => s.org === current.org && s.lot === source.lot && s.warehouse === destination);
    if (!receiver) { receiver = { ...source, id: uid('stock'), warehouse: destination, quantity: 0 }; data.stock.push(receiver); }
    if (receiver.id === source.id) throw new Error('El origen y el destino deben ser diferentes.');
    source.quantity -= quantity;
    data.records.unshift({ id: uid('transfer'), org: current.org, resource: action.resource, flow: 'F48', title: `Transferencia · ${source.name}`, status: 'En tránsito', date: DEMO_DATE, revision: 1, data: { ...values, stockOrigenId: source.id, stockDestinoId: receiver.id, cantidad: quantity } });
  } else if (operation === 'inventory.confirmReceipt') {
    if (!reference || reference.status !== 'En tránsito' || !reference.data.stockDestinoId) throw new Error('Selecciona una transferencia en tránsito.');
    const receiver = data.stock.find(s => s.org === current.org && s.id === reference.data.stockDestinoId);
    if (!receiver) throw new Error('No se encuentra el destino de la transferencia.');
    receiver.quantity += Number(reference.data.cantidad); updateRecord();
  } else if (/dispensing\.(confirm|deliverPartial|return)|inventory\.(consume|approveAdjustment|reverseMovement)|purchasing\.receive/.test(operation)) {
    const stock = data.stock.find(s => s.org === current.org && (s.id === target.stockId || s.id === values.producto || s.id === values.lote || s.lot === values.lote)) || data.stock.find(s => s.org === current.org);
    if (!stock) throw new Error('Selecciona un producto o lote de este almacén.');
    const quantity = Number(values.cantidad || 1);
    if (!Number.isFinite(quantity) || quantity <= 0) throw new Error('Introduce una cantidad positiva.');
    const adds = /return|Receipt|Adjustment|reverse|receive/.test(operation);
    if (!adds && stock.expiry < DEMO_DATE) throw new Error('El lote está vencido en el escenario. Selecciona otro.');
    if (!adds && stock.quantity < quantity) throw new Error('El lote no tiene suficientes existencias. Conservamos la captura.');
    stock.quantity += adds ? quantity : -quantity; updateRecord();
  } else if (/occupancy\.reserve|admissions\.confirm|discharge\.confirmExit|admissions\.cancelRequest/.test(operation)) {
    if (!patient) throw new Error('Selecciona un paciente.');
    const bed = data.beds.find(b => b.org === current.org && (b.id === target.bedId || [b.id, b.name].includes(text(values, 'recurso', 'plaza', 'cama', 'jaula')))) || data.beds.find(b => b.org === current.org && (operation === 'discharge.confirmExit' ? b.patient === patient.id : b.status === 'Disponible'));
    if (!bed) throw new Error('No hay una plaza compatible disponible para esta operación.');
    if (/confirmExit|cancelRequest/.test(operation)) { bed.status = 'Disponible'; bed.patient = undefined; }
    else { if (bed.status !== 'Disponible' && bed.patient !== patient.id) throw new Error('La plaza está ocupada. Selecciona otra.'); if (data.beds.some(b => b.id !== bed.id && b.org === current.org && b.patient === patient.id)) throw new Error('El paciente ya tiene una plaza. Prepara un traslado.'); bed.status = operation === 'occupancy.reserve' ? 'Reservada' : 'Ocupada'; bed.patient = patient.id; }
    updateRecord();
  } else if (/relationships\.revoke|portal\.revokeDelegation/.test(operation)) {
    data.records.filter(r => r.org === current.org && r.patient === current.patient && ['portal-links', 'responsible-relationships'].includes(r.resource)).forEach(r => { r.status = 'Revocada'; r.data.motivo = text(values, 'motivo'); }); updateRecord();
  } else if (/portal\.acceptLink|relationships\.verify/.test(operation)) {
    const link = data.records.find(r => r.org === current.org && r.patient === current.patient && r.resource === 'portal-links'); if (link) link.status = 'Vigente'; updateRecord();
  } else if (/identity\.enterWorkspace|context\.(saveAndSwitch|chooseBranch|chooseWorkspace)/.test(operation)) {
    const org = organizations.find(o => [o.id, o.name].includes(text(values, 'organizacion', 'espacio'))) || organizations.find(o => o.id === current.org)!;
    const branch = org.branches.find(b => [b.id, b.name].includes(text(values, 'sucursal'))) || org.branches[0];
    context.org = org.id; context.branch = branch.id; const first = data.patients.find(p => p.org === org.id); context.patient = first?.id || ''; context.encounter = data.encounters.find(e => e.org === org.id && e.patient === first?.id)?.id || ''; context.specialty = first?.specialty || 'H_GENERAL_MEDICINE';
  } else if (/identity\.(discardAndLogout|saveAndLogout)|operations\.loginDemo|portal\.loginDemo/.test(operation)) {
    updateRecord();
  } else if (/invoices\.(issueDemo|checkDemoStatus)|integrations\.retry|connections\.testDemo|sendReminder|resendInvitation|requestRecovery|verifyChannelDemo|dictation\.startDemo/.test(operation)) {
    const existing = operation === 'integrations.retry' || operation === 'invoices.checkDemoStatus' ? data.jobs.find(j => j.org === current.org && (j.id === target.recordId || j.status.includes('Rechaz') || j.status.includes('Error'))) : undefined;
    if (existing) { if (!existing.status.startsWith('Completado')) existing.attempts += 1; existing.status = 'Completado · demo'; targetId = existing.id; }
    else { const job = { id: uid('job'), org: current.org, type: action.label, label: action.label, status: operation === 'invoices.issueDemo' ? 'Pendiente · demo' : 'Completado · demo', attempts: 1, operationId: uid('operation'), date: DEMO_DATE }; data.jobs.unshift(job); targetId = job.id; }
    updateRecord();
  } else {
    updateRecord();
  }
  data.events.unshift({ id: uid('event'), org: current.org, branch: current.branch, actor: current.role, operation, label: action.label, date: DEMO_DATE, target: targetId, operationId: target.operationId });
  return { data, context, targetId, message: action.label + ' · cambio guardado en la demo' };
}

export function recordsForScreen(data: DemoData, context: Context, screenFlows: string[]) {
  const resources = new Set(screenFlows.map(f => flowById[f]?.resource));
  return data.records.filter(r => r.org === context.org && (resources.has(r.resource) || screenFlows.includes(r.flow)));
}
