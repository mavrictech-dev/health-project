import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {Readable} from 'node:stream';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const require=createRequire(import.meta.url);
const qa=require('../scripts/patients-real-qa.cjs');
const tenantA='11111111-1111-1111-1111-111111111111',tenantB='22222222-2222-2222-2222-222222222222',tenantV='33333333-3333-3333-3333-333333333333';
const patientId='44444444-4444-4444-4444-444444444444';
const manifest=()=>({schema:'health-patients-real-qa-v1',qaDatabase:'health_project_sqlserver_qa_isolated_20261105',baseUrl:'http://health.localhost:18300',runId:'pacqa-20261109-offline',human:{hostname:'qa-offline-a.health.localhost',tenantId:tenantA,email:'owner-a@example.test',password:'OFFLINE_ONLY'},otherHuman:{hostname:'qa-offline-b.health.localhost',tenantId:tenantB,email:'owner-b@example.test',password:'OFFLINE_ONLY'},animal:{hostname:'qa-offline-v.health.localhost',tenantId:tenantV,email:'owner-v@example.test',password:'OFFLINE_ONLY'}});
const fails=(fn:()=>unknown,code:string)=>assert.throws(fn,(error:unknown)=>qa.safeFailure(error)===code);
const spec=(tag='UI')=>qa.fixtureSpec(manifest().runId,'HUMAN',tag);
const patient=(s=spec())=>({id:patientId,tenantId:tenantA,...structuredClone(s.input),revision:1,createdAt:'2026-11-09T00:00:00Z'});

test('real QA import is inert: no Playwright, browser, network, stdin or CLI execution',()=>{
 const script=fileURLToPath(new URL('../scripts/patients-real-qa.cjs',import.meta.url));
 const code=`const Module=require('node:module');const load=Module._load;Module._load=function(id,...rest){if(['playwright','node:http','node:https','node:net','node:fs','node:child_process'].includes(id))throw Error('side effect');return load.call(this,id,...rest)};require(${JSON.stringify(script)});process.stdout.write('inert');`;
 const result=spawnSync(process.execPath,['-e',code],{encoding:'utf8',timeout:5000});assert.equal(result.status,0);assert.equal(result.stdout,'inert');assert.equal(result.stderr,'');
});

test('manifest permits only the pinned QA database, exact local base and three distinct canonical hosts/tenants',()=>{
 assert.equal(qa.validateManifest(manifest()).schema,'health-patients-real-qa-v1');
 for(const [key,value] of [['schema','other'],['qaDatabase','production'],['baseUrl','http://health.localhost:18300/'],['baseUrl','https://health.localhost:18300'],['baseUrl','http://health.localhost:18300/?secret=x'],['baseUrl','http://x:y@health.localhost:18300'],['baseUrl','http://127.0.0.1:18300'],['baseUrl','http://health.localhost:18080'],['runId','pacqa-../secret'],['runId','pacqa-'+ 'a'.repeat(50)],['runId','PACQA-test']])fails(()=>qa.validateManifest({...manifest(),[key]:value}),'INVALID_MANIFEST');
 for(const hostname of ['qa-a.example.test','qa-a.health.localhost.evil.test','a.health.localhost','qa-a.b.health.localhost','qa-*.health.localhost','qa-A.health.localhost','qa-a.health.localhost:18300'])fails(()=>qa.validateManifest({...manifest(),human:{...manifest().human,hostname}}),'INVALID_MANIFEST');
 for(const tenantId of ['bad',tenantA.toUpperCase().replace('1','A'),tenantB])fails(()=>qa.validateManifest({...manifest(),human:{...manifest().human,tenantId}}),'INVALID_MANIFEST');
 fails(()=>qa.validateManifest({...manifest(),otherHuman:{...manifest().otherHuman,hostname:manifest().human.hostname}}),'INVALID_MANIFEST');
 for(const email of ['real@external.com','name@example.test.evil','name@example.test\nsecret','not-email'])fails(()=>qa.validateManifest({...manifest(),human:{...manifest().human,email}}),'INVALID_MANIFEST');
 for(const password of ['',null,'  '])fails(()=>qa.validateManifest({...manifest(),human:{...manifest().human,password}}),'INVALID_MANIFEST');
 fails(()=>qa.validateManifest({...manifest(),credentialsFile:'forbidden'}),'INVALID_MANIFEST');
});

