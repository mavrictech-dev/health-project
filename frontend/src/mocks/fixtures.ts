import { createSaasState } from '@/lib/saas';
import { flows } from '@/lib/spec';
import { patientScopedFlows } from '@/lib/scope';
import type { DemoData, Organization, Patient, RecordItem } from '@/lib/types';

export const DEMO_DATE = '2026-10-13';
export const organizations = [
  { id: 'org-human', name: 'Clínica Aurora', initials: 'CA', type: 'Medicina humana', branches: [{ id: 'miraflores', name: 'Miraflores' }, { id: 'san-isidro', name: 'San Isidro' }] },
  { id: 'org-vet', name: 'Vértice Veterinaria', initials: 'VV', type: 'Veterinaria', branches: [{ id: 'vet-centro', name: 'Sede Central' }, { id: 'vet-norte', name: 'Sede Norte' }] },
  { id: 'org-own', name: 'Consultorio Dr. Mateo', initials: 'MM', type: 'Profesional independiente', branches: [{ id: 'consultorio', name: 'Consultorio propio' }, { id: 'externa', name: 'Lugar externo · Clínica del Valle', external: true }] },
];
export const professionals = [
  { id: 'pro-mateo', name: 'Dr. Mateo Mendoza', specialty: 'Medicina general', color: 'sage', avatar: 'MM' },
  { id: 'pro-valeria', name: 'Dra. Valeria Torres', specialty: 'Odontología', color: 'lilac', avatar: 'VT' },
  { id: 'pro-andres', name: 'Dr. Andrés Ríos', specialty: 'Cardiología', color: 'blue', avatar: 'AR' },
  { id: 'pro-camila', name: 'Dra. Camila Silva', specialty: 'Veterinaria', color: 'peach', avatar: 'CS' },
];
export const getOrganizations = (data: Pick<DemoData, 'organizations'>): Organization[] => data.organizations || organizations;
export const isVeterinary = (data: DemoData, id: string) => /veterinar/i.test(getOrganizations(data).find(o => o.id === id)?.type || '');
const people: Patient[] = [
  { id: 'p-lucia', org: 'org-human', name: 'Lucía Fernández', domain: 'HUMAN', age: '32 años', identifier: 'DEMO-1001', phone: '900 000 101', email: 'lucia@example.test', avatar: 'LF', color: 'peach', specialty: 'H_GENERAL_MEDICINE', allergies: ['Penicilina · registrada'], created: DEMO_DATE },
  { id: 'p-diego', org: 'org-human', name: 'Diego Martínez', domain: 'HUMAN', age: '41 años', identifier: 'DEMO-1002', phone: '900 000 102', email: 'diego@example.test', avatar: 'DM', color: 'blue', specialty: 'D_ODONTOLOGIA_GENERAL', allergies: [], created: DEMO_DATE },
  { id: 'p-elena', org: 'org-human', name: 'Elena Rodríguez', domain: 'HUMAN', age: '58 años', identifier: 'DEMO-1003', phone: '900 000 103', email: 'elena@example.test', avatar: 'ER', color: 'lilac', specialty: 'H_CARDIOLOGY', allergies: [], created: DEMO_DATE },
  { id: 'p-nicolas', org: 'org-human', name: 'Nicolás Castro', domain: 'HUMAN', age: '8 años', identifier: 'DEMO-1004', phone: '900 000 104', email: 'responsable.nicolas@example.test', responsible: 'Mariana Castro', avatar: 'NC', color: 'sage', specialty: 'H_PEDIATRICS', allergies: [], created: DEMO_DATE },
  { id: 'p-sofia', org: 'org-human', name: 'Sofía Herrera', domain: 'HUMAN', age: '27 años', identifier: 'DEMO-1005', phone: '900 000 105', email: 'sofia@example.test', avatar: 'SH', color: 'pink', specialty: 'H_GENERAL_MEDICINE', allergies: [], created: DEMO_DATE },
  { id: 'p-carlos', org: 'org-human', name: 'Carlos Vega', domain: 'HUMAN', age: '46 años', identifier: 'DEMO-1006', phone: '900 000 106', email: 'carlos@example.test', avatar: 'CV', color: 'sand', specialty: 'H_CARDIOLOGY', allergies: [], created: DEMO_DATE },
  { id: 'p-luna', org: 'org-vet', name: 'Luna', domain: 'ANIMAL', species: 'Canino', age: '4 años', identifier: 'DEMO-V001', phone: '900 000 201', email: 'responsable.luna@example.test', responsible: 'Ana Valdez', avatar: 'LU', color: 'peach', specialty: 'V_GENERAL', allergies: [], created: DEMO_DATE },
  { id: 'p-milo', org: 'org-vet', name: 'Milo', domain: 'ANIMAL', species: 'Felino', age: '2 años', identifier: 'DEMO-V002', phone: '900 000 202', email: 'responsable.milo@example.test', responsible: 'Jorge Pérez', avatar: 'MI', color: 'lilac', specialty: 'V_GENERAL', allergies: [], created: DEMO_DATE },
  { id: 'p-nala', org: 'org-vet', name: 'Nala', domain: 'ANIMAL', species: 'Canino', age: '6 años', identifier: 'DEMO-V003', phone: '900 000 203', email: 'responsable.nala@example.test', responsible: 'Andrea Soto', avatar: 'NA', color: 'sage', specialty: 'V_CARDIO', allergies: [], created: DEMO_DATE },
  { id: 'p-rayo', org: 'org-vet', name: 'Rayo', domain: 'ANIMAL', species: 'Equino', age: '7 años', identifier: 'DEMO-V004', phone: '900 000 204', email: 'responsable.rayo@example.test', responsible: 'Hacienda Los Olivos', avatar: 'RA', color: 'sand', specialty: 'V_GENERAL', allergies: [], created: DEMO_DATE },
  { id: 'p-lucia-other', org: 'org-own', name: 'Lucía Fernández', domain: 'HUMAN', age: '36 años', identifier: 'DEMO-3001', phone: '900 000 301', email: 'otra.lucia@example.test', avatar: 'LF', color: 'blue', specialty: 'H_GENERAL_MEDICINE', allergies: [], created: DEMO_DATE },
];

