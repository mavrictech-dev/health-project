"""B5 offline models only: no operational DPAPI/store, sockets, Node, Edge or app."""
import contextlib,hashlib,importlib.util,io,json,os,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import Mock,patch
SPEC=importlib.util.spec_from_file_location('b5_launcher',Path(__file__).resolve().parents[1]/'run-patient-links-real-qa.py');L=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(L)
BASE_SPEC=importlib.util.spec_from_file_location('b5_approved_base_test',Path(__file__).resolve().parents[1]/'run-patients-real-qa.py');B=importlib.util.module_from_spec(BASE_SPEC);BASE_SPEC.loader.exec_module(B)
PRIVATE='offline-canary-do-not-print';T=Path(os.environ['TEMP']);UUID='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
def manifest():
    value={'schema':'health-patients-real-qa-v1','qaDatabase':B.DATABASE,'baseUrl':B.BASE_URL,'runId':B.RUN_ID}
    for i,(key,host) in enumerate(L.HOSTS.items(),1):value[key]={'hostname':host,'tenantId':str(i)*8+'-'+str(i)*4+'-'+str(i)*4+'-'+str(i)*4+'-'+str(i)*12,'email':key+'@example.test','password':PRIVATE}
    return value
def report():
    return {'schema':'patient-links-real-qa-v1','runId':B.RUN_ID,'mode':'readonly','status':'PASS','checks':sorted(L.CHECKS),'reads':[{'requestId':str(i)*8+'-'+str(i)*4+'-'+str(i)*4+'-'+str(i)*4+'-'+str(i)*12,'status':status,'actorId':None if status==401 else UUID,'tenantId':UUID,'patientId':UUID,'phase':'offline'} for i,status in enumerate([200,401,404],1)],'screenshots':[{'path':'test-results/patient-links-real-qa/'+B.RUN_ID+'/b5-readonly/test-'+str(i)+'.png','sha256':'A'*64} for i in range(8)],'uiPaging21Exercised':False,'inactiveObserved':True,'sqlAuditValidated':False,'businessWrites':0,'apiOrSqlAuditCountInferred':False,'phase':'offline'}
class FakeOperations:
    def __init__(self):self.events=[];self.reserved=False;self.active=False;self.failure=None;self.safe=None;self.value=report();self.module=Mock();self.module.filter_result.side_effect=lambda response,mode,passwords:B.filter_result(response,mode,passwords)
    def preflight(self,pins):self.events.append('pins')
    def reserve(self):
        if self.reserved:raise L.Failure('PRIOR_ATTEMPT')
        self.events.append('reserve');self.reserved=True
    def base(self):return self.module
    def context(self):return self
    @contextlib.contextmanager
    def managed_environment(self,*args):
        self.active=True;self.events.append('context-enter')
        try:yield {'ensure_alive':lambda:self.events.append('alive') if self.active else (_ for _ in ()).throw(L.Failure('DEADLINE_FAILED'))}
        finally:self.active=False;self.events.append('context-close')
    def payload(self,base):self.events.append('decrypt');assert self.active;return json.dumps(manifest()).encode(),[PRIVATE]
    def transport(self,base,wire):
        self.events.append('contained-node');assert self.active;assert PRIVATE.encode() in wire
        if self.failure:raise self.failure
        return subprocess.CompletedProcess(['not-executed'],0,b'{"control":"runner","status":"passed"}\n',b'')
    def report(self,passwords):assert self.active;return L.validate_report(self.value,passwords)
    def finish(self,value):self.events.append('finish');assert not self.active;self.safe=value
