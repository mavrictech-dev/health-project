'use client';
import { useEffect, useMemo, useState } from 'react';
import Image from 'next/image';
import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { Controller, useForm, type Resolver } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { AlertCircle, ArrowRight, Check, CheckCircle2, Download, LoaderCircle, ShieldCheck } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { actionById, actions, flowById, screens } from '@/lib/spec';
import { actionAvailability, formSpecs, balance, portalLinked } from '@/mocks/engine';
import { cacheFile, csvText, documentHtml, downloadBlob, getFile, getImport, prepareImport } from '@/lib/files';
import { DEMO_DATE, getOrganizations } from '@/mocks/fixtures';
import { getSaas, tenantProfessionals } from '@/lib/saas';
import { profiles } from '@/lib/profiles';
import { anatomyAtlases } from '@/data/anatomy-atlases';
import { useDemo, type Overlay } from '@/store/demo';
import { displayValue, structureLabel } from '@/lib/display';
import { PersonAvatar, Status } from './shared';
import type { FormField, FormValues } from '@/lib/types';

const commits: Record<string, string> = { F10_A02: 'F10_A05', F11_A01: 'F11_A04', F16_A01: 'F16_A03', F17_A01: 'F17_A04' };
const destinations: Record<string, string> = { F03_A01: '/recuperar', F03_A04: '/acceso', F15_A02: '/app/pacientes?paciente=', F15_A03: '/app/pacientes?tab=historia&paciente=', F30_A05: '/app/ordenes', F43_A06: '/app/finanzas/caja', F47_A06: '/app/compras', F50_A06: '/app/hospital/estancias', F65_A01: '/app/reportes', F70_A05: '/portal/citas', F77_A06: '/app/finanzas/caja', F78_A03: '/operacion/inicio' };
function nice(value: unknown) { if (value === true) return 'Confirmado'; if (value === false) return 'Sin confirmar'; return String(value ?? ''); }

