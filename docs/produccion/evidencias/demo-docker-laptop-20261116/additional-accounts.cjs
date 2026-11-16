// Supervisor-only verification, executed in the isolated Docker QA image.
const {chromium}=require('/qa/node_modules/playwright');
const fs=require('node:fs/promises'),net=require('node:net'),assert=require('node:assert/strict');
const output='/output/supervisor-accounts',port=Number(process.env.DEMO_PORT||18090);
const tenant=`http://reunion.health.localhost:${port}`,platform=`http://health.localhost:${port}`;
const sockets=new Set();let server,browser,created=false;
(async()=>{
 await fs.mkdir(output);created=true;
 server=net.createServer(client=>{const upstream=net.connect(80,'gateway');for(const s of [client,upstream]){sockets.add(s);s.on('close',()=>sockets.delete(s));s.on('error',()=>{client.destroy();upstream.destroy();});}client.pipe(upstream);upstream.pipe(client);});
 await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'::',resolve);});
 browser=await chromium.launch({headless:true});const accounts=[];
 for(const actor of [{email:'admin@example.test',role:'ADM',base:tenant},{email:'plataforma@example.test',role:'SAD',base:platform}]){
  const context=await browser.newContext({viewport:{width:1440,height:1000},locale:'es-PE',timezoneId:'America/Lima'});
  try{
   const page=await context.newPage(),errors=[],serverErrors=[];page.setDefaultTimeout(25000);
   page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(new URL(r.url()).pathname.startsWith('/api/')&&r.status()>=500)serverErrors.push({path:new URL(r.url()).pathname,status:r.status()});});
   await page.goto(actor.base+'/acceso/');await page.getByLabel('Correo electrónico',{exact:true}).waitFor();
   if(actor.role==='ADM')await page.getByLabel('RUC del Negocio',{exact:true}).fill('20000000001');
   await page.getByLabel('Correo electrónico',{exact:true}).fill(actor.email);await page.getByLabel('Contraseña',{exact:true}).fill(process.env.DEMO_APP_PASSWORD);
   const sessionResponse=page.waitForResponse(r=>new URL(r.url()).pathname==='/api/auth/browser/session'&&r.request().method()==='GET'&&r.status()===200);
   await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();const session=await(await sessionResponse).json();
   assert.equal(session.user.email,actor.email);assert.ok(session.user.roles.includes(actor.role));
   if(actor.role==='ADM'&&!session.branchId){await page.getByRole('heading',{name:'Selecciona una sucursal',exact:true}).waitFor();await page.getByRole('button',{name:/Sede principal · ejemplo/}).click();}
   await page.waitForURL(actor.base+(actor.role==='SAD'?'/saas/inicio/':'/app/inicio/'));
   if(actor.role==='SAD'){
    await page.getByRole('link',{name:'Clientes',exact:true}).click();await page.getByText('Clínica ficticia · reunión',{exact:true}).first().waitFor();
   }else{
    await page.goto(actor.base+'/app/configuracion/organizacion/');await page.getByText('Sede principal · ejemplo',{exact:true}).first().waitFor();
   }
   await page.screenshot({path:output+'/'+actor.role.toLowerCase()+'-desktop.png',fullPage:true});
   await page.setViewportSize({width:390,height:844});assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
   await page.screenshot({path:output+'/'+actor.role.toLowerCase()+'-mobile.png',fullPage:true});
   assert.deepEqual(errors,[]);assert.deepEqual(serverErrors,[]);accounts.push({email:actor.email,role:actor.role,origin:actor.base,finalPath:new URL(page.url()).pathname,pageErrors:errors,serverErrors});
  }finally{await context.request.dispose();await context.close();}
 }
 await fs.writeFile(output+'/result.json',JSON.stringify({status:'PASS',accounts,mockedRequests:false,physicalAudioTested:false,hostRuntimeDependencies:false},null,2));
 console.log('ADDITIONAL_ACCOUNTS_PASS');
})().catch(async e=>{const error=String(e.stack||e).replaceAll(process.env.DEMO_APP_PASSWORD||'no-secret-match','[redacted]');console.error(error);if(created)await fs.writeFile(output+'/FAILED.json',JSON.stringify({status:'FAILED',error},null,2));process.exitCode=1;}).finally(async()=>{await browser?.close();for(const socket of sockets)socket.destroy();server?.close();});
