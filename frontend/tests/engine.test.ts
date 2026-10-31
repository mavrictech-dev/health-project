import test from 'node:test';
import assert from 'node:assert/strict';
import { createFixtures, DEMO_DATE } from '../src/mocks/fixtures';
import { runCommand, balance, portalLinked, actionAvailability } from '../src/mocks/engine';
import type { Context } from '../src/lib/types';

const context: Context = { org: 'org-human', branch: 'miraflores', role: 'PRO', patient: 'p-lucia', encounter: 'e-1', specialty: 'H_GENERAL_MEDICINE' };

test('reservar cambia agenda, conserva origen y rechaza solapamientos sin mutar la entrada', () => {
  const data = createFixtures(); const original = JSON.stringify(data);
  assert.throws(() => runCommand(data, context, 'F16_A03', { paciente: 'p-lucia', profesional: 'pro-mateo', fecha: DEMO_DATE, inicioHora: '09:15', finHora: '09:45' }), /ocupado/);
  assert.equal(JSON.stringify(data), original);
  const result = runCommand(data, context, 'F16_A03', { paciente: 'p-lucia', profesional: 'pro-mateo', fecha: DEMO_DATE, inicioHora: '12:00', finHora: '12:30', sucursal: 'san-isidro' });
  assert.equal(result.data.appointments.length, data.appointments.length + 1);
  assert.equal(result.data.appointments.at(-1)?.branch, 'san-isidro');
  assert.equal(result.data.appointments.at(-1)?.time, '12:00');
});

test('una referencia de otra organización no reserva al paciente actual por defecto', () => {
  assert.throws(() => runCommand(createFixtures(), context, 'F16_A03', { paciente: 'p-luna', inicioHora: '12:00', finHora: '12:30' }), /Selecciona un paciente/);
});

test('el portal rechaza un paciente sin vínculo aunque el contexto actual sea válido', () => {
  const data = createFixtures(); const portal = { ...context, role: 'PAC' as const };
  assert.ok(portalLinked(data, portal));
  assert.throws(() => runCommand(data, portal, 'F17_A04', { paciente: 'p-diego', fecha: DEMO_DATE }), /vínculo vigente/);
  assert.doesNotThrow(() => runCommand(data, portal, 'F17_A04', { paciente: 'p-lucia', fecha: DEMO_DATE }));
});

test('firma fija una revisión y la adenda conserva el original', () => {
  const data = createFixtures();
  const signed = runCommand(data, context, 'F27_A02', { confirmacionFirma: true }, { documentId: 'doc-2' });
  assert.ok(signed.data.documents.find(d => d.id === 'doc-2')?.signed);
  assert.throws(() => runCommand(signed.data, context, 'F27_A02', { confirmacionFirma: true }, { documentId: 'doc-2' }), /ya está firmada/);
  const original = structuredClone(signed.data.documents.find(d => d.id === 'doc-2'));
  const addendum = runCommand(signed.data, context, 'F28_A01', { motivo: 'Corrección de ejemplo', correccion: 'Texto corregido ficticio.' }, { documentId: 'doc-2' });
  assert.deepEqual(addendum.data.documents.find(d => d.id === 'doc-2'), original);
  assert.ok(addendum.data.documents.some(d => d.original === 'doc-2' && d.content === 'Texto corregido ficticio.'));
});

test('publicar exige firma y vínculo vigente; revocar oculta lectura futura', () => {
  const data = createFixtures();
  assert.throws(() => runCommand(data, context, 'F40_A03', {}, { documentId: 'doc-2' }), /firma/);
  const published = runCommand(data, context, 'F40_A03', {}, { documentId: 'doc-1' });
  assert.equal(published.data.documents.find(d => d.id === 'doc-1')?.published, true);
  const revoked = runCommand(published.data, { ...context, role: 'ADM' }, 'F39_A05', { motivo: 'Fin de delegación' });
  assert.equal(portalLinked(revoked.data, { ...context, role: 'PAC' }), false);
  assert.ok(actionAvailability('F71_A01', revoked.data, { ...context, role: 'PAC' }).includes('vínculo'));
});

test('referencias documentales de otro tenant se rechazan', () => {
  assert.throws(() => runCommand(createFixtures(), context, 'F27_A02', {}, { documentId: 'doc-v1' }), /otro espacio/);
});

test('un cargo propuesto no cobra; confirmar y pagar calculan saldo en unidades menores', () => {
  const data = createFixtures(); const caj = { ...context, role: 'CAJ' as const };
  const draft = runCommand(data, caj, 'F43_A01', { importe: 49.99, servicio: 'Servicio de ejemplo' });
  assert.equal(balance(draft.data, context.org, context.patient), 6000);
  const charged = runCommand(draft.data, caj, 'F43_A03', {}, { recordId: draft.targetId });
  assert.equal(balance(charged.data, context.org, context.patient), 10999);
  const paid = runCommand(charged.data, caj, 'F44_A02', { importe: 49.99, medioFicticio: 'Efectivo de demostración' });
  assert.equal(balance(paid.data, context.org, context.patient), 6000);
});

test('la misma confirmación no duplica pagos', () => {
  const caj = { ...context, role: 'CAJ' as const }; const target = { operationId: 'payment-once' };
  const first = runCommand(createFixtures(), caj, 'F44_A02', { importe: 60 }, target);
  const second = runCommand(first.data, caj, 'F44_A02', { importe: 60 }, target);
  assert.equal(second.data.movements.length, first.data.movements.length);
  assert.equal(balance(second.data, context.org, context.patient), 0);
});

