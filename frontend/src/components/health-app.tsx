'use client';
import { useEffect, useState, useSyncExternalStore } from 'react';
import { usePathname, useSearchParams, useRouter } from 'next/navigation';
import { CheckCircle2, ShieldCheck, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useDemo } from '@/store/demo';
import { getScreen, specialties, actors } from '@/lib/spec';
import { Header, Navigation } from './shell';
import { Dashboard } from './dashboard';
import { Agenda } from './agenda';
import { PatientsDirectory, PatientProfile } from './patients';
import { ClinicalWorkspace } from './clinical';
import { AuditView, BedsView, DocumentsView, FinanceView, InventoryView, ModuleView, ProcessTray, ReportsView } from './modules';
import { OverlayHost } from './overlay-host';
import { PortalDashboard } from './portal';
import { AccessView } from './access';
import Link from 'next/link';
import { SaasHome, SaasClients, SaasPlans, SaasSubscriptions, SaasCatalog, SaasAudit, TenantSettings, TenantBar } from './saas';
import { canManageTenant, pathLicenseReason } from '@/lib/saas';
import type { Role } from '@/lib/types';
import { useAuth, homeFor } from './auth-session';
import { AuthAccess } from './auth-access';
import { RuntimeWorkspace } from './runtime-workspace';
import { RuntimeReviewFeature, runtimeReviewTitle } from './runtime-workspace';
import { isMockMode } from '@/lib/app-mode';
import { ReviewHome, ReviewBanner, useReviewRoute } from './review-mode';

const subscribeClient = () => () => {};
const clientSnapshot = () => true;
const serverSnapshot = () => false;

