import {tenantKinds,type TenantDraft,type TenantKind,type PatientDomain,type PlatformPlan,type PlatformSpecialty,type TenantRequest,type TenantReview} from './platform-types';
const reserved = new Set(['www','admin','api','app','saas','mail','support','status','auth','portal','localhost']);
export function emptyTenantDraft():TenantDraft {
  return {name:'',slug:'',kind:'CLINIC',domain:'HUMAN',ownerName:'',ownerEmail:'',password:'',credential:'',timezone:'America/Lima',branchName:'Sede principal',address:'',specialties:[],planId:'',cycle:'MONTHLY',branchQuota:'1',professionalQuota:'1',specialtyQuota:'1'};
}
export function compatibleDomain(kind:TenantKind,domain:PatientDomain) {return kind==='DOCTOR' || (kind==='VETERINARY'?domain==='ANIMAL':domain==='HUMAN');}
export function compatiblePlans(plans:PlatformPlan[],kind:TenantKind,domain:PatientDomain) {
  return plans.filter(p=>compatibleDomain(kind,domain)&&p.status==='PUBLISHED'&&p.kinds.includes(kind)&&p.domains.includes(domain)&&(kind!=='DENTAL'||p.modules.includes('DENTAL')));
}
export function compatibleSpecialties(catalog:PlatformSpecialty[],kind:TenantKind,domain:PatientDomain,plan:PlatformPlan|undefined) {
  return catalog.filter(s=>compatibleDomain(kind,domain)&&s.domain===domain&&(kind!=='DENTAL'||s.dental)&&(!s.dental||!!plan?.modules.includes('DENTAL')));
}
function text(value:string,label:string,max:number) {const v=value.trim();if(!v||v.length>max)throw Error(`Revisa ${label}.`);return v;}
function quota(value:string,min:number,max:number,label:string) {if(!/^\d+$/.test(value)||!Number.isSafeInteger(Number(value))||Number(value)<min||Number(value)>max)throw Error(`${label}: usa un entero entre ${min} y ${max}.`);return Number(value);}
export function buildTenantRequest(draft:TenantDraft,plans:PlatformPlan[],catalog:PlatformSpecialty[]):TenantRequest {
  if(!tenantKinds.includes(draft.kind)||!['HUMAN','ANIMAL'].includes(draft.domain)||!compatibleDomain(draft.kind,draft.domain))throw Error('El tipo de cliente y el ámbito no son compatibles.');
  const name=text(draft.name,'el nombre del cliente',160),slug=draft.slug.trim();
  if(slug.length>63||!slug.match(/^[a-z0-9]+(-[a-z0-9]+)*$/)||reserved.has(slug))throw Error('El subdominio debe usar minúsculas, números y guiones, sin nombres reservados.');
  const plan=compatiblePlans(plans,draft.kind,draft.domain).find(p=>p.planId===draft.planId);if(!plan)throw Error('Selecciona una oferta publicada compatible.');
  if(!['MONTHLY','YEARLY'].includes(draft.cycle))throw Error('Selecciona un ciclo mensual o anual.');
  const branchQuota=quota(draft.branchQuota,Math.max(1,plan.includedBranches),Math.min(10000,plan.maxBranches),'Cupo de sedes');
  const professionalQuota=quota(draft.professionalQuota,Math.max(1,plan.includedProfessionals),Math.min(100000,plan.maxProfessionals),'Cupo de profesionales');
  const specialtyQuota=quota(draft.specialtyQuota,1,Math.min(241,plan.maxSpecialties),'Cupo de especialidades');
  if(draft.kind==='DOCTOR'&&professionalQuota!==1)throw Error('El profesional independiente conserva una identidad clínica.');
  const specialties=[...new Set(draft.specialties)];
  if(!specialties.length||specialties.length>specialtyQuota)throw Error('Selecciona al menos una especialidad, dentro del cupo contratado.');
  const allowed=new Set(compatibleSpecialties(catalog,draft.kind,draft.domain,plan).map(s=>s.code));
  if(specialties.some(code=>!allowed.has(code)))throw Error('Hay especialidades incompatibles con el ámbito o los módulos de la oferta.');
  const timezone=text(draft.timezone,'la zona horaria',100);
  try{new Intl.DateTimeFormat('es',{timeZone:timezone});}catch{throw Error('Revisa la zona horaria; por ejemplo, America/Lima.');}
  const ownerName=text(draft.ownerName,'el nombre del propietario',160),email=text(draft.ownerEmail,'el correo del propietario',254).toLowerCase();
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))throw Error('Revisa el correo del propietario.');
  if(draft.password.length<12||new TextEncoder().encode(draft.password).length>72)throw Error('La contraseña inicial necesita al menos 12 caracteres y como máximo 72 bytes.');
  if(draft.credential.trim().length>100)throw Error('La acreditación profesional admite hasta 100 caracteres.');
  if(draft.address.length>300)throw Error('La dirección admite hasta 300 caracteres.');
  return {name,slug,kind:draft.kind,domain:draft.domain,owner:{name:ownerName,email,password:draft.password,domain:draft.kind==='DOCTOR'?draft.domain:null,credential:draft.credential.trim()||null},timezone,branchName:text(draft.branchName,'el nombre de la primera sede',160),address:draft.address.trim(),specialties,subscription:{planId:plan.planId,cycle:draft.cycle,branchQuota,professionalQuota,specialtyQuota}};
}
export function tenantReview(draft:TenantDraft,plans:PlatformPlan[],catalog:PlatformSpecialty[]):TenantReview {
  const request=buildTenantRequest(draft,plans,catalog);
  return {name:request.name,slug:request.slug,kind:request.kind,domain:request.domain,owner:{name:request.owner.name,email:request.owner.email,domain:request.owner.domain,credential:request.owner.credential},timezone:request.timezone,branchName:request.branchName,address:request.address,specialties:request.specialties,subscription:request.subscription};
}
export function ambiguousCreateStatus(status:number) {return status===0||status>=500||(status>=200&&status<300);}
export function money(value:number) {return new Intl.NumberFormat('es-PE',{style:'currency',currency:'PEN'}).format(value/100);}
export function cycleLabel(value:string) {return value==='YEARLY'?'Anual':value==='MONTHLY'?'Mensual':value;}
export function statusLabel(value:string) {return ({TRIAL:'Prueba',ACTIVE:'Activo',SUSPENDED:'Suspendido',CANCELLED:'Cancelado',PENDING:'Pendiente',PAID:'Pagado'} as Record<string,string>)[value]||value;}
