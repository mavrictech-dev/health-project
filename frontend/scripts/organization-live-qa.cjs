/* All API transport is intercepted. This does not verify MySQL, persistence,
 * rollback, concurrent transactions, or browsers other than installed Edge. */
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const {mkdirSync,writeFileSync}=require('node:fs');
const assert=require('node:assert/strict');
const port=43120,base=`http://127.0.0.1:${port}`,path='/app/configuracion/organizacion/';
const server=spawn(process.execPath,['scripts/preview-static.cjs'],{env:{...process.env,PORT:String(port)},stdio:['ignore','pipe','pipe'],windowsHide:true});
async function ready(){await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Own organization preview did not start')),15000);server.once('error',reject);server.once('exit',()=>{clearTimeout(timer);reject(Error('Own organization preview exited; check live export and port'));});server.stdout.on('data',data=>{if(data.toString().includes('Health Project:')){clearTimeout(timer);resolve();}});});}
async function stop(){if(server.exitCode!==null||server.signalCode!==null)return;await new Promise(resolve=>{server.once('exit',resolve);server.kill();});}
async function run(){
  const browser=await chromium.launch({channel:'msedge',headless:true});
  try{
    const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce',serviceWorkers:'block'});
    const page=await context.newPage();page.setDefaultTimeout(15000);
    const results=[],requests=[],expectedHttp=[],expectedNetwork=[],unexpectedRequests=[],unexpectedHttp=[],unexpectedNetwork=[],unexpectedConsole=[],jsErrors=[],consoleMessages=[];
    let posts=0,configurationReads=0,resourceConsoleErrors=0;
    const sentinel=JSON.stringify({state:{theme:'dark'},version:2,sentinel:'organization-must-not-touch-demo'});
    await context.addInitScript(value=>{
      const key='health-project-demo-v1',get=Storage.prototype.getItem,set=Storage.prototype.setItem;
      if(get.call(localStorage,key)===null)set.call(localStorage,key,value);
      window.__demoReads=0;window.__demoWrites=0;window.__readDemo=()=>get.call(localStorage,key);
      Storage.prototype.getItem=function(k){if(k===key)window.__demoReads++;return get.call(this,k);};
      Storage.prototype.setItem=function(k,v){if(k===key)window.__demoWrites++;return set.call(this,k,v);};
    },sentinel);
    const branch=(id,name,active=true,external=false)=>({id,name,address:'Dirección sintética',active,external});
    const privateMarkers=['@example.test','PRIVATE-CREDENTIAL','member-private-','branch-main','branch-inactive','branch-external','H_GENERAL','PRIVATE_UNKNOWN_'];
    const member=(suffix,name,roles,status,owner=false)=>({id:'member-private-'+suffix,name,email:suffix+'@example.test',clinicalDomain:roles.includes('PRO')?'HUMAN':null,credential:'PRIVATE-CREDENTIAL-'+suffix,roles,status,owner,branches:['branch-main'],specialties:roles.includes('PRO')?['H_GENERAL']:[]});
    const configuration=()=>({tenantId:'tenant-a',name:'Clínica sintética',branchQuota:3,professionalQuota:5,
      branches:[branch('branch-main','Principal'),branch('branch-inactive','Sede inactiva',false),branch('branch-external','Lugar externo',true,true)],
      specialties:[{code:'H_GENERAL',name:'Medicina general',domain:'HUMAN',dental:false}],
      members:[member('owner','Miembro A',['ADM'],'ACTIVE',true),member('active','Miembro B',['PRO','ADM'],'ACTIVE'),member('invited','Miembro C',['PRO'],'INVITED'),member('inactive','Miembro D',['PRO'],'INACTIVE')]});
    const state={role:'ADM',platform:false,mismatch:false,config:configuration(),configStatus:200,configGate:null,postGate:null,outcome:'success',failReadAfterPost:false};
    await context.route('**/*',async route=>{
      const request=route.request(),url=new URL(request.url()),endpoint=url.pathname,method=request.method();
      try{
      if(!endpoint.startsWith('/api/')){if(url.origin!==base){unexpectedRequests.push({endpoint,method});return route.abort();}return route.continue();}
      requests.push({endpoint,method});
      const answer=(value,status=200)=>route.fulfill({status,contentType:'application/json',headers:{'X-Request-Id':'org-intercepted-reference'},body:JSON.stringify(value)});
      const problem=(status,detail)=>{expectedHttp.push({endpoint,status});return answer({detail,requestId:'org-intercepted-reference'},status);};
      if(endpoint==='/api/public/context')return answer(state.platform?{platform:true,baseDomain:'health.localhost'}:{platform:false,id:'tenant-a',name:'Clínica sintética',hostname:'tenant.health.localhost',baseDomain:'health.localhost'});
      if(endpoint==='/api/auth/browser/session')return answer({user:{id:'synthetic-user',name:'Administrador sintético',email:'admin@example.test',roles:[state.role],tenantId:state.mismatch?'other-tenant':state.platform?null:'tenant-a'},csrfToken:'org-synthetic-csrf',expiresAt:'2099-01-01T00:00:00Z'});
      if(endpoint==='/api/public/status')return answer({mode:'OPEN',message:'Estado interceptado',revision:1});
      if(endpoint==='/api/tenant/configuration'&&method==='GET'){
        configurationReads++;if(state.configGate)await state.configGate;
        return state.configStatus===200?answer(state.config):problem(state.configStatus,state.configStatus===403?'No tienes permiso para consultar':state.configStatus===401?'Sesión no válida':'Configuración temporalmente no disponible');
      }
      if(endpoint==='/api/tenant/branches'&&method==='POST'){
        posts++;assert.equal(request.headers()['x-csrf-token'],'org-synthetic-csrf');
        const payload=request.postDataJSON();assert.deepEqual(Object.keys(payload).sort(),['active','address','external','name']);assert.equal(payload.external,false);assert.equal(payload.active,true);assert.equal(typeof payload.name,'string');assert.equal(typeof payload.address,'string');
        if(state.postGate)await state.postGate;
        if(state.outcome==='quota'){
          state.config={...configuration(),branchQuota:2};state.config.branches.push(branch('other-writer','Sede recibida al refrescar'));
          return problem(409,'No hay capacidad de sedes');
        }
        if(state.outcome==='invalid')return problem(400,'Revisa la dirección');
        if(state.outcome==='forbidden')return problem(403,'No tienes permiso para crear');
        if(state.outcome==='503')return problem(503,'Resultado temporalmente desconocido');
        if(state.outcome==='malformed')return answer({saved:true});
        const saved={id:'created-'+posts,name:payload.name,address:payload.address,external:false,active:true};
        state.config.branches.push({...saved,name:payload.name+' · recibido por GET'});
        if(state.outcome==='network'){expectedNetwork.push(endpoint);return route.abort('failed');}
        if(state.failReadAfterPost)state.configStatus=503;
        return answer(saved);
      }
      unexpectedRequests.push({endpoint,method});return route.abort();
      }catch(error){unexpectedRequests.push({endpoint,method,error:String(error.message).split('\n')[0]});return route.abort();}
    });
    page.on('pageerror',error=>jsErrors.push(error.message));
    page.on('console',message=>{const value=message.text();consoleMessages.push(value);if(message.type()!=='error')return;if(value.startsWith('Failed to load resource:'))resourceConsoleErrors++;else unexpectedConsole.push(value);});
    page.on('response',response=>{if(response.status()<400)return;const endpoint=new URL(response.url()).pathname;if(!expectedHttp.some(e=>e.endpoint===endpoint&&e.status===response.status()))unexpectedHttp.push({endpoint,status:response.status()});});
    page.on('requestfailed',request=>{const endpoint=new URL(request.url()).pathname;if(!expectedNetwork.includes(endpoint)&&!request.failure()?.errorText.includes('ERR_ABORTED'))unexpectedNetwork.push({endpoint,error:request.failure()?.errorText});});
    mkdirSync('test-results',{recursive:true});
    const heading=name=>page.getByRole('heading',{name,exact:true}).waitFor();
    const go=()=>page.goto(base+path,{waitUntil:'networkidle'});
    const privateFree=value=>{for(const marker of privateMarkers)assert.equal(value.includes(marker),false,'Private fixture field leaked');};
    const privacy=async()=>{privateFree(await page.locator('body').innerText());privateFree(await page.locator('html').evaluate(element=>element.outerHTML));privateFree(consoleMessages.join('\n'));};
    const shot=async name=>{await privacy();return page.screenshot({path:`test-results/organization-intercepted-${name}.png`,fullPage:true,mask:[page.locator('input[type=password]')]});};
    const isolated=async()=>{const value=await page.evaluate(()=>({value:window.__readDemo(),reads:window.__demoReads,writes:window.__demoWrites}));assert.equal(value.value,sentinel);assert.equal(value.reads,0);assert.equal(value.writes,0);};
    const capacity=async(branches,professionals)=>{assert.ok((await page.getByTestId('branch-capacity').innerText()).includes(branches));assert.ok((await page.getByTestId('professional-capacity').innerText()).includes(professionals));};
    async function open(name='Sede norte'){
      await page.getByRole('button',{name:'Crear sede propia',exact:true}).click();await page.getByLabel('Nombre de la sede',{exact:true}).fill(name);await page.getByLabel('Dirección (opcional)',{exact:true}).fill('Avenida sintética 123');await page.getByRole('button',{name:'Revisar sede',exact:true}).click();await heading('Revisa la nueva sede');
    }
    async function discard(){await page.getByRole('button',{name:'Cerrar',exact:true}).click();await heading('¿Descartar el borrador?');await page.getByRole('button',{name:'Descartar borrador',exact:true}).click();await page.getByRole('dialog').waitFor({state:'hidden'});}
    try{
      let release;state.config={...configuration(),branches:[],members:[]};state.configGate=new Promise(resolve=>{release=resolve;});
      await page.goto(base+path,{waitUntil:'domcontentloaded'});await page.getByRole('status').filter({hasText:'Cargando configuración'}).waitFor();assert.equal(posts,0);release();state.configGate=null;
      await heading('Sin sedes registradas');await heading('Sin miembros registrados');await capacity('0 de 3','0 de 5');await privacy();await isolated();results.push('loading and genuine empty configuration without fabricated branches or members');

      state.config=configuration();state.configStatus=503;await go();await page.getByRole('alert').filter({hasText:'org-intercepted-reference'}).waitFor();state.configStatus=200;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await page.getByRole('row').filter({hasText:'Sede inactiva'}).waitFor();await capacity('1 de 3','2 de 5');await page.getByRole('row').filter({hasText:'Lugar externo'}).waitFor();await shot('configuration');await isolated();results.push('GET failure/retry and active/inactive/external capacity predicates');

      const team=page.getByRole('table',{name:'Equipo y asignaciones de la configuración consultada'});
      for(const [name,status] of [['Miembro A','Activo'],['Miembro B','Activo'],['Miembro C','Invitado'],['Miembro D','Inactivo']]){const row=team.getByRole('row').filter({hasText:name});await row.waitFor();assert.ok((await row.innerText()).includes(status));assert.ok((await row.innerText()).includes('Principal'));}
      assert.ok((await team.getByRole('row').filter({hasText:'Miembro A'}).innerText()).includes('Propietario'));
      const professionalRow=await team.getByRole('row').filter({hasText:'Miembro B'}).innerText();assert.ok(professionalRow.includes('Profesional'));assert.ok(professionalRow.includes('Administración'));assert.ok(professionalRow.includes('Medicina general'));await privacy();await shot('team-desktop');
      const readOnlyStart=requests.length;await page.getByRole('button',{name:'Actualizar configuración',exact:true}).click();await team.getByRole('row').filter({hasText:'Miembro A'}).waitFor();assert.ok(requests.slice(readOnlyStart).every(request=>request.method==='GET'));results.push('team owner, translated roles/status, assignment names and read-only refresh without contact/credential/internal identifiers');

      for(const corruption of ['missing-name','invalid-role','missing-catalog','duplicate-member','foreign-tenant']){
        state.config=configuration();if(corruption==='missing-name')delete state.config.members[0].name;if(corruption==='invalid-role')state.config.members[0].roles=['UNKNOWN'];if(corruption==='missing-catalog')delete state.config.specialties;if(corruption==='duplicate-member')state.config.members.push({...state.config.members[0]});if(corruption==='foreign-tenant')state.config.tenantId='other-tenant';
        await go();await page.getByRole('alert').filter({hasText:'La configuración recibida no es válida'}).waitFor();assert.equal(await team.count(),0);assert.equal(await page.getByRole('heading',{name:'Sin miembros registrados',exact:true}).count(),0);await privacy();state.config=configuration();await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await team.getByRole('row').filter({hasText:'Miembro A'}).waitFor();await capacity('1 de 3','2 de 5');
      }
      results.push('malformed member/role/catalog, duplicate IDs and foreign tenant reject whole configuration and recover via GET retry');

      state.config=configuration();state.config.members[0].branches=[];state.config.members[0].specialties=['PRIVATE_UNKNOWN_CODE'];state.config.members[1].branches=['PRIVATE_UNKNOWN_BRANCH','branch-inactive'];await go();await team.getByText('Sin sedes asignadas',{exact:true}).waitFor();await team.getByText('Especialidad no disponible',{exact:true}).waitFor();await team.getByText('Sede no disponible',{exact:true}).waitFor();await privacy();await shot('team-unavailable-references');state.config=configuration();await go();await team.getByRole('row').filter({hasText:'Miembro A'}).waitFor();results.push('historical empty assignments and unknown references show honest safe labels, never raw codes');

      state.configStatus=403;await go();await page.getByRole('alert').filter({hasText:'No tienes permiso para consultar'}).waitFor();state.configStatus=200;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await capacity('1 de 3','2 de 5');
      state.configStatus=401;await go();await page.getByRole('alert').filter({hasText:'Tu sesión venció'}).waitFor();assert.equal(await page.locator('.live-organization').count(),0);state.configStatus=200;await go();await capacity('1 de 3','2 de 5');results.push('403 explicit retry and current 401 expires shell instead of showing stale configuration');

      await open('Borrador conservado');await page.getByRole('button',{name:'Cerrar',exact:true}).click();await heading('¿Descartar el borrador?');await page.getByRole('button',{name:'Seguir revisando',exact:true}).click();await heading('Revisa la nueva sede');
      for(const outcome of ['invalid','forbidden']){
        state.outcome=outcome;const before=posts;await page.getByRole('button',{name:'Confirmar sede',exact:true}).click();await page.getByRole('alert').filter({hasText:outcome==='invalid'?'Revisa la dirección':'No tienes permiso para crear'}).waitFor();assert.equal(posts,before+1);await page.getByRole('button',{name:'Volver al formulario',exact:true}).click();assert.equal(await page.getByLabel('Nombre de la sede',{exact:true}).inputValue(),'Borrador conservado');assert.equal(await page.getByLabel('Dirección (opcional)',{exact:true}).inputValue(),'Avenida sintética 123');await page.getByRole('button',{name:'Revisar sede',exact:true}).click();
      }
      state.outcome='quota';const readBefore=configurationReads;await page.getByRole('button',{name:'Confirmar sede',exact:true}).click();await page.getByRole('alert').filter({hasText:'No hay capacidad de sedes'}).waitFor();await capacity('2 de 2','2 de 5');assert.ok(configurationReads>readBefore);assert.equal(await page.getByText('Sede registrada:',{exact:false}).count(),0);await page.getByRole('button',{name:'Volver al formulario',exact:true}).click();assert.equal(await page.getByLabel('Nombre de la sede',{exact:true}).inputValue(),'Borrador conservado');await discard();results.push('dirty close guard and 400/403/409 preserve draft; quota conflict refreshes server configuration');

      for(const outcome of ['503','network','malformed']){
        state.config=configuration();state.outcome=outcome;await go();await open('Sede ambigua '+outcome);const before=posts;await page.getByRole('button',{name:'Confirmar sede',exact:true}).click();await heading('No se confirmó el resultado');assert.equal(posts,before+1);assert.equal(await page.getByRole('button',{name:'Confirmar sede',exact:true}).isDisabled(),true);
        await page.getByRole('button',{name:'Consultar configuración sin reenviar',exact:true}).click();await page.getByText('Consulta actualizada.',{exact:false}).waitFor();assert.equal(posts,before+1);assert.equal(await page.getByRole('button',{name:'Volver al borrador para decidir',exact:true}).isDisabled(),true);await page.getByRole('checkbox').check();await page.getByRole('button',{name:'Volver al borrador para decidir',exact:true}).click();assert.equal(await page.getByLabel('Nombre de la sede',{exact:true}).inputValue(),'Sede ambigua '+outcome);assert.equal(posts,before+1);await discard();
        if(outcome==='network')await page.getByRole('row').filter({hasText:'Sede ambigua network · recibido por GET'}).waitFor();
      }
      results.push('503, aborted network and malformed 2xx block POST replay; GET plus conscious acknowledgement without uniqueness claim');

      state.config=configuration();state.outcome='success';await go();await open('Sede nueva confirmada');const before=posts,readBeforeSuccess=configurationReads;let releasePost;state.postGate=new Promise(resolve=>{releasePost=resolve;});
      await page.getByRole('button',{name:'Confirmar sede',exact:true}).evaluate(button=>{button.click();button.click();});await page.getByRole('button',{name:'Guardando…',exact:true}).waitFor();assert.equal(posts,before+1);assert.equal(configurationReads,readBeforeSuccess);assert.equal(await page.getByText('Sede registrada: Sede nueva confirmada.',{exact:true}).count(),0);releasePost();state.postGate=null;
      await heading('Sede confirmada');await page.getByRole('button',{name:'Ver configuración',exact:true}).click();await page.getByRole('row').filter({hasText:'Sede nueva confirmada · recibido por GET'}).waitFor();await capacity('2 de 3','2 de 5');await shot('confirmed-get');await go();await page.getByRole('row').filter({hasText:'Sede nueva confirmada · recibido por GET'}).waitFor();await isolated();results.push('review and double-click guard; success only after POST response and GET redisplay including reload');

      state.config=configuration();state.failReadAfterPost=true;await go();await open('Sede nueva confirmada sin lectura');await page.getByRole('button',{name:'Confirmar sede',exact:true}).click();await heading('Sede confirmada');await page.getByRole('button',{name:'Ver configuración',exact:true}).click();await page.getByRole('alert').filter({hasText:'Configuración temporalmente no disponible'}).waitFor();state.failReadAfterPost=false;state.configStatus=200;const after=posts;await page.getByRole('button',{name:'Volver a intentar',exact:true}).click();await page.getByRole('row').filter({hasText:'Sede nueva confirmada sin lectura · recibido por GET'}).waitFor();assert.equal(posts,after);results.push('confirmed POST remains truthful when subsequent GET fails; retry reads only');

      await page.setViewportSize({width:390,height:844});for(const [theme,label] of [['light','blanco'],['dark','negro'],['navy','navy']]){await page.getByRole('button',{name:'Tema '+label,exact:true}).click();assert.equal(await page.evaluate(()=>document.documentElement.dataset.theme),theme);assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await shot('mobile-'+theme);await team.screenshot({path:`test-results/organization-intercepted-team-mobile-${theme}.png`});await privacy();await isolated();}
      await open('Sede móvil sintética');assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));await page.getByRole('dialog').getByText('Dirección',{exact:true}).waitFor();await shot('mobile-review');await discard();await isolated();results.push('three mobile 390 themes and review without overflow; live preferences and exact demo sentinel isolated');

      await page.setViewportSize({width:1440,height:1000});for(const [role,platform] of [['SAD',true],['SOP',true],['PRO',false],['AUD',false],['PAC',false],['RES',false]]){
        state.role=role;state.platform=platform;const start=requests.length;await go();await heading('No tienes acceso a esta ruta');assert.equal(await page.getByRole('link',{name:'Organización y sedes',exact:true}).count(),0);assert.equal(requests.slice(start).some(r=>r.endpoint.startsWith('/api/tenant/')||r.endpoint.startsWith('/api/platform/')),false);await privacy();await isolated();
      }
      state.role='ADM';state.platform=false;state.mismatch=true;const start=requests.length;await go();await page.getByRole('alert').filter({hasText:'La sesión no corresponde a este espacio'}).first().waitFor();assert.equal(await page.locator('.live-organization').count(),0);assert.equal(requests.slice(start).some(r=>r.endpoint.startsWith('/api/tenant/')),false);state.mismatch=false;
      results.push('SAD/SOP, non-admin tenant, portal and host mismatch never call tenant/platform endpoints');
      assert.deepEqual(jsErrors,[]);assert.deepEqual(unexpectedRequests,[]);assert.deepEqual(unexpectedHttp,[]);assert.deepEqual(unexpectedNetwork,[]);assert.deepEqual(unexpectedConsole,[]);assert.ok(resourceConsoleErrors<=expectedHttp.length+expectedNetwork.length);
      await privacy();const report=JSON.stringify({network:'all API intercepted; synthetic fixtures',browser:'installed Edge through Playwright Chromium only',mysqlVerified:false,persistenceVerified:false,rollbackVerified:false,concurrencyVerified:false,privacyVerified:true,results,posts,configurationReads,requests,expectedHttp,expectedNetwork,jsErrors,unexpectedRequests,unexpectedHttp,unexpectedNetwork,unexpectedConsole,resourceConsoleErrors},null,2);privateFree(report);writeFileSync('test-results/organization-live-intercepted.json',report);
      console.log(JSON.stringify({passed:results.length,mysqlVerified:false,posts,configurationReads,expectedHttp:expectedHttp.length,expectedNetwork:expectedNetwork.length,jsErrors}));
    }catch(error){await shot('failure');throw error;}
  }finally{await browser.close();}
}
(async()=>{try{await ready();await run();}finally{await stop();}})().catch(error=>{console.error(String(error.message).split('\n')[0]);process.exitCode=1;});
