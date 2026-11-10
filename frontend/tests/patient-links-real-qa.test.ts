import test from 'node:test';
import assert from 'node:assert/strict';
import {Readable,PassThrough} from 'node:stream';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const qa=require('../scripts/patient-links-real-qa.cjs');
const tenant='11111111-1111-1111-1111-111111111111',actor='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const manifest=()=>({schema:'health-patients-real-qa-v1',qaDatabase:'health_project_sqlserver_qa_isolated_20261105',baseUrl:'http://health.localhost:18300',runId:'pacqa-20261109-a1',human:{hostname:qa.HOSTS.human,tenantId:tenant,email:'human@example.test',password:'OFFLINE-ONLY-secret'},otherHuman:{hostname:qa.HOSTS.otherHuman,tenantId:'22222222-2222-2222-2222-222222222222',email:'other@example.test',password:'OFFLINE-ONLY-other'},animal:{hostname:qa.HOSTS.animal,tenantId:'33333333-3333-3333-3333-333333333333',email:'animal@example.test',password:'OFFLINE-ONLY-animal'}});
const row=(n=0)=>({tenantId:tenant,patientId:qa.HUMAN,userId:`aaaaaaaa-aaaa-aaaa-aaaa-${String(n).padStart(12,'0')}`,userName:'Historical',relationship:'',active:false,scopes:['UNKNOWN','UNKNOWN','DOCUMENTS']});
function failure(code:string,fn:()=>unknown){assert.throws(fn,(error:unknown)=>(error as {code:string}).code===code&&!String(error).includes('secret'));}

test('session cookie validation queries the exact same-origin API path with HttpOnly required',async()=>{
 const origin='http://'+qa.HOSTS.human+':18300';
 type CookieMetadata={name:string;httpOnly:boolean;path:string};
 const session:CookieMetadata={name:'health_session',httpOnly:true,path:'/api'};
 const check=async(cookies:CookieMetadata[],accepted:boolean)=>{
  const calls:string[]=[];
  const context={cookies:async(url:string)=>{calls.push(url);return cookies.filter(cookie=>new URL(url).origin===origin&&new URL(url).pathname.startsWith(cookie.path));}};
  if(accepted)await qa.checkSessionCookie(context,origin);
  else await assert.rejects(qa.checkSessionCookie(context,origin),(error:unknown)=>(error as {code:string}).code==='SESSION_MISMATCH');
  assert.deepEqual(calls,[origin+'/api/']);
 };
 await check([session],true);
 await check([],false);
 await check([{...session,name:'other_session'}],false);
 await check([{...session,httpOnly:false}],false);
 // The path-filtering double excludes /api cookies from a root URL.
 assert.equal(new URL(origin).pathname.startsWith(session.path),false);
 const calls:string[]=[];
 await assert.rejects(qa.checkSessionCookie({cookies:async(url:string)=>{calls.push(url);return new URL(url).origin===origin?[session]:[];}},'http://'+qa.HOSTS.otherHuman+':18300'),(error:unknown)=>(error as {code:string}).code==='SESSION_MISMATCH');
 assert.deepEqual(calls,['http://'+qa.HOSTS.otherHuman+':18300/api/']);
});

