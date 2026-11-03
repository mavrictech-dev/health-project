import test,{afterEach} from 'node:test';
import assert from 'node:assert/strict';
import { api,ApiError,errorMessage,setCsrf } from '../src/lib/api';
const originalFetch=globalThis.fetch,originalWindow=Object.getOwnPropertyDescriptor(globalThis,'window');
afterEach(()=>{globalThis.fetch=originalFetch;setCsrf('');if(originalWindow)Object.defineProperty(globalThis,'window',originalWindow);else Reflect.deleteProperty(globalThis,'window');});

test('cookie credentials and in-memory CSRF for mutations, no automatic retry',async()=>{
  const requests:RequestInit[]=[];setCsrf('memory-only');
  globalThis.fetch=async(url,init)=>{assert.equal(url,'/api/example');requests.push(init!);return Response.json({ok:true});};
  await api('/example');await api('/example',{method:'POST',body:{example:true}});
  assert.equal(requests[0].credentials,'same-origin');assert.equal(requests[0].cache,'no-store');
  assert.equal(new Headers(requests[0].headers).has('X-CSRF-Token'),false);
  assert.equal(new Headers(requests[1].headers).get('X-CSRF-Token'),'memory-only');
  assert.equal(requests[1].body,'{"example":true}');
  let attempts=0;globalThis.fetch=async()=>{attempts++;return Response.json({detail:'Rejected',requestId:'request-503'},{status:503});};
  await assert.rejects(api('/example',{method:'POST'}),(e:unknown)=>e instanceof ApiError&&e.status===503&&e.requestId==='request-503');assert.equal(attempts,1);
});
test('401 clears CSRF and signals expiry even if response JSON is malformed',async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  setCsrf('obsolete');globalThis.fetch=async()=>new Response('bad json',{status:401,headers:{'X-Request-Id':'correlation-401'}});
  await assert.rejects(api('/protected'),(e:unknown)=>e instanceof ApiError&&e.status===401&&e.requestId==='correlation-401');assert.equal(expired,1);
  globalThis.fetch=async(_url,init)=>{assert.equal(new Headers(init?.headers).has('X-CSRF-Token'),false);return new Response(null,{status:204});};await api('/after',{method:'DELETE'});
});
test('expected anonymous session and invalid login do not broadcast stale session events',async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  globalThis.fetch=async()=>Response.json({detail:'Credenciales no válidas',requestId:'bad-login'},{status:401});
  for(const path of ['/auth/browser/login','/auth/browser/session'])await assert.rejects(api(path),ApiError);
  assert.equal(expired,0);
});
test('HTTP error detail/status/correlation survive and UI formats a safe reference',async()=>{
  globalThis.fetch=async()=>Response.json({detail:'Sin permiso',requestId:'server-403'},{status:403});
  await assert.rejects(api('/monitor'),(e:unknown)=>e instanceof ApiError&&e.status===403&&e.message==='Sin permiso'&&errorMessage(e).includes('Referencia: server-403'));
  globalThis.fetch=async()=>Response.json({detail:'Conflicto'},{status:409,headers:{'X-Request-Id':'header-ref'}});
  await assert.rejects(api('/update'),(e:unknown)=>e instanceof ApiError&&e.requestId==='header-ref');
  assert.equal(errorMessage(new ApiError('Error',400,'<unsafe>\nref')),'Error Referencia: unsaferef');
});
test('network errors differ from invalid credentials; abort is preserved and never retried',async()=>{
  globalThis.fetch=async()=>{throw new TypeError('offline');};await assert.rejects(api('/example'),(e:unknown)=>e instanceof ApiError&&e.status===0&&e.message.includes('conectar'));
  const controller=new AbortController();controller.abort();let calls=0;globalThis.fetch=async()=>{calls++;return Response.json({});};
  await assert.rejects(api('/example',{signal:controller.signal}),{name:'AbortError'});assert.equal(calls,0);
  globalThis.fetch=async()=>{throw new DOMException('cancelled','AbortError');};await assert.rejects(api('/example'),{name:'AbortError'});
});
test('interrupted response retains correlation and JSON null errors still retain HTTP status',async()=>{
  globalThis.fetch=async()=>{const response=new Response('{}',{headers:{'X-Request-Id':'interrupted'}});response.text=async()=>{throw new TypeError('body interrupted');};return response;};
  await assert.rejects(api('/example'),(e:unknown)=>e instanceof ApiError&&e.status===0&&e.requestId==='interrupted');
  globalThis.fetch=async()=>new Response('null',{status:403});
  await assert.rejects(api('/example'),(e:unknown)=>e instanceof ApiError&&e.status===403);
});

