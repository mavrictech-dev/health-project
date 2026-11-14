import test from 'node:test';
import assert from 'node:assert/strict';
import {api,setCsrf} from '../src/lib/api';
import {mockAgenda,demoAgendaContext} from '../src/mocks/agenda-api';
import {calendarWindow,zonedParts} from '../src/lib/agenda';
import type {Patient} from '../src/lib/patient-types';

const branchId='93000000-0000-4000-8000-000000000001';
function fixture(){return {tenant:crypto.randomUUID(),branchId,patients:[{id:crypto.randomUUID(),name:'Paciente sintético',identifier:'QA-HP8',contact:{}} as Patient],role:'REC'};}
function call(options:ReturnType<typeof fixture>&{idempotencyKey?:string},route:string,method='GET',body:Record<string,unknown>={},params=new URLSearchParams({branchId})){return structuredClone(mockAgenda(route,method,body,params,options).value) as Record<string,unknown>;}
test('booking transport sends the idempotency key together with cookie credentials and CSRF',async()=>{
 const original=globalThis.fetch;let observed:RequestInit|undefined;
 globalThis.fetch=async(_input,options)=>{observed=options;return new Response(JSON.stringify({id:'confirmed-booking'}),{status:200,headers:{'Content-Type':'application/json'}});};
 try{setCsrf('synthetic-csrf');const result=await api<{id:string}>('/appointments',{method:'POST',body:{service:'Synthetic booking'},idempotencyKey:'hp8-reservation-001'});assert.equal(result.id,'confirmed-booking');assert.equal(observed?.credentials,'same-origin');assert.equal((observed?.headers as Record<string,string>)['Idempotency-Key'],'hp8-reservation-001');assert.equal((observed?.headers as Record<string,string>)['X-CSRF-Token'],'synthetic-csrf');}
 finally{globalThis.fetch=original;setCsrf('');}
});