function DemoHealthApp() {
  const pathname = usePathname(); const path = pathname === '/' ? '/' : pathname.replace(/\/$/, '');
  const search = useSearchParams(); const screen = getScreen(path, search.toString());
  const { data, context, density, sidebarCollapsed, overlay, message, notify, setPatient, setSpecialty, setRole, open } = useDemo(); const ready = useSyncExternalStore(subscribeClient, clientSnapshot, serverSnapshot);
  useEffect(() => { const patient = search.get('paciente'); if (patient && patient !== 'id') setPatient(patient); const specialty = search.get('especialidad'); if (specialty && specialties.some(s => s.code === specialty)) setSpecialty(specialty); }, [search, setPatient, setSpecialty]);
  useEffect(() => { const keydown = (event: KeyboardEvent) => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') { event.preventDefault(); if (!overlay) open({ kind: 'search' }); } }; document.addEventListener('keydown', keydown); return () => document.removeEventListener('keydown', keydown); }, [open, overlay]);
  useEffect(() => { if (!message) return; const timeout = setTimeout(() => notify(''), 5000); return () => clearTimeout(timeout); }, [message, notify]);
  if (!ready) return <div className="boot-screen">Preparando tu espacio…</div>;
  const access = ['/acceso', '/portal/acceso', '/operacion/acceso', '/saas/acceso', '/recuperar', '/invitacion'].includes(path);
  const isPortal = path.startsWith('/portal');
  const permitted = screen.roles.includes(context.role) || ['S05','S06','S63'].includes(screen.id) && canManageTenant(data, context) || screen.id === 'S53' || screen.id === 'S35' && isPortal && ['PAC', 'RES'].includes(context.role) || screen.id === 'S17' && !['PAC', 'RES', 'SOP', 'SAD'].includes(context.role);
  const license = pathLicenseReason(data, context, path);
  if (isMockMode && runtimeReviewTitle(path)) return <div className={`app-frame ${sidebarCollapsed ? 'is-collapsed' : ''}`}><Navigation/><div className="app-main"><Header title={runtimeReviewTitle(path)!}/><main className="page-content"><RuntimeReviewFeature path={path}/></main></div>{overlay&&<OverlayHost key={overlay.kind}/>}</div>;
  const content = !permitted ? <div className="restricted-panel"><ShieldCheck size={32} /><h2>Esta área corresponde a otro rol</h2><p>Para recorrerla en la presentación, cambia a uno de los roles preparados.</p><div className="detail-actions justify-center">{screen.roles.filter(r => r !== 'SOP').map(role => <Button key={role} onClick={() => setRole(role as Role)}>{actors.find(a => a.id === role)?.name || role}</Button>)}</div></div> : license ? <div className="restricted-panel"><ShieldCheck size={32}/><h2>Este módulo necesita otra capacidad</h2><p>{license}</p><Link href="/app/plataforma"><Button>Ver plan y capacidad</Button></Link></div> : screen.id === 'S57' ? <SaasHome/> : screen.id === 'S58' ? <SaasClients/> : screen.id === 'S59' ? <SaasPlans/> : screen.id === 'S60' ? <SaasSubscriptions/> : screen.id === 'S61' ? <SaasCatalog/> : screen.id === 'S62' ? <SaasAudit/> : ['S05','S06','S08','S51','S63'].includes(screen.id) ? <TenantSettings screenId={screen.id}/> : screen.id === 'S17' ? <Dashboard /> : ['S14', 'S16', 'S30'].includes(screen.id) ? <Agenda reception={screen.id === 'S16'} portal={screen.id === 'S30'} /> : screen.id === 'S09' ? <PatientsDirectory /> : ['S10', 'S11', 'S19'].includes(screen.id) ? <PatientProfile history={screen.id === 'S19'} /> : screen.id === 'S18' ? <ClinicalWorkspace key={`${context.patient}:${context.encounter}:${search.toString()}`} /> : ['S28', 'S31'].includes(screen.id) ? <DocumentsView portal={screen.id === 'S31'} /> : screen.id === 'S35' ? <FinanceView portal={isPortal} /> : screen.id === 'S39' ? <InventoryView /> : screen.id === 'S41' ? <BedsView /> : screen.id === 'S49' ? <ReportsView /> : screen.id === 'S50' ? <AuditView /> : screen.id === 'S29' ? <PortalDashboard /> : <ModuleView key={screen.id} screenId={screen.id} />;
  return <>{access ? <AccessView platform={path.startsWith('/saas')} portal={path.startsWith('/portal')} operator={path.startsWith('/operacion')} recovery={['/recuperar', '/invitacion'].includes(path)} /> : <div className={`app-frame ${sidebarCollapsed ? 'is-collapsed' : ''} ${density === 'compact' ? 'is-dense' : ''}`}><Navigation /><div className="app-main"><Header title={screen.id === 'S17' ? 'Inicio' : screen.name.replace('Espacio de ', '')} /><main className="page-content">{(path.startsWith('/app') || path === '/') && context.role !== 'SAD' && <TenantBar/>}{content}{permitted && !license && screen.flows.length > 0 && <ProcessTray screen={screen} />}</main></div></div>}{overlay && <OverlayHost key={overlay.kind} />}{message && <div className="success-banner" role="status"><CheckCircle2 size={17} /><span>{message}</span><button aria-label="Cerrar aviso" onClick={() => notify('')}><X size={14} /></button></div>}</>;
}

export function HealthApp() {
  if (isMockMode) return <ReviewApp/>;
  return <LiveHealthApp/>;
}

function ReviewApp() {
  useReviewRoute();
  const path = usePathname().replace(/\/$/, '');
  if (path === '' || path === '/demo') return <ReviewHome/>;
  const access = ['/acceso','/portal/acceso','/operacion/acceso','/saas/acceso','/recuperar','/registro','/verificar','/restablecer','/invitacion'].includes(path);
  return <div className="review-mode"><ReviewBanner/>{access ? <AuthAccess key={path}/> : <DemoHealthApp/>}</div>;
}

function LiveHealthApp() {
  const path=usePathname().replace(/\/$/,''),auth=useAuth(),router=useRouter();
  const [demo,setDemo]=useState(false);
  useEffect(()=>{if(path==='/demo')sessionStorage.setItem('health-explicit-demo','1');setDemo(sessionStorage.getItem('health-explicit-demo')==='1');},[path]);
  if(demo) return <><div className="explicit-demo-banner">Presentación clínica · datos ficticios<Button variant="outline" onClick={()=>{sessionStorage.removeItem('health-explicit-demo');setDemo(false);router.push(auth.user?homeFor(auth.user):'/acceso');}}>Volver a mi espacio</Button></div><DemoHealthApp/></>;
  if(['/acceso','/portal/acceso','/operacion/acceso','/saas/acceso','/recuperar','/registro','/verificar','/restablecer','/invitacion'].includes(path)) return <AuthAccess key={path}/>;
  if(auth.loading) return <div className="boot-screen" role="status">Conectando con tu espacio…</div>;
  if(!auth.user || auth.error) return <AuthAccess mode="login"/>;
  return <RuntimeWorkspace/>;
}
