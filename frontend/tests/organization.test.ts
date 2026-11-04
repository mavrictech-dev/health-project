import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {buildBranchRequest,readOrganizationBranch,readOrganizationConfiguration,organizationMemberView,organizationRoleLabels,organizationStatusLabels,organizationUsage,ambiguousBranchStatus} from '../src/lib/organization-types';
import {liveEntries,liveRoute,organizationPath} from '../src/lib/live-routes';

const member=(id:string,roles:string[],status:string)=>({id,name:'Miembro sintético',email:'private@example.test',clinicalDomain:roles.includes('PRO')?'HUMAN':null,credential:'SYNTHETIC-CREDENTIAL-NOT-FOR-DISPLAY',roles,status,owner:id==='m1',branches:['b1'],specialties:roles.includes('PRO')?['H_GENERAL']:[]});
const configuration=()=>({tenantId:'tenant-a',name:'Organización sintética',branchQuota:3,professionalQuota:5,
  branches:[{id:'b1',name:'Principal',address:'',active:true,external:false},{id:'b2',name:'Inactiva',address:'',active:0,external:0},{id:'b3',name:'Externa',address:'',active:1,external:1}],
  specialties:[{code:'H_GENERAL',name:'Medicina general',domain:'HUMAN',dental:false}],
  members:[member('m1',['ADM'],'ACTIVE'),member('m2',['PRO','ADM'],'ACTIVE'),member('m3',['PRO'],'INVITED'),member('m4',['PRO'],'INACTIVE'),member('m5',['AUD'],'INVITED')]});