export function ActionPanel({ overlay, onComplete }: { overlay: Overlay; onComplete: () => void }) {
  const { data, context, execute, busy, setDirty, open, setPatient, notify, draftNotes, setFilters } = useDemo();
  const router = useRouter(); const pathname = usePathname(); const query = useSearchParams();
  const professionals = tenantProfessionals(data, context.org, context.branch);
  const action = actionById[overlay.actionId!]; const flow = flowById[action.flow];
  const spec = formSpecs[action.id];
  const [createdTargetId, setCreatedTargetId] = useState<string | undefined>();
  const [stage, setStage] = useState<'edit' | 'review' | 'done'>('edit'); const [values, setValues] = useState<FormValues>({}); const [error, setError] = useState(''); const [selectedFile, setSelectedFile] = useState<File | null>(null); const [importInfo, setImportInfo] = useState(getImport());
  const patient = data.patients.find(p => p.org === context.org && p.id === context.patient);
  const appointment = data.appointments.find(a => a.org === context.org && a.id === overlay.target?.appointmentId);
  const allowedDocuments = data.documents.filter(d => d.org === context.org && (!['PAC', 'RES'].includes(context.role) || d.patient === context.patient && d.published && !d.withdrawn));
  const selectedDocId = String(values.documentoVersion || values.original || overlay.target?.documentId || '');
  const doc = selectedDocId ? allowedDocuments.find(d => d.id === selectedDocId) : allowedDocuments.find(d => d.patient === context.patient && d.status === 'Borrador') || allowedDocuments.find(d => d.patient === context.patient);
  const record = data.records.find(r => r.id === overlay.target?.recordId && r.org === context.org) || data.records.find(r => r.org === context.org && r.resource === action.resource && r.patient === context.patient);
  const attachedFile = getFile(overlay.target?.recordId || record?.id || '');
  const encounter = data.encounters.find(e => e.id === context.encounter && e.org === context.org);
  const fields = useMemo(() => spec?.fields || [], [spec]);
  const schema = useMemo(() => z.object(Object.fromEntries(fields.map(field => {
    if (field.type === 'checkbox') return [field.key, z.boolean().refine(v => !field.required || v, 'Confirma la revisión para continuar.')];
    if (field.type === 'number') return [field.key, z.union([z.string(), z.number()]).refine(v => !field.required && v === '' || v !== '' && Number.isFinite(Number(v)) && (field.min === undefined || Number(v) >= field.min), field.min !== undefined ? `Introduce un valor de al menos ${field.min}.` : 'Introduce un número válido.').transform(v => v === '' ? '' : Number(v))];
    return [field.key, field.required ? z.string().trim().min(1, 'Completa este campo.') : z.string()];
  }))), [fields]);
  const choices = (field: FormField): { value: string; label: string }[] => {
    if (action.id === 'F23_A01' && field.key === 'vista') return Object.values(anatomyAtlases).filter(atlas => patient?.domain === 'ANIMAL' ? !['human-front', 'human-back'].includes(atlas.id) : !['dog', 'cat', 'horse', 'bird', 'bovine', 'reptile', 'fish'].includes(atlas.id)).map(atlas => ({ value: atlas.id, label: atlas.label }));
    if (field.key === 'estructura' && ['F23', 'F72'].includes(action.flow)) {
      if (overlay.target?.structure) return [{ value: overlay.target.structure, label: structureLabel(overlay.target.structure) }];
      const atlas = anatomyAtlases[query.get('atlas') || (patient?.domain === 'ANIMAL' ? patient?.species === 'Felino' ? 'cat' : patient?.species === 'Equino' ? 'horse' : 'dog' : 'human-front')];
      return atlas.regions.map(region => ({ value: `${atlas.id}:${region.id}`, label: region.label }));
    }
    if (field.key === 'pieza') {
      if (patient?.domain === 'ANIMAL') { const upper = patient.species === 'Felino' ? [1,2,3,4,6,7,8,9] : Array.from({length: patient.species === 'Equino' ? 11 : 10},(_,i)=>i+1); const lower = patient.species === 'Felino' ? [1,2,3,4,7,8,9] : Array.from({length:11},(_,i)=>i+1); return [100,200,300,400].flatMap(base => (base < 300 ? upper : lower).map(n => ({ value: String(base+n), label: `Pieza ${base+n}` }))); }
      return [10,20,30,40,50,60,70,80].flatMap(base => Array.from({length:base >= 50 ? 5 : 8},(_,i)=>({value:String(base+i+1),label:`Pieza ${base+i+1}${base >= 50 ? ' · temporal' : ''}`})));
    }
    if (/^(paciente|animal|fichaFuente|fichaConservada)$/.test(field.key)) return data.patients.filter(p => !p.mergedInto && p.org === context.org && (!['PAC', 'RES'].includes(context.role) || portalLinked(data, context, p.id))).map(p => ({ value: p.id, label: `${p.name} · ${p.identifier}` }));
    if (/^(profesional|responsableClinico|suplente)$/.test(field.key)) return professionals.map(p => ({ value: p.id, label: p.name }));
    if (field.key === 'unidad' && ['PERIODONTAL', 'ENDO', 'ORTHODONTIC'].includes(overlay.target?.component || '')) return ['mm', '°'].map(value => ({ value, label: value }));
    if (field.key === 'membresia') return getOrganizations(data).map(o => ({ value: o.id, label: o.name }));
    if (field.key === 'sucursal') return getOrganizations(data).find(o => o.id === context.org)!.branches.map(b => ({ value: b.id, label: b.name }));
    if (/^(organizacion|espacio)$/.test(field.key)) return getOrganizations(data).map(o => ({ value: o.id, label: o.name }));
    if (/^(lote|producto)$/.test(field.key)) return data.stock.filter(s => s.org === context.org).map(s => ({ value: s.id, label: `${s.name} · ${s.lot} · ${s.quantity} ${s.unit}` }));
    if (/^(cita|reserva)$/.test(field.key)) return data.appointments.filter(a => a.org === context.org).map(a => ({ value: a.id, label: `${a.date} ${a.time} · ${data.patients.find(p => p.id === a.patient)?.name}` }));
    if (['recurso', 'plaza', 'cama', 'jaula'].includes(field.key) && ['F49', 'F50', 'F55'].includes(action.flow)) return data.beds.filter(b => b.org === context.org).map(b => ({ value: b.id, label: `${b.name} · ${b.status}` }));
    if (/^(original|documentoOriginal|documento|documentoVersion)$/.test(field.key)) return data.documents.filter(d => d.org === context.org && d.patient === context.patient).map(d => ({ value: d.id, label: `${d.title} · v${d.version} · ${d.status}` }));
    if (action.flow === 'F48' && field.key === 'origen') return [...new Set(data.stock.filter(s => s.org === context.org).map(s => s.warehouse || 'Almacén principal'))].map(value => ({ value, label: value }));
    if (action.flow === 'F48' && field.key === 'destino') return getOrganizations(data).find(o => o.id === context.org)!.branches.map(b => ({ value: b.name, label: b.name }));
    if (field.key === 'servicio' && ['F16', 'F17'].includes(action.flow)) return (context.org === 'org-vet' ? ['Consulta veterinaria', 'Control preventivo veterinario', 'Evaluación odontológica veterinaria'] : ['Consulta general', 'Consulta odontológica', 'Control cardiológico', 'Consulta pediátrica']).map(v => ({ value: v, label: v }));
    return (field.options || ['Seleccionar opción']).map(v => ({ value: v, label: v }));
  };
  const defaults: FormValues = Object.fromEntries(fields.map(f => {
    let value: string | number | boolean = '';
    if (f.type === 'checkbox') value = false;
    else if (f.type === 'date' && !/Nacimiento|vencim|finVigencia/i.test(f.key)) value = overlay.target?.date || DEMO_DATE;
    else if (f.type === 'time') { const start = overlay.target?.time || '12:00'; const minutes = Number(start.slice(0,2)) * 60 + Number(start.slice(3,5)) + 30; value = /fin/i.test(f.key) ? `${String(Math.floor(minutes / 60)).padStart(2,'0')}:${String(minutes % 60).padStart(2,'0')}` : start; }
    else if (f.key === 'paciente' || f.key === 'animal') value = context.patient;
    else if (f.key === 'sucursal') value = context.branch;
    else if (f.key === 'profesional') value = overlay.target?.professional || context.professional || professionals[0]?.id || '';
    else if (f.key === 'organizacion') value = context.org;
    else if (f.key === 'estructura' && overlay.target?.structure) value = overlay.target.structure;
    else if (f.key === 'pieza' && overlay.target?.structure) value = overlay.target.structure;
    else if (f.key === 'cara') value = overlay.target?.surface || query.get('cara') || '';
    else if (f.key === 'importe') value = Math.max(1, balance(data, context.org, context.patient) / 100 || 150);
    else if (f.key === 'lote') value = data.stock.find(s => s.org === context.org && (s.id === overlay.target?.stockId || !overlay.target?.stockId))?.id || '';
    else if (['documento', 'documentoVersion', 'original'].includes(f.key) && doc) value = doc.id;
    else if (f.key === 'cantidad') value = 1;
    else if (f.key === 'resumen' && encounter) value = draftNotes[encounter.id] ?? encounter.note;
    else if (f.type === 'select' && f.required && f.options?.length && !/condicion|estado|decision|sexo/i.test(f.key)) value = choices(f)[0]?.value || '';
    return [f.key, value];
  }));
  const { register, handleSubmit, control, formState: { errors }, setValue } = useForm<FormValues>({ defaultValues: defaults, resolver: zodResolver(schema) as Resolver<FormValues> });
  const isRead = ['DETAIL_SHEET_RIGHT', 'NAV_ROUTE', 'SELECT_CONTROL', 'FILTER_INLINE', 'GRAPH_CONTROL', 'EXPORT_LOCAL', 'PRINT_CLIENT', 'CLOSE_OR_RETURN', 'UNDO_LOCAL'].includes(action.pattern);
  const requiresReview = !isRead && (action.pattern === 'REVIEW_SHEET_RIGHT' || !!spec?.reviewRequired || !!commits[action.id] || /payments|charges|inventory|dispensing/.test(action.operation));
  const next = actions.filter(a => a.flow === action.flow && a.id !== action.id && a.roles.includes(context.role));
  async function commit(capture: FormValues) {
    setError('');
    try {
      if (isRead) {
        if (Object.keys(capture).length) setFilters(action.flow, capture);
        if (action.pattern === 'EXPORT_LOCAL') {
          if (action.flow === 'F64') { const packet = { fecha: DEMO_DATE, tipo: 'Exportación ficticia Health Project', organizacion: getOrganizations(data).find(o => o.id === context.org)?.name, pacientes: data.patients.filter(p => p.org === context.org), citas: data.appointments.filter(a => a.org === context.org), atenciones: data.encounters.filter(e => e.org === context.org), documentos: data.documents.filter(d => d.org === context.org), inventario: data.stock.filter(s => s.org === context.org), movimientos: data.movements.filter(m => m.org === context.org) }; downloadBlob(`health-project-exportacion-${DEMO_DATE}.json`, JSON.stringify(packet, null, 2), 'application/json'); }
          else if (action.flow === 'F71' && doc) downloadBlob(`${doc.title}-v${doc.version}.html`, documentHtml(doc, data), 'text/html;charset=utf-8');
          else if (overlay.target?.recordId && getFile(overlay.target.recordId)) downloadBlob(getFile(overlay.target.recordId)!.name, getFile(overlay.target.recordId)!);
          else downloadBlob(`health-project-${action.flow}-${DEMO_DATE}.csv`, csvText(data.records.filter(r => r.org === context.org && (r.resource === action.resource || action.flow === 'F65')).map(r => ({ titulo: r.title, estado: r.status, fecha: r.date, ...r.data }))), 'text/csv;charset=utf-8');
          notify('Archivo ficticio descargado.');
        } else if (action.pattern === 'PRINT_CLIENT') window.print();
        else if (action.pattern === 'NAV_ROUTE') {
          const destination = destinations[action.id] || screens.find(s => action.screens.includes(s.id) && s.routes[0]?.startsWith('/') && s.routes[0].split('?')[0] !== pathname)?.routes[0] || pathname;
          router.push(destination.endsWith('paciente=') ? destination + context.patient : destination.replace('=id', '=' + context.patient));
        } else if (['GRAPH_CONTROL', 'UNDO_LOCAL'].includes(action.pattern)) {
          const params = new URLSearchParams(query.toString()); params.set('vista', 'graficos'); params.set('seleccion', String(Number(query.get('seleccion') || 0) + 1));
          if (action.pattern === 'UNDO_LOCAL') { params.delete('atlas'); params.delete('estructura'); setFilters('F23', {}); }
          else if (action.flow === 'F24') { if (patient?.domain === 'ANIMAL') useDemo.getState().setSpecialty(profiles.find(profile => profile.patientDomain === 'ANIMAL' && profile.componentFamilies.includes('VET_DENTAL'))!.code); else if (!context.specialty.startsWith('D_')) useDemo.getState().setSpecialty('D_ODONTOLOGIA_GENERAL'); params.set('familia', patient?.domain === 'ANIMAL' ? 'VET_DENTAL' : 'HUMAN_DENTAL'); if (capture.pieza) params.set('pieza', String(capture.pieza)); if (capture.cara) params.set('cara', String(capture.cara)); }
          else { params.set('familia', 'ANATOMY'); if (capture.vista) params.set('atlas', String(capture.vista)); if (capture.estructura) { const [atlas, ...region] = String(capture.estructura).split(':'); params.set('atlas', atlas); params.set('estructura', region.join(':')); } }
          router.push('/app/atencion?' + params.toString());
        } else if (action.id === 'F01_A02' && capture.membresia) { const org = getOrganizations(data).find(o => o.id === capture.membresia); if (org) useDemo.getState().switchContext(org.id, org.branches[0].id); }
        else if (['F70_A03', 'F17_A02'].includes(action.id) && capture.paciente) setPatient(String(capture.paciente));
        setDirty(false); onComplete(); return;
      }
      if (action.id === 'F64_A01') {
        if (!selectedFile) throw new Error('Selecciona un CSV o JSON ficticio.');
        const preview = await prepareImport(selectedFile, String(capture.esquema || 'Pacientes')); setImportInfo(preview); setValues(capture); setStage('review'); setDirty(false); return;
      }
      let combined = { ...useDemo.getState().filters[action.flow], ...capture };
      if (action.id === 'F64_A04' && importInfo) combined = { ...capture, archivo: importInfo.name, esquema: importInfo.schema, filasJson: JSON.stringify(importInfo.rows), hashImport: importInfo.hash };
      const targetId = await execute(commits[action.id] || action.id, combined, overlay.target);
      setCreatedTargetId(targetId);
      if (selectedFile && targetId) cacheFile(targetId, selectedFile);
      setValues(capture); setStage('done');
      if (action.flow === 'F01' || action.flow === 'F70' || action.flow === 'F78') router.push(action.flow === 'F70' ? '/portal/inicio' : action.flow === 'F78' ? '/operacion/inicio' : '/app/inicio');
      if (['F79_A02', 'F79_A03'].includes(action.id)) { router.push(['PAC', 'RES'].includes(context.role) ? '/portal/acceso' : '/acceso'); }
    } catch (e) { setError(e instanceof Error ? e.message : 'No se pudo completar la operación.'); }
  }
  const onSubmit = handleSubmit(capture => { setValues(capture); setError(''); if (requiresReview && stage === 'edit') setStage('review'); else void commit(capture); });
  const selectTarget = overlay.target?.structure ? `${structureLabel(overlay.target.structure)}${overlay.target.surface ? ' · ' + overlay.target.surface : ''}` : '';
  return <>
    <div className="sheet-body">
      {patient && <div className="context-pill"><PersonAvatar patient={patient} /><div><strong>{patient.name}</strong><small>{patient.identifier} · {patient.species || patient.age}{selectTarget && ` · ${selectTarget}`}</small></div><Status value={appointment?.status || (['F27', 'F28', 'F38', 'F40', 'F71'].includes(action.flow) ? doc?.status : undefined) || 'Contexto activo'} /></div>}
      {stage === 'done' ? <div className="completed-action"><span><CheckCircle2 size={30} /></span><h2>Todo listo</h2><p>El registro quedó actualizado y ya puedes consultarlo en su módulo.</p>{next.length > 0 && <><h3>Continuar este recorrido</h3><div className="detail-actions">{next.slice(0, 5).map(a => <Button key={a.id} variant="outline" data-action={a.id} disabled={!!actionAvailability(a.id, data, context)} onClick={() => open({ kind: 'action', actionId: a.id, target: { ...overlay.target, ...(createdTargetId?.startsWith('document-') ? { documentId: createdTargetId } : createdTargetId?.startsWith('appointment-') ? { appointmentId: createdTargetId } : createdTargetId ? { recordId: createdTargetId } : {}) } })}>{a.label}<ArrowRight size={13} /></Button>)}</div></>}</div> : <>
        {stage === 'review' && <><div className="review-box"><ShieldCheck size={20} /><h3>Revisa antes de confirmar</h3><p>{action.flow === 'F27' || action.flow === 'F28' ? 'La firma es una simulación. Esta revisión quedará fija; una corrección posterior se registra mediante adenda.' : action.flow === 'F40' ? 'Se publicará únicamente esta versión para los vínculos vigentes del destinatario.' : 'Comprueba el paciente, el alcance y los datos de esta operación.'}</p></div>{Object.entries(values).filter(([, v]) => v !== '').map(([key, value]) => <div className="review-row" key={key}><span>{fields.find(f => f.key === key)?.label || key}</span><strong>{choices(fields.find(f => f.key === key) || { key, type: 'text', label: key, required: false }).find(c => c.value === value)?.label || nice(value)}</strong></div>)}{importInfo && action.flow === 'F64' && <div className="import-preview"><h3>{importInfo.name}</h3><p>{importInfo.rows.length} filas · {importInfo.errors.length} errores</p>{importInfo.errors.map(e => <p className="field-error" key={e}>{e}</p>)}<pre>{JSON.stringify(importInfo.rows.slice(0, 4), null, 2)}</pre></div>}</>}
        {stage === 'edit' && <form id="panel-form" onSubmit={onSubmit} onChange={() => setDirty(true)} className="form-grid">
          {fields.map(field => <div key={field.key} className={`form-field ${field.type === 'textarea' || field.type === 'checkbox' || field.type === 'file' ? 'field-full' : ''}`}>
            {field.type !== 'checkbox' && <label htmlFor={`field-${field.key}`}>{field.label}{field.required && <span className="required-mark"> *</span>}</label>}
            {field.type === 'select' ? <Controller name={field.key} control={control} render={({ field: controlled }) => <Select value={String(controlled.value || '') || null} onValueChange={value => { controlled.onChange(value || ''); if (['PAC', 'RES'].includes(context.role) && ['paciente', 'animal'].includes(field.key) && value) setPatient(String(value)); if (field.key === 'producto') { const stock = data.stock.find(s => s.id === value && s.org === context.org); if (stock) setValue('lote', stock.id); } setDirty(true); }}><SelectTrigger id={`field-${field.key}`} className="form-select"><SelectValue placeholder="Selecciona una opción">{controlled.value ? choices(field).find(option => option.value === String(controlled.value))?.label : undefined}</SelectValue></SelectTrigger><SelectContent>{choices(field).map(option => <SelectItem key={option.value} value={option.value}>{option.label}</SelectItem>)}</SelectContent></Select>} /> : field.type === 'checkbox' ? <Controller name={field.key} control={control} render={({ field: controlled }) => <label className="check-field"><Checkbox checked={!!controlled.value} onCheckedChange={value => { controlled.onChange(value); setDirty(true); }} /><span>{field.label}</span></label>} /> : field.type === 'textarea' ? <Textarea id={`field-${field.key}`} rows={4} {...register(field.key)} placeholder="Escribe lo que deseas registrar…" /> : field.type === 'file' ? <Input id={`field-${field.key}`} type="file" accept={action.flow === 'F64' ? '.csv,.json' : '.png,.jpg,.jpeg,.pdf,.svg,.txt,.csv,.json'} onChange={e => { const file = e.target.files?.[0]; if (file && file.size > 5 * 1024 * 1024) { setError('El archivo debe pesar menos de 5 MB.'); return; } setSelectedFile(file || null); setValue(field.key, file?.name || '', { shouldValidate: true }); setDirty(true); }} /> : <Input id={`field-${field.key}`} type={/contrase|password/i.test(field.key) ? 'password' : field.type} step={field.type === 'number' ? 'any' : undefined} min={field.min} {...register(field.key)} />}
            {field.type === 'file' && action.flow === 'F64' && <Button type="button" variant="ghost" onClick={() => downloadBlob('pacientes-ejemplo.csv', csvText([{ nombre: 'Paciente ficticio', identificacion: 'DEMO-IMPORT-01', correo: 'paciente@example.test' }]), 'text/csv;charset=utf-8')}><Download size={13} />Descargar CSV de ejemplo</Button>}{errors[field.key] && <p className="field-error">{String(errors[field.key]?.message || 'Revisa el campo.')}</p>}
          </div>)}
        </form>}
        {(fields.length === 0 || isRead || stage === 'review') && (action.flow === 'F21' && encounter ? <div className="document-preview"><p className="table-subtext">Atención · {encounter.date}</p><div className="doc-heading">Resumen de la visita</div><p>{draftNotes[encounter.id] ?? encounter.note ?? 'Sin nota registrada.'}</p><hr /><p>{data.annotations.filter(a => a.org === context.org && a.patient === context.patient).length} registros gráficos · {data.documents.filter(d => d.org === context.org && d.patient === context.patient).length} documentos</p>{draftNotes[encounter.id] !== undefined && <p className="field-error">Hay una nota local que debes guardar antes de finalizar.</p>}</div> : doc && ['F27', 'F28', 'F38', 'F40', 'F71'].includes(action.flow) ? <div className="document-preview"><p className="table-subtext">Health Project · Documento de demostración</p><div className="doc-heading">{doc.title}</div><p>{doc.date} · Versión {doc.version} · {patient?.name}</p><hr /><p>{doc.content}</p><hr /><p className="table-subtext">{doc.signed || 'Borrador sin firma'} · {doc.published ? 'Publicado en portal' : 'Privado'}</p></div> : appointment && ['F16', 'F18', 'F20'].includes(action.flow) ? <div className="detail-values"><div className="review-row"><span>Servicio</span><strong>{appointment.service}</strong></div><div className="review-row"><span>Fecha y hora</span><strong>{appointment.date} · {appointment.time}</strong></div><div className="review-row"><span>Profesional</span><strong>{getSaas(data).professionals.find(p => p.id === appointment.professional)?.name}</strong></div><div className="review-row"><span>Estado</span><Status value={appointment.status} /></div></div> : record && <div className="detail-values"><div className="review-row"><span>Registro</span><strong>{record.title}</strong></div><div className="review-row"><span>Estado</span><Status value={record.status} /></div>{Object.entries(record.data).filter(([key]) => key !== 'operacion').map(([key, value]) => <div className="review-row" key={key}><span>{key.replace(/([A-Z])/g, ' $1')}</span><strong>{displayValue(value, data)}</strong></div>)}</div>)}
        {isRead && fields.length === 0 && !doc && !appointment && !record && <div className="review-box"><h3>{flow.name}</h3><p>{patient ? 'Elige un registro de este paciente para continuar.' : 'Selecciona un contexto válido para consultar.'}</p></div>}
      </>}
      {attachedFile && isRead && <AttachmentPreview key={attachedFile.name + attachedFile.lastModified} file={attachedFile} />}
      {record?.history?.length && isRead ? <details className="capture-extra"><summary>Revisiones anteriores</summary>{record.history.map(revision => <div className="review-box" key={revision.revision}><h3>Revisión {revision.revision} · {revision.status}</h3>{Object.entries(revision.data).map(([key, value]) => <div className="review-row" key={key}><span>{key}</span><strong>{displayValue(value, data)}</strong></div>)}</div>)}</details> : null}
      {error && <div className="error-message" role="alert"><AlertCircle size={17} /><span>{error}</span></div>}
    </div>
    <div data-slot="sheet-footer"><Button variant="outline" onClick={() => stage === 'review' ? setStage('edit') : onComplete()}>{stage === 'review' ? 'Volver a editar' : stage === 'done' ? 'Cerrar' : 'Cancelar'}</Button><div className="sheet-footer-right">{stage === 'done' ? <Button onClick={onComplete}>Volver a la pantalla <Check size={15} /></Button> : stage === 'review' ? <Button disabled={busy} onClick={() => action.id === 'F64_A01' ? open({ kind: 'action', actionId: 'F64_A04' }) : void commit(values)}>{busy ? <LoaderCircle className="animate-spin" size={16} /> : <Check size={15} />}{action.id === 'F64_A01' ? 'Aplicar lote' : 'Confirmar'}</Button> : <Button form="panel-form" type="submit" disabled={busy}>{busy && <LoaderCircle className="animate-spin" size={16} />}{isRead ? action.pattern === 'EXPORT_LOCAL' ? 'Descargar' : action.pattern === 'PRINT_CLIENT' ? 'Imprimir' : action.pattern === 'NAV_ROUTE' ? 'Abrir vista' : 'Listo' : requiresReview ? 'Revisar y continuar' : action.flow === 'F10' ? 'Guardar paciente' : action.flow === 'F11' ? 'Guardar animal' : 'Guardar y continuar'}{!busy && <ArrowRight size={14} />}</Button>}</div></div>
  </>;
}

function AttachmentPreview({ file }: { file: File }) {
  const [url] = useState(() => URL.createObjectURL(file));
  useEffect(() => () => URL.revokeObjectURL(url), [url]);
  return <div><p className="section-label">{file.name}</p>{file.type.startsWith('image/') ? <Image className="file-preview-image" src={url} alt={file.name} width={800} height={600} unoptimized /> : <iframe className="file-preview-frame" src={url} title={`Vista previa de ${file.name}`} />}</div>;
}