test('real links runner import is inert: no filesystem, Playwright, process or network modules loaded',()=>{
 const file=require.resolve('../scripts/patient-links-real-qa.cjs'),Module=require('node:module'),original=Module._load;
 delete require.cache[file];
 Module._load=function(this:unknown,name:string,...args:unknown[]){if(['playwright','node:fs','node:http','node:https','node:child_process','node:net'].includes(name))throw Error('I/O during import');return original.call(this,name,...args);};
 try{require(file);}finally{Module._load=original;}
});
test('manifest pins all three exact hosts, distinct canonical tenants and synthetic emails; closed readonly flag',()=>{
 qa.validateManifest(manifest());qa.parseFlags(['--readonly']);
 for(const args of [[],['--allow-synthetic-writes'],['--readonly','--readonly'],['--base','http://evil'],['--password=secret']])failure('INVALID_FLAGS',()=>qa.parseFlags(args));
 for(const field of ['schema','qaDatabase','baseUrl','runId'])failure('INVALID_MANIFEST',()=>qa.validateManifest({...manifest(),[field]:'bad'}));
 for(const delta of [{hostname:'qa-other.health.localhost'},{tenantId:actor.toUpperCase()},{tenantId:tenant+'\n'},{email:'real@outside.invalid'},{password:''},{extra:'secret'}])failure('INVALID_MANIFEST',()=>qa.validateManifest({...manifest(),human:{...manifest().human,...delta}}));
 failure('INVALID_MANIFEST',()=>qa.validateManifest({...manifest(),otherHuman:{...manifest().otherHuman,tenantId:tenant}}));
});
test('host/session validate exact identity/domain and ADM/REC only, including mixed-role denial',()=>{
 const entry=manifest().human,host={platform:false,id:tenant,hostname:entry.hostname,domain:'HUMAN'},session={user:{id:actor,tenantId:tenant,email:entry.email,roles:['REC']},csrfToken:'offline'};
 qa.checkHost(host,entry,'HUMAN');assert.equal(qa.checkSession(session,entry).id,actor);
 for(const delta of [{id:actor},{hostname:qa.HOSTS.otherHuman},{platform:true},{domain:'ANIMAL'}])failure('HOST_MISMATCH',()=>qa.checkHost({...host,...delta},entry,'HUMAN'));
 for(const roles of [['PRO'],['ASI'],['AUD'],['ADM','PAC'],['REC','RES'],['ADM','SAD'],['REC','SOP'],[]])failure('SESSION_MISMATCH',()=>qa.checkSession({...session,user:{...session.user,roles}},entry));
 for(const delta of [{id:'bad'},{id:actor+'\n'},{tenantId:actor},{email:'other@example.test'}])failure('SESSION_MISMATCH',()=>qa.checkSession({...session,user:{...session.user,...delta}},entry));
 failure('SESSION_MISMATCH',()=>qa.checkSession({...session,csrfToken:''},entry));
});
test('seven-field contract validates whole page and preserves historical order/scopes/blank/inactive values',()=>{
 const raw=row(),rows=qa.readLinks([raw,{...row(1),userName:'Alpha',active:true,scopes:[]}],tenant,qa.HUMAN,21);
 assert.equal(rows[0].userName,'Historical');assert.equal(rows[0].active,false);assert.deepEqual(rows[0].scopes,['UNKNOWN','UNKNOWN','DOCUMENTS']);assert.equal(Object.keys(rows[0]).length,7);raw.scopes.push('later');assert.equal(rows[0].scopes.length,3);assert.equal(Object.isFrozen(rows[0].scopes),true);
 assert.deepEqual(qa.readLinks([],tenant,qa.HUMAN,21),[]);assert.equal(qa.readLinks([{...row(),userName:'',relationship:'',scopes:[]}],tenant,qa.HUMAN,1)[0].userName,'');
 const page=Array.from({length:21},(_,i)=>row(i));qa.readLinks(page,tenant,qa.HUMAN,21);failure('INVALID_RESPONSE',()=>qa.readLinks([...page,row(22)],tenant,qa.HUMAN,21));
 for(const value of [[row(),row()],new Array(1),[{...row(),email:'private'}],[{...row(),patientId:tenant}],[{...row(),tenantId:actor}],[{...row(),userId:actor.toUpperCase()}],[{...row(),userName:'x'.repeat(161)}],[{...row(),relationship:'x'.repeat(81)}],[{...row(),active:1}],[{...row(),scopes:[null]}],[{...row(),scopes:'[]'}]])failure('INVALID_RESPONSE',()=>qa.readLinks(value,tenant,qa.HUMAN,21));
});
test('real order/subpages and animal prerequisite do not fabricate fixtures or scan alternatives',()=>{
 const full=qa.readLinks([row(),row(1)],tenant,qa.HUMAN,21);qa.checkSubpages(full,full.slice(0,1),full.slice(1,2));failure('INVALID_RESPONSE',()=>qa.checkSubpages(full,full.slice(1),full.slice(0,1)));
 const entry=manifest().animal,p={id:actor,tenantId:entry.tenantId,domain:'ANIMAL',name:'Synthetic',identifier:qa.ANIMAL_IDENTIFIER};assert.equal(qa.findAnimal([p],entry),p);
 for(const rows of [[],[p,p],[{...p,tenantId:tenant}],[{...p,identifier:'other'}],[{...p,domain:'HUMAN'}]])failure('PREREQUISITE_FAILED',()=>qa.findAnimal(rows,entry));
});
test('browser policy and APIRequestContext guard independently deny writes, foreign host, extra API and injection',async()=>{
 const origin='http://'+qa.HOSTS.human+':18300',policy={origin,staticRoutes:qa.buildStaticRoutes(['acceso/index.html','_next/a.js','app/pacientes/index.html']),loginAllowed:true,loginEmail:'offline@example.test',loginPassword:'OFFLINE',logoutAllowed:true,ids:new Set([qa.HUMAN]),queries:new Set(['',qa.ANIMAL_IDENTIFIER])};
 for(const path of ['/acceso/','/_next/a.js','/app/pacientes/','/api/public/context','/api/auth/browser/session','/api/patients/'+qa.HUMAN,'/api/patients/'+qa.HUMAN+'/links?limit=21&offset=0'])assert.equal(qa.allowedRequest('GET',origin+path,policy),true);
 assert.equal(qa.allowedRequest('POST',origin+'/api/auth/browser/login',policy,{email:policy.loginEmail,password:policy.loginPassword}),true);assert.equal(qa.allowedRequest('POST',origin+'/api/auth/browser/login',policy,{email:'other@example.test',password:policy.loginPassword}),false);assert.equal(qa.allowedRequest('DELETE',origin+'/api/auth/browser/session',policy),true);
 for(const method of ['POST','PUT','PATCH','DELETE'])assert.equal(qa.allowedRequest(method,origin+'/api/patients/'+qa.HUMAN+'/links',policy),false);
 for(const path of ['/api/support','/api/patients/'+qa.HUMAN+'/history','/api/patients/'+qa.HUMAN+'/links?limit=200&offset=0','/api/patients/'+qa.HUMAN+'/links?limit=21&offset=-1','/actuator/health/readiness'])assert.equal(qa.allowedRequest('GET',origin+path,policy),false);
 assert.equal(qa.allowedRequest('GET','http://'+qa.HOSTS.otherHuman+':18300/api/public/context',policy),false);
 let requests=0;const client={origin,policy,identity:{csrfToken:'offline'},page:{evaluate:async()=>{requests++;return {status:200,requestId:actor,jsonValid:true,data:{}};}}};
 await assert.rejects(qa.guardedRequest(client,'/api/patients','POST',{}),(e:unknown)=>(e as {code:string}).code==='UNSAFE_REQUEST');assert.equal(requests,0);await qa.guardedRequest(client,'/api/public/context');assert.equal(requests,1);
 let handler:(r:unknown)=>Promise<void>=async()=>{},unsafe=0,continued=0,aborted=0;
 await qa.installBrowserGuard({route:async(_pattern:string,callback:typeof handler)=>{handler=callback;}},policy,()=>{unsafe++;});
 for(const [method,url,valid] of [['GET',origin+'/api/public/context',true],['PUT',origin+'/api/patients/'+qa.HUMAN,false],['GET','http://external.invalid/api/public/context',false]] as const){
  await handler({request:()=>({method:()=>method,url:()=>url}),continue:async()=>{continued++;assert.equal(valid,true);},abort:async()=>{aborted++;assert.equal(valid,false);},get fulfill(){throw Error('Response substitution forbidden');}});
 }
 assert.equal(continued,1);assert.equal(aborted,2);assert.equal(unsafe,2);
 await handler({request:()=>({method:()=>'GET',url:()=>origin+'/api/public/context'}),continue:async()=>{throw Error('OFFLINE-PRIVATE');},abort:async()=>{throw Error('OFFLINE-PRIVATE');},get fulfill(){throw Error('forbidden');}});assert.equal(unsafe,3);
});
test('approved export produces only exact file, index and invertible Windows RSC aliases',()=>{
 const fs=require('node:fs'),crypto=require('node:crypto'),raw=fs.readFileSync('C:/Users/maxmo/AppData/Local/Temp/B5R4-reviewed-pins.json');
 assert.equal(crypto.createHash('sha256').update(raw).digest('hex').toUpperCase(),'6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6');
 const pins=JSON.parse(raw.toString('utf8')),root='D:/Mavric/Health Project/frontend/out/';
 const expected=Object.keys(pins).map(p=>p.replaceAll('\\','/')).filter(p=>p.startsWith(root)).map(p=>p.slice(root.length)).sort();
 assert.equal(Object.keys(pins).length,726);assert.equal(expected.length,444);assert.deepEqual([...qa.STATIC_FILES],expected);assert.equal(Object.isFrozen(qa.STATIC_FILES),true);
 const routes=qa.buildStaticRoutes(qa.STATIC_FILES),origin='http://'+qa.HOSTS.human+':18300',policy={origin,staticRoutes:routes};
 for(const file of expected)for(const method of ['GET','HEAD'])assert.equal(qa.allowedRequest(method,origin+'/'+file,policy),true,file);
 for(const p of ['/','/index.html','/demo','/demo/','/demo/index.html','/__next._tree.txt','/demo/__next.$c$path.__PAGE__.txt','/app/pacientes','/app/pacientes/','/acceso/','/file.svg','/_next/static/media/'+expected.find(p=>p.includes('/media/'))!.split('/').at(-1)]){
  for(const method of ['GET','HEAD'])assert.equal(qa.allowedRequest(method,origin+p,policy),true,p);
  for(const method of ['POST','PUT','PATCH','DELETE','OPTIONS'])assert.equal(qa.allowedRequest(method,origin+p,policy),false);
 }
 assert.equal(qa.allowedRequest('GET',origin+'/__next._tree.txt?_rsc=offline',policy),true);
 // An alias must map back to a real inventory member under the proxy's exact rule.
 for(const file of expected){const parts=file.split('/'),dir=parts.at(-2),leaf=parts.at(-1);if(dir?.startsWith('__next.')&&!leaf!.slice(0,-4).includes('.')&&leaf!.endsWith('.txt')){
  const alias='/'+[...parts.slice(0,-2),dir+'.'+leaf].join('/');const match=alias.match(/^(.*\/)(__next\.[^/]+)\.txt$/)!;const dot=match[2].lastIndexOf('.');
  assert.equal(match[1].slice(1)+match[2].slice(0,dot)+'/'+match[2].slice(dot+1)+'.txt',file);assert.equal(routes.has(alias),true);
 }}
 for(const p of ['/demo/__next.demo.__PAGE__.txt','/_next/not-in-export.js','/app/not-in-export/','/unknown.txt','/support','/demo/unknown.txt','/api','/actuator'])assert.equal(qa.allowedRequest('GET',origin+p,policy),false,p);
 assert.equal(qa.allowedRequest('GET','http://'+qa.HOSTS.otherHuman+':18300/demo/',policy),false);
});

