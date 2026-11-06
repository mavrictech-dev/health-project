"""Offline protocol/state tests; never execute SQL against an engine."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location('isolated_provision', Path(__file__).resolve().parents[1] / 'provision-isolated-sqlserver-qa.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


def frame(data, phase):
    raw = M.compact({'phase': phase, 'data': data}).encode('utf-16le')
    return '\n'.join('A66JSON:' + raw[i:i+2000].hex().upper() for i in range(0,len(raw),2000)) + '\nA66END:' + M.digest(raw) + '\n'


class SqlModel:
    """Models wrapper gates/transaction phases, not SQL Server permissions/DDL."""
    def __init__(self, art, directory, fault=None):
        self.art, self.directory, self.fault = art, directory, fault
        self.calls, self.raw_exits = [], []
        self.exists, self.marker, self.commits = False, False, 0
        self.marker_value = M.MARKER
        self.instance = 'HEALTHPROJECTQA'
        self.actual = copy.deepcopy(art.expected)
        self.events = []

    def run(self, database, sql, phase, mutation=False):
        self.calls.append(phase)
        self.raw_exits.append({'phase': phase, 'raw_exit_code': 0})
        text = sql.decode() if isinstance(sql, bytes) else sql
        if self.instance != 'HEALTHPROJECTQA':
            raise M.ProvisionError('SQLCMD_FAILED')
        if phase == 'plan':
            assert database == 'master' and not mutation
            assert 'sys.server_principals' in text and 'DB_ID(' in text
            return {'instanceName':self.instance,'databaseName':M.DATABASE,'databaseExists':int(self.exists),'canCreate':1}
        if phase == 'created':
            journal = json.loads(max(self.directory.glob('*/journal.json'),key=lambda p:p.stat().st_mtime_ns).read_text())
            assert journal['sql_action'] == 'create_outcome_unverified'
            assert database == 'master' and mutation and 'BEGIN TRAN' not in text
            assert M.DATA_FILE in text and M.LOG_FILE in text and 'IS NOT NULL THROW' in text
            assert not self.exists
            self.exists = True
            self.events.append('create')
            if self.fault == 'create':
                raise M.ProvisionError('SQLCMD_TIMEOUT')
            return {'created':1}
        assert database == M.DATABASE and self.exists
        if phase == 'marked':
            assert not self.marker and 'WITHOUT LOGIN' in text and 'GRANT CONTROL ON DATABASE::['+M.DATABASE+']' in text
            assert M.MARKER in text and 'CREATE LOGIN' not in text
            if self.fault == 'mark':
                raise M.ProvisionError('SQLCMD_FAILED')
            self.marker = True
            if self.fault in ('wrong_marker','missing_marker'):
                self.marker_value = 'wrong' if self.fault == 'wrong_marker' else None
            return {'marked':1}
        assert self.marker
        assert 'health_project_scope' in text and M.MARKER in text
        if self.marker_value != M.MARKER:
            raise M.ProvisionError('SQLCMD_FAILED')
        if phase == 'commit_acknowledged':
            # Interpret the actual transport wrapper, preserving source batches.
            begin = text.index('BEGIN TRAN;')
            impersonate = text.index("EXECUTE AS USER=N'"+M.MIGRATOR+"'")
            revert = text.index('REVERT;',impersonate)
            check = text.index('IF @a66_catalog COLLATE',revert)
            commit = text.index('COMMIT;',check)
            assert text.index(M.MARKER) < begin < impersonate < revert < check < commit
            position = impersonate
            for name,_ in M.PINS:
                source = self.art.blobs[name].decode()
                found = text.index(source,position)
                assert position < found < revert
                position = found + len(source)
            assert '@@TRANCOUNT<>1 OR XACT_STATE()<>1' in text[revert:check]
            assert "HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL')" in text[:position]
            self.events += ['begin','execute_as_migrator','V1..V9','revert','postconditions']
            # Read the expected postconditions from the wrapper being executed,
            # then evaluate them against model state before allowing COMMIT.
            literal = re.search(r"IF @a66_catalog COLLATE Latin1_General_100_BIN2<>N'((?:[^']|'')*)'",text[check:commit]).group(1)
            expected = json.loads(literal.replace("''","'"))
            if self.fault == 'acl':
                self.actual['acl'][0]['state'] = 'W'
            if self.fault == 'migrate' or self.actual != expected:
                self.events.append('rollback_on_close')
                raise M.ProvisionError('SQLCMD_FAILED')
            self.commits += 1
            self.events.append('commit')
            if self.fault == 'ack':
                raise M.ProvisionError('RESPONSE_INVALID')
            return copy.deepcopy(self.actual)
        assert phase == 'verified' and not mutation
        self.events.append('fresh_verify')
        if self.fault == 'fresh':
            raise M.ProvisionError('SQLCMD_TIMEOUT')
        if self.fault == 'wrong_fresh':
            result = copy.deepcopy(self.actual)
            result['counts']['users'] = 1
            return result
        return copy.deepcopy(self.actual)


class IsolatedProvisionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.art = M.Artifacts.load()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.model = SqlModel(self.art,self.directory)

    def execute(self,args=None,**kwargs):
        return M.execute([] if args is None else args,transport=self.model,loader=lambda:self.art,
                         path_check=lambda:None,env={},directory=self.directory,**kwargs)

    def test_pinned_artifacts_exact_acl_definitions_and_full_seed_values(self):
        self.assertEqual(len(self.art.modules),164)
        self.assertEqual(len(self.art.acl),562)
        self.assertEqual(len(self.art.seeds['specialties']),241)
        self.assertEqual(self.art.expected['counts']['users'],0)
        self.assertEqual(self.art.expected['counts']['auth_sessions'],0)
        self.assertEqual(len(self.art.seeds['workflow_definitions']),15)
        self.assertEqual(len(self.art.seeds['specialties'][0]),5)
        self.assertIn('CONVERT(bigint,86400000000)',self.art.blobs[M.PINS[-1][0]].decode())
        modified=dict(self.art.blobs)
        modified[M.PINS[0][0]] += b'-- drift'
        with self.assertRaisesRegex(M.ProvisionError,'ARTIFACT_HASH'):
            M.Artifacts(modified)
        crlf={key:value.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n') for key,value in self.art.blobs.items()}
        self.assertEqual(M.Artifacts(crlf).expected,self.art.expected)

    def test_plan_has_no_writes_and_existing_database_is_blocked(self):
        result=self.execute()
        self.assertEqual((result['status'],self.model.calls),('planned',['plan']))
        self.assertFalse(result['jdbc_positive_validated'])
        self.assertFalse(self.model.exists)
        self.model.exists=True
        result=self.execute()
        self.assertEqual((result['status'],result['code']),('blocked','DATABASE_EXISTS'))
        self.assertEqual(self.model.events,[])

    def test_unknown_unconfirmed_or_alternate_flags_never_reach_sql(self):
        for argv in [['apply'],['create'],['create','--confirm-isolated-qa','--host','elsewhere'],['--database',M.DATABASE],['plan','extra']]:
            with self.subTest(argv=argv):
                self.assertEqual(self.execute(argv)['code'],'COMMAND_INVALID')
        self.assertEqual(self.model.calls,[])

    def test_hostile_environment_and_hash_drift_precede_every_query(self):
        for key in ['SQLCMDINI','SQLCMDPASSWORD','sqlcmdserver']:
            result=M.execute([],transport=self.model,loader=lambda:self.art,env={key:'CANARY_SECRET'},directory=self.directory)
            self.assertEqual(result['code'],'HOSTILE_ENVIRONMENT')
            self.assertNotIn('CANARY',json.dumps(result))
        def bad_loader():
            raise M.ProvisionError('ARTIFACT_HASH')
        result=M.execute(['create','--confirm-isolated-qa'],transport=self.model,loader=bad_loader,env={},directory=self.directory)
        self.assertEqual(result['code'],'ARTIFACT_HASH')
        self.assertEqual(self.model.calls,[])

    def test_wrong_instance_database_and_metadata_types_fail_before_writes(self):
        self.model.instance='MSSQLSERVER'
        self.assertEqual(self.execute()['code'],'SQLCMD_FAILED')
        for change in [{'databaseName':'other'},{'instanceName':'other'},{'databaseExists':True},{'canCreate':None}]:
            with patch.object(self.model,'run',return_value={'instanceName':'HEALTHPROJECTQA','databaseName':M.DATABASE,'databaseExists':0,'canCreate':1,**change}):
                self.assertEqual(self.execute(['create','--confirm-isolated-qa'])['code'],'METADATA_INVALID')
        self.assertEqual(self.model.events,[])

    def test_path_failure_precedes_nontransactional_create(self):
        def unsafe():
            raise M.ProvisionError('PATH_UNSAFE')
        result=M.execute(['create','--confirm-isolated-qa'],transport=self.model,loader=lambda:self.art,path_check=unsafe,env={},directory=self.directory)
        self.assertEqual(result['code'],'PATH_UNSAFE')
        self.assertEqual(self.model.calls,['plan'])
        self.assertFalse(self.model.exists)

    def test_real_path_guard_rejects_reparse_and_existing_files(self):
        import stat
        with patch.object(M.Path,'lstat',return_value=SimpleNamespace(st_mode=stat.S_IFDIR,st_file_attributes=stat.FILE_ATTRIBUTE_REPARSE_POINT)):
            with self.assertRaisesRegex(M.ProvisionError,'PATH_UNSAFE'):
                M.check_paths()
        with patch.object(M.Path,'lstat',return_value=SimpleNamespace(st_mode=stat.S_IFDIR,st_file_attributes=0)),patch.object(M.Path,'is_symlink',return_value=False),patch.object(M.os.path,'lexists',return_value=True):
            with self.assertRaisesRegex(M.ProvisionError,'FILE_COLLISION'):
                M.check_paths()

    def test_wrong_or_missing_marker_blocks_migration_before_transaction(self):
        for fault in ('wrong_marker','missing_marker'):
            self.model=SqlModel(self.art,self.directory,fault)
            result=self.execute(['create','--confirm-isolated-qa'])
            self.assertEqual(result['status'],'error')
            self.assertNotIn('begin',self.model.events)
            self.assertEqual(self.model.commits,0)
            self.assertTrue(result['reconciliation_required'])

    def test_create_model_executes_wrapper_transaction_guards_before_commit(self):
        result=self.execute(['create','--confirm-isolated-qa'])
        self.assertEqual((result['status'],result['sql_action']),('configured','commit_verified'))
        self.assertEqual(self.model.calls,['plan','created','marked','commit_acknowledged','verified'])
        self.assertEqual(self.model.events,['create','begin','execute_as_migrator','V1..V9','revert','postconditions','commit','fresh_verify'])
        self.assertEqual(self.model.commits,1)
        self.assertFalse(result['reconciliation_required'])

    def test_equal_count_wrong_acl_state_aborts_before_commit(self):
        self.model.fault='acl'
        result=self.execute(['create','--confirm-isolated-qa'])
        self.assertEqual(result['status'],'error')
        self.assertEqual(self.model.commits,0)
        self.assertIn('rollback_on_close',self.model.events)
        self.assertNotIn('verified',self.model.calls)
        self.assertTrue(result['reconciliation_required'])

    def test_failure_between_create_marker_and_migrate_never_retries_or_deletes(self):
        for fault,last in [('create','created'),('mark','marked'),('migrate','commit_acknowledged')]:
            with self.subTest(fault=fault):
                self.model=SqlModel(self.art,self.directory,fault)
                result=self.execute(['create','--confirm-isolated-qa'])
                self.assertEqual(result['status'],'error')
                self.assertEqual(self.model.calls[-1],last)
                self.assertTrue(self.model.exists)
                self.assertTrue(result['reconciliation_required'])
                self.assertFalse(result['retry_mutation'])
                self.assertEqual(self.model.calls.count('created'),1)
                self.assertEqual(self.model.commits,0)

    def test_missing_ack_and_postcommit_failure_have_distinct_unverified_states(self):
        for fault,action in [('ack','migration_outcome_unverified'),('fresh','commit_acknowledged'),('wrong_fresh','commit_acknowledged')]:
            with self.subTest(fault=fault):
                self.model=SqlModel(self.art,self.directory,fault)
                result=self.execute(['create','--confirm-isolated-qa'])
                self.assertEqual((result['status'],result['sql_action']),('error',action))
                self.assertTrue(result['reconciliation_required'])
                self.assertFalse(result['retry_mutation'])
                self.assertEqual(self.model.commits,1)
                self.assertIn('Do not repeat',result['message'])

    def test_verify_is_fresh_and_marker_guard_precedes_all_new_database_reads(self):
        self.model.exists=self.model.marker=True
        result=self.execute(['verify'])
        self.assertEqual((result['status'],self.model.calls),('verified',['plan','verified']))
        sql=M.verify_sql(self.art)
        self.assertLess(sql.index('health_project_scope'),sql.index('FROM dbo.['))
        self.assertIn('DATALENGTH(CONVERT(nvarchar(4000),value))',sql)
        self.assertIn("COLLATE Latin1_General_100_BIN2",sql)
        self.assertNotIn('CREATE DATABASE',sql)
        self.assertFalse(result['jdbc_positive_validated'])

    def test_boolean_cannot_impersonate_numeric_catalog_or_create_ack(self):
        original=self.model.run
        def bad_ack(database,sql,phase,mutation=False):
            value=original(database,sql,phase,mutation)
            return {'created':True} if phase=='created' else value
        with patch.object(self.model,'run',side_effect=bad_ack):
            result=self.execute(['create','--confirm-isolated-qa'])
        self.assertEqual(result['code'],'CREATE_ACK_INVALID')
        self.assertNotIn('marked',self.model.calls)
        self.model=SqlModel(self.art,self.directory)
        self.model.exists=self.model.marker=True
        self.model.actual['counts']['users']=False
        self.assertEqual(self.execute(['verify'])['code'],'VERIFICATION_FAILED')

    def test_journal_failure_stops_before_create_without_raw_exception(self):
        with patch.object(M.os,'fsync',side_effect=OSError('CANARY_PRIVATE')):
            result=self.execute(['create','--confirm-isolated-qa'])
        self.assertEqual((result['code'],self.model.calls),('JOURNAL_FAILED',['plan']))
        self.assertNotIn('CANARY',json.dumps(result))

    def test_framing_duplicates_missing_chunks_wrong_phase_never_acknowledge(self):
        valid=frame({'x':1},'verified')
        self.assertEqual(M.parse_response(valid,'verified'),{'x':1})
        for value in ['',valid[:-3],valid.replace('A66JSON:','X:'),frame({'x':1},'created')]:
            with self.assertRaises(M.ProvisionError):
                M.parse_response(value,'verified')
        with self.assertRaises(M.ProvisionError):
            M.unique([('x',1),('x',2)])

    def test_production_frame_max_type_and_unicode_multichunk_checksum(self):
        sql=M.framed('synthetic_probe','@synthetic')
        self.assertIn("SELECT CAST(N'A66JSON:' AS nvarchar(max))+CONVERT(varchar(4000)",sql)
        self.assertIn('@a66_offset,2000),2)',sql)
        self.assertIn('SET @a66_offset+=2000',sql)
        payload={'text':('synthetic \\ / \" é 漢字 🐳\n'*500),'nullable':None,'number':123456789}
        emitted=frame(payload,'synthetic_probe')
        lines=emitted.splitlines()
        self.assertGreater(len(lines),3)
        self.assertTrue(all(len(line)==4008 for line in lines[:-2]))
        self.assertEqual(M.parse_response(emitted,'synthetic_probe'),payload)
        # Reproduce the actual old SQL concatenation ceiling, rather than
        # silently trusting the unlimited Python frame generator.
        clipped='\n'.join(line[:4000] if line.startswith('A66JSON:') else line for line in lines)+'\n'
        with self.assertRaisesRegex(M.ProvisionError,'RESPONSE_INVALID'):
            M.parse_response(clipped,'synthetic_probe')
        altered=list(lines)
        altered[1]=altered[1][:-2]+('00' if altered[1][-2:]!='00' else '01')
        with self.assertRaisesRegex(M.ProvisionError,'RESPONSE_INVALID'):
            M.parse_response('\n'.join(altered),'synthetic_probe')

    def test_transport_effective_argv_sanitized_environment_and_stderr(self):
        transport=M.Transport(M.environment({'PATH':'synthetic','SQL_PASSWORD':'CANARY'}),self.directory)
        good=subprocess.CompletedProcess([],0,frame({'x':1},'verified'),'')
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=good) as run:
            self.assertEqual(transport.run(M.DATABASE,'SELECT fixed','verified'),{'x':1})
            argv=run.call_args.args[0]
            self.assertEqual(argv[argv.index('-S')+1],r'lpc:.\HEALTHPROJECTQA')
            self.assertEqual(argv[argv.index('-d')+1],M.DATABASE)
            self.assertNotIn('-h',argv)
            self.assertIn('-X1',argv)
            self.assertIn('-x',argv)
            self.assertEqual(run.call_args.kwargs['timeout'],20)
            self.assertNotIn('SQL_PASSWORD',run.call_args.kwargs['env'])
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=subprocess.CompletedProcess([],0,frame({'created':1},'created'),' \r\n')) as run:
            self.assertEqual(transport.run('master','CREATE fixed','created',True),{'created':1})
            argv=run.call_args.args[0]
            self.assertEqual(argv[argv.index('-t')+1],'60')
            self.assertEqual(argv[argv.index('-l')+1],'5')
            self.assertEqual(run.call_args.kwargs['timeout'],75)
        for index,(code,stderr,expected) in enumerate([(0,'Timeout expired\r\n','SQLCMD_TIMEOUT'),(1,'timeout expired','SQLCMD_TIMEOUT'),(0,'CANARY_PRIVATE','SQLCMD_FAILED'),(1,'','SQLCMD_FAILED')]):
            with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=subprocess.CompletedProcess([],code,good.stdout,stderr)):
                with self.assertRaisesRegex(M.ProvisionError,expected) as error:
                    transport.run('master','SELECT fixed','phase'+str(index))
                self.assertNotIn('CANARY',str(error.exception))

    def test_transport_timeout_missing_executable_and_bad_output_are_safe(self):
        transport=M.Transport({},self.directory)
        with patch.object(M.shutil,'which',return_value=None):
            with self.assertRaisesRegex(M.ProvisionError,'SQLCMD_NOT_FOUND'):
                transport.run('master','SELECT fixed','missing')
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',side_effect=subprocess.TimeoutExpired('CANARY',20)):
            with self.assertRaisesRegex(M.ProvisionError,'SQLCMD_TIMEOUT'):
                transport.run('master','SELECT fixed','timeout')
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=subprocess.CompletedProcess([],0,'','')):
            with self.assertRaisesRegex(M.ProvisionError,'RESPONSE_INVALID'):
                transport.run('master','SELECT fixed','empty')


if __name__=='__main__':
    unittest.main()
