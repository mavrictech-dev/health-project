/** Read-only projection of OrganizationService.configuration; no demo identities. */
export interface OrganizationBranch { id:string; name:string; address:string; external:boolean; active:boolean }
export const organizationRoleLabels = {ADM:'Administración',REC:'Recepción',PRO:'Profesional',ASI:'Asistencia',DIA:'Diagnóstico',FAR:'Farmacia',CAJ:'Caja',ALM:'Almacén',PAC:'Paciente',RES:'Responsable',AUD:'Auditoría'} as const;
export type OrganizationRole = keyof typeof organizationRoleLabels;
export const organizationStatusLabels = {ACTIVE:'Activo',INVITED:'Invitado',INACTIVE:'Inactivo'} as const;
export interface OrganizationMember {
  id:string; name:string; roles:OrganizationRole[]; status:keyof typeof organizationStatusLabels;
  owner:boolean; branches:string[]; specialties:string[];
}
export interface OrganizationSpecialty { code:string; name:string; domain:'HUMAN'|'ANIMAL'; dental:boolean }
export interface OrganizationConfiguration {
  tenantId:string; name:string; branchQuota:number; professionalQuota:number;
  branches:OrganizationBranch[]; members:OrganizationMember[]; specialties:OrganizationSpecialty[];
}
export interface BranchDraft { name:string; address:string }
/** Requests.Branch, creation of an active, owned branch only. */
export interface BranchRequest { name:string; address:string; external:false; active:true }
export function buildBranchRequest(draft:BranchDraft):BranchRequest {
  const name=draft.name.trim(),address=draft.address.trim();
  if(!name||name.length>160)throw Error('El nombre de la sede debe tener entre 1 y 160 caracteres.');
  if(address.length>300)throw Error('La dirección admite hasta 300 caracteres.');
  return {name,address,external:false,active:true};
}
const invalid=()=>Error('La configuración recibida no es válida para esta organización. Vuelve a consultarla.');
function record(value:unknown):Record<string,unknown> {
  if(!value||typeof value!=='object'||Array.isArray(value))throw invalid();
  return value as Record<string,unknown>;
}
function field(value:unknown):string { if(typeof value!=='string')throw invalid();return value; }
function nonblank(value:unknown):string { const text=field(value);if(!text.trim())throw invalid();return text; }
function references(value:unknown):string[] {
  if(!Array.isArray(value))throw invalid();
  const values=value.map(nonblank);
  if(new Set(values).size!==values.length)throw invalid();
  return values;
}
function flag(value:unknown):boolean {
  if(value===true||value===1)return true;
  if(value===false||value===0)return false;
  throw invalid();
}
function quota(value:unknown):number { if(typeof value!=='number'||!Number.isSafeInteger(value)||value<0)throw invalid();return value; }
export function readOrganizationBranch(value:unknown):OrganizationBranch {
  const row=record(value),id=field(row.id),name=field(row.name);
  if(!id||!name.trim())throw invalid();
  return {id,name,address:field(row.address),external:flag(row.external),active:flag(row.active)};
}
export function readOrganizationConfiguration(value:unknown,tenantId:string):OrganizationConfiguration {
  const row=record(value);
  if(!tenantId||row.tenantId!==tenantId||!Array.isArray(row.branches)||!Array.isArray(row.members)||!Array.isArray(row.specialties))throw invalid();
  const branches=row.branches.map(readOrganizationBranch);
  const specialties=row.specialties.map(value=>{
    const specialty=record(value);
    if(specialty.domain!=='HUMAN'&&specialty.domain!=='ANIMAL')throw invalid();
    return {code:nonblank(specialty.code),name:nonblank(specialty.name),domain:specialty.domain,dental:flag(specialty.dental)} as OrganizationSpecialty;
  });
  const members=row.members.map(value=>{
    const member=record(value),id=nonblank(member.id),name=nonblank(member.name),status=field(member.status),roles=references(member.roles);
    if(!roles.length||!roles.every(role=>Object.hasOwn(organizationRoleLabels,role))||!Object.hasOwn(organizationStatusLabels,status))throw invalid();
    // Validate the backend shape, then discard personal contact/credential fields.
    field(member.email);
    if(member.clinicalDomain!==null&&member.clinicalDomain!=='HUMAN'&&member.clinicalDomain!=='ANIMAL')throw invalid();
    if(member.credential!==null)field(member.credential);
    return {id,name,status:status as OrganizationMember['status'],roles:roles as OrganizationRole[],owner:flag(member.owner),branches:references(member.branches),specialties:references(member.specialties)};
  });
  if(new Set(branches.map(b=>b.id)).size!==branches.length||new Set(members.map(m=>m.id)).size!==members.length||new Set(specialties.map(s=>s.code)).size!==specialties.length)throw invalid();
  return {tenantId,name:nonblank(row.name),branchQuota:quota(row.branchQuota),professionalQuota:quota(row.professionalQuota),branches,members,specialties};
}
/** Display projection excludes contact data, credentials and assignment identifiers. */
export function organizationMemberView(member:OrganizationMember,config:OrganizationConfiguration) {
  return {
    name:member.name,owner:member.owner,roles:member.roles.map(role=>organizationRoleLabels[role]),status:organizationStatusLabels[member.status],
    branches:member.branches.map(id=>{const branch=config.branches.find(b=>b.id===id);return branch?branch.name+(!branch.active?' · Inactiva':''):'Sede no disponible';}),
    specialties:member.specialties.map(code=>config.specialties.find(s=>s.code===code)?.name||'Especialidad no disponible'),
  };
}
/** Matches the capacity predicates in sp_subscription_validate/sp_member_save. */
export function organizationUsage(config:OrganizationConfiguration) {
  const branches=config.branches.filter(branch=>branch.active&&!branch.external).length;
  const professionals=config.members.filter(member=>member.status!=='INACTIVE'&&member.roles.includes('PRO')).length;
  return {branches,professionals,branchesRemaining:Math.max(0,config.branchQuota-branches),professionalsRemaining:Math.max(0,config.professionalQuota-professionals)};
}
export function ambiguousBranchStatus(status:number) { return status===0||status>=500||status>=200&&status<300; }
