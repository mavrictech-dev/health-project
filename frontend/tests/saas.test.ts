import test from 'node:test';
import assert from 'node:assert/strict';
import { createFixtures } from '../src/mocks/fixtures';
import { actionAvailability, runCommand } from '../src/mocks/engine';
import { getSaas, getTenant, newSubscription, pathLicenseReason, quote, runSaasCommand, tenantProfessionals, tenantUsage } from '../src/lib/saas';
import type { Context } from '../src/lib/types';
import type { SaasPlan, SaasValues } from '../src/lib/saas-types';

const admin: Context = { org: 'org-human', branch: 'miraflores', role: 'SAD', patient: '', encounter: '', specialty: 'H_GENERAL_MEDICINE' };
const customer: Context = { ...admin, role: 'ADM' };
const solo: SaasValues = { name: 'Consultorio de Ana', slug: 'consulta-ana', ownerName: 'Dra. Ana Lima', ownerEmail: 'ana@example.test', kind: 'DOCTOR', domain: 'HUMAN', planId: 'plan-professional', cycle: 'Mensual', branchQuota: 1, professionalQuota: 1, specialtyQuota: 5, specialties: ['H_CARDIOLOGY'], branchName: 'Consultorio', address: 'Dirección de ejemplo' };
const planValues = (plan: SaasPlan): SaasValues => { const { rate, ...fields } = plan; return { ...fields, basePrice: rate.base / 100, branchPrice: rate.perBranch / 100, professionalPrice: rate.perProfessional / 100, annualDiscount: rate.annualDiscount, includedBranches: rate.includedBranches, includedProfessionals: rate.includedProfessionals }; };

test('crear un profesional independiente crea su tenant, contrato, área e identidad sin copiar pacientes', () => {
  const input = createFixtures(); const result = runSaasCommand(input, admin, 'tenant.create', solo);
  const tenant = getTenant(result.data, result.targetId)!; const org = result.data.organizations.find(o => o.id === tenant.id)!;
  assert.equal(tenant.kind, 'DOCTOR'); assert.equal(tenant.status, 'Prueba'); assert.equal(org.branches.length, 1);
  assert.equal(result.data.patients.filter(p => p.org === tenant.id).length, 0);
  assert.deepEqual(tenantUsage(result.data, tenant.id), { branches: 1, professionals: 1, specialties: 1 });
  assert.equal(tenantProfessionals(result.data, tenant.id)[0].email, solo.ownerEmail);
  assert.equal(getSaas(result.data).areas.filter(a => a.tenantId === tenant.id).length, 1);
  assert.equal(getSaas(input).tenants.length, 3);
});

test('slug duplicado y ámbitos incompatibles fallan sin mutar datos ni crear contratos parciales', () => {
  const data = runSaasCommand(createFixtures(), admin, 'tenant.create', solo).data; const before = JSON.stringify(data);
  assert.throws(() => runSaasCommand(data, admin, 'tenant.create', solo), /identificador/);
  assert.throws(() => runSaasCommand(data, admin, 'tenant.create', { ...solo, slug: 'otro', specialties: ['V_GENERAL'] }), /ámbito/);
  assert.throws(() => runSaasCommand(data, admin, 'tenant.create', { ...solo, slug: 'otro', kind: 'VETERINARY' }), /ámbito/);
  assert.equal(JSON.stringify(data), before);
});

test('administración de un cliente solo cambia sus recursos; operador técnico no administra el SaaS', () => {
  const data = createFixtures();
  assert.throws(() => runSaasCommand(data, customer, 'branch.create', { branchName: 'Otra sede' }, { tenantId: 'org-vet' }), /administración de este cliente/);
  assert.throws(() => runSaasCommand(data, customer, 'tenant.create', solo), /administrador general/);
  assert.throws(() => runSaasCommand(data, { ...admin, role: 'SOP' }, 'plan.create', {}), /administrador general/);
  assert.doesNotThrow(() => runSaasCommand(data, customer, 'branch.create', { branchName: 'Sede Sur' }));
});

