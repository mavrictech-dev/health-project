"""B5 readonly QA operation; default plan/import never reads DPAPI or starts anything.
Canonical integration + explicit reviewed hashes are required before future execution.
"""
import argparse,contextlib,ctypes,hashlib,importlib.util,json,os,re,stat,sys,subprocess
from pathlib import Path
ROOT=Path('D:/Mavric/Health Project');TEMP=Path('C:/Users/maxmo/AppData/Local/Temp')
BASE=ROOT/'scripts/run-patients-real-qa.py';RUNNER=ROOT/'frontend/scripts/patient-links-real-qa.cjs';ENV=TEMP/'B5R3-environment.py';MANIFEST=TEMP/'B5R3-reviewed-pins.json';PREPARED=TEMP/'B4P1-prepared'
LEDGER=PREPARED/'B5-E4-browser-attempt.json';COMPLETED=PREPARED/'B5-E4-browser-completed.json'
READINESS=ROOT/'tmp/patients-real-env-20261109/environment-readiness.json';SEALED=READINESS.with_name('patients-manifest.dpapi');HELPER=ROOT/'scripts/provision-isolated-sqlserver-logins.py'
BASE_SHA='249395F1120CDE3F68426339683BCC2117D3E4993E5C2F5553513FBB56E7EDFE';READINESS_SHA='94C962F88B2C346B6D3CE3DC2C461129B6730E02AF138E392A063C61B9F4EE08';CIPHER_SHA='adf5bada134203d6d69c2d1a662073fe411d2f8ff3f6e983e54fdbcff45d1aed';HELPER_SHA='4415F6DB8260B000F64023DA6D94E088FB49DE53FC55A9EF4140AA0329740EAD'
HOSTS={'human':'qa-3fe6475a3f-a.health.localhost','otherHuman':'qa-3fe6475a3f-b.health.localhost','animal':'qa-3fe6475a3f-v.health.localhost'}
CHECKS={'human-api-seven-fields-order-subpages','human-ui-opt-in-return-close-refresh','themes-mobile-desktop-keyboard','animal-api-ui-empty','other-tenant-neutral-404','anonymous-401','logout-query-expires-removes-rows'}
REPORT=ROOT/'frontend/test-results/patient-links-real-qa/pacqa-20261109-a1/b5-readonly-e4/report.json'
CODES={'PIN_INVALID','INPUT_CHANGED','PATH_SCOPE_CHANGED','PRIOR_ATTEMPT','MANIFEST_CHANGED','MANIFEST_SCOPE_CHANGED','OUTPUT_INVALID','DEADLINE_FAILED','EXECUTION_FAILED','ENVIRONMENT_FAILED','UNSAFE_RUNNER_OUTPUT','RUNNER_TIMEOUT','READINESS_INVALID','PREREQUISITE_FAILED','PROCESS_TIMEOUT','PROCESS_ACTIVE_REMAINS','PROCESS_EARLY_EXIT','PUBLIC_REJECTED','PROCESS_JOB_FAILED','PROCESS_OUTPUT_LIMIT','PROCESS_IO_FAILED','SECRET_OUTPUT_REJECTED'}
CODES.update({'PROCESS_CLEANUP_FAILED','PROCESS_CONTAINMENT_FAILED'})
STEPS={'setup','browser-launch','context-create','page-create','navigation-access','public-context','login-form','login-submit','login-navigation','session-validation','cookie-validation','api-request','fixture-lookup','ui-ficha','ui-links','ui-assert','capture','logout','cleanup','input','unknown'}
CATEGORIES={'DNS','CONNECT','TIMEOUT','JAVASCRIPT','ASSERTION','UNKNOWN'}
CLEANUP_CODES={'NOT_STARTED','COMPLETE','ASSIGN_FAILED','JOB_STOP_FAILED','ACTIVE_QUERY_FAILED','ACTIVE_REMAINS','JOB_CLOSE_FAILED','PROCESS_DRAIN_FAILED','PROCESS_WAIT_FAILED','STREAM_CLOSE_FAILED','TRANSPORT_FAILED'}
RUNNER_CODES={'INVALID_FLAGS','INVALID_MANIFEST','INPUT_FAILED','HOST_MISMATCH','SESSION_MISMATCH','INVALID_RESPONSE','UNSAFE_REQUEST','PREREQUISITE_FAILED','REQUEST_ID_INVALID','REQUEST_ID_COLLISION','ASSERTION_FAILED','BROWSER_ERROR','REPORT_FAILED','UNSAFE_DIAGNOSTICS','UNEXPECTED_FAILURE'}
class Failure(Exception):
    def __init__(self,code):self.code=code if code in CODES else 'EXECUTION_FAILED';super().__init__(self.code)
