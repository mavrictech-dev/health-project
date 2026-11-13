import test from 'node:test';
import assert from 'node:assert/strict';
import {api,setCsrf} from '../src/lib/api';
test('booking transport sends the idempotency key together with cookie credentials and CSRF',async()=>{
 const original=globalThis.fetch;let observed:RequestInit|undefined;
 globalThis.fetch=async(_input,options)=>{observed=options;return new Response(JSON.stringify({id:'confirmed-booking'}),{status:200,headers:{'Content-Type':'application/json'}});};
 try{setCsrf('synthetic-csrf');const result=await api<{id:string}>('/appointments',{method:'POST',body:{service:'Synthetic booking'},idempotencyKey:'hp8-reservation-001'});assert.equal(result.id,'confirmed-booking');assert.equal(observed?.credentials,'same-origin');assert.equal((observed?.headers as Record<string,string>)['Idempotency-Key'],'hp8-reservation-001');assert.equal((observed?.headers as Record<string,string>)['X-CSRF-Token'],'synthetic-csrf');}
 finally{globalThis.fetch=original;setCsrf('');}
});