test('Branch DTO creates owned active branches only and strips caller flags/revisions',()=>{
  const input={name:'  Sede norte  ',address:'  Dirección sintética  ',active:false,external:true,tenantId:'other',expectedRevision:99};
  assert.deepEqual(buildBranchRequest(input),{name:'Sede norte',address:'Dirección sintética',active:true,external:false});
  assert.equal(input.active,false);
  assert.equal(buildBranchRequest({name:'Sede sin dirección',address:''}).address,'');
});
test('Branch validation follows Java NotBlank and Size boundaries including UTF16 length',()=>{
  for(const name of ['','   ','a'.repeat(161),'😀'.repeat(81)])assert.throws(()=>buildBranchRequest({name,address:''}),/nombre/);
  assert.equal(buildBranchRequest({name:'😀'.repeat(80),address:'a'.repeat(300)}).name.length,160);
  assert.throws(()=>buildBranchRequest({name:'Sede',address:'a'.repeat(301)}),/dirección/);
});
test('usage excludes inactive/external branches and includes invited PRO without double counting roles',()=>{
  const config=readOrganizationConfiguration(configuration(),'tenant-a');
  assert.deepEqual(organizationUsage(config),{branches:1,professionals:2,branchesRemaining:2,professionalsRemaining:3});
  config.branchQuota=0;config.professionalQuota=1;
  assert.deepEqual(organizationUsage(config),{branches:1,professionals:2,branchesRemaining:0,professionalsRemaining:0});
});
test('malformed or foreign configuration cannot become empty data or misleading quota',()=>{
  for(const patch of [{tenantId:'other'},{branches:null},{members:null},{branchQuota:'3'},{professionalQuota:-1},{members:[{id:'m',roles:'PRO',status:'ACTIVE'}]},{members:[{id:'m',roles:['PRO'],status:'UNKNOWN'}]},{branches:[{id:'b',name:'Sede',address:'',external:'false',active:true}]}])assert.throws(()=>readOrganizationConfiguration({...configuration(),...patch},'tenant-a'),/configuración/);
  assert.throws(()=>readOrganizationConfiguration({...configuration(),branches:[configuration().branches[0],configuration().branches[0]]},'tenant-a'));
  assert.throws(()=>readOrganizationConfiguration({...configuration(),members:[configuration().members[0],configuration().members[0]]},'tenant-a'));
  assert.deepEqual(readOrganizationBranch({id:'b',name:'Sede',address:'',external:0,active:1}),{id:'b',name:'Sede',address:'',external:false,active:true});
  assert.throws(()=>readOrganizationBranch({}),/configuración/);
});
test('empty configuration and zero quotas remain actual server values',()=>{
  const config=readOrganizationConfiguration({...configuration(),branches:[],members:[],branchQuota:0,professionalQuota:0},'tenant-a');
  assert.deepEqual(organizationUsage(config),{branches:0,professionals:0,branchesRemaining:0,professionalsRemaining:0});
});
test('only tenant ADM can select organization; every other role and host is denied',()=>{
  const host={platform:false,id:'tenant-a'};
  for(const role of ['ADM','PRO','AUD','REC','PAC','RES','SAD','SOP']){
    const user={id:'u',roles:[role],tenantId:role==='SAD'||role==='SOP'?null:'tenant-a'};
    assert.equal(liveRoute(organizationPath,user,host).kind,role==='ADM'?'allowed':'forbidden');
    assert.equal(liveEntries(user).some(e=>e.view==='organization'),role==='ADM');
    assert.equal(liveRoute(organizationPath,user,{platform:true}).kind,'forbidden');
  }
  for(const roles of [['ADM','PAC'],['ADM','RES'],['ADM','SAD']])assert.equal(liveRoute(organizationPath,{id:'u',roles,tenantId:'tenant-a'},host).kind,'forbidden');
  assert.equal(liveRoute(organizationPath,{id:'u',roles:['ADM'],tenantId:'other'},host).kind,'forbidden');
  assert.deepEqual(liveRoute(organizationPath+'/',{id:'u',roles:['ADM'],tenantId:'tenant-a'},host),{kind:'allowed',view:'organization'});
  const routes=JSON.parse(readFileSync('src/data/routes.json','utf8')) as string[];
  assert.equal(routes.length,81);assert.equal(routes.filter(r=>r===organizationPath).length,1);
});
test('unknown writes require explicit reconciliation; validation/conflicts do not imply success',()=>{
  for(const status of [0,200,201,500,503])assert.equal(ambiguousBranchStatus(status),true);
  for(const status of [400,401,403,409,422])assert.equal(ambiguousBranchStatus(status),false);
});
test('member projection validates backend fields and drops contact/credential data',()=>{
  const config=readOrganizationConfiguration(configuration(),'tenant-a');
  assert.equal(config.members[0].owner,true);assert.equal(config.members[1].owner,false);
  assert.deepEqual(organizationMemberView(config.members[0],config),{name:'Miembro sintético',owner:true,roles:['Administración'],status:'Activo',branches:['Principal'],specialties:[]});
  const projection=JSON.stringify(config);
  for(const privateValue of ['private@example.test','SYNTHETIC-CREDENTIAL-NOT-FOR-DISPLAY','clinicalDomain','credential','email'])assert.equal(projection.includes(privateValue),false);
  const numericOwner=readOrganizationConfiguration({...configuration(),members:[{...member('m1',['ADM'],'ACTIVE'),owner:1}]},'tenant-a');
  assert.equal(numericOwner.members[0].owner,true);
});
test('read-only historical membership accepts no assigned branches without inventing one',()=>{
  const config=readOrganizationConfiguration({...configuration(),members:[{...member('m1',['ADM'],'ACTIVE'),branches:[],specialties:[]}]},'tenant-a');
  const view=organizationMemberView(config.members[0],config);
  assert.deepEqual(view.branches,[]);assert.deepEqual(view.specialties,[]);
  assert.equal(organizationUsage(config).professionals,0);
});
test('known roles/statuses are translated without treating INVITED as mail delivery',()=>{
  for(const role of Object.keys(organizationRoleLabels))for(const status of Object.keys(organizationStatusLabels)){
    const config=readOrganizationConfiguration({...configuration(),members:[member('m1',[role],status)]},'tenant-a');
    const view=organizationMemberView(config.members[0],config);
    assert.equal(view.roles[0],organizationRoleLabels[role as keyof typeof organizationRoleLabels]);
    assert.equal(view.status,organizationStatusLabels[status as keyof typeof organizationStatusLabels]);
  }
  assert.equal(organizationStatusLabels.INVITED,'Invitado');
});
test('malformed member fields/roles/assignments and duplicated identities are rejected safely',()=>{
  const base=member('m1',['ADM'],'ACTIVE');
  const patches=[{id:''},{name:' '},{name:42},{email:null},{clinicalDomain:'ALIEN'},{credential:42},{owner:'true'},{roles:[]},{roles:['SAD']},{roles:['__proto__']},{roles:['ADM','ADM']},{roles:[3]},{status:'SENT'},{branches:null},{branches:[null]},{branches:['b1','b1']},{specialties:{}},{specialties:['H_GENERAL','H_GENERAL']}];
  for(const patch of patches)assert.throws(()=>readOrganizationConfiguration({...configuration(),members:[{...base,...patch}]},'tenant-a'),/configuración/);
  for(const key of Object.keys(base)){
    const incomplete={...base} as Record<string,unknown>;delete incomplete[key];
    assert.throws(()=>readOrganizationConfiguration({...configuration(),members:[incomplete]},'tenant-a'),/configuración/,key);
  }
  assert.throws(()=>readOrganizationConfiguration({...configuration(),members:[base,base]},'tenant-a'),/configuración/);
});
test('unknown assignment references show safe unavailable labels, never raw identifiers',()=>{
  const config=readOrganizationConfiguration({...configuration(),members:[{...member('m1',['ADM'],'ACTIVE'),branches:['not-received-private-id','b2'],specialties:['NOT_RECEIVED_PRIVATE_CODE']}]},'tenant-a');
  const view=organizationMemberView(config.members[0],config);
  assert.deepEqual(view.branches,['Sede no disponible','Inactiva · Inactiva']);
  assert.deepEqual(view.specialties,['Especialidad no disponible']);
  const text=JSON.stringify(view);for(const forbidden of ['not-received-private-id','NOT_RECEIVED_PRIVATE_CODE','m1"'])assert.equal(text.includes(forbidden),false);
});
test('missing/malformed specialty catalog is an error; empty valid catalog has safe unresolved labels',()=>{
  const base=configuration();const missing={...base} as Record<string,unknown>;delete missing.specialties;
  for(const patch of [missing,{...base,specialties:null},{...base,specialties:[{code:'H_GENERAL',name:3,domain:'HUMAN',dental:false}]},{...base,specialties:[{code:'H_GENERAL',name:'Perfil',domain:'OTHER',dental:false}]},{...base,specialties:[base.specialties[0],base.specialties[0]]}])assert.throws(()=>readOrganizationConfiguration(patch,'tenant-a'),/configuración/);
  const empty=readOrganizationConfiguration({...base,specialties:[]},'tenant-a');
  assert.deepEqual(organizationMemberView(empty.members[1],empty).specialties,['Especialidad no disponible']);
  assert.deepEqual(organizationUsage(empty),{branches:1,professionals:2,branchesRemaining:2,professionalsRemaining:3});
});
