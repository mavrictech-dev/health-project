export type PatientDomain = 'HUMAN' | 'ANIMAL';
export interface PatientInput { name:string; domain:PatientDomain; identifier:string; birthDate:string|null; species:string|null; contact:Record<string,unknown>; allergies:string[] }
export interface Patient extends PatientInput { id:string; tenantId:string; revision:number; createdAt:string }
export interface PatientDraft { name:string; identifier:string; phone:string; email:string; birthDate:string; species:string }
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const object=(v:unknown):v is Record<string,unknown>=>v!==null&&typeof v==='object'&&!Array.isArray(v);
function invalid():never {throw new Error('La respuesta de pacientes no es válida para este espacio. Vuelve a consultar.');}
export function patientAccess(user:{id:string;tenantId?:string|null;roles:string[]}|null,host:{platform:boolean;id?:string;domain?:string}|null,write=false){
  return !!user&&!!host&&!host.platform&&!!host.id&&uuid.test(host.id)&&uuid.test(user.id)&&user.tenantId===host.id&&['HUMAN','ANIMAL'].includes(host.domain||'')&&!user.roles.some(r=>['SAD','SOP','PAC','RES'].includes(r))&&user.roles.some(r=>(write?['ADM','REC','PRO']:['ADM','REC','PRO','ASI','AUD']).includes(r));
}
function validDate(value:unknown):value is string {if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value)||value<'0001-01-01')return false;const date=new Date(value+'T00:00:00Z');return Number.isFinite(date.getTime())&&date.toISOString().slice(0,10)===value;}
export function readPatient(value:unknown,tenantId:string,domain:PatientDomain,id?:string):Patient {
  if(!object(value)||typeof value.id!=='string'||!uuid.test(value.id)||value.tenantId!==tenantId||value.domain!==domain||(id!==undefined&&id!==value.id)||typeof value.name!=='string'||!value.name.trim()||value.name.length>160||typeof value.identifier!=='string'||!value.identifier.trim()||value.identifier.length>100||!(value.birthDate===null||validDate(value.birthDate))||!(value.species===null||typeof value.species==='string'&&value.species.length<=80)||!object(value.contact)||!Array.isArray(value.allergies)||!value.allergies.every(v=>typeof v==='string'&&v.length<=160)||!Number.isSafeInteger(value.revision)||Number(value.revision)<1||typeof value.createdAt!=='string'||!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z$/.test(value.createdAt)||!validDate(value.createdAt.slice(0,10))||!Number.isFinite(Date.parse(value.createdAt)))invalid();
  return value as unknown as Patient;
}
export function readPatientPage(value:unknown,tenantId:string,domain:PatientDomain){
  if(!Array.isArray(value)||value.length>21)invalid();
  const rows=value.map(v=>readPatient(v,tenantId,domain));if(new Set(rows.map(v=>v.id)).size!==rows.length)invalid();
  return {rows:rows.slice(0,20),hasNext:rows.length===21};
}
export function patientListPath(query:string,offset:number){return '/patients?'+new URLSearchParams({query,limit:'21',offset:String(offset)});}
export function patientDraft(patient?:Patient):PatientDraft {return {name:patient?.name||'',identifier:patient?.identifier||'',phone:typeof patient?.contact.phone==='string'?patient.contact.phone:'',email:typeof patient?.contact.email==='string'?patient.contact.email:'',birthDate:patient?.birthDate||'',species:patient?.species||''};}
export function buildPatientInput(draft:PatientDraft,domain:PatientDomain,original?:Patient):PatientInput {
  const name=draft.name.trim(),identifier=draft.identifier.trim();
  if(!name||name.length>160||!identifier||identifier.length>100)throw new Error('Revisa el nombre y el identificador.');
  if(draft.birthDate&&(!validDate(draft.birthDate)||draft.birthDate>new Date().toISOString().slice(0,10)))throw new Error('Revisa la fecha de nacimiento; no puede estar en el futuro.');
  if(draft.species.length>80||domain==='ANIMAL'&&!draft.species.trim())throw new Error('Indica la especie (máximo 80 caracteres).');
  const contact={...original?.contact};
  for(const key of ['phone','email'] as const){const before=original?.contact[key];if(draft[key]!== (typeof before==='string'?before:''))contact[key]=draft[key];}
  return {name,identifier,domain,birthDate:draft.birthDate||null,species:domain==='ANIMAL'?draft.species:original?.species??null,contact,allergies:[...original?.allergies||[]]};
}
export function patientWriteBody(input:PatientInput,original?:Patient){return original?{expectedRevision:original.revision,patient:input}:input;}
export function ambiguousPatientStatus(status:number){return status===0||status>=500||status>=200&&status<300;}
