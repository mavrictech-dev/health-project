"""CPU/mocked SQL and DPAPI; no operational credentials/store/login mutation."""
import copy
import ctypes
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SPEC=importlib.util.spec_from_file_location('isolated_logins',Path(__file__).resolve().parents[1]/'provision-isolated-sqlserver-logins.py')
M=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(M)
CANARY='Aa9!SYNTHETIC_ONLY_NOT_A_REAL_PASSWORD_'+('q'*24)


def credentials():
    return M.Credentials({'version':1,'instance':'HEALTHPROJECTQA','database':M.A66.DATABASE,
                          'accounts':{name:{'role':role,'password':CANARY+str(i)} for i,(name,role) in enumerate(M.ACCOUNTS.items())}})


def snapshot(artifact,installed=False):
    return {'catalog':M.expected_catalog(artifact,installed),'metadata':M.expected_metadata(installed)}


def frame(value,phase):
    raw=M.A66.compact({'phase':phase,'data':value}).encode('utf-16le')
    return '\n'.join('A66JSON:'+raw[i:i+2000].hex().upper() for i in range(0,len(raw),2000))+'\nA66END:'+M.A66.digest(raw)+'\n'


class FakeDpapi:
    def __init__(self):
        self.value=None
        self.corrupt=False

    def protect(self,value):
        self.value=value
        return b'OPAQUE_TEST_CIPHERTEXT_NOT_A_REAL_SECRET'

    def unprotect(self,value):
        if self.corrupt or value!=b'OPAQUE_TEST_CIPHERTEXT_NOT_A_REAL_SECRET':
            raise M.SetupError('DPAPI_FAILED')
        return self.value


class ModelTransport:
    """Checks actual wrapper gates and ordering; not an engine permissions model."""
    def __init__(self,artifact,store):
        self.artifact,self.store=artifact,store
        self.value=snapshot(artifact)
        self.calls,self.raw_exits,self.events=[],[],[]
        self.fault=None
        self.commits=0

    def run(self,sql,phase):
        self.calls.append(phase)
        self.raw_exits.append({'phase':phase,'raw_exit_code':0})
        assert M.A66.literal(phase)+' phase,JSON_QUERY(' in sql
        if phase=='commit_acknowledged':
            assert self.store.saved and self.store.states[-1]['sql_action']=='mutation_outcome_unverified'
            assert sql.count('BEGIN TRAN;')==1 and sql.count('COMMIT;')==1
            begin=sql.index('BEGIN TRAN;'); first_create=sql.index('CREATE LOGIN')
            # Evaluate the actual JSON guards carried by the production wrapper.
            gates=list(re.finditer(r"IF @a66_catalog COLLATE Latin1_General_100_BIN2<>N'((?:[^']|'')*)' OR @a67_metadata COLLATE Latin1_General_100_BIN2<>N'((?:[^']|'')*)'",sql))
            assert len(gates)==2 and begin<gates[0].start()<first_create<gates[1].start()<sql.index('COMMIT;')
            expected_before={'catalog':json.loads(gates[0][1].replace("''","'")),'metadata':json.loads(gates[0][2].replace("''","'"))}
            if M.A66.compact(self.value)!=M.A66.compact(expected_before):
                raise M.SetupError('SQLCMD_FAILED')
            assert sql.count('CREATE LOGIN [')==2 and sql.count('CREATE USER [')==2 and sql.count('ALTER ROLE [')==2
            assert 'CHECK_POLICY=ON,CHECK_EXPIRATION=OFF' in sql and 'WITH DEFAULT_SCHEMA=[dbo]' in sql
            assert 'ALTER LOGIN' not in sql and 'DROP LOGIN' not in sql and 'GRANT CONTROL' not in sql
            self.events += ['begin','guard','create2logins','create2users','memberships2','postconditions']
            actual=snapshot(self.artifact,True)
            if self.fault=='delta':
                actual['metadata']['users'][0]['memberships'].append({'role':'db_owner'})
            expected_after={'catalog':json.loads(gates[1][1].replace("''","'")),'metadata':json.loads(gates[1][2].replace("''","'"))}
            if M.A66.compact(actual)!=M.A66.compact(expected_after):
                self.events.append('rollback_on_close')
                raise M.SetupError('SQLCMD_FAILED')
            assert '@@TRANCOUNT<>1 OR XACT_STATE()<>1' in sql[gates[1].end():sql.index('COMMIT;')]
            self.value=actual;self.commits+=1;self.events.append('commit')
            if self.fault=='ack':
                raise M.SetupError('RESPONSE_INVALID')
        elif phase=='inspect_fresh':
            self.events.append('fresh')
            if self.fault=='fresh':
                raise M.SetupError('SQLCMD_TIMEOUT')
        return copy.deepcopy(self.value)


