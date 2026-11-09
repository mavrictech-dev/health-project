'use strict';
/* Prepared real-backend QA. This module performs no I/O on import.
 * Credentials: stdin JSON only. Default --readonly; explicit --allow-synthetic-writes
 * is intended ONLY for a separately authorized, supervisor-prepared local run.
 * No service management, SQL, provisioning, response simulation, traces or session dumps.
 */
const SCHEMA='health-patients-real-qa-v1';
const DATABASE='health_project_sqlserver_qa_isolated_20261105';
const BASE='http://health.localhost:18300';
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const KEYS=['human','otherHuman','animal'];
const CODES=new Set(['INVALID_MANIFEST','INVALID_FLAGS','UNSAFE_DIAGNOSTICS','HOST_MISMATCH','SESSION_MISMATCH','INVALID_RESPONSE','UNSAFE_REQUEST','LOOKUP_TRUNCATED','FIXTURE_COLLISION','UNEXPECTED_STATE','UNCERTAIN_WRITE','WRITE_REJECTED','ASSERTION_FAILED','BROWSER_ERROR','INPUT_FAILED','REPORT_FAILED','UNEXPECTED_FAILURE']);
class QaFailure extends Error { constructor(code){super(CODES.has(code)?code:'UNEXPECTED_FAILURE');this.code=this.message;} }
function demand(ok,code='ASSERTION_FAILED'){if(!ok)throw new QaFailure(code);}
const object=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
const exactKeys=(v,keys)=>object(v)&&Object.keys(v).sort().join('|')===[...keys].sort().join('|');
function validateManifest(v){
 demand(exactKeys(v,['schema','qaDatabase','baseUrl','runId',...KEYS]),'INVALID_MANIFEST');
 demand(v.schema===SCHEMA&&v.qaDatabase===DATABASE&&v.baseUrl===BASE&&typeof v.runId==='string'&&/^pacqa-[a-z0-9][a-z0-9-]{0,33}$/.test(v.runId),'INVALID_MANIFEST');
 const hosts=new Set(),tenants=new Set();
 for(const key of KEYS){const p=v[key];demand(exactKeys(p,['hostname','tenantId','email','password']),'INVALID_MANIFEST');
  demand(typeof p.hostname==='string'&&/^qa-[a-z0-9](?:[a-z0-9-]{0,55}[a-z0-9])?\.health\.localhost$/.test(p.hostname)&&!hosts.has(p.hostname),'INVALID_MANIFEST');
  demand(typeof p.tenantId==='string'&&UUID.test(p.tenantId)&&!tenants.has(p.tenantId),'INVALID_MANIFEST');
  demand(typeof p.email==='string'&&p.email.length<=254&&/^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[a-z0-9-]+\.)*example\.test$/.test(p.email)&&typeof p.password==='string'&&p.password.trim().length>0&&p.password.length<=1024,'INVALID_MANIFEST');
  hosts.add(p.hostname);tenants.add(p.tenantId);
 }
 return v;
}
function parseFlags(args){demand(Array.isArray(args)&&args.length<=1&&args.every(x=>['--readonly','--allow-synthetic-writes'].includes(x)),'INVALID_FLAGS');return {writes:args[0]==='--allow-synthetic-writes'};}
function originFor(entry){return 'http://'+entry.hostname+':18300';}
function checkHost(value,entry,domain){demand(object(value)&&value.platform===false&&value.id===entry.tenantId&&value.hostname===entry.hostname&&value.domain===domain,'HOST_MISMATCH');}
function checkSession(value,entry,write=false){const user=value?.user;demand(object(user)&&typeof user.id==='string'&&UUID.test(user.id)&&user.tenantId===entry.tenantId&&user.email===entry.email&&Array.isArray(user.roles)&&user.roles.every(r=>typeof r==='string')&&!user.roles.some(r=>['SAD','SOP','PAC','RES'].includes(r))&&user.roles.some(r=>(write?['ADM','REC','PRO']:['ADM','REC','PRO','ASI','AUD']).includes(r))&&typeof value.csrfToken==='string'&&!!value.csrfToken,'SESSION_MISMATCH');return user.id;}
function validDate(v){if(typeof v!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(v)||v<'0001-01-01')return false;const t=new Date(v+'T00:00:00Z');return Number.isFinite(t.getTime())&&t.toISOString().slice(0,10)===v;}
function patientShape(p,tenant,domain){demand(object(p)&&typeof p.id==='string'&&UUID.test(p.id)&&p.tenantId===tenant&&p.domain===domain&&typeof p.name==='string'&&!!p.name.trim()&&p.name.length<=160&&typeof p.identifier==='string'&&!!p.identifier.trim()&&p.identifier.length<=100&&(p.birthDate===null||validDate(p.birthDate))&&(p.species===null||typeof p.species==='string'&&p.species.length<=80)&&object(p.contact)&&Array.isArray(p.allergies)&&p.allergies.every(a=>typeof a==='string'&&a.length<=160)&&Number.isSafeInteger(p.revision)&&p.revision>0&&typeof p.createdAt==='string'&&/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z$/.test(p.createdAt)&&Number.isFinite(Date.parse(p.createdAt)),'INVALID_RESPONSE');return p;}
function equal(a,b){if(Array.isArray(a)||Array.isArray(b))return Array.isArray(a)&&Array.isArray(b)&&a.length===b.length&&a.every((v,i)=>equal(v,b[i]));if(object(a)||object(b))return object(a)&&object(b)&&Object.keys(a).length===Object.keys(b).length&&Object.keys(a).every(k=>Object.hasOwn(b,k)&&equal(a[k],b[k]));return a===b;}
function fixtureSpec(runId,domain,tag){
 demand(/^pacqa-[a-z0-9][a-z0-9-]{0,33}$/.test(runId)&&['HUMAN','ANIMAL'].includes(domain)&&/^(UI|EDIT|RECOVER|PAGE-(?:0[0-9]|1[0-9]|20))$/.test(tag),'INVALID_MANIFEST');
 const identifier=`PACQA-${runId}-${domain}-${tag}`,opaque=tag!=='UI'&&tag!=='RECOVER';
 return {runId,domain,tag,input:{name:identifier,domain,identifier,birthDate:'2000-01-01',species:domain==='ANIMAL'?'PACQA Canino':null,contact:{phone:tag==='EDIT'?'PACQA-SEED':'PACQA-PHONE',email:runId+'@example.test',...(opaque?{pacqa:{runId,tag,opaque:{keep:['alpha',7,true]}}}:{})},allergies:opaque?['PACQA synthetic allergy']:[]}};
}
function fixtureStage(p,spec){
 const input=spec.input;let stage='initial';
 if(spec.tag==='EDIT'){stage=p.revision===1&&p.contact?.phone==='PACQA-SEED'?'seed':p.revision===2&&p.contact?.phone==='PACQA-FIRST'?'first':p.revision===3&&p.contact?.phone==='PACQA-FINAL'?'complete':'invalid';}
 const expected={...input,contact:{...input.contact,phone:spec.tag==='EDIT'?({'seed':'PACQA-SEED','first':'PACQA-FIRST','complete':'PACQA-FINAL'})[stage]:input.contact.phone}};
 demand(stage!=='invalid'&&Object.keys(input).every(k=>equal(p[k],expected[k]))&&(spec.tag==='EDIT'||p.revision===1),'UNEXPECTED_STATE');return stage;
}
function reconcileFixture(rows,spec,tenant){
 demand(Array.isArray(rows),'INVALID_RESPONSE');demand(rows.length<100,'LOOKUP_TRUNCATED');
 for(const row of rows)patientShape(row,tenant,spec.domain);
 const matches=rows.filter(row=>row.identifier===spec.input.identifier);
 demand(matches.length<=1,'FIXTURE_COLLISION');if(!matches.length)return {action:'create'};
 const p=matches[0];demand(p.name===spec.input.name&&p.domain===spec.domain&&p.tenantId===tenant,'FIXTURE_COLLISION');
 return {action:'reuse',patient:p,stage:fixtureStage(p,spec)};
}
function checkProblem(result,status,resource){demand(result.status===status&&result.jsonValid&&object(result.data)&&result.data.status===status&&typeof result.data.type==='string'&&result.data.type.startsWith('urn:health-project:error:')&&result.data.instance==='/api'+resource,'INVALID_RESPONSE');}
function mutationOutcome(status,jsonValid=true){if(!jsonValid||!Number.isInteger(status)||status===0||status>=500||status>=200&&status<300&&!jsonValid)return 'uncertain';if(status>=200&&status<300)return 'confirmed';return status===409?'rejected-conflict':'rejected';}
function allowedRequest(method,address,policy,body){
 let u;try{u=new URL(address);}catch{return false;}
 if(u.origin!==policy.origin||u.username||u.password)return false;
 method=method.toUpperCase();const p=u.pathname;
 if(['GET','HEAD'].includes(method))return !p.startsWith('/api/')||['/api/public/context','/api/public/status','/api/auth/browser/session'].includes(p)||/^\/api\/patients(?:\/[0-9a-f-]{36})?$/.test(p);
 if(method==='POST'&&p==='/api/auth/browser/login'||method==='DELETE'&&p==='/api/auth/browser/session')return true;
 if(!policy.writes)return false;
 if(method==='POST'&&p==='/api/patients')return policy.inputs.some(input=>equal(input,body));
 if(method==='PUT'&&/^\/api\/patients\/[0-9a-f-]{36}$/.test(p))return policy.ids.has(p.split('/').pop())&&exactKeys(body,['expectedRevision','patient'])&&Number.isSafeInteger(body.expectedRevision)&&body.expectedRevision>0&&policy.inputs.some(input=>equal(input,body.patient));
 return false;
}
const CONTROLS=new Set(['manifest','login','readonly-directory','readonly-detail','readonly-pagination','human-ui','animal-ui','pagination','opaque-edit-conflict','duplicate-recovery','tenant-isolation','host-session-isolation','fixture-capture','logout','runner']);
function safeResult(control,status,code,httpStatus){return {control:CONTROLS.has(control)?control:'runner',status:['passed','failed','reused','resumed','not-applicable'].includes(status)?status:'failed',...(code?{code:CODES.has(code)?code:'UNEXPECTED_FAILURE'}:{}),...(Number.isInteger(httpStatus)&&httpStatus>=100&&httpStatus<=599?{httpStatus}:{})};}
function safeFailure(error){return error instanceof QaFailure&&CODES.has(error.code)?error.code:'UNEXPECTED_FAILURE';}
async function readStdin(stream){const {StringDecoder}=require('node:string_decoder');const decoder=new StringDecoder('utf8');let text='',bytes=0;try{for await(const chunk of stream){const buffer=Buffer.isBuffer(chunk)?chunk:Buffer.from(chunk);bytes+=buffer.length;demand(bytes<=65536,'INPUT_FAILED');text+=decoder.write(buffer);}text+=decoder.end();return validateManifest(JSON.parse(text));}catch(error){throw error instanceof QaFailure?error:new QaFailure('INVALID_MANIFEST');}}
module.exports={validateManifest,parseFlags,checkHost,checkSession,checkProblem,patientShape,fixtureSpec,fixtureStage,reconcileFixture,mutationOutcome,allowedRequest,safeResult,safeFailure,readStdin,QaFailure};

