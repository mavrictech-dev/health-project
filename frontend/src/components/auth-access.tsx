'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { ArrowRight, CheckCircle2, Eye, EyeOff, HeartPulse, LoaderCircle, ShieldCheck, ExternalLink } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Logo } from './shell';
import { useAuth, homeFor } from './auth-session';
import { api, errorMessage, isAbort } from '@/lib/api';
import { useVisualPreferences } from './providers';
import { SupportSheet } from './runtime-support';
import { useDemo } from '@/store/demo';
import { isMockMode } from '@/lib/app-mode';
import { getSaas } from '@/lib/saas';
import { DemoInbox } from './review-mode';
import { activateMockSession } from '@/mocks/runtime-api';
type Plan = { id: string; name: string; kinds: string[]; domains: string[]; baseMinor: number };
type Specialty = { code: string; name: string; domain: string; dental: boolean };
export function AuthAccess({ mode: forcedMode }: { mode?: string }) {
  const path = usePathname(), router = useRouter(), auth = useAuth();
  const mode = forcedMode || (path.includes('registro') ? 'register' : path.includes('restablecer') ? 'reset' : path.includes('verificar') ? 'verify' : path.includes('recuperar') ? 'recover' : path.includes('invitacion') ? 'invite' : 'login');
  const [email, setEmail] = useState(isMockMode ? 'revision@example.test' : ''), [password, setPassword] = useState(''), [confirm, setConfirm] = useState(''), [name, setName] = useState(''), [slug, setSlug] = useState(''), [organizationName, setOrganizationName] = useState('');
  const [ruc,setRuc]=useState('');
  const [show, setShow] = useState(false), [busy, setBusy] = useState(false), [error, setError] = useState(''), [message, setMessage] = useState(''), [support, setSupport] = useState(false), [token, setToken] = useState(''), [terms, setTerms] = useState(false);
  const [kind, setKind] = useState('DOCTOR'), [domain, setDomain] = useState('HUMAN'), [plans, setPlans] = useState<Plan[]>([]), [specialties, setSpecialties] = useState<Specialty[]>([]), [planId, setPlan] = useState(''), [specialtyCode, setSpecialty] = useState('');
  const {theme,setTheme} = useVisualPreferences();
  useEffect(() => { const params = new URLSearchParams(window.location.hash.slice(1)); setToken(params.get('token') || ''); if (window.location.hash) window.history.replaceState(null, '', window.location.pathname); }, []);
  useEffect(() => { const controller=new AbortController(); if (mode === 'register' && auth.host?.platform) void api<{ plans: Plan[]; specialties: Specialty[] }>('/public/registration',{signal:controller.signal}).then(data => { if(!controller.signal.aborted){setPlans(data.plans);setSpecialties(data.specialties);} }).catch(e => {if(!isAbort(e)&&!controller.signal.aborted)setError(errorMessage(e));}); return()=>controller.abort(); }, [mode, auth.host?.platform]);
  const compatible = plans.filter(p => p.kinds.includes(kind) && p.domains.includes(domain));
  const catalog = specialties.filter(s => s.domain === domain && (kind !== 'DENTAL' || s.dental));
  const selectedPlan = compatible.some(p => p.id === planId) ? planId : compatible[0]?.id || '';
  const selectedSpecialty = catalog.some(s => s.code === specialtyCode) ? specialtyCode : catalog[0]?.code || '';
  const titles: Record<string, string> = { login: 'Bienvenido de nuevo', register: auth.host?.platform ? 'Crea tu espacio de salud' : 'Crea tu cuenta del portal', recover: 'Recupera tu acceso', reset: 'Elige una nueva contraseña', verify: 'Confirma tu correo', invite: 'Acepta tu invitación' };
  async function submit(event: React.FormEvent) {
    event.preventDefault(); setError(''); setMessage('');
    if (['register', 'reset'].includes(mode) && password !== confirm) { setError('Las contraseñas deben coincidir.'); return; }
    setBusy(true);
    try {
      if (mode === 'login' || mode === 'invite') {
        if (mode === 'invite') await api('/auth/invitations/accept', { method: 'POST', body: { email, password } });
        const user = await auth.login(email, password,ruc||auth.host?.ruc); setPassword(''); if(!user.requiresBranchSelection)router.replace(homeFor(user));
      } else if (mode === 'register') { const result = await api<{ message: string }>('/auth/register', { method: 'POST', body: { name, email, password, kind, domain, organizationName, slug, ...(auth.host?.platform?{ruc}:{}), planId: selectedPlan || null, specialtyCode: selectedSpecialty || null, acceptTerms: terms } }); setMessage(result.message); setPassword(''); setConfirm(''); }
      else if (mode === 'recover') setMessage((await api<{ message: string }>('/auth/recovery/request', { method: 'POST', body: { email } })).message);
      else if (mode === 'verify' || mode === 'reset') { const result = await api<{ message: string }>(mode === 'verify' ? '/auth/verify/complete' : '/auth/recovery/complete', { method: 'POST', body: { token, ...(mode === 'reset' ? { password } : {}) } }); setMessage(result.message); setPassword(''); setConfirm(''); setToken(''); }
    } catch (e) { setError(errorMessage(e)); } finally { setBusy(false); }
  }
  async function resend() { setBusy(true); setError(''); try { setMessage((await api<{ message: string }>('/auth/verify/request', { method: 'POST', body: { email } })).message); } catch (e) { setError(errorMessage(e)); } finally { setBusy(false); } }
  async function openWorkspace() {
    if(!isMockMode){try{const result=await api<{hostname:string}>('/public/tenant-space',{method:'POST',body:{ruc}});window.location.href=window.location.protocol+'//'+result.hostname+(window.location.port?':'+window.location.port:'')+'/acceso/';}catch(e){setError(errorMessage(e));}return;}

    if (isMockMode) {
      const store = useDemo.getState(), tenant = getSaas(store.data).tenants.find(tenant => (tenant as {ruc?:string}).ruc === ruc), organization = store.data.organizations.find(org => org.id === tenant?.id);
      if (!organization) { setError('No hay un espacio de ejemplo con ese identificador. Puedes crearlo desde Registro o Clientes.'); return; }
      store.switchContext(organization.id, organization.branches[0].id); store.setRole('ADM'); activateMockSession(); router.push('/app/inicio'); return;
    }
    window.location.href=`${window.location.protocol}//${slug}.${auth.host?.baseDomain}${window.location.port ? ':'+window.location.port : ''}/acceso/`;
  }
  return <div className="access-screen runtime-access"><div className="access-story"><Logo /><div><p className="eyebrow">CUIDADO QUE CONECTA</p><h1>Cada historia<br />merece su espacio.</h1><p>Un acceso a tu equipo, tus pacientes<br />y cada paso de su atención.</p><div className="access-art"><HeartPulse size={110} strokeWidth={.7} /><span className="access-orbit orbit-one" /><span className="access-orbit orbit-two" /></div></div><a className="access-story-footer" href="https://mavrictec.com" target="_blank" rel="noopener noreferrer">Mavric Technologies <ExternalLink size={13} /></a></div><div className="access-form-wrapper"><div className="access-form runtime-auth-form"><div className="auth-topline"><span className="access-tag">{auth.host?.name || 'HEALTH PROJECT'}</span><select aria-label="Tema" value={theme} onChange={e => setTheme(e.target.value as 'light' | 'dark' | 'navy')}><option value="light">Blanco</option><option value="dark">Negro</option><option value="navy">Navy</option></select></div><h2>{titles[mode]}</h2><p>{auth.host?.platform ? 'Tu plataforma, desde un solo lugar.' : `Estás en ${auth.host?.name || 'tu espacio'}.`}</p>
    {isMockMode&&<p className="review-auth-note">Acceso simulado. Utiliza un correo y una contraseña ficticios; los cambios quedan en este navegador.</p>}
    {auth.loading ? <p role="status">Conectando con tu espacio…</p> : auth.error ? <div className="auth-feedback error" role="alert"><p>{auth.error}</p><Button variant="outline" onClick={() => void auth.refresh()}>Volver a intentar</Button></div> : auth.user?.requiresBranchSelection ? <BranchSelection onSelected={()=>router.replace(homeFor(auth.user!))}/> : <form onSubmit={submit}>
      {((mode==='login'&&!auth.host?.platform)||(mode==='register'&&auth.host?.platform))&&<div className="form-field"><label htmlFor="auth-ruc">RUC del Negocio</label><Input id="auth-ruc" value={ruc} onChange={e=>setRuc(e.target.value)} inputMode="numeric" pattern="[0-9]{11}" minLength={11} maxLength={11} autoComplete="off" required/><small>11 dígitos. Tu usuario es tu correo electrónico.</small></div>}
      {mode === 'register' && <><div className="form-field"><label htmlFor="auth-name">Tu nombre</label><Input id="auth-name" value={name} onChange={e => setName(e.target.value)} maxLength={160} autoComplete="name" required /></div>{auth.host?.platform && <><div className="form-field"><label htmlFor="auth-organization">Nombre del espacio</label><Input id="auth-organization" value={organizationName} onChange={e => setOrganizationName(e.target.value)} maxLength={160} required /></div><div className="auth-field-row"><div className="form-field"><label htmlFor="auth-kind">Tipo de cliente</label><select id="auth-kind" value={kind} onChange={e => { setKind(e.target.value); if (e.target.value === 'VETERINARY') setDomain('ANIMAL'); else if (e.target.value !== 'DOCTOR') setDomain('HUMAN'); }}>{[['DOCTOR','Independiente'],['CLINIC','Clínica'],['HOSPITAL','Hospital'],['VETERINARY','Veterinaria'],['DENTAL','Centro odontológico'],['SPECIALTY_CENTER','Centro de especialidad']].map(([id,label]) => <option key={id} value={id}>{label}</option>)}</select></div><div className="form-field"><label htmlFor="auth-domain">Ámbito</label><select id="auth-domain" value={domain} disabled={kind !== 'DOCTOR'} onChange={e => setDomain(e.target.value)}><option value="HUMAN">Humano</option><option value="ANIMAL">Animal</option></select></div></div><div className="form-field"><label htmlFor="auth-slug">Tu subdominio</label><Input id="auth-slug" value={slug} onChange={e => setSlug(e.target.value.toLowerCase())} pattern="[a-z0-9]+(-[a-z0-9]+)*" maxLength={63} placeholder="mi-clinica" required /><small>{slug || 'mi-clinica'}.{auth.host.baseDomain}</small></div><div className="form-field"><label htmlFor="auth-plan">Plan inicial</label><select id="auth-plan" value={selectedPlan} onChange={e => setPlan(e.target.value)} required><option value="" disabled>Selecciona un plan</option>{compatible.map(p => <option key={p.id} value={p.id}>{p.name} · S/ {(p.baseMinor/100).toFixed(2)} / mes</option>)}</select></div><div className="form-field"><label htmlFor="auth-specialty">Especialidad inicial</label><select id="auth-specialty" value={selectedSpecialty} onChange={e => setSpecialty(e.target.value)} required><option value="" disabled>Selecciona una especialidad</option>{catalog.map(s => <option key={s.code} value={s.code}>{s.name}</option>)}</select></div></>}</>}
      {!['reset', 'verify'].includes(mode) && <div className="form-field"><label htmlFor="auth-email">Correo electrónico</label><Input id="auth-email" value={email} onChange={e => setEmail(e.target.value)} type="email" autoComplete="email" maxLength={254} required /></div>}
      {['login', 'register', 'reset', 'invite'].includes(mode) && <div className="form-field"><label htmlFor="auth-password">{mode === 'reset' ? 'Nueva contraseña' : 'Contraseña'}</label><div className="password-field"><Input id="auth-password" value={password} onChange={e => setPassword(e.target.value)} type={show ? 'text' : 'password'} autoComplete={['register','reset'].includes(mode) ? 'new-password' : 'current-password'} minLength={['register','reset'].includes(mode) ? 12 : 1} required /><button type="button" aria-label={show ? 'Ocultar contraseña' : 'Mostrar contraseña'} onClick={() => setShow(!show)}>{show ? <EyeOff size={16} /> : <Eye size={16} />}</button></div>{['register','reset'].includes(mode) && <small>Al menos 12 caracteres; máximo 72 bytes.</small>}</div>}
      {['register','reset'].includes(mode) && <div className="form-field"><label htmlFor="auth-confirm">Confirma la contraseña</label><Input id="auth-confirm" value={confirm} onChange={e => setConfirm(e.target.value)} type="password" autoComplete="new-password" required /></div>}
      {mode === 'register' && <label className="auth-consent"><input type="checkbox" checked={terms} onChange={e => setTerms(e.target.checked)} required />Confirmo la creación de esta cuenta y el uso de mi correo para verificar el acceso.</label>}
      {mode === 'verify' && !message && <p>Confirma el correo con el enlace recibido. El enlace solo se puede utilizar una vez.</p>}
      {error && <div className="auth-feedback error" role="alert">{error}{error.includes('Verifica') && <button type="button" onClick={resend} disabled={busy}>Reenviar verificación</button>}</div>}
      {message && <div className="auth-feedback success" role="status"><CheckCircle2 size={18} /><p>{message}</p></div>}
      {!(['verify','reset'].includes(mode) && message) && <Button className="auth-submit" disabled={busy || (['verify','reset'].includes(mode) && !token)} type="submit">{busy ? <><LoaderCircle size={16} className="spin" />Procesando…</> : <>{mode === 'login' ? 'Iniciar sesión' : mode === 'register' ? 'Crear cuenta' : mode === 'recover' ? 'Enviar enlace de recuperación' : mode === 'verify' ? 'Confirmar correo' : mode === 'invite' ? 'Aceptar e iniciar sesión' : 'Guardar contraseña'}<ArrowRight size={16} /></>}</Button>}
    </form>}
    {isMockMode&&<DemoInbox/>}
    <div className="auth-links">{mode === 'login' ? <><Link href="/recuperar">Olvidé mi contraseña</Link><Link href="/registro">Crear una cuenta</Link></> : <Link href="/acceso">Volver a iniciar sesión</Link>}<button onClick={() => setSupport(true)}>Solicitar soporte</button>{isMockMode&&<Link href="/">Volver a la presentación</Link>}</div>
    {auth.host?.platform && mode === 'login' && <div className="workspace-login"><label htmlFor="workspace-ruc">¿Ingresas a una clínica o consulta?</label><div><Input id="workspace-ruc" value={ruc} onChange={e=>setRuc(e.target.value)} inputMode="numeric" maxLength={11} placeholder="RUC de tu negocio" /><Button variant="outline" disabled={!/^[0-9]{11}$/.test(ruc)} onClick={()=>void openWorkspace()}>Abrir espacio</Button></div></div>}
    <p className="access-note"><ShieldCheck size={13} />Tu sesión pertenece únicamente a este espacio.</p></div></div><SupportSheet open={support} onClose={() => setSupport(false)} /></div>;
}

export function BranchSelection({onSelected}:{onSelected?:()=>void}){const auth=useAuth(),[busy,setBusy]=useState(false),[error,setError]=useState('');return <section className="runtime-panel"><p className="eyebrow">TU ESPACIO DE TRABAJO</p><h2>Selecciona una sucursal</h2><p>Elige dónde vas a operar. Solo se muestran tus sedes autorizadas.</p><div className="branch-choices">{auth.branches.map(branch=><Button key={branch.id} variant="outline" disabled={busy} onClick={async()=>{setBusy(true);setError('');try{await auth.selectBranch(branch.id);onSelected?.();}catch(e){setError(errorMessage(e));}finally{setBusy(false);}}}><span><strong>{branch.name}</strong><small>{branch.address||'Sede de atención'}</small></span><ArrowRight size={18}/></Button>)}</div>{!auth.branches.length&&<p>No tienes sucursales asignadas. Solicita la asignación al administrador.</p>}{error&&<p role="alert">{error}</p>}</section>;}