test('collection request keys bind the appointment and replay the original revision',()=>{
 const f=fixture(),rows=call(f,'/v1/agenda/citas','GET',{},new URLSearchParams({branchId,from:'2000-01-01T00:00:00Z',to:'2100-01-01T00:00:00Z'})).rows as {id:string}[];
 const id=rows[1].id,other=rows[2].id,body={branchId,requestId:crypto.randomUUID(),expectedRevision:0,status:'PAID',amountMinor:2500,paymentMethod:'YAPE'};
 const first=call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',body);
 assert.throws(()=>call(f,`/v1/agenda/citas/${other}/cobro`,'PUT',body),e=>(e as {status:number}).status===409);
 call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',{...body,requestId:crypto.randomUUID(),expectedRevision:1,status:'PENDING',paymentMethod:null});
 assert.deepEqual(call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',body),first);
 const summary=call(f,'/v1/agenda/arqueo','GET',{},new URLSearchParams({branchId,from:'2000-01-01T00:00:00Z',to:'2100-01-01T00:00:00Z'})) as unknown as {paymentMethod:string;netMinor:number;receipts:number;reversals:number}[];
 assert.deepEqual(summary.find(s=>s.paymentMethod==='YAPE'),{paymentMethod:'YAPE',netMinor:0,receipts:1,reversals:1});
});

test('synthetic collection validation preserves the runtime payment contract and stale revisions',()=>{
 const f=fixture(),id='97000000-0000-4000-8000-000000000002';
 const body={branchId,requestId:crypto.randomUUID(),expectedRevision:0,status:'PAID',amountMinor:2500,paymentMethod:'YAPE'};
 for(const change of [{paymentMethod:'BITCOIN'},{amountMinor:2000000001},{status:'PENDING',paymentMethod:'CASH'},{expectedRevision:undefined},{requestId:undefined}])assert.throws(()=>call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',{...body,...change}),e=>(e as {status:number}).status===400);
 call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',body);
 assert.throws(()=>call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',{...body,requestId:crypto.randomUUID()}),e=>(e as {status:number}).status===409);
});

test('synthetic calendar rejects unauthorized roles and keeps tenant and branch scopes separate',()=>{
 const f=fixture();
 for(const role of ['PAC','RES','SOP','SAD'])for(const route of ['/v1/agenda/contexto','/v1/agenda/citas','/appointments'])assert.throws(()=>call({...f,role},route),e=>(e as {status:number}).status===403);
 assert.throws(()=>call(f,'/v1/agenda/contexto','GET',{},new URLSearchParams({branchId:crypto.randomUUID()})),e=>(e as {status:number}).status===403);
 const appointment={branchId,patientId:f.patients[0].id,professionalId:demoAgendaContext.professionals[0].id,specialtyCode:demoAgendaContext.professionals[0].specialtyCode,startsAt:'2030-11-15T15:00:00Z',endsAt:'2030-11-15T15:30:00Z',service:'Consulta sintética',note:''};
 const booked=call({...f,idempotencyKey:crypto.randomUUID()},'/appointments','POST',appointment);
 assert.ok(booked.id);
 const other=fixture(),values=call(other,'/appointments') as unknown as {id:string}[];
 assert.equal(values.some(a=>a.id===booked.id),false);
 const secondBranch=call({...f,branchId:crypto.randomUUID()},'/appointments','GET',{},new URLSearchParams()) as unknown as {id:string}[];
 assert.equal(secondBranch.length,0);
});

test('synthetic competing reservations reject overlap and bind retries to their original content',()=>{
 const f={...fixture(),idempotencyKey:crypto.randomUUID()},body={branchId,patientId:'',professionalId:demoAgendaContext.professionals[0].id,specialtyCode:demoAgendaContext.professionals[0].specialtyCode,startsAt:'2030-11-15T15:00:00Z',endsAt:'2030-11-15T15:30:00Z',service:'Consulta sintética',note:''};body.patientId=f.patients[0].id;
 const saved=call(f,'/appointments','POST',body);
 assert.deepEqual(call(f,'/appointments','POST',body),saved);
 assert.throws(()=>call(f,'/appointments','POST',{...body,service:'Otro servicio'}),e=>(e as {status:number}).status===409);
 assert.throws(()=>call({...f,idempotencyKey:crypto.randomUUID()},'/appointments','POST',body),e=>(e as {status:number}).status===409);
 assert.equal((call(f,'/appointments') as unknown as {id:string}[]).filter(a=>a.id===saved.id).length,1);
});

test('synthetic collection corrections compensate each previous method on the registration day and branch',()=>{
 const f=fixture(),id='97000000-0000-4000-8000-000000000002',date=zonedParts(new Date(),'America/Lima').date,period=calendarWindow(date,'day','America/Lima');
 for(const [revision,method] of ['CASH','CARD','TRANSFER','YAPE','PLIN','OTHER'].entries())call(f,`/v1/agenda/citas/${id}/cobro`,'PUT',{branchId,requestId:crypto.randomUUID(),expectedRevision:revision,status:'PAID',amountMinor:2500,paymentMethod:method});
 const summary=call(f,'/v1/agenda/arqueo','GET',{},new URLSearchParams({branchId,from:period.from,to:period.to})) as unknown as {paymentMethod:string;netMinor:number;receipts:number;reversals:number}[];
 assert.equal(summary.reduce((sum,r)=>sum+r.netMinor,0),10500); // Seed CASH 8000 plus the current OTHER payment 2500.
 for(const method of ['CARD','TRANSFER','YAPE','PLIN'])assert.deepEqual(summary.find(r=>r.paymentMethod===method),{paymentMethod:method,netMinor:0,receipts:1,reversals:1});
 const otherBranch=crypto.randomUUID();assert.deepEqual(call({...f,branchId:otherBranch},'/v1/agenda/arqueo','GET',{},new URLSearchParams({branchId:otherBranch,from:period.from,to:period.to})),[]);
 assert.deepEqual(call(f,'/v1/agenda/arqueo','GET',{},new URLSearchParams({branchId,from:'2030-11-15T05:00:00Z',to:'2030-11-16T05:00:00Z'})),[]);
});
