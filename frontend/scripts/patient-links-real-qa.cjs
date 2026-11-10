'use strict';
/* Prepared real readonly QA. Import is inert. No response substitution or SQL access.
 * EOF and manifest validation precede loading Playwright or starting any browser. */
const RUN='pacqa-20261109-a1',DB='health_project_sqlserver_qa_isolated_20261105',BASE='http://health.localhost:18300';
const HUMAN='c692af54-6391-4e8a-9b95-7bcbdd930bcc',ANIMAL_IDENTIFIER='PACQA-'+RUN+'-ANIMAL-UI';
const HOSTS={human:'qa-3fe6475a3f-a.health.localhost',otherHuman:'qa-3fe6475a3f-b.health.localhost',animal:'qa-3fe6475a3f-v.health.localhost'};
const BROWSER_FLAGS=Object.freeze(['--host-resolver-rules=MAP health.localhost 127.0.0.1, MAP *.health.localhost 127.0.0.1','--no-proxy-server']);
const STEPS=new Set(['setup','browser-launch','context-create','page-create','navigation-access','public-context','login-form','login-submit','login-navigation','session-validation','cookie-validation','api-request','fixture-lookup','ui-ficha','ui-links','ui-assert','capture','logout','cleanup','input','unknown']);
const CATEGORIES=new Set(['DNS','CONNECT','TIMEOUT','JAVASCRIPT','ASSERTION','UNKNOWN']);
const CODES=new Set(['INVALID_FLAGS','INVALID_MANIFEST','INPUT_FAILED','HOST_MISMATCH','SESSION_MISMATCH','INVALID_RESPONSE','UNSAFE_REQUEST','PREREQUISITE_FAILED','REQUEST_ID_INVALID','REQUEST_ID_COLLISION','ASSERTION_FAILED','BROWSER_ERROR','REPORT_FAILED','UNSAFE_DIAGNOSTICS','UNEXPECTED_FAILURE']);
class QaFailure extends Error{constructor(code){super(CODES.has(code)?code:'UNEXPECTED_FAILURE');this.code=this.message;}}
const demand=(value,code='ASSERTION_FAILED')=>{if(!value)throw new QaFailure(code);};
const object=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
const canonical=value=>typeof value==='string'&&value.length===36&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(value);
const exact=(value,keys)=>object(value)&&Object.keys(value).sort().join('|')===[...keys].sort().join('|');
const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
function diagnostic(error,step){
 let category='UNKNOWN';const text=typeof error?.message==='string'?error.message.slice(0,8192):'',name=typeof error?.name==='string'?error.name:'';
 if(error instanceof QaFailure||name==='AssertionError')category='ASSERTION';
 else if(/ERR_NAME_NOT_RESOLVED|ENOTFOUND|\bDNS\b/i.test(text))category='DNS';
 else if(/ERR_CONNECTION|ECONNREFUSED|ECONNRESET|Failed to fetch/i.test(text))category='CONNECT';
 else if(name==='TimeoutError'||/\btimeout\b|timed out/i.test(text))category='TIMEOUT';
 else if(['TypeError','ReferenceError','SyntaxError'].includes(name)||/\b(?:TypeError|ReferenceError|SyntaxError)\b/.test(text))category='JAVASCRIPT';
 return Object.freeze({step:STEPS.has(step)?step:'unknown',category});
}
function launchOptions(){return {channel:'msedge',headless:true,args:[...BROWSER_FLAGS]};}
function validateManifest(value){
 demand(exact(value,['schema','qaDatabase','baseUrl','runId',...Object.keys(HOSTS)]),'INVALID_MANIFEST');
 demand(value.schema==='health-patients-real-qa-v1'&&value.qaDatabase===DB&&value.baseUrl===BASE&&value.runId===RUN,'INVALID_MANIFEST');
 const tenants=new Set();
 for(const key of Object.keys(HOSTS)){
  const p=value[key];demand(exact(p,['hostname','tenantId','email','password'])&&p.hostname===HOSTS[key]&&canonical(p.tenantId)&&!tenants.has(p.tenantId),'INVALID_MANIFEST');tenants.add(p.tenantId);
  demand(typeof p.email==='string'&&p.email.length<=254&&/^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[a-z0-9-]+\.)*example\.test$/.test(p.email)&&typeof p.password==='string'&&p.password.trim().length>0&&p.password.length<=1024,'INVALID_MANIFEST');
 }
 return value;
}
function parseFlags(args){demand(Array.isArray(args)&&args.length===1&&args[0]==='--readonly','INVALID_FLAGS');return {readonly:true};}
function checkHost(value,entry,domain){demand(object(value)&&value.platform===false&&value.hostname===entry.hostname&&value.id===entry.tenantId&&canonical(value.id)&&value.domain===domain,'HOST_MISMATCH');}
function checkSession(value,entry){const user=value?.user;demand(object(user)&&canonical(user.id)&&user.tenantId===entry.tenantId&&user.email===entry.email&&Array.isArray(user.roles)&&Array.from(user.roles).every(r=>typeof r==='string')&&!user.roles.some(r=>['SAD','SOP','PAC','RES'].includes(r))&&user.roles.some(r=>r==='ADM'||r==='REC')&&typeof value.csrfToken==='string'&&!!value.csrfToken,'SESSION_MISMATCH');return {id:user.id,csrfToken:value.csrfToken};}
async function checkSessionCookie(context,origin){const cookies=await context.cookies(origin+'/api/');demand(cookies.some(c=>c.name==='health_session'&&c.httpOnly===true),'SESSION_MISMATCH');}
function readLinks(value,tenantId,patientId,limit){
 demand(canonical(tenantId)&&canonical(patientId)&&Number.isInteger(limit)&&limit>=1&&limit<=21&&Array.isArray(value)&&value.length<=limit,'INVALID_RESPONSE');const users=new Set();
 return Object.freeze(Array.from(value,row=>{
  demand(exact(row,['tenantId','patientId','userId','userName','relationship','active','scopes'])&&row.tenantId===tenantId&&row.patientId===patientId&&canonical(row.userId)&&!users.has(row.userId)&&typeof row.userName==='string'&&row.userName.length<=160&&typeof row.relationship==='string'&&row.relationship.length<=80&&typeof row.active==='boolean'&&Array.isArray(row.scopes),'INVALID_RESPONSE');users.add(row.userId);
  const scopes=Object.freeze(Array.from(row.scopes,scope=>{demand(typeof scope==='string','INVALID_RESPONSE');return scope;}));return Object.freeze({tenantId,patientId,userId:row.userId,userName:row.userName,relationship:row.relationship,active:row.active,scopes});
 }));
}
function checkSubpages(full,first,second){demand(equal(first,full.slice(0,1))&&equal(second,full.slice(1,2)),'INVALID_RESPONSE');}
function patient(value,tenant,domain,id){demand(object(value)&&canonical(value.id)&&value.tenantId===tenant&&value.domain===domain&&(!id||value.id===id)&&typeof value.name==='string'&&!!value.name.trim()&&value.name.length<=160&&typeof value.identifier==='string'&&!!value.identifier.trim()&&value.identifier.length<=100,'PREREQUISITE_FAILED');return value;}
function fixtureResponse(status,value,entry,domain,id){if(status===404){problem(value,404,'/api/patients/'+id);throw new QaFailure('PREREQUISITE_FAILED');}demand(status===200,'INVALID_RESPONSE');return patient(value,entry.tenantId,domain,id);}
function findAnimal(rows,entry){demand(Array.isArray(rows)&&rows.length===1,'PREREQUISITE_FAILED');const p=patient(rows[0],entry.tenantId,'ANIMAL');demand(p.identifier===ANIMAL_IDENTIFIER,'PREREQUISITE_FAILED');return p;}
function problem(value,status,path){demand(object(value)&&value.status===status&&value.instance===path&&typeof value.type==='string'&&value.type.startsWith('urn:health-project:error:')&&canonical(value.requestId),'INVALID_RESPONSE');}
function allowedRequest(method,address,policy,body){
 let url;try{if(typeof address!=='string'||/[\\\x00-\x20\x7f]/.test(address))return false;url=new URL(address);}catch{return false;}
 if(url.origin!==policy.origin||url.username||url.password||url.hash)return false;
 const p=url.pathname;method=method.toUpperCase();
 if(method==='POST')return p==='/api/auth/browser/login'&&!url.search&&policy.loginAllowed===true&&exact(body,['email','password'])&&body.email===policy.loginEmail&&body.password===policy.loginPassword;
 if(method==='DELETE')return p==='/api/auth/browser/session'&&!url.search&&policy.logoutAllowed===true;
 if(!['GET','HEAD'].includes(method))return false;
 if(!p.startsWith('/api/'))return !p.startsWith('/actuator/')&&(p.startsWith('/_next/')||p.startsWith('/app/')||p==='/acceso/'||p==='/favicon.ico'||p==='/');
 if(method!=='GET')return false;
 if(['/api/public/context','/api/public/status','/api/auth/browser/session'].includes(p))return !url.search;
 if(p==='/api/patients')return [...url.searchParams.keys()].sort().join('|')==='limit|offset|query'&&['2','21'].includes(url.searchParams.get('limit'))&&url.searchParams.get('offset')==='0'&&policy.queries.has(url.searchParams.get('query'));
 const match=p.match(/^\/api\/patients\/([^/]+)(\/links)?$/);if(!match||!canonical(match[1])||!policy.ids.has(match[1]))return false;
 if(!match[2])return !url.search;
 return [...url.searchParams.keys()].sort().join('|')==='limit|offset'&&['1','21'].includes(url.searchParams.get('limit'))&&['0','1','20'].includes(url.searchParams.get('offset'));
}
async function guardedRequest(client,path,method='GET',body){
 const url=client.origin+path;demand(allowedRequest(method,url,client.policy,body),'UNSAFE_REQUEST');
 const result=await client.page.evaluate(async({origin,resource,method,body,csrfToken})=>{
  if(window.location.origin!==origin||!resource.startsWith('/')||resource.startsWith('//'))throw new Error('QA_ORIGIN_MISMATCH');
  const response=await fetch(resource,{method,credentials:'same-origin',cache:'no-store',redirect:'error',headers:{'Content-Type':'application/json',...(method==='DELETE'?{'X-CSRF-Token':csrfToken}:{})},body:body===undefined?undefined:JSON.stringify(body)});
  let data=null,jsonValid=true;try{data=await response.json();}catch{jsonValid=false;}
  return {status:response.status,requestId:response.headers.get('x-request-id')||'',jsonValid,data};
 },{origin:client.origin,resource:path,method,body,csrfToken:method==='DELETE'?client.identity.csrfToken:''});
 demand(exact(result,['status','requestId','jsonValid','data'])&&Number.isInteger(result.status)&&result.status>=100&&result.status<=599&&typeof result.requestId==='string'&&result.requestId.length<=100&&typeof result.jsonValid==='boolean','INVALID_RESPONSE');
 return {url:()=>url,status:()=>result.status,headers:()=>({'x-request-id':result.requestId}),json:async()=>{demand(result.jsonValid,'INVALID_RESPONSE');return result.data;}};
}
async function installBrowserGuard(context,policy,onUnsafe){await context.route('**/*',async route=>{try{const request=route.request();let body;if(request.method()==='POST')body=request.postDataJSON();if(!allowedRequest(request.method(),request.url(),policy,body)){onUnsafe();await route.abort();return;}await route.continue();}catch(error){onUnsafe(error);try{await route.abort();}catch{}}});}
function recorder(){const byId=new Map();return {add(value){demand(exact(value,['requestId','status','actorId','tenantId','patientId','phase'])&&canonical(value.requestId)&&canonical(value.tenantId)&&canonical(value.patientId)&&(value.actorId===null||canonical(value.actorId))&&Number.isInteger(value.status)&&value.status>=100&&value.status<=599&&typeof value.phase==='string'&&/^[a-z0-9-]{1,60}$/.test(value.phase),'REQUEST_ID_INVALID');demand(value.status!==401||value.actorId===null,'REQUEST_ID_INVALID');const prior=byId.get(value.requestId);demand(!prior||equal(prior,value),'REQUEST_ID_COLLISION');if(!prior)byId.set(value.requestId,Object.freeze({...value}));},values(){return [...byId.values()];}};}
async function recordResponse(records,client,response,sourcePhase){
 const url=new URL(response.url());if(!url.pathname.endsWith('/links'))return null;
 const requestId=(await response.headers())['x-request-id'],status=response.status(),patientId=url.pathname.split('/')[3];
 records.add({requestId,status,actorId:status===401?null:client.identity?.id||null,tenantId:client.entry.tenantId,patientId,phase:sourcePhase});
 const value=await response.json();if(status===200)return readLinks(value,client.entry.tenantId,patientId,Number(url.searchParams.get('limit')));
 problem(value,status,url.pathname);return null;
}
async function readStdin(stream){const decoder=new TextDecoder('utf-8',{fatal:true});let bytes=0,text='';try{for await(const chunk of stream){const data=Buffer.isBuffer(chunk)?chunk:Buffer.from(chunk);bytes+=data.length;demand(bytes<=65536,'INPUT_FAILED');text+=decoder.decode(data,{stream:true});}text+=decoder.decode();return validateManifest(JSON.parse(text));}catch(error){throw error instanceof QaFailure?error:new QaFailure('INVALID_MANIFEST');}}
function scopeLabel(value){switch(value){case 'APPOINTMENTS':return 'Citas';case 'DOCUMENTS':return 'Documentos';case 'BILLING':return 'Facturación';default:return 'Referencia histórica: '+(value||'(vacía)');}}
async function run(manifest,playwright){
 const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
 const directory=path.resolve('test-results/patient-links-real-qa',RUN,'b5-readonly-e4');
 demand(!fs.existsSync(directory),'REPORT_FAILED');fs.mkdirSync(directory,{recursive:true});
 const records=recorder(),clients=[],checks=[],screenshots=[],pending=new Set();let unsafe=false,responseError=null,pageError=null,fatal=null,failureDiagnostic=null,browser,phase='setup',step='setup';
 const report={schema:'patient-links-real-qa-v1',runId:RUN,mode:'readonly',status:'FAIL',checks,reads:[],screenshots,uiPaging21Exercised:false,inactiveObserved:false,sqlAuditValidated:false};
 const clean=async()=>{await Promise.all([...pending]);demand(!unsafe,'UNSAFE_REQUEST');if(responseError)throw responseError;if(pageError){failureDiagnostic=pageError;throw new QaFailure('BROWSER_ERROR');}};
 const pass=name=>checks.push(name);
 const observe=(client,response,sourcePhase)=>recordResponse(records,client,response,sourcePhase);
 async function api(client,resource,status=200){
  if(!['public-context','session-validation','fixture-lookup'].includes(step))step='api-request';client.phase=phase;const response=await guardedRequest(client,'/api'+resource);
  if(resource.includes('/links?')){const rows=await observe(client,response,phase);demand(response.status()===status,'INVALID_RESPONSE');return rows;}
  demand(response.status()===status,'INVALID_RESPONSE');
  const value=await response.json();if(status!==200)problem(value,status,'/api'+resource);return value;
 }
 async function newClient(key,login=true){
  const entry=manifest[key],origin='http://'+entry.hostname+':18300',domain=key==='animal'?'ANIMAL':'HUMAN';
  step='context-create';const context=await browser.newContext({viewport:{width:1440,height:1000},serviceWorkers:'block',reducedMotion:'reduce'});
  step='page-create';const page=await context.newPage();
  const client={context,page,entry,origin,domain,identity:null,phase:'setup',policy:{origin,loginAllowed:login,loginEmail:entry.email,loginPassword:entry.password,logoutAllowed:login,ids:new Set([HUMAN]),queries:new Set(['',ANIMAL_IDENTIFIER])}};clients.push(client);page.setDefaultTimeout(8000);page.on('pageerror',error=>{pageError=diagnostic(error,step);});
  await installBrowserGuard(context,client.policy,error=>{unsafe=true;if(error)failureDiagnostic=diagnostic(error,step);});
  page.on('response',response=>{if(!new URL(response.url()).pathname.endsWith('/links'))return;const p=observe(client,response,client.phase).then(rows=>{client.lastRows=rows;}).catch(error=>{responseError=error instanceof QaFailure?error:new QaFailure('INVALID_RESPONSE');});pending.add(p);p.finally(()=>pending.delete(p));});
  step='navigation-access';await page.goto(origin+'/acceso/',{waitUntil:'networkidle'});step='public-context';checkHost(await api(client,'/public/context'),entry,domain);
  if(login){step='login-form';await page.locator('#auth-email').fill(entry.email);await page.locator('#auth-password').fill(entry.password);step='login-submit';await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();step='login-navigation';await page.waitForURL(url=>url.pathname.startsWith('/app/'),{waitUntil:'networkidle'});client.policy.loginAllowed=false;step='session-validation';client.identity=checkSession(await api(client,'/auth/browser/session'),entry);step='public-context';checkHost(await api(client,'/public/context'),entry,domain);step='cookie-validation';await checkSessionCookie(context,origin);}
  return client;
 }
 async function open(client,p){
  step='ui-ficha';
  client.phase=phase;const count=records.values().length;client.policy.queries.add(p.identifier);await client.page.goto(client.origin+'/app/pacientes/',{waitUntil:'networkidle'});
  await client.page.getByLabel('Buscar por nombre o identificador',{exact:true}).fill(p.identifier);await client.page.getByRole('button',{name:'Buscar',exact:true}).click();await client.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});
  const row=client.page.getByRole('row').filter({has:client.page.getByRole('cell',{name:p.identifier,exact:true})});demand(await row.count()===1,'PREREQUISITE_FAILED');await row.getByRole('button',{name:/Ver ficha/}).click();await client.page.getByRole('button',{name:'Ver vínculos',exact:true}).waitFor();await clean();demand(records.values().length===count,'ASSERTION_FAILED');
 }
 async function assertRows(client,rows){
  step='ui-assert';
  await clean();const view=client.page.locator('.patient-links'),items=view.locator('.patient-links-list>li');demand(await items.count()===Math.min(rows.length,20));
  for(let i=0;i<Math.min(rows.length,20);i++){const row=rows[i],item=items.nth(i);demand(await item.locator('h3').textContent()===(row.userName||'Nombre sin registrar'));const values=await item.locator('dd').allTextContents();demand(values[0]===(row.relationship||'Relación sin registrar')&&values[1]===(row.active?'Vínculo activo':'Vínculo inactivo'));if(row.scopes.length)demand(equal(await item.locator('.patient-link-scopes>li').allTextContents(),row.scopes.map(scopeLabel)));else demand(values[2]==='Sin alcances registrados');}
  const displayed=await view.innerText();for(const forbidden of [client.entry.email,client.entry.tenantId,...rows.flatMap(row=>[row.patientId,row.userId])])demand(!displayed.includes(forbidden),'INVALID_RESPONSE');
  if(!rows.length)await view.getByText('Este paciente no tiene vínculos registrados',{exact:true}).waitFor();
  demand(await client.page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));demand(await client.page.getByRole('dialog').evaluate(element=>element.scrollWidth<=element.clientWidth));
 }
 async function show(client){step='ui-links';client.phase=phase;await client.page.getByRole('button',{name:'Ver vínculos',exact:true}).click();await client.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();}
 async function capture(client,name){step='capture';await clean();demand(client.identity!==null,'SESSION_MISMATCH');const filename=name+'.png',absolute=path.join(directory,filename);await client.page.screenshot({path:absolute,fullPage:true});screenshots.push({path:path.relative(process.cwd(),absolute).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(fs.readFileSync(absolute)).digest('hex').toUpperCase()});}
 try{
  step='browser-launch';browser=await playwright.chromium.launch(launchOptions());phase='human-login';const human=await newClient('human');phase='human-prerequisite';step='fixture-lookup';human.phase=phase;const fixture=await guardedRequest(human,'/api/patients/'+HUMAN);const hp=fixtureResponse(fixture.status(),await fixture.json(),human.entry,'HUMAN',HUMAN);
  phase='human-page';step='api-request';const rows=await api(human,'/patients/'+HUMAN+'/links?limit=21&offset=0');demand(rows.length>=1,'PREREQUISITE_FAILED');report.inactiveObserved=rows.some(row=>!row.active);
  phase='human-subpage-first';const first=await api(human,'/patients/'+HUMAN+'/links?limit=1&offset=0');phase='human-subpage-second';const second=await api(human,'/patients/'+HUMAN+'/links?limit=1&offset=1');checkSubpages(rows,first,second);pass('human-api-seven-fields-order-subpages');
  phase='human-ui';await open(human,hp);await show(human);demand(equal(human.lastRows,rows));await assertRows(human,rows);await capture(human,'human-desktop');
  if(rows.length===21){report.uiPaging21Exercised=true;phase='human-ui-next';human.phase=phase;await human.page.getByRole('button',{name:'Siguiente',exact:true}).click();await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();demand(human.lastRows.length>0&&equal(human.lastRows[0],rows[20]));await assertRows(human,human.lastRows);phase='human-ui-previous';human.phase=phase;await human.page.getByRole('button',{name:'Anterior',exact:true}).click();await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();}
  else report.pagingLimit='Fixture has fewer than 21 links; real UI lookahead navigation not exercised';
  await human.page.getByRole('button',{name:'Volver a la ficha',exact:true}).click();phase='human-ui-explicit-refresh';const fresh=await api(human,'/patients/'+HUMAN+'/links?limit=21&offset=0');await show(human);demand(equal(human.lastRows,fresh));await assertRows(human,fresh);await human.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();pass('human-ui-opt-in-return-close-refresh');
  for(const width of [1440,390])for(const theme of ['blanco','negro','navy']){phase='human-ui-themes';await human.page.setViewportSize({width,height:width===390?844:1000});await human.page.getByRole('button',{name:'Tema '+theme,exact:true}).click();await open(human,hp);await human.page.getByRole('button',{name:'Ver vínculos',exact:true}).focus();await human.page.keyboard.press('Enter');await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();await assertRows(human,human.lastRows);await capture(human,'human-'+width+'-'+theme);await human.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();}pass('themes-mobile-desktop-keyboard');
  phase='animal-login';const animal=await newClient('animal');phase='animal-prerequisite';const ap=findAnimal(await api(animal,'/patients?'+new URLSearchParams({query:ANIMAL_IDENTIFIER,limit:'2',offset:'0'})),animal.entry);animal.policy.ids.add(ap.id);
  phase='animal-page';demand((await api(animal,'/patients/'+ap.id+'/links?limit=21&offset=0')).length===0,'PREREQUISITE_FAILED');phase='animal-ui';await open(animal,ap);await show(animal);await assertRows(animal,[]);await capture(animal,'animal-empty');await animal.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();pass('animal-api-ui-empty');
  phase='other-human-login';const other=await newClient('otherHuman');phase='other-human-neutral-404';await api(other,'/patients/'+HUMAN+'/links?limit=21&offset=0',404);pass('other-tenant-neutral-404');
  phase='anonymous-401';const anonymous=await newClient('human',false);await api(anonymous,'/patients/'+HUMAN+'/links?limit=21&offset=0',401);pass('anonymous-401');
  phase='human-ui-before-logout';await open(human,hp);await show(human);phase='human-logout';human.logoutAttempted=true;const logout=await guardedRequest(human,'/api/auth/browser/session','DELETE');demand([200,204].includes(logout.status()),'SESSION_MISMATCH');
  phase='human-ui-expired-401';human.phase=phase;await human.page.getByRole('button',{name:'Volver a consultar vínculos',exact:true}).click();await human.page.getByText(/Tu sesión venció o fue revocada/).waitFor();await clean();demand(await human.page.locator('.patient-links').count()===0);pass('logout-query-expires-removes-rows');
  phase='logout-cleanup';for(const client of [animal,other]){client.logoutAttempted=true;const response=await guardedRequest(client,'/api/auth/browser/session','DELETE');demand([200,204].includes(response.status()),'SESSION_MISMATCH');}await clean();report.status='PASS';
 }catch(error){fatal=error instanceof QaFailure?error.code:'UNEXPECTED_FAILURE';report.code=fatal;failureDiagnostic=failureDiagnostic||diagnostic(error,step);}
 finally{
  for(const client of clients)if(client.identity&&!client.logoutAttempted)try{client.logoutAttempted=true;const response=await guardedRequest(client,'/api/auth/browser/session','DELETE');demand([200,204,401].includes(response.status()),'SESSION_MISMATCH');}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'SESSION_MISMATCH';}
  for(const client of clients)try{await client.context.close();}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'BROWSER_ERROR';}
  if(browser)try{await browser.close();}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'BROWSER_ERROR';}
  if(fatal){report.status='FAIL';report.code=fatal;report.diagnostic=failureDiagnostic||diagnostic(null,'cleanup');}report.reads=records.values();report.phase=phase;report.businessWrites=0;report.apiOrSqlAuditCountInferred=false;
  fs.writeFileSync(path.join(directory,'report.json'),JSON.stringify(report,null,2),{flag:'wx'});
 }
 return report;
}
async function cli(args,stream,load=()=>require('playwright')){parseFlags(args);demand(!process.env.DEBUG&&!process.env.PWDEBUG&&!process.env.PLAYWRIGHT_TRACE_DIR,'UNSAFE_DIAGNOSTICS');const manifest=await readStdin(stream);return run(manifest,load());}
module.exports={validateManifest,parseFlags,checkHost,checkSession,checkSessionCookie,readLinks,checkSubpages,patient,fixtureResponse,findAnimal,problem,allowedRequest,guardedRequest,installBrowserGuard,recorder,recordResponse,readStdin,scopeLabel,diagnostic,launchOptions,cli,QaFailure,HOSTS,HUMAN,ANIMAL_IDENTIFIER};
if(require.main===module)void cli(process.argv.slice(2),process.stdin).then(report=>{process.exitCode=report.status==='PASS'?0:1;process.stdout.write(JSON.stringify({control:'runner',status:report.status==='PASS'?'passed':'failed'})+'\n');}).catch(error=>{process.exitCode=1;process.stderr.write(JSON.stringify({control:'runner',status:'failed',code:error instanceof QaFailure?error.code:'UNEXPECTED_FAILURE'})+'\n');});