test('static inventory and request parser reject traversal/encoded paths and never turn API or actuator into assets',()=>{
 for(const name of ['/index.html','../index.html','a/../b.txt','a//b.txt','./a.txt','a\\b.txt','a%2fb.txt','a?b.txt','a#b.txt','C:/a.txt','a/NUL.txt','a./b.txt','a/CON','a/..','a/'])failure('INVALID_RESPONSE',()=>qa.buildStaticRoutes([name]));
 failure('INVALID_RESPONSE',()=>qa.buildStaticRoutes(['index.html','index.html']));
 const origin='http://'+qa.HOSTS.human+':18300',routes=qa.buildStaticRoutes(['index.html','demo/index.html','api/index.html','api/private.txt','actuator/index.html','actuator/health.txt','API/private.txt']),policy={origin,staticRoutes:routes};
 assert.equal([...routes].some((p:string)=>/^\/(api|actuator)(\/|$)/i.test(p)),false);
 for(const p of ['/api/private.txt','/api/','/api','/actuator/health.txt','/actuator/','/API/private.txt','/demo/../index.html','/%2e%2e/index.html','/demo%2findex.html','/demo%5cindex.html','/demo%252findex.html','//index.html','/demo/./index.html','/demo\\index.html'])assert.equal(qa.allowedRequest('GET',origin+p,policy),false,p);
 assert.equal(qa.allowedRequest('GET','http://user:canary@'+qa.HOSTS.human+':18300/index.html',policy),false);
});

