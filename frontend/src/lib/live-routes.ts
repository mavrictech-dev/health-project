/** Navigation hints only. The API remains the authority for every permission. */
export interface LiveUser { id: string; roles: string[]; tenantId?: string | null }
export interface LiveHost { platform: boolean; id?: string }
export const accessPaths = ['/acceso', '/portal/acceso', '/operacion/acceso', '/saas/acceso', '/recuperar', '/registro', '/verificar', '/restablecer', '/invitacion'];
export type LiveView = 'home' | 'clients' | 'organization' | 'trace' | 'monitor' | 'support' | 'account';
export const organizationPath = '/app/configuracion/organizacion';
export function liveBase(user: LiveUser) {
  return user.roles.includes('SAD') ? '/saas' : user.roles.includes('SOP') ? '/operacion' : user.roles.some(r => ['PAC','RES'].includes(r)) ? '/portal' : '/app';
}
export function sessionMatchesHost(user: LiveUser, host: LiveHost) {
  const platformRole = user.roles.some(r => ['SAD','SOP'].includes(r));
  return host.platform ? user.tenantId == null && platformRole : !!host.id && user.tenantId === host.id && !platformRole;
}
export function liveEntries(user: LiveUser) {
  const base = liveBase(user), audit = user.roles.some(r => ['SAD','SOP','ADM','AUD'].includes(r));
  return [
    { path: base+'/inicio', label: 'Mi espacio', view: 'home' as LiveView },
    ...(user.roles.includes('SAD') ? [{ path: '/saas/clientes', label: 'Clientes', view: 'clients' as LiveView }] : []),
    ...(base==='/app'&&!!user.tenantId&&user.roles.includes('ADM') ? [{ path: organizationPath, label: 'Organización y sedes', view: 'organization' as LiveView }] : []),
    ...(audit ? [{ path: base+'/trazabilidad', label: 'Trazabilidad', view: 'trace' as LiveView }, { path: base+'/monitor', label: 'Estado de la aplicación', view: 'monitor' as LiveView }] : []),
    { path: base+'/soporte', label: 'Solicitudes de soporte', view: 'support' as LiveView },
    { path: base+'/cuenta', label: 'Mi cuenta y sesiones', view: 'account' as LiveView },
  ];
}
export function liveRoute(path: string, user: LiveUser, host: LiveHost): { kind: 'allowed'; view: LiveView } | { kind: 'forbidden' | 'unavailable' } {
  path = path.replace(/\/$/, '') || '/';
  if (!sessionMatchesHost(user, host)) return { kind: 'forbidden' };
  if (path === '/') return { kind: 'allowed', view: 'home' };
  const entry = liveEntries(user).find(e => e.path === path);
  if (entry) return { kind: 'allowed', view: entry.view };
  if (path === organizationPath) return { kind: 'forbidden' };
  const base = liveBase(user);
  if (path === base+'/auditoria' && user.roles.some(r => ['SAD','ADM','AUD'].includes(r))) return { kind: 'allowed', view: 'trace' };
  if (!path.startsWith(base+'/')) return { kind: 'forbidden' };
  if (['monitor','trazabilidad','auditoria','clientes'].includes(path.slice(base.length+1))) return { kind: 'forbidden' };
  return { kind: 'unavailable' };
}