test('stdin is bounded, preserves split UTF8 credentials only in memory and never echoes validation failures',async()=>{
 const input=manifest();input.human.password='OFFLINE-ñ';const buffer=Buffer.from(JSON.stringify(input)),split=buffer.indexOf(Buffer.from('ñ'))+1;
 const result=await qa.readStdin(Readable.from([buffer.subarray(0,split),buffer.subarray(split)]));assert.equal(result.human.password,input.human.password);
 await assert.rejects(qa.readStdin(Readable.from(['x'.repeat(65537)])),(e:unknown)=>qa.safeFailure(e)==='INPUT_FAILED');
 await assert.rejects(qa.readStdin(Readable.from(['{"password":"OFFLINE-PRIVATE"}'])),(e:unknown)=>qa.safeFailure(e)==='INVALID_MANIFEST'&&!String(e).includes('PRIVATE'));
});

test('readonly is the default; an explicit unique flag is required for writes, no argv credential/config channels',()=>{
 assert.deepEqual(qa.parseFlags([]),{writes:false});assert.deepEqual(qa.parseFlags(['--readonly']),{writes:false});assert.deepEqual(qa.parseFlags(['--allow-synthetic-writes']),{writes:true});
 for(const args of [['--readonly','--allow-synthetic-writes'],['--allow-synthetic-writes','--allow-synthetic-writes'],['--password=secret'],['--manifest','file'],['--base','http://evil']])fails(()=>qa.parseFlags(args),'INVALID_FLAGS');
});

test('request policy pins origin, blocks all readonly business mutations, and only permits declared own fixture writes',()=>{
 const origin='http://qa-offline-a.health.localhost:18300',s=spec(),policy={origin,writes:false,ids:new Set([patientId]),inputs:[s.input]};
 for(const path of ['/acceso/','/_next/a.js','/api/public/context','/api/public/status','/api/auth/browser/session','/api/patients?limit=21&offset=0','/api/patients/'+patientId])assert.equal(qa.allowedRequest('GET',origin+path,policy),true);
 assert.equal(qa.allowedRequest('POST',origin+'/api/auth/browser/login',policy),true);assert.equal(qa.allowedRequest('DELETE',origin+'/api/auth/browser/session',policy),true);
 for(const method of ['POST','PUT','PATCH','DELETE'])assert.equal(qa.allowedRequest(method,origin+'/api/patients',policy,s.input),false);
 for(const path of ['/api/support','/api/bootstrap','/api/tenant/configuration','/api/patients/'+patientId+'/history'])assert.equal(qa.allowedRequest('GET',origin+path,policy),false);
 for(const address of ['http://evil.test/api/patients','http://qa-offline-b.health.localhost:18300/api/patients','https://qa-offline-a.health.localhost:18300/api/patients','http://user:pass@qa-offline-a.health.localhost:18300/api/patients'])assert.equal(qa.allowedRequest('GET',address,policy),false);
 const writable={...policy,writes:true};assert.equal(qa.allowedRequest('POST',origin+'/api/patients',writable,s.input),true);assert.equal(qa.allowedRequest('POST',origin+'/api/patients',writable,{...s.input,identifier:'other-run'}),false);
 assert.equal(qa.allowedRequest('PUT',origin+'/api/patients/'+patientId,writable,{expectedRevision:7,patient:s.input}),true);assert.equal(qa.allowedRequest('PUT',origin+'/api/patients/'+tenantB,writable,{expectedRevision:7,patient:s.input}),false);assert.equal(qa.allowedRequest('PUT',origin+'/api/patients/'+patientId,writable,{expectedRevision:0,patient:s.input}),false);assert.equal(qa.allowedRequest('PUT',origin+'/api/patients/'+patientId,writable,{expectedRevision:7,patient:s.input,actor:'forbidden'}),false);
});

