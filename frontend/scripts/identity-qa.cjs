const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const config=Object.fromEntries(fs.readFileSync(process.env.HEALTH_ENV_FILE || path.resolve('..','.env'),'utf8').replace(/^\uFEFF/,'').split(/\r?\n/).filter(l=>l.includes('=')&&!l.startsWith('#')).map(l=>[l.slice(0,l.indexOf('=')),l.slice(l.indexOf('=')+1)]));
const base=(process.env.HEALTH_TEST_URL || 'http://health.localhost:8080').replace(/\/$/,'');
const mailBase=(process.env.HEALTH_MAILPIT_URL || 'http://127.0.0.1:8025').replace(/\/$/,'');
const results=[];const errors=[];
async function mail(email,segment){for(let i=0;i<30;i++){const data=await(await fetch(mailBase+'/api/v1/messages')).json();for(const item of data.messages){if(!item.To?.some(p=>p.Address===email))continue;const detail=await(await fetch(mailBase+'/api/v1/message/'+item.ID)).json();const link=detail.Text?.match(/https?:\/\/[^\s]+/g)?.find(s=>s.includes(segment));if(link)return link;}await new Promise(r=>setTimeout(r,500));}throw Error('Expected local mail was not delivered');}
(async()=>{
  const browser=await chromium.launch({channel:'msedge',headless:true,args:['--host-resolver-rules=MAP *.health.localhost 127.0.0.1,MAP health.localhost 127.0.0.1']});
  const context=await browser.newContext({viewport:{width:1440,height:1000},reducedMotion:'reduce'});const page=await context.newPage();page.setDefaultTimeout(30000);page.on('pageerror',e=>errors.push(e.message));
  fs.mkdirSync('test-results',{recursive:true});
  try{
    await page.goto(base+'/acceso/');await page.getByLabel('Correo electrónico',{exact:true}).waitFor();
    for(const theme of ['light','dark','navy']){await page.getByLabel('Tema',{exact:true}).selectOption(theme);await page.screenshot({path:`test-results/identity-login-${theme}.png`,fullPage:true});}
    await page.getByLabel('Tema',{exact:true}).selectOption('light');
    await page.getByRole('button',{name:'Solicitar soporte',exact:true}).click();await page.getByRole('heading',{name:'Solicitar soporte',exact:true}).waitFor();
    if(await page.locator('[data-slot="sheet-content"]').getByRole('link',{name:/mavrictec.com/}).getAttribute('href')!=='https://mavrictec.com')throw Error('Incorrect provider URL');
    await page.screenshot({path:'test-results/identity-support-sheet.png',fullPage:true});await page.getByRole('button',{name:'Cerrar',exact:true}).last().click();
    await page.getByLabel('Correo electrónico',{exact:true}).fill(config.BOOTSTRAP_ADMIN_EMAIL);await page.getByLabel('Contraseña',{exact:true}).fill(config.BOOTSTRAP_ADMIN_PASSWORD);await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();
    await page.locator('.runtime-nav').waitFor();results.push('real administrator login');
    if(await page.evaluate(()=>document.cookie.includes('health_session')))throw Error('Session cookie readable by JS');
    await page.locator('.runtime-nav').getByRole('link',{name:'Trazabilidad',exact:true}).click();await page.getByRole('heading',{name:'Trazabilidad',exact:true}).waitFor();await page.locator('.runtime-table tbody tr').first().waitFor();
    await page.getByRole('button',{name:'Ver recorrido',exact:true}).first().click();await page.getByRole('heading',{name:'Recorrido de la operación'}).waitFor();await page.locator('.runtime-timeline li').first().waitFor();await page.screenshot({path:'test-results/identity-trace-detail.png',fullPage:true});await page.getByRole('button',{name:'Cerrar',exact:true}).click();
    const downloadPromise=page.waitForEvent('download');await page.getByRole('button',{name:'Exportar página'}).click();const download=await downloadPromise;await download.saveAs('test-results/identity-trace-export.csv');results.push('trace filtering, detail and CSV export');
    await page.locator('.runtime-nav').getByRole('link',{name:'Estado de la aplicación',exact:true}).click();await page.getByRole('heading',{name:'Servicios operativos',exact:true}).waitFor();await page.screenshot({path:'test-results/identity-monitor-light.png',fullPage:true});
    await page.getByRole('button',{name:'Tema negro',exact:true}).click();await page.screenshot({path:'test-results/identity-monitor-dark.png',fullPage:true});await page.getByRole('button',{name:'Tema navy',exact:true}).click();await page.screenshot({path:'test-results/identity-monitor-navy.png',fullPage:true});results.push('live monitor, white/black/navy');
    let modeFailure;
    try {
      await page.getByRole('button',{name:'Cambiar estado',exact:true}).click();await page.getByLabel('Estado operativo').selectOption('READ_ONLY');await page.getByLabel('Motivo o mensaje').fill('Comprobación UI temporal');await page.getByRole('button',{name:'Confirmar cambio de estado',exact:true}).click();await page.getByRole('heading',{name:'Aplicación en solo lectura',exact:true}).waitFor();
      await page.getByRole('button',{name:'Cambiar estado',exact:true}).click();await page.getByLabel('Estado operativo').selectOption('OPEN');await page.getByLabel('Motivo o mensaje').fill('Todos los servicios disponibles');await page.getByRole('button',{name:'Confirmar cambio de estado',exact:true}).click();await page.getByRole('heading',{name:'Servicios operativos',exact:true}).waitFor();results.push('application state transitions');
    } catch(error) { modeFailure=error; throw error; }
    finally {
      try {
        // Browser fetch keeps host-only cookies AND Chromium's local DNS mapping.
        await page.evaluate(async expectedOrigin => {
          if(location.origin!==expectedOrigin)throw Error('Refusing OPEN restoration outside the selected origin');
          const sessionResponse=await fetch('/api/auth/browser/session',{credentials:'same-origin'});
          if(!sessionResponse.ok)throw Error('Could not obtain the administrator session for OPEN restoration');
          const session=await sessionResponse.json();
          const stateResponse=await fetch('/api/public/status',{credentials:'same-origin'});
          if(!stateResponse.ok)throw Error('Could not read application mode for OPEN restoration');
          const state=await stateResponse.json();
          if(state.mode!=='OPEN') {
            const restored=await fetch('/api/monitor/mode',{method:'PUT',credentials:'same-origin',headers:{'Content-Type':'application/json','X-CSRF-Token':session.csrfToken},body:JSON.stringify({expectedRevision:state.revision,mode:'OPEN',message:'Todos los servicios disponibles'})});
            if(!restored.ok)throw Error('OPEN restoration failed; inspect the selected QA stack');
          }
        },new URL(base).origin);
      } catch(error) {
        if(modeFailure)console.error('OPEN restoration also failed; original UI error preserved.');
        else throw error;
      }
    }
    await page.locator('.runtime-nav').getByRole('link',{name:'Mi cuenta y sesiones',exact:true}).click();await page.getByRole('heading',{name:'Sesiones de tu identidad'}).waitFor();await page.getByText('Esta sesión',{exact:true}).waitFor();await page.getByRole('button',{name:'Cerrar sesión',exact:true}).click();await page.getByRole('heading',{name:'Bienvenido de nuevo',exact:true}).waitFor();results.push('sessions and real logout');
    const run=crypto.randomBytes(4).toString('hex'),email='ui-'+run+'@example.test',password='Health-UI-'+crypto.randomBytes(10).toString('hex');
    await page.goto(base+'/registro/');await page.getByLabel('Tu nombre',{exact:true}).fill('Profesional UI');await page.getByLabel('Nombre del espacio',{exact:true}).fill('Consulta UI '+run);await page.getByLabel('Tu subdominio',{exact:true}).fill('ui-'+run);await page.getByLabel('Correo electrónico',{exact:true}).fill(email);await page.getByLabel('Contraseña',{exact:true}).fill(password);await page.getByLabel('Confirma la contraseña',{exact:true}).fill(password);await page.locator('.auth-consent input').check();await page.getByRole('button',{name:'Crear cuenta',exact:true}).click();await page.getByRole('status').filter({hasText:'Si la solicitud'}).waitFor();
    await page.goto(await mail(email,'/verificar/'));await page.getByRole('button',{name:'Confirmar correo',exact:true}).click();await page.getByText('Correo verificado. Ya puedes iniciar sesión en tu espacio.',{exact:true}).waitFor();results.push('self registration, local mail and verified email');
    await page.getByRole('link',{name:'Volver a iniciar sesión',exact:true}).click();await page.getByLabel('Correo electrónico',{exact:true}).fill(email);await page.getByLabel('Contraseña',{exact:true}).fill(password);await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();await page.locator('.runtime-nav').waitFor();
    await page.getByRole('button',{name:'Cerrar sesión',exact:true}).click();await page.getByRole('link',{name:'Olvidé mi contraseña',exact:true}).click();await page.getByLabel('Correo electrónico',{exact:true}).fill(email);await page.getByRole('button',{name:'Enviar enlace de recuperación',exact:true}).click();await page.getByRole('status').filter({hasText:'Si la solicitud'}).waitFor();
    await page.goto(await mail(email,'/restablecer/'));await page.getByLabel('Nueva contraseña',{exact:true}).fill(password+'-Changed');await page.getByLabel('Confirma la contraseña',{exact:true}).fill(password+'-Changed');await page.getByRole('button',{name:'Guardar contraseña',exact:true}).click();await page.getByText('Contraseña actualizada. Inicia sesión con tu nueva contraseña.',{exact:true}).waitFor();results.push('password recovery through mail link');
    await page.setViewportSize({width:390,height:844});await page.screenshot({path:'test-results/identity-mobile.png',fullPage:true});if(await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+2))throw Error('Mobile overflow');results.push('responsive mobile access');
    if(errors.length)throw Error(errors.join('\n'));
    fs.writeFileSync('test-results/identity-ui.json',JSON.stringify({passed:results.length,results,errors},null,2));console.log('PASS:',results.length,'browser scenarios');
  }catch(e){await page.screenshot({path:'test-results/identity-failure.png',fullPage:true});console.error('Screen alerts:',await page.getByRole('alert').allTextContents());throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e.message);process.exit(1);});