test('dispensar usa el lote elegido y no permite stock negativo', () => {
  const data = createFixtures(); const pharmacy = { ...context, role: 'FAR' as const };
  const result = runCommand(data, pharmacy, 'F36_A04', { cantidad: 5 }, { stockId: 'stock-2' });
  assert.equal(result.data.stock.find(s => s.id === 'stock-2')?.quantity, 115);
  assert.equal(result.data.stock.find(s => s.id === 'stock-1')?.quantity, 48);
  assert.throws(() => runCommand(data, pharmacy, 'F36_A04', { cantidad: 1000 }, { stockId: 'stock-2' }), /suficientes/);
});

test('transferencia deja stock en tránsito y recepción no lo duplica', () => {
  const data = createFixtures(); const warehouse = { ...context, role: 'ALM' as const };
  const moved = runCommand(data, warehouse, 'F48_A02', { producto: 'stock-1', cantidad: 5, destino: 'San Isidro' });
  assert.equal(moved.data.stock.find(s => s.id === 'stock-1')?.quantity, 43);
  const transfer = moved.data.records.find(r => r.status === 'En tránsito' && r.flow === 'F48')!;
  const received = runCommand(moved.data, warehouse, 'F48_A03', {}, { recordId: transfer.id });
  assert.equal(received.data.stock.find(s => s.warehouse === 'San Isidro')?.quantity, 5);
  assert.throws(() => runCommand(received.data, warehouse, 'F48_A03', {}, { recordId: transfer.id }), /en tránsito/);
});

test('una plaza ocupada no se asigna a otro paciente; egresar la libera', () => {
  const data = createFixtures(); const incoming = { ...context, patient: 'p-diego', encounter: 'e-dental' };
  assert.throws(() => runCommand(data, incoming, 'F49_A04', {}, { bedId: 'bed-1' }), /ocupada/);
  const discharged = runCommand(data, { ...context, role: 'REC' }, 'F55_A05', {}, { bedId: 'bed-1' });
  assert.equal(discharged.data.beds.find(b => b.id === 'bed-1')?.status, 'Disponible');
  assert.equal(discharged.data.beds.find(b => b.id === 'bed-1')?.patient, undefined);
});

test('cerrar atención impide modificar captura histórica directamente', () => {
  const data = runCommand(createFixtures(), context, 'F21_A04').data;
  assert.throws(() => runCommand(data, context, 'F22_A04', { perfil: 'H_GENERAL_MEDICINE' }), /finalizada/);
});

test('importación aplica filas válidas y no vuelve a procesar el mismo lote', () => {
  const admin = { ...context, role: 'ADM' as const };
  const input = { esquema: 'Pacientes', archivo: 'pacientes.csv', hashImport: '1234', filasJson: JSON.stringify([{ nombre: 'Paciente ficticio nuevo', identificacion: 'DEMO-NEW' }, { nombre: '', identificacion: 'BAD' }]) };
  const data = createFixtures(); const result = runCommand(data, admin, 'F64_A04', input);
  assert.equal(result.data.patients.length, data.patients.length + 1);
  assert.equal(result.data.records[0].data.rechazados, 1);
  assert.throws(() => runCommand(result.data, admin, 'F64_A04', input), /ya fue aplicado/);
});

test('un rol sin permiso no cambia dinero ni datos', () => {
  assert.throws(() => runCommand(createFixtures(), context, 'F44_A02', { importe: 150 }), /Caja/);
});

test('órdenes emitidas generan trabajo diagnóstico para el mismo paciente', () => {
  const result = runCommand(createFixtures(), context, 'F30_A03', { servicio: 'Estudio ficticio' });
  assert.ok(result.data.records.some(r => r.flow === 'F31' && r.patient === context.patient && r.title === 'Tarea · Estudio ficticio'));
});

test('el alta heredada dirige al SaaS y las sucursales heredadas respetan el contrato', () => {
  const admin = { ...context, role: 'ADM' as const };
  assert.throws(() => runCommand(createFixtures(), admin, 'F05_A01', { nombre: 'Clínica de ejemplo' }), /Administración SaaS/);
  const added = runCommand(createFixtures(), admin, 'F05_A03', { nombre: 'Sucursal de ejemplo' });
  assert.equal(added.data.organizations.find(o => o.id === admin.org)?.branches.length, 3);
  assert.throws(() => runCommand(added.data, admin, 'F05_A03', { nombre: 'Exceso de cuota' }), /sedes contratadas/);
});

test('guardar evaluaciones conserva respuestas de revisiones previas', () => {
  const first = runCommand(createFixtures(), context, 'F22_A04', { perfil: 'H_CARDIOLOGY', capture_1: 'Dato ficticio inicial' });
  const next = runCommand(first.data, context, 'F22_A04', { perfil: 'H_CARDIOLOGY', capture_1: 'Dato ficticio actualizado' });
  const responses = next.data.records.filter(r => r.flow === 'F22' && r.data.perfil === 'H_CARDIOLOGY');
  assert.equal(responses.length, 2);
  assert.equal(responses[0].revision, 2);
  assert.equal(responses[1].data.capture_1, 'Dato ficticio inicial');
});