test('remote HostContext and session are checked against exact tenant/domain/identity and internal role',()=>{
 const entry=manifest().human,host={platform:false,id:tenantA,hostname:entry.hostname,domain:'HUMAN'};qa.checkHost(host,entry,'HUMAN');
 for(const delta of [{platform:true},{id:tenantB},{hostname:manifest().otherHuman.hostname},{domain:'ANIMAL'}])fails(()=>qa.checkHost({...host,...delta},entry,'HUMAN'),'HOST_MISMATCH');
 const session={user:{id:patientId,tenantId:tenantA,email:entry.email,roles:['ADM']},csrfToken:'OFFLINE_ONLY'};assert.equal(qa.checkSession(session,entry,true),patientId);
 for(const delta of [{id:'bad'},{tenantId:tenantB},{email:'other@example.test'},{roles:['SAD','ADM']},{roles:['PAC','ADM']},{roles:['RES']},{roles:['unknown']}])fails(()=>qa.checkSession({...session,user:{...session.user,...delta}},entry),'SESSION_MISMATCH');
 qa.checkSession({...session,user:{...session.user,roles:['AUD']}},entry);fails(()=>qa.checkSession({...session,user:{...session.user,roles:['AUD']}},entry,true),'SESSION_MISMATCH');fails(()=>qa.checkSession({...session,csrfToken:''},entry),'SESSION_MISMATCH');
});

test('fixtures are deterministic and disjoint by domain/run; reconciliation never duplicates or resets existing data',()=>{
 const s=spec();assert.deepEqual(qa.fixtureSpec(manifest().runId,'HUMAN','UI'),s);assert.notEqual(qa.fixtureSpec(manifest().runId,'ANIMAL','UI').input.identifier,s.input.identifier);assert.notEqual(qa.fixtureSpec('pacqa-other','HUMAN','UI').input.identifier,s.input.identifier);
 assert.deepEqual(qa.reconcileFixture([],s,tenantA),{action:'create'});const p=patient(s);assert.equal(qa.reconcileFixture([p],s,tenantA).action,'reuse');assert.equal(qa.reconcileFixture([p],s,tenantA).patient,p);
 fails(()=>qa.reconcileFixture([{...p,name:'Unexpected collision'}],s,tenantA),'FIXTURE_COLLISION');fails(()=>qa.reconcileFixture([p,p],s,tenantA),'FIXTURE_COLLISION');fails(()=>qa.reconcileFixture([{...p,tenantId:tenantB}],s,tenantA),'INVALID_RESPONSE');fails(()=>qa.reconcileFixture([{...p,domain:'ANIMAL'}],s,tenantA),'INVALID_RESPONSE');fails(()=>qa.reconcileFixture([{...p,contact:{...p.contact,unknown:true}}],s,tenantA),'UNEXPECTED_STATE');fails(()=>qa.reconcileFixture([{...p,revision:2}],s,tenantA),'UNEXPECTED_STATE');fails(()=>qa.reconcileFixture(Array(100).fill(p),s,tenantA),'LOOKUP_TRUNCATED');
 for(const tag of ['PAGE-00','PAGE-20','EDIT','RECOVER'])assert.ok(qa.fixtureSpec(manifest().runId,'HUMAN',tag).input.identifier.startsWith('PACQA-'));
 fails(()=>qa.fixtureSpec(manifest().runId,'HUMAN','PAGE-21'),'INVALID_MANIFEST');
});

