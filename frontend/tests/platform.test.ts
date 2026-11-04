import test from 'node:test';
import assert from 'node:assert/strict';
import {ambiguousCreateStatus,buildTenantRequest,compatiblePlans,compatibleSpecialties,emptyTenantDraft,tenantReview} from '../src/lib/platform';
import type {PlatformPlan,PlatformSpecialty,TenantDraft} from '../src/lib/platform-types';
const plan:PlatformPlan={planId:'plan-live',name:'Oferta configurada',description:'Fixture sintética',status:'PUBLISHED',version:7,kinds:['DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER'],domains:['HUMAN','ANIMAL'],modules:['CORE','DENTAL'],includedBranches:2,includedProfessionals:1,includedSpecialties:3,maxBranches:4,maxProfessionals:8,maxSpecialties:5,baseMinor:10000,branchMinor:2000,professionalMinor:1000,annualDiscount:15};
const catalog:PlatformSpecialty[]=[{code:'H_GENERAL',name:'Medicina general',domain:'HUMAN',dental:false},{code:'H_CARDIO',name:'Cardiología',domain:'HUMAN',dental:false},{code:'D_GENERAL',name:'Odontología',domain:'HUMAN',dental:true},{code:'V_GENERAL',name:'Veterinaria',domain:'ANIMAL',dental:false}];
const draft=():TenantDraft=>({...emptyTenantDraft(),name:' Clínica sintética ',slug:'clinica-sintetica',ownerName:' Propietaria sintética ',ownerEmail:'OWNER@EXAMPLE.TEST',password:'SyntheticOnly123!',planId:plan.planId,branchQuota:'2',professionalQuota:'1',specialtyQuota:'3',specialties:['H_GENERAL'],address:' Dirección sintética '});

