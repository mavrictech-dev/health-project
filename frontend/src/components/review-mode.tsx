'use client';
import Link from 'next/link';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { ArrowUpRight, Activity, Building2, FileClock, HeartPulse, PawPrint, RotateCcw, ShieldCheck, Stethoscope, Users } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from '@/components/ui/sheet';
import { Logo } from './shell';
import { useDemo } from '@/store/demo';
import { activateMockSession, resetMockRuntime } from '@/mocks/runtime-api';
import type { Role } from '@/lib/types';
import { api } from '@/lib/api';

export function ReviewBanner() {
  return <div className="review-banner" role="note"><span><i />Presentación · datos ficticios</span><Link href="/">Cambiar vista<ArrowUpRight size={13}/></Link></div>;
}
export function useReviewRoute() {
  const path = usePathname();
  useEffect(() => {
    const store = useDemo.getState();
    if (path.startsWith('/saas') || path === '/registro/' || path === '/registro') store.setRole('SAD');
    else if (path.startsWith('/operacion')) store.setRole('SOP');
    else if (path.startsWith('/portal') && !['PAC', 'RES'].includes(store.context.role)) store.setRole(store.context.org === 'org-vet' ? 'RES' : 'PAC');
    else if (path.startsWith('/app') && ['SAD', 'SOP', 'PAC', 'RES'].includes(store.context.role)) store.setRole('PRO');
  }, [path]);
}
const journeys = [
  { id: 'saas', icon: Building2, label: 'Administración SaaS', description: 'Clientes, planes, suscripciones y capacidad por sedes, profesionales y especialidades.', detail: 'Administrador general', path: '/saas/inicio', role: 'SAD', org: 'org-human' },
  { id: 'human', icon: Stethoscope, label: 'Medicina humana', description: 'Agenda, pacientes, historia clínica compartida y atención por especialidad.', detail: 'Equipo clínico', path: '/app/inicio', role: 'PRO', org: 'org-human', patient: 'p-lucia' },
  { id: 'dental', icon: HeartPulse, label: 'Odontología', description: 'Odontograma, hallazgos por pieza, periodoncia y plan de tratamiento.', detail: 'Consulta odontológica', path: '/app/atencion', role: 'PRO', org: 'org-human', patient: 'p-diego' },
  { id: 'vet', icon: PawPrint, label: 'Veterinaria', description: 'Pacientes animales, responsables, atención y gráficos veterinarios.', detail: 'Equipo veterinario', path: '/app/atencion', role: 'PRO', org: 'org-vet', patient: 'p-luna' },
  { id: 'portal', icon: Users, label: 'Portal del paciente', description: 'Citas, documentos, pagos y seguimiento desde la vista del paciente.', detail: 'Paciente o responsable', path: '/portal/inicio', role: 'PAC', org: 'org-human', patient: 'p-lucia' },
  { id: 'operations', icon: Activity, label: 'Estado y trazabilidad', description: 'Monitor, recorrido de operaciones, cambios antes y después y solicitudes de soporte.', detail: 'Operación de plataforma', path: '/saas/monitor', role: 'SAD', org: 'org-human' },
] as const;
export function ReviewHome() {
  const router = useRouter(), [restore, setRestore] = useState(false), theme = useDemo(s => s.theme), setTheme = useDemo(s => s.setTheme);
  const organizations = useDemo(s => s.data.organizations.length);
  function openJourney(journey: (typeof journeys)[number]) {
    const store = useDemo.getState(), org = store.data.organizations.find(org => org.id === journey.org);
    if (org) store.switchContext(org.id, org.branches[0].id);
    store.setRole(journey.role as Role);
    if ('patient' in journey) store.setPatient(journey.patient);
    activateMockSession(); router.push(journey.path);
  }
  return <div className="review-home"><header className="review-top"><Logo/><div><select aria-label="Tema de la presentación" value={theme} onChange={e => setTheme(e.target.value as 'light' | 'dark' | 'navy')}><option value="light">Blanco</option><option value="dark">Negro</option><option value="navy">Navy</option></select><Button variant="outline" onClick={() => setRestore(true)}><RotateCcw size={14}/>Restaurar demo</Button></div></header><main><div className="review-intro"><span className="access-tag">HEALTH PROJECT · PRESENTACIÓN INTERACTIVA</span><h1>Una plataforma.<br/><span>Cada forma de cuidar.</span></h1><p>Recorre la experiencia completa desde distintos perfiles. Elige por dónde empezar; puedes cambiar de vista en cualquier momento.</p><div className="review-facts"><span><Building2 size={14}/>{organizations} clientes de ejemplo</span><span><Stethoscope size={14}/>241 especialidades</span><span><ShieldCheck size={14}/>Sin credenciales reales</span></div></div><div className="review-journeys">{journeys.map(journey => <button className="review-journey" key={journey.id} onClick={() => openJourney(journey)}><div><span className={`review-icon ${journey.id}`}><journey.icon size={23} strokeWidth={1.5}/></span><ArrowUpRight size={18}/></div><small>{journey.detail}</small><h2>{journey.label}</h2><p>{journey.description}</p><span className="review-enter">Explorar vista<ArrowUpRight size={14}/></span></button>)}</div><div className="review-bottom"><div><FileClock size={21}/><p><strong>Prueba los recorridos y conserva tus cambios.</strong>Los datos se guardan solo en este navegador. Los correos, cobros, subdominios y el estado del servidor son simulados.</p></div><Link href="/saas/acceso/" onClick={() => {useDemo.getState().setRole('SAD');activateMockSession();}}>Revisar acceso y registro<ArrowUpRight size={14}/></Link></div></main><footer><span>Health Project · entorno de presentación</span><a href="https://mavrictec.com" target="_blank" rel="noopener noreferrer">Mavric Technologies<ArrowUpRight size={13}/></a></footer>{restore&&<Sheet open onOpenChange={setRestore}><SheetContent side="right" className="runtime-sheet"><SheetHeader><SheetTitle>Restaurar la demostración</SheetTitle><SheetDescription>Se reemplazarán los cambios de presentación guardados en este navegador.</SheetDescription></SheetHeader><div className="sheet-body"><p className="runtime-caption">Volverás a los clientes, pacientes, planes, tickets y recorridos ficticios iniciales.</p><div className="detail-actions"><Button variant="outline" onClick={() => setRestore(false)}>Conservar mis cambios</Button><Button onClick={() => {useDemo.getState().reset('consulta');resetMockRuntime();setRestore(false);}}>Restaurar datos de ejemplo</Button></div></div></SheetContent></Sheet>}</div>;
}
export function DemoInbox() {
  const [mail, setMail] = useState<{id:string;subject:string;email:string;href:string;used:boolean}[]>([]);
  useEffect(() => { const update = () => {void api<typeof mail>('/demo/mail').then(setMail);}; update(); window.addEventListener('health:demo-updated', update); return () => window.removeEventListener('health:demo-updated', update); }, []);
  if (!mail.length) return null;
  return <section className="review-inbox" aria-label="Buzón simulado"><h3>Buzón de demostración</h3><p>No se envían correos reales. Abre un mensaje para continuar el recorrido.</p>{mail.map(item => <div key={item.id}><strong>{item.subject}</strong><small>{item.email}</small>{item.used?<span>Enlace utilizado</span>:<Link href={item.href}>Abrir enlace simulado<ArrowUpRight size={12}/></Link>}</div>)}</section>;
}