test('las sedes se limitan por contrato y una ampliación válida habilita el recurso', () => {
  const data = createFixtures(); const ctx = { ...customer, org: 'org-vet', branch: 'vet-centro' };
  assert.throws(() => runSaasCommand(data, ctx, 'branch.create', { branchName: 'Sede Este' }), /sedes/);
  const expanded = runSaasCommand(data, ctx, 'subscription.configure', { planId: 'plan-vet', cycle: 'Mensual', branchQuota: 3, professionalQuota: 3, specialtyQuota: 10 }).data;
  const added = runSaasCommand(expanded, ctx, 'branch.create', { branchName: 'Sede Este' });
  assert.equal(tenantUsage(added.data, 'org-vet').branches, 3);
  assert.throws(() => runSaasCommand(added.data, ctx, 'subscription.configure', { planId: 'plan-vet', cycle: 'Mensual', branchQuota: 2, professionalQuota: 3, specialtyQuota: 10 }), /consumo|utiliza|uso/);
});

test('lugares externos del independiente no consumen sede; el plan conserva una identidad clínica', () => {
  const data = createFixtures(); const ctx = { ...customer, org: 'org-own', branch: 'consultorio' };
  const result = runSaasCommand(data, ctx, 'branch.create', { branchName: 'Atención en Clínica Norte', external: true });
  assert.equal(tenantUsage(result.data, 'org-own').branches, 1);
  assert.throws(() => runSaasCommand(result.data, ctx, 'branch.edit', { branchName: 'Consultorio externo', external: true }, { branchId: 'consultorio' }), /sede propia activa/);
  assert.throws(() => runSaasCommand(result.data, ctx, 'member.create', { professionalId: 'pro-valeria', branchIds: ['consultorio'], specialties: ['H_GENERAL_MEDICINE'] }), /licencias/);
  assert.throws(() => runSaasCommand(result.data, ctx, 'subscription.configure', { planId: 'plan-professional', cycle: 'Mensual', branchQuota: 1, professionalQuota: 2, specialtyQuota: 5 }), /profesional|plan/);
});

test('una identidad puede trabajar en varios tenants con asignaciones propias y una licencia por cliente', () => {
  const created = runSaasCommand(createFixtures(), admin, 'tenant.create', { ...solo, kind: 'SPECIALTY_CENTER', planId: 'plan-center', professionalQuota: 5, specialtyQuota: 10 });
  const branch = created.data.organizations.find(o => o.id === created.targetId)!.branches[0].id;
  const result = runSaasCommand(created.data, admin, 'member.create', { professionalId: 'pro-andres', branchIds: [branch], specialties: ['H_CARDIOLOGY'], status: 'Activo' }, { tenantId: created.targetId });
  assert.equal(getSaas(result.data).professionals.filter(p => p.id === 'pro-andres').length, 1);
  assert.equal(getSaas(result.data).memberships.filter(m => m.professionalId === 'pro-andres').length, 2);
  assert.equal(tenantProfessionals(result.data, created.targetId, branch)[0].id, 'pro-andres');
  assert.equal(tenantUsage(result.data, created.targetId).professionals, 1);
  assert.throws(() => runSaasCommand(result.data, admin, 'member.create', { professionalId: 'pro-andres', branchIds: [branch], specialties: ['H_CARDIOLOGY'] }, { tenantId: created.targetId }), /ya tiene una membresía/);
  assert.throws(() => runSaasCommand(result.data, admin, 'member.edit', { branchIds: ['miraflores'], specialties: ['H_CARDIOLOGY'] }, { tenantId: created.targetId, memberId: result.targetId }), /sede activa/);
});

test('invitaciones reservan licencia y un miembro inactivo no aparece en agenda', () => {
  const data = createFixtures(); const result = runSaasCommand(data, customer, 'member.status', { status: 'Invitado' }, { memberId: 'member-org-human-pro-andres' });
  assert.equal(tenantUsage(result.data, 'org-human').professionals, 3);
  assert.ok(!tenantProfessionals(result.data, 'org-human').some(p => p.id === 'pro-andres'));
  const inactive = runSaasCommand(result.data, customer, 'member.status', { status: 'Inactivo' }, { memberId: 'member-org-human-pro-andres' });
  assert.equal(tenantUsage(inactive.data, 'org-human').professionals, 2);
});

