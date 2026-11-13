import {getTenant} from '@/lib/saas';
import {useDemo} from '@/store/demo';
import type {Patient} from '@/lib/patient-types';
type Row=Record<string,unknown>;
const KEY='health-cards-demo-v1';
export const reviewUserId='91000000-0000-4000-8000-000000000001';
export function reviewTenantId(){const index=useDemo.getState().data.organizations.findIndex(o=>o.id===useDemo.getState().context.org);return '92000000-0000-4000-8000-'+String(Math.max(index,0)+1).padStart(12,'0');}
export function reviewRuc(){const current=useDemo.getState();const tenant=getTenant(current.data,current.context.org);if(tenant?.ruc)return tenant.ruc;const index=useDemo.getState().data.organizations.findIndex(o=>o.id===useDemo.getState().context.org);return '200000000'+String(Math.max(index,0)+1).padStart(2,'0');}
export function reviewBranches(){const store=useDemo.getState();return (store.data.organizations.find(o=>o.id===store.context.org)?.branches||[]).map((b,i)=>({id:'93000000-0000-4000-8000-'+String(i+1).padStart(12,'0'),name:b.name,address:b.address}));}
interface State{services?:Row[];agreements?:Row[];patients:Patient[];antecedents:Row[];consultations:Row[];branchId:string|null;}
let memory:Record<string,State>={};
function state(){if(memory[reviewTenantId()])return memory[reviewTenantId()];try{memory=JSON.parse(localStorage.getItem(KEY)||'{}');}catch{/* optional demo storage */}return memory[reviewTenantId()]||seed();}
function seed(){const tenantId=reviewTenantId(),createdAt='2026-11-13T09:20:00.000Z',patientId='94000000-0000-4000-8000-000000000001';return memory[tenantId]={patients:[{id:patientId,tenantId,name:'Lucía Torres · ejemplo',identifier:'00000001',domain:'HUMAN',birthDate:'1992-05-14',species:null,contact:{phone:'000 000 000',email:'paciente@example.test'},allergies:[],revision:1,createdAt}],antecedents:[{id:'demo-ant-2',patientId,version:2,personal:'Asma intermitente desde la adolescencia. Sin hospitalizaciones recientes.',family:'Madre con hipertensión arterial.',allergies:'Sin alergias medicamentosas referidas.',medication:'Broncodilatador de rescate según indicación previa.',actorName:'Dra. Elena Vega · ejemplo',createdAt:'2026-11-13T14:35:00.000Z'},{id:'demo-ant-1',patientId,version:1,personal:'Refiere episodios ocasionales de dificultad respiratoria.',family:'Sin antecedentes familiares registrados.',allergies:'Pendiente de confirmar en entrevista.',medication:'Sin medicación registrada.',actorName:'Dr. Andrés Soto · ejemplo',createdAt:'2026-11-10T16:10:00.000Z'}],consultations:[],branchId:null};}
function save(){try{localStorage.setItem(KEY,JSON.stringify(memory));}catch{/* optional */}}
function fail(message:string,status=400):never{throw Object.assign(new Error(message),{status});}
export function reviewBranchId(){return state().branchId;}
export function mockCards(route:string,method:string,body:Row,params:URLSearchParams):{handled:boolean;value?:unknown}{
 const s=state(),tenant=reviewTenantId(),user=useDemo.getState().context.role;
 const done=(value:unknown)=>({handled:true,value});
 if(route.startsWith('/v1/catalogo/')){const isService=route.endsWith('/servicios');const list=isService?(s.services??=[{id:'demo-service-1',name:'Consulta general',priceMinor:8000,active:true,revision:1},{id:'demo-service-2',name:'Control de seguimiento',priceMinor:5000,active:true,revision:1}]):(s.agreements??=[{id:'demo-agreement-1',name:'Convenio de ejemplo',discountPercent:10,active:true,revision:1}]);if(method==='GET')return done(list);if(method==='POST'){if(user!=='ADM')fail('Se requiere permiso de administrador.',403);const prior=list.find(row=>row.id===body.id);if(Number(prior?.revision||0)!==body.expectedRevision)fail('El catalogo cambio. Recarga.',409);const row={...body,revision:Number(body.expectedRevision)+1,...(isService?{priceMinor:body.value}:{discountPercent:body.value})};if(prior)Object.assign(prior,row);else list.push(row);save();return done(row);}}

 if(route==='/v1/auth/login'&&method==='POST'){
  if(body.ruc!==reviewRuc()||!body.email||!body.password)fail('Revisa el RUC, el correo y la contraseña ficticios.',401);
  const branches=reviewBranches();s.branchId=branches.length===1?branches[0].id:null;save();return done({branches,branchId:s.branchId,requiresBranchSelection:branches.length>1});
 }
 if(/^\/v1\/negocios\/[0-9]{11}\/sucursales$/.test(route)&&method==='GET'){if(route.split('/')[3]!==reviewRuc())fail('El RUC no corresponde a este espacio.',403);return done(reviewBranches());}
 if(route==='/v1/auth/sucursal'&&method==='POST'){if(!reviewBranches().some(b=>b.id===body.branchId))fail('Sucursal no autorizada.',403);s.branchId=String(body.branchId);save();return done({branchId:s.branchId,permissions:[user]});}
 if(route==='/v1/pacientes/directorio'&&method==='GET'){const dni=params.get('dni')||'';return done(s.patients.filter(p=>p.identifier.startsWith(dni)));}
 if(route==='/appointments'&&method==='GET')return done([]);
 if(route==='/patients'&&method==='GET'){const query=(params.get('query')||'').toLowerCase();return done(s.patients.filter(p=>(p.name+' '+p.identifier).toLowerCase().includes(query)).slice(Number(params.get('offset')||0),Number(params.get('offset')||0)+Number(params.get('limit')||21)));}
 if(route==='/patients'&&method==='POST'){if(s.patients.some(p=>p.identifier===body.identifier))fail('Este identificador ya está registrado.',409);const p={...body,id:crypto.randomUUID(),tenantId:tenant,revision:1,createdAt:new Date().toISOString()} as unknown as Patient;s.patients.push(p);save();return done(p);}
 const p=/^\/patients\/([^/]+)$/.exec(route);if(p){const index=s.patients.findIndex(row=>row.id===p[1]);if(index<0)fail('Paciente no encontrado.',404);if(method==='GET')return done(s.patients[index]);if(method==='PUT'){if(body.expectedRevision!==s.patients[index].revision)fail('La ficha cambió.',409);s.patients[index]={...s.patients[index],...body.patient as Patient,revision:s.patients[index].revision+1};save();return done(s.patients[index]);}}
 const history=/^\/v1\/pacientes\/([^/]+)\/(antecedentes|consultas)$/.exec(route);
 if(history){if(!s.patients.some(p=>p.id===history[1]))fail('Paciente no encontrado.',404);const list=history[2]==='antecedentes'?s.antecedents:s.consultations;
  if(method==='GET')return done(list.filter(row=>row.patientId===history[1]));
  if(method==='POST'&&history[2]==='antecedentes'){if(user!=='PRO')fail('Se requiere permiso profesional.',403);const version=Number(list.find(row=>row.patientId===history[1])?.version||0);if(body.expectedVersion!==version)fail('Los antecedentes cambiaron. Recarga.',409);const row={...body,id:crypto.randomUUID(),patientId:history[1],version:version+1,actorName:'Dra. Elena Vega · ejemplo',createdAt:new Date().toISOString()};list.unshift(row);save();return done(row);}
 }
 if(route==='/v1/consultas'&&method==='POST'){if(user!=='PRO'||!s.branchId||s.branchId!==body.branchId)fail('Selecciona una sucursal autorizada.',403);const prior=s.consultations.find(c=>c.id===body.requestId);if(prior)return done(prior);const row={...body,id:body.requestId,branchName:reviewBranches().find(b=>b.id===s.branchId)?.name,professionalName:'Dra. Elena Vega · ejemplo',createdAt:new Date().toISOString()};s.consultations.unshift(row);save();return done(row);}
 return {handled:false};
}