export function createFixtures(scenario = 'consulta'): DemoData {
  const patients = structuredClone(people);
  const appointments = [
    { id: 'a-1', org: 'org-human', branch: 'miraflores', patient: 'p-lucia', professional: 'pro-mateo', service: 'Consulta de medicina general', specialty: 'H_GENERAL_MEDICINE', date: DEMO_DATE, time: '09:00', duration: 30, status: 'En atención', note: 'Control y seguimiento' },
    { id: 'a-2', org: 'org-human', branch: 'miraflores', patient: 'p-diego', professional: 'pro-valeria', service: 'Evaluación odontológica', specialty: 'D_ODONTOLOGIA_GENERAL', date: DEMO_DATE, time: '09:30', duration: 45, status: 'En espera', note: 'Primera evaluación' },
    { id: 'a-3', org: 'org-human', branch: 'miraflores', patient: 'p-elena', professional: 'pro-andres', service: 'Control cardiológico', specialty: 'H_CARDIOLOGY', date: DEMO_DATE, time: '10:15', duration: 30, status: 'Confirmada', note: 'Revisión de resultados' },
    { id: 'a-4', org: 'org-human', branch: 'miraflores', patient: 'p-nicolas', professional: 'pro-mateo', service: 'Consulta pediátrica', specialty: 'H_PEDIATRICS', date: DEMO_DATE, time: '11:00', duration: 30, status: 'Confirmada', note: 'Control de crecimiento' },
    { id: 'a-5', org: 'org-human', branch: 'san-isidro', patient: 'p-sofia', professional: 'pro-mateo', service: 'Consulta de medicina general', specialty: 'H_GENERAL_MEDICINE', date: DEMO_DATE, time: '14:00', duration: 30, status: 'Reservada', note: '' },
    { id: 'a-6', org: 'org-human', branch: 'miraflores', patient: 'p-carlos', professional: 'pro-andres', service: 'Control cardiológico', specialty: 'H_CARDIOLOGY', date: DEMO_DATE, time: '15:00', duration: 30, status: 'Reservada', note: '' },
    { id: 'a-v1', org: 'org-vet', branch: 'vet-centro', patient: 'p-luna', professional: 'pro-camila', service: 'Consulta veterinaria', specialty: 'V_GENERAL', date: DEMO_DATE, time: '09:00', duration: 30, status: 'En espera', note: 'Control preventivo' },
    { id: 'a-v2', org: 'org-vet', branch: 'vet-centro', patient: 'p-milo', professional: 'pro-camila', service: 'Consulta veterinaria', specialty: 'V_GENERAL', date: DEMO_DATE, time: '10:00', duration: 30, status: 'Confirmada', note: '' },
  ];
  const encounters = [
    { id: 'e-1', org: 'org-human', branch: 'miraflores', patient: 'p-lucia', professional: 'pro-mateo', date: DEMO_DATE, specialty: 'H_GENERAL_MEDICINE', status: 'En curso', note: 'Paciente acude a control. Registrar evolución y revisión de antecedentes.', revision: 1 },
    { id: 'e-old', org: 'org-human', branch: 'san-isidro', patient: 'p-lucia', professional: 'pro-mateo', date: '2026-09-22', specialty: 'H_GENERAL_MEDICINE', status: 'Finalizada', note: 'Consulta de seguimiento. Documento firmado de demostración.', revision: 2 },
    { id: 'e-dental', org: 'org-human', branch: 'miraflores', patient: 'p-diego', professional: 'pro-valeria', date: DEMO_DATE, specialty: 'D_ODONTOLOGIA_GENERAL', status: 'Borrador', note: '', revision: 1 },
    { id: 'e-vet', org: 'org-vet', branch: 'vet-centro', patient: 'p-luna', professional: 'pro-camila', date: DEMO_DATE, specialty: 'V_GENERAL', status: 'En curso', note: 'Evaluación veterinaria de ejemplo.', revision: 1 },
  ];
  const records: RecordItem[] = flows.flatMap((f, i) => {
    const vetOnly = ['F11', 'F14', 'F60'].includes(f.id);
    return (vetOnly ? ['org-vet'] : ['org-human', 'org-vet']).map(org => ({
      id: `r-${org}-${f.id}`, org, resource: f.resource, flow: f.id, patient: patientScopedFlows.has(f.id) ? org === 'org-vet' ? 'p-luna' : 'p-lucia' : undefined,
      title: f.name, status: /consult|queries|reading|reports/.test(f.resource) ? 'Disponible' : ['Pendiente', 'En curso', 'Registrado'][i % 3], date: DEMO_DATE, revision: 1,
      data: { descripcion: 'Registro ficticio preparado para la presentación.', responsable: org === 'org-vet' ? 'Dra. Camila Silva' : 'Dr. Mateo Mendoza', origen: org === 'org-vet' ? 'Sede Central' : 'Miraflores' },
    }));
  });
  const data: DemoData = {
    organizations: structuredClone(organizations), patients, appointments, encounters, records,
    documents: [
      { id: 'doc-1', org: 'org-human', patient: 'p-lucia', title: 'Resumen de consulta', type: 'Nota clínica', status: 'Firmado · demo', version: 1, content: 'Resumen de control y seguimiento\n\nMotivo: consulta de seguimiento.\nEvolución registrada en la atención del 22 de septiembre.\n\nDocumento ficticio para demostración.', signed: 'Dr. Mateo Mendoza', published: true, date: '2026-09-22' },
      { id: 'doc-2', org: 'org-human', patient: 'p-lucia', title: 'Evolución de hoy', type: 'Nota clínica', status: 'Borrador', version: 1, content: 'Motivo de consulta:\n\nEvaluación:\n\nPlan registrado:', published: false, date: DEMO_DATE },
      { id: 'doc-v1', org: 'org-vet', patient: 'p-luna', title: 'Control veterinario de Luna', type: 'Informe veterinario', status: 'Firmado · demo', version: 1, content: 'Control veterinario ficticio.\nResponsable: Ana Valdez.\nEspecie: canino.\n\nDocumento preparado para demostración.', signed: 'Dra. Camila Silva', published: true, date: '2026-09-30' },
    ],
    observations: ['2026-07-13', '2026-08-13', '2026-09-13', DEMO_DATE].flatMap((date, i) => [
      { id: `o-bp-${i}`, org: 'org-human', patient: 'p-lucia', parameter: 'Presión sistólica', value: [124, 122, 120, 118][i], unit: 'mmHg', date },
      { id: `o-hr-${i}`, org: 'org-human', patient: 'p-lucia', parameter: 'Frecuencia cardíaca', value: [76, 74, 72, 72][i], unit: 'lpm', date },
      { id: `o-w-${i}`, org: 'org-vet', patient: 'p-luna', parameter: 'Peso', value: [18.4, 18.7, 19, 19.1][i], unit: 'kg', date },
    ]),
    annotations: [
      { id: 'an-d1', org: 'org-human', patient: 'p-diego', encounter: 'e-dental', component: 'HUMAN_DENTAL', structure: '16', surface: 'Oclusal', condition: 'Hallazgo registrado', date: DEMO_DATE },
      { id: 'an-d2', org: 'org-human', patient: 'p-diego', encounter: 'e-dental', component: 'HUMAN_DENTAL', structure: '36', surface: 'Vestibular', condition: 'Procedimiento planificado', date: DEMO_DATE },
    ],
    movements: [
      { id: 'm-1', org: 'org-human', patient: 'p-lucia', kind: 'charge', amount: 12000, title: 'Consulta de medicina general', date: DEMO_DATE },
      { id: 'm-2', org: 'org-human', patient: 'p-lucia', kind: 'payment', amount: 6000, title: 'Pago parcial · efectivo demo', date: DEMO_DATE },
      { id: 'm-v1', org: 'org-vet', patient: 'p-luna', kind: 'charge', amount: 8000, title: 'Consulta veterinaria', date: DEMO_DATE },
    ],
    stock: [
      { id: 'stock-1', org: 'org-human', name: 'Producto de farmacia A', lot: 'DEMO-L001', expiry: '2027-08-30', quantity: 48, unit: 'unidades', category: 'Farmacia' },
      { id: 'stock-2', org: 'org-human', name: 'Material clínico B', lot: 'DEMO-L002', expiry: '2027-03-30', quantity: 120, unit: 'unidades', category: 'Insumos' },
      { id: 'stock-v1', org: 'org-vet', name: 'Producto veterinario A', lot: 'DEMO-V001', expiry: '2027-10-30', quantity: 36, unit: 'unidades', category: 'Veterinaria' },
    ],
    beds: [
      { id: 'bed-1', org: 'org-human', name: 'Cama 101', type: 'Cama', area: 'Hospitalización general', patient: 'p-lucia', status: 'Ocupada' },
      { id: 'bed-2', org: 'org-human', name: 'Cama 102', type: 'Cama', area: 'Hospitalización general', status: 'Disponible' },
      { id: 'bed-3', org: 'org-human', name: 'Cama 103', type: 'Cama', area: 'Hospitalización general', status: 'Disponible' },
      { id: 'bed-v1', org: 'org-vet', name: 'Jaula A1', type: 'Jaula', area: 'Hospital veterinario', status: 'Disponible' },
      { id: 'bed-v2', org: 'org-vet', name: 'Jaula A2', type: 'Jaula', area: 'Hospital veterinario', patient: 'p-milo', status: 'Ocupada' },
    ],
    events: [{ id: 'event-seed', org: 'org-human', branch: 'miraflores', actor: 'PRO', operation: 'demo.start', label: 'Inicio del escenario de presentación', date: DEMO_DATE }],
    jobs: [{ id: 'job-1', org: 'org-human', type: 'Comprobante', label: 'Emisión de comprobante DEMO-001', status: 'Rechazado · demo', attempts: 1, operationId: 'invoice-demo-001', date: DEMO_DATE }],
  };
  for (const id of ['p-nicolas', 'p-milo']) {
    const p = patients.find(p => p.id === id)!;
    data.records.push({ id: `link-${id}`, org: p.org, resource: 'portal-links', flow: 'F39', patient: p.id, title: `Vínculo verificado de ${p.name}`, status: 'Vigente', date: DEMO_DATE, revision: 1, data: { responsable: p.responsible || 'Responsable ficticio', alcance: 'Citas y contenido publicado' } });
  }
  data.records.filter(r => r.resource === 'portal-links').forEach(r => { r.status = 'Vigente'; });
  if (scenario === 'veterinaria') data.appointments.find(a => a.id === 'a-v1')!.status = 'En atención';
  data.saas = createSaasState(data.organizations);
  return data;
}
