import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { liveBase, liveEntries, liveRoute, sessionMatchesHost } from '../src/lib/live-routes';
import { LIVE_PREFERENCES_KEY, readLiveTheme, writeLiveTheme } from '../src/lib/live-preferences';
const platform={platform:true}, tenant={platform:false,id:'tenant-a'};
const user=(role:string,tenantId:string|null=null)=>({id:'server-user',roles:[role],tenantId});

test('host and membership must agree; platform privileges never come from a tenant route',()=>{
  assert.equal(sessionMatchesHost(user('SAD'),platform),true);
  assert.equal(sessionMatchesHost(user('SOP'),tenant),false);
  assert.equal(sessionMatchesHost(user('ADM','tenant-a'),tenant),true);
  assert.equal(sessionMatchesHost(user('ADM','tenant-b'),tenant),false);
  assert.equal(sessionMatchesHost(user('PRO','tenant-a'),platform),false);
  assert.equal(sessionMatchesHost(user('PRO'),tenant),false);
});
test('SAD and SOP have explicit separate spaces; SOP cannot read clients',()=>{
  assert.equal(liveBase(user('SOP')),'/operacion');
  assert.deepEqual(liveRoute('/',user('SAD'),platform),{kind:'allowed',view:'home'});
  for(const route of ['/operacion/inicio','/operacion/cuenta','/operacion/soporte','/operacion/trazabilidad','/operacion/monitor'])assert.equal(liveRoute(route,user('SOP'),platform).kind,'allowed');
  for(const route of ['/saas/clientes','/saas/inicio','/operacion/clientes'])assert.equal(liveRoute(route,user('SOP'),platform).kind,'forbidden');
  assert.equal(liveEntries(user('SOP')).some(e=>e.view==='clients'),false);
  assert.deepEqual(liveRoute('/saas/auditoria/',user('SAD'),platform),{kind:'allowed',view:'trace'});
  assert.deepEqual(liveRoute('/saas/clientes',user('SAD'),platform),{kind:'allowed',view:'clients'});
});
test('tenant audit permissions and portal membership do not silently fall back to home',()=>{
  for(const role of ['ADM','AUD'])assert.equal(liveRoute('/app/monitor',user(role,'tenant-a'),tenant).kind,'allowed');
  for(const role of ['PRO','REC','CAJ'])assert.equal(liveRoute('/app/trazabilidad',user(role,'tenant-a'),tenant).kind,'forbidden');
  for(const role of ['PAC','RES']){
    assert.equal(liveBase(user(role,'tenant-a')),'/portal');
    assert.equal(liveRoute('/portal/cuenta',user(role,'tenant-a'),tenant).kind,'allowed');
    assert.equal(liveRoute('/app/inicio',user(role,'tenant-a'),tenant).kind,'forbidden');
    assert.equal(liveRoute('/portal/monitor',user(role,'tenant-a'),tenant).kind,'forbidden');
  }
  assert.equal(liveRoute('/app/agenda',user('PRO','tenant-a'),tenant).kind,'unavailable');
  assert.equal(liveRoute('/saas/planes',user('SAD'),platform).kind,'unavailable');
  assert.equal(liveRoute('/app/unknown',user('PRO','tenant-a'),tenant).kind,'unavailable');
});
test('live theme reads and writes only its own key and never stores identities/business data',()=>{
  const calls:string[]=[],values=new Map([['health-project-demo-v1','sentinel']]);
  const storage={getItem(key:string){calls.push(key);return values.get(key)||null;},setItem(key:string,value:string){calls.push(key);values.set(key,value);}};
  assert.equal(readLiveTheme(storage),'light');
  writeLiveTheme(storage,'navy');assert.equal(readLiveTheme(storage),'navy');
  assert.equal(values.get('health-project-demo-v1'),'sentinel');
  assert.ok(calls.every(key=>key===LIVE_PREFERENCES_KEY));
  assert.deepEqual(JSON.parse(values.get(LIVE_PREFERENCES_KEY)!),{theme:'navy'});
  values.set(LIVE_PREFERENCES_KEY,'invalid');assert.equal(readLiveTheme(storage),'light');
  assert.equal(readLiveTheme({getItem(){throw Error('blocked');},setItem(){}}),'light');
  assert.doesNotThrow(()=>writeLiveTheme({getItem(){return null;},setItem(){throw Error('blocked');}},'dark'));
});
test('static route generator preserves the existing runtime routes and all three SOP entries',()=>{
  const source=readFileSync('scripts/generate-spec.mjs','utf8');
  const declaration=source.match(/const runtimeRoutes = (\[[^;]+\]);/)?.[0];assert.ok(declaration);
  const runtime=Array.from(runInNewContext(declaration+'\nruntimeRoutes')) as string[];
  const plan=JSON.parse(readFileSync('../docs/frontend-demo/Plan_Frontend.json','utf8'));
  const saas=JSON.parse(readFileSync('src/data/saas-screens.json','utf8'));
  const planned=[...plan.screenPlan,...saas].flatMap(s=>s.routes).filter((r:string)=>r.startsWith('/')).map((r:string)=>r.split('?')[0]);
  const exported=JSON.parse(readFileSync('src/data/routes.json','utf8')) as string[];
  assert.deepEqual([...new Set([...planned,...runtime])].sort(),[...exported].sort());
  assert.equal(exported.length,81);
  for(const route of ['/operacion/soporte','/operacion/trazabilidad','/operacion/monitor'])assert.ok(exported.includes(route));
});

test('patient directory routes are restricted to internal read roles in the matching tenant',()=>{
 for(const role of ['ADM','REC','PRO','ASI','AUD'])assert.deepEqual(liveRoute('/app/pacientes',user(role,'tenant-a'),tenant),{kind:'allowed',view:'patients'});
 for(const role of ['SAD','SOP','PAC','RES','CAJ','unknown'])assert.equal(liveRoute('/app/pacientes',user(role,'tenant-a'),tenant).kind,'forbidden');
 assert.equal(liveRoute('/app/pacientes',user('ADM','tenant-b'),tenant).kind,'forbidden');
 assert.equal(liveRoute('/app/pacientes',user('ADM','tenant-a'),platform).kind,'forbidden');
 for(const role of ['SAD','SOP','PAC','RES'])assert.equal(liveEntries({id:'u',tenantId:'tenant-a',roles:['ADM',role]}).some(e=>e.view==='patients'),false);
});
