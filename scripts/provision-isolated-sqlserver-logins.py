"""Closed QA login setup. Secrets stay in memory/stdin or DPAPI CurrentUser ciphertext."""
import copy
import ctypes
from ctypes import wintypes
import hmac
import importlib.util
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import stat
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('a67_a66_pure', ROOT / 'scripts/provision-isolated-sqlserver-qa.py')
A66 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(A66)
STORE = Path('D:/Mavric/Health Project/tmp/sqlserver-isolated-credentials')
TEMP = ROOT / 'tmp/sqlserver-a67-logins'
ACCOUNTS = {'hp_qa_bootstrap_20261105': 'hp_bootstrap_executor', 'hp_qa_runtime_20261105': 'hp_runtime_executor'}
BASE_FP = 'CBD9C3CE913BFB57D3E257C8CA225E4F959F31669A90414C570F74B0DD74E2AB'
ENTROPY = ('Health Project A67 CurrentUser v1|' + A66.DATABASE + '|' + A66.compact(ACCOUNTS)).encode('utf-8')


class SetupError(Exception):
    pass


def require(condition, code):
    if not condition:
        raise SetupError(code)


class Credentials:
    __slots__ = ('_payload',)

    def __init__(self, payload):
        expected = {'version', 'instance', 'database', 'accounts'}
        require(type(payload) is dict and set(payload) == expected and type(payload['version']) is int and payload['version'] == 1 and
                payload['instance'] == 'HEALTHPROJECTQA' and payload['database'] == A66.DATABASE and
                type(payload['accounts']) is dict and set(payload['accounts']) == set(ACCOUNTS), 'CREDENTIAL_SCHEMA')
        passwords = []
        for name, role in ACCOUNTS.items():
            row = payload['accounts'][name]
            require(type(row) is dict and set(row) == {'role', 'password'} and row['role'] == role, 'CREDENTIAL_SCHEMA')
            password = row['password']
            require(type(password) is str and 48 <= len(password) <= 128 and all(33 <= ord(c) <= 126 for c in password) and
                    all(re.search(pattern, password) for pattern in (r'[A-Z]', r'[a-z]', r'[0-9]', r'[^A-Za-z0-9]')), 'CREDENTIAL_SCHEMA')
            passwords.append(password)
        require(passwords[0] != passwords[1], 'CREDENTIAL_SCHEMA')
        self._payload = copy.deepcopy(payload)

    def __repr__(self):
        return '<Credentials redacted>'

    __str__ = __repr__

    def encode(self):
        return A66.compact(self._payload).encode('utf-8')

    def password_for(self, name):
        require(name in ACCOUNTS, 'CREDENTIAL_SCHEMA')
        return self._payload['accounts'][name]['password']

    @classmethod
    def decode(cls, raw):
        try:
            payload = json.loads(raw.decode('utf-8'), object_pairs_hook=A66.unique)
            return cls(payload)
        except (ValueError, UnicodeError, A66.ProvisionError):
            raise SetupError('CREDENTIAL_SCHEMA') from None


def generate_credentials():
    return Credentials({'version': 1, 'instance': 'HEALTHPROJECTQA', 'database': A66.DATABASE,
                        'accounts': {name: {'role': role, 'password': 'Aa9!' + secrets.token_urlsafe(48)} for name, role in ACCOUNTS.items()}})


class DataBlob(ctypes.Structure):
    _fields_ = [('cbData', wintypes.DWORD), ('pbData', ctypes.POINTER(ctypes.c_ubyte))]


