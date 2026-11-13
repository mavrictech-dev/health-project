'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';
import { Activity, Building2, Globe2, ShieldCheck, Bell, CalendarDays, ChevronDown, ChevronLeft, ChevronRight, CircleHelp, ClipboardList, CreditCard, FlaskConical, HeartPulse, Home, Hospital, Layers3, Menu, Moon, MoreHorizontal, Package, PawPrint, Search, Settings2, Sparkles, Stethoscope, Sun, Users, Workflow, type LucideIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useDemo } from '@/store/demo';
import { getOrganizations } from '@/mocks/fixtures';
import { getSaas, getTenant, pathLicenseReason } from '@/lib/saas';
import { actors } from '@/lib/spec';
import { isMockMode } from '@/lib/app-mode';

interface NavEntry { label: string; icon: LucideIcon; path: string; children?: [string, string][]; }
const nav: { title: string; items: NavEntry[] }[] = [
  { title: 'MI ESPACIO', items: [
    { label: 'Inicio', icon: Home, path: '/app/inicio' },
    { label: 'Agenda', icon: CalendarDays, path: '/app/agenda', children: [['Calendario', '/app/agenda'], ['Solicitudes y espera', '/app/agenda/solicitudes'], ['Disponibilidad', '/app/configuracion/agenda']] },
    { label: 'Recepción', icon: ClipboardList, path: '/app/recepcion' },
    { label: 'Pacientes', icon: Users, path: '/app/pacientes', children: [['Directorio', '/app/pacientes'], ['Duplicados', '/app/pacientes/duplicados']] },
    { label: 'Atención clínica', icon: Stethoscope, path: '/app/atencion' },
    { label: 'Consulta médica', icon: ClipboardList, path: '/app/consulta' },
  ] },
  { title: 'GESTIÓN CLÍNICA', items: [
    { label: 'Órdenes y resultados', icon: ClipboardList, path: '/app/ordenes' },
    { label: 'Documentos', icon: Layers3, path: '/app/documentos' },
    { label: 'Seguimiento', icon: HeartPulse, path: '/app/seguimiento' },
    { label: 'Diagnóstico', icon: FlaskConical, path: '/app/diagnostico/trabajo', children: [['Lista de trabajo', '/app/diagnostico/trabajo'], ['Muestras', '/app/diagnostico/muestras'], ['Laboratorio', '/app/diagnostico/laboratorio'], ['Imágenes', '/app/diagnostico/imagenes']] },
    { label: 'Farmacia', icon: Package, path: '/app/farmacia' },
    { label: 'Hospital', icon: Hospital, path: '/app/hospital/admisiones', children: [['Admisiones', '/app/hospital/admisiones'], ['Camas y jaulas', '/app/hospital/recursos'], ['Estancias y turnos', '/app/hospital/estancias'], ['Medicación', '/app/hospital/medicacion'], ['Urgencias', '/app/urgencias'], ['Cirugía', '/app/cirugia'], ['Anestesia', '/app/anestesia']] },
    { label: 'Especialidades', icon: Activity, path: '/app/especialidades', children: [['Sesiones especializadas', '/app/especialidades?proceso=sesiones'], ['Transfusión', '/app/especialidades?proceso=transfusion'], ['Trasplante', '/app/especialidades?proceso=trasplante'], ['Reproducción', '/app/especialidades?proceso=reproduccion']] },
    { label: 'Veterinaria', icon: PawPrint, path: '/app/veterinaria/poblaciones', children: [['Poblaciones', '/app/veterinaria/poblaciones'], ['Programas sanitarios', '/app/veterinaria/programas']] },
  ] },
  { title: 'ORGANIZACIÓN', items: [
    { label: 'Tarifario y convenios', icon: CreditCard, path: '/app/tarifario' },
    { label: 'Finanzas', icon: CreditCard, path: '/app/finanzas/caja', children: [['Caja y cuentas', '/app/finanzas/caja'], ['Presupuestos', '/app/finanzas/presupuestos'], ['Comprobantes', '/app/finanzas/comprobantes'], ['Honorarios', '/app/finanzas/honorarios']] },
    { label: 'Almacén', icon: Package, path: '/app/inventario', children: [['Inventario y lotes', '/app/inventario'], ['Compras', '/app/compras']] },
    { label: 'Reportes', icon: Activity, path: '/app/reportes' },
    { label: 'Configuración', icon: Settings2, path: '/app/configuracion/organizacion', children: [['Organización', '/app/configuracion/organizacion'], ['Sedes y áreas', '/app/configuracion/sedes'], ['Equipo y permisos', '/app/configuracion/equipo'], ['Servicios y precios', '/app/configuracion/servicios'], ['Catálogo de especialidades', '/app/configuracion/especialidades'], ['Integraciones', '/app/configuracion/integraciones'], ['Importar y exportar', '/app/configuracion/datos'], ['Auditoría', '/app/auditoria'], ['Plan y soporte', '/app/plataforma'], ['Mi cuenta', '/app/cuenta']] },
  ] },
];
const portalItems: NavEntry[] = [
  { label: 'Mi inicio', icon: Home, path: '/portal/inicio' }, { label: 'Mis citas', icon: CalendarDays, path: '/portal/citas' },
  { label: 'Documentos', icon: Layers3, path: '/portal/documentos' }, { label: 'Seguimiento', icon: HeartPulse, path: '/portal/seguimiento' },
  { label: 'Pagos', icon: CreditCard, path: '/portal/pagos' }, { label: 'Vínculos', icon: Users, path: '/portal/vinculos' }, { label: 'Mi cuenta', icon: Settings2, path: '/portal/cuenta' },
];
export function Logo({ small = false }: { small?: boolean }) { return <div className="brand"><span className="brand-mark"><HeartPulse size={22} strokeWidth={1.8} /></span>{!small && <span>health<span className="brand-light">project</span><small>Un espacio para cuidar.</small></span>}</div>; }
export function Navigation({ mobile = false }: { mobile?: boolean }) {
  const pathname = usePathname(); const path = pathname === '/' ? '/' : pathname.replace(/\/$/, '');
  const { data, sidebarCollapsed: collapsed, context, setRole, open, close } = useDemo();
  const router = useRouter();
  const [expanded, setExpanded] = useState<string[]>([]);
  const org = getOrganizations(data).find(o => o.id === context.org)!;
  const isSaas = path.startsWith('/saas'); const tenant = getTenant(data, context.org);
  const isPortal = path.startsWith('/portal'); const isOperations = path.startsWith('/operacion');
  const groups = isSaas ? [{ title: 'PLATAFORMA SAAS', items: [{label:'Resumen',icon:Globe2,path:'/saas/inicio'},{label:'Clientes y tenants',icon:Building2,path:'/saas/clientes'},{label:'Planes',icon:Layers3,path:'/saas/planes'},{label:'Suscripciones',icon:CreditCard,path:'/saas/suscripciones'},{label:'Especialidades globales',icon:Stethoscope,path:'/saas/especialidades'},{label:'Auditoría SaaS',icon:ShieldCheck,path:'/saas/auditoria'}] }] : isPortal ? [{ title: 'MI SALUD', items: portalItems }] : isOperations ? [{ title: 'PLATAFORMA', items: [{ label: 'Operación MAVRIC', icon: Workflow, path: '/operacion/inicio' }, { label: 'Mi cuenta', icon: Settings2, path: '/operacion/cuenta' }] }] : nav.map(group => ({...group, items: group.items.filter(item => !pathLicenseReason(data, context, item.path)).map(item => ({...item, children: item.children?.filter(([,route]) => !pathLicenseReason(data, context, route))}))}));
  if (isMockMode) {
    const base = isSaas ? '/saas' : isPortal ? '/portal' : '/app';
    groups.push({ title: 'OPERACIÓN Y ACCESO', items: [
      ...(!isPortal ? [{ label: 'Trazabilidad', icon: ShieldCheck, path: base + '/trazabilidad' }, { label: 'Estado de la aplicación', icon: Activity, path: base + '/monitor' }] : []),
      { label: 'Solicitudes de soporte', icon: CircleHelp, path: base + '/soporte' },
      { label: 'Cuenta y sesiones', icon: Settings2, path: base + '/cuenta' },
    ] });
  }
  const mini = collapsed && !mobile;
  return <aside className={`sidebar ${mini ? 'collapsed' : ''} ${mobile ? 'mobile-sidebar' : ''}`}>
    <Link className="brand-link" href={isSaas ? '/saas/inicio' : isPortal ? '/portal/inicio' : '/app/inicio'} onClick={mobile ? close : undefined}><Logo small={mini} /></Link>
    {!mini && (isSaas ? <div className="workspace-card saas-global-card"><span className="workspace-initials"><Globe2 size={19}/></span><span><strong>Health Project SaaS</strong><small>Administración general · todos los clientes</small></span></div> : <button className="workspace-card" onClick={() => open({ kind: 'context' })}><span className="workspace-initials">{org.initials}</span><span><strong>{org.name}</strong><small>{org.branches.find(b => b.id === context.branch)?.name} · {getSaas(data).plans.find(p=>p.id===tenant?.subscription.planId)?.name}</small></span><ChevronDown size={15} /></button>)}
    <nav aria-label="Navegación principal" className="nav-scroll">{groups.map(group => <div className="nav-group" key={group.title}>{!mini && <p className="nav-label">{group.title}</p>}{group.items.map(item => {
      const active = path === item.path || (item.path === '/app/inicio' && path === '/') || !!item.children?.some(([, route]) => route.split('?')[0] === path);
      const isExpanded = expanded.includes(item.label);
      return <div key={item.label}><div className={`nav-row ${active ? 'active' : ''}`}><Link href={item.path} title={mini ? item.label : undefined} onClick={mobile ? close : undefined}><item.icon size={18} strokeWidth={1.7} />{!mini && <span>{item.label}</span>}{!mini && item.label === 'Recepción' && <span className="nav-count">{data.appointments.filter(a => a.org === context.org && ['En espera', 'Llamada'].includes(a.status)).length}</span>}</Link>{!mini && item.children && <button aria-label={`Mostrar opciones de ${item.label}`} aria-expanded={isExpanded} onClick={() => setExpanded(items => isExpanded ? items.filter(i => i !== item.label) : [...items, item.label])}><ChevronDown size={13} className={isExpanded ? 'rotated' : ''} /></button>}</div>{item.children && isExpanded && !mini && <div className="nav-children">{item.children.map(([label, route]) => <Link key={label} className={path === route.split('?')[0] ? 'child-active' : ''} href={route} onClick={mobile ? close : undefined}>{label}</Link>)}</div>}</div>;
    })}</div>)}</nav>
    <div className="sidebar-bottom">{!isSaas && <button className="help-link saas-entry" title="Administración SaaS · vista demo" onClick={()=>{setRole('SAD');close();router.push('/saas/inicio');}}><Globe2 size={17}/>{!mini&&<span>Administración SaaS <small>Demo</small></span>}</button>}{!mini && <button className="help-link" onClick={() => open({ kind: 'action', actionId: 'F66_A01' })}><CircleHelp size={17} /><span>Centro de ayuda</span><ChevronRight size={14} /></button>}<button className="demo-switch" onClick={() => open({ kind: 'demo' })}><span className="demo-spark"><Sparkles size={16} /></span>{!mini && <span><strong>Espacio de demostración</strong><small>Datos ficticios · cambiar rol</small></span>}{!mini && <MoreHorizontal size={15} />}</button></div>
  </aside>;
}
export function Header({ title }: { title: string }) {
  const { data, sidebarCollapsed, setCollapsed, context, theme, setTheme, open } = useDemo();
  const org = getOrganizations(data).find(o => o.id === context.org)!; const isSaas = usePathname().startsWith('/saas'); const professional = getSaas(data).professionals.find(p => p.id === context.professional);
  return <header className="app-header"><div className="header-left"><Button variant="ghost" size="icon" className="desktop-toggle" aria-label={sidebarCollapsed ? 'Expandir menú' : 'Colapsar menú'} onClick={() => setCollapsed(!sidebarCollapsed)}>{sidebarCollapsed ? <ChevronRight size={17} /> : <ChevronLeft size={17} />}</Button><Button variant="ghost" size="icon" className="mobile-toggle" aria-label="Abrir navegación" onClick={() => open({ kind: 'mobile-menu' })}><Menu size={19} /></Button><span className="header-breadcrumb">{isSaas ? 'Plataforma SaaS' : 'Mi espacio'} <ChevronRight size={12} /><strong>{title}</strong></span></div><div className="header-right"><button className="global-search" onClick={() => open({ kind: 'search' })}><Search size={16} /><span>Buscar en mi espacio</span><kbd>⌘ K</kbd></button><div className="theme-switch" aria-label="Tema de apariencia">{(['light', 'dark', 'navy'] as const).map(t => <button key={t} aria-label={`Tema ${t === 'light' ? 'blanco' : t === 'dark' ? 'negro' : 'navy'}`} aria-pressed={theme === t} className={theme === t ? 'selected' : ''} onClick={() => setTheme(t)}>{t === 'light' ? <Sun size={15} /> : t === 'dark' ? <Moon size={15} /> : <span className="navy-icon" />}</button>)}</div><button className="notification-button" aria-label="Notificaciones" onClick={() => open({ kind: 'notifications' })}><Bell size={19} strokeWidth={1.7} /><i /></button><div className="header-divider" /><button className="account-button" onClick={() => open({ kind: 'demo' })}><span className="person-avatar sage small">{context.role === 'PRO' ? professional?.avatar || 'PRO' : context.role}</span><span className="header-account"><strong>{context.role === 'PRO' ? professional?.name || 'Profesional' : actors.find(a => a.id === context.role)?.name.split(' ').slice(0, 3).join(' ')}</strong><small>{isSaas ? 'Administración general' : org.name}</small></span><ChevronDown size={13} /></button></div></header>;
}
