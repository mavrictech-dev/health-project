"""Offline generation/transport/frame orchestration only. Every subprocess is doubled."""
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import unittest
import uuid
from unittest.mock import Mock, patch

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('c1p2_controller',ROOT/'scripts/verify-patient-link-management-sql.py')
M=importlib.util.module_from_spec(SPEC);sys.modules[SPEC.name]=M;SPEC.loader.exec_module(M)
N='1'*32


def response(prefix, payload, raw=0, stderr=b'', header=False):
    body=prefix+json.dumps(payload,ensure_ascii=False,separators=(',',':'))
    if header:body=M.HEADER+body
    return subprocess.CompletedProcess([],raw,body.encode('utf-8'),stderr)


def baseline(n=N):
    return {'kind':'BASELINE','mode':M.MODE,'nonce':n,'status':'PASS','sp_count':134,'trigger_count':31,'role_acl_count':564,'optional_history':False,'application_mode':'OPEN','fingerprints':{k:'A'*64 for k in M.FINGERPRINT_KEYS},'probe':M.PROBE}


def phase(name='sequence_human_adm',n=N,state=None):
    p=M.BY_NAME[name]
    state=(0 if p.error==0 else 1) if state is None else state
    return {'kind':'PHASE','mode':M.MODE,'nonce':n,'phase':name,'status':'PASS','error':p.error,'xact_state':state,'cleanup':'CLOSE' if state==-1 else 'EXPLICIT','checks':p.checks,'probe':M.PROBE}


class ControllerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source=(ROOT/M.TEMPLATE).read_text(encoding='utf-8')
        # Local canonical source reads only. Missing historical worker V10-V12
        # are NOT copied/synced and never trigger a live-DB fallback.
        canonical=Path('D:/Mavric/Health Project')
        cls.bundle=M.load_bundle(canonical,ROOT/M.TEMPLATE)

    def test_01_exact_mode_and_closed_matrix(self):
        self.assertEqual(M.command('PRE_APLICACION'),M.MODE)
        for value in ['pre_aplicacion','PRE_APLICACION ',' PRE_APLICACION','POST','APPLY','COMMIT','REPAIR',True,None]:
            with self.subTest(value=value),self.assertRaises(M.Failure):M.command(value)
        self.assertEqual(len(M.PHASES),len(M.BY_NAME));self.assertGreater(len({p.family for p in M.PHASES}),15)
        self.assertTrue(all(re.fullmatch('[a-z0-9_]{1,80}',p.name) for p in M.PHASES))
        self.assertTrue(any('counter0' in item for item in M.PENDING));self.assertTrue(any('Two-connection' in item for item in M.PENDING))

    def test_02_whole_sql_is_nonexecuting_template_after_guard(self):
        self.assertTrue(self.source.startswith('-- C1P2 PREPARATION ONLY.'))
        self.assertIn(':On Error exit\nTHROW 59999',self.source)
        self.assertEqual(1,self.source.count('/*'));self.assertEqual(1,self.source.count('*/'))
        self.assertIn('Templates only:',self.source)
        self.assertEqual(set(M.SECTIONS),set(M.sections(self.source)))
        for source in [self.source+self.source,self.source.replace('-- C1P2_CASE_END','-- MISSING_END'),self.source+'\n-- C1P2_UNKNOWN_BEGIN\n-- C1P2_UNKNOWN_END']:
            with self.assertRaises(M.Failure):M.sections(source)

    def test_03_all_phases_compose_complete_exact_v14_and_stop_on_error(self):
        migration=self.bundle[1]
        for p in M.PHASES:
            with self.subTest(phase=p.name):
                sql=M.phase_sql(self.bundle,p.name,N)
                self.assertTrue(sql.startswith(':On Error exit\n'))
                self.assertEqual(1,len(re.findall(r'(?m)^:On Error exit\r?$',sql)))
                self.assertEqual(1,sql.count(migration))
                self.assertNotRegex(sql,r'__[A-Z_]+__')
                self.assertLess(sql.index('BEGIN TRANSACTION;'),sql.index(migration))
                self.assertIn('ROLLBACK TRANSACTION;',sql)
                self.assertNotRegex(re.sub(r'--[^\n]*','',sql),r'(?i)\bCOMMIT\b|SET\s+PARSEONLY|UPDATE\s+dbo\.application_state|CREATE\s+LOGIN|ALTER\s+AUTHORIZATION')
                self.assertIn('CREATE USER hp_qa_c1p2_runtime WITHOUT LOGIN;',sql)
                self.assertIn('EXECUTE AS USER=',sql)
                self.assertEqual(p.error==59998,'CREATE TRIGGER dbo.hp_qa_c1p2_audit_failure' in sql)
        with self.assertRaises(M.Failure):M.phase_sql(self.bundle,"x';COMMIT--",N)
        with self.assertRaises(M.Failure):M.phase_sql(self.bundle,M.PHASES[0].name,'not-a-nonce')

    def test_04_all37_tables_and_catalog_surfaces_are_fingerprinted(self):
        self.assertEqual(37,len(M.TABLE_KEYS));self.assertIn('audit_events',M.TABLE_KEYS)
        sql=M.baseline_sql(self.bundle,N)
        for table,keys in M.TABLE_KEYS.items():
            self.assertIn('SELECT * FROM dbo.['+table+'] ORDER BY '+','.join('['+k+']' for k in keys),sql)
            self.assertIn('[table_'+table+']',sql)
        for key in ['modules','columns','defaults','checks','foreign_keys','foreign_key_columns','indexes','index_columns','triggers','trigger_events','acl','role_memberships','principals','schemas','database','extended_properties','identity_metadata','optional_history']:
            self.assertIn('['+key+']',sql)
        self.assertNotIn('last_value',M.CATALOG['identity_metadata'])
        self.assertIn('grantor_principal_id',M.CATALOG['acl']);self.assertIn('owner_sid',M.CATALOG['database'])
        self.assertIn('flyway_schema_history',sql)
        self.assertNotIn('__',sql)

    def test_05_manifest_pins_are_closed_and_fail_on_any_changed_file(self):
        paths={M.DRIVER:ROOT/M.DRIVER,M.TEMPLATE:ROOT/M.TEMPLATE,M.TEST:ROOT/M.TEST}
        pins={k:M.digest(p.read_bytes()) for k,p in paths.items()}
        manifest={'mode':M.MODE,'reviewed_sources':pins}
        M.validate_manifest(ROOT,manifest)
        for name in pins:
            bad={**manifest,'reviewed_sources':{**pins,name:'0'*64}}
            with self.subTest(name=name),self.assertRaises(M.Failure):M.validate_manifest(ROOT,bad)
        with self.assertRaises(M.Failure):M.validate_manifest(ROOT,{'mode':M.MODE,'reviewed_sources':{**pins,'extra':'0'*64}})
        with self.assertRaises(M.Failure):M.validate_manifest(ROOT,{'mode':'POST','reviewed_sources':pins})
        with patch.object(Path,'read_bytes',return_value=b'changed'):
            with self.assertRaises(M.Failure):M.load_bundle(Path('D:/Mavric/Health Project'),ROOT/M.TEMPLATE)

    def test_06_long_unicode_bare_and_exact_header_frames(self):
        value=baseline()
        for header in [False,True]:
            raw=response('C1P2_BASELINE',value,header=header).stdout
            self.assertGreater(len(raw),20000)
            self.assertEqual(value,M.frame(raw,'C1P2_BASELINE'))
            self.assertEqual(value,M.frame(b'\xef\xbb\xbf'+raw+b'\r\n','C1P2_BASELINE'))
        raw=response('C1P2_BASELINE',value).stdout
        for corrupted in [b'c1p2_frame\n--------\n'+raw,b'other\n----------\n'+raw,raw+b'\n'+raw,b'noise\n'+raw,raw+b'\nnoise',b'\n'+raw,raw+b'\n\n',raw.replace(b'"status"',b'\n"status"'),raw[:-1],b'\xff'+raw]:
            with self.subTest(length=len(corrupted)),self.assertRaises(M.Failure):M.frame(corrupted,'C1P2_BASELINE')

    def test_07_json_duplicates_constants_top_types_and_trailing_text_are_rejected(self):
        for text in ['{"status":"PASS","status":"FAIL"}','{"fingerprints":{"x":1,"x":2}}','{"n":NaN}','{"n":Infinity}','[]','true','null','{} {}','{"a":1}\n']:
            raw=('C1P2_RESULT'+text).encode()
            if text.endswith('\n'):continue  # The exact SQLcmd terminal newline is allowed.
            with self.subTest(text=text),self.assertRaises(M.Failure):
                value=M.frame(raw,'C1P2_RESULT')
                M.need(type(value) is dict,'bad')

    def test_08_baseline_fields_types_prerequisites_and_correlation(self):
        value=baseline();self.assertEqual('PASS',M.baseline_response(response('C1P2_BASELINE',value),N)['status'])
        for key,bad in [('sp_count',True),('sp_count',135),('trigger_count',30),('role_acl_count',True),('role_acl_count',566),('optional_history',1),('application_mode','READ_ONLY'),('nonce','2'*32),('mode','POST'),('probe',M.PROBE[:-1]),('fingerprints',{})]:
            with self.subTest(key=key),self.assertRaises(M.Failure):M.baseline_response(response('C1P2_BASELINE',{**value,key:bad}),N)
        with self.assertRaises(M.Failure):M.baseline_response(response('C1P2_BASELINE',value,raw=False),N)
        value['optional_history']=True;value['role_acl_count']=573;M.baseline_response(response('C1P2_BASELINE',value),N)
        for raw,stderr in [(1,b''),(0,b'engine error'),(16,b'3998')]:
            with self.assertRaises(M.Failure):M.baseline_response(response('C1P2_BASELINE',value,raw,stderr),N)

    def test_09_raw_zero_and_error_text_never_substitute_for_phase_frame(self):
        name='revision_exponent';value=phase(name)
        good=response('C1P2_RESULT',value)
        self.assertEqual(51000,M.phase_response(good,name,N)['error'])
        for key,bad in [('error',True),('error',0),('xact_state',True),('xact_state',0),('checks',True),('checks',0),('nonce','2'*32),('phase','other'),('status','FAIL'),('probe',M.PROBE[:-1])]:
            with self.subTest(key=key),self.assertRaises(M.Failure):M.phase_response(response('C1P2_RESULT',{**value,key:bad}),name,N)
        for r in [subprocess.CompletedProcess([],0,b'',b'Msg51000'),subprocess.CompletedProcess([],0,b'PASS',b''),response('C1P2_RESULT',value,0,b'51000'),response('C1P2_RESULT',value,16,b'')]:
            with self.assertRaises(M.Failure):M.phase_response(r,name,N)

    def test_10_doom_requires_exact3998_raw16_error_state_and_no_extra_messages(self):
        name='revision_exponent';value=phase(name,state=-1)
        message=b'Msg 3998, Level 16, State 1, Line 900\r\nUncommittable transaction is detected at the end of the batch. The transaction is rolled back.'
        self.assertEqual(-1,M.phase_response(response('C1P2_RESULT',value,16,message),name,N)['xact_state'])
        for raw,stderr in [(0,message),(16,b''),(16,message+b'\nother'),(16,message.replace(b'3998',b'51000')),(16,message.replace(b'State 1',b'State 2')),(16,message.replace(b'rolled back.',b'committed.'))]:
            with self.subTest(raw=raw,stderr=stderr),self.assertRaises(M.Failure):M.phase_response(response('C1P2_RESULT',value,raw,stderr),name,N)
        with self.assertRaises(M.Failure):M.phase_response(response('C1P2_RESULT',phase('sequence_human_adm',state=-1),16,message),'sequence_human_adm',N)

    def test_11_scoped_environment_rejects_sqlcmd_and_does_not_inherit_credentials_or_path(self):
        env=M.environment({'SystemRoot':r'C:\Windows','PATH':'evil','SECRET_PASSWORD':'canary','ODBCINI':'canary','TEMP':r'C:\Temp'})
        self.assertNotIn('SECRET_PASSWORD',env);self.assertNotIn('ODBCINI',env);self.assertNotIn('evil',env['PATH']);self.assertEqual(r'C:\Temp',env['TEMP'])
        for key in ['SQLCMDPASSWORD','SqlCmdServer','SQLCMDINI','sqlcmdanything']:
            with self.subTest(key=key),self.assertRaises(M.Failure):M.environment({key:'canary'})
        for env in [{'SystemRoot':r'C:\evil'},{'TEMP':'relative'},{'TEMP':r'\\remote\share'}]:
            with self.assertRaises(M.Failure):M.environment(env)

    def test_12_transport_uses_only_pinned_lpc_integrated_args_utf8_and_deadlines(self):
        run=Mock(return_value=subprocess.CompletedProcess([],0,b'',b''));resolve=Mock(return_value=str(M.SQLCMD))
        transport=M.Transport(environ={},run=run,resolve=resolve)
        sql=':On Error exit\nSELECT N\'🦷中\';\n';transport.invoke(sql)
        args=run.call_args.args[0];kwargs=run.call_args.kwargs
        self.assertEqual(str(M.SQLCMD),args[0]);self.assertEqual(M.SERVER,args[args.index('-S')+1]);self.assertEqual(M.DATABASE,args[args.index('-d')+1]);self.assertIn('-E',args)
        self.assertNotIn('-U',args);self.assertNotIn('-P',args);self.assertFalse(kwargs['shell']);self.assertEqual(sql.encode('utf-8'),kwargs['input']);self.assertEqual(300,kwargs['timeout'])
        for flag,value in [('-V','11'),('-r','1'),('-f','65001'),('-y','0'),('-w','65535'),('-l','5'),('-t','120')]:self.assertEqual(value,args[args.index(flag)+1])
        for flag in ['-b','-x','-X1']:self.assertIn(flag,args)
        transport.invoke(sql);self.assertEqual(2,resolve.call_count)
        for sql in ['SELECT1',':On Error exit\n:connect evil',':On Error exit\n!!cmd',':On Error exit\n:r file',':On Error exit\n:On Error ignore',':On Error exit\n:reset',':On Error exit\n:quit']:
            with self.assertRaises(M.Failure):transport.invoke(sql)

    def test_13_timeout_is_failure_no_retry_and_no_engine_is_started(self):
        run=Mock(side_effect=subprocess.TimeoutExpired('fake',300));transport=M.Transport(environ={},run=run,resolve=lambda:str(M.SQLCMD))
        with self.assertRaisesRegex(M.Failure,'TRANSPORT_TIMEOUT'):transport.invoke(':On Error exit\nSELECT1;')
        self.assertEqual(1,run.call_count)

    def test_14_executable_hash_and_expected_path_fail_closed_without_probe(self):
        with patch.object(Path,'is_file',return_value=True),patch.object(Path,'is_symlink',return_value=False),patch.object(Path,'stat',return_value=Mock(st_file_attributes=0)),patch.object(Path,'read_bytes',return_value=b'wrong'):
            with self.assertRaisesRegex(M.Failure,'SQLCMD_PIN_MISMATCH'):M.executable()
        with self.assertRaises(M.Failure):M.executable(Path(r'C:\unapproved\sqlcmd.exe'))

    def new_evidence(self):
        return M.Evidence(Path(os.environ['TEMP'])/('C1P2R1-unit-'+uuid.uuid4().hex),ROOT)

    def fake_run(self, failure=None, drift=None, failure_phase=None, initial_failure=False, baseline_failure_at=None):
        events=[];baseline_count=0
        def invoke(sql):
            nonlocal baseline_count
            correlation=re.search(r"N'([0-9a-f]{32})' nonce",sql).group(1)
            if 'C1P2_BASELINE' in sql:
                baseline_count+=1;events.append('baseline');value=baseline(correlation)
                if (initial_failure and baseline_count==1) or baseline_count==baseline_failure_at:
                    return subprocess.CompletedProcess([],0,b'canary-invalid-baseline-frame',b'')
                if baseline_count==drift:value['fingerprints']['table_patients']='B'*64
                return response('C1P2_BASELINE',value)
            name=re.search(r"INSERT #c1p2_phase VALUES\('([a-z0-9_]+)'\)",sql).group(1);events.append(name)
            if failure_phase is None or name==failure_phase:
                if isinstance(failure,Exception):raise failure
                if failure=='frame':return subprocess.CompletedProcess([],0,b'PASS',b'')
            return response('C1P2_RESULT',phase(name,correlation))
        return M.Runner(self.bundle,Mock(invoke=invoke),self.new_evidence()),events

    def test_15_runner_new_connections_before_after_each_phase_and_final(self):
        runner,events=self.fake_run();result=runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        self.assertTrue(result['restored']);self.assertEqual(['baseline','baseline','sequence_human_adm','baseline','baseline','revision_exponent','baseline','baseline'],events)
        self.assertEqual(2,len(result['checks']))

    def test_16_timeout_and_bad_frame_stop_and_still_check_fresh_restoration_and_final(self):
        for failure in [M.Failure('TRANSPORT_TIMEOUT'),'frame']:
            runner,events=self.fake_run(failure=failure)
            with self.subTest(failure=failure),self.assertRaises(M.Failure):runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
            self.assertEqual(['baseline','baseline','sequence_human_adm','baseline','baseline'],events)

    def test_17_baseline_drift_never_passes_or_continues(self):
        for when in [2,3,4]:
            runner,events=self.fake_run(drift=when)
            with self.subTest(when=when),self.assertRaises(M.Failure):runner.execute(M.MODE,['sequence_human_adm'])
            self.assertLessEqual(events.count('sequence_human_adm'),1)

    def test_18_wrong_mode_and_phase_never_reach_transport(self):
        transport=Mock();runner=M.Runner(self.bundle,transport)
        for mode in ['POST','PRE_APLICACION ']:
            with self.assertRaises(M.Failure):runner.execute(mode)
        for names in [[],['unknown'],['sequence_human_adm','sequence_human_adm']]:
            with self.assertRaises(M.Failure):runner.execute(M.MODE,names)
        transport.invoke.assert_not_called()

    def stored_summary(self, runner):
        # Read durable files after execute returns/raises, never substitute a
        # variable captured in the fake subprocess for a journal artifact.
        return json.loads((runner.evidence.path/'summary.json').read_text(encoding='utf-8'))

    def test_19_second_phase_invalid_frame_retains_primary_partial_and_durable_records(self):
        runner,events=self.fake_run(failure='frame',failure_phase='revision_exponent')
        with self.assertRaises(M.RunFailure) as caught:
            runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        result=self.stored_summary(runner)
        self.assertEqual(caught.exception.report,result);self.assertEqual('FAIL',result['status'])
        failure=result['primaryFailure'];self.assertEqual('FRAME_INVALID',failure['code'])
        self.assertEqual('phasevalidate',failure['stage']);self.assertEqual('revision_exponent',failure['phase'])
        self.assertRegex(failure['nonce'],'^[0-9a-f]{32}$');self.assertEqual('PARTIAL',result['checksStatus'])
        self.assertEqual(1,len(result['checks']));self.assertEqual('sequence_human_adm',result['checks'][0]['phase'])
        self.assertEqual(8,len(events));self.assertEqual(8,len(result['attempts']))
        self.assertEqual(2,len(result['conservation']['postbaseline']));self.assertTrue(result['conservation']['final']['matchesInitial'])
        for attempt in result['attempts']:
            self.assertTrue(attempt['attemptRecorded']);self.assertTrue(attempt['resultRecorded'])
            stored=json.loads((runner.evidence.path/attempt['attempt']).read_text())
            self.assertEqual(attempt['nonce'],stored['nonce'])
            sql=(runner.evidence.path/stored['sql']['file']).read_bytes()
            self.assertEqual(stored['sqlSha256'],M.digest(sql))
            outcome=json.loads((runner.evidence.path/attempt['result']).read_text())
            if attempt['stage']=='phaseinvoke' and attempt['phase']=='revision_exponent':
                self.assertIsNone(outcome['validatedFrame']);self.assertEqual('FAILED',outcome['validation'])
                self.assertEqual(0,outcome['transport']['returncode']);self.assertEqual(4,outcome['transport']['stdout']['bytes'])
        journal=[json.loads(line) for line in (runner.evidence.path/'journal.jsonl').read_text().splitlines()]
        self.assertEqual(8,sum(item['event']=='ATTEMPT' for item in journal))
        self.assertEqual(8,sum(item['event']=='RESULT' for item in journal))
        self.assertEqual(1,sum(item['event']=='CHECK_ACCEPTED' for item in journal))

    def test_20_final_baseline_error_or_drift_cannot_replace_primary(self):
        for options,secondary in [({'drift':6},'FINAL_BASELINE_DRIFT'),({'baseline_failure_at':6},'FRAME_INVALID')]:
            runner,events=self.fake_run(failure='frame',failure_phase='revision_exponent',**options)
            with self.subTest(options=options),self.assertRaises(M.RunFailure) as caught:
                runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
            result=self.stored_summary(runner);self.assertEqual('FRAME_INVALID',str(caught.exception))
            self.assertEqual('revision_exponent',result['primaryFailure']['phase'])
            self.assertEqual('phasevalidate',result['primaryFailure']['stage'])
            self.assertTrue(any(f['code']==secondary and f['stage']=='finalbaseline' for f in result['secondaryFailures']))
            self.assertEqual(1,len(result['checks']));self.assertEqual('PARTIAL',result['checksStatus'])
            self.assertEqual(8,len(events));self.assertIsNot(result['conservation']['final']['matchesInitial'],True)

    def test_21_timeout_concrete_code_survives_with_new_cleanup_connections(self):
        for code in ['TIMEOUT','TRANSPORT_TIMEOUT']:
            runner,events=self.fake_run(failure=M.Failure(code),failure_phase='revision_exponent')
            with self.subTest(code=code),self.assertRaises(M.RunFailure):
                runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
            result=self.stored_summary(runner)
            self.assertEqual(code,result['primaryFailure']['code']);self.assertEqual('phaseinvoke',result['primaryFailure']['stage'])
            self.assertEqual(1,len(result['checks']));self.assertTrue(result['restored'])
            self.assertEqual(['baseline','baseline'],events[-2:])
            outcome=json.loads((runner.evidence.path/'0006-result.json').read_text())
            self.assertEqual('TRANSPORT_FAILED',outcome['outcome']);self.assertIsNone(outcome['transport']['returncode'])

    def test_22_initial_baseline_failure_retains_unknown_conservation_and_final_attempt(self):
        runner,events=self.fake_run(initial_failure=True)
        with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm'])
        result=self.stored_summary(runner)
        self.assertEqual(['baseline','baseline'],events);self.assertEqual([],result['checks'])
        self.assertEqual('baselineinitial',result['primaryFailure']['stage'])
        self.assertEqual('FAILED',result['conservation']['initial']['status'])
        self.assertEqual('VALID',result['conservation']['final']['status'])
        self.assertIsNone(result['conservation']['final']['matchesInitial']);self.assertFalse(result['restored'])

    def test_23_evidence_failure_before_first_transport_leaves_zero_calls(self):
        transport=Mock()
        path=Path(os.environ['TEMP'])/('C1P2R1-unit-'+uuid.uuid4().hex)
        with patch.object(M.Evidence,'_write',side_effect=OSError('private canary')):
            with self.assertRaisesRegex(M.Failure,'EVIDENCE_WRITE_FAILED'):M.Evidence(path,ROOT)
        transport.invoke.assert_not_called()
        runner,events=self.fake_run()
        with patch.object(runner.evidence,'begin',side_effect=OSError('private canary')):
            with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm'])
        self.assertEqual([],events);result=self.stored_summary(runner)
        self.assertEqual('EVIDENCE_WRITE_FAILED',result['primaryFailure']['code'])
        self.assertFalse(result['attempts'][0]['transportStarted']);self.assertFalse(result['attempts'][0]['attemptRecorded'])
        self.assertEqual('NOT_ATTEMPTED',result['conservation']['final']['status'])

    def test_24_post_transport_evidence_failure_stops_phases_but_persists_readonly_cleanup(self):
        runner,events=self.fake_run();end=runner.evidence.end
        def write(metadata,value):
            if metadata['stage']=='phaseinvoke':raise OSError('secret log failure')
            return end(metadata,value)
        with patch.object(runner.evidence,'end',side_effect=write):
            with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        result=self.stored_summary(runner)
        self.assertEqual(['baseline','baseline','sequence_human_adm','baseline','baseline'],events)
        self.assertEqual('EVIDENCE_WRITE_FAILED',result['primaryFailure']['code'])
        self.assertEqual([],result['checks']);self.assertTrue(result['conservation']['postbaseline'][0]['matchesInitial'])
        self.assertTrue(result['conservation']['final']['matchesInitial'])
        for order,stage in [(4,'postbaseline'),(5,'finalbaseline')]:
            stored=json.loads((runner.evidence.path/f'{order:04}-result.json').read_text())
            self.assertEqual(stage,stored['stage']);self.assertEqual('VALID',stored['validation'])

    def test_25_failed_phase_attempt_write_never_starts_mutation(self):
        runner,events=self.fake_run();begin=runner.evidence.begin
        def write(metadata,sql):
            if metadata['stage']=='phaseinvoke':raise OSError('cannot persist mutation attempt')
            return begin(metadata,sql)
        with patch.object(runner.evidence,'begin',side_effect=write):
            with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        result=self.stored_summary(runner)
        self.assertEqual(['baseline']*4,events)
        self.assertFalse(result['attempts'][2]['transportStarted']);self.assertEqual('NOT_TRANSPORTED',result['attempts'][2]['outcome'])
        self.assertTrue(result['conservation']['final']['matchesInitial'])

    def test_26_permanent_evidence_failure_after_transport_still_attempts_cleanup(self):
        runner,events=self.fake_run();begin=runner.evidence.begin;end=runner.evidence.end;broken=False
        def write_begin(metadata,sql):
            if broken:raise OSError('disk offline')
            return begin(metadata,sql)
        def write_end(metadata,value):
            nonlocal broken
            if metadata['stage']=='phaseinvoke':broken=True
            if broken:raise OSError('disk offline')
            return end(metadata,value)
        with patch.object(runner.evidence,'begin',side_effect=write_begin),patch.object(runner.evidence,'end',side_effect=write_end),patch.object(runner.evidence,'finish',side_effect=OSError('disk offline')):
            with self.assertRaises(M.RunFailure) as caught:runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        result=caught.exception.report
        self.assertEqual(['baseline','baseline','sequence_human_adm','baseline','baseline'],events)
        self.assertFalse(result['evidence']['summaryWritten']);self.assertEqual('FAIL',result['status'])
        self.assertTrue(result['conservation']['final']['matchesInitial'])
        self.assertTrue((runner.evidence.path/'0003-attempt.json').is_file())
        self.assertFalse((runner.evidence.path/'summary.json').exists())

    def test_27_existing_escape_unc_and_reparse_evidence_paths_rejected(self):
        existing=self.new_evidence();manifest=(existing.path/'run.json').read_bytes()
        with self.assertRaisesRegex(M.Failure,'EVIDENCE_ALREADY_EXISTS'):M.Evidence(existing.path,ROOT)
        self.assertEqual(manifest,(existing.path/'run.json').read_bytes())
        for path in [Path(os.environ['TEMP'])/'..'/'C1P2R1-escape',ROOT/'scripts'/'C1P2R1-outside',Path(r'\\server\share\C1P2R1-remote'),Path('C1P2R1-relative'),Path(os.environ['TEMP'])/'unowned-name']:
            with self.subTest(path=path),self.assertRaises(M.Failure):M.Evidence(path,ROOT)
        with patch.object(Path,'is_symlink',return_value=True):
            with self.assertRaisesRegex(M.Failure,'EVIDENCE_LOCATION_INVALID'):self.new_evidence()
        with patch.object(Path,'is_symlink',return_value=False),patch.object(Path,'stat',return_value=Mock(st_file_attributes=1024)):
            with self.assertRaisesRegex(M.Failure,'EVIDENCE_LOCATION_INVALID'):M.Evidence._plain(Path('fictional'))

    def test_28_arbitrary_native_buffers_exception_and_server_canary_are_never_logged(self):
        canary=b'PRIVATE_ROW_PASSWORD_TOKEN_CANARY_012345'
        runner,events=self.fake_run();invoke=runner.transport.invoke
        def native(sql):
            if 'C1P2_RESULT' in sql:
                return subprocess.CompletedProcess([],16,canary,b'Msg 51000, Level 16, State 1, Server '+canary+b', Line 12\r\n'+canary)
            return invoke(sql)
        runner.transport.invoke=native
        with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm'])
        for path in runner.evidence.path.iterdir():
            if path.is_file():self.assertNotIn(canary,path.read_bytes())
        stored=json.loads((runner.evidence.path/'0003-result.json').read_text())
        self.assertEqual([{'msg':51000,'level':16,'state':1,'line':12}],stored['transport']['nativeHeaders'])
        self.assertEqual(M.digest(canary),stored['transport']['stdout']['sha256']);self.assertIsNone(stored['validatedFrame'])
        for error in [RuntimeError(canary.decode()),M.Failure(canary.decode())]:
            runner,events=self.fake_run(failure=error)
            with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm'])
            stored=self.stored_summary(runner);self.assertEqual('CONTROLLER_FAILED',stored['primaryFailure']['code'])
            self.assertNotIn(canary,(runner.evidence.path/'summary.json').read_bytes())

    def test_29_attempt_and_controlled_sql_are_durable_before_each_invoke(self):
        runner,events=self.fake_run();invoke=runner.transport.invoke;order=0
        def inspect(sql):
            nonlocal order
            order+=1
            attempt=json.loads((runner.evidence.path/f'{order:04}-attempt.json').read_text())
            self.assertEqual(M.digest(sql.encode('utf-8')),attempt['sqlSha256'])
            self.assertEqual(sql.encode('utf-8'),(runner.evidence.path/attempt['sql']['file']).read_bytes())
            self.assertFalse((runner.evidence.path/f'{order:04}-result.json').exists())
            journal=(runner.evidence.path/'journal.jsonl').read_text().splitlines()
            self.assertEqual('ATTEMPT',json.loads(journal[-1])['event'])
            return invoke(sql)
        runner.transport.invoke=inspect
        result=runner.execute(M.MODE,['sequence_human_adm'])
        self.assertEqual('PASS',self.stored_summary(runner)['status']);self.assertEqual(5,order)
        self.assertEqual('COMPLETE',result['checksStatus'])

    def test_30_summary_write_failure_cannot_return_pass(self):
        runner,events=self.fake_run()
        with patch.object(runner.evidence,'finish',side_effect=OSError('private canary')):
            with self.assertRaises(M.RunFailure) as caught:runner.execute(M.MODE,['sequence_human_adm'])
        result=caught.exception.report
        self.assertEqual('EVIDENCE_WRITE_FAILED',result['primaryFailure']['code'])
        self.assertEqual('FAIL',result['status']);self.assertEqual('PARTIAL',result['checksStatus'])
        self.assertEqual(1,len(result['checks']));self.assertFalse(result['evidence']['summaryWritten'])
        self.assertTrue(result['restored']);self.assertEqual(5,len(events))

    def test_31_postbaseline_failure_does_not_accept_candidate_check(self):
        runner,events=self.fake_run(baseline_failure_at=3)
        with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        result=self.stored_summary(runner)
        self.assertEqual('postbaseline',result['primaryFailure']['stage']);self.assertEqual([],result['checks'])
        self.assertEqual('VALID',json.loads((runner.evidence.path/'0003-result.json').read_text())['validation'])
        self.assertTrue(result['conservation']['final']['matchesInitial']);self.assertNotIn('revision_exponent',events)

    def test_32_prephase_drift_and_run_reuse_are_closed(self):
        runner,events=self.fake_run(drift=2)
        with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm'])
        result=self.stored_summary(runner)
        self.assertEqual('prephase',result['primaryFailure']['stage']);self.assertEqual(['baseline']*3,events)
        prior=(runner.evidence.path/'summary.json').read_bytes()
        with self.assertRaisesRegex(M.Failure,'EVIDENCE_REUSED'):runner.execute(M.MODE,['sequence_human_adm'])
        self.assertEqual(prior,(runner.evidence.path/'summary.json').read_bytes());self.assertEqual(3,len(events))

    def test_33_summary_fsync_failure_never_publishes_a_success_summary(self):
        runner,events=self.fake_run();write=runner.evidence._write
        def persist(name,value):
            if name=='summary.json':
                with patch.object(M.os,'fsync',side_effect=OSError('disk canary')):return write(name,value)
            return write(name,value)
        with patch.object(runner.evidence,'_write',side_effect=persist):
            with self.assertRaises(M.RunFailure) as caught:runner.execute(M.MODE,['sequence_human_adm'])
        self.assertEqual('FAIL',caught.exception.report['status']);self.assertFalse(caught.exception.report['evidence']['summaryWritten'])
        self.assertFalse((runner.evidence.path/'summary.json').exists())
        self.assertTrue((runner.evidence.path/'summary.json.pending').exists())
        self.assertEqual(5,len(events))

    def test_34_durable_record_is_create_only_and_import_creates_nothing(self):
        evidence=self.new_evidence();evidence._write('fictional.json',{'marker':'first'})
        prior=(evidence.path/'fictional.json').read_bytes()
        with self.assertRaises(FileExistsError):evidence._write('fictional.json',{'marker':'second'})
        self.assertEqual(prior,(evidence.path/'fictional.json').read_bytes())
        # Re-import in isolation while all creation/process entrypoints are
        # blocked. Merely loading/generating the module cannot create evidence.
        spec=importlib.util.spec_from_file_location('c1p2r1_import_only',ROOT/M.DRIVER)
        value=importlib.util.module_from_spec(spec);sys.modules[spec.name]=value
        with patch.object(Path,'mkdir',side_effect=AssertionError('import created directory')),patch.object(subprocess,'run',side_effect=AssertionError('import launched process')):
            spec.loader.exec_module(value)
            self.assertEqual(M.baseline_sql(self.bundle,N),value.baseline_sql(self.bundle,N))

    def test_35_timeout_partial_buffers_are_hash_only_and_keep_concrete_code(self):
        canary=b'PRIVATE_TIMEOUT_ROW_CANARY_987654'
        stderr=b'Msg 3998, Level 16, State 1, Line 77\r\n'+canary
        run=Mock(side_effect=subprocess.TimeoutExpired('fake',300,output=canary,stderr=stderr))
        transport=M.Transport(environ={},run=run,resolve=lambda:str(M.SQLCMD))
        with self.assertRaises(M.TransportFailure) as caught:transport.invoke(':On Error exit\nSELECT1;')
        self.assertEqual('TRANSPORT_TIMEOUT',str(caught.exception));self.assertEqual(1,run.call_count)
        self.assertNotIn(canary,json.dumps(caught.exception.output_metadata).encode())
        runner,events=self.fake_run(failure=caught.exception,failure_phase='revision_exponent')
        with self.assertRaises(M.RunFailure):runner.execute(M.MODE,['sequence_human_adm','revision_exponent'])
        stored=json.loads((runner.evidence.path/'0006-result.json').read_text())
        self.assertEqual({'bytes':len(canary),'sha256':M.digest(canary)},stored['transport']['stdout'])
        self.assertEqual({'bytes':len(stderr),'sha256':M.digest(stderr)},stored['transport']['stderr'])
        self.assertIsNone(stored['transport']['returncode'])
        self.assertEqual('TRANSPORT_TIMEOUT',self.stored_summary(runner)['primaryFailure']['code'])
        self.assertEqual(1,len(self.stored_summary(runner)['checks']))


if __name__=='__main__':unittest.main()