class Dpapi:
    """CurrentUser (no LOCAL_MACHINE flag), no UI, correct pointer-sized LocalFree."""
    def __init__(self):
        require(os.name == 'nt', 'DPAPI_UNAVAILABLE')
        self.crypt = ctypes.WinDLL('crypt32', use_last_error=True)
        self.kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        blob = ctypes.POINTER(DataBlob)
        self.crypt.CryptProtectData.argtypes = [blob, wintypes.LPCWSTR, blob, ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD, blob]
        self.crypt.CryptProtectData.restype = wintypes.BOOL
        self.crypt.CryptUnprotectData.argtypes = [blob, ctypes.POINTER(ctypes.c_void_p), blob, ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD, blob]
        self.crypt.CryptUnprotectData.restype = wintypes.BOOL
        self.kernel.LocalFree.argtypes = [ctypes.c_void_p]
        self.kernel.LocalFree.restype = ctypes.c_void_p

    def _call(self, raw, decrypt):
        require(type(raw) is bytes and 0 < len(raw) <= 1048576, 'DPAPI_FAILED')
        buffer = ctypes.create_string_buffer(raw)
        entropy = ctypes.create_string_buffer(ENTROPY)
        source = DataBlob(len(raw), ctypes.cast(buffer, ctypes.POINTER(ctypes.c_ubyte)))
        extra = DataBlob(len(ENTROPY), ctypes.cast(entropy, ctypes.POINTER(ctypes.c_ubyte)))
        output = DataBlob()
        try:
            function = self.crypt.CryptUnprotectData if decrypt else self.crypt.CryptProtectData
            ok = function(ctypes.byref(source), None, ctypes.byref(extra), None, None, 1, ctypes.byref(output))
            require(bool(ok) and bool(output.pbData) and 0 < output.cbData <= 1048576, 'DPAPI_FAILED')
            return ctypes.string_at(output.pbData, output.cbData)
        finally:
            ctypes.memset(buffer, 0, len(raw))
            if output.pbData:
                if decrypt:
                    ctypes.memset(output.pbData, 0, output.cbData)
                self.kernel.LocalFree(ctypes.cast(output.pbData, ctypes.c_void_p))

    def protect(self, raw):
        return self._call(raw, False)

    def unprotect(self, raw):
        return self._call(raw, True)


def inspect_ancestors(path):
    require(path.is_absolute() and '..' not in path.parts, 'STORE_PATH_INVALID')
    for parent in (path, *path.parents):
        try:
            info = parent.lstat()
        except FileNotFoundError:
            continue
        require(not parent.is_symlink() and not getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT, 'STORE_REPARSE')
        require(stat.S_ISDIR(info.st_mode), 'STORE_PATH_INVALID')


class CredentialStore:
    def __init__(self, *, _test_root=None, protector=None):
        self.root = STORE if _test_root is None else Path(_test_root)
        self.protector = protector
        self.lock_fd = None

    def reserve(self):
        inspect_ancestors(self.root.parent)
        require(not os.path.lexists(self.root), 'STORE_COLLISION')
        self.root.mkdir()  # parent is fixed, existing and inspected; never adopt a directory
        self.lock_fd = os.open(self.root / 'setup.lock', os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, 'O_BINARY', 0), 0o600)
        os.write(self.lock_fd, b'1')
        os.fsync(self.lock_fd)
        import msvcrt
        os.lseek(self.lock_fd, 0, os.SEEK_SET)
        try:
            msvcrt.locking(self.lock_fd, msvcrt.LK_NBLCK, 1)
        except OSError:
            raise SetupError('STORE_LOCK_FAILED') from None

    def close(self):
        if self.lock_fd is not None:
            os.close(self.lock_fd)  # release OS lock, retain the file and all evidence
            self.lock_fd = None

    def save(self, credentials):
        require(self.lock_fd is not None, 'STORE_LOCK_REQUIRED')
        protector = self.protector or Dpapi()
        plaintext = credentials.encode()
        ciphertext = protector.protect(plaintext)
        require(hmac.compare_digest(protector.unprotect(ciphertext), plaintext), 'DPAPI_ROUNDTRIP')
        path = self.root / 'credentials.dpapi'
        with path.open('xb') as stream:
            stream.write(ciphertext)
            stream.flush()
            os.fsync(stream.fileno())
        require(hmac.compare_digest(self.load().encode(), plaintext), 'DPAPI_ROUNDTRIP')

    def load(self):
        inspect_ancestors(self.root)
        path = self.root / 'credentials.dpapi'
        info = path.lstat()
        require(stat.S_ISREG(info.st_mode) and not path.is_symlink() and not getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT and 0 < info.st_size <= 1048576, 'STORE_FILE_INVALID')
        return Credentials.decode((self.protector or Dpapi()).unprotect(path.read_bytes()))

    def journal(self, state):
        A66.persist(self.root / 'setup.journal.json', state)