def require(value,code):
    if not value:raise Failure(code)
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()
def no_reparse(path):
    for p in (Path(path),*Path(path).parents):
        if p.exists() or p.is_symlink():require(not p.is_symlink() and not getattr(p.lstat(),'st_file_attributes',0)&stat.FILE_ATTRIBUTE_REPARSE_POINT,'PATH_SCOPE_CHANGED')
def write_new(path,value):
    no_reparse(Path(path).parent)
    try:
        with Path(path).open('x',encoding='utf-8') as f:json.dump(value,f,separators=(',',':'));f.write('\n');f.flush();os.fsync(f.fileno())
    except FileExistsError:raise Failure('PRIOR_ATTEMPT') from None
def imported(path,name):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def validate_scope(value,base):
    passwords=base.validate_manifest(value)
    require(all(value[key]['hostname']==host for key,host in HOSTS.items()),'MANIFEST_SCOPE_CHANGED');return passwords
def validate_diagnostic(value):
    require(type(value) is dict and set(value)=={'step','category'} and type(value['step']) is str and value['step'] in STEPS and type(value['category']) is str and value['category'] in CATEGORIES,'OUTPUT_INVALID');return dict(value)
def validate_report(value,passwords):
    # Report is a closed summary: no names, email, bodies, cookies, CSRF or arbitrary exceptions.
    allowed={'schema','runId','mode','status','checks','reads','screenshots','uiPaging21Exercised','inactiveObserved','sqlAuditValidated','pagingLimit','code','phase','businessWrites','apiOrSqlAuditCountInferred','diagnostic'}
    require(type(value) is dict and set(value)<=allowed and value.get('schema')=='patient-links-real-qa-v1' and value.get('runId')=='pacqa-20261109-a1' and value.get('mode')=='readonly' and value.get('status') in ('PASS','FAIL'),'OUTPUT_INVALID')
    text=json.dumps(value,ensure_ascii=False)
    for password in passwords:require(password not in text and json.dumps(password,ensure_ascii=True)[1:-1] not in text,'UNSAFE_RUNNER_OUTPUT')
    require(type(value.get('businessWrites')) is int and value['businessWrites']==0 and value.get('sqlAuditValidated') is False and value.get('apiOrSqlAuditCountInferred') is False,'OUTPUT_INVALID')
    require(type(value.get('checks')) is list and all(type(c) is str and re.fullmatch('[a-z0-9-]{1,80}',c) for c in value['checks']),'OUTPUT_INVALID')
    require(len(value['checks'])==len(set(value['checks'])) and set(value['checks'])<=CHECKS and (value['status']!='PASS' or set(value['checks'])==CHECKS),'OUTPUT_INVALID')
    for key in ('uiPaging21Exercised','inactiveObserved'):require(type(value.get(key)) is bool,'OUTPUT_INVALID')
    for key in ('phase','code'):
        if key in value:require(type(value[key]) is str and re.fullmatch('[A-Za-z0-9_-]{1,80}',value[key]),'OUTPUT_INVALID')
    if 'code' in value:require(value['code'] in RUNNER_CODES,'OUTPUT_INVALID')
    if value['status']=='FAIL':validate_diagnostic(value.get('diagnostic'))
    else:require('diagnostic' not in value,'OUTPUT_INVALID')
    if 'pagingLimit' in value:require(value['pagingLimit']=='Fixture has fewer than 21 links; real UI lookahead navigation not exercised','OUTPUT_INVALID')
    require(type(value.get('reads')) is list and len(value['reads'])<=200,'OUTPUT_INVALID');seen=set()
    for row in value['reads']:
        require(type(row) is dict and set(row)=={'requestId','status','actorId','tenantId','patientId','phase'},'OUTPUT_INVALID')
        for key in ('requestId','tenantId','patientId'):require(type(row[key]) is str and bool(re.fullmatch('[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',row[key])),'OUTPUT_INVALID')
        require(row['requestId'] not in seen,'OUTPUT_INVALID');seen.add(row['requestId']);require(type(row['status']) is int and 100<=row['status']<=599 and (row['actorId'] is None or type(row['actorId']) is str and bool(re.fullmatch('[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',row['actorId']))) and (row['status']!=401 or row['actorId'] is None) and type(row['phase']) is str and bool(re.fullmatch('[a-z0-9-]{1,60}',row['phase'])),'OUTPUT_INVALID')
    require(type(value.get('screenshots')) is list and len(value['screenshots'])<=20,'OUTPUT_INVALID')
    for shot in value['screenshots']:require(type(shot) is dict and set(shot)=={'path','sha256'} and type(shot['path']) is str and bool(re.fullmatch(r'test-results/patient-links-real-qa/pacqa-20261109-a1/b5-readonly-e4/[a-z0-9-]+\.png',shot['path'])) and type(shot['sha256']) is str and bool(re.fullmatch('[A-F0-9]{64}',shot['sha256'])),'OUTPUT_INVALID')
    if value['status']=='PASS':require({200,401,404}<={row['status'] for row in value['reads']} and len(value['screenshots'])>=8,'OUTPUT_INVALID')
    return value
