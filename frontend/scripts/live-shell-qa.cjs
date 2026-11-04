/* Intercepted network only: does not validate MySQL, SMTP, or backend persistence.
 * node scripts/live-shell-qa.cjs [--demo] starts and stops its own static preview.
 */
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const {mkdirSync,writeFileSync}=require('node:fs');
const assert=require('node:assert/strict');
const demo=process.argv.includes('--demo'),port=demo?43118:43117,base=`http://127.0.0.1:${port}`;
const server=spawn(process.execPath,['scripts/preview-static.cjs',...(demo?['--demo']:[])],{env:{...process.env,PORT:String(port)},stdio:['ignore','pipe','pipe'],windowsHide:true});
async function ready(){await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Own preview did not start')),15000);server.once('error',reject);server.once('exit',()=>{clearTimeout(timer);reject(Error('Own preview exited; check export and port availability'));});server.stdout.on('data',data=>{if(data.toString().includes('Health Project:')){clearTimeout(timer);resolve();}});});}
async function stop(){if(server.exitCode!==null||server.signalCode!==null)return;await new Promise(resolve=>{server.once('exit',resolve);server.kill();});}
async function existingDemo(){await new Promise((resolve,reject)=>{const child=spawn(process.execPath,['scripts/demo-qa.cjs'],{env:{...process.env,HEALTH_PREVIEW_URL:base},stdio:'inherit',windowsHide:true});child.once('error',reject);child.once('exit',code=>code===0?resolve():reject(Error('Intercepted demo QA failed')));});}
async function live(){
  const browser=await chromium.launch({channel:'msedge',headless:true});
  const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce',serviceWorkers:'block'});
  const page=await context.newPage(),errors=[],requests=[],blocked=[],results=[];
  const sentinel=JSON.stringify({state:{theme:'dark'},version:2,sentinel:'live-must-not-touch-demo'});
  const state={role:'SAD',tenant:false,valid:true,contextError:false,contextNetworkError:false,sessionError:false,traceStatus:200,logoutError:true,loginError:false,mismatch:false,delay:null};
  await context.addInitScript(value=>{
    const key='health-project-demo-v1',get=Storage.prototype.getItem,set=Storage.prototype.setItem;
    if(get.call(localStorage,key)===null)set.call(localStorage,key,value);
    window.__demoReads=0;window.__demoWrites=0;window.__readDemo=()=>get.call(localStorage,key);
    Storage.prototype.getItem=function(k){if(k===key)window.__demoReads++;return get.call(this,k);};
    Storage.prototype.setItem=function(k,v){if(k===key)window.__demoWrites++;return set.call(this,k,v);};
  },sentinel);
  const host=()=>state.tenant?{platform:false,id:'tenant-a',name:'Clínica de prueba',hostname:'tenant.health.localhost',baseDomain:'health.localhost'}:{platform:true,baseDomain:'health.localhost'};
  const user=()=>({id:'user-synthetic',name:'Revisor de red simulada',email:'qa@example.test',roles:[state.role],tenantId:state.mismatch?'other-tenant':state.tenant?'tenant-a':null});
  const intercept=async route=>{
    const request=route.request(),url=new URL(request.url());
    if(url.pathname.startsWith('/api/')){
      requests.push({path:url.pathname,method:request.method()});
      const answer=(value,status=200)=>route.fulfill({status,contentType:'application/json',headers:{'X-Request-Id':'intercepted-reference'},body:JSON.stringify(value)});
      const problem=status=>answer({detail:status===401?'Sesión no válida':status===403?'No tienes permiso':'Servicio simulado no disponible',requestId:'intercepted-reference'},status);
      if(url.pathname==='/api/public/context'){if(state.delay)await state.delay;if(state.contextNetworkError)return route.abort('failed');return state.contextError?problem(503):answer(host());}
      if(url.pathname==='/api/auth/browser/login'){if(state.loginError)return problem(401);state.valid=true;return answer({user:user(),csrfToken:'synthetic-csrf',expiresAt:'2099-01-01T00:00:00Z'});}
      if(url.pathname==='/api/auth/browser/session'){
        if(request.method()==='DELETE'){if(state.logoutError)return problem(503);assert.equal(request.headers()['x-csrf-token'],'synthetic-csrf');state.valid=false;return route.fulfill({status:204});}
        return state.sessionError?problem(503):!state.valid?problem(401):answer({user:user(),csrfToken:'synthetic-csrf',expiresAt:'2099-01-01T00:00:00Z'});
      }
      if(url.pathname==='/api/public/status')return answer({mode:'OPEN',message:'Estado interceptado',revision:1});
      if(url.pathname==='/api/auth/sessions')return answer([{id:'session-synthetic',current:true,expiresAt:'2099-01-01T00:00:00Z'}]);
      if(url.pathname==='/api/platform/tenants'){
        assert.equal(request.method(),'GET');assert.equal(url.searchParams.get('limit'),'200');
        return answer([{id:'tenant-synthetic',name:'Clínica sintética QA',slug:'tenant',hostname:'tenant.health.localhost',url:'http://tenant.health.localhost:18080',kind:'CLINIC',domain:'HUMAN',status:'ACTIVE',ownerName:'Propietario sintético',ownerEmail:'owner@example.test',timezone:'America/Lima',planName:'Plan sintético',planVersion:1,cycle:'MONTHLY',branchesUsed:1,branchQuota:2,professionalsUsed:3,professionalQuota:5,specialtiesUsed:2,specialtyQuota:4}]);
      }
      if(url.pathname==='/api/platform/tenants/tenant-synthetic')return answer({id:'tenant-synthetic',name:'Clínica sintética QA',slug:'tenant',hostname:'tenant.health.localhost',kind:'CLINIC',domain:'HUMAN',status:'ACTIVE',ownerName:'Propietario sintético',ownerEmail:'owner@example.test',timezone:'America/Lima'});
      if(url.pathname==='/api/platform/tenants/tenant-synthetic/configuration')return answer({planName:'Plan sintético',planVersion:1,cycle:'MONTHLY',branchQuota:2,professionalQuota:5,specialtyQuota:4,baseMinor:10000,branchMinor:2000,professionalMinor:1000,annualDiscount:10,modules:['CORE'],branches:[],specialties:[],members:[],invoices:[]});
      if(url.pathname==='/api/trace/events')return state.traceStatus!==200?problem(state.traceStatus):answer({items:[],hasMore:false,nextCursor:0});
      if(url.pathname==='/api/support')return answer([]);
      if(url.pathname==='/api/monitor')return answer({application:{mode:'OPEN',message:'Estado interceptado',revision:1},database:{status:'UP',latencyMs:1},uptimeMs:100,version:'intercepted',requests:[],samples:[]});
      blocked.push(request.url());return route.abort();
    }
    if(url.origin!==base){blocked.push(request.url());return route.abort();}
    return route.continue();
  };
  await context.route('**/*',intercept);
  page.on('pageerror',error=>errors.push(error.message));page.setDefaultTimeout(15000);
  mkdirSync('test-results',{recursive:true});
  const go=path=>page.goto(base+path,{waitUntil:'networkidle'});
  const heading=name=>page.getByRole('heading',{name,exact:true}).waitFor();
  const isolated=async()=>{const value=await page.evaluate(()=>({value:window.__readDemo(),reads:window.__demoReads,writes:window.__demoWrites}));assert.equal(value.value,sentinel);assert.equal(value.reads,0);assert.equal(value.writes,0);};
  const shot=name=>page.screenshot({path:`test-results/live-intercepted-${name}.png`,fullPage:true});
  try{
    let release;state.delay=new Promise(resolve=>{release=resolve;});
    await page.goto(base+'/',{waitUntil:'domcontentloaded'});await page.getByRole('status').filter({hasText:'Conectando'}).waitFor();await isolated();release();state.delay=null;await heading('Hola, Revisor');assert.ok(!(await page.locator('.runtime-header').innerText()).includes('Ruta no disponible'));results.push('host root loading then server identity');
    state.contextError=true;await go('/saas/inicio/');await page.getByRole('alert').filter({hasText:'intercepted-reference'}).waitFor();assert.equal(await page.locator('.runtime-nav').count(),0);state.contextError=false;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await heading('Hola, Revisor');await isolated();results.push('context error clears shell, safe correlation and retry');
    state.contextNetworkError=true;await go('/saas/inicio/');await page.getByRole('alert').filter({hasText:'No se pudo conectar'}).waitFor();state.contextNetworkError=false;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await heading('Hola, Revisor');await isolated();results.push('network failure differs from invalid credentials');
    await page.getByRole('button',{name:'Cerrar sesión',exact:true}).click();await page.getByRole('alert').filter({hasText:'No se confirmó el cierre'}).waitFor();await heading('Hola, Revisor');await isolated();results.push('failed logout remains truthful and retryable');
    state.traceStatus=403;await go('/saas/trazabilidad/');await page.getByRole('alert').filter({hasText:'intercepted-reference'}).waitFor();state.traceStatus=200;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await page.getByText('No hay movimientos para estos filtros',{exact:true}).waitFor();await isolated();results.push('403 detail and explicit GET retry');
    state.traceStatus=401;await go('/saas/trazabilidad/');await page.getByRole('alert').filter({hasText:'Tu sesión venció'}).waitFor();assert.equal(await page.locator('.runtime-nav').count(),0);state.traceStatus=200;state.valid=false;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await page.getByLabel('Correo electrónico',{exact:true}).fill('qa@example.test');await page.getByLabel('Contraseña',{exact:true}).fill('synthetic-only');state.loginError=true;await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();await page.getByRole('alert').filter({hasText:'Sesión no válida'}).waitFor();state.loginError=false;await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();await heading('Hola, Revisor');await isolated();results.push('401 expiry and rejected login, subsequent confirmed login');
    state.sessionError=true;await go('/saas/inicio/');await page.getByRole('alert').filter({hasText:'Servicio simulado'}).waitFor();assert.equal(await page.locator('.runtime-nav').count(),0);state.sessionError=false;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await heading('Hola, Revisor');results.push('failed session refresh leaves no usable stale identity');
    await go('/saas/clientes/');await heading('Clientes y espacios');await page.getByRole('row').filter({hasText:'Clínica sintética QA'}).waitFor();await page.getByRole('button',{name:'Detalle',exact:true}).click();await heading('Clínica sintética QA');await page.getByText('owner@example.test',{exact:true}).waitFor();await shot('sad-clients-detail');await page.getByRole('button',{name:'Cerrar',exact:true}).click();await isolated();assert.ok(requests.some(r=>r.path==='/api/platform/tenants'));await go('/saas/auditoria/');await heading('Trazabilidad');assert.equal(await page.locator('.runtime-header>div:first-child strong').innerText(),'Auditoría');results.push('baseline SAD clients GET, list/detail and UTF8 audit label preserved');
    const sopRequestsStart=requests.length;state.role='SOP';for(const path of ['/operacion/soporte/','/operacion/trazabilidad/','/operacion/monitor/']){await go(path);await page.locator('.runtime-nav').waitFor();assert.equal(await page.getByRole('link',{name:'Clientes',exact:true}).count(),0);}await go('/saas/clientes/');await heading('No tienes acceso a esta ruta');assert.equal(requests.slice(sopRequestsStart).some(r=>r.path==='/api/platform/tenants'),false);await isolated();results.push('SOP direct exported routes and no clients within SOP scenario');
    state.role='PRO';state.tenant=true;await go('/app/agenda/');await heading('Área todavía no integrada');assert.equal(await page.getByText('Buen día, Dr. Mateo',{exact:true}).count(),0);await go('/app/monitor/');await heading('No tienes acceso a esta ruta');await go('/saas/inicio/');await heading('No tienes acceso a esta ruta');await isolated();results.push('clinical availability, tenant permission and foreign route boundaries');
    state.mismatch=true;await go('/app/inicio/');await page.getByRole('alert').filter({hasText:'no corresponde'}).waitFor();assert.equal(await page.locator('.runtime-nav').count(),0);state.mismatch=false;
    for(const role of ['ADM','AUD']){state.role=role;await go('/app/monitor/');await heading('Estado de la aplicación');}state.role='PAC';await go('/portal/cuenta/');await heading('Mi cuenta y sesiones');await go('/app/inicio/');await heading('No tienes acceso a esta ruta');await isolated();results.push('host mismatch rejected, ADM/AUD monitor and PAC portal');
    state.role='SAD';state.tenant=false;await go('/saas/inicio/');await page.setViewportSize({width:390,height:844});
    for(const [theme,label] of [['light','blanco'],['dark','negro'],['navy','navy']]){await page.getByRole('button',{name:`Tema ${label}`,exact:true}).click();assert.equal(await page.evaluate(()=>document.documentElement.dataset.theme),theme);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await shot(`mobile-${theme}`);}await isolated();await page.reload({waitUntil:'networkidle'});assert.equal(await page.evaluate(()=>document.documentElement.dataset.theme),'navy');results.push('three mobile themes persisted separately and no overflow');
    await page.setViewportSize({width:1440,height:1000});await go('/demo/');await page.locator('.explicit-demo-banner').waitFor();await page.getByRole('button',{name:'Tema negro',exact:true}).click();const demoBeforeExit=await page.evaluate(()=>({value:window.__readDemo(),reads:window.__demoReads,writes:window.__demoWrites}));await page.getByRole('button',{name:'Volver a mi espacio',exact:true}).click();await heading('Hola, Revisor');assert.equal(await page.evaluate(()=>document.documentElement.dataset.theme),'navy');const savedDemo=await page.evaluate(()=>window.__readDemo());assert.equal(JSON.parse(savedDemo).state.theme,'dark');assert.equal(savedDemo,demoBeforeExit.value);assert.deepEqual(await page.evaluate(()=>({reads:window.__demoReads,writes:window.__demoWrites})),{reads:demoBeforeExit.reads,writes:demoBeforeExit.writes});results.push('explicit demo allowed to hydrate its store, exit restores live theme');
    state.logoutError=false;await page.getByRole('button',{name:'Cerrar sesión',exact:true}).click();await page.getByLabel('Correo electrónico',{exact:true}).waitFor();assert.equal(await page.locator('.runtime-nav').count(),0);results.push('confirmed logout returns to access');
    await page.setViewportSize({width:390,height:844});
    for(const theme of ['light','dark','navy']){await page.getByLabel('Tema',{exact:true}).selectOption(theme);assert.equal(await page.evaluate(()=>document.documentElement.dataset.theme),theme);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await shot(`access-mobile-${theme}`);}results.push('mobile access keeps three themes without overflow');
    const storageContext=await browser.newContext({viewport:{width:390,height:844},serviceWorkers:'block'});
    try{
      await storageContext.addInitScript(()=>{for(const name of ['localStorage','sessionStorage'])Object.defineProperty(window,name,{configurable:true,get(){throw new DOMException('Storage blocked for this intercepted scenario','SecurityError');}});});
      await storageContext.route('**/*',intercept);const storagePage=await storageContext.newPage();storagePage.setDefaultTimeout(15000);storagePage.on('pageerror',error=>errors.push(error.message));
      state.valid=false;await storagePage.goto(base+'/acceso/',{waitUntil:'networkidle'});await storagePage.getByLabel('Correo electrónico',{exact:true}).waitFor();
      assert.equal(await storagePage.evaluate(()=>{try{void localStorage;return false;}catch(error){return error.name==='SecurityError';}}),true);
      await storagePage.getByLabel('Tema',{exact:true}).selectOption('navy');assert.equal(await storagePage.evaluate(()=>document.documentElement.dataset.theme),'navy');
      await storagePage.getByLabel('Correo electrónico',{exact:true}).fill('qa@example.test');await storagePage.getByLabel('Contraseña',{exact:true}).fill('synthetic-only');await storagePage.getByRole('button',{name:'Iniciar sesión',exact:true}).click();await storagePage.getByRole('heading',{name:'Hola, Revisor',exact:true}).waitFor();
      await storagePage.getByRole('button',{name:'Tema negro',exact:true}).click();assert.equal(await storagePage.evaluate(()=>document.documentElement.dataset.theme),'dark');assert.ok(await storagePage.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
      await storagePage.screenshot({path:'test-results/live-intercepted-storage-blocked.png',fullPage:true});results.push('blocked storage getters leave access, login and in-memory mobile theme usable');
    }finally{await storageContext.close();}
    assert.deepEqual(errors,[]);assert.deepEqual(blocked,[]);
    writeFileSync('test-results/live-shell-intercepted.json',JSON.stringify({network:'intercepted; no real API',mysqlVerified:false,results,requests,errors,blocked},null,2));
    console.log(JSON.stringify({network:'intercepted',passed:results.length,mysqlVerified:false,errors}));
  }catch(error){await shot('failure');throw error;}finally{await browser.close();}
}
(async()=>{try{await ready();await(demo?existingDemo():live());}finally{await stop();}})().catch(error=>{console.error(error);process.exitCode=1;});