def load_credentials():
    """Authorized local launchers only: return a redacted object, never print/export."""
    return CredentialStore().load()


def login_expected(name):
    return {'name': name, 'type': 'S', 'disabled': 0, 'database': A66.DATABASE, 'policy': 1, 'expiration': 0,
            'serverRoles': 0, 'sysadmin': 0, 'extraPermissions': 0, 'ownedObjects': 0, 'credentialBound': 0, 'databaseOwner': 0}


def user_expected(name):
    return {'name': name, 'type': 'S', 'authenticationType': 1, 'schema': 'dbo', 'sidMatch': 1,
            'memberships': [{'role': ACCOUNTS[name]}], 'extraPermissions': 0, 'ownedSchemas': 0, 'ownedObjects': 0, 'ownedPrincipals': 0}


def expected_metadata(installed):
    return {'canAlterLogins': 1, 'controlDatabase': 1, 'publicServerUnexpected': 0, 'publicDatabaseUnexpected': 0, 'roleParents': 0, 'roleOwnedSecurables': 0,
            'logins': [login_expected(name) for name in ACCOUNTS] if installed else [],
            'users': [user_expected(name) for name in ACCOUNTS] if installed else []}


def expected_catalog(artifact, installed):
    result = copy.deepcopy(artifact.expected)
    if installed:
        result['extraPrincipals'] = 2
    return result


def snapshot_sql(artifact):
    names = ','.join(A66.literal(name) for name in ACCOUNTS)
    sql = A66.database_guard() + A66.catalog_sql(artifact)
    sql += """DECLARE @a67_metadata nvarchar(max)=(SELECT
 CONVERT(int,ISNULL(HAS_PERMS_BY_NAME(NULL,NULL,'ALTER ANY LOGIN'),0)) canAlterLogins,
 CONVERT(int,ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL'),0)) controlDatabase,
 (SELECT COUNT(*) FROM sys.server_permissions p JOIN sys.server_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name=N'public' AND p.state IN ('G','W') AND NOT ((p.class=100 AND p.permission_name IN (N'CONNECT SQL',N'VIEW ANY DATABASE')) OR (p.class=105 AND p.permission_name=N'CONNECT'))) publicServerUnexpected,
 (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'public') AND state IN ('G','W') AND NOT((class=0 AND permission_name IN (N'CONNECT',N'VIEW ANY COLUMN ENCRYPTION KEY DEFINITION',N'VIEW ANY COLUMN MASTER KEY DEFINITION')) OR (class=1 AND OBJECT_SCHEMA_NAME(major_id)=N'sys'))) publicDatabaseUnexpected,
 (SELECT COUNT(*) FROM sys.database_role_members WHERE member_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor'))) roleParents,
 ((SELECT COUNT(*) FROM sys.schemas WHERE principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))+(SELECT COUNT(*) FROM sys.objects WHERE principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))+(SELECT COUNT(*) FROM sys.database_principals WHERE owning_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))) roleOwnedSecurables,
 JSON_QUERY(COALESCE((SELECT s.name,s.type,CONVERT(int,s.is_disabled) disabled,s.default_database_name [database],CONVERT(int,l.is_policy_checked) policy,CONVERT(int,l.is_expiration_checked) expiration,
 (SELECT COUNT(*) FROM sys.server_role_members WHERE member_principal_id=s.principal_id) serverRoles,
 CONVERT(int,ISNULL(IS_SRVROLEMEMBER(N'sysadmin',s.name),-1)) sysadmin,
 (SELECT COUNT(*) FROM sys.server_permissions WHERE grantee_principal_id=s.principal_id AND NOT(class=100 AND major_id=0 AND permission_name=N'CONNECT SQL' AND state='G')) extraPermissions,
 ((SELECT COUNT(*) FROM sys.server_principals WHERE owning_principal_id=s.principal_id)+(SELECT COUNT(*) FROM sys.endpoints WHERE principal_id=s.principal_id)) ownedObjects,
 CONVERT(int,CASE WHEN s.credential_id IS NULL THEN 0 ELSE 1 END) credentialBound,
 (SELECT COUNT(*) FROM sys.databases WHERE database_id=DB_ID() AND owner_sid=s.sid) databaseOwner
 FROM sys.server_principals s LEFT JOIN sys.sql_logins l ON l.principal_id=s.principal_id WHERE s.name IN (""" + names + """ ) ORDER BY s.name COLLATE Latin1_General_100_BIN2 FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]')) logins,
 JSON_QUERY(COALESCE((SELECT u.name,u.type,u.authentication_type authenticationType,u.default_schema_name [schema],CONVERT(int,CASE WHEN u.sid=s.sid THEN 1 ELSE 0 END) sidMatch,
 JSON_QUERY(COALESCE((SELECT r.name role FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id WHERE m.member_principal_id=u.principal_id ORDER BY r.name COLLATE Latin1_General_100_BIN2 FOR JSON PATH),N'[]')) memberships,
 (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id=u.principal_id AND NOT(class=0 AND major_id=0 AND permission_name=N'CONNECT' AND state='G')) extraPermissions,
 (SELECT COUNT(*) FROM sys.schemas WHERE principal_id=u.principal_id) ownedSchemas,
 (SELECT COUNT(*) FROM sys.objects WHERE principal_id=u.principal_id) ownedObjects,
 (SELECT COUNT(*) FROM sys.database_principals WHERE owning_principal_id=u.principal_id) ownedPrincipals
 FROM sys.database_principals u LEFT JOIN sys.server_principals s ON s.name=u.name WHERE u.name IN (""" + names + """ ) ORDER BY u.name COLLATE Latin1_General_100_BIN2 FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]')) users
 FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER);
DECLARE @a67_snapshot nvarchar(max)=(SELECT JSON_QUERY(@a66_catalog) catalog,JSON_QUERY(@a67_metadata) metadata FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
"""
    return sql