def cleanup_state():return {'assigned':False,'stopAttempted':False,'activeProcessesAfterStop':None,'jobClosed':False,'processWaited':False,'processDrained':False,'streamsClosed':False,'unassignedProcessKilled':False,'code':'NOT_STARTED'}
def validate_cleanup(value):
    require(type(value) is dict and set(value)==set(cleanup_state()),'OUTPUT_INVALID')
    for key in set(value)-{'activeProcessesAfterStop','code'}:require(type(value[key]) is bool,'OUTPUT_INVALID')
    require(value['activeProcessesAfterStop'] is None or type(value['activeProcessesAfterStop']) is int and value['activeProcessesAfterStop']>=0,'OUTPUT_INVALID');require(type(value['code']) is str and value['code'] in CLEANUP_CODES,'OUTPUT_INVALID')
    if value['activeProcessesAfterStop'] is not None:require(value['assigned'] and value['stopAttempted'],'OUTPUT_INVALID')
    if value['code']=='COMPLETE':require(value['activeProcessesAfterStop']==0 and all(value[k] for k in ('assigned','stopAttempted','jobClosed','processWaited','processDrained','streamsClosed')),'OUTPUT_INVALID')
    return dict(value)
def observed_transport(base,argv,wire,cwd,environment,telemetry,*,popen=None,kernel=None):
    """Wrap the approved base transport, observing REAL counts before handle close.
    Injection parameters are only for offline doubles, never CLI configuration.
    """
    popen=subprocess.Popen if popen is None else popen;closed=set()
    class Job(base.WindowsJob):
        def __init__(self):super().__init__(kernel=kernel)
        def assign(self,process):
            try:super().assign(process);telemetry['assigned']=True
            except Exception:telemetry['code']='ASSIGN_FAILED';raise
        def stop(self):
            telemetry['stopAttempted']=True
            try:
                super().stop()
                accounting=base.Accounting()
                if not self.kernel.QueryInformationJobObject(self.handle,1,ctypes.byref(accounting),ctypes.sizeof(accounting),None):telemetry['code']='ACTIVE_QUERY_FAILED';raise Failure('PROCESS_CLEANUP_FAILED')
                telemetry['activeProcessesAfterStop']=int(accounting.ActiveProcesses)
                if accounting.ActiveProcesses!=0:telemetry['code']='ACTIVE_REMAINS';raise Failure('PROCESS_CLEANUP_FAILED')
            except Exception:
                if telemetry['code']=='NOT_STARTED':telemetry['code']='JOB_STOP_FAILED'
                raise
        def close(self):
            owned=bool(getattr(self,'handle',None))
            try:super().close();telemetry['jobClosed']=owned
            except Exception:telemetry['code']='JOB_CLOSE_FAILED';raise
    class Stream:
        def __init__(self,stream,name):self.stream=stream;self.name=name
        def close(self):
            try:self.stream.close();closed.add(self.name)
            except Exception:telemetry['code']='STREAM_CLOSE_FAILED';raise
    class Process:
        def __init__(self,process):
            self.process=process
            for name in ('stdin','stdout','stderr'):
                stream=getattr(process,name);setattr(self,name,None if stream is None else Stream(stream,name))
        @property
        def _handle(self):return self.process._handle
        @property
        def returncode(self):return self.process.returncode
        def poll(self):return self.process.poll()
        def kill(self):self.process.kill();telemetry['unassignedProcessKilled']=True
        def communicate(self,**kwargs):
            try:
                result=self.process.communicate(**kwargs)
                if 'input' not in kwargs:telemetry['processDrained']=True
                return result
            except Exception:
                if 'input' not in kwargs:telemetry['code']='PROCESS_DRAIN_FAILED'
                raise
        def wait(self,**kwargs):
            try:result=self.process.wait(**kwargs);telemetry['processWaited']=True;return result
            except Exception:telemetry['code']='PROCESS_WAIT_FAILED';raise
    try:return base.contained_run(argv,wire,cwd,environment,popen=lambda *args,**kwargs:Process(popen(*args,**kwargs)),job_factory=Job)
    except Exception:
        if telemetry['code']=='NOT_STARTED':telemetry['code']='TRANSPORT_FAILED'
        raise
    finally:
        telemetry['streamsClosed']=closed=={'stdin','stdout','stderr'}
        if telemetry['code'] in ('NOT_STARTED','TRANSPORT_FAILED') and telemetry['activeProcessesAfterStop']==0 and all(telemetry[k] for k in ('assigned','stopAttempted','jobClosed','processWaited','processDrained','streamsClosed')):telemetry['code']='COMPLETE'