test('API decisions remain identical to the pre-R4 guard for the closed business/auth matrix',()=>{
 const previous=require('C:/Users/maxmo/AppData/Local/Temp/B5R4-source-1-before.bin');
 const origin='http://'+qa.HOSTS.human+':18300',policy={origin,loginAllowed:true,loginEmail:'offline@example.test',loginPassword:'OFFLINE',logoutAllowed:true,ids:new Set([qa.HUMAN]),queries:new Set(['',qa.ANIMAL_IDENTIFIER]),staticRoutes:qa.buildStaticRoutes(qa.STATIC_FILES)};
 const paths=['/api','/api/','/api/public/context','/api/public/status','/api/public/context?q=x','/api/auth/browser/login','/api/auth/browser/session','/api/support','/api/accounts','/api/monitor','/api/auth/register','/api/patients?limit=2&offset=0&query=','/api/patients?limit=21&offset=0&query='+qa.ANIMAL_IDENTIFIER,'/api/patients?limit=50&offset=0&query=','/api/patients/'+qa.HUMAN,'/api/patients/'+actor,'/api/patients/'+qa.HUMAN+'/history',...['1','21','200'].flatMap(limit=>['0','1','20','-1'].map(offset=>'/api/patients/'+qa.HUMAN+'/links?limit='+limit+'&offset='+offset))];
 for(const p of paths)for(const method of ['GET','HEAD','POST','PUT','PATCH','DELETE','OPTIONS'])for(const body of [undefined,{email:policy.loginEmail,password:policy.loginPassword},{}])assert.equal(qa.allowedRequest(method,origin+p,policy,body),previous.allowedRequest(method,origin+p,policy,body),method+' '+p);
});