def inspect_sql(artifact, phase='inspect'):
    require(phase in {'inspect', 'inspect_fresh'}, 'PHASE_INVALID')
    return 'SET NOCOUNT ON;\n' + snapshot_sql(artifact) + A66.framed(phase, '@a67_snapshot')


def sql_gate(artifact, installed):
    return "IF @a66_catalog COLLATE Latin1_General_100_BIN2<>" + A66.literal(A66.compact(expected_catalog(artifact, installed))) + " OR @a67_metadata COLLATE Latin1_General_100_BIN2<>" + A66.literal(A66.compact(expected_metadata(installed))) + " THROW 59999,N'Isolated QA login postconditions mismatch',1;\n"


def create_sql(artifact, credentials):
    sql = ':ON ERROR EXIT\nSET NOCOUNT ON; SET XACT_ABORT ON;\nBEGIN TRAN;\n' + snapshot_sql(artifact) + sql_gate(artifact, False)
    sql += 'GO\nUSE [master];\n' + A66.INSTANCE_GUARD
    for name in ACCOUNTS:
        sql += 'CREATE LOGIN [' + name + '] WITH PASSWORD=' + A66.literal(credentials.password_for(name)) + ',DEFAULT_DATABASE=[' + A66.DATABASE + '],CHECK_POLICY=ON,CHECK_EXPIRATION=OFF;\n'
    sql += 'USE [' + A66.DATABASE + '];\n'
    for name, role in ACCOUNTS.items():
        sql += 'CREATE USER [' + name + '] FOR LOGIN [' + name + '] WITH DEFAULT_SCHEMA=[dbo];\nALTER ROLE [' + role + '] ADD MEMBER [' + name + '];\n'
    sql += 'GO\n' + snapshot_sql(artifact) + sql_gate(artifact, True)
    sql += "IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'Isolated QA login transaction invalid',1;\nCOMMIT;\n"
    return sql + A66.framed('commit_acknowledged', '@a67_snapshot')