class Operations:
    def __init__(self):self.cleanup=cleanup_state()
    def preflight(self,pins):
        require(Path(__file__).absolute()==ROOT/'scripts/run-patient-links-real-qa.py','PATH_SCOPE_CHANGED')
        require(type(pins) is dict and set(pins)=={'launcher','runner','environment','manifest'} and all(type(v) is str and re.fullmatch('[A-Fa-f0-9]{64}',v) for v in pins.values()),'PIN_INVALID')
        require(pins['manifest'].upper()=='6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6','INPUT_CHANGED')
        for path,pin in {Path(__file__):pins['launcher'],RUNNER:pins['runner'],ENV:pins['environment'],MANIFEST:pins['manifest'],BASE:BASE_SHA,READINESS:READINESS_SHA,HELPER:HELPER_SHA}.items():no_reparse(path);require(sha(path)==pin.upper(),'INPUT_CHANGED')
        require(not LEDGER.exists() and not COMPLETED.exists() and not REPORT.parent.exists(),'PRIOR_ATTEMPT')
        readiness=json.loads(READINESS.read_text(encoding='utf-8-sig'));require(readiness.get('manifestCipherSHA256')==CIPHER_SHA,'READINESS_INVALID')
    def reserve(self):write_new(LEDGER,{'status':'STARTED','mode':'readonly','automaticRetry':False,'reviewRequired':True})
    def base(self):
        require(sha(BASE)==BASE_SHA,'INPUT_CHANGED');module=imported(BASE,'B5_readonly_approved_transport');module.TIMEOUT_SECONDS=120;return module
    def context(self):return imported(ENV,'B5_readonly_approved_environment')
    def payload(self,base):
        no_reparse(SEALED);sealed=SEALED.read_bytes();require(0<len(sealed)<=2097152 and hashlib.sha256(sealed).hexdigest()==CIPHER_SHA,'MANIFEST_CHANGED');require(sha(HELPER)==HELPER_SHA,'INPUT_CHANGED')
        wire=base.decrypt_manifest(sealed,HELPER);require(type(wire) is bytes and 0<len(wire)<=65536,'MANIFEST_SCOPE_CHANGED')
        try:value=json.loads(wire)
        except Exception:raise Failure('MANIFEST_SCOPE_CHANGED') from None
        return wire,validate_scope(value,base)
    def transport(self,base,wire):
        environment=base.node_environment(os.environ);node=base.resolve_node(environment);require(Path(node)==Path('C:/Program Files/nodejs/node.exe'),'INPUT_CHANGED')
        return observed_transport(base,[node,str(RUNNER),'--readonly'],wire,ROOT/'frontend',environment,self.cleanup)
    def cleanup_evidence(self):return validate_cleanup(self.cleanup)
    def report(self,passwords):
        no_reparse(REPORT);raw=REPORT.read_bytes();require(len(raw)<=131072,'OUTPUT_INVALID');value=validate_report(json.loads(raw),passwords)
        for shot in value['screenshots']:path=ROOT/'frontend'/shot['path'];no_reparse(path);require(sha(path)==shot['sha256'],'OUTPUT_INVALID')
        return value
    def finish(self,value):write_new(COMPLETED,value)