for(const path of ['/auth/browser/login','/protected'])test(`late 401 from ${path} rejects its caller without clearing a newer session`,async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  let finish!:(response:Response)=>void;let requests=0;setCsrf('old-session');
  globalThis.fetch=async(_url,init)=>{requests++;if(requests===1){assert.equal(new Headers(init?.headers).get('X-CSRF-Token'),'old-session');return new Promise<Response>(resolve=>{finish=resolve;});}assert.equal(new Headers(init?.headers).get('X-CSRF-Token'),'new-session');return new Response(null,{status:204});};
  const pending=api(path,{method:'POST'}),rejected=assert.rejects(pending,(error:unknown)=>error instanceof ApiError&&error.status===401&&error.requestId==='old-request');
  setCsrf('new-session');finish(Response.json({detail:'Old session rejected',requestId:'old-request'},{status:401}));await rejected;
  await api('/next-write',{method:'POST'});assert.equal(expired,0);assert.equal(requests,2);
});
test('a new session generation is distinct even when its CSRF value is identical',async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  let finish!:(response:Response)=>void;setCsrf('same-value');globalThis.fetch=()=>new Promise<Response>(resolve=>{finish=resolve;});
  const pending=api('/protected'),rejected=assert.rejects(pending,ApiError);setCsrf('same-value');finish(Response.json({}, {status:401}));await rejected;
  globalThis.fetch=async(_url,init)=>{assert.equal(new Headers(init?.headers).get('X-CSRF-Token'),'same-value');return new Response(null,{status:204});};
  await api('/next-write',{method:'POST'});assert.equal(expired,0);
});
test('a 401 body that arrives after a new session cannot expire it',async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  let body!:(text:string)=>void,started!:()=>void;const reading=new Promise<void>(resolve=>{started=resolve;});setCsrf('old-session');
  globalThis.fetch=async()=>{const response=new Response(null,{status:401});response.text=()=>new Promise<string>(resolve=>{body=resolve;started();});return response;};
  const pending=api('/protected'),rejected=assert.rejects(pending,ApiError);await reading;setCsrf('new-session');body('{}');await rejected;
  globalThis.fetch=async(_url,init)=>{assert.equal(new Headers(init?.headers).get('X-CSRF-Token'),'new-session');return new Response(null,{status:204});};await api('/next-write',{method:'POST'});assert.equal(expired,0);
});
test('a cancelled 401 response never invalidates the current session or broadcasts expiry',async()=>{
  const events=new EventTarget();Object.defineProperty(globalThis,'window',{configurable:true,value:events});let expired=0;events.addEventListener('health:session-expired',()=>expired++);
  let body!:(text:string)=>void,started!:()=>void;const reading=new Promise<void>(resolve=>{started=resolve;});const controller=new AbortController();setCsrf('current-session');
  globalThis.fetch=async()=>{const response=new Response(null,{status:401});response.text=()=>new Promise<string>(resolve=>{body=resolve;started();});return response;};
  const pending=api('/protected',{signal:controller.signal}),rejected=assert.rejects(pending,{name:'AbortError'});await reading;controller.abort();body('{}');await rejected;
  globalThis.fetch=async(_url,init)=>{assert.equal(new Headers(init?.headers).get('X-CSRF-Token'),'current-session');return new Response(null,{status:204});};await api('/next-write',{method:'POST'});assert.equal(expired,0);
});