async function run(manifest,flags){
 const {chromium}=require('playwright'),fs=require('node:fs'),path=require('node:path');
 const root=path.resolve('test-results','patients-real-qa',manifest.runId,'attempt-'+Date.now()),checks=[],fixtures=[];
 const report={schema:'health-patients-real-qa-report-v1',runId:manifest.runId,mode:flags.writes?'synthetic-writes':'readonly',checks,fixtures,sqlGrantsVerified:false};
 let browser,current='manifest';const clients=[];let browserError=false,unsafeRequest=false;
 const pass=(control,status='passed')=>checks.push(safeResult(control,status));
 const assertClean=()=>{demand(!browserError,'BROWSER_ERROR');demand(!unsafeRequest,'UNSAFE_REQUEST');};
 function owned(p,spec,entry){patientShape(p,entry.tenantId,spec.domain);demand(p.identifier===spec.input.identifier&&p.name===spec.input.name,'FIXTURE_COLLISION');fixtureStage(p,spec);return p;}
 async function api(client,resource,method='GET',body){
  demand(client.page.url().startsWith(client.origin+'/'),'HOST_MISMATCH');
  try{return await client.page.evaluate(async({resource,method,body,identity})=>{
   const headers={'Content-Type':'application/json'};
   if(!['GET','HEAD'].includes(method)){
    const session=await fetch('/api/auth/browser/session',{credentials:'same-origin',cache:'no-store',redirect:'error'});if(!session.ok)return {status:0,data:null};const value=await session.json();
    if(value.user?.id!==identity.id||value.user?.tenantId!==identity.tenantId||value.user?.email!==identity.email||typeof value.csrfToken!=='string')return {status:0,data:null};headers['X-CSRF-Token']=value.csrfToken;
   }
   const response=await fetch('/api'+resource,{method,headers,credentials:'same-origin',cache:'no-store',redirect:'error',body:body===undefined?undefined:JSON.stringify(body)});
   let data;try{data=await response.json();}catch{return {status:response.status,data:null,jsonValid:false};}return {status:response.status,data,jsonValid:true};
  },{resource,method,body,identity:client.identity});}catch{throw new QaFailure(method==='GET'?'INVALID_RESPONSE':'UNCERTAIN_WRITE');}
 }
 function checked(result,status=200){demand(result.status===status&&result.jsonValid&&result.data!==null,'INVALID_RESPONSE');return result.data;}
 async function newClient(key){
  const entry=manifest[key],domain=key==='animal'?'ANIMAL':'HUMAN',origin=originFor(entry);
  const context=await browser.newContext({viewport:{width:1440,height:1000},serviceWorkers:'block',reducedMotion:'reduce'});
  const page=await context.newPage(),client={context,page,entry,domain,origin,identity:null,policy:{origin,writes:flags.writes,ids:new Set(),inputs:[]},writes:0};clients.push(client);page.setDefaultTimeout(15000);
  context.on('page',p=>p.on('pageerror',()=>{browserError=true;}));page.on('pageerror',()=>{browserError=true;});
  await context.route('**/*',async route=>{try{const r=route.request();let body;const method=r.method();if(['POST','PUT'].includes(method)&&new URL(r.url()).pathname.startsWith('/api/patients')){try{body=r.postDataJSON();}catch{unsafeRequest=true;return route.abort();}}
   if(!allowedRequest(method,r.url(),client.policy,body)){unsafeRequest=true;return route.abort();}if(['POST','PUT'].includes(method)&&new URL(r.url()).pathname.startsWith('/api/patients'))client.writes++;return route.continue();}catch{unsafeRequest=true;return route.abort();}});
  await page.goto(origin+'/acceso/',{waitUntil:'networkidle'});
  checkHost(checked(await api(client,'/public/context')),entry,domain);
  await page.locator('#auth-email').fill(entry.email);await page.locator('#auth-password').fill(entry.password);await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();
  await page.waitForURL(u=>u.pathname.startsWith('/app/'),{waitUntil:'networkidle'});
  const session=checked(await api(client,'/auth/browser/session'));client.identity={id:checkSession(session,entry,flags.writes),tenantId:entry.tenantId,email:entry.email};
  checkHost(checked(await api(client,'/public/context')),entry,domain);
  const cookies=await context.cookies(origin+'/api/');demand(cookies.some(c=>c.name==='health_session'&&c.httpOnly),'SESSION_MISMATCH');
  pass('login');return client;
 }
 async function list(client,query='',offset=0,limit=21){const rows=checked(await api(client,'/patients?'+new URLSearchParams({query,limit:String(limit),offset:String(offset)})));demand(Array.isArray(rows)&&rows.length<=limit,'INVALID_RESPONSE');for(const p of rows)patientShape(p,client.entry.tenantId,client.domain);return rows;}
 async function get(client,id){const p=checked(await api(client,'/patients/'+id));patientShape(p,client.entry.tenantId,client.domain);demand(p.id===id,'INVALID_RESPONSE');return p;}
 async function lookup(client,spec){return reconcileFixture(await list(client,spec.input.identifier,0,100),spec,client.entry.tenantId);}
 async function search(client,query){const p=client.page;await p.goto(client.origin+'/app/pacientes/',{waitUntil:'networkidle'});await p.getByRole('heading',{name:'Pacientes',exact:true}).waitFor();await p.getByLabel('Buscar por nombre o identificador',{exact:true}).fill(query);await p.getByRole('button',{name:'Buscar',exact:true}).click();await p.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});await p.getByRole('region',{name:/Directorio de pacientes/}).waitFor();assertClean();}
 async function open(client,spec){await search(client,spec.input.identifier);const row=client.page.getByRole('row').filter({has:client.page.getByRole('cell',{name:spec.input.identifier,exact:true})});demand(await row.count()===1,'FIXTURE_COLLISION');await row.getByRole('button',{name:/Ver ficha/}).click();await client.page.getByRole('button',{name:'Editar datos administrativos',exact:true}).waitFor();}
 async function form(client,spec,identifier=spec.input.identifier){const p=client.page;await p.getByRole('button',{name:'Crear paciente',exact:true}).click();for(const [label,value] of [['Nombre',spec.input.name],['Identificador',identifier],['Fecha de nacimiento',spec.input.birthDate],['Teléfono',spec.input.contact.phone],['Correo',spec.input.contact.email],...(spec.domain==='ANIMAL'?[['Especie',spec.input.species]]:[])])await p.getByLabel(label,{exact:true}).fill(value);}
 async function review(client){await client.page.getByRole('button',{name:'Revisar datos',exact:true}).click();await client.page.getByRole('heading',{name:'Revisar alta',exact:true}).waitFor();}
 async function uiWrite(client,method,expected=200){
  const p=client.page;
  try{
   const pending=p.waitForResponse(r=>new URL(r.url()).origin===client.origin&&/^\/api\/patients(?:\/[0-9a-f-]{36})?$/.test(new URL(r.url()).pathname)&&r.request().method()===method);
   const [response]=await Promise.all([pending,p.getByRole('button',{name:'Confirmar guardado',exact:true}).click()]);let data;try{data=await response.json();}catch{throw new QaFailure('UNCERTAIN_WRITE');}
   const outcome=mutationOutcome(response.status(),object(data));demand(outcome!=='uncertain','UNCERTAIN_WRITE');demand(response.status()===expected, 'WRITE_REJECTED');
   if(expected===409){try{checkProblem({status:409,jsonValid:true,data},409,new URL(response.url()).pathname.slice(4));}catch{throw new QaFailure('UNCERTAIN_WRITE');}return {status:409,data};}
   try{patientShape(data,client.entry.tenantId,client.domain);}catch{throw new QaFailure('UNCERTAIN_WRITE');}await p.getByText('Paciente guardado y respuesta validada.',{exact:true}).waitFor();await p.getByRole('button',{name:'Editar datos administrativos',exact:true}).waitFor();return data;
  }catch(error){throw error instanceof QaFailure?error:new QaFailure('UNCERTAIN_WRITE');}
 }
 async function capture(client,spec,label){
  demand(flags.writes,'UNSAFE_REQUEST');const p=client.page,dialog=p.getByRole('dialog');demand(await dialog.count()===1&&await dialog.locator('input[type=password]').count()===0,'UNSAFE_REQUEST');
  const expected=spec.input;const hasName=await dialog.getByText(expected.name,{exact:true}).count()||await dialog.locator('#patient-name').inputValue().then(v=>v===expected.name).catch(()=>false);demand(!!hasName,'FIXTURE_COLLISION');
  demand(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'ASSERTION_FAILED');
  await dialog.screenshot({path:path.join(root,label+'.png')});pass('fixture-capture');
 }
 async function ensure(client,spec,viaUi=false){
  const found=await lookup(client,spec);if(found.action==='reuse'){client.policy.ids.add(found.patient.id);fixtures.push({identifier:spec.input.identifier,id:found.patient.id,status:'reused'});return found.patient;}
  client.policy.inputs.push(spec.input);let saved;
  if(viaUi){await search(client,spec.input.identifier);await form(client,spec);for(const width of [1440,390]){await client.page.setViewportSize({width,height:width===390?844:1000});await capture(client,spec,spec.domain.toLowerCase()+'-form-'+width);}await client.page.setViewportSize({width:1440,height:1000});await review(client);saved=await uiWrite(client,'POST');}
  else {const result=await api(client,'/patients','POST',spec.input);const outcome=mutationOutcome(result.status,result.jsonValid&&object(result.data));demand(outcome!=='uncertain','UNCERTAIN_WRITE');demand(outcome==='confirmed','WRITE_REJECTED');saved=result.data;}
  try{owned(saved,spec,client.entry);}catch{throw new QaFailure('UNCERTAIN_WRITE');}
  client.policy.ids.add(saved.id);fixtures.push({identifier:spec.input.identifier,id:saved.id,status:'created'});return saved;
 }
 async function readonly(client){
  const rows=await list(client);await client.page.goto(client.origin+'/app/pacientes/',{waitUntil:'networkidle'});await client.page.getByRole('heading',{name:'Pacientes',exact:true}).waitFor();
  await client.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});const next=client.page.getByRole('button',{name:'Siguiente',exact:true});demand(await next.isEnabled()===(rows.length===21));
  if(rows.length===21){await next.click();await client.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});await client.page.getByRole('button',{name:'Anterior',exact:true}).click();await client.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});pass('readonly-pagination');}else pass('readonly-pagination','not-applicable');
  if(rows.length){await get(client,rows[0].id);await client.page.getByRole('button',{name:/Ver ficha/}).first().click();await client.page.getByRole('heading',{name:'Ficha administrativa',exact:true}).waitFor();await client.page.getByText('Cargando ficha…',{exact:true}).waitFor({state:'hidden'});await client.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();pass('readonly-detail');}else pass('readonly-detail','not-applicable');
  await search(client,'PACQA-'+manifest.runId);demand(client.writes===0,'UNSAFE_REQUEST');pass('readonly-directory');
 }
 async function editForm(client,spec,phone){await open(client,spec);await client.page.getByRole('button',{name:'Editar datos administrativos',exact:true}).click();await client.page.getByLabel('Teléfono',{exact:true}).fill(phone);await client.page.getByRole('button',{name:'Revisar datos',exact:true}).click();await client.page.getByRole('heading',{name:'Revisar cambios',exact:true}).waitFor();}
 async function editConflict(client,spec){
  const initial=await ensure(client,spec),stage=fixtureStage(initial,spec);client.policy.inputs.push({...spec.input,contact:{...spec.input.contact,phone:'PACQA-FIRST'}},{...spec.input,contact:{...spec.input.contact,phone:'PACQA-FINAL'}});
  if(stage==='complete'){pass('opaque-edit-conflict','reused');return;}
  if(stage==='first'){await editForm(client,spec,'PACQA-FINAL');const final=await uiWrite(client,'PUT');owned(final,spec,client.entry);demand(final.revision===3);owned(await get(client,final.id),spec,client.entry);pass('opaque-edit-conflict','resumed');return;}
  const rival=await newClient('human');rival.policy.ids.add(initial.id);rival.policy.inputs.push({...spec.input,contact:{...spec.input.contact,phone:'PACQA-FINAL'}});
  await editForm(client,spec,'PACQA-FIRST');await editForm(rival,spec,'PACQA-FINAL');await client.page.getByText(/Revisión 1/).waitFor();await rival.page.getByText(/Revisión 1/).waitFor();const one=await uiWrite(client,'PUT');owned(one,spec,client.entry);demand(one.revision===2&&equal(one.contact.pacqa,spec.input.contact.pacqa)&&equal(one.allergies,spec.input.allergies));
  const count=rival.writes;await uiWrite(rival,'PUT',409);await rival.page.getByRole('heading',{name:'Conflicto al guardar',exact:true}).waitFor();demand(await rival.page.getByRole('dialog').getByText('PACQA-FINAL',{exact:true}).count()===1);demand(await rival.page.getByRole('button',{name:'Confirmar guardado',exact:true}).isDisabled());
  for(const width of [1440,390]){await rival.page.setViewportSize({width,height:width===390?844:1000});await rival.page.getByRole('dialog').getByRole('alert').scrollIntoViewIfNeeded();await capture(rival,spec,'edit-conflict-'+width);}
  demand(rival.writes===count+1);await rival.page.getByRole('button',{name:'Recargar ficha y descartar borrador',exact:true}).click();await rival.page.getByRole('button',{name:'Editar datos administrativos',exact:true}).waitFor();await rival.page.getByText(/Revisión 2/).waitFor();
  await rival.page.getByRole('button',{name:'Editar datos administrativos',exact:true}).click();await rival.page.getByLabel('Teléfono',{exact:true}).fill('PACQA-FINAL');await rival.page.getByRole('button',{name:'Revisar datos',exact:true}).click();demand(rival.writes===count+1);const final=await uiWrite(rival,'PUT');owned(final,spec,client.entry);demand(final.revision===3&&rival.writes===count+2);owned(await get(client,final.id),spec,client.entry);pass('opaque-edit-conflict');
 }
 async function duplicate(client,main,spec){
  const found=await lookup(client,spec);if(found.action==='reuse'){fixtures.push({identifier:spec.input.identifier,id:found.patient.id,status:'reused'});pass('duplicate-recovery','reused');return;}
  const duplicateInput={...spec.input,identifier:main.input.identifier};client.policy.inputs.push(duplicateInput,spec.input);
  await search(client,spec.input.identifier);await form(client,spec,main.input.identifier);await review(client);const before=client.writes;await uiWrite(client,'POST',409);await client.page.getByRole('heading',{name:'Alta rechazada',exact:true}).waitFor();demand(await client.page.getByRole('button',{name:'Volver al borrador',exact:true}).isEnabled());demand(await client.page.getByRole('button',{name:'Confirmar guardado',exact:true}).isDisabled());
  for(const width of [1440,390]){await client.page.setViewportSize({width,height:width===390?844:1000});await client.page.getByRole('dialog').getByRole('alert').scrollIntoViewIfNeeded();await capture(client,spec,'create-conflict-'+width);}
  await client.page.getByRole('button',{name:'Volver al borrador',exact:true}).click();for(const [key,label] of [['name','Nombre'],['birthDate','Fecha de nacimiento']])demand(await client.page.getByLabel(label,{exact:true}).inputValue()===spec.input[key]);demand(await client.page.getByLabel('Teléfono',{exact:true}).inputValue()===spec.input.contact.phone&&await client.page.getByLabel('Correo',{exact:true}).inputValue()===spec.input.contact.email);
  await client.page.getByLabel('Identificador',{exact:true}).fill(spec.input.identifier);await review(client);demand(client.writes===before+1);const saved=await uiWrite(client,'POST');owned(saved,spec,client.entry);demand(client.writes===before+2);client.policy.ids.add(saved.id);fixtures.push({identifier:spec.input.identifier,id:saved.id,status:'created'});pass('duplicate-recovery');
 }
 try{
  fs.mkdirSync(root,{recursive:true});
  browser=await chromium.launch({channel:'msedge',headless:true,args:['--host-resolver-rules=MAP health.localhost 127.0.0.1, MAP *.health.localhost 127.0.0.1','--no-proxy-server']});
  current='login';const human=await newClient('human'),other=await newClient('otherHuman'),animal=await newClient('animal');
  if(!flags.writes){current='readonly-directory';for(const c of [human,other,animal])await readonly(c);}
  else{
   current='human-ui';const hspec=fixtureSpec(manifest.runId,'HUMAN','UI'),hsaved=await ensure(human,hspec,true);pass('human-ui',fixtures.find(f=>f.id===hsaved.id).status==='reused'?'reused':'passed');
   current='animal-ui';const aspec=fixtureSpec(manifest.runId,'ANIMAL','UI'),asaved=await ensure(animal,aspec,true);pass('animal-ui',fixtures.find(f=>f.id===asaved.id).status==='reused'?'reused':'passed');
   for(const [key,spec,saved] of [['human',hspec,hsaved],['animal',aspec,asaved]]){const fresh=await newClient(key);await fresh.page.reload({waitUntil:'networkidle'});owned(await get(fresh,saved.id),spec,fresh.entry);await open(fresh,spec);for(const value of [spec.input.identifier,spec.input.contact.phone,spec.input.contact.email,...(spec.domain==='ANIMAL'?[spec.input.species]:[])])await fresh.page.getByRole('dialog').getByText(value,{exact:true}).first().waitFor();for(const width of [1440,390]){await fresh.page.setViewportSize({width,height:width===390?844:1000});await capture(fresh,spec,spec.domain.toLowerCase()+'-persisted-'+width);}}
   current='pagination';const pages=[];for(let i=0;i<21;i++){const spec=fixtureSpec(manifest.runId,'HUMAN','PAGE-'+String(i).padStart(2,'0'));pages.push(await ensure(human,spec));}
   const query='PACQA-'+manifest.runId+'-HUMAN-PAGE-',rows=await list(human,query);demand(rows.length===21&&rows.every(r=>pages.some(p=>p.id===r.id)));await search(human,query);demand(await human.page.getByRole('row').count()===21);await human.page.getByRole('button',{name:'Siguiente',exact:true}).click();await human.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});demand(await human.page.getByRole('row').count()===2);demand((await list(human,query,20)).length===1);pass('pagination');
   current='opaque-edit-conflict';await editConflict(human,fixtureSpec(manifest.runId,'HUMAN','EDIT'));
   current='duplicate-recovery';await duplicate(human,hspec,fixtureSpec(manifest.runId,'HUMAN','RECOVER'));
   current='tenant-isolation';for(const [client,id] of [[other,hsaved.id],[animal,hsaved.id],[human,asaved.id]]){checkProblem(await api(client,'/patients/'+id),404,'/patients/'+id);await search(client,id===hsaved.id?hspec.input.identifier:aspec.input.identifier);await client.page.getByRole('heading',{name:'Sin pacientes para esta consulta',exact:true}).waitFor();demand(await client.page.getByRole('button',{name:/Ver ficha/}).count()===0);}pass('tenant-isolation');
   current='host-session-isolation';const isolation=await browser.newContext({serviceWorkers:'block'});try{
    const copied=await human.context.cookies(human.origin+'/api/');await isolation.addCookies(copied.filter(c=>c.name==='health_session').map(c=>({...c,domain:other.entry.hostname})));
    const p=await isolation.newPage();await isolation.route('**/*',route=>{const r=route.request();return r.method()==='GET'&&new URL(r.url()).origin===other.origin?route.continue():route.abort();});
    const response=await p.goto(other.origin+'/api/auth/browser/session');demand(response&&response.status()===401);let data;try{data=await response.json();}catch{throw new QaFailure('INVALID_RESPONSE');}checkProblem({status:response.status(),jsonValid:true,data},401,'/auth/browser/session');pass('host-session-isolation');
   }finally{await isolation.close();}
  }
  assertClean();current='logout';for(const client of clients){const result=await api(client,'/auth/browser/session','DELETE');demand(result.status===200||result.status===204,'SESSION_MISMATCH');}pass('logout');assertClean();
 }catch(error){checks.push(safeResult(current,'failed',safeFailure(error)));process.exitCode=1;}
 finally{
  for(const client of clients)try{await client.context.close();}catch{checks.push(safeResult('runner','failed','BROWSER_ERROR'));process.exitCode=1;}
  if(browser)try{await browser.close();}catch{checks.push(safeResult('runner','failed','BROWSER_ERROR'));process.exitCode=1;}
  try{fs.mkdirSync(root,{recursive:true});fs.writeFileSync(path.join(root,'report.json'),JSON.stringify(report,null,2));}catch{throw new QaFailure('REPORT_FAILED');}
 }
 return report;
}
async function main(){
 try{const flags=parseFlags(process.argv.slice(2));demand(!process.env.DEBUG&&!process.env.PWDEBUG&&!process.env.PLAYWRIGHT_TRACE_DIR,'UNSAFE_DIAGNOSTICS');const manifest=await readStdin(process.stdin);await run(manifest,flags);process.stdout.write(JSON.stringify({control:'runner',status:process.exitCode?'failed':'passed'})+'\n');}
 catch(error){process.exitCode=1;process.stderr.write(JSON.stringify(safeResult('runner','failed',safeFailure(error)))+'\n');}
}
if(require.main===module)void main();