test('áreas y membresías solo asignan especialidades activadas y sedes del tenant', () => {
  const data = createFixtures();
  assert.throws(() => runSaasCommand(data, customer, 'area.create', { areaName: 'Veterinaria', branchId: 'miraflores', specialties: ['V_GENERAL'] }), /especialidades activas/);
  assert.throws(() => runSaasCommand(data, customer, 'area.create', { areaName: 'Cardiología', branchId: 'vet-centro', specialties: ['H_CARDIOLOGY'] }), /sede activa/);
  assert.throws(() => runSaasCommand(data, customer, 'specialties.configure', { specialties: ['H_GENERAL_MEDICINE'] }), /asignación/);
  assert.throws(() => runSaasCommand(data, customer, 'member.create', { professionalId: 'pro-camila', branchIds: ['miraflores'], specialties: ['H_CARDIOLOGY'] }), /ámbito/);
});

test('editar el catálogo versiona precios y módulos sin modificar contratos aceptados', () => {
  const data = createFixtures(); const plan = getSaas(data).plans.find(p => p.id === 'plan-hospital')!; const contract = structuredClone(getTenant(data, 'org-human')!.subscription);
  const result = runSaasCommand(data, admin, 'plan.edit', { ...planValues(plan), basePrice: 1200, modules: ['CORE', 'PORTAL'] }, { planId: plan.id });
  assert.equal(getSaas(result.data).plans.find(p => p.id === plan.id)!.version, 2);
  assert.deepEqual(getTenant(result.data, 'org-human')!.subscription, contract);
  assert.equal(quote(getTenant(result.data, 'org-human')!.subscription).total, quote(contract).total);
});

test('el precio suma capacidad adicional y calcula facturación anual en unidades menores', () => {
  const plan = getSaas(createFixtures()).plans.find(p => p.id === 'plan-vet')!;
  const quoteMonth = quote(newSubscription(plan, 'Mensual', 3, 5));
  assert.equal(quoteMonth.monthly, 24900 + 2 * 9900 + 2 * 3900);
  assert.equal(quote(newSubscription(plan, 'Anual', 3, 5)).total, Math.round(quoteMonth.monthly * 12 * .85));
});

test('módulos ausentes bloquean rutas y comandos; suspender conserva historias y bloquea registros', () => {
  const data = createFixtures(); const ctx: Context = { ...customer, role: 'PRO', org: 'org-own', branch: 'consultorio', patient: 'p-lucia-other' };
  assert.match(pathLicenseReason(data, ctx, '/app/hospital/admisiones'), /suscripción/);
  assert.match(actionAvailability('F49_A01', data, ctx), /módulo/);
  const core = structuredClone(data); getTenant(core, 'org-own')!.subscription.modules = ['CORE'];
  assert.throws(() => runSaasCommand(core, { ...ctx, role: 'ADM' }, 'specialties.configure', { specialties: ['H_GENERAL_MEDICINE', 'H_PEDIATRICS', 'D_ODONTOLOGIA_GENERAL'] }), /módulo de odontología/);
  const suspended = runSaasCommand(data, admin, 'tenant.status', { status: 'Suspendido' }, { tenantId: 'org-human' }).data;
  assert.deepEqual(suspended.patients, data.patients);
  assert.throws(() => runCommand(suspended, { ...customer, role: 'PRO', patient: 'p-lucia', encounter: 'e-1' }, 'F21_A02', { resumen: 'No guardar' }), /suspendido/);
});

test('un pago SaaS se registra una sola vez y no altera la caja clínica', () => {
  const input = createFixtures(); const paid = runSaasCommand(input, admin, 'invoice.pay', {}, { tenantId: 'org-vet', invoiceId: 'invoice-org-vet' });
  const repeated = runSaasCommand(paid.data, admin, 'invoice.pay', {}, { tenantId: 'org-vet', invoiceId: 'invoice-org-vet' });
  assert.deepEqual(paid.data.movements, input.movements); assert.equal(repeated.data.saas!.events.length, paid.data.saas!.events.length);
  assert.equal(repeated.data.saas!.invoices.find(i => i.id === 'invoice-org-vet')!.status, 'Pagado');
});

test('reservar rechaza profesionales sin membresía activa o sin especialidad asignada en el tenant', () => {
  const data = createFixtures(); const ctx = { ...customer, role: 'PRO' as const, patient: 'p-lucia' };
  assert.throws(() => runCommand(data, ctx, 'F16_A03', { paciente: 'p-lucia', profesional: 'pro-camila', inicioHora: '12:00' }), /membresía activa/);
  assert.throws(() => runCommand(data, ctx, 'F16_A03', { paciente: 'p-lucia', profesional: 'pro-andres', especialidad: 'H_PEDIATRICS', inicioHora: '12:00' }), /especialidad/);
});
