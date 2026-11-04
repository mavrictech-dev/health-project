'use client';
import {useCallback,useEffect,useRef,useState} from 'react';
import {Building2,CheckCircle2,LoaderCircle,RefreshCw} from 'lucide-react';
import {Button} from '@/components/ui/button';
import {Input} from '@/components/ui/input';
import {Textarea} from '@/components/ui/textarea';
import {Sheet,SheetContent,SheetHeader,SheetTitle,SheetDescription} from '@/components/ui/sheet';
import {api,ApiError,errorMessage,isAbort} from '@/lib/api';
import {ambiguousBranchStatus,buildBranchRequest,organizationMemberView,organizationUsage,readOrganizationBranch,readOrganizationConfiguration,type BranchDraft,type BranchRequest,type OrganizationConfiguration} from '@/lib/organization-types';
import {sessionMatchesHost} from '@/lib/live-routes';
import {useAuth} from './auth-session';
import '@/styles/live-organization.css';

export function RuntimeOrganization(){
  const {user,host}=useAuth();
  if(!user||!host||host.platform||!user.roles.includes('ADM')||user.roles.some(role=>['PAC','RES'].includes(role))||!sessionMatchesHost(user,host))return <section role="alert"><h1>No tienes acceso a Organización</h1><p>Este recorrido requiere administrar la organización de esta sesión.</p></section>;
  return <OrganizationWorkspace key={host.id} tenantId={host.id!}/>;
}
function OrganizationWorkspace({tenantId}:{tenantId:string}){
  const [data,setData]=useState<OrganizationConfiguration|null>(null),[loading,setLoading]=useState(true),[loadError,setLoadError]=useState(''),[open,setOpen]=useState(false),[notice,setNotice]=useState('');
  const readController=useRef<AbortController|null>(null);
  const reload=useCallback(async()=>{
    readController.current?.abort();const controller=new AbortController();readController.current=controller;
    setLoading(true);setLoadError('');setData(null);
    try{
      const value=readOrganizationConfiguration(await api('/tenant/configuration',{signal:controller.signal}),tenantId);
      if(!controller.signal.aborted)setData(value);
      return !controller.signal.aborted;
    }catch(error){if(!controller.signal.aborted&&!isAbort(error))setLoadError(errorMessage(error));return false;}
    finally{if(!controller.signal.aborted)setLoading(false);}
  },[tenantId]);
  useEffect(()=>{void reload();return()=>readController.current?.abort();},[reload]);
  const usage=data?organizationUsage(data):null;
  return <section className="live-organization"><div className="runtime-heading"><div><p className="eyebrow">MI ORGANIZACIÓN</p><h1>Organización y sedes</h1><p>Sedes y capacidad contratada de {data?.name||'tu organización'}.</p></div><div className="detail-actions"><Button variant="outline" disabled={loading} onClick={()=>void reload()}><RefreshCw size={15}/>Actualizar configuración</Button><Button disabled={!data||loading} onClick={()=>{setNotice('');setOpen(true);}}><Building2 size={15}/>Crear sede propia</Button></div></div>
    {notice&&<p className="organization-confirmed" role="status"><CheckCircle2 size={16}/>{notice}</p>}
    {loading&&<p className="runtime-loading" role="status"><LoaderCircle className="spin" size={16}/>Cargando configuración…</p>}
    {loadError&&<div className="runtime-notice error" role="alert"><p>{loadError}</p><Button variant="outline" onClick={()=>void reload()}>Volver a intentar</Button></div>}
    {data&&usage&&<><div className="organization-capacity"><article data-testid="branch-capacity"><h2>Sedes propias activas</h2><strong>{usage.branches} de {data.branchQuota}</strong><p>{usage.branchesRemaining} disponibles según la consulta.</p></article><article data-testid="professional-capacity"><h2>Cupo de profesionales</h2><strong>{usage.professionals} de {data.professionalQuota}</strong><p>Incluye profesionales activos e invitados; excluye inactivos.</p></article></div>
      <p className="runtime-caption">Estos cálculos orientan según la última consulta. El servidor valida el cupo y los permisos al guardar. Esta vista no modifica planes, equipo ni habilita uso asistencial.</p>
      <div className="runtime-table-wrap"><table className="runtime-table"><thead><tr><th>Sede</th><th>Dirección</th><th>Tipo</th><th>Estado</th></tr></thead><tbody>{data.branches.map(branch=><tr key={branch.id}><td><strong>{branch.name}</strong></td><td>{branch.address||'Sin dirección registrada'}</td><td>{branch.external?'Lugar externo':'Sede propia'}</td><td>{branch.active?'Activa':'Inactiva'}</td></tr>)}</tbody></table>{!data.branches.length&&<div className="runtime-empty"><Building2 size={30}/><h2>Sin sedes registradas</h2><p>La configuración consultada no contiene sedes.</p></div>}</div>
      <section className="organization-team" aria-labelledby="organization-team-title"><h2 id="organization-team-title">Equipo de la organización</h2><p className="runtime-caption">Consulta de membresías y asignaciones, sin edición. El estado Invitado no confirma el envío ni la entrega de una invitación. Los perfiles asignados no habilitan por sí solos el uso asistencial.</p>
        {data.members.length?<div className="runtime-table-wrap"><table className="runtime-table organization-team-table"><caption className="sr-only">Equipo y asignaciones de la configuración consultada</caption><thead><tr><th>Miembro</th><th>Roles</th><th>Estado</th><th>Sedes asignadas</th><th>Especialidades asignadas</th></tr></thead><tbody>{data.members.map(member=>{const view=organizationMemberView(member,data);return <tr key={member.id}><td data-label="Miembro"><strong>{view.name}</strong>{view.owner&&<span className="organization-owner">Propietario</span>}</td><td data-label="Roles"><ul>{view.roles.map(role=><li key={role}>{role}</li>)}</ul></td><td data-label="Estado">{view.status}</td><td data-label="Sedes asignadas">{view.branches.length?<ul>{view.branches.map((name,index)=><li key={index}>{name}</li>)}</ul>:'Sin sedes asignadas'}</td><td data-label="Especialidades asignadas">{view.specialties.length?<ul>{view.specialties.map((name,index)=><li key={index}>{name}</li>)}</ul>:'Sin especialidades asignadas'}</td></tr>;})}</tbody></table></div>:<div className="runtime-empty"><h3>Sin miembros registrados</h3><p>La configuración consultada no contiene miembros.</p></div>}
      </section></>}
    {open&&<CreateBranch reload={reload} onClose={()=>setOpen(false)} onConfirmed={name=>setNotice(`Sede registrada: ${name}.`)} quotaFull={!!usage&&usage.branchesRemaining===0}/>}
  </section>;
}
function CreateBranch({reload,onClose,onConfirmed,quotaFull}:{reload:()=>Promise<boolean>;onClose:()=>void;onConfirmed:(name:string)=>void;quotaFull:boolean}){
  const [draft,setDraft]=useState<BranchDraft>({name:'',address:''}),[review,setReview]=useState<BranchRequest|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState(''),[ambiguous,setAmbiguous]=useState(false),[checking,setChecking]=useState(false),[consulted,setConsulted]=useState(false),[retryAccepted,setRetryAccepted]=useState(false),[confirmed,setConfirmed]=useState(''),[discard,setDiscard]=useState(false);
  const busyRef=useRef(false),alive=useRef(true),controller=useRef<AbortController|null>(null),bodyRef=useRef<HTMLDivElement>(null);
  useEffect(()=>{alive.current=true;return()=>{alive.current=false;controller.current?.abort();};},[]);
  useEffect(()=>{bodyRef.current?.scrollTo(0,0);},[review,confirmed,discard]);
  const dirty=!!draft.name||!!draft.address;
  useEffect(()=>{if(!dirty||confirmed)return;const warn=(event:BeforeUnloadEvent)=>{event.preventDefault();event.returnValue='';};window.addEventListener('beforeunload',warn);return()=>window.removeEventListener('beforeunload',warn);},[dirty,confirmed]);
  function close(){if(busyRef.current||checking)return;if(dirty&&!confirmed)setDiscard(true);else onClose();}
  function prepare(event:React.FormEvent){event.preventDefault();setError('');try{setReview(buildBranchRequest(draft));}catch(error){setError(errorMessage(error));}}
  async function save(){
    if(!review||busyRef.current||ambiguous||confirmed)return;
    busyRef.current=true;setBusy(true);setError('');controller.current=new AbortController();
    try{
      const raw=await api('/tenant/branches',{method:'POST',body:review,signal:controller.current.signal});
      let branch;
      try{branch=readOrganizationBranch(raw);if(branch.external||!branch.active)throw Error();}
      catch{throw new ApiError('La respuesta de alta no permite confirmar el resultado.',200);}
      if(!alive.current)return;
      setConfirmed(branch.name);setDraft({name:'',address:''});setReview(null);onConfirmed(branch.name);await reload();
    }catch(error){
      if(!alive.current||isAbort(error))return;
      setError(errorMessage(error));
      if(error instanceof ApiError&&ambiguousBranchStatus(error.status)){setAmbiguous(true);setConsulted(false);setRetryAccepted(false);}
      if(error instanceof ApiError&&error.status===409)await reload();
    }finally{busyRef.current=false;if(alive.current)setBusy(false);}
  }
  async function consult(){if(checking)return;setChecking(true);setConsulted(false);setRetryAccepted(false);const ok=await reload();if(alive.current){setConsulted(ok);setChecking(false);}}
  return <Sheet open onOpenChange={value=>{if(!value)close();}}><SheetContent side="right" className="runtime-sheet organization-sheet"><SheetHeader><SheetTitle>{confirmed?'Sede confirmada':review?'Revisa la nueva sede':'Crear sede propia'}</SheetTitle><SheetDescription>Alta de una sede propia activa en tu organización.</SheetDescription></SheetHeader><div className="sheet-body" ref={bodyRef}>
    {discard?<div className="organization-message"><h2>¿Descartar el borrador?</h2><p>{ambiguous?'Descartar el borrador no cancela una solicitud que pudo haberse guardado. Consulta la configuración para comprobar el estado.':'Los datos todavía no enviados se perderán.'}</p><Button variant="outline" onClick={()=>setDiscard(false)}>Seguir revisando</Button><Button onClick={onClose}>Descartar borrador</Button></div>:confirmed?<div className="organization-message" role="status"><CheckCircle2 size={24}/><h2>{confirmed}</h2><p>El servidor confirmó el alta. La lista y los cupos se consultan de nuevo; si esa lectura falla, usa Volver a intentar en la página.</p><Button onClick={onClose}>Ver configuración</Button></div>:<>
      {quotaFull&&<p className="runtime-caption">El cupo consultado de sedes está completo. Puedes actualizar la configuración; el servidor decide si el alta es posible.</p>}
      {error&&<div className="runtime-notice error" role="alert">{error}</div>}
      {ambiguous&&<div className="organization-message" role="alert"><h2>No se confirmó el resultado</h2><p>La solicitud pudo haberse guardado. No se repetirá automáticamente. Consulta el estado antes de decidir; encontrar o no una sede con el mismo nombre no prueba unicidad ni confirma el resultado de esta solicitud.</p><Button variant="outline" disabled={checking} onClick={()=>void consult()}>{checking?'Consultando…':'Consultar configuración sin reenviar'}</Button>{consulted&&<><p>Consulta actualizada. Cierra este panel para revisar las sedes recibidas.</p><label className="organization-ack"><input type="checkbox" checked={retryAccepted} onChange={event=>setRetryAccepted(event.target.checked)}/>He revisado el estado y acepto que un nuevo envío podría duplicar la sede.</label><Button variant="outline" disabled={!retryAccepted} onClick={()=>{setAmbiguous(false);setReview(null);setError('');}}>Volver al borrador para decidir</Button></>}</div>}
      {review?<><dl className="organization-review"><div><dt>Nombre</dt><dd>{review.name}</dd></div><div><dt>Dirección</dt><dd>{review.address||'Sin dirección registrada'}</dd></div><div><dt>Tipo y estado</dt><dd>Sede propia · Activa</dd></div></dl><p className="runtime-caption">El cupo se comprueba al guardar. No se crean profesionales ni se modifican las condiciones del plan.</p><div className="detail-actions"><Button variant="outline" disabled={busy||ambiguous} onClick={()=>setReview(null)}>Volver al formulario</Button><Button disabled={busy||ambiguous} onClick={()=>void save()}>{busy?<><LoaderCircle className="spin" size={15}/>Guardando…</>:'Confirmar sede'}</Button></div></>:<form className="organization-form" onSubmit={prepare}><div className="form-field"><label htmlFor="branch-name">Nombre de la sede</label><Input id="branch-name" value={draft.name} onChange={event=>setDraft({...draft,name:event.target.value})} maxLength={160} required disabled={ambiguous}/></div><div className="form-field"><label htmlFor="branch-address">Dirección (opcional)</label><Textarea id="branch-address" value={draft.address} onChange={event=>setDraft({...draft,address:event.target.value})} maxLength={300} disabled={ambiguous}/></div><Button type="submit" disabled={ambiguous}>Revisar sede</Button></form>}
    </>}
  </div></SheetContent></Sheet>;
}