test('restart accepts only the known edit stages and preserves opaque contact/allergy data',()=>{
 const s=spec('EDIT'),seed=patient(s);assert.equal(qa.reconcileFixture([seed],s,tenantA).stage,'seed');
 for(const [revision,phone,stage] of [[2,'PACQA-FIRST','first'],[3,'PACQA-FINAL','complete']] as const){const p={...seed,revision,contact:{...seed.contact,phone}};assert.equal(qa.reconcileFixture([p],s,tenantA).stage,stage);}
 for(const delta of [{revision:2},{revision:4},{contact:{phone:'PACQA-SEED'}},{allergies:[]},{birthDate:null},{contact:{...seed.contact,phone:'another-writer'}}])fails(()=>qa.reconcileFixture([{...seed,...delta}],s,tenantA),'UNEXPECTED_STATE');
 assert.equal(seed.revision,1);assert.equal(seed.contact.phone,'PACQA-SEED');
});

test('uncertain writes always stop; valid409 is a confirmed rejection, never a success or an automatic retry',()=>{
 for(const status of [0,500,503])assert.equal(qa.mutationOutcome(status,true),'uncertain');for(const status of [200,201,400,409,503])assert.equal(qa.mutationOutcome(status,false),'uncertain');assert.equal(qa.mutationOutcome(409,true),'rejected-conflict');assert.equal(qa.mutationOutcome(403,true),'rejected');assert.equal(qa.mutationOutcome(200,true),'confirmed');
});

test('safe results discard arbitrary messages, user/session objects, input and untrusted control names',()=>{
 const secret='OFFLINE_SECRET_CREDENTIAL';assert.deepEqual(qa.safeResult(secret,'failed',secret,999),{control:'runner',status:'failed',code:'UNEXPECTED_FAILURE'});assert.equal(qa.safeFailure(new Error(secret)),'UNEXPECTED_FAILURE');assert.equal(qa.safeFailure(new qa.QaFailure('UNCERTAIN_WRITE')),'UNCERTAIN_WRITE');
 const output=JSON.stringify(qa.safeResult('login','failed','SESSION_MISMATCH',401,{password:secret,user:manifest().human}));assert.equal(output.includes(secret),false);assert.equal(output.includes('owner'),false);assert.deepEqual(JSON.parse(output),{control:'login',status:'failed',code:'SESSION_MISMATCH',httpStatus:401});
});

test('CLI rejects an invalid stdin manifest before loading Playwright and emits only a safe failure code',()=>{
 const file=fileURLToPath(new URL('../scripts/patients-real-qa.cjs',import.meta.url)),bad={...manifest(),baseUrl:'http://external.invalid',human:{...manifest().human,password:'OFFLINE-PRIVATE-CLI'}};
 const result=spawnSync(process.execPath,[file],{input:JSON.stringify(bad),encoding:'utf8',timeout:5000,env:{...process.env,DEBUG:'',PWDEBUG:'',PLAYWRIGHT_TRACE_DIR:''}});
 assert.equal(result.status,1);assert.equal(result.stdout,'');assert.deepEqual(JSON.parse(result.stderr),{control:'runner',status:'failed',code:'INVALID_MANIFEST'});assert.equal(result.stderr.includes('PRIVATE'),false);assert.equal(result.stderr.includes(bad.human.email),false);
});

test('negative HTTP checks require the backend problem contract, never a gateway HTML404/401',()=>{
 const resource='/patients/'+patientId,good={status:404,jsonValid:true,data:{status:404,type:'urn:health-project:error:not_found',instance:'/api'+resource}};
 qa.checkProblem(good,404,resource);
 for(const value of [{...good,jsonValid:false},{...good,data:null},{...good,data:{...good.data,type:'gateway'}},{...good,data:{...good.data,status:401}},{...good,data:{...good.data,instance:'/unrelated'}}])fails(()=>qa.checkProblem(value,404,resource),'INVALID_RESPONSE');
});