class ModelStore:
    def __init__(self):
        self.saved=False;self.states=[];self.closed=False;self.fault=None

    def reserve(self):
        if self.fault=='collision':
            raise M.SetupError('STORE_COLLISION')

    def save(self,value):
        if self.fault=='dpapi':
            raise M.SetupError('DPAPI_FAILED')
        self.saved=True

    def journal(self,value):
        if self.fault=='journal':
            raise M.SetupError('JOURNAL_FAILED')
        self.states.append(copy.deepcopy(value))

    def load(self):
        return credentials()

    def close(self):
        self.closed=True


class IsolatedLoginTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.artifact=M.A66.Artifacts.load()

    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.path=Path(self.temp.name)
        self.store=ModelStore();self.transport=ModelTransport(self.artifact,self.store)

    def execute(self,args=None):
        return M.execute([] if args is None else args,transport=self.transport,store=self.store,generator=credentials,
                         loader=lambda:self.artifact,env={},directory=self.path/'evidence')

    def assert_no_canary(self,value):
        self.assertFalse(CANARY in str(value))

    def test_plan_absent_installed_partial_and_never_loads_store_or_generates(self):
        with patch.object(M.CredentialStore,'load',side_effect=AssertionError('MUST_NOT_READ_STORE')):
            self.assertEqual(self.execute()['resources'],'absent')
            self.transport.value=snapshot(self.artifact,True)
            self.assertEqual(self.execute()['resources'],'installed')
            self.transport.value['metadata']['users'].pop()
            self.assertEqual((self.execute()['status'],self.execute()['resources']),('blocked','partial'))
        self.assertEqual(self.store.states,[])
        self.assertFalse(self.store.saved)
        self.assertNotIn('commit_acknowledged',self.transport.calls)

    def test_empty_sql_arrays_are_coalesced_by_producer_not_defaulted_by_parser(self):
        sql=M.snapshot_sql(self.artifact)
        for alias in ['logins','users','memberships']:
            self.assertIn(",N'[]')) "+alias,sql)
        self.assertIn('JSON_QUERY(COALESCE((SELECT s.name',sql)
        self.assertIn('JSON_QUERY(COALESCE((SELECT u.name',sql)
        self.assertIn('JSON_QUERY(COALESCE((SELECT r.name role',sql)
        # Exact structure observed from the authorized real diagnostic. None
        # must still fail: only SQL generation is corrected to emit JSON [].
        observed=snapshot(self.artifact)
        observed['metadata']['logins']=None;observed['metadata']['users']=None
        with self.assertRaisesRegex(M.SetupError,'SNAPSHOT_INVALID'):
            M.resource_state(observed,self.artifact)
        self.assertEqual(M.resource_state(snapshot(self.artifact),self.artifact),'absent')

    def test_fresh_inspection_frame_phase_matches_actual_parser_contract(self):
        for phase in ['inspect','inspect_fresh']:
            sql=M.inspect_sql(self.artifact,phase)
            self.assertIn(M.A66.literal(phase)+' phase,JSON_QUERY(',sql)
            self.assertEqual(M.A66.parse_response(frame(snapshot(self.artifact,True),phase),phase),snapshot(self.artifact,True))
        with self.assertRaisesRegex(M.SetupError,'PHASE_INVALID'):M.inspect_sql(self.artifact,'other')

    def test_no_create_on_collisions_catalog_drift_privilege_or_wrong_sid(self):
        for edit in [lambda s:s['metadata'].__setitem__('canAlterLogins',0),lambda s:s['catalog']['counts'].__setitem__('users',1)]:
            self.transport.value=snapshot(self.artifact);edit(self.transport.value)
            self.assertIn(self.execute(['create','--confirm-isolated-logins'])['code'],('SETUP_AUTHORITY_REQUIRED','CATALOG_DRIFT'))
        for edit in [lambda s:s['metadata']['users'][0].__setitem__('sidMatch',0),lambda s:s['metadata']['logins'][0].__setitem__('serverRoles',1),lambda s:s['metadata']['users'][0]['memberships'].append({'role':'db_owner'}),lambda s:s['metadata'].__setitem__('publicDatabaseUnexpected',1)]:
            self.transport.value=snapshot(self.artifact,True);edit(self.transport.value)
            self.assertEqual(self.execute()['code'],'PRINCIPAL_CONFLICT')
        self.transport.value=snapshot(self.artifact,True)
        self.assertEqual(self.execute(['create','--confirm-isolated-logins'])['code'],'PRINCIPAL_COLLISION')
        self.assertFalse(self.store.saved)
        self.assertNotIn('commit_acknowledged',self.transport.calls)

    def test_bad_flags_hostile_env_and_hash_drift_stop_before_queries(self):
        for args in [['create'],['apply'],['--server','elsewhere'],['verify','extra']]:
            self.assertEqual(self.execute(args)['code'],'COMMAND_INVALID')
        for key in ['SQLCMDINI','SQLCMDPASSWORD','SQLCMDSERVER']:
            result=M.execute([],transport=self.transport,env={key:CANARY},directory=self.path)
            self.assertEqual(result['code'],'HOSTILE_ENVIRONMENT');self.assert_no_canary(result)
        def bad():
            raise M.A66.ProvisionError('ARTIFACT_HASH')
        self.assertEqual(M.execute([],transport=self.transport,loader=bad,env={},directory=self.path)['code'],'ARTIFACT_HASH')
        self.assertEqual(self.transport.calls,[])

    def test_create_order_real_wrapper_model_and_exact_delta(self):
        result=self.execute(['create','--confirm-isolated-logins'])
        self.assertEqual((result['status'],result['sql_action']),('configured','commit_verified'))
        self.assertEqual(self.transport.calls,['inspect','commit_acknowledged','inspect_fresh'])
        self.assertEqual(self.transport.commits,1)
        self.assertEqual(self.transport.events[-2:],['commit','fresh'])
        self.assertFalse(result['reconciliation_required']);self.assert_no_canary(result)
        self.assertEqual(self.artifact.expected['extraPrincipals'],0)
        self.assertEqual(self.transport.value['catalog']['extraPrincipals'],2)

    def test_failed_storage_never_reaches_mutation(self):
        for fault in ['collision','dpapi','journal']:
            self.store.fault=fault
            result=self.execute(['create','--confirm-isolated-logins'])
            self.assertNotIn('commit_acknowledged',self.transport.calls)
            self.assertEqual(result['sql_action'],'not_attempted')

    def test_failed_delta_blocks_commit_and_ack_fresh_failure_never_retries(self):
        for fault,action,commits in [('delta','mutation_outcome_unverified',0),('ack','mutation_outcome_unverified',1),('fresh','commit_acknowledged',1)]:
            self.store=ModelStore();self.transport=ModelTransport(self.artifact,self.store);self.transport.fault=fault
            result=self.execute(['create','--confirm-isolated-logins'])
            self.assertEqual((result['status'],result['sql_action']),('error',action))
            self.assertEqual(self.transport.commits,commits)
            self.assertTrue(result['reconciliation_required']);self.assertFalse(result['retry_mutation'])
            self.assertEqual(self.transport.calls.count('commit_acknowledged'),1)
            self.assertTrue(self.store.saved);self.assertTrue(self.store.closed)

    def test_verify_metadata_and_cipher_does_not_validate_password(self):
        self.transport.value=snapshot(self.artifact,True)
        result=self.execute(['verify'])
        self.assertEqual(result['status'],'verified')
        self.assertTrue(result['credential_store_verified'])
        self.assertFalse(result['password_authentication_validated']);self.assertFalse(result['jdbc_positive_validated'])
        self.assertEqual(self.transport.calls,['inspect'])

    def test_credential_schema_binding_types_distinctness_and_safe_repr(self):
        bundle=credentials()
        self.assert_no_canary(repr(bundle));self.assert_no_canary(str(bundle))
        self.assertEqual(M.Credentials.decode(bundle.encode()).encode(),bundle.encode())
        for key,value in [('version',True),('instance','MSSQLSERVER'),('database','other')]:
            payload=json.loads(bundle.encode());payload[key]=value
            with self.assertRaisesRegex(M.SetupError,'CREDENTIAL_SCHEMA'):
                M.Credentials(payload)
        payload=json.loads(bundle.encode());name=list(M.ACCOUNTS)[0]
        payload['accounts'][name]['role']='db_owner'
        with self.assertRaises(M.SetupError):M.Credentials(payload)
        payload=json.loads(bundle.encode());values=list(payload['accounts'].values());values[1]['password']=values[0]['password']
        with self.assertRaises(M.SetupError):M.Credentials(payload)
        with self.assertRaisesRegex(M.SetupError,'CREDENTIAL_SCHEMA') as error:M.Credentials.decode(CANARY.encode())
        self.assert_no_canary(error.exception)

    def test_cipher_store_exclusive_durable_roundtrip_and_no_plaintext_files(self):
        protector=FakeDpapi();store=M.CredentialStore(_test_root=self.path/'cipher',protector=protector)
        try:
            store.reserve();store.journal({'sql_action':'not_attempted'});store.save(credentials())
            self.assertEqual(store.load().encode(),credentials().encode())
            for path in store.root.iterdir():
                if path.name!='setup.lock':self.assertFalse(CANARY.encode() in path.read_bytes())
            with self.assertRaises(FileExistsError):store.save(credentials())
            protector.corrupt=True
            with self.assertRaisesRegex(M.SetupError,'DPAPI_FAILED'):store.load()
        finally:store.close()
        for path in store.root.iterdir():self.assertFalse(CANARY.encode() in path.read_bytes())
        with self.assertRaisesRegex(M.SetupError,'STORE_COLLISION'):M.CredentialStore(_test_root=store.root).reserve()
        self.assertTrue((store.root/'credentials.dpapi').exists())

    def test_reparse_fsync_lock_and_roundtrip_fail_before_sql(self):
        from types import SimpleNamespace
        with patch.object(M.Path,'lstat',return_value=SimpleNamespace(st_mode=stat.S_IFDIR,st_file_attributes=stat.FILE_ATTRIBUTE_REPARSE_POINT)):
            with self.assertRaisesRegex(M.SetupError,'STORE_REPARSE'):M.inspect_ancestors(self.path)
        store=M.CredentialStore(_test_root=self.path/'fsync')
        try:
            with patch.object(M.os,'fsync',side_effect=OSError('synthetic')):
                with self.assertRaises(OSError):store.reserve()
        finally:store.close()

        import msvcrt
        store=M.CredentialStore(_test_root=self.path/'lock')
        try:
            with patch.object(msvcrt,'locking',side_effect=OSError('synthetic')):
                with self.assertRaisesRegex(M.SetupError,'STORE_LOCK_FAILED'):store.reserve()
        finally:store.close()
        protector=FakeDpapi();store=M.CredentialStore(_test_root=self.path/'roundtrip',protector=protector)
        try:
            store.reserve()
            with patch.object(protector,'unprotect',return_value=b'wrong'):
                with self.assertRaisesRegex(M.SetupError,'DPAPI_ROUNDTRIP'):store.save(credentials())
            self.assertFalse((store.root/'credentials.dpapi').exists())
        finally:store.close()

    def test_dpapi_ctypes_signatures_current_user_flags_and_localfree_x64(self):
        class Function:
            def __init__(self,callback):self.callback=callback
            def __call__(self,*args):return self.callback(*args)
        from types import SimpleNamespace
        buffers=[];calls=[];freed=[]
        def operation(decrypt,*args):
            source,description,entropy,reserved,prompt,flags,out=args
            self.assertIsNone(description);self.assertIsNone(reserved);self.assertIsNone(prompt)
            self.assertEqual(flags,1) # UI_FORBIDDEN only; LOCAL_MACHINE=4 is absent
            extra=ctypes.cast(entropy,ctypes.POINTER(M.DataBlob)).contents
            self.assertEqual(ctypes.string_at(extra.pbData,extra.cbData),M.ENTROPY)
            body=credentials().encode() if decrypt else b'OPAQUE_FAKE_DPAPI'
            buffer=ctypes.create_string_buffer(body);buffers.append(buffer)
            output=ctypes.cast(out,ctypes.POINTER(M.DataBlob)).contents
            output.cbData=len(body);output.pbData=ctypes.cast(buffer,ctypes.POINTER(ctypes.c_ubyte))
            calls.append(decrypt)
            return 1
        crypt=SimpleNamespace(CryptProtectData=Function(lambda *args:operation(False,*args)),CryptUnprotectData=Function(lambda *args:operation(True,*args)))
        kernel=SimpleNamespace(LocalFree=Function(lambda pointer:freed.append(pointer.value)))
        with patch.object(M.ctypes,'WinDLL',side_effect=lambda name,**kwargs:crypt if name=='crypt32' else kernel):
            provider=M.Dpapi()
            cipher=provider.protect(credentials().encode())
            self.assertEqual(provider.unprotect(cipher),credentials().encode())
            self.assertEqual(ctypes.sizeof(M.DataBlob),16)
            self.assertEqual(M.DataBlob.pbData.offset,8)
            self.assertEqual(provider.kernel.LocalFree.argtypes,[ctypes.c_void_p])
            self.assertEqual(provider.kernel.LocalFree.restype,ctypes.c_void_p)
            self.assertEqual(len(provider.crypt.CryptProtectData.argtypes),7)
            self.assertEqual(len(freed),2);self.assertEqual(calls,[False,True])
            self.assertTrue(all(byte==0 for byte in buffers[-1].raw))
            crypt.CryptUnprotectData=Function(lambda *args:0)
            with self.assertRaisesRegex(M.SetupError,'DPAPI_FAILED'):provider.unprotect(b'corrupt')

    def test_generator_is_mocked_and_secrets_with_quotes_stay_escaped_in_memory(self):
        with patch.object(M.secrets,'token_urlsafe',side_effect=['SYNTHETICa'*7,'SYNTHETICb'*7]) as random:
            generated=M.generate_credentials()
            self.assertEqual(random.call_count,2)
            self.assertNotEqual(generated.password_for(list(M.ACCOUNTS)[0]),generated.password_for(list(M.ACCOUNTS)[1]))
        payload=json.loads(credentials().encode())
        first=list(M.ACCOUNTS)[0]
        payload['accounts'][first]['password']=CANARY+"'quote"
        sql=M.create_sql(self.artifact,M.Credentials(payload))
        self.assertIn("''quote'",sql)

    def test_secret_sql_only_stdin_and_no_plaintext_artifacts_or_errors(self):
        transport=M.Transport({'PATH':'synthetic'})
        sql=M.create_sql(self.artifact,credentials())
        good=subprocess.CompletedProcess([],0,'1> 2> '+frame(snapshot(self.artifact,True),'commit_acknowledged')+'1> ','')
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=good) as run:
            self.assertEqual(transport.run(sql,'commit_acknowledged'),snapshot(self.artifact,True))
            argv=run.call_args.args[0]
            self.assertFalse(any(CANARY in arg for arg in argv))
            for flag in ['-Q','-q','-P','-i','-e'] :self.assertNotIn(flag,argv)
            self.assertNotIn(CANARY,repr(run.call_args.kwargs['env']))
            self.assertIn(CANARY,run.call_args.kwargs['input'])
            self.assertTrue(run.call_args.kwargs['input'].endswith('\nGO\n:EXIT\n'))
            self.assertEqual(run.call_args.kwargs['timeout'],30)
            self.assertEqual(argv[argv.index('-S')+1],M.A66.SERVER)
        for raw,stderr,expected in [(0,'Timeout expired','SQLCMD_TIMEOUT'),(1,'Timeout expired','SQLCMD_TIMEOUT'),(0,CANARY,'SQLCMD_FAILED'),(1,'','SQLCMD_FAILED')]:
            with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=subprocess.CompletedProcess([],raw,CANARY,stderr)):
                with self.assertRaisesRegex(M.SetupError,expected) as error:transport.run(sql,'commit_acknowledged')
                self.assert_no_canary(error.exception)
        self.assertEqual(list(self.path.iterdir()),[])

    def test_context_notices_do_not_turn_valid_commit_into_unverified_outcome(self):
        transport=M.Transport({'PATH':'synthetic'})
        responses=[]
        def sqlcmd(argv,**kwargs):
            sql=kwargs['input']
            phase='commit_acknowledged' if "N'commit_acknowledged' phase" in sql else 'inspect_fresh'
            # ODBC behavior established by the readonly USE probe: severity0
            # context notices are emitted unless the message threshold is1.
            threshold=argv[argv.index('-m')+1] if '-m' in argv else '0'
            notices="Changed database context to 'master'.\n" if threshold=='0' else ''
            responses.append(phase)
            return subprocess.CompletedProcess(argv,0,frame(snapshot(self.artifact,True),phase),notices)
        with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',side_effect=sqlcmd):
            acknowledged=transport.run(M.create_sql(self.artifact,credentials()),'commit_acknowledged')
            fresh=transport.run(M.inspect_sql(self.artifact,'inspect_fresh'),'inspect_fresh')
        self.assertEqual(M.resource_state(acknowledged,self.artifact),'installed')
        self.assertEqual(M.resource_state(fresh,self.artifact),'installed')
        self.assertEqual(responses,['commit_acknowledged','inspect_fresh'])
        self.assertEqual(list(self.path.iterdir()),[])

    def test_prompt_normalization_never_accepts_unframed_or_corrupt_output(self):
        transport=M.Transport({})
        for stdout in [CANARY,'1> '+CANARY,frame({'x':1},'inspect')[:-5]]:
            with patch.object(M.shutil,'which',return_value='sqlcmd.exe'),patch.object(M.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stdout,'')):
                with self.assertRaises(M.A66.ProvisionError) as error:transport.run('SELECT fixed','inspect')
                self.assert_no_canary(error.exception)


if __name__=='__main__':unittest.main()