test('both guardians abort forbidden requests and record only the first closed denial without canary data',async()=>{
 const origin='http://'+qa.HOSTS.human+':18300',denied=qa.denialRecorder(),policy={origin,staticRoutes:qa.buildStaticRoutes(['demo/index.html']),onDenied:denied.add,ids:new Set([qa.HUMAN]),queries:new Set([''])};
 const canary='OFFLINE-private-URL-cookie-password';let handler:(r:unknown)=>Promise<void>=async()=>{},aborted=0,continued=0,unsafe=0,evaluated=0;
 await qa.installBrowserGuard({route:async(_pattern:string,callback:typeof handler)=>{handler=callback;}},policy,()=>{unsafe++;});
 const request=async(method:string,url:string,throws=false)=>handler({request:()=>({method:()=>method,url:()=>url,postDataJSON:()=>{throw new Error(canary);}}),continue:async()=>{if(throws)throw new Error(canary);continued++;},abort:async()=>{aborted++;},get fulfill(){throw new Error('forbidden');}});
 await request('GET',origin+'/demo/');assert.equal(continued,1);await request('GET',origin+'/unknown.txt?password='+canary);
 await request('PUT',origin+'/api/patients/'+qa.HUMAN);await request('GET','http://foreign.invalid/'+canary);await request('POST',origin+'/api/auth/browser/login');
 assert.equal(aborted,4);assert.equal(unsafe,4);assert.deepEqual(denied.value(),{method:'GET',category:'STATIC_PATH'});assert.equal(Object.isFrozen(denied.value()),true);
 const client={origin,policy,identity:{csrfToken:canary},page:{evaluate:async()=>{evaluated++;}}};await assert.rejects(qa.guardedRequest(client,'/api/private?token='+canary),(e:unknown)=>(e as {code:string}).code==='UNSAFE_REQUEST');assert.equal(evaluated,0);assert.deepEqual(denied.value(),{method:'GET',category:'STATIC_PATH'});
 for(const [method,address,category] of [['GET','not a URL '+canary,'INVALID_URL'],['GET','http://foreign.invalid/'+canary,'FOREIGN_ORIGIN'],['GET',origin+'/api/private?password='+canary,'API_READ'],['POST',origin+'/api/private','API_WRITE'],['GET',origin+'/unknown.txt','STATIC_PATH']] as const){const value=qa.denialDiagnostic(method,address,policy);assert.deepEqual(value,{method,category});assert.equal(JSON.stringify(value).includes(canary),false);}
 assert.deepEqual(qa.denialDiagnostic(canary,origin+'/demo/',policy,true),{method:'OTHER',category:'ROUTE_HANDLER'});
 const handlerDenial=qa.denialRecorder();policy.onDenied=handlerDenial.add;await request('GET',origin+'/demo/',true);assert.deepEqual(handlerDenial.value(),{method:'GET',category:'ROUTE_HANDLER'});assert.equal(aborted,5);
 const late=denied.finish({status:'PASS'});assert.deepEqual(late,{status:'FAIL',code:'UNSAFE_REQUEST',diagnostic:{step:'cleanup',category:'UNKNOWN'},denial:{method:'GET',category:'STATIC_PATH'}});
 const prior={status:'FAIL',code:'INVALID_RESPONSE',diagnostic:{step:'ui-ficha',category:'ASSERTION'}};denied.finish(prior);assert.equal(prior.code,'INVALID_RESPONSE');assert.deepEqual(prior.diagnostic,{step:'ui-ficha',category:'ASSERTION'});
 let failingHandler:(r:unknown)=>Promise<void>=async()=>{},abortOnCallbackError=0;
 await qa.installBrowserGuard({route:async(_pattern:string,callback:typeof failingHandler)=>{failingHandler=callback;}},policy,()=>{throw new Error(canary);});
 await assert.rejects(failingHandler({request:()=>({method:()=>'GET',url:()=>origin+'/unknown.txt'}),abort:async()=>{abortOnCallbackError++;},continue:async()=>{throw new Error('must not continue');}}));assert.equal(abortOnCallbackError,1);
 failure('INVALID_RESPONSE',()=>qa.denialRecorder().add({method:'GET',category:'STATIC_PATH',url:canary}));failure('INVALID_RESPONSE',()=>qa.denialRecorder().add({method:canary,category:'STATIC_PATH'}));
});

