/* Connected Docker QA only: no request interception, mock API, stored cookies or host runtimes. */
const {chromium}=require('playwright');
const fs=require('node:fs/promises'),path=require('node:path'),net=require('node:net'),assert=require('node:assert/strict');
const port=Number(process.env.DEMO_PORT||18090),run=process.env.QA_RUN_ID||'meeting-review',waitRestart=process.env.QA_WAIT_RESTART==='true';
assert.match(run,/^[a-z0-9-]{1,64}$/);assert.ok(port>1024&&port<=65535);
const base=`http://reunion.health.localhost:${port}`,platform=`http://health.localhost:${port}`,out=path.join('/output',run);
const patient='a4000000-0000-4000-8000-000000000001',branch='a3000000-0000-4000-8000-000000000001';
let browser,context,page,forwarder,ownsOutput=false,phase='active';const errors=[],serverErrors=[],steps=[],http=[],tunnels=new Set();
const record=(check,detail={})=>{steps.push({check,...detail});console.log(JSON.stringify({check,...detail}));};
async function shutdown(){
  try{await context?.request.dispose();}finally{try{await browser?.close();}finally{
    for(const socket of tunnels)socket.destroy();
    if(forwarder?.listening)await new Promise(resolve=>forwarder.close(resolve));
  }}
}
async function checkpoint(name,receipt){
  phase=waitRestart?'controlled-'+name:'active';
  await fs.writeFile(path.join(out,`${name}.json`),JSON.stringify(receipt,null,2));
  if(!waitRestart)return;
  const marker=path.join(out,`resume-${name}`),deadline=Date.now()+15*60*1000;
  while(Date.now()<deadline){try{await fs.access(marker);phase='active';return;}catch{}await new Promise(r=>setTimeout(r,500));}
  throw Error(`CHECKPOINT_TIMEOUT_${name}`);
}
async function shot(name){await page.screenshot({path:path.join(out,`${name}.png`),fullPage:true});}
async function realGet(route){const response=await page.request.get(base+'/api'+route);assert.equal(response.status(),200,route);return response.json();}
async function persisted(id,date,time){
  await page.reload();await page.getByRole('heading',{name:'Agenda',exact:true}).waitFor();
  // Context loading initializes today's date. Wait for it before choosing tomorrow.
  await page.getByLabel('Profesional de agenda',{exact:true}).locator('option').nth(1).waitFor({state:'attached'});
  await page.getByLabel('Fecha de agenda',{exact:true}).fill(date);
  await page.getByRole('button',{name:'Ver cita de Paciente ficticio de reunión a las '+time,exact:true}).waitFor();
  const rows=await realGet('/v1/agenda/citas?'+new URLSearchParams({branchId:branch,from:date+'T05:00:00Z',to:new Date(Date.parse(date+'T05:00:00Z')+86400000).toISOString()}));
  const row=rows.rows.find(r=>r.id===id);assert.ok(row,'Persisted appointment missing');assert.equal(row.collectionStatus,'PAID');assert.equal(row.amountMinor,9550);assert.equal(row.paymentMethod,'YAPE');
  const patients=await realGet('/patients?query=DEMO-001&limit=20&offset=0');assert.equal(patients.length,1);assert.equal(patients[0].id,patient);
  return row;
}
(async()=>{
  await fs.mkdir('/output',{recursive:true});await fs.mkdir(out);ownsOutput=true;
  // Chromium's *.localhost addresses terminate at this runner. Forward TCP unchanged:
  // browser URL, Host, Origin, cookies and CSRF remain the canonical laptop origin.
  forwarder=net.createServer(socket=>{const upstream=net.connect(80,'gateway');for(const tunnel of [socket,upstream]){tunnels.add(tunnel);tunnel.on('close',()=>tunnels.delete(tunnel));}socket.pipe(upstream);upstream.pipe(socket);socket.on('error',()=>upstream.destroy());upstream.on('error',()=>socket.destroy());});
  await new Promise((resolve,reject)=>{forwarder.once('error',reject);forwarder.listen(port,'::',resolve);});
  browser=await chromium.launch({headless:true});
  context=await browser.newContext({viewport:{width:1600,height:1100},locale:'es-PE',timezoneId:'America/Lima'});
  page=await context.newPage();page.setDefaultTimeout(25000);
  page.on('pageerror',e=>errors.push(e.message));
  page.on('response',r=>{const u=new URL(r.url());if(u.pathname.startsWith('/api/')){http.push({method:r.request().method(),path:u.pathname,status:r.status(),phase});if(r.status()>=500)serverErrors.push({path:u.pathname,status:r.status(),phase});}});
  const platformResponse=await context.request.get(platform+'/api/public/context');assert.equal(platformResponse.status(),200);assert.equal((await platformResponse.json()).platform,true);
  const inaccessible=await context.request.get(base+'/demo/');assert.equal(inaccessible.status(),404);
  await page.goto(base+'/acceso/');await page.getByLabel('RUC del Negocio',{exact:true}).waitFor();
  await page.getByLabel('RUC del Negocio',{exact:true}).fill('20000000001');await page.getByLabel('Correo electrónico',{exact:true}).fill('profesional@example.test');await page.getByLabel('Contraseña',{exact:true}).fill(process.env.DEMO_APP_PASSWORD);
  await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();
  await page.getByRole('heading',{name:'Selecciona una sucursal',exact:true}).waitFor();assert.equal(await page.locator('.branch-choices button').count(),2);await shot('01-desktop-sucursales');
  await page.getByRole('button',{name:/Sede principal · ejemplo/}).click();await page.waitForURL(/\/app\/inicio\/?$/);
  await page.goto(base+'/app/agenda/');await page.getByRole('heading',{name:'Agenda',exact:true}).waitFor();await page.getByRole('button',{name:'Nueva cita',exact:true}).waitFor({state:'visible'});
  assert.equal(await page.getByText(/Acceso simulado/).count(),0);await shot('02-desktop-agenda-inicial');
  const today=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Lima',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date()),date=new Date(Date.parse(today+'T12:00:00Z')+86400000).toISOString().slice(0,10);
  const existing=await realGet('/v1/agenda/citas?'+new URLSearchParams({branchId:branch,from:date+'T05:00:00Z',to:new Date(Date.parse(date+'T05:00:00Z')+86400000).toISOString()}));
  let time;for(let hour=8;hour<21;hour++){const slot=`${String(hour).padStart(2,'0')}:00`,start=Date.parse(date+'T'+slot+':00-05:00');if(!existing.rows.some(r=>Date.parse(r.startsAt)<start+1800000&&Date.parse(r.endsAt)>start&&!['CANCELLED','WITHDRAWN','NO_SHOW'].includes(r.status))){time=slot;break;}}assert.ok(time,'No free synthetic future slot');
  const reconciliationRoute='/v1/agenda/arqueo?'+new URLSearchParams({branchId:branch,from:today+'T05:00:00Z',to:new Date(Date.parse(today+'T05:00:00Z')+86400000).toISOString()});
  const initialReconciliation=await realGet(reconciliationRoute),initialYape=Number(initialReconciliation.find(r=>r.paymentMethod==='YAPE')?.netMinor||0),initialReceipts=Number(initialReconciliation.find(r=>r.paymentMethod==='YAPE')?.receipts||0);
  await page.getByLabel('Fecha de agenda',{exact:true}).fill(date);await page.getByRole('button',{name:`Agendar ${date} a las ${time}`,exact:true}).click();
  await page.locator(`#agenda-patient option[value="${patient}"]`).waitFor({state:'attached'});await page.getByLabel('Paciente',{exact:true}).selectOption(patient);await page.getByLabel('Servicio',{exact:true}).fill('Consulta ficticia · '+run);await shot('03-desktop-reserva-formulario');
  const beforePosts=http.filter(r=>r.method==='POST'&&r.path==='/api/appointments').length;
  await page.getByRole('button',{name:'Revisar cita',exact:true}).click();await page.getByRole('heading',{name:'Confirma los datos de la cita',exact:true}).waitFor();assert.equal(http.filter(r=>r.method==='POST'&&r.path==='/api/appointments').length,beforePosts);await shot('04-desktop-revision-explicita');
  const savedResponse=page.waitForResponse(r=>new URL(r.url()).pathname==='/api/appointments'&&r.request().method()==='POST');await page.getByRole('button',{name:'Confirmar cita',exact:true}).click();const saved=await savedResponse;assert.equal(saved.status(),200);const appointment=await saved.json();assert.equal(appointment.branchId,branch);assert.equal(appointment.patientId,patient);
  await page.getByText('Cita registrada en la agenda de esta sucursal.',{exact:true}).waitFor();record('Real browser reservation after explicit review',{appointmentId:appointment.id,date,time});await shot('05-desktop-cita-guardada');
  await page.getByRole('button',{name:new RegExp('Ver cita de Paciente ficticio de reunión a las '+time)}).click();await page.getByLabel('Estatus de cobro',{exact:true}).selectOption('PAID');await page.getByLabel('Importe en soles',{exact:true}).fill('95.50');await page.getByLabel('Medio de Pago',{exact:true}).selectOption('YAPE');await shot('06-desktop-cobro-manual-ficticio');
  await page.getByRole('button',{name:'Guardar estado de cobro',exact:true}).click();await page.getByText('Estado de cobro guardado y arqueo actualizado.',{exact:true}).waitFor();
  await page.getByRole('button',{name:'Hoy',exact:true}).click();const expectedYape=initialYape+9550;
  await page.locator('.agenda-methods > div').filter({hasText:'Yape'}).getByText(new RegExp((expectedYape/100).toFixed(2).replace('.','\\.'))).waitFor();
  const reconciliation=await realGet(reconciliationRoute);assert.equal(Number(reconciliation.find(r=>r.paymentMethod==='YAPE')?.netMinor),expectedYape);assert.equal(Number(reconciliation.find(r=>r.paymentMethod==='YAPE')?.receipts),initialReceipts+1);await shot('07-desktop-arqueo-real');record('Real manual YAPE receipt and branch reconciliation',{amountMinor:9550,paymentMethod:'YAPE',priorNetMinor:initialYape,resultNetMinor:expectedYape,priorReceipts:initialReceipts,resultReceipts:initialReceipts+1});
  const csrfDenied=await context.request.post(base+'/api/v1/auth/sucursal',{headers:{Origin:base},data:{branchId:branch}});assert.equal(csrfDenied.status(),403);record('Real missing-CSRF request denied',{status:403});
  await page.setViewportSize({width:390,height:844});await page.getByRole('button',{name:'Semana',exact:true}).click();await page.locator('.agenda-day').nth(6).waitFor();await shot('08-mobile-semana-real');assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);await page.getByRole('button',{name:'Día',exact:true}).click();await shot('09-mobile-dia-real');
  await page.setViewportSize({width:1600,height:1100});
  const receipt={runId:run,appointmentId:appointment.id,date,time,canonicalOrigin:base,synthetic:true};
  await checkpoint('after-restart',receipt);await persisted(appointment.id,date,time);await shot('10-desktop-persistencia-restart');record('Same browser session and paid appointment after backend restart',{restartPerformed:waitRestart});
  await checkpoint('after-second-up',receipt);await persisted(appointment.id,date,time);await shot('11-desktop-persistencia-segundo-up');record('Same browser session, appointment and unique fixture after second up',{secondUpPerformed:waitRestart});
  const expectedDowntime=serverErrors.filter(r=>r.phase==='controlled-after-restart'&&r.path==='/api/public/status'&&r.status===502);
  assert.deepEqual(errors,[]);assert.deepEqual(serverErrors.filter(r=>!expectedDowntime.includes(r)),[]);
  const result={status:waitRestart?'PASS':'PASS_BROWSER_ONLY',...receipt,playwright:'1.56.1',browser:browser.version(),steps,pageErrors:errors,serverErrors,expectedDowntime,http,physicalAudioTested:false,mockedRequests:false,hostRuntimeDependencies:false};
  await shutdown();await fs.writeFile(path.join(out,'result.json'),JSON.stringify(result,null,2));console.log('CONNECTED_QA_COMPLETE '+run);
})().catch(async e=>{const safe=String(e.stack||e).replaceAll(process.env.DEMO_APP_PASSWORD||'never-match-secret','[redacted]');console.error(safe);if(ownsOutput){await shot('FAILED').catch(()=>{});await fs.writeFile(path.join(out,'FAILED.json'),JSON.stringify({status:'FAILED',error:safe,steps,pageErrors:errors,serverErrors},null,2));}await shutdown();process.exitCode=1;});
