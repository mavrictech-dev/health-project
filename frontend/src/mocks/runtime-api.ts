import { useDemo } from '@/store/demo';
import { actors, specialties } from '@/lib/spec';
import { getSaas, getTenant } from '@/lib/saas';

type Row = Record<string, unknown>;
interface Ticket extends Row { id: string; tenantId: string | null; reference: string; email: string; subject: string; message: string; status: string; priority: string; revision: number; createdAt: string; updatedAt: string; comments: Row[]; }
interface TraceEvent extends Row { id: number; requestId: string; tenantId: string | null; action: string; targetId: string; actorName: string; createdAt: string; resourceType: string; }
interface ReviewState {
  version: 1;
  application: { mode: string; message: string; revision: number };
  tickets: Ticket[]; events: TraceEvent[]; requests: Row[]; sequence: number;
  sessions: Row[]; signedOut: boolean;
  mail: { id: string; subject: string; email: string; href: string; used: boolean; purpose: string }[];
}
const KEY = 'health-project-review-v1';
let memory: ReviewState | undefined;
const now = () => new Date().toISOString();
const id = (prefix: string) => `${prefix}-${crypto.randomUUID()}`;
function fail(message: string, status = 400): never { throw Object.assign(new Error(message), { status }); }

export function mockUser() {
  const { context } = useDemo.getState();
  return { id: `demo-${context.role}`, name: actors.find(a => a.id === context.role)?.name || 'Revisor de presentación', email: `${context.role.toLowerCase()}@example.test`, roles: [context.role], tenantId: ['SAD', 'SOP'].includes(context.role) ? null : context.org };
}
function host() {
  const { context, data } = useDemo.getState(), platform = ['SAD', 'SOP'].includes(context.role);
  const tenant = getTenant(data, context.org), organization = data.organizations.find(o => o.id === context.org);
  return { platform, id: platform ? undefined : context.org, name: platform ? 'Health Project SaaS' : organization?.name, slug: tenant?.slug, kind: tenant?.kind, domain: tenant?.domain, baseDomain: 'health.demo', hostname: platform ? 'health.demo' : `${tenant?.slug || 'clinica'}.health.demo` };
}
function seed(): ReviewState {
  const createdAt = now();
  const tickets: Ticket[] = [{ id: 'demo-ticket-1', tenantId: 'org-human', reference: 'MVT-DEMO-001', email: 'administracion@example.test', subject: 'Configurar una nueva sede', message: 'Necesitamos revisar los permisos y la agenda de la nueva sede. Solicitud ficticia para la presentación.', status: 'IN_PROGRESS', priority: 'NORMAL', revision: 2, createdAt, updatedAt: createdAt, comments: [{ id: 'demo-comment-1', actorName: 'Mavric Technologies · Soporte demo', createdAt, message: 'Estamos revisando la capacidad del plan y la asignación del equipo.' }] }];
  return {
    version: 1, application: { mode: 'OPEN', message: 'Todos los servicios disponibles · simulación', revision: 1 }, tickets, events: [], requests: [], sequence: 0,
    sessions: [
      { id: 'demo-current', current: true, revoked: false, sourceIp: 'Navegador de la presentación', userAgent: 'Esta sesión de demostración', lastSeenAt: createdAt, expiresAt: new Date(Date.now() + 86400000).toISOString() },
      { id: 'demo-tablet', current: false, revoked: false, sourceIp: 'Dispositivo ficticio', userAgent: 'Tablet de recepción · ejemplo', lastSeenAt: createdAt, expiresAt: new Date(Date.now() + 86400000).toISOString() },
    ], signedOut: false, mail: [],
  };
}
function state() {
  if (memory) return memory;
  try { const saved = JSON.parse(localStorage.getItem(KEY) || 'null'); if (saved?.version === 1) memory = saved as ReviewState; } catch { /* Browser storage is optional for presenting. */ }
  if (!memory) {
    memory = seed();
    record('support_tickets', 'demo-ticket-1', 'support.update', { status: 'OPEN', revision: 1 }, { status: 'IN_PROGRESS', revision: 2 }, '/api/support/demo-ticket-1/steps', 'POST', 'org-human');
    const failed = { id: 'demo-rejected-request', tenantId: 'org-human', actorName: 'Sin sesión · ejemplo', method: 'POST', route: '/api/auth/browser/login', status: 401, durationMs: 24, sourceIp: 'Origen ficticio', userAgent: 'Navegador de demostración', createdAt: now() };
    memory.requests.unshift(failed);
    save();
  }
  return memory;
}
function save() {
  try { localStorage.setItem(KEY, JSON.stringify(memory)); } catch { /* Keep this session usable when storage is blocked/full. */ }
  if (typeof window !== 'undefined') window.dispatchEvent(new Event('health:demo-updated'));
}
export function activateMockSession() {
  const value = state(); value.signedOut = false;
  value.sessions.forEach(session => { session.revoked = false; }); save();
}
export function resetMockRuntime() { memory = undefined; try { localStorage.removeItem(KEY); } catch { /* optional */ } state(); save(); }
function scoped(row: Row) { return ['SAD', 'SOP'].includes(useDemo.getState().context.role) || row.tenantId === useDemo.getState().context.org; }
function record(resource: string, targetId: string, action: string, beforeState: unknown, afterState: unknown, route: string, method = 'PUT', tenantId: string | null = mockUser().tenantId) {
  const value = memory || state(), user = mockUser(), requestId = id('demo-request'), createdAt = now();
  const common = { requestId, tenantId, actorName: user.name, actorEmail: user.email, actorRoles: user.roles, createdAt, sourceIp: 'Navegador · simulación local', userAgent: 'Health Project · modo presentación', targetId, resourceType: resource };
  value.events.unshift(
    { ...common, id: ++value.sequence, action: `${action}.requested`, metadata: { simulation: true, step: 'Revisión de datos y permisos' } },
    { ...common, id: ++value.sequence, action, beforeState, afterState, metadata: { simulation: true, step: 'Cambio guardado en este navegador' } },
    { ...common, id: ++value.sequence, action: `${action}.completed`, metadata: { simulation: true, step: 'Recorrido completado' } },
  );
  value.events.sort((a, b) => b.id - a.id);
  value.requests.unshift({ id: requestId, tenantId, actorName: user.name, actorEmail: user.email, method, route, status: method === 'POST' ? 201 : 200, durationMs: 12, sourceIp: common.sourceIp, userAgent: common.userAgent, createdAt });
  value.events = value.events.slice(0, 600); value.requests = value.requests.slice(0, 200); save();
}

