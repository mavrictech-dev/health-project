import test from 'node:test';
import assert from 'node:assert/strict';
import {patientAccess,readPatient,readPatientPage,patientDraft,buildPatientInput,patientWriteBody,patientListPath,ambiguousPatientStatus,type Patient} from '../src/lib/patient-types';
const tenant='11111111-1111-1111-1111-111111111111',id='22222222-2222-2222-2222-222222222222';
const host={platform:false,id:tenant,domain:'HUMAN'};
const fixture=():Patient=>({id,tenantId:tenant,name:'Contrato sintético',identifier:'TEST',domain:'HUMAN',birthDate:'2000-01-01',species:'preservada',contact:{phone:'123',email:'test@example.test',extra:{language:'es'},alternate:[1,true]},allergies:['A'],revision:7,createdAt:'2026-01-01T00:00:00Z'});
test('patient permissions require canonical identity, tenant, host domain and internal roles',()=>{
 for(const role of ['ADM','REC','PRO','ASI','AUD']){const user={id,tenantId:tenant,roles:[role]};assert.equal(patientAccess(user,host),true);assert.equal(patientAccess(user,host,true),['ADM','REC','PRO'].includes(role));}
 for(const role of ['SAD','SOP','PAC','RES','CAJ','unknown'])assert.equal(patientAccess({id,tenantId:tenant,roles:[role]},host),false);
 for(const role of ['SAD','SOP','PAC','RES'])assert.equal(patientAccess({id,tenantId:tenant,roles:['ADM',role]},host),false);
 for(const invalid of [{...host,platform:true},{...host,id},{...host,domain:undefined}])assert.equal(patientAccess({id,tenantId:tenant,roles:['ADM']},invalid),false);
 assert.equal(patientAccess({id:'bad',tenantId:tenant,roles:['ADM']},host),false);
});
test('patient response validates camelCase shape, identity, tenant and domain before display',()=>{
 const p=fixture();assert.equal(readPatient(p,tenant,'HUMAN',id),p);
 for(const delta of [{id:'bad'},{tenantId:id},{domain:'ANIMAL'},{birthDate:'2026-02-30'},{birthDate:'broken'},{revision:0},{revision:1.5},{allergies:[12]},{contact:[]},{createdAt:'bad'},{createdAt:'2026Z'},{createdAt:'2026-02-30T00:00:00Z'},{identifier:''},{species:22}])assert.throws(()=>readPatient({...p,...delta},tenant,'HUMAN',id));
 assert.throws(()=>readPatient(p,tenant,'HUMAN',tenant));assert.throws(()=>readPatient({patient:p},tenant,'HUMAN'));
});
test('lookahead page requests 21, displays 20, advances by 20 and never invents total',()=>{
 const rows=Array.from({length:21},(_,i)=>({...fixture(),id:`22222222-2222-2222-2222-${String(i).padStart(12,'0')}`}));
 assert.equal(readPatientPage(rows,tenant,'HUMAN').rows.length,20);assert.equal(readPatientPage(rows,tenant,'HUMAN').hasNext,true);assert.equal(readPatientPage(rows.slice(0,20),tenant,'HUMAN').hasNext,false);assert.deepEqual(readPatientPage([],tenant,'HUMAN'),{rows:[],hasNext:false});
 assert.throws(()=>readPatientPage([...rows,rows[0]],tenant,'HUMAN'));assert.throws(()=>readPatientPage([rows[0],rows[0]],tenant,'HUMAN'));assert.throws(()=>readPatientPage({items:rows,total:21},tenant,'HUMAN'));
 const url=new URL(patientListPath('a & b',20),'https://example.test');assert.equal(url.searchParams.get('query'),'a & b');assert.equal(url.searchParams.get('offset'),'20');assert.equal(url.searchParams.get('limit'),'21');
});
test('editing preserves unknown contact, allergies, date, species and original revision without server fields',()=>{
 const p=fixture(),draft=patientDraft(p);draft.phone='456';const input=buildPatientInput(draft,'HUMAN',p);
 assert.deepEqual(input.contact,{...p.contact,phone:'456'});assert.deepEqual(input.allergies,p.allergies);assert.equal(input.birthDate,p.birthDate);assert.equal(input.species,p.species);
 assert.deepEqual(patientWriteBody(input,p),{expectedRevision:7,patient:input});assert.equal(p.revision,7);assert.equal('tenantId' in input,false);assert.equal('id' in input,false);assert.equal('revision' in input,false);
 const odd={...p,contact:{phone:{legacy:true},extra:5}};assert.deepEqual(buildPatientInput(patientDraft(odd),'HUMAN',odd).contact,odd.contact);
});
test('draft validation honors domain and future date; create ambiguity blocks retry',()=>{
 const draft={...patientDraft(),name:' Test ',identifier:' ID '};assert.equal(buildPatientInput(draft,'HUMAN').name,'Test');assert.throws(()=>buildPatientInput(draft,'ANIMAL'));assert.equal(buildPatientInput({...draft,species:'Canino'},'ANIMAL').species,'Canino');assert.throws(()=>buildPatientInput({...draft,birthDate:'2999-01-01'},'HUMAN'));
 for(const status of [0,200,201,500,503])assert.equal(ambiguousPatientStatus(status),true);for(const status of [400,401,403,409,422])assert.equal(ambiguousPatientStatus(status),false);
});
import {api,ApiError,setCsrf} from '../src/lib/api';

test('POST409 distinguishes confirmed JSON rejection from an unreadable result without retries',async()=>{
 const originalFetch=globalThis.fetch;let requests=0;setCsrf('synthetic-regression');
 try{
  const draft={...patientDraft(),name:'Alta de contrato',identifier:'Duplicado',phone:'123',email:'qa@example.test',birthDate:'2000-01-01',species:'Canino'};
  const input=buildPatientInput(draft,'ANIMAL');
  globalThis.fetch=async()=>{requests++;return Response.json({detail:'Identificador utilizado'},{status:409});};
  await assert.rejects(api('/patients',{method:'POST',body:input}),(error:unknown)=>error instanceof ApiError&&error.status===409&&error.message==='Identificador utilizado');
  assert.equal(requests,1);assert.deepEqual(buildPatientInput(draft,'ANIMAL'),input);
  globalThis.fetch=async()=>{requests++;return new Response('<p>Gateway</p>',{status:409,headers:{'Content-Type':'text/html'}});};
  await assert.rejects(api('/patients',{method:'POST',body:input}),(error:unknown)=>error instanceof ApiError&&error.status===409&&/respuesta no válida/.test(error.message));assert.equal(requests,2);
 }finally{globalThis.fetch=originalFetch;setCsrf('');}
});

test('an explicit detail reload supplies the next edit revision without mutating the rejected revision',()=>{
 const rejected=fixture(),reloaded=readPatient({...rejected,revision:8},tenant,'HUMAN',id);
 const input=buildPatientInput(patientDraft(reloaded),'HUMAN',reloaded);assert.deepEqual(patientWriteBody(input,reloaded),{expectedRevision:8,patient:input});
 assert.equal(rejected.revision,7);
});
