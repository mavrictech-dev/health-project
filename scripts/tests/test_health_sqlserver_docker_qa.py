"""Own OFFLINE Docker models only. Every process and socket is globally blocked."""
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import unittest
import uuid
from unittest.mock import Mock,patch

ROOT=Path(__file__).resolve().parents[2]
with patch.object(subprocess,'run',side_effect=AssertionError('real process forbidden')),patch.object(subprocess,'Popen',side_effect=AssertionError('real process forbidden')),patch.object(socket,'socket',side_effect=AssertionError('real socket forbidden')):
    SPEC=importlib.util.spec_from_file_location('health_docker_qa',ROOT/'scripts/health-sqlserver-docker-qa.py')
    M=importlib.util.module_from_spec(SPEC);sys.modules[SPEC.name]=M;SPEC.loader.exec_module(M)


def setUpModule():
    global BLOCKS
    # R3 artifacts are nested in a NEW owned namespace; old P1 directories and
    # their journals remain untouched. Production path guards are unchanged.
    sandbox=Path(os.environ['TEMP'])/('C1DockerP1R3-tests-'+uuid.uuid4().hex);sandbox.mkdir(exist_ok=False)
    BLOCKS=[patch.dict(os.environ,{'TEMP':str(sandbox)}),patch.object(subprocess,'run',side_effect=AssertionError('real process forbidden')),patch.object(subprocess,'Popen',side_effect=AssertionError('real process forbidden')),patch.object(socket,'socket',side_effect=AssertionError('real socket forbidden'))]
    for block in BLOCKS:block.start()


def tearDownModule():
    for block in reversed(BLOCKS):block.stop()


def directory():return Path(os.environ['TEMP'])/('C1DockerP1-unit-'+uuid.uuid4().hex)


class DockerModel:
    """Fictitious responses, not an engine or Docker daemon implementation."""
    def __init__(self,data,**options):
        self.data=data;self.options=options;self.calls=[];self.cid='a'*64;self.labels={'vendor':'Microsoft'};self.run_id=None;self.owner=None

    def __call__(self,argv,**kwargs):
        args=argv[3:];payload=kwargs['input'];entry=json.loads((self.owner.evidence.path/f'{self.owner.evidence.order:04}-attempt.json').read_text())
        assert entry['argv']==argv and entry['order']==self.owner.evidence.order
        if payload is not None:
            assert entry['sql']['sha256']==M.sha(payload)
            assert (self.owner.evidence.path/entry['sql']['file']).read_bytes()==payload
        phase=entry['phase'];self.calls.append({'phase':phase,'argv':argv,'kwargs':kwargs,'entry':entry})
        if self.options.get('exception_at')==phase:raise RuntimeError('PRIVATE_EXCEPTION_CANARY_0088')
        if self.options.get('timeout_at')==phase:raise subprocess.TimeoutExpired(argv,180,output=b'PRIVATE_TIMEOUT_CANARY_0088',stderr=b'PRIVATE_STDERR_CANARY_0088')
        if self.options.get('exit_at')==phase:return subprocess.CompletedProcess(argv,7,b'PRIVATE_EXIT_CANARY_0088',b'PRIVATE_EXIT_CANARY_0088')
        if self.options.get('missing_at')==phase:return subprocess.CompletedProcess(argv,0,b'',b'')
        if args[:2]==['context','inspect']:value=self.options.get('endpoint',M.ENDPOINT)
        elif args[0]=='info':value={'version':M.DAEMON_VERSION,'os':'linux','arch':'x86_64',**self.options.get('daemon',{})}
        elif args[:2]==['image','inspect']:
            value={'id':M.IMAGE_ID,'digests':[M.IMAGE],'os':'linux','arch':'amd64','labels':self.labels,**self.options.get('image',{})}
        elif 'ls' in args:
            raw=b'"existing"\n' if self.options.get('collision')==phase else b''
            return subprocess.CompletedProcess(argv,0,raw,b'')
        elif args[:2]==['volume','create']:
            self.run_id=next(v.split('=',1)[1] for v in args if v.startswith(M.RUN_LABEL+'='));return subprocess.CompletedProcess(argv,0,M.VOLUME.encode()+b'\n',b'')
        elif args[:2]==['volume','inspect']:
            value={'name':M.VOLUME,'driver':'local','scope':'local','labels':{M.LABEL:M.LABEL_VALUE,M.RUN_LABEL:self.run_id},'options':None,**self.options.get('volume',{})}
        elif args[:2]==['container','create']:return subprocess.CompletedProcess(argv,0,(self.cid+'\n').encode(),b'')
        elif args[:2]==['container','inspect']:
            running=any(v['phase']=='start_once' for v in self.calls)
            value={'id':self.cid,'image':M.IMAGE_ID,'hostname':M.NAME,'labels':{**self.labels,M.LABEL:M.LABEL_VALUE,M.RUN_LABEL:self.run_id},'state':'running' if running else 'created','running':running,'privileged':False,'network':'bridge','restart':'no','binds':None,'ports':{'1433/tcp':[{'HostIp':'127.0.0.1','HostPort':'14436'}]},'mounts':[{'type':'volume','name':M.VOLUME,'target':'/var/opt/mssql','rw':True}],**self.options.get('container',{})}
        elif args[:2]==['container','start']:return subprocess.CompletedProcess(argv,0,(self.cid+'\n').encode(),b'')
        elif args[:1]==['exec'] and '/usr/bin/sha256sum' in args:
            return subprocess.CompletedProcess(argv,0,((self.options.get('inner','F'*64)).lower()+'  '+M.INNER+'\n').encode(),b'')
        elif args[:1]==['exec']:
            text=payload.decode('utf-8');stage=re.search(r"N'([^']+)' stage",text).group(1);n=re.search(r"N'([0-9a-f]{32})' nonce",text).group(1)
            value={'kind':'C1DOCKER','stage':stage,'nonce':n,'ok':True,'probe':M.PROBE}
            if stage=='verify_database':value.update(tables=37,procedures=134,triggers=31,roleAcl=564,fingerprints={k:'A'*64 for k in self.data['module'].FINGERPRINT_KEYS})
            if stage=='verify_database':value.update(self.options.get('poststate',{}))
            raw=('C1DOCKER'+json.dumps(value,ensure_ascii=False,separators=(',',':'))).encode('utf-8')
            if self.options.get('frame_at')==stage:raw=b'PRIVATE_INVALID_FRAME_CANARY_0088'
            stderr=b'PRIVATE_NATIVE_CANARY_0088' if self.options.get('stderr_at')==stage else b''
            return subprocess.CompletedProcess(argv,0,raw,stderr)
        else:raise AssertionError('unexpected command')
        return subprocess.CompletedProcess(argv,0,json.dumps(value,separators=(',',':')).encode(),b'')


class DockerToolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.manifest,cls.data=M.candidate(M.CANONICAL)

    def runner(self,**options):
        manifest=copy.deepcopy(self.manifest);manifest['reviewed']=True;manifest['innerSqlcmdSha256']='F'*64
        model=DockerModel(self.data,**options);port=Mock()
        runner=M.Provisioner(M.CANONICAL,manifest,directory(),run=model,resolve=lambda:str(M.CLI),port_check=port,environment={},secret=lambda:'PRIVATE_SA_CANARY_0088')
        model.owner=runner;return runner,model,port

    def failure(self,**options):
        runner,model,port=self.runner(**options)
        with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        result=json.loads((runner.evidence.path/'summary.json').read_text())
        self.assertEqual(caught.exception.report,result)
        return result,runner,model

    def test_01_import_plan_generation_do_not_create_evidence_processes_or_sockets(self):
        with patch.object(Path,'mkdir',side_effect=AssertionError('plan wrote directory')):
            result=M.plan(M.CANONICAL)
            for stage in M.SQL_STAGES:self.assertTrue(M.sql(self.data,stage,'0'*32).startswith(b':On Error exit\n'))
        self.assertEqual('OFFLINE_PLAN',result['status']);self.assertTrue(result['provisionBlocked'])
        self.assertIsNone(result['manifestCandidate']['innerSqlcmdSha256']);self.assertFalse(result['manifestCandidate']['reviewed'])
        self.assertEqual(list(range(1,14)),result['migrationVersions'])

    def test_02_pending_pin_or_unreviewed_manifest_blocks_before_all_operations(self):
        for inner,reviewed in [(None,False),(None,True),('F'*64,False),('bad',True)]:
            manifest=copy.deepcopy(self.manifest);manifest.update(innerSqlcmdSha256=inner,reviewed=reviewed)
            run=Mock();port=Mock();target=directory()
            with self.subTest(inner=inner,reviewed=reviewed),self.assertRaises(M.Fault):M.Provisioner(M.CANONICAL,manifest,target,run=run,port_check=port)
            run.assert_not_called();port.assert_not_called();self.assertFalse(target.exists())

    def test_03_manifest_sources_target_digest_cli_and_extra_fields_are_closed(self):
        for path,value in [('docker.image','tag:latest'),('docker.imageId','sha256:wrong'),('docker.context','remote'),('target.database','master'),('target.publish','0.0.0.0:14436:1433'),('ownSources.'+M.DRIVER,'0'*64)]:
            manifest=copy.deepcopy(self.manifest);manifest.update(reviewed=True,innerSqlcmdSha256='F'*64)
            key,leaf=path.split('.',1);manifest[key][leaf]=value
            with self.subTest(path=path),self.assertRaises(M.Fault):M.validate_manifest(M.CANONICAL,manifest)
        manifest=copy.deepcopy(self.manifest);manifest.update(reviewed=True,innerSqlcmdSha256='F'*64,extra=1)
        with self.assertRaises(M.Fault):M.validate_manifest(M.CANONICAL,manifest)

    def test_04_all_canonical_migration_pins_including_v14_are_checked_without_executing_it(self):
        original=Path.read_bytes
        def changed(path):
            if path.name.startswith('V14__'):return b'changed V14'
            return original(path)
        with patch.object(Path,'read_bytes',changed):
            with self.assertRaisesRegex(M.Fault,'CANONICAL_MIGRATION_CHANGED'):M.refs(M.CANONICAL)
        with self.assertRaises(M.Fault):M.refs(ROOT.parent)
        with patch('importlib.machinery.SourceFileLoader.exec_module',side_effect=AssertionError('canonical loader/cache forbidden')):
            self.assertEqual(set(range(1,15)),set(M.refs(M.CANONICAL)['migrations']))

    def test_05_success_sequence_uses_one_start_one_db_create_one_migration_and_fresh_verify(self):
        runner,model,port=self.runner();result=runner.execute()
        self.assertEqual('PASS',result['status']);phases=[c['phase'] for c in model.calls]
        for phase in ['volume_create','container_create','start_once',*M.SQL_STAGES]:self.assertEqual(1,phases.count(phase),phase)
        self.assertLess(phases.index('start_once'),phases.index('readiness'));self.assertLess(phases.index('create_database'),phases.index('apply_v1_v13'));self.assertLess(phases.index('apply_v1_v13'),phases.index('verify_database'))
        self.assertGreaterEqual(port.call_count,3);self.assertEqual(5,phases.count('inner_pin'))
        self.assertFalse(result['cleanupAttempted']);self.assertFalse(result['retryAttempted'])
        stored=json.loads((runner.evidence.path/'summary.json').read_text());self.assertEqual(result,stored)
        with self.assertRaises(M.Fault):runner.execute()

    def test_06_password_is_child_env_once_never_argv_journal_summary_native_output_or_global(self):
        before=dict(os.environ);runner,model,port=self.runner();runner.execute()
        for call in model.calls:
            self.assertNotIn('PRIVATE_SA_CANARY_0088',json.dumps(call['argv']))
            env=call['kwargs']['env']
            self.assertEqual(call['phase']=='container_create','MSSQL_SA_PASSWORD' in env)
            if call['phase']=='container_create':self.assertEqual('PRIVATE_SA_CANARY_0088',env['MSSQL_SA_PASSWORD'])
        self.assertEqual(before,dict(os.environ))
        for path in runner.evidence.path.iterdir():
            if path.is_file():self.assertNotIn(b'PRIVATE_SA_CANARY_0088',path.read_bytes())

    def test_07_docker_flags_targets_inspections_and_sqlcmd_are_restricted(self):
        runner,model,port=self.runner();runner.execute()
        for call in model.calls:
            argv=call['argv'];kwargs=call['kwargs'];self.assertEqual([str(M.CLI),'--context','desktop-linux'],argv[:3]);self.assertFalse(kwargs['shell']);self.assertEqual(180,kwargs['timeout'])
            self.assertNotIn('Config.Env',' '.join(argv));self.assertFalse(any(arg in ('rm','remove','prune','pull','run','restart','--privileged','--env-file','-P') for arg in argv))
            if call['phase'] in M.SQL_STAGES:
                self.assertIn(M.SQL_SHELL,argv);self.assertIn(model.cid,argv);self.assertNotIn(M.NAME,argv)
                self.assertTrue(type(kwargs['input']) is bytes);self.assertTrue(kwargs['input'].startswith(b':On Error exit\n'))
                for flag,value in [('-V','11'),('-r','1'),('-f','65001'),('-y','0'),('-w','65535'),('-l','30'),('-t','120')]:self.assertEqual(value,argv[argv.index(flag)+1])
                for flag in ['-b','-x','-X1']:self.assertIn(flag,argv)
        create=next(c for c in model.calls if c['phase']=='container_create')['argv']
        self.assertEqual(M.IMAGE,create[-1]);self.assertIn('--pull=never',create);self.assertIn('127.0.0.1:14436:1433',create);self.assertIn('--restart=no',create)

    def test_08_immutable_v1_v13_bytes_are_in_one_external_transaction_and_v14_is_absent(self):
        script=M.sql_raw(self.data,'apply_v1_v13','0'*32)
        for n in range(1,14):self.assertEqual(1,script.count(self.data['migrations'][n]['bytes'].removeprefix(b'\xef\xbb\xbf')))
        self.assertNotIn(self.data['migrations'][14]['bytes'],script)
        self.assertLess(script.index(b'BEGIN TRANSACTION;'),script.index(self.data['migrations'][1]['bytes']))
        self.assertLess(script.index(self.data['migrations'][13]['bytes'].removeprefix(b'\xef\xbb\xbf')),script.rindex(b'COMMIT TRANSACTION;'))
        self.assertIn(b'GO\n',script);self.assertNotIn(b'CREATE LOGIN',script);self.assertNotIn(b'CREATE USER',script)
        create=M.sql(self.data,'create_database','0'*32);self.assertEqual(1,create.count(('CREATE DATABASE ['+M.DATABASE+']').encode()));self.assertNotIn(b'BEGIN TRANSACTION',create)

    def test_09_collisions_stop_before_any_mutation_and_do_not_adopt(self):
        for collision in ['absence_container','absence_volume','absence_docker_port']:
            result,runner,model=self.failure(collision=collision)
            self.assertEqual('FAIL',result['status']);self.assertEqual('RESOURCE_COLLISION',result['failure']['code'])
            self.assertFalse(any(c['entry']['mutation'] for c in model.calls));self.assertFalse(result['cleanupAttempted'])

    def test_10_host_port_collision_stops_without_docker_mutations(self):
        runner,model,port=self.runner();port.side_effect=M.Fault('HOST_PORT_COLLISION')
        with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        self.assertEqual('FAIL',caught.exception.report['status']);self.assertFalse(any(c['entry']['mutation'] for c in model.calls))

    def test_11_hostile_daemon_image_and_architecture_fail_closed(self):
        for options in [{'endpoint':'tcp://remote:2375'},{'daemon':{'arch':'arm64'}},{'daemon':{'os':'windows'}},{'daemon':{'version':'29.8.3'}},{'image':{'id':'sha256:'+'b'*64}},{'image':{'digests':[]}},{'image':{'arch':'arm64'}},{'image':{'labels':[]}}]:
            result,runner,model=self.failure(**options)
            self.assertEqual('FAIL',result['status']);self.assertFalse(any(c['entry']['mutation'] for c in model.calls))

    def test_12_wrong_volume_label_or_driver_never_reuses_foreign_resource(self):
        for volume in [{'labels':{M.LABEL:M.LABEL_VALUE}},{'name':'other'},{'driver':'nfs'},{'options':{'device':'/data'}}]:
            result,runner,model=self.failure(volume=volume)
            self.assertEqual('UNKNOWN',result['status']);self.assertEqual('VOLUME_OWNERSHIP_INVALID',result['failure']['code'])
            self.assertNotIn('container_create',[c['phase'] for c in model.calls])

    def test_13_wrong_container_hostname_labels_ports_mounts_privilege_or_state_stop_before_start(self):
        for container in [{'hostname':'other'},{'labels':{}},{'ports':{'1433/tcp':[{'HostIp':'0.0.0.0','HostPort':'14436'}]}},{'privileged':True},{'network':'host'},{'restart':'always'},{'mounts':[]},{'mounts':[{'type':'volume','name':M.VOLUME,'target':'/var/opt/mssql','rw':1}]},{'state':'running'}]:
            result,runner,model=self.failure(container=container)
            self.assertEqual('UNKNOWN',result['status']);self.assertEqual('CONTAINER_TARGET_INVALID',result['failure']['code'])
            self.assertNotIn('start_once',[c['phase'] for c in model.calls])

    def test_14_inner_pin_mismatch_stops_without_any_sql(self):
        result,runner,model=self.failure(inner='E'*64)
        self.assertEqual('UNKNOWN',result['status']);self.assertEqual('INNER_SQLCMD_PIN_CHANGED',result['failure']['code'])
        self.assertFalse(any(c['phase'] in M.SQL_STAGES for c in model.calls))

    def test_15_timeout_is_unknown_once_retains_resources_no_reconcile_retry_or_cleanup(self):
        for phase in ['volume_create','container_create','start_once','create_database','apply_v1_v13']:
            result,runner,model=self.failure(timeout_at=phase)
            self.assertEqual('UNKNOWN',result['status']);self.assertEqual('PROCESS_TIMEOUT_UNKNOWN',result['failure']['code'])
            self.assertEqual(phase,model.calls[-1]['phase']);self.assertEqual(1,sum(c['phase']==phase for c in model.calls));self.assertFalse(result['cleanupAttempted']);self.assertFalse(result['retryAttempted'])
            for p in runner.evidence.path.iterdir():
                if p.is_file():self.assertNotIn(b'PRIVATE_TIMEOUT_CANARY_0088',p.read_bytes())

    def test_16_missing_create_receipt_does_not_search_for_or_adopt_container(self):
        result,runner,model=self.failure(missing_at='container_create')
        self.assertEqual('UNKNOWN',result['status']);self.assertIsNone(result['resources']['container']);self.assertEqual('container_create',model.calls[-1]['phase'])

    def test_17_raw_zero_stderr_or_invalid_frame_never_passes(self):
        for key in ['stderr_at','frame_at']:
            result,runner,model=self.failure(**{key:'apply_v1_v13'})
            self.assertEqual('UNKNOWN',result['status']);self.assertEqual('apply_v1_v13',model.calls[-1]['phase'])
            for p in runner.evidence.path.iterdir():
                if p.is_file():self.assertNotIn(b'PRIVATE_NATIVE_CANARY_0088',p.read_bytes());self.assertNotIn(b'PRIVATE_INVALID_FRAME_CANARY_0088',p.read_bytes())

    def test_18_arbitrary_exception_is_sanitized(self):
        result,runner,model=self.failure(exception_at='container_create')
        self.assertEqual('UNKNOWN',result['status']);self.assertEqual('PROCESS_FAILED',result['failure']['code'])
        self.assertNotIn('PRIVATE_EXCEPTION_CANARY_0088',json.dumps(result))

    def test_19_environment_is_scoped_and_hostile_docker_sqlcmd_or_sa_values_rejected(self):
        for key in ['DOCKER_HOST','docker_context','DOCKER_CONFIG','SQLCMDPASSWORD','MSSQL_SA_PASSWORD']:
            with self.subTest(key=key),self.assertRaises(M.Fault):M.child_environment({key:'canary'})
        env=M.child_environment({'PATH':'hostile','SOMEE_PASSWORD':'secret','HTTPS_PROXY':'remote'})
        self.assertNotIn('hostile',env['PATH']);self.assertNotIn('SOMEE_PASSWORD',env);self.assertNotIn('HTTPS_PROXY',env)

    def test_20_exclusive_evidence_rejects_existing_escape_unc_reparse_and_overwrites(self):
        target=directory();manifest=copy.deepcopy(self.manifest)
        evidence=M.Evidence(target,M.CANONICAL,manifest);prior=(target/'manifest.json').read_bytes()
        with self.assertRaises(M.Fault):M.Evidence(target,M.CANONICAL,manifest)
        self.assertEqual(prior,(target/'manifest.json').read_bytes())
        for path in [Path('relative'),ROOT/'scripts'/'C1Docker-outside',Path(os.environ['TEMP'])/'..'/'C1Docker-escape',Path(r'\\server\share\C1Docker-remote')]:
            with self.assertRaises(M.Fault):M.Evidence(path,M.CANONICAL,manifest)
        with patch.object(Path,'is_symlink',return_value=True):
            with self.assertRaises(M.Fault):M.Evidence(directory(),M.CANONICAL,manifest)
        with self.assertRaises(FileExistsError):evidence.write('manifest.json',{'overwrite':True})

    def test_21_evidence_write_failure_before_first_process_is_zero_calls(self):
        runner,model,port=self.runner()
        with patch.object(runner.evidence,'begin',side_effect=OSError('canary')):
            with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        self.assertEqual([],model.calls);self.assertEqual('FAIL',caught.exception.report['status'])
        self.assertEqual('EVIDENCE_WRITE_FAILED',caught.exception.report['failure']['code'])

    def test_22_receipt_write_failure_after_mutation_is_unknown_and_stops(self):
        runner,model,port=self.runner();end=runner.evidence.end
        def fail(entry,result):
            if entry['phase']=='container_create':raise OSError('private storage canary')
            return end(entry,result)
        with patch.object(runner.evidence,'end',side_effect=fail):
            with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        self.assertEqual('UNKNOWN',caught.exception.report['status']);self.assertEqual('EVIDENCE_WRITE_FAILED',caught.exception.report['failure']['code'])
        self.assertEqual('container_create',model.calls[-1]['phase'])

    def test_23_strict_json_and_sql_frame_types_duplicates_unicode_and_correlation(self):
        value={'kind':'C1DOCKER','stage':'readiness','nonce':'0'*32,'ok':True,'probe':M.PROBE}
        raw=('C1DOCKER'+json.dumps(value,ensure_ascii=False)).encode();valid=raw;self.assertGreater(len(raw),20000)
        self.assertTrue(M.sql_frame(subprocess.CompletedProcess([],0,raw,b''),'readiness','0'*32,self.data)['ok'])
        for header in [b'c1docker_frame\n--------------\n',b'c1docker_frame\r\n--------------\r\n']:
            self.assertTrue(M.sql_frame(subprocess.CompletedProcess([],0,header+valid,b''),'readiness','0'*32,self.data)['ok'])
        for broken in [raw+b'\nnoise',raw.replace(b'"ok": true',b'"ok": true,"ok": true'),raw.replace(b'"ok": true',b'"ok": 1'),raw[:-1],raw.replace(b'"stage"',b'\n"stage"')]:
            with self.assertRaises(M.Fault):M.sql_frame(subprocess.CompletedProcess([],0,broken,b''),'readiness','0'*32,self.data)
        for raw in [b'{"x":NaN}',b'{"x":Infinity}',b'{"x":1,"x":2}',b'{}\n{}']:
            with self.assertRaises(M.Fault):M.json_bytes(raw)
        with self.assertRaises(M.Fault):M.sql_frame(subprocess.CompletedProcess([],0,valid,b''),'readiness','1'*32,self.data)
        with self.assertRaises(M.Fault):M.sql_frame(subprocess.CompletedProcess([],0,b'c1docker_frame\n----------\n'+valid,b''),'readiness','0'*32,self.data)

    def test_24_poststate_exports_all37_pk_and_complete_catalog_hashes_no_rows(self):
        text=M.sql_raw(self.data,'verify_database','0'*32).decode()
        for table,keys in self.data['module'].TABLE_KEYS.items():
            self.assertIn('SELECT * FROM dbo.['+table+'] ORDER BY '+','.join('['+key+']' for key in keys),text)
        for key in self.data['module'].CATALOG:self.assertIn(' AS ['+key+']',text)
        self.assertIn('FOR JSON PATH,INCLUDE_NULL_VALUES',text);self.assertIn('HASHBYTES',text)
        self.assertIn('sys.database_principals',text);self.assertIn('grantor_principal_id',text)
        self.assertIn('SUSER_SID(N\'sa\')',text);self.assertIn('V13-only poststate',text)

    def test_25_canonical_module_and_cli_tampering_fail_before_native_execution(self):
        original=Path.read_bytes
        def changed(path):
            if path==M.CANONICAL/M.MODULE:return b'tampered module'
            return original(path)
        with patch.object(Path,'read_bytes',changed):
            with self.assertRaisesRegex(M.Fault,'CANONICAL_PIN_CHANGED'):M.refs(M.CANONICAL)
        fake=Mock();fake.is_file.return_value=True;fake.read_bytes.return_value=b'tampered CLI'
        with patch.object(M,'local',return_value=fake):
            with self.assertRaisesRegex(M.Fault,'DOCKER_CLI_PIN_CHANGED'):M.cli_executable()

    def test_26_nonzero_exit_and_readonly_timeout_remain_uncertain_without_retry(self):
        result,runner,model=self.failure(exit_at='apply_v1_v13')
        self.assertEqual('UNKNOWN',result['status']);self.assertEqual('apply_v1_v13',model.calls[-1]['phase'])
        result,runner,model=self.failure(timeout_at='context')
        self.assertEqual('UNKNOWN',result['status']);self.assertEqual(1,len(model.calls));self.assertFalse(any(c['entry']['mutation'] for c in model.calls))

    def test_27_wrong_fresh_poststate_or_hash_set_cannot_produce_pass(self):
        for poststate in [{'tables':36},{'procedures':True},{'roleAcl':566},{'fingerprints':{}}]:
            result,runner,model=self.failure(poststate=poststate)
            self.assertEqual('UNKNOWN',result['status']);self.assertIsNone(result['baseline']);self.assertEqual('verify_database',model.calls[-1]['phase'])

    def test_28_summary_failure_after_fresh_verification_never_returns_pass(self):
        runner,model,port=self.runner()
        with patch.object(runner.evidence,'finish',side_effect=OSError('storage canary')):
            with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        self.assertEqual('UNKNOWN',caught.exception.report['status']);self.assertEqual('EVIDENCE_WRITE_FAILED',caught.exception.report['failure']['code'])
        self.assertFalse(caught.exception.report['evidence']['summaryWritten']);self.assertEqual('verify_database',model.calls[-1]['phase'])

    def test_29_evidence_creation_failure_and_nonconstant_faults_are_sanitized(self):
        manifest=copy.deepcopy(self.manifest);manifest.update(reviewed=True,innerSqlcmdSha256='F'*64);run=Mock();port=Mock()
        with patch.object(M.Evidence,'write',side_effect=OSError('storage canary')):
            with self.assertRaisesRegex(M.Fault,'EVIDENCE_WRITE_FAILED'):M.Provisioner(M.CANONICAL,manifest,directory(),run=run,port_check=port,environment={})
        run.assert_not_called();port.assert_not_called()
        self.assertEqual('CONTROLLER_FAILED',str(M.Fault('PRIVATE_FAULT_CANARY_0088')))

    def double_failure(self, options, *, summary_fail=False, journal_fail=False):
        runner,model,port=self.runner(**options);end=runner.evidence.end;append=runner.evidence.append
        def broken_end(entry,result):
            if entry['phase']=='apply_v1_v13':raise OSError('PRIVATE_STORAGE_CANARY_0099')
            return end(entry,result)
        def broken_append(value):
            if value['event']=='RESULT' and value['order']==36:raise OSError('PRIVATE_STORAGE_CANARY_0099')
            return append(value)
        with patch.object(runner.evidence,'append',side_effect=broken_append if journal_fail else append),patch.object(runner.evidence,'end',side_effect=end if journal_fail else broken_end):
            if summary_fail:
                with patch.object(runner.evidence,'finish',side_effect=OSError('PRIVATE_SUMMARY_CANARY_0099')):
                    with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
            else:
                with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        returned=caught.exception.report
        if summary_fail:
            self.assertFalse((runner.evidence.path/'summary.json').exists())
            # Explicit caller/CLI-output capture, NOT a fabricated tool journal.
            snapshot=runner.evidence.path/'model-caller-output.json'
            with snapshot.open('x',encoding='utf-8') as stream:json.dump({'kind':'CALLER_CAPTURE_OF_UNPERSISTED_REPORT','report':returned},stream)
            result=json.loads(snapshot.read_text())['report']
        else:result=json.loads((runner.evidence.path/'summary.json').read_text())
        self.assertEqual(returned,result)
        self.assertEqual('UNKNOWN',result['status']);self.assertEqual('apply_v1_v13',model.calls[-1]['phase'])
        self.assertEqual(36,len(model.calls));self.assertEqual(1,sum(c['phase']=='apply_v1_v13' for c in model.calls))
        self.assertFalse(result['cleanupAttempted']);self.assertFalse(result['retryAttempted'])
        self.assertFalse(any(c['phase']=='apply_v1_v13' for c in result['receipts']))
        attempt=json.loads((runner.evidence.path/'0036-attempt.json').read_text())
        failure=result['failure'];self.assertEqual(36,failure['lastAttemptOrder']);self.assertEqual(attempt['nonce'],failure['nonce'])
        self.assertRegex(failure['nonce'],'^[0-9a-f]{32}$');self.assertEqual({'volume':M.VOLUME,'container':model.cid},failure['ids'])
        self.assertTrue(result['attempts'][-1]['processStarted']);self.assertFalse(result['attempts'][-1]['resultRecorded'])
        for path in runner.evidence.path.iterdir():
            if path.is_file():
                for canary in [b'PRIVATE_TIMEOUT_CANARY_0088',b'PRIVATE_STDERR_CANARY_0088',b'PRIVATE_EXIT_CANARY_0088',b'PRIVATE_INVALID_FRAME_CANARY_0088',b'PRIVATE_STORAGE_CANARY_0099',b'PRIVATE_SUMMARY_CANARY_0099',b'PRIVATE_SA_CANARY_0088']:
                    self.assertNotIn(canary,path.read_bytes())
        return result,runner,model

    def test_30_timeout_and_result_write_failure_keep_primary_secondary_and_known_stats(self):
        result,runner,model=self.double_failure({'timeout_at':'apply_v1_v13'})
        primary=result['failure'];self.assertEqual('PROCESS_TIMEOUT_UNKNOWN',primary['code']);self.assertEqual('process',primary['stage'])
        self.assertIsNone(primary['transport']['exit'])
        for field,raw in [('stdout',b'PRIVATE_TIMEOUT_CANARY_0088'),('stderr',b'PRIVATE_STDERR_CANARY_0088')]:
            self.assertEqual({'bytes':len(raw),'sha256':M.sha(raw)},primary['transport'][field])
        self.assertEqual(1,len(result['secondaryFailures']));secondary=result['secondaryFailures'][0]
        self.assertEqual('EVIDENCE_WRITE_FAILED',secondary['code']);self.assertEqual('result_evidence',secondary['stage'])
        self.assertEqual(primary['nonce'],secondary['nonce']);self.assertEqual(primary['transport'],secondary['transport'])
        self.assertIsNone(result['attempts'][-1]['receipt']);self.assertTrue(result['evidence']['summaryWritten'])

    def test_31_native_exit_or_invalid_frame_plus_storage_never_lose_original_cause(self):
        for options,code,exit_code,raw in [({'exit_at':'apply_v1_v13'},'PROCESS_RECEIPT_INVALID',7,b'PRIVATE_EXIT_CANARY_0088'),({'frame_at':'apply_v1_v13'},'PROTOCOL_INVALID',0,b'PRIVATE_INVALID_FRAME_CANARY_0088')]:
            result,runner,model=self.double_failure(options)
            self.assertEqual(code,result['failure']['code']);self.assertEqual(exit_code,result['failure']['transport']['exit'])
            self.assertEqual({'bytes':len(raw),'sha256':M.sha(raw)},result['failure']['transport']['stdout'])
            self.assertEqual('EVIDENCE_WRITE_FAILED',result['secondaryFailures'][0]['code'])
            self.assertIsNone(result['attempts'][-1]['receipt'])

    def test_32_summary_failure_is_an_additional_secondary_and_cannot_hide_two_original_errors(self):
        for options,code in [({'timeout_at':'apply_v1_v13'},'PROCESS_TIMEOUT_UNKNOWN'),({'exit_at':'apply_v1_v13'},'PROCESS_RECEIPT_INVALID'),({'frame_at':'apply_v1_v13'},'PROTOCOL_INVALID')]:
            result,runner,model=self.double_failure(options,summary_fail=True)
            self.assertEqual(code,result['failure']['code']);self.assertFalse(result['evidence']['summaryWritten'])
            self.assertEqual(['result_evidence','summary_evidence'],[f['stage'] for f in result['secondaryFailures']])
            self.assertEqual(['EVIDENCE_WRITE_FAILED']*2,[f['code'] for f in result['secondaryFailures']])
            self.assertEqual({'exit':None,'stdout':None,'stderr':None},result['secondaryFailures'][1]['transport'])

    def test_33_storage_only_is_primary_and_does_not_invent_a_native_error(self):
        result,runner,model=self.double_failure({})
        self.assertEqual('EVIDENCE_WRITE_FAILED',result['failure']['code']);self.assertEqual('result_evidence',result['failure']['stage'])
        self.assertEqual([],result['secondaryFailures']);self.assertEqual(0,result['failure']['transport']['exit'])
        self.assertIsNone(result['attempts'][-1]['code']);self.assertEqual('apply_v1_v13',result['attempts'][-1]['receipt']['stage'])

    def test_34_journal_append_failure_keeps_the_published_native_result_and_primary(self):
        result,runner,model=self.double_failure({'timeout_at':'apply_v1_v13'},journal_fail=True)
        stored=json.loads((runner.evidence.path/'0036-result.json').read_text())
        self.assertEqual('PROCESS_TIMEOUT_UNKNOWN',stored['code']);self.assertEqual(stored['transport'],result['failure']['transport'])
        self.assertEqual('PROCESS_TIMEOUT_UNKNOWN',result['failure']['code']);self.assertEqual('EVIDENCE_WRITE_FAILED',result['secondaryFailures'][0]['code'])

    def test_35_attempt_and_summary_failure_before_first_process_is_zero_calls_and_no_timeout(self):
        runner,model,port=self.runner()
        with patch.object(runner.evidence,'begin',side_effect=OSError('storage canary')),patch.object(runner.evidence,'finish',side_effect=OSError('summary canary')):
            with self.assertRaises(M.ProvisionFailure) as caught:runner.execute()
        result=caught.exception.report;self.assertEqual([],model.calls);port.assert_not_called()
        self.assertEqual('FAIL',result['status']);self.assertEqual('EVIDENCE_WRITE_FAILED',result['failure']['code'])
        self.assertEqual('prepare',result['failure']['stage']);self.assertEqual({'exit':None,'stdout':None,'stderr':None},result['failure']['transport'])
        self.assertEqual([],result['attempts']);self.assertEqual('summary_evidence',result['secondaryFailures'][0]['stage'])
        self.assertNotIn('PROCESS_TIMEOUT_UNKNOWN',json.dumps(result));self.assertFalse(result['evidence']['summaryWritten'])
        capture=runner.evidence.path/'model-caller-output.json'
        with capture.open('x',encoding='utf-8') as stream:json.dump({'kind':'CALLER_CAPTURE_OF_UNPERSISTED_REPORT','report':result},stream)
        self.assertEqual(result,json.loads(capture.read_text())['report'])



    def test_36_administrative_guard_policy_keeps_external_and_doomed_transactions_closed(self):
        # Structure/policy model only: no SQL states are fabricated in an engine.
        guard=M.engine_guard('master')
        match=re.search(r'OR @@TRANCOUNT<>0 OR XACT_STATE\(\) NOT IN \(([^)]+)\)',guard)
        self.assertIsNotNone(match)
        accepted_states={int(value) for value in match.group(1).split(',')}
        self.assertEqual({0,1},accepted_states)
        cases=[(0,0,True),(0,1,True),(0,-1,False),(0,2,False),(0,-2,False),
               (1,0,False),(1,1,False),(1,-1,False),(2,1,False)]
        for count,state,expected in cases:
            with self.subTest(count=count,state=state):
                self.assertEqual(expected,count==0 and state in accepted_states)
        self.assertNotIn('COMMIT',guard);self.assertNotIn('ROLLBACK',guard)
        self.assertNotIn('BEGIN TRAN',guard)

    def test_37_migration_commit_boundary_and_all_nontransaction_guards_remain_strict(self):
        guard=M.engine_guard('master')
        for fragment in ["DB_NAME()", "SERVERPROPERTY('MachineName')", "ProductMajorVersion", "Developer Edition%", "CONNECTIONPROPERTY('net_transport')", "SUSER_SNAME()", "IS_SRVROLEMEMBER(N'sysadmin')", "Latin1_General_100_BIN2"]:
            self.assertIn(fragment,guard)
        apply=M.sql_raw(self.data,'apply_v1_v13','0'*32)
        self.assertIn(b'IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999',apply)
        for n in range(1,14):self.assertEqual(1,apply.count(self.data['migrations'][n]['bytes'].removeprefix(b'\xef\xbb\xbf')))
        self.assertNotIn(self.data['migrations'][14]['bytes'],apply)

    def assert_render(self,raw):
        rendered,offsets=M.render_sql_details(raw)
        self.assertEqual(rendered,M.render_sql(raw));self.assertEqual(rendered,M.render_sql(rendered))
        self.assertTrue(all(len(line)<=4094 for line in rendered.split(b'\n')))
        # Independently remove exactly the recorded inserted bytes, never LF
        # belonging to literals/comments or original CRLF/BOM.
        restored=bytearray(rendered)
        for extra,original in reversed(list(enumerate(offsets))):
            at=original+extra;self.assertEqual(10,restored[at]);del restored[at]
            self.assertIn(raw[original],b' \t\r\v\f')
        self.assertEqual(raw,bytes(restored));rendered.decode('utf-8',errors='strict')
        return rendered,offsets

    def test_38_renderer_byte_boundary_counts_cr_and_preserves_all_bytes(self):
        self.assertEqual(b'a'*4094,M.render_sql(b'a'*4094))
        rendered,offsets=self.assert_render(b'a'*4094+b' ')
        self.assertEqual((4094,),offsets);self.assertEqual(b'a'*4094+b'\n ',rendered)
        rendered,offsets=self.assert_render(b'a'*4094+b'\r\n')
        self.assertEqual(b'a'*4094+b'\n\r\n',rendered)
        for raw in (b'a'*4095,b'a'*4095+b' ',b':setvar x '+b'a'*4095):
            with self.assertRaisesRegex(M.Fault,'^SQL_INPUT_UNREPRESENTABLE$'):M.render_sql(raw)

    def test_39_renderer_lexical_islands_unicode_escapes_comments_and_identifiers(self):
        tokens=[("N'á🦷中 a''b "+'x'*700+"'").encode(),b'[identifier ]] with space '+b'x'*700+b']',b'"identifier "" with space '+b'x'*700+b'"',b'/* outer '+b'x'*600+b' /* inner */ tail */']
        raw=b'\xef\xbb\xbfSELECT '+b' + '.join(tokens*3)+b'; -- must stay a comment\r\n'+b'/* nested\r\n/* block */ end */\nSELECT N\'multiline\ntext\';\n'
        rendered,offsets=self.assert_render(raw);self.assertTrue(offsets);self.assertTrue(rendered.startswith(b'\xef\xbb\xbf'))
        for token in tokens:self.assertEqual(raw.count(token),rendered.count(token))
        self.assertIn(b'; -- must stay a comment\r\n',rendered);self.assertIn(b"N'multiline\ntext'",rendered)

    def test_40_renderer_never_splits_comments_literals_or_directives(self):
        for token in (b"N'"+b'x '*2200+b"'",b'-- '+b'x '*2200,b'/* '+b'x '*2200+b' */',b'['+b'x '*2200+b']',b'"'+b'x '*2200+b'"'):
            with self.assertRaisesRegex(M.Fault,'^SQL_INPUT_UNREPRESENTABLE$'):M.render_sql(token)
        raw=b':On Error exit\r\nGO -- keep entire directive\r\nSELECT '+b'x + '*1300+b'1;\r\nGO 2\r\n'
        rendered,offsets=self.assert_render(raw)
        self.assertIn(b':On Error exit\r\nGO -- keep entire directive\r\n',rendered);self.assertTrue(rendered.endswith(b'GO 2\r\n'))
        # Moving GO to a fresh physical line must not manufacture a batch.
        with self.assertRaisesRegex(M.Fault,'^SQL_INPUT_UNREPRESENTABLE$'):M.render_sql(b'x'*4094+b' GO')

    def test_41_renderer_rejects_invalid_utf8_and_unclosed_lexemes_with_fixed_codes(self):
        for raw in (b'\xff',b'SELECT '+b'\xf0\x9f'):
            with self.assertRaisesRegex(M.Fault,'^SQL_INPUT_UTF8_INVALID$'):M.render_sql(raw)
        for raw in (b"SELECT N'unclosed",b'/* unclosed',b'[unclosed',b'"unclosed'):
            with self.assertRaisesRegex(M.Fault,'^SQL_INPUT_UNREPRESENTABLE$'):M.render_sql(raw)

    def test_42_all_five_raw_corpora_and_wire_payloads_reconstruct_exactly(self):
        for stage in M.SQL_STAGES:
            raw=M.sql_raw(self.data,stage,'0'*32);rendered,offsets=self.assert_render(raw)
            self.assertEqual(rendered,M.sql(self.data,stage,'0'*32))
            self.assertTrue(raw.startswith(b':On Error exit\n'));self.assertTrue(rendered.startswith(b':On Error exit\n'))
            if stage=='apply_v1_v13':
                self.assertTrue(offsets);self.assertIn(b'IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999',rendered)
                for n in range(1,14):self.assertEqual(1,raw.count(self.data['migrations'][n]['bytes'].removeprefix(b'\xef\xbb\xbf')))

    def test_43_unrepresentable_payload_stops_before_sql_without_fallback(self):
        with patch.object(M,'sql_raw',return_value=b"SELECT N'"+b'x'*4095+b"'"):
            result,runner,model=self.failure()
        self.assertEqual('SQL_INPUT_UNREPRESENTABLE',result['failure']['code'])
        self.assertFalse(any(c['phase'] in M.SQL_STAGES for c in model.calls))
        self.assertFalse(result['retryAttempted']);self.assertFalse(result['cleanupAttempted'])

if __name__=='__main__':unittest.main()