class Tests(unittest.TestCase):
    def failure(self,code,fn):
        with self.assertRaises(L.Failure) as caught:fn()
        self.assertEqual(code,caught.exception.code);self.assertNotIn(PRIVATE,str(caught.exception))
    def test_import_and_default_plan_have_no_io_or_context_or_process(self):
        spec=importlib.util.spec_from_file_location('b5_inert',L.__file__);module=importlib.util.module_from_spec(spec)
        with patch.object(Path,'read_bytes',side_effect=AssertionError),patch.object(Path,'read_text',side_effect=AssertionError),patch.object(subprocess,'Popen',side_effect=AssertionError),patch.object(importlib.util,'spec_from_file_location',side_effect=AssertionError),contextlib.redirect_stdout(io.StringIO()) as output:
            spec.loader.exec_module(module);self.assertEqual(0,module.main([]));self.assertEqual('PREPARED_OFFLINE',json.loads(output.getvalue())['status'])
    def test_approved_transport_import_hash_and_timeout_changed_in_instance_only(self):
        self.assertEqual(L.BASE_SHA,L.sha(Path(B.__file__)))
        with patch.object(L,'BASE',Path(B.__file__)):module=L.Operations().base()
        self.assertEqual(120,module.TIMEOUT_SECONDS);self.assertEqual(900,B.TIMEOUT_SECONDS);self.assertEqual(L.BASE_SHA,L.sha(B.__file__))
    def test_exact_three_environment_constant_deltas_and_manifest_copy_history(self):
        old=(T/'B4P1-environment.py').read_bytes();new=(T/'B5P1-environment.py').read_bytes()
        for a,b in [(b"MANIFEST=TEMP/'B4P1-reviewed-pins.json'",b"MANIFEST=TEMP/'B5P1-reviewed-pins.json'"),(b"LEDGER=PREPARED/'readiness-attempt.json'",b"LEDGER=PREPARED/'B5-readonly-attempt.json'"),(b"COMPLETED=PREPARED/'readiness-completed.json'",b"COMPLETED=PREPARED/'B5-readonly-completed.json'")]:self.assertEqual(1,old.count(a));new=new.replace(b,a)
        self.assertEqual(old,new);self.assertEqual((T/'B4P1-reviewed-pins.json').read_bytes(),(T/'B5P1-reviewed-pins.json').read_bytes())
        before=json.loads((T/'B5P1-history-before.json').read_text());self.assertTrue(all(L.sha(p)==pin for p,pin in before.items()))
        spec=importlib.util.spec_from_file_location('b5_context_inert',T/'B5P1-environment.py');module=importlib.util.module_from_spec(spec)
        with patch.object(subprocess,'Popen',side_effect=AssertionError):spec.loader.exec_module(module);context=module.managed_environment('bad','bad')
        self.assertIsNotNone(context);self.assertEqual('B5-readonly-attempt.json',module.LEDGER.name);self.assertEqual('B5-readonly-completed.json',module.COMPLETED.name);self.assertFalse(module.LEDGER.exists())
        with tempfile.TemporaryDirectory(prefix='B5P1-test-',dir=T) as folder:
            ledger=Path(folder)/module.LEDGER.name;module.write_new(ledger,{'status':'STARTED'});before=ledger.read_bytes()
            with self.assertRaises(module.SafeError) as caught:module.write_new(ledger,{'status':'retry'})
            self.assertEqual('PRIOR_ATTEMPT',caught.exception.code);self.assertEqual(before,ledger.read_bytes())
    def test_scope_uses_approved_full_manifest_and_rejects_other_host_dataset(self):
        self.assertEqual([PRIVATE]*3,L.validate_scope(manifest(),B))
        for key,delta in [('human',{'hostname':'qa-other.health.localhost'}),('animal',{'tenantId':manifest()['human']['tenantId']}),('human',{'email':'real@example.invalid'})]:
            value=manifest();value[key].update(delta)
            with self.assertRaises(Exception):L.validate_scope(value,B)
    def test_execute_context_stays_alive_during_single_decrypt_node_result_and_closes(self):
        ops=FakeOperations();result=L.execute({'environment':'A'*64,'manifest':'B'*64},ops);self.assertEqual('PASS',result['status']);self.assertEqual(1,ops.events.count('decrypt'));self.assertEqual(1,ops.events.count('contained-node'));self.assertLess(ops.events.index('context-enter'),ops.events.index('decrypt'));self.assertLess(ops.events.index('contained-node'),ops.events.index('context-close'));self.assertEqual('finish',ops.events[-1]);self.assertFalse(ops.active);self.assertNotIn(PRIVATE,json.dumps(result));self.failure('PRIOR_ATTEMPT',lambda:L.execute({},ops))
    def test_timeout_or_secret_output_closes_context_and_preserves_failed_operation(self):
        for failure in [B.LaunchError('RUNNER_TIMEOUT'),L.Failure('UNSAFE_RUNNER_OUTPUT')]:
            ops=FakeOperations();ops.failure=failure;result=L.execute({'environment':'A'*64,'manifest':'B'*64},ops);self.assertEqual('FAIL',result['status']);self.assertFalse(ops.active);self.assertEqual('finish',ops.events[-1]);self.assertNotIn(PRIVATE,json.dumps(result))
    def test_result_strict_shape_redaction_and_no_fake_pass_empty_checks(self):
        L.validate_report(report(),[PRIVATE])
        for changes in [{'checks':[]},{'reads':[]},{'businessWrites':1},{'sqlAuditValidated':True},{'credentials':PRIVATE},{'phase':PRIVATE},{'screenshots':[{'path':'../../private','sha256':'A'*64}]}]:
            value=report();value.update(changes)
            with self.assertRaises(L.Failure):L.validate_report(value,[PRIVATE])
        value=report();value['reads'].append(value['reads'][0]);self.failure('OUTPUT_INVALID',lambda:L.validate_report(value,[PRIVATE]))
        for stdout,stderr in [(b'{"control":"runner","status":"passed"}\n'+PRIVATE.encode(),b''),(b'{"control":"runner","status":"passed"}\n',PRIVATE.encode())]:
            with self.assertRaises(B.LaunchError) as caught:B.filter_result(subprocess.CompletedProcess([],0,stdout,stderr),'--readonly',[PRIVATE])
            self.assertEqual('UNSAFE_RUNNER_OUTPUT',caught.exception.code)
    def test_ledger_exclusive_and_worker_execution_refused_before_credential_or_context(self):
        # Explicit module locations make this test portable across both checkouts.
        with patch.object(L,'__file__',str(L.ROOT/'tmp/B5P1-noncanonical/launcher.py')):
            self.failure('PATH_SCOPE_CHANGED',lambda:L.Operations().preflight({}))
        with patch.object(L,'__file__',str(L.ROOT/'scripts/run-patient-links-real-qa.py')):
            self.failure('PIN_INVALID',lambda:L.Operations().preflight({}))
        with tempfile.TemporaryDirectory(prefix='B5P1-test-',dir=T) as folder:
            p=Path(folder)/'attempt.json';L.write_new(p,{'status':'STARTED'});self.failure('PRIOR_ATTEMPT',lambda:L.write_new(p,{'status':'retry'}))
    def test_cipher_and_helper_pins_precede_decrypt_using_synthetic_files(self):
        with tempfile.TemporaryDirectory(prefix='B5P1-test-',dir=T) as folder:
            sealed=Path(folder)/'fake.dpapi';sealed.write_bytes(b'not-dpapi');helper=Path(folder)/'helper.py';helper.write_bytes(b'public-helper-double');base=Mock();base.decrypt_manifest.return_value=json.dumps(manifest()).encode();base.validate_manifest.side_effect=B.validate_manifest
            with patch.multiple(L,SEALED=sealed,HELPER=helper,CIPHER_SHA=hashlib.sha256(b'not-dpapi').hexdigest(),HELPER_SHA=L.sha(helper)):
                wire,passwords=L.Operations().payload(base);self.assertEqual([PRIVATE]*3,passwords);self.assertIn(PRIVATE.encode(),wire);base.decrypt_manifest.assert_called_once();base.decrypt_manifest.reset_mock();sealed.write_bytes(b'changed');self.failure('MANIFEST_CHANGED',lambda:L.Operations().payload(base));base.decrypt_manifest.assert_not_called()
    def test_minimal_environment_and_fixed_node_guard(self):
        values=B.node_environment({'PATH':'C:/Program Files/nodejs','TEMP':'C:/Temp','HEALTH_PASSWORD':PRIVATE,'NODE_OPTIONS':'bad','JAVA_TOOL_OPTIONS':'bad','DEBUG':'bad'});self.assertEqual({'PATH','TEMP'},set(values))
        with self.assertRaises(B.LaunchError):B.node_environment({'SQLCMDPASSWORD':PRIVATE})
        base=Mock();base.node_environment.return_value={};base.resolve_node.return_value='C:/other/node.exe';self.failure('INPUT_CHANGED',lambda:L.Operations().transport(base,b'fake'));base.contained_run.assert_not_called()
    def test_actual_contained_transport_association_precedes_stdin_and_cleanup_with_models(self):
        events=[];process=Mock();process._handle=123;process.returncode=0;process.communicate.side_effect=lambda **kw:events.append('stdin' if 'input' in kw else 'drain') or (b'{"control":"runner","status":"passed"}\n',b'');process.wait.return_value=0
        job=Mock();job.assign.side_effect=lambda p:events.append('assign');job.stop.side_effect=lambda:events.append('stop');job.close.side_effect=lambda:events.append('close');result=B.contained_run(['node.exe','fixed','--readonly'],b'synthetic',Path('C:/fake'),{},popen=lambda *a,**kw:process,job_factory=lambda:job)
        self.assertEqual(0,result.returncode);self.assertLess(events.index('assign'),events.index('stdin'));self.assertLess(events.index('stdin'),events.index('stop'));self.assertIn('close',events)
        job.reset_mock();job.assign.side_effect=RuntimeError('injected');process.poll.return_value=None
        with self.assertRaises(RuntimeError):B.contained_run(['node.exe'],b'synthetic',Path('C:/fake'),{},popen=lambda *a,**kw:process,job_factory=lambda:job)
        process.kill.assert_called_once()
    def test_prerequisite_failure_survives_unchanged_environment_context_teardown(self):
        ops=FakeOperations();ops.value={'schema':'patient-links-real-qa-v1','runId':B.RUN_ID,'mode':'readonly','status':'FAIL','code':'PREREQUISITE_FAILED','phase':'human-prerequisite','checks':[],'reads':[],'screenshots':[],'uiPaging21Exercised':False,'inactiveObserved':False,'sqlAuditValidated':False,'businessWrites':0,'apiOrSqlAuditCountInferred':False}
        ops.transport=lambda *args:subprocess.CompletedProcess([],1,b'{"control":"runner","status":"failed"}\n',b'')
        @contextlib.contextmanager
        def rewriting_context(*args):
            ops.active=True
            try:yield {'ensure_alive':lambda:None}
            except Exception:raise L.Failure('ENVIRONMENT_FAILED') from None
            finally:ops.active=False
        ops.managed_environment=rewriting_context
        result=L.execute({'environment':'A'*64,'manifest':'B'*64},ops);self.assertEqual('PREREQUISITE_FAILED',result['code']);self.assertFalse(ops.active)
    def test_preflight_real_hash_checks_paths_missing_inputs_and_no_cipher_read(self):
        with tempfile.TemporaryDirectory(prefix='B5P1-test-',dir=T) as folder:
            root=Path(folder);selfpath=root/'scripts/run-patient-links-real-qa.py';runner=root/'frontend/scripts/patient-links-real-qa.cjs';base=root/'scripts/base.py';env=root/'B5P1-environment.py';manifest_path=root/'B5P1-reviewed-pins.json';readiness=root/'readiness.json';helper=root/'helper.py'
            for p in [selfpath,runner,base,env,helper]:p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b'offline-source')
            manifest_path.write_bytes((T/'B5P1-reviewed-pins.json').read_bytes());readiness.write_text(json.dumps({'manifestCipherSHA256':L.CIPHER_SHA}))
            pins={'launcher':L.sha(selfpath),'runner':L.sha(runner),'environment':L.sha(env),'manifest':L.sha(manifest_path)}
            with patch.multiple(L,ROOT=root,__file__=str(selfpath),RUNNER=runner,BASE=base,BASE_SHA=L.sha(base),ENV=env,MANIFEST=manifest_path,READINESS=readiness,READINESS_SHA=L.sha(readiness),HELPER=helper,HELPER_SHA=L.sha(helper),LEDGER=root/'attempt.json',COMPLETED=root/'completed.json',REPORT=root/'reports/report.json'),patch.object(L,'imported',side_effect=AssertionError('context/helper imported in preflight')):
                L.Operations().preflight(pins)
                self.failure('PIN_INVALID',lambda:L.Operations().preflight({**pins,'launcher':'bad'}))
                self.failure('INPUT_CHANGED',lambda:L.Operations().preflight({**pins,'runner':'A'*64}))
                runner.write_bytes(b'changed');self.failure('INPUT_CHANGED',lambda:L.Operations().preflight(pins));runner.write_bytes(b'offline-source')
                L.write_new(L.LEDGER,{'status':'STARTED'});self.failure('PRIOR_ATTEMPT',lambda:L.Operations().preflight(pins))
    def test_actual_transport_timeout_stops_job_drains_closes_and_escaped_secret_filter(self):
        process=Mock();process._handle=123;process.returncode=1;process.communicate.side_effect=[subprocess.TimeoutExpired(['node.exe'],120),(b'',b'')];process.wait.return_value=1;job=Mock()
        with self.assertRaises(B.LaunchError) as caught:B.contained_run(['node.exe','fixed','--readonly'],b'synthetic',Path('C:/fake'),{},popen=lambda *a,**kw:process,job_factory=lambda:job)
        self.assertEqual('RUNNER_TIMEOUT',caught.exception.code);job.stop.assert_called_once();job.close.assert_called_once();process.wait.assert_called_once()
        for stream in (process.stdin,process.stdout,process.stderr):stream.close.assert_called_once()
        password='offline-quote-"-ñ'
        for form in (password.encode(),json.dumps(password,ensure_ascii=True)[1:-1].encode(),json.dumps(password,ensure_ascii=False)[1:-1].encode()):
            with self.assertRaises(B.LaunchError) as caught:B.filter_result(subprocess.CompletedProcess([],1,b'',form),'--readonly',[password])
            self.assertEqual('UNSAFE_RUNNER_OUTPUT',caught.exception.code)
if __name__=='__main__':unittest.main(verbosity=2)