class Transport:
    def __init__(self, env):
        self.env, self.raw_exits = env, []

    def run(self, sql, phase):
        executable = shutil.which('sqlcmd.exe', path=self.env.get('PATH', ''))
        require(executable is not None, 'SQLCMD_NOT_FOUND')
        argv = [executable, '-S', A66.SERVER, '-d', A66.DATABASE, '-E', '-C', '-b', '-X1', '-x', '-l', '5', '-t', '20', '-f', '65001', '-y', '0', '-w', '65535', '-r1']
        try:
            response = subprocess.run(argv, input=sql + '\nGO\n:EXIT\n', env=self.env, capture_output=True, text=True, encoding='utf-8', errors='strict', timeout=30, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        except subprocess.TimeoutExpired:
            raise SetupError('SQLCMD_TIMEOUT') from None
        except (OSError, UnicodeError):
            raise SetupError('SQLCMD_FAILED') from None
        raw = response.returncode
        self.raw_exits.append({'phase': phase, 'raw_exit_code': raw if type(raw) is int else None})
        require(type(response.stderr) is str, 'SQLCMD_FAILED')
        if re.search(r'(?im)^\s*Timeout[ \t]+expired\s*$', response.stderr):
            raise SetupError('SQLCMD_TIMEOUT')
        require(not response.stderr.strip() and type(raw) is int and raw == 0, 'SQLCMD_FAILED')
        # ODBC stdin mode can emit numeric interactive prompts. Remove only
        # anchored prompt tokens; all remaining output must pass the unchanged
        # framed checksum parser. Never persist raw output or echoed SQL.
        require(type(response.stdout) is str, 'RESPONSE_INVALID')
        output = re.sub(r'(?m)^(?:[1-9][0-9]*>[ \t]*)+', '', response.stdout)
        return A66.parse_response(output, phase)


def resource_state(snapshot, artifact):
    require(type(snapshot) is dict and set(snapshot) == {'catalog', 'metadata'}, 'SNAPSHOT_INVALID')
    meta = snapshot['metadata']
    require(type(meta) is dict and set(meta) == set(expected_metadata(False)) and type(meta['logins']) is list and type(meta['users']) is list, 'SNAPSHOT_INVALID')
    require(meta['canAlterLogins'] == 1 and type(meta['canAlterLogins']) is int and meta['controlDatabase'] == 1 and type(meta['controlDatabase']) is int, 'SETUP_AUTHORITY_REQUIRED')
    present = len(meta['logins']) + len(meta['users'])
    if present == 0:
        installed = False
    elif present == 4:
        installed = True
    else:
        return 'partial'
    require(A66.compact(snapshot['catalog']) == A66.compact(expected_catalog(artifact, installed)), 'CATALOG_DRIFT')
    require(A66.compact(meta) == A66.compact(expected_metadata(installed)), 'PRINCIPAL_CONFLICT')
    if not installed:
        require(A66.digest(A66.compact(snapshot['catalog']).encode('utf-8')) == BASE_FP, 'CATALOG_DRIFT')
    return 'installed' if installed else 'absent'


def execute(argv, *, transport=None, store=None, generator=generate_credentials, loader=A66.Artifacts.load, env=None, directory=TEMP):
    mode = 'plan' if argv in ([], ['plan']) else 'verify' if argv == ['verify'] else 'create' if argv == ['create', '--confirm-isolated-logins'] else None
    result = {'status': 'error', 'sql_action': 'not_attempted', 'reconciliation_required': False, 'retry_mutation': False,
              'instance': 'HEALTHPROJECTQA', 'database': A66.DATABASE, 'scope': A66.MARKER, 'jdbc_positive_validated': False,
              'password_authentication_validated': False, 'credential_store_verified': False}
    reserved = False
    evidence = None
    try:
        require(mode is not None, 'COMMAND_INVALID')
        child_env = A66.environment(os.environ if env is None else env)
        artifact = loader()
        transport = transport or Transport(child_env)
        snapshot = transport.run(inspect_sql(artifact), 'inspect')
        state = resource_state(snapshot, artifact)
        result['resources'] = state
        result['catalog_fingerprint'] = A66.digest(A66.compact(snapshot['catalog']).encode('utf-8'))
        if mode == 'plan':
            result.update(status='planned' if state != 'partial' else 'blocked', code='READONLY_PLAN', credential_store='not_accessed_in_plan')
        elif mode == 'verify':
            require(state == 'installed', 'PRINCIPALS_NOT_INSTALLED')
            store = store or CredentialStore()
            store.load()  # schema/DPAPI binding only, never SQL password authentication
            result.update(status='verified', code='METADATA_AND_DPAPI_VERIFIED', credential_store_verified=True)
        else:
            require(state == 'absent', 'PRINCIPAL_COLLISION')
            store = store or CredentialStore()
            store.reserve()
            reserved = True
            store.journal(result)
            credentials = generator()
            store.save(credentials)
            result['credential_store_verified'] = True
            # Build in memory only. Never include SQL/password/blob in evidence.
            sql = create_sql(artifact, credentials)
            result['sql_action'] = 'mutation_outcome_unverified'
            result['reconciliation_required'] = True
            store.journal(result)
            acknowledged = transport.run(sql, 'commit_acknowledged')
            require(resource_state(acknowledged, artifact) == 'installed', 'COMMIT_ACK_INVALID')
            result['sql_action'] = 'commit_acknowledged'
            store.journal(result)
            fresh = transport.run(inspect_sql(artifact, 'inspect_fresh'), 'inspect_fresh')
            require(resource_state(fresh, artifact) == 'installed', 'FRESH_VERIFY_FAILED')
            result.update(status='configured', code='COMMIT_VERIFIED', sql_action='commit_verified', reconciliation_required=False,
                          catalog_fingerprint=A66.digest(A66.compact(fresh['catalog']).encode('utf-8')))
    except SetupError as error:
        result['code'] = str(error)
        if result['code'] in {'PRINCIPAL_CONFLICT', 'CATALOG_DRIFT'}:
            result['resources'] = 'conflict'
        if result['code'] in {'PRINCIPAL_CONFLICT', 'PRINCIPAL_COLLISION', 'STORE_COLLISION', 'SETUP_AUTHORITY_REQUIRED'}:
            result['status'] = 'blocked'
    except A66.ProvisionError as error:
        result['code'] = error.code
    except Exception:
        result['code'] = 'INSPECTION_OR_STORAGE_FAILED'
    finally:
        if reserved:
            try:
                store.journal(result)
            except Exception:
                result.update(status='error', code='JOURNAL_FAILED')
        if store is not None:
            try:
                store.close()
            except Exception:
                result.update(status='error', code='STORE_CLOSE_FAILED')
    if result['reconciliation_required']:
        result['message'] = 'Do not retry or delete principals or ciphertext. Reconcile using a fresh administrative connection; historical errors remain unchanged.'
    if transport is not None:
        result['raw_exits'] = transport.raw_exits
    result['limits'] = ['Administrative metadata/DPAPI only; no password login, JDBC, TLS, runtime grants, bootstrap SAD, HTTP or visual validation.',
                        'Plan does not access the operational credential store; create checks collisions exclusively before generating secrets.']
    try:
        directory.mkdir(parents=True, exist_ok=True)
        evidence = directory / (uuid.uuid4().hex + '.json')
        A66.persist(evidence, result)
        result['evidence'] = str(evidence)
    except Exception:
        result.update(status='error', code='EVIDENCE_FAILED')
    return result


def main(argv=None, **dependencies):
    result = execute(sys.argv[1:] if argv is None else argv, **dependencies)
    print(json.dumps(result, indent=2))
    return 0 if result['status'] in {'planned', 'verified', 'configured'} else 2 if result['status'] == 'blocked' else 1


if __name__ == '__main__':
    sys.exit(main())
