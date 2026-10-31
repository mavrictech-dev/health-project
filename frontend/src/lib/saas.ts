import { specialties } from './spec';
import type { Context, DemoData, Organization, PatientDomain } from './types';
import type { ModuleId, SaasCommand, SaasPlan, SaasState, SaasTarget, SaasValues, Subscription, Tenant, TenantKind } from './saas-types';

export const SAAS_DATE = '2026-10-13';
export const tenantKinds: { id: TenantKind; label: string }[] = [
  { id: 'DOCTOR', label: 'Profesional independiente' }, { id: 'CLINIC', label: 'Clínica humana' }, { id: 'HOSPITAL', label: 'Hospital' },
  { id: 'VETERINARY', label: 'Centro veterinario' }, { id: 'DENTAL', label: 'Centro odontológico' }, { id: 'SPECIALTY_CENTER', label: 'Centro de especialidad' },
];
export const saasModules: { id: ModuleId; name: string; description: string }[] = [
  { id: 'CORE', name: 'Consulta y agenda', description: 'Pacientes, historias, consulta, recetas y documentos.' },
  { id: 'PORTAL', name: 'Portal', description: 'Pacientes y responsables con contenido publicado.' },
  { id: 'DENTAL', name: 'Odontología', description: 'Odontogramas y registros dentales.' },
  { id: 'DIAGNOSTICS', name: 'Diagnóstico', description: 'Laboratorio, muestras e imágenes.' },
  { id: 'PHARMACY', name: 'Farmacia', description: 'Dispensación y administración de medicación.' },
  { id: 'FINANCE', name: 'Finanzas', description: 'Presupuestos, caja y comprobantes clínicos.' },
  { id: 'INVENTORY', name: 'Compras e inventario', description: 'Productos, lotes y transferencias.' },
  { id: 'HOSPITAL', name: 'Hospitalización', description: 'Admisiones, camas o jaulas y cuidados.' },
  { id: 'SURGERY', name: 'Cirugía y anestesia', description: 'Casos quirúrgicos y recuperación.' },
  { id: 'ADVANCED', name: 'Procesos especializados', description: 'Sesiones, transfusión, trasplante y reproducción.' },
  { id: 'VET_POPULATION', name: 'Salud poblacional veterinaria', description: 'Poblaciones y programas sanitarios.' },
  { id: 'REPORTS', name: 'Reportes', description: 'Indicadores del cliente.' },
];
export const commandTitles: Record<SaasCommand, string> = { 'tenant.create': 'Crear cliente / tenant', 'tenant.edit': 'Editar cliente', 'tenant.status': 'Cambiar estado del cliente', 'plan.create': 'Crear plan', 'plan.edit': 'Editar plan', 'subscription.configure': 'Configurar suscripción', 'branch.create': 'Añadir sede o lugar de atención', 'branch.edit': 'Editar sede', 'branch.archive': 'Cambiar disponibilidad de la sede', 'member.create': 'Añadir profesional', 'member.edit': 'Configurar profesional', 'member.status': 'Cambiar estado del profesional', 'specialties.configure': 'Configurar especialidades', 'area.create': 'Crear área de especialidad', 'area.edit': 'Editar área', 'invoice.pay': 'Registrar pago de suscripción demo' };
const allModules = saasModules.map(m => m.id);
const humanCodes = ['H_GENERAL_MEDICINE', 'H_CARDIOLOGY', 'H_PEDIATRICS', 'H_NEUROLOGY', 'H_DERMATOLOGY', 'H_ORTHOPEDICS', 'D_ODONTOLOGIA_GENERAL', 'D_PERIODONCIA', 'D_ORTODONCIA_ORTOPEDIA_DENTOFACIAL'];
const vetCodes = ['V_GENERAL', 'V_CARDIO', 'V_DENTAL', 'V_DERM', 'V_ORTHO', 'V_NEURO'];
const validCodes = (codes: string[]) => codes.filter(code => specialties.some(s => s.code === code));
export function kindLabel(kind: TenantKind) { return tenantKinds.find(k => k.id === kind)?.label || kind; }
export function specialtyName(code: string) { return specialties.find(s => s.code === code)?.name || code; }
export function compatibleSpecialties(tenant: Pick<Tenant, 'domain' | 'kind'>) { return specialties.filter(s => s.patientDomain === tenant.domain && (tenant.kind !== 'DENTAL' || s.code.startsWith('D_'))); }
export function compatiblePlans(state: SaasState, tenant: Pick<Tenant, 'domain' | 'kind'>) { return state.plans.filter(p => p.status === 'Publicado' && p.kinds.includes(tenant.kind) && p.domains.includes(tenant.domain)); }
export function quote(subscription: Subscription) {
  const rate = subscription.rate;
  const branches = Math.max(0, subscription.branchQuota - rate.includedBranches) * rate.perBranch;
  const professionals = Math.max(0, subscription.professionalQuota - rate.includedProfessionals) * rate.perProfessional;
  const monthly = rate.base + branches + professionals;
  return { base: rate.base, branches, professionals, monthly, total: subscription.cycle === 'Anual' ? Math.round(monthly * 12 * (1 - rate.annualDiscount / 100)) : monthly, monthlyEquivalent: subscription.cycle === 'Anual' ? Math.round(monthly * (1 - rate.annualDiscount / 100)) : monthly };
}
export function newSubscription(plan: SaasPlan, cycle: 'Mensual' | 'Anual' = 'Mensual', branches = plan.rate.includedBranches, professionals = plan.rate.includedProfessionals, specialtyQuota = plan.includedSpecialties): Subscription {
  return { planId: plan.id, cycle, branchQuota: branches, professionalQuota: professionals, specialtyQuota, rate: structuredClone(plan.rate), modules: [...plan.modules], nextRenewal: cycle === 'Anual' ? '2027-10-13' : '2026-11-13' };
}
export function createSaasState(organizations: Organization[]): SaasState {
  const makePlan = (id: string, name: string, description: string, base: number, includedBranches: number, includedProfessionals: number, maxBranches: number, maxProfessionals: number, includedSpecialties: number, maxSpecialties: number, kinds: TenantKind[], modules = allModules): SaasPlan => ({ id, name, description, version: 1, status: 'Publicado', kinds, domains: ['HUMAN', 'ANIMAL'], rate: { version: 1, base, perBranch: id === 'plan-professional' ? 3500 : 9900, perProfessional: id === 'plan-vet' ? 3900 : 4500, includedBranches, includedProfessionals, annualDiscount: 15 }, maxBranches, maxProfessionals, includedSpecialties, maxSpecialties, modules });
  const plans = [
    makePlan('plan-professional', 'Profesional', 'Un médico, odontólogo o veterinario independiente.', 8900, 1, 1, 3, 1, 5, 10, ['DOCTOR'], ['CORE', 'PORTAL', 'DENTAL', 'FINANCE', 'REPORTS']),
    makePlan('plan-center', 'Centro', 'Equipos clínicos, centros odontológicos y de especialidad.', 29900, 1, 5, 30, 200, 10, 182, ['CLINIC', 'DENTAL', 'SPECIALTY_CENTER']),
    makePlan('plan-hospital', 'Hospital', 'Sedes, áreas y equipos de una institución grande.', 89900, 3, 20, 100, 1000, 30, 241, ['HOSPITAL', 'CLINIC', 'VETERINARY']),
    makePlan('plan-vet', 'Veterinaria', 'Clínicas y redes veterinarias con varias sedes.', 24900, 1, 3, 40, 300, 10, 59, ['VETERINARY']),
  ];
  const state: SaasState = { plans, tenants: [], professionals: [
    { id: 'pro-mateo', name: 'Dr. Mateo Mendoza', email: 'mateo@example.test', domain: 'HUMAN', credential: 'DEMO-CMP-001', color: 'sage', avatar: 'MM' },
    { id: 'pro-valeria', name: 'Dra. Valeria Torres', email: 'valeria@example.test', domain: 'HUMAN', credential: 'DEMO-COP-002', color: 'lilac', avatar: 'VT' },
    { id: 'pro-andres', name: 'Dr. Andrés Ríos', email: 'andres@example.test', domain: 'HUMAN', credential: 'DEMO-CMP-003', color: 'blue', avatar: 'AR' },
    { id: 'pro-camila', name: 'Dra. Camila Silva', email: 'camila@example.test', domain: 'ANIMAL', credential: 'DEMO-CMVP-004', color: 'peach', avatar: 'CS' },
  ], memberships: [], areas: [], invoices: [], events: [{ id: 'saas-seed', actor: 'SAD', label: 'Clientes de demostración configurados', target: 'Plataforma', date: SAAS_DATE }] };
  for (const org of organizations) {
    const vet = /veterin/i.test(org.type); const solo = /independiente/i.test(org.type);
    const kind: TenantKind = solo ? 'DOCTOR' : vet ? 'VETERINARY' : org.id === 'org-human' ? 'HOSPITAL' : 'CLINIC';
    const plan = plans.find(p => p.id === (solo ? 'plan-professional' : vet ? 'plan-vet' : kind === 'HOSPITAL' ? 'plan-hospital' : 'plan-center'))!;
    const codes = validCodes(solo ? ['H_GENERAL_MEDICINE', 'H_PEDIATRICS'] : vet ? vetCodes : humanCodes);
    const count = org.branches.filter(b => !b.external && !/Lugar externo/i.test(b.name)).length;
    const tenant: Tenant = { id: org.id, kind, domain: vet ? 'ANIMAL' : 'HUMAN', status: 'Activo', slug: org.id.replace('org-', ''), ownerName: solo ? 'Dr. Mateo Mendoza' : vet ? 'Dra. Camila Silva' : 'Isabel García', ownerEmail: solo ? 'mateo@example.test' : vet ? 'camila@example.test' : 'administracion@example.test', created: SAAS_DATE, specialties: codes, subscription: newSubscription(plan, 'Mensual', Math.max(plan.rate.includedBranches, count), plan.rate.includedProfessionals) };
    state.tenants.push(tenant);
    const ids = solo ? ['pro-mateo'] : vet ? ['pro-camila'] : org.id === 'org-human' ? ['pro-mateo', 'pro-valeria', 'pro-andres'] : [];
    for (const id of ids) state.memberships.push({ id: `member-${org.id}-${id}`, tenantId: org.id, professionalId: id, specialties: id === 'pro-valeria' ? codes.filter(c => c.startsWith('D_')) : id === 'pro-andres' ? codes.filter(c => c === 'H_CARDIOLOGY') : codes.filter(c => !c.startsWith('D_')), branchIds: org.branches.map(b => b.id), status: 'Activo', owner: solo || vet });
    org.branches.filter(b => !b.external && !/Lugar externo/i.test(b.name)).forEach(branch => state.areas.push({ id: `area-${branch.id}`, tenantId: org.id, branchId: branch.id, name: solo ? 'Consulta del profesional' : vet ? 'Consulta veterinaria' : 'Consulta externa', specialties: [...codes] }));
    state.invoices.push({ id: `invoice-${org.id}`, tenantId: org.id, number: `SaaS-DEMO-${state.tenants.length.toString().padStart(3, '0')}`, period: 'Octubre 2026', amount: quote(tenant.subscription).total, date: SAAS_DATE, status: org.id === 'org-vet' ? 'Pendiente' : 'Pagado' });
  }
  return state;
}
export function normalizeSaasData(input: DemoData): DemoData {
  if (input.saas && input.organizations.every(o => input.saas!.tenants.some(t => t.id === o.id))) return input;
  const data = structuredClone(input); const seeded = createSaasState(data.organizations);
  if (!data.saas) data.saas = seeded;
  else for (const tenant of seeded.tenants.filter(t => !data.saas!.tenants.some(existing => existing.id === t.id))) { data.saas.tenants.push(tenant); data.saas.areas.push(...seeded.areas.filter(a => a.tenantId === tenant.id)); }
  data.organizations.flatMap(o => o.branches).forEach(b => { if (/Lugar externo/i.test(b.name)) b.external = true; });
  return data;
}
export function getSaas(data: DemoData) { return data.saas || createSaasState(data.organizations || []); }
export function getTenant(data: DemoData, id: string) { return getSaas(data).tenants.find(t => t.id === id); }
export function tenantUsage(data: DemoData, id: string) {
  const org = data.organizations.find(o => o.id === id); const state = getSaas(data); const tenant = state.tenants.find(t => t.id === id);
  return { branches: org?.branches.filter(b => b.status !== 'Inactiva' && !b.external && !/Lugar externo/i.test(b.name)).length || 0, professionals: state.memberships.filter(m => m.tenantId === id && m.status !== 'Inactivo').length, specialties: tenant?.specialties.length || 0 };
}
export function tenantProfessionals(data: DemoData, id: string, branch?: string) {
  const state = getSaas(data);
  return state.memberships.filter(m => m.tenantId === id && m.status === 'Activo' && (!branch || m.branchIds.includes(branch))).flatMap(m => { const p = state.professionals.find(p => p.id === m.professionalId); return p ? [{ ...p, membership: m, specialty: m.specialties.map(specialtyName).join(' · ') }] : []; });
}
export function tenantSpecialties(data: DemoData, id: string) { const tenant = getTenant(data, id); return specialties.filter(s => tenant ? tenant.specialties.includes(s.code) : s.patientDomain === 'HUMAN'); }
export function canManageTenant(data: DemoData, context: Context, tenantId = context.org) {
  if (context.role === 'SAD') return true;
  if (context.org !== tenantId) return false;
  if (context.role === 'ADM') return true;
  const tenant = getTenant(data, tenantId);
  return context.role === 'PRO' && tenant?.kind === 'DOCTOR' && getSaas(data).memberships.some(m => m.tenantId === tenantId && m.owner && m.status === 'Activo' && (!context.professional || m.professionalId === context.professional));
}
export function moduleForPath(path: string): ModuleId | undefined {
  if (path.startsWith('/portal')) return 'PORTAL';
  if (path.startsWith('/app/diagnostico') || path === '/app/ordenes') return 'DIAGNOSTICS';
  if (path === '/app/farmacia' || path === '/app/hospital/medicacion') return 'PHARMACY';
  if (path.startsWith('/app/hospital') || path === '/app/urgencias') return 'HOSPITAL';
  if (['/app/cirugia', '/app/anestesia'].includes(path)) return 'SURGERY';
  if (path === '/app/especialidades') return 'ADVANCED';
  if (path.startsWith('/app/veterinaria')) return 'VET_POPULATION';
  if (path.startsWith('/app/finanzas')) return 'FINANCE';
  if (['/app/inventario', '/app/compras'].includes(path)) return 'INVENTORY';
  if (path === '/app/reportes') return 'REPORTS';
  return undefined;
}
export function pathLicenseReason(data: DemoData, context: Context, path: string) {
  const tenant = getTenant(data, context.org); const feature = moduleForPath(path);
  if (!tenant || !feature) return '';
  if (feature === 'VET_POPULATION' && tenant.domain !== 'ANIMAL') return 'Este módulo corresponde al ámbito veterinario.';
  return tenant.subscription.modules.includes(feature) ? '' : `${saasModules.find(m => m.id === feature)?.name} no está incluido en la suscripción de este cliente.`;
}
export function flowLicenseReason(data: DemoData, context: Context, flow: string, pattern: string) {
  if (['SAD', 'SOP'].includes(context.role)) return '';
  const tenant = getTenant(data, context.org); if (!tenant) return '';
  const number = Number(flow.slice(1));
  const feature: ModuleId | undefined = number === 24 ? 'DENTAL' : number >= 30 && number <= 34 ? 'DIAGNOSTICS' : [36, 37].includes(number) ? 'PHARMACY' : number >= 43 && number <= 46 ? 'FINANCE' : [47, 48].includes(number) ? 'INVENTORY' : [49, 50, 51, 55].includes(number) ? 'HOSPITAL' : [52, 53, 54].includes(number) ? 'SURGERY' : [56, 57, 58, 59].includes(number) ? 'ADVANCED' : [14, 60].includes(number) ? 'VET_POPULATION' : number === 65 ? 'REPORTS' : undefined;
  if (feature && !tenant.subscription.modules.includes(feature)) return 'Este proceso requiere un módulo que no está incluido en el plan del cliente.';
  if (['Suspendido', 'Cancelado'].includes(tenant.status) && !['DETAIL_SHEET_RIGHT', 'NAV_ROUTE', 'SELECT_CONTROL', 'FILTER_INLINE', 'GRAPH_CONTROL', 'EXPORT_LOCAL', 'PRINT_CLIENT', 'CLOSE_OR_RETURN', 'UNDO_LOCAL'].includes(pattern) && !['F03', 'F66', 'F70', 'F79'].includes(flow)) return 'Este cliente está suspendido. Puedes consultar su información y gestionar la suscripción.';
  return '';
}
const id = (prefix: string) => `${prefix}-${crypto.randomUUID().slice(0, 8)}`;
const str = (v: SaasValues, key: string) => String(v[key] ?? '').trim();
const list = (v: SaasValues, key: string) => [...new Set(Array.isArray(v[key]) ? v[key] as string[] : [])];
function required(v: SaasValues, key: string, label: string) { const value = str(v, key); if (!value) throw new Error(`Completa ${label}.`); return value; }
function integer(v: SaasValues, key: string, min = 0) { const n = Number(v[key]); if (!Number.isInteger(n) || n < min) throw new Error('Revisa las capacidades: deben ser números enteros válidos.'); return n; }
function email(value: string) { if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) throw new Error('Introduce un correo válido.'); return value.toLowerCase(); }
function checkedSpecialties(codes: string[], tenant: Pick<Tenant, 'kind' | 'domain'>, quota: number) { if (!codes.length) throw new Error('Activa al menos una especialidad.'); if (codes.length > quota) throw new Error(`El contrato permite ${quota} especialidades activas.`); if (codes.some(code => !compatibleSpecialties(tenant).some(s => s.code === code))) throw new Error('Una especialidad no corresponde al ámbito de este cliente.'); }
function checkSpecialtyModules(codes: string[], modules: ModuleId[]) { if (codes.some(code => code.startsWith('D_') || ['V_DENTAL', 'V_DENTAL_EQUINE'].includes(code)) && !modules.includes('DENTAL')) throw new Error('Las especialidades odontológicas requieren el módulo de odontología en el contrato.'); }
export function subscriptionFromValues(state: SaasState, tenant: Pick<Tenant, 'kind' | 'domain'>, values: SaasValues, used = { branches: 1, professionals: 0, specialties: 1 }) {
  const plan = compatiblePlans(state, tenant).find(p => p.id === values.planId); if (!plan) throw new Error('Selecciona un plan publicado compatible con este cliente.');
  const branches = integer(values, 'branchQuota', plan.rate.includedBranches); const professionals = integer(values, 'professionalQuota', plan.rate.includedProfessionals); const specs = integer(values, 'specialtyQuota', 1);
  if (branches > plan.maxBranches || professionals > plan.maxProfessionals || specs > plan.maxSpecialties) throw new Error('La capacidad solicitada supera el máximo del plan.');
  if (tenant.kind === 'DOCTOR' && professionals !== 1) throw new Error('El plan de profesional independiente corresponde a una identidad clínica.');
  if (branches < used.branches || professionals < used.professionals || specs < used.specialties) throw new Error('No puedes contratar menos sedes, profesionales o especialidades que los que ya están en uso.');
  return newSubscription(plan, values.cycle === 'Anual' ? 'Anual' : 'Mensual', branches, professionals, specs);
}
export function runSaasCommand(input: DemoData, context: Context, command: SaasCommand, values: SaasValues, target: SaasTarget = {}) {
  const data = structuredClone(normalizeSaasData(input)); const state = data.saas!; const tenantId = target.tenantId || context.org;
  const globalOnly = ['tenant.create', 'tenant.status', 'plan.create', 'plan.edit', 'invoice.pay'].includes(command);
  if (globalOnly ? context.role !== 'SAD' : !canManageTenant(data, context, tenantId)) throw new Error(globalOnly ? 'Esta acción corresponde al administrador general del SaaS.' : 'Solo la administración de este cliente puede realizar este cambio.');
  const tenant = state.tenants.find(t => t.id === tenantId); const org = data.organizations.find(o => o.id === tenantId);
  if (!globalOnly && (!tenant || !org)) throw new Error('Selecciona un cliente válido.');
  if (tenant && ['Suspendido', 'Cancelado'].includes(tenant.status) && !['tenant.status', 'tenant.edit', 'subscription.configure', 'invoice.pay', 'plan.create', 'plan.edit'].includes(command)) throw new Error('Reactiva la suscripción antes de modificar los recursos del cliente.');
  let resultId = tenantId;
  if (command.startsWith('plan.')) {
    const existing = command === 'plan.edit' ? state.plans.find(p => p.id === target.planId) : undefined;
    if (command === 'plan.edit' && !existing) throw new Error('No se encuentra el plan.');
    const name = required(values, 'name', 'el nombre del plan');
    if (state.plans.some(p => p.id !== existing?.id && p.name.toLowerCase() === name.toLowerCase())) throw new Error('Ya existe un plan con ese nombre.');
    const kinds = list(values, 'kinds') as TenantKind[]; const domains = list(values, 'domains') as PatientDomain[]; const modules = list(values, 'modules') as ModuleId[];
    if (!kinds.length || kinds.some(kind => !tenantKinds.some(k => k.id === kind)) || !domains.length || domains.some(d => !['HUMAN', 'ANIMAL'].includes(d))) throw new Error('Selecciona tipos de cliente y ámbitos válidos.');
    if (!modules.includes('CORE') || modules.some(m => !saasModules.some(feature => feature.id === m))) throw new Error('El plan debe incluir consulta y agenda.');
    const price = (key: string) => { const amount = Number(values[key]); if (!Number.isFinite(amount) || amount < 0) throw new Error('Los precios deben ser importes válidos.'); return Math.round(amount * 100); };
    const includedBranches = integer(values, 'includedBranches', 1); const includedProfessionals = integer(values, 'includedProfessionals', 1); const includedSpecialties = integer(values, 'includedSpecialties', 1);
    const maxBranches = integer(values, 'maxBranches', includedBranches); const maxProfessionals = integer(values, 'maxProfessionals', includedProfessionals); const maxSpecialties = integer(values, 'maxSpecialties', includedSpecialties); const discount = Number(values.annualDiscount);
    if (!Number.isFinite(discount) || discount < 0 || discount > 60) throw new Error('El descuento anual debe estar entre 0 y 60 %.');
    const version = (existing?.version || 0) + 1; const plan: SaasPlan = { id: existing?.id || id('plan'), name, description: str(values, 'description'), version, status: values.status === 'Borrador' ? 'Borrador' : values.status === 'Archivado' ? 'Archivado' : 'Publicado', kinds, domains, rate: { version, base: price('basePrice'), perBranch: price('branchPrice'), perProfessional: price('professionalPrice'), includedBranches, includedProfessionals, annualDiscount: discount }, maxBranches, maxProfessionals, includedSpecialties, maxSpecialties, modules };
    if (existing) Object.assign(existing, plan); else state.plans.push(plan); resultId = plan.id;
  } else if (command === 'tenant.create') {
    const name = required(values, 'name', 'el nombre del cliente'); const slug = required(values, 'slug', 'el identificador del espacio').toLowerCase();
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) throw new Error('El identificador debe contener letras, números y guiones.');
    if (state.tenants.some(t => t.slug === slug)) throw new Error('Ya existe un cliente con ese identificador.');
    const kind = str(values, 'kind') as TenantKind; const domain = str(values, 'domain') as PatientDomain;
    if (!tenantKinds.some(k => k.id === kind) || !['HUMAN', 'ANIMAL'].includes(domain) || kind === 'VETERINARY' && domain !== 'ANIMAL' || !['VETERINARY', 'DOCTOR'].includes(kind) && domain !== 'HUMAN') throw new Error('Revisa el tipo y ámbito del cliente.');
    const ownerName = required(values, 'ownerName', 'el responsable de la cuenta'); const ownerEmail = email(required(values, 'ownerEmail', 'el correo del responsable'));
    const contract = subscriptionFromValues(state, { kind, domain }, values); const codes = list(values, 'specialties'); checkedSpecialties(codes, { kind, domain }, contract.specialtyQuota); checkSpecialtyModules(codes, contract.modules);
    const tenantId = id('tenant'); const branchId = id('branch');
    const created: Tenant = { id: tenantId, kind, domain, ownerName, ownerEmail, slug, status: 'Prueba', created: SAAS_DATE, specialties: codes, subscription: contract };
    state.tenants.push(created); data.organizations.push({ id: tenantId, name, initials: name.split(' ').slice(0, 2).map(s => s[0]).join('').toUpperCase(), type: kind === 'DOCTOR' ? domain === 'ANIMAL' ? 'Veterinario independiente' : 'Profesional independiente' : domain === 'ANIMAL' ? 'Veterinaria' : kindLabel(kind), branches: [{ id: branchId, name: required(values, 'branchName', 'el nombre de la primera sede'), address: str(values, 'address'), status: 'Activa' }] });
    state.areas.push({ id: id('area'), tenantId, branchId, name: 'Consulta y atención', specialties: [...codes] });
    if (kind === 'DOCTOR') {
      let professional = state.professionals.find(p => p.email === ownerEmail);
      if (professional && professional.domain !== domain) throw new Error('Esta identidad profesional corresponde a otro ámbito.');
      if (!professional) { professional = { id: id('professional'), name: ownerName, email: ownerEmail, domain, credential: str(values, 'credential'), color: domain === 'ANIMAL' ? 'peach' : 'sage', avatar: ownerName.split(' ').slice(0, 2).map(s => s[0]).join('').toUpperCase() }; state.professionals.push(professional); }
      state.memberships.push({ id: id('member'), tenantId, professionalId: professional.id, branchIds: [branchId], specialties: [...codes], status: 'Activo', owner: true });
    }
    resultId = tenantId;
  } else if (command === 'tenant.edit') {
    if (!tenant || !org) throw new Error('Selecciona un cliente.');
    const slug = required(values, 'slug', 'el identificador').toLowerCase(); if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug) || state.tenants.some(t => t.id !== tenantId && t.slug === slug)) throw new Error('El identificador no es válido o ya está ocupado.');
    org.name = required(values, 'name', 'el nombre'); org.initials = org.name.split(' ').slice(0, 2).map(s => s[0]).join('').toUpperCase(); tenant.slug = slug; tenant.ownerName = required(values, 'ownerName', 'el responsable'); tenant.ownerEmail = email(required(values, 'ownerEmail', 'el correo'));
  } else if (command === 'tenant.status') {
    if (!tenant) throw new Error('Selecciona un cliente.'); const status = str(values, 'status'); if (!['Prueba', 'Activo', 'Suspendido', 'Cancelado'].includes(status)) throw new Error('Selecciona un estado válido.');
    tenant.status = status as Tenant['status'];
  } else if (command === 'subscription.configure') {
    tenant!.subscription = subscriptionFromValues(state, tenant!, values, tenantUsage(data, tenantId));
    checkSpecialtyModules(tenant!.specialties, tenant!.subscription.modules);
    state.invoices.unshift({ id: id('invoice'), tenantId, number: `SaaS-DEMO-${String(state.invoices.length + 1).padStart(3, '0')}`, period: values.cycle === 'Anual' ? 'Octubre 2026 — Octubre 2027' : 'Octubre 2026', amount: quote(tenant!.subscription).total, date: SAAS_DATE, status: 'Pendiente' });
  } else if (command === 'specialties.configure') {
    const codes = list(values, 'specialties'); checkedSpecialties(codes, tenant!, tenant!.subscription.specialtyQuota);
    checkSpecialtyModules(codes, tenant!.subscription.modules);
    const used = state.memberships.filter(m => m.tenantId === tenantId && m.status !== 'Inactivo').flatMap(m => m.specialties);
    if (used.some(code => !codes.includes(code))) throw new Error('Retira primero la asignación de los profesionales que utilizan las especialidades que deseas desactivar.');
    tenant!.specialties = codes; state.areas.filter(a => a.tenantId === tenantId).forEach(a => { a.specialties = a.specialties.filter(code => codes.includes(code)); });
  } else if (command.startsWith('branch.')) {
    const branch = org!.branches.find(b => b.id === target.branchId);
    if (command !== 'branch.create' && !branch) throw new Error('Selecciona una sede de este cliente.');
    if (command === 'branch.archive') {
      if (branch!.status !== 'Inactiva' && org!.branches.filter(b => b.status !== 'Inactiva' && !b.external).length === 1 && !branch!.external) throw new Error('El cliente necesita al menos una sede activa.');
      if (branch!.status === 'Inactiva' && !branch!.external && tenantUsage(data, tenantId).branches >= tenant!.subscription.branchQuota) throw new Error('Contrata capacidad para otra sede antes de reactivarla.');
      branch!.status = branch!.status === 'Inactiva' ? 'Activa' : 'Inactiva';
    } else {
      const name = required(values, 'branchName', 'el nombre de la sede'); const external = tenant!.kind === 'DOCTOR' && !!values.external;
      if (external && branch && !branch.external && branch.status !== 'Inactiva' && tenantUsage(data, tenantId).branches <= 1) throw new Error('El cliente necesita al menos una sede propia activa.');
      if (org!.branches.some(b => b.id !== branch?.id && b.name.toLowerCase() === name.toLowerCase())) throw new Error('Ya existe una sede con ese nombre en este cliente.');
      if (!external && (command === 'branch.create' || branch!.external) && tenantUsage(data, tenantId).branches >= tenant!.subscription.branchQuota) throw new Error('Has alcanzado las sedes contratadas. Amplía la capacidad de la suscripción.');
      if (branch) Object.assign(branch, { name, address: str(values, 'address'), external }); else { const branchId = id('branch'); org!.branches.push({ id: branchId, name, address: str(values, 'address'), external, status: 'Activa' }); resultId = branchId; }
    }
  } else if (command.startsWith('member.')) {
    const membership = state.memberships.find(m => m.id === target.memberId && m.tenantId === tenantId);
    if (command !== 'member.create' && !membership) throw new Error('Selecciona un profesional de este cliente.');
    if (command === 'member.status') {
      const status = str(values, 'status'); if (!['Activo', 'Invitado', 'Inactivo'].includes(status)) throw new Error('Selecciona un estado válido.');
      if (membership!.owner && status === 'Inactivo') throw new Error('El profesional propietario necesita conservar su acceso.');
      if (membership!.status === 'Inactivo' && status !== 'Inactivo' && tenantUsage(data, tenantId).professionals >= tenant!.subscription.professionalQuota) throw new Error('No hay licencias clínicas disponibles.');
      membership!.status = status as 'Activo' | 'Invitado' | 'Inactivo';
    } else {
      if (command === 'member.create' && tenantUsage(data, tenantId).professionals >= tenant!.subscription.professionalQuota) throw new Error('Has alcanzado las licencias de profesionales contratadas.');
      const branches = list(values, 'branchIds'); if (!branches.length || branches.some(branchId => !org!.branches.some(b => b.id === branchId && b.status !== 'Inactiva'))) throw new Error('Asigna al menos una sede activa de este cliente.');
      const codes = list(values, 'specialties'); checkedSpecialties(codes, tenant!, tenant!.subscription.specialtyQuota); if (codes.some(code => !tenant!.specialties.includes(code))) throw new Error('Activa primero esas especialidades para el cliente.');
      let professional = state.professionals.find(p => p.id === (membership?.professionalId || values.professionalId));
      if (!professional) {
        const name = required(values, 'professionalName', 'el nombre del profesional'); const mail = email(required(values, 'professionalEmail', 'el correo del profesional'));
        professional = state.professionals.find(p => p.email === mail);
        if (!professional) { professional = { id: id('professional'), name, email: mail, domain: tenant!.domain, credential: str(values, 'credential'), color: tenant!.domain === 'ANIMAL' ? 'peach' : 'sage', avatar: name.split(' ').slice(0, 2).map(s => s[0]).join('').toUpperCase() }; state.professionals.push(professional); }
      }
      if (professional.domain !== tenant!.domain) throw new Error('Este profesional pertenece a otro ámbito clínico.');
      if (!membership && state.memberships.some(m => m.tenantId === tenantId && m.professionalId === professional!.id)) throw new Error('Esta identidad profesional ya tiene una membresía en el cliente. Revisa su estado.');
      if (membership) Object.assign(membership, { specialties: codes, branchIds: branches }); else { const memberId = id('member'); state.memberships.push({ id: memberId, tenantId, professionalId: professional.id, branchIds: branches, specialties: codes, status: values.status === 'Invitado' ? 'Invitado' : 'Activo', owner: false }); resultId = memberId; }
    }
  } else if (command.startsWith('area.')) {
    const branchId = str(values, 'branchId'); if (!org!.branches.some(b => b.id === branchId && b.status !== 'Inactiva')) throw new Error('Selecciona una sede activa de este cliente.');
    const codes = list(values, 'specialties'); if (!codes.length || codes.some(code => !tenant!.specialties.includes(code))) throw new Error('Asigna especialidades activas del cliente.');
    const area = state.areas.find(a => a.id === target.areaId && a.tenantId === tenantId); const fields = { name: required(values, 'areaName', 'el nombre del área'), branchId, specialties: codes };
    if (command === 'area.edit' && !area) throw new Error('Selecciona un área de este cliente.');
    if (area) Object.assign(area, fields); else { const areaId = id('area'); state.areas.push({ id: areaId, tenantId, ...fields }); resultId = areaId; }
  } else if (command === 'invoice.pay') {
    const invoice = state.invoices.find(i => i.id === target.invoiceId && i.tenantId === tenantId); if (!invoice) throw new Error('Selecciona un comprobante SaaS de este cliente.'); if (invoice.status === 'Pagado') return { data: input, targetId: invoice.id, message: 'Este pago demo ya estaba registrado.' }; invoice.status = 'Pagado'; resultId = invoice.id;
  }
  state.events.unshift({ id: id('saas-event'), actor: context.role, tenantId: command.startsWith('plan.') ? undefined : command === 'tenant.create' ? resultId : tenantId, label: commandTitles[command], target: resultId, date: SAAS_DATE });
  return { data, targetId: resultId, message: 'Configuración guardada en la demo.' };
}
