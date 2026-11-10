import {patientAccess} from './patient-types';

export interface PatientLink {
  readonly tenantId:string; readonly patientId:string; readonly userId:string;
  readonly userName:string; readonly relationship:string; readonly active:boolean;
  readonly scopes:readonly string[];
}
export interface PatientLinkPage {readonly rows:readonly PatientLink[];readonly hasNext:boolean}
const canonical=(value:unknown):value is string=>typeof value==='string'&&value.length===36&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(value);
const maxOffset=2147483647;
function invalid():never {throw new Error('No se pudo validar la respuesta de vínculos.');}
export function patientLinksAccess(user:Parameters<typeof patientAccess>[0],host:Parameters<typeof patientAccess>[1]){
  return patientAccess(user,host)&&!!user&&canonical(user.id)&&canonical(host?.id)&&user.roles.some(role=>role==='ADM'||role==='REC');
}
function validOffset(offset:number){return Number.isInteger(offset)&&offset>=0&&offset<=maxOffset;}
export function patientLinksPath(patientId:string,offset:number){
  if(!canonical(patientId)||!validOffset(offset))invalid();
  return '/patients/'+patientId+'/links?'+new URLSearchParams({limit:'21',offset:String(offset)});
}
export function nextPatientLinkOffset(offset:number):number|null {
  if(!validOffset(offset))invalid();
  return offset<=maxOffset-20?offset+20:null;
}
export function readPatientLinkPage(value:unknown,tenantId:string,patientId:string):PatientLinkPage {
  if(!canonical(tenantId)||!canonical(patientId)||!Array.isArray(value)||value.length>21)invalid();
  const users=new Set<string>();
  const rows=Array.from(value,(item:unknown):PatientLink=>{
    if(item===null||typeof item!=='object'||Array.isArray(item))invalid();
    const row=item as Record<string,unknown>;
    if(row.tenantId!==tenantId||row.patientId!==patientId||!canonical(row.userId)||users.has(row.userId)||typeof row.userName!=='string'||row.userName.length>160||typeof row.relationship!=='string'||row.relationship.length>80||typeof row.active!=='boolean'||!Array.isArray(row.scopes))invalid();
    users.add(row.userId);
    const scopes=Object.freeze(Array.from(row.scopes,(scope:unknown)=>{if(typeof scope!=='string')invalid();return scope;}));
    return Object.freeze({tenantId,patientId,userId:row.userId,userName:row.userName,relationship:row.relationship,active:row.active,scopes});
  });
  return Object.freeze({rows:Object.freeze(rows.slice(0,20)),hasNext:rows.length===21});
}
export function patientLinkScopeLabel(scope:string){
  switch(scope){case 'APPOINTMENTS':return 'Citas';case 'DOCUMENTS':return 'Documentos';case 'BILLING':return 'Facturación';default:return 'Referencia histórica: '+(scope||'(vacía)');}
}