test('Tenant DTO matches the new-owner Java variant and does not carry demo/pricing/revision fields',()=>{
  const input=Object.assign(draft(),{tenantId:'must-not-leak',ownerUserId:'must-not-leak',expectedRevision:2,price:1});
  const output=buildTenantRequest(input,[plan],catalog);
  assert.deepEqual(Object.keys(output).sort(),['name','slug','kind','domain','owner','timezone','branchName','address','specialties','subscription'].sort());
  assert.deepEqual(output.owner,{name:'Propietaria sintética',email:'owner@example.test',password:'SyntheticOnly123!',domain:null,credential:null});
  assert.deepEqual(output.subscription,{planId:'plan-live',cycle:'MONTHLY',branchQuota:2,professionalQuota:1,specialtyQuota:3});
  assert.deepEqual(output.specialties,['H_GENERAL']);assert.equal(output.timezone,'America/Lima');assert.equal(output.address,'Dirección sintética');
  assert.equal(output.name,'Clínica sintética');assert.equal(input.name,' Clínica sintética ');
});
test('published offers must match kind/domain and odontological module',()=>{
  const offers:PlatformPlan[]=[plan,{...plan,planId:'draft',status:'DRAFT'},{...plan,planId:'archived',status:'ARCHIVED'},{...plan,planId:'animal-only',domains:['ANIMAL']},{...plan,planId:'core-only',modules:['CORE']}];
  assert.deepEqual(compatiblePlans(offers,'DENTAL','HUMAN').map(p=>p.planId),['plan-live']);
  assert.deepEqual(compatiblePlans(offers,'HOSPITAL','ANIMAL'),[]);
  assert.throws(()=>buildTenantRequest({...draft(),planId:'draft'},offers,catalog),/publicada/);
});
test('specialty filtering respects domains, DENTAL kind and included module without activating profiles',()=>{
  assert.deepEqual(compatibleSpecialties(catalog,'DENTAL','HUMAN',plan).map(s=>s.code),['D_GENERAL']);
  assert.deepEqual(compatibleSpecialties(catalog,'CLINIC','HUMAN',{...plan,modules:['CORE']}).map(s=>s.code),['H_GENERAL','H_CARDIO']);
  assert.deepEqual(compatibleSpecialties(catalog,'VETERINARY','ANIMAL',plan).map(s=>s.code),['V_GENERAL']);
  assert.deepEqual(emptyTenantDraft().specialties,[]);
  assert.throws(()=>buildTenantRequest({...draft(),specialties:['V_GENERAL']},[plan],catalog),/incompatibles/);
  assert.throws(()=>buildTenantRequest({...draft(),specialties:['UNKNOWN']},[plan],catalog),/incompatibles/);
  assert.throws(()=>buildTenantRequest({...draft(),specialties:['D_GENERAL']},[{...plan,modules:['CORE']}],catalog),/incompatibles/);
});
test('quotas enforce included minima, configured maxima, integer syntax and actual selected usage',()=>{
  for(const value of ['0','1','5','2.5','1e2','NaN','-1',''])assert.throws(()=>buildTenantRequest({...draft(),branchQuota:value},[plan],catalog),/Cupo de sedes/);
  assert.throws(()=>buildTenantRequest({...draft(),professionalQuota:'9'},[plan],catalog),/Cupo de profesionales/);
  assert.throws(()=>buildTenantRequest({...draft(),specialtyQuota:'6'},[plan],catalog),/Cupo de especialidades/);
  assert.throws(()=>buildTenantRequest({...draft(),specialtyQuota:'1',specialties:['H_GENERAL','H_CARDIO']},[plan],catalog),/cupo contratado/);
  assert.throws(()=>buildTenantRequest({...draft(),specialties:[]},[plan],catalog),/al menos/);
  assert.deepEqual(buildTenantRequest({...draft(),specialties:['H_GENERAL','H_GENERAL']},[plan],catalog).specialties,['H_GENERAL']);
});
test('DOCTOR has one clinical identity and owner clinical domain matches tenant',()=>{
  const result=buildTenantRequest({...draft(),kind:'DOCTOR',domain:'ANIMAL',specialties:['V_GENERAL'],credential:'VET-TEST'},[plan],catalog);
  assert.equal(result.owner.domain,'ANIMAL');assert.equal(result.owner.credential,'VET-TEST');
  assert.throws(()=>buildTenantRequest({...draft(),kind:'DOCTOR',professionalQuota:'2'},[plan],catalog),/una identidad/);
  assert.throws(()=>buildTenantRequest({...draft(),kind:'CLINIC',domain:'ANIMAL'},[plan],catalog),/no son compatibles/);
});
test('enum values are backend values and annual cycle is YEARLY',()=>{
  assert.equal(buildTenantRequest({...draft(),cycle:'YEARLY'},[plan],catalog).subscription.cycle,'YEARLY');
  assert.throws(()=>buildTenantRequest({...draft(),cycle:'ANNUAL' as TenantDraft['cycle']},[plan],catalog),/ciclo/);
  assert.throws(()=>buildTenantRequest({...draft(),kind:'HOSPITAL_DEMO' as TenantDraft['kind']},[plan],catalog),/tipo/);
});
test('empty/short passwords and UTF8 byte overflow are rejected without echoing the password',()=>{
  assert.equal(emptyTenantDraft().password,'');
  for(const password of ['', 'short', 'é'.repeat(37)])assert.throws(()=>buildTenantRequest({...draft(),password},[plan],catalog),/12 caracteres.*72 bytes/);
  assert.throws(()=>buildTenantRequest({...draft(),ownerEmail:'not-an-email'},[plan],catalog),/correo/);
  assert.throws(()=>buildTenantRequest({...draft(),timezone:'Invalid/Zone'},[plan],catalog),/zona horaria/);
});
test('review contains no password, extra owner ID, or mutable reference to selected specialties',()=>{
  const input=draft(),review=tenantReview(input,[plan],catalog),serialized=JSON.stringify(review);
  assert.equal(serialized.includes(input.password),false);assert.equal(serialized.includes('password'),false);assert.equal('ownerUserId' in review,false);
  review.specialties.push('H_CARDIO');assert.deepEqual(input.specialties,['H_GENERAL']);assert.equal(input.password,'SyntheticOnly123!');
});
test('reserved slugs, invalid lengths and ambiguous transport outcomes are handled explicitly',()=>{
  for(const slug of ['admin','www','auth','portal','Upper','-bad','bad-','nested.name','a'.repeat(64)])assert.throws(()=>buildTenantRequest({...draft(),slug},[plan],catalog),/subdominio/);
  assert.throws(()=>buildTenantRequest({...draft(),branchName:''},[plan],catalog),/primera sede/);
  assert.throws(()=>buildTenantRequest({...draft(),address:'x'.repeat(301)},[plan],catalog),/dirección/);
  for(const status of [0,200,201,500,503])assert.equal(ambiguousCreateStatus(status),true);
  for(const status of [400,403,409])assert.equal(ambiguousCreateStatus(status),false);
});