def execute(pins,operations=None):
    ops=operations or Operations();ops.preflight(pins);ops.reserve();passwords=[];wire=None;result={'status':'FAIL','code':'EXECUTION_FAILED','automaticRetry':False,'credentialsPrinted':False}
    try:
        base=ops.base();context=ops.context()
        with context.managed_environment(pins['environment'],pins['manifest']) as handle:
            try:
                handle['ensure_alive']();wire,passwords=ops.payload(base);handle['ensure_alive']()
                response=ops.transport(base,wire);filtered=base.filter_result(response,'--readonly',passwords);handle['ensure_alive']()
                report=ops.report(passwords);require((filtered['rawExit']==0)==(report['status']=='PASS'),'OUTPUT_INVALID')
                if report['status']=='FAIL':result['diagnostic']=validate_diagnostic(report['diagnostic'])
                require(report['status']=='PASS','PREREQUISITE_FAILED' if report.get('code')=='PREREQUISITE_FAILED' else 'EXECUTION_FAILED')
                result={'status':'PASS','mode':'readonly','rawExit':filtered['rawExit'],'automaticRetry':False,'credentialsPrinted':False,'checks':len(report['checks']),'linkReadsObserved':len(report['reads']),'uiPaging21Exercised':report['uiPaging21Exercised'],'sqlAuditValidated':False}
            except Exception as error:
                # Preserve the QA failure through the unchanged context's normal teardown.
                # If teardown itself fails, the outer exception takes precedence.
                detail=result.get('diagnostic');result={'status':'FAIL','code':getattr(error,'code',None) if getattr(error,'code',None) in CODES else 'EXECUTION_FAILED','automaticRetry':False,'credentialsPrinted':False}
                if detail is not None:result['diagnostic']=detail
    except Exception as error:result={'status':'FAIL','code':error.code if isinstance(error,Failure) else (error.code if getattr(error,'code',None) in CODES else 'EXECUTION_FAILED'),'automaticRetry':False,'credentialsPrinted':False}
    finally:
        wire=None;passwords.clear() # Immutable bytes/strings cannot be promised erased.
        try:
            result['nodeCleanup']=ops.cleanup_evidence()
            if result['status']=='PASS' and result['nodeCleanup']['code']!='COMPLETE':result.update(status='FAIL',code='PROCESS_CLEANUP_FAILED')
        except Exception:result={'status':'FAIL','code':'OUTPUT_INVALID','automaticRetry':False,'credentialsPrinted':False,'nodeCleanup':cleanup_state()}
        ops.finish(result)
    return result
def plan():return {'status':'PREPARED_OFFLINE','mode':'plan','contextEntered':False,'DPAPILoads':0,'processesStarted':0,'networkRequests':0,'futureMode':'--execute-readonly'}
def main(argv=None):
    parser=argparse.ArgumentParser();parser.add_argument('--execute-readonly',action='store_true');parser.add_argument('--plan',action='store_true')
    for name in ('launcher','runner','environment','manifest'):parser.add_argument('--approved-'+name+'-sha256')
    args=parser.parse_args(argv)
    try:
        require(not(args.execute_readonly and args.plan),'PIN_INVALID')
        result=execute({name:getattr(args,'approved_'+name+'_sha256') for name in ('launcher','runner','environment','manifest')}) if args.execute_readonly else plan()
    except Exception as error:result={'status':'FAIL','code':error.code if isinstance(error,Failure) else 'EXECUTION_FAILED','automaticRetry':False,'credentialsPrinted':False}
    print(json.dumps(result,separators=(',',':')));return 1 if result['status']=='FAIL' else 0
if __name__=='__main__':raise SystemExit(main())
