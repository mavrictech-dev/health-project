'use client';
import {useEffect,useRef,useState} from 'react';
import {Button} from '@/components/ui/button';
import {api,ApiError,isAbort} from '@/lib/api';
import {patientLinksPath,readPatientLinkPage,nextPatientLinkOffset,patientLinkScopeLabel,type PatientLinkPage} from '@/lib/patient-link-types';

function message(error:unknown){
  const status=error instanceof ApiError?error.status:0;
  const text=status===401?'Tu sesión venció. Vuelve a acceder.':status===403?'No tienes permiso para consultar los vínculos de este paciente.':status===404?'Este paciente ya no está disponible.':'No se pudieron consultar los vínculos. Comprueba la conexión y vuelve a consultar.';
  const reference=error instanceof ApiError?error.requestId.replace(/[^a-zA-Z0-9_.:-]/g,'').slice(0,100):'';
  return text+(reference?' Referencia: '+reference:'');
}
export function RuntimePatientLinks({tenantId,patientId,onBack}:{tenantId:string;patientId:string;onBack:()=>void}){
  const [offset,setOffset]=useState(0),[refresh,setRefresh]=useState(0);
  const key=[tenantId,patientId,offset,refresh].join(':');
  const currentKey=useRef(key);currentKey.current=key;
  const [result,setResult]=useState<{key:string;page?:PatientLinkPage;error?:string}>();
  useEffect(()=>{
    const controller=new AbortController();setResult(undefined);
    void (async()=>{
      try{
        const path=patientLinksPath(patientId,offset);
        const value=await api(path,{signal:controller.signal});
        if(controller.signal.aborted||currentKey.current!==key)return;
        const page=readPatientLinkPage(value,tenantId,patientId);
        if(!controller.signal.aborted&&currentKey.current===key)setResult({key,page});
      }catch(error){if(!controller.signal.aborted&&currentKey.current===key&&!isAbort(error))setResult({key,error:message(error)});}
    })();
    return()=>controller.abort();
  },[key,tenantId,patientId,offset]);
  const current=result?.key===key?result:undefined,next=nextPatientLinkOffset(offset);
  function reload(){setResult(undefined);setRefresh(value=>value+1);}
  function move(value:number){setResult(undefined);setOffset(value);}
  const heading=useRef<HTMLHeadingElement>(null);
  useEffect(()=>{heading.current?.focus();},[]);
  return <section className="patient-links" aria-labelledby="patient-links-heading">
    <Button variant="outline" onClick={onBack}>Volver a la ficha</Button>
    <h2 id="patient-links-heading" ref={heading} tabIndex={-1}>Vínculos del paciente</h2>
    <p className="patient-links-explanation">El estado corresponde al vínculo y no confirma el acceso actual al portal.</p>
    {!current&&<p role="status">Cargando vínculos...</p>}
    {current?.error&&<div role="alert" className="patient-message"><p>{current.error}</p><Button variant="outline" onClick={reload}>Volver a consultar vínculos</Button></div>}
    {current?.page&&<>
      {!current.page.rows.length?<p role="status">{offset===0?'Este paciente no tiene vínculos registrados':'No hay vínculos en esta página'}</p>:<ul className="patient-links-list" aria-label="Vínculos registrados">{current.page.rows.map(link=><li key={link.userId}>
        <h3>{link.userName||'Nombre sin registrar'}</h3>
        <dl><div><dt>Relación</dt><dd>{link.relationship||'Relación sin registrar'}</dd></div><div><dt>Estado del vínculo</dt><dd className="patient-link-state">{link.active?'Vínculo activo':'Vínculo inactivo'}</dd></div><div><dt>Alcances registrados</dt><dd>{link.scopes.length?<ul className="patient-link-scopes">{link.scopes.map((scope,index)=><li key={index}>{patientLinkScopeLabel(scope)}</li>)}</ul>:'Sin alcances registrados'}</dd></div></dl>
      </li>)}</ul>}
      <div className="patient-links-pagination"><span>Página {offset/20+1}</span><Button variant="outline" disabled={offset===0} onClick={()=>move(Math.max(0,offset-20))}>Anterior</Button><Button variant="outline" disabled={!current.page.hasNext||next===null} onClick={()=>{if(next!==null)move(next);}}>Siguiente</Button></div>
      <Button variant="outline" onClick={reload}>Volver a consultar vínculos</Button>
    </>}
  </section>;
}