// Reuse the clinical/SaaS command engines. Their changes appear in the same review trail.
useDemo.subscribe((next, previous) => {
  if (next.data === previous.data || !memory) return;
  for (const event of next.data.events.filter(event => !previous.data.events.some(old => old.id === event.id))) {
    record('clinical_workflow', event.target || event.id, event.operation, undefined, { label: event.label, branch: event.branch, actor: event.actor }, `/demo/processes/${event.operation}`, 'POST', event.org);
  }
  const current = getSaas(next.data), prior = getSaas(previous.data);
  for (const event of current.events.filter(event => !prior.events.some(old => old.id === event.id))) {
    const after = current.tenants.find(t => t.id === event.tenantId), before = prior.tenants.find(t => t.id === event.tenantId);
    record(after ? 'tenants' : 'plans', event.target, event.label, before, after || { label: event.label, target: event.target }, '/demo/saas/commands', 'POST', event.tenantId || null);
  }
});

export async function mockApi(path: string, options: { method?: string; body?: unknown } = {}): Promise<unknown> {
  const url = new URL(path, 'https://demo.invalid'), route = url.pathname, params = url.searchParams, method = options.method || 'GET', body = (options.body || {}) as Row;
  const value = state();
  if (route === '/public/context' && method === 'GET') return host();
  if (route === '/public/status' && method === 'GET') return { ...value.application, status: value.application.mode === 'OPEN' ? 'OPERATIONAL' : 'RESTRICTED' };
  if (route === '/auth/browser/session' && method === 'GET') {
    if (value.signedOut) fail('Sesión de demostración cerrada. Puedes volver a entrar con datos ficticios.', 401);
    return { user: mockUser(), csrfToken: 'demo-no-server', expiresAt: new Date(Date.now() + 86400000).toISOString() };
  }
  if (route === '/auth/browser/login' && method === 'POST') {
    if (!body.email || !body.password) fail('Completa el correo ficticio y la contraseña de ejemplo.');
    activateMockSession(); record('users', mockUser().id, 'login.simulated', undefined, { outcome: 'Simulación de acceso completada' }, '/api/auth/browser/login', 'POST');
    return { user: mockUser(), csrfToken: 'demo-no-server', expiresAt: new Date(Date.now() + 86400000).toISOString() };
  }
  if (route === '/auth/browser/session' && method === 'DELETE') { value.signedOut = true; value.sessions[0].revoked = true; save(); return {}; }
  if (route === '/auth/sessions' && method === 'GET') return value.sessions;
  if (route.startsWith('/auth/sessions/') && method === 'DELETE') {
    const session = value.sessions.find(row => row.id === route.split('/').at(-1)); if (!session) fail('Sesión no encontrada.', 404);
    session.revoked = true; if (session.current) value.signedOut = true;
    record('users', mockUser().id, 'session.revoke.simulated', { revoked: false }, { revoked: true }, '/api' + route, method); return {};
  }
  if (route === '/auth/password' && method === 'PUT') {
    if (String(body.newPassword || '').length < 12) fail('Usa al menos 12 caracteres en la contraseña de ejemplo.');
    value.sessions.forEach(row => { row.revoked = true; }); value.signedOut = true;
    record('users', mockUser().id, 'password.change.simulated', undefined, { sessionsRevoked: true }, '/api/auth/password'); return {};
  }
  if (route === '/public/registration' && method === 'GET') return {
    plans: getSaas(useDemo.getState().data).plans.filter(plan => plan.status === 'Publicado').map(plan => ({ ...plan, baseMinor: plan.rate.base })),
    specialties: specialties.map(specialty => ({ code: specialty.code, name: specialty.name, domain: specialty.patientDomain, dental: specialty.code.startsWith('D_') })),
  };
  if (route === '/auth/register' && method === 'POST') {
    if (!body.acceptTerms || String(body.password || '').length < 12) fail('Revisa la confirmación y usa al menos 12 caracteres ficticios.');
    if (host().platform) {
      const store = useDemo.getState(), plan = getSaas(store.data).plans.find(plan => plan.id === body.planId);
      if (!plan) fail('Selecciona un plan compatible.');
      await store.executeSaas('tenant.create', { name: String(body.organizationName || ''), slug: String(body.slug || ''), ownerName: String(body.name || ''), ownerEmail: String(body.email || ''), kind: String(body.kind), domain: String(body.domain), planId: plan.id, cycle: 'Mensual', branchQuota: plan.rate.includedBranches, professionalQuota: plan.rate.includedProfessionals, specialtyQuota: Math.max(plan.includedSpecialties, 1), specialties: [String(body.specialtyCode)], branchName: 'Sede principal' });
    }
    value.mail.unshift({ id: id('demo-mail'), email: String(body.email), subject: 'Confirma tu correo · simulación', href: `/verificar/#token=${id('demo-verify')}`, purpose: 'verify', used: false }); save();
    return { message: 'Cuenta de ejemplo preparada. Abre el mensaje simulado que aparece debajo para completar la verificación.' };
  }
  if (['/auth/recovery/request', '/auth/verify/request'].includes(route) && method === 'POST') {
    const verify = route.includes('/verify/'), purpose = verify ? 'verify' : 'recovery';
    value.mail.unshift({ id: id('demo-mail'), email: String(body.email), subject: verify ? 'Confirma tu correo · simulación' : 'Recuperar acceso · simulación', href: `${verify ? '/verificar/' : '/restablecer/'}#token=${id('demo-' + purpose)}`, purpose, used: false }); save();
    return { message: 'Mensaje simulado preparado. Puedes abrir el enlace debajo; no se envía ningún correo real.' };
  }
  if (['/auth/recovery/complete', '/auth/verify/complete'].includes(route) && method === 'POST') {
    const purpose = route.includes('/verify/') ? 'verify' : 'recovery', mail = value.mail.find(mail => mail.href.endsWith(`#token=${String(body.token)}`) && mail.purpose === purpose && !mail.used);
    if (!mail) fail('El enlace de ejemplo ya fue usado o no es válido. Solicita uno nuevo.');
    if (purpose === 'recovery' && String(body.password || '').length < 12) fail('Usa al menos 12 caracteres.');
    mail.used = true; record('users', mockUser().id, `${purpose}.complete.simulated`, undefined, { verified: true }, '/api' + route, method);
    return { message: purpose === 'verify' ? 'Correo confirmado en la demostración. Ya puedes simular el acceso.' : 'Recuperación completada en la demostración. No se ha guardado ninguna contraseña real.' };
  }
  if (route === '/auth/invitations/accept' && method === 'POST') return { message: 'Invitación ficticia aceptada.' };
  if (route === '/demo/mail' && method === 'GET') return value.mail.slice(0, 6);
  if (route === '/public/support' && method === 'POST') {
    if (!body.email || !body.subject || !body.message) fail('Completa el correo, asunto y descripción.');
    const ticket: Ticket = { id: id('demo-ticket'), tenantId: mockUser().tenantId, reference: `MVT-DEMO-${crypto.randomUUID().slice(0, 8).toUpperCase()}`, email: String(body.email), subject: String(body.subject), message: String(body.message), status: 'OPEN', priority: String(body.priority || 'NORMAL'), revision: 1, createdAt: now(), updatedAt: now(), comments: [] };
    value.tickets.unshift(ticket); record('support_tickets', ticket.id, 'support.create', undefined, { reference: ticket.reference, subject: ticket.subject, status: ticket.status }, '/api/public/support', method); return { reference: ticket.reference, status: ticket.status };
  }
  if (route === '/support' && method === 'GET') return value.tickets.filter(scoped);
  if (route.startsWith('/support/')) {
    const ticket = value.tickets.find(row => row.id === route.split('/')[2] && scoped(row)); if (!ticket) fail('Solicitud no encontrada.', 404);
    if (method === 'GET' && route.split('/').length === 3) return ticket;
    if (method === 'POST' && route.endsWith('/steps')) {
      if (ticket.revision !== Number(body.expectedRevision)) fail('La solicitud cambió. Actualiza antes de responder.', 409);
      const before = { status: ticket.status, priority: ticket.priority, revision: ticket.revision };
      if (host().platform) { ticket.status = String(body.status); ticket.priority = String(body.priority); }
      if (body.message) ticket.comments.push({ id: id('demo-comment'), actorName: mockUser().name, createdAt: now(), message: String(body.message) });
      ticket.revision++; ticket.updatedAt = now(); record('support_tickets', ticket.id, 'support.update', before, { status: ticket.status, priority: ticket.priority, revision: ticket.revision }, '/api' + route, method, ticket.tenantId); return ticket;
    }
  }
  if (route === '/trace/events' && method === 'GET') {
    const query = (params.get('query') || '').toLowerCase(), before = Number(params.get('before') || 0), limit = Math.min(200, Math.max(1, Number(params.get('limit') || 50)));
    const rows = value.events.filter(scoped).filter(row => (!query || `${row.action} ${row.actorName} ${row.targetId} ${row.requestId}`.toLowerCase().includes(query)) && (!params.get('resource') || row.resourceType === params.get('resource')) && (!params.get('actor') || row.actorName.toLowerCase().includes(params.get('actor')!.toLowerCase())) && (!before || row.id < before) && (!params.get('from') || row.createdAt >= params.get('from')!) && (!params.get('to') || row.createdAt < params.get('to')!));
    const items = rows.slice(0, limit); return { items, hasMore: rows.length > limit, nextCursor: items.at(-1)?.id || 0 };
  }
  if (route === '/trace/requests' && method === 'GET') return value.requests.filter(scoped).filter(row => (!Number(params.get('status')) || Number(row.status) >= Number(params.get('status'))) && (!params.get('query') || `${row.route} ${row.id}`.toLowerCase().includes(params.get('query')!.toLowerCase()))).slice(0, Number(params.get('limit') || 100));
  if (route.startsWith('/trace/requests/') && method === 'GET') {
    const request = value.requests.find(row => row.id === route.split('/').at(-1) && scoped(row)); if (!request) fail('Recorrido no encontrado.', 404);
    return { ...request, steps: value.events.filter(row => row.requestId === request.id) };
  }
  if (route === '/monitor/mode' && method === 'PUT') {
    if (!mockUser().roles.includes('SAD')) fail('Esta acción corresponde a la administración SaaS.', 403);
    if (value.application.revision !== Number(body.expectedRevision)) fail('El estado cambió. Actualiza la vista.', 409);
    if (!['OPEN', 'READ_ONLY', 'MAINTENANCE'].includes(String(body.mode)) || !String(body.message || '').trim()) fail('Selecciona un estado y un motivo.');
    const before = { ...value.application }; value.application = { mode: String(body.mode), message: String(body.message), revision: before.revision + 1 };
    record('application_state', 'demo-platform', 'application.mode.change', before, value.application, '/api/monitor/mode'); return value.application;
  }
  if (route === '/monitor' && method === 'GET') return {
    application: value.application, version: 'demo', instanceId: 'review-browser', uptimeMs: 12780000, database: { status: 'UP · demo', latencyMs: 4 },
    samples: Array.from({ length: 32 }, (_, i) => ({ id: `sample-${i}`, createdAt: new Date(Date.now() - i * 15000).toISOString(), dbLatencyMs: 3 + (i * 7 % 13), memoryUsed: 186646528, memoryMax: 536870912 })),
    requests: [{ statusGroup: 200, total: 1248 + value.requests.filter(r => Number(r.status) < 400).length, averageMs: 18 }, { statusGroup: 400, total: 12, averageMs: 9 }],
    mail: [{ status: 'SENT', total: value.mail.length }, { status: 'FAILED', total: 0 }],
    migrations: [{ version: 'demo', description: 'Ejemplo visual · sin base de datos conectada', installedOn: now(), success: true }],
  };
  // Missing mocks must fail here: presentation mode never falls back to the real API.
  fail('Este recorrido de API aún no tiene una simulación preparada.', 404);
}
