import test from 'node:test';
import assert from 'node:assert/strict';
import {patientLinksAccess,patientLinksPath,nextPatientLinkOffset,readPatientLinkPage,patientLinkScopeLabel} from '../src/lib/patient-link-types';
const tenant='11111111-1111-1111-1111-111111111111',patient='22222222-2222-2222-2222-222222222222',user='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const host={platform:false,id:tenant,domain:'HUMAN'};
const link=(n=0)=>({tenantId:tenant,patientId:patient,userId:`aaaaaaaa-aaaa-aaaa-aaaa-${String(n).padStart(12,'0')}`,userName:'Nombre histórico',relationship:'',active:false,scopes:['OLD','OLD','DOCUMENTS'],email:'private@example.test',token:'private'});

test('links access requires patient access plus ADM/REC, never write/module/status capability',()=>{
  for(const domain of ['HUMAN','ANIMAL'])for(const roles of [['ADM'],['REC'],['ADM','REC']])assert.equal(patientLinksAccess({id:user,tenantId:tenant,roles},{...host,domain,status:'SUSPENDED',modules:[]} as typeof host),true);
  for(const role of ['PRO','ASI','AUD','CAJ','PAC','RES','SAD','SOP','unknown'])assert.equal(patientLinksAccess({id:user,tenantId:tenant,roles:[role]},host),false);
  for(const role of ['PAC','RES','SAD','SOP'])for(const base of ['ADM','REC'])assert.equal(patientLinksAccess({id:user,tenantId:tenant,roles:[base,role]},host),false);
  for(const invalid of [null,{...host,platform:true},{...host,id:patient},{...host,id:'bad'},{...host,domain:'OTHER'}])assert.equal(patientLinksAccess({id:user,tenantId:tenant,roles:['ADM']},invalid),false);
  assert.equal(patientLinksAccess(null,host),false);assert.equal(patientLinksAccess({id:'bad',tenantId:tenant,roles:['ADM']},host),false);assert.equal(patientLinksAccess({id:user,tenantId:null,roles:['ADM']},host),false);
  assert.equal(patientLinksAccess({id:user+'\n',tenantId:tenant,roles:['ADM']},host),false);assert.equal(patientLinksAccess({id:user,tenantId:tenant+'\n',roles:['ADM']},{...host,id:tenant+'\n'}),false);
});
test('path is canonical, fixed lookahead and SQL integer offset; next avoids overflow',()=>{
  assert.equal(patientLinksPath(patient,20),'/patients/'+patient+'/links?limit=21&offset=20');
  for(const id of ['bad',patient+'\n',patient+'/links',user.toUpperCase()])assert.throws(()=>patientLinksPath(id,0));
  for(const offset of [-1,1.5,NaN,Infinity,2147483648,Number.MAX_SAFE_INTEGER]){assert.throws(()=>patientLinksPath(patient,offset));assert.throws(()=>nextPatientLinkOffset(offset));}
  assert.equal(patientLinksPath(patient,2147483647).endsWith('offset=2147483647'),true);
  assert.equal(nextPatientLinkOffset(0),20);assert.equal(nextPatientLinkOffset(2147483627),2147483647);assert.equal(nextPatientLinkOffset(2147483628),null);assert.equal(nextPatientLinkOffset(2147483647),null);
});
test('page validates all 21 including lookahead, preserves SQL order and has no invented total',()=>{
  const rows=Array.from({length:21},(_,i)=>link(i));rows[0].userName='Zulu';rows[1].userName='Alpha';
  const page=readPatientLinkPage(rows,tenant,patient);assert.equal(page.rows.length,20);assert.equal(page.hasNext,true);assert.deepEqual(page.rows.slice(0,2).map(row=>row.userName),['Zulu','Alpha']);assert.equal('total' in page,false);
  assert.deepEqual(readPatientLinkPage([],tenant,patient),{rows:[],hasNext:false});assert.equal(readPatientLinkPage(rows.slice(0,20),tenant,patient).hasNext,false);
  assert.throws(()=>readPatientLinkPage([...rows,link(22)],tenant,patient));assert.throws(()=>readPatientLinkPage([rows[0],rows[0]],tenant,patient));rows[20].patientId=user;assert.throws(()=>readPatientLinkPage(rows,tenant,patient));
});
test('seven-field immutable projection and independent historical scopes, blanks, inactive link',()=>{
  const raw=link();raw.userName='';raw.relationship='';const out=readPatientLinkPage([raw],tenant,patient),row=out.rows[0];
  assert.deepEqual(Object.keys(row),['tenantId','patientId','userId','userName','relationship','active','scopes']);assert.equal(row.active,false);assert.equal(row.userName,'');assert.equal(row.relationship,'');assert.equal(JSON.stringify(out).includes('private'),false);
  assert.deepEqual(row.scopes,['OLD','OLD','DOCUMENTS']);raw.scopes.push('LATER');raw.userName='changed';assert.equal(row.userName,'');assert.equal(row.scopes.length,3);
  for(const value of [out,out.rows,row,row.scopes])assert.equal(Object.isFrozen(value),true);
  assert.throws(()=>{(row.scopes as string[]).push('changed');});assert.throws(()=>{(out.rows as unknown[]).push({});});
  assert.deepEqual(readPatientLinkPage([{...link(),active:true,scopes:[]}],tenant,patient).rows[0].scopes,[]);
  assert.equal(readPatientLinkPage([{...link(),userName:'x'.repeat(160),relationship:'x'.repeat(80)}],tenant,patient).rows.length,1);
});
test('malformed array/row/required types/foreign identities/scopes fail before any partial rendering',()=>{
  for(const value of [null,{},'[]',1,[null],[[]],[1],new Array(1)])assert.throws(()=>readPatientLinkPage(value,tenant,patient));
  const malformed:Record<string,unknown[]>={tenantId:[null,patient,tenant+'\n'],patientId:[null,tenant,patient+'\n'],userId:[null,1,'bad',user.toUpperCase(),user+'\n'],userName:[null,1,'x'.repeat(161)],relationship:[null,{},'x'.repeat(81)],active:[null,0,1,'true'],scopes:[null,'[]',{},[null],[{}],[1],new Array(1)]};
  for(const [key,values] of Object.entries(malformed))for(const value of values)assert.throws(()=>readPatientLinkPage([{...link(),[key]:value}],tenant,patient),key);
  for(const key of ['tenantId','patientId','userId','userName','relationship','active','scopes']){const row:Record<string,unknown>=link();delete row[key];assert.throws(()=>readPatientLinkPage([row],tenant,patient));}
  for(const [tenantId,patientId] of [['bad',patient],[tenant,'bad'],[tenant+'\n',patient]])assert.throws(()=>readPatientLinkPage([],tenantId,patientId));
});
test('scope labels preserve historical unknowns and duplicates instead of granting rights',()=>{
  assert.deepEqual(['APPOINTMENTS','DOCUMENTS','BILLING'].map(patientLinkScopeLabel),['Citas','Documentos','Facturación']);
  assert.equal(patientLinkScopeLabel('<img onerror=x>'),'Referencia histórica: <img onerror=x>');assert.equal(patientLinkScopeLabel(''),'Referencia histórica: (vacía)');
});