test('browser fetch executes same-origin callback with cookies/no-store/redirect guard and own CSRF',async()=>{
 const origin='http://'+qa.HOSTS.human+':18300',policy={origin,loginAllowed:false,logoutAllowed:true,ids:new Set([qa.HUMAN]),queries:new Set([''])};
 const savedFetch=globalThis.fetch,savedWindow=Object.getOwnPropertyDescriptor(globalThis,'window');let current=origin,calls=0,fetchOptions:RequestInit|undefined;
 Object.defineProperty(globalThis,'window',{configurable:true,value:{location:{get origin(){return current;}}}});
 const page={evaluate:async(fn:(args:unknown)=>unknown,args:unknown)=>fn(args)};
 const client={origin,policy,identity:{csrfToken:'OFFLINE_CSRF'},page};
 globalThis.fetch=async(resource,options)=>{calls++;assert.equal(String(resource),'/api/auth/browser/session');fetchOptions=options;return new Response('{}',{status:200,headers:{'X-Request-Id':actor}});};
 try{
  const response=await qa.guardedRequest(client,'/api/auth/browser/session','DELETE');assert.equal(response.status(),200);assert.deepEqual(await response.json(),{});assert.equal(response.url(),origin+'/api/auth/browser/session');assert.deepEqual(response.headers(),{'x-request-id':actor});
  assert.equal(fetchOptions?.credentials,'same-origin');assert.equal(fetchOptions?.cache,'no-store');assert.equal(fetchOptions?.redirect,'error');assert.equal((fetchOptions?.headers as Record<string,string>)['X-CSRF-Token'],'OFFLINE_CSRF');assert.equal('Host' in (fetchOptions?.headers as object),false);assert.equal('Cookie' in (fetchOptions?.headers as object),false);
  current='http://'+qa.HOSTS.otherHuman+':18300';await assert.rejects(qa.guardedRequest(client,'/api/auth/browser/session'));assert.equal(calls,1);
  current=origin;for(const status of [401,403]){globalThis.fetch=async()=>new Response('{"status":'+status+'}',{status,headers:{'X-Request-Id':actor}});const negative=await qa.guardedRequest(client,'/api/auth/browser/session');assert.equal(negative.status(),status);assert.equal((await negative.json()).status,status);}
  globalThis.fetch=async()=>new Response('<html>bad</html>',{status:503});const bad=await qa.guardedRequest(client,'/api/auth/browser/session');assert.equal(bad.status(),503);await assert.rejects(bad.json(),(e:unknown)=>(e as {code:string}).code==='INVALID_RESPONSE');
 }finally{globalThis.fetch=savedFetch;if(savedWindow)Object.defineProperty(globalThis,'window',savedWindow);else Reflect.deleteProperty(globalThis,'window');}
 assert.deepEqual(qa.launchOptions(),{channel:'msedge',headless:true,args:['--host-resolver-rules=MAP health.localhost 127.0.0.1, MAP *.health.localhost 127.0.0.1','--no-proxy-server']});
});
test('API response observed by browser and adapter deduplicates once, UI adds one; conflicts always fail',async()=>{
 const origin='http://'+qa.HOSTS.human+':18300',resource='/api/patients/'+qa.HUMAN+'/links?limit=21&offset=0',records=qa.recorder();
 const client={entry:{tenantId:tenant},identity:{id:actor},origin,policy:{origin,ids:new Set([qa.HUMAN])},page:{evaluate:async()=>({status:200,requestId:actor,jsonValid:true,data:[row()]})}};
 const browserReply={url:()=>origin+resource,status:()=>200,headers:()=>({'x-request-id':actor}),json:async()=>[row()]};
 await qa.recordResponse(records,client,browserReply,'human-page');const adapter=await qa.guardedRequest(client,resource);await qa.recordResponse(records,client,adapter,'human-page');assert.equal(records.values().length,1);
 await qa.recordResponse(records,client,{...browserReply,headers:()=>({'x-request-id':tenant})},'human-ui');assert.equal(records.values().length,2);
 for(const [changed,phase] of [[{status:()=>404},'human-page'],[{},'other-phase']] as const)await assert.rejects(qa.recordResponse(records,client,{...browserReply,...changed},phase),(e:unknown)=>(e as {code:string}).code==='REQUEST_ID_COLLISION');
 for(const changed of [{actorId:tenant},{tenantId:actor},{patientId:tenant}])failure('REQUEST_ID_COLLISION',()=>records.add({...records.values()[0],...changed}));
});
test('closed diagnostics never serialize messages/stack/URLs or raw and escaped secrets',()=>{
 const secret='OFFLINE-"-ñ-PRIVATE',escaped=JSON.stringify(secret);
 const cases:[Error,string][]=[[new Error('net::ERR_NAME_NOT_RESOLVED '+escaped),'DNS'],[new Error('ECONNREFUSED '+secret),'CONNECT'],[Object.assign(new Error('timed out '+secret),{name:'TimeoutError'}),'TIMEOUT'],[new TypeError(secret),'JAVASCRIPT'],[new Error('page.evaluate: ReferenceError '+secret),'JAVASCRIPT'],[new qa.QaFailure('ASSERTION_FAILED'),'ASSERTION'],[new Error(secret),'UNKNOWN']];
 for(const [error,category] of cases){error.stack='PRIVATE stack '+escaped;const value=qa.diagnostic(error,'public-context');assert.deepEqual(value,{step:'public-context',category});const output=JSON.stringify(value);assert.equal(output.includes(secret),false);assert.equal(output.includes(escaped),false);assert.equal(output.includes('PRIVATE'),false);}
 assert.deepEqual(qa.diagnostic(new Error(secret),'https://private.invalid/'+secret),{step:'unknown',category:'UNKNOWN'});
});
test('requestId records deduplicate real IDs and never admit unknown metadata, emails or forged identity',()=>{
 const record={requestId:actor,status:200,actorId:actor,tenantId:tenant,patientId:qa.HUMAN,phase:'human-page'},r=qa.recorder();r.add(record);r.add({...record});assert.equal(r.values().length,1);
 failure('REQUEST_ID_COLLISION',()=>r.add({...record,status:404}));failure('REQUEST_ID_INVALID',()=>r.add({...record,email:'private'}));failure('REQUEST_ID_INVALID',()=>r.add({...record,requestId:'untrusted'}));failure('REQUEST_ID_INVALID',()=>r.add({...record,status:401}));
 r.add({...record,requestId:tenant,status:401,actorId:null});assert.equal(r.values().length,2);
});
test('negative problems require real backend shape and canonical request IDs',()=>{
 const path='/api/patients/'+qa.HUMAN+'/links',value={status:404,type:'urn:health-project:error:not_found',instance:path,requestId:actor};qa.problem(value,404,path);
 for(const delta of [{status:401},{instance:'/wrong'},{type:'gateway'},{requestId:'bad'}])failure('INVALID_RESPONSE',()=>qa.problem({...value,...delta},404,path));
 failure('PREREQUISITE_FAILED',()=>qa.fixtureResponse(404,{...value,instance:'/api/patients/'+qa.HUMAN},manifest().human,'HUMAN',qa.HUMAN));
 failure('INVALID_RESPONSE',()=>qa.fixtureResponse(503,{},manifest().human,'HUMAN',qa.HUMAN));
});
test('stdin waits for EOF before loading Playwright and rejects bytes/flags without secret output',async()=>{
 const stream=new PassThrough();let loaded=false;const promise=qa.cli(['--readonly'],stream,()=>{loaded=true;throw Error('offline load marker');});stream.write(JSON.stringify(manifest()));await new Promise(resolve=>setImmediate(resolve));assert.equal(loaded,false);stream.end();await assert.rejects(promise);assert.equal(loaded,true);
 await assert.rejects(qa.readStdin(Readable.from([Buffer.from([0xff])])),(e:unknown)=>(e as {code:string}).code==='INVALID_MANIFEST');
 await assert.rejects(qa.readStdin(Readable.from(['x'.repeat(65537)])),(e:unknown)=>(e as {code:string}).code==='INPUT_FAILED');
 let called=false;await assert.rejects(qa.cli(['--allow-synthetic-writes'],Readable.from(['secret']),()=>{called=true;}));assert.equal(called,false);
 assert.equal(qa.scopeLabel('__proto__'),'Referencia histórica: __proto__');
});
