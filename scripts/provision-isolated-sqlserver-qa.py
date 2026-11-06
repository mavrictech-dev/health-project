"""Closed, journaled setup of a NEW isolated QA database. No runtime credentials."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'backend/src/main/resources/db/sqlserver'
TEMP = ROOT / 'tmp/sqlserver-a66-provision'
SERVER = r'lpc:.\HEALTHPROJECTQA'
DATABASE = 'health_project_sqlserver_qa_isolated_20261105'
MARKER = 'Health Project isolated JDBC QA; provisioned 2026-11-05; no real data'
MIGRATOR = 'hp_qa_isolated_migrator'
DATA_ROOT = r'D:\HealthProject-QA\SqlServer'
DATA_DIR = DATA_ROOT + r'\Data'
DATA_FILE = DATA_DIR + '\\' + DATABASE + '.mdf'
LOG_FILE = DATA_DIR + '\\' + DATABASE + '_log.ldf'
QUERY_SECONDS = 60
PROCESS_SECONDS = 75
PINS = (
    ('V1__schema.sql', 'ed1dcb3e6bd4f2ac1f9b11de9aa7d1053db0e71ca3610e21801cc60d51fe4a0a'),
    ('V2__catalog_seed.sql', 'f672c8856ab6a150ae1967e85b8baf9df07f2615f4db8445263f11f322a1a885'),
    ('V3__identity_infrastructure_procedures.sql', 'b4ebe83471354e2027315d95e1657afde72ad2c19c508e2ef764c2356f940ce0'),
    ('V4__saas_organization_procedures.sql', '9640cd1215f27eb6789e7b79c11291aa37bc89f61b2112f678d364c2112654dc'),
    ('V5__clinical_procedures.sql', 'd2352d8fe6a6f8f84c62179f7a643027866a17229064b9b0ce3d96f60fcd9ece'),
    ('V6__operations_procedures.sql', '4a8539629c916007563a0b96b997897191dbd00aa84fb3c8e6ed5284ae5afeab'),
    ('V7__audit_triggers.sql', '56602e981c437e3b5a3057e8483d2ffce1491d046f478dc544906e4be3af42dc'),
    ('V8__execution_permissions.sql', '3d162d64b43001c1c63ed1084ef0797531d712155cea11a1ce1269a6fca555bd'),
    ('V9__appointment_window_days.sql', '5f8161b8e763ac50d4e12d9604ad0fb1c7ab02545c8782d2e73955939a5a69d0'),
)
LIMITS = ['No JDBC, TCP login, TLS, runtime grants, business or visual validation.',
          'No data copy, Flyway baseline, login, bootstrap SAD, retry or automatic cleanup.']


class ProvisionError(Exception):
    def __init__(self, code):
        self.code = code
        super().__init__(code)


def require(condition, code):
    if not condition:
        raise ProvisionError(code)


def digest(data):
    return hashlib.sha256(data).hexdigest().upper()


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'))


def literal(value):
    return "N'" + value.replace("'", "''") + "'"


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'RESPONSE_INVALID')
        result[key] = value
    return result


def split_values(text):
    """Split only this pinned seed grammar, respecting SQL quotes/parentheses."""
    parts, start, depth, quoted, index = [], 0, 0, False, 0
    while index < len(text):
        char = text[index]
        if char == "'":
            if quoted and index + 1 < len(text) and text[index + 1] == "'":
                index += 2
                continue
            quoted = not quoted
        elif not quoted:
            if char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
            elif char == ',' and depth == 0:
                parts.append(text[start:index].strip())
                start = index + 1
        require(depth >= 0, 'ARTIFACT_CONTRACT')
        index += 1
    require(not quoted and depth == 0, 'ARTIFACT_CONTRACT')
    return parts + [text[start:].strip()]


def seed_value(expression):
    if re.fullmatch(r'-?\d+', expression):
        return expression
    # Only N-string literals, concatenation and the approved MAX cast are used.
    tokens = re.findall(r"N'(?:[^']|'')*'", expression)
    remainder = re.sub(r"N'(?:[^']|'')*'", '', expression)
    remainder = re.sub(r'CAST\(| AS nvarchar\(max\)\)|[+\s]', '', remainder)
    require(tokens and not remainder, 'ARTIFACT_CONTRACT')
    return ''.join(token[2:-1].replace("''", "'") for token in tokens)


class Artifacts:
    def __init__(self, blobs):
        require(set(blobs) == {name for name, _ in PINS}, 'ARTIFACT_HASH')
        self.blobs = dict(blobs)
        self.hashes = {}
        texts = []
        for name, pin in PINS:
            raw = self.blobs[name]
            normalized = raw.replace(b'\r\n', b'\n')
            require(b'\r' not in normalized and digest(normalized).lower() == pin, 'ARTIFACT_HASH')
            text = normalized.decode('utf-8')
            require(not re.search(r'(?m)^\s*(?::|!!|GO\s+\d)', text), 'ARTIFACT_CONTRACT')
            self.hashes[name] = pin
            texts.append(text)
        schema = texts[0]
        self.columns = {name: re.findall(r'^\s+\[([^]]+)\]', body, re.M)
                        for name, body in re.findall(r'CREATE TABLE dbo\.(\w+) \((.*?)\n \);', schema, re.S)}
        require(len(self.columns) == 37, 'ARTIFACT_CONTRACT')
        self.modules = {}
        for text in texts:
            for verb, kind, name, body in re.findall(r'^(CREATE|ALTER) (PROCEDURE|TRIGGER) dbo\.(\w+)(.*?)(?=^GO\s*$)', text, re.M | re.S):
                definition = 'CREATE ' + kind + ' dbo.' + name + body.rstrip(' \t\n')
                parent = re.search(r' ON dbo\.\[?(\w+)\]?', body) if kind == 'TRIGGER' else None
                self.modules[name] = {'kind': 'P' if kind == 'PROCEDURE' else 'TR', 'name': name,
                                      'hash': digest(definition.encode('utf-16le')),
                                      'parent': parent.group(1) if parent else None, 'disabled': 0}
        require(sum(row['kind'] == 'P' for row in self.modules.values()) == 133 and
                sum(row['kind'] == 'TR' for row in self.modules.values()) == 31, 'ARTIFACT_CONTRACT')
        self.acl = []
        pattern = r'^(GRANT|DENY) (EXECUTE|SELECT,INSERT,UPDATE,DELETE|VIEW DEFINITION) ON OBJECT::dbo\.(\[?\w+\]?) TO (hp_(?:runtime|bootstrap)_executor);'
        for state, permissions, obj, role in re.findall(pattern, texts[7], re.M):
            obj = obj.strip('[]')
            if obj != 'flyway_schema_history':
                for permission in permissions.split(','):
                    self.acl.append({'role': role, 'classId': 1, 'schemaName': 'dbo', 'objectName': obj,
                                     'minorId': 0, 'permissionName': permission, 'state': 'G' if state == 'GRANT' else 'D'})
        self.acl.sort(key=lambda row: tuple(row.values()))
        require(len(self.acl) == 562 and len({compact(row) for row in self.acl}) == 562, 'ARTIFACT_CONTRACT')
        self.seed_columns, self.seeds, self.profile_categories = {}, {}, {}
        for line in texts[1].splitlines():
            if not line or line.startswith('--'):
                continue
            match = re.fullmatch(r'INSERT INTO dbo\.(\w+)\s*(?:\(([^)]+)\))? VALUES\s*\((.*)\);', line)
            require(match is not None, 'ARTIFACT_CONTRACT')
            table, columns, values = match.groups()
            cols = columns.split(',') if columns else self.columns[table]
            cols = [col.strip() for col in cols]
            expressions = split_values(values)
            require(len(cols) == len(expressions), 'ARTIFACT_CONTRACT')
            require(table not in self.seed_columns or self.seed_columns[table] == cols, 'ARTIFACT_CONTRACT')
            self.seed_columns[table] = cols
            values = {col: seed_value(expr) for col, expr in zip(cols, expressions)}
            self.seeds.setdefault(table, []).append({col: digest(value.encode('utf-16le')) for col, value in values.items()})
            if table == 'specialties':
                profile = json.loads(values['profile'], object_pairs_hook=unique)
                category = profile['catalogDomain']
                self.profile_categories[category] = self.profile_categories.get(category, 0) + 1
        require({table: len(rows) for table, rows in self.seeds.items()} ==
                {'specialties': 241, 'plans': 4, 'plan_versions': 4, 'workflow_definitions': 15, 'application_state': 1}, 'ARTIFACT_CONTRACT')
        for rows in self.seeds.values():
            rows.sort(key=lambda row: tuple(row.values()))
        self.expected = {
            'tables': sorted(self.columns),
            'modules': sorted(self.modules.values(), key=lambda row: (row['kind'], row['name'])),
            'roles': [{'name': name, 'type': 'R', 'owner': 'dbo'} for name in ('hp_bootstrap_executor', 'hp_runtime_executor')],
            'migrator': {'count': 1, 'type': 'S', 'authenticationType': 0, 'controlGranted': 1, 'extraPermissions': 0, 'memberships': 0},
            'extraPrincipals': 0, 'acl': self.acl,
            'counts': {table: len(self.seeds.get(table, [])) for table in sorted(self.columns)},
            'seedRows': {table: self.seeds[table] for table in sorted(self.seeds)},
        }

    @classmethod
    def load(cls):
        return cls({name: (SOURCE / name).read_bytes() for name, _ in PINS})


INSTANCE_GUARD = """IF ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'') COLLATE Latin1_General_100_BIN2<>N'HEALTHPROJECTQA'
 OR CONVERT(varchar(30),SERVERPROPERTY('ProductVersion')) NOT LIKE '16.0.%'
 OR ISNULL(CONVERT(int,SERVERPROPERTY('IsIntegratedSecurityOnly')),1)<>0
 OR NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE principal_id=1 AND name=N'sa' AND is_disabled=1)
 THROW 59999,N'Isolated QA instance mismatch',1;
"""


def database_guard(marker=True):
    sql = INSTANCE_GUARD + 'IF DB_NAME() COLLATE Latin1_General_100_BIN2<>' + literal(DATABASE) + " THROW 59999,N'Isolated QA database mismatch',1;\n"
    sql += "IF (SELECT COUNT(*) FROM sys.database_files)<>2 OR EXISTS(SELECT 1 FROM sys.database_files WHERE physical_name COLLATE Latin1_General_100_BIN2 NOT IN (" + literal(DATA_FILE) + ',' + literal(LOG_FILE) + ")) THROW 59999,N'Isolated QA files mismatch',1;\n"
    if marker:
        sql += "IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=" + literal(MARKER) + " AND DATALENGTH(CONVERT(nvarchar(4000),value))=" + str(len(MARKER.encode('utf-16le'))) + ") OR (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>160 THROW 59999,N'Isolated QA scope mismatch',1;\n"
    return sql


def framed(phase, data_expression):
    return """DECLARE @a66_response nvarchar(max)=(SELECT """ + literal(phase) + " phase,JSON_QUERY(" + data_expression + """
) data FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
DECLARE @a66_offset int=1;
WHILE @a66_offset<=DATALENGTH(@a66_response)
BEGIN
 SELECT CAST(N'A66JSON:' AS nvarchar(max))+CONVERT(varchar(4000),SUBSTRING(CONVERT(varbinary(max),@a66_response),@a66_offset,2000),2);
 SET @a66_offset+=2000;
END;
SELECT N'A66END:'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@a66_response)),2);
"""


def plan_sql():
    return 'SET NOCOUNT ON;\n' + INSTANCE_GUARD + framed('plan', "(SELECT N'HEALTHPROJECTQA' instanceName," + literal(DATABASE) + " databaseName,CONVERT(int,CASE WHEN DB_ID(" + literal(DATABASE) + ") IS NULL THEN 0 ELSE 1 END) databaseExists,CONVERT(int,ISNULL(HAS_PERMS_BY_NAME(NULL,NULL,'CREATE ANY DATABASE'),0)) canCreate FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)")


def create_sql():
    return ':ON ERROR EXIT\nSET NOCOUNT ON;\n' + INSTANCE_GUARD + "IF DB_NAME()<>N'master' OR DB_ID(" + literal(DATABASE) + ") IS NOT NULL THROW 59999,N'Isolated QA creation conflict',1;\nCREATE DATABASE [" + DATABASE + "] ON PRIMARY(NAME=N'" + DATABASE + "_data',FILENAME=" + literal(DATA_FILE) + ",SIZE=16MB,FILEGROWTH=16MB) LOG ON(NAME=N'" + DATABASE + "_log',FILENAME=" + literal(LOG_FILE) + ",SIZE=16MB,FILEGROWTH=16MB);\n" + framed('created', "(SELECT 1 created FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)")


def mark_sql():
    return ':ON ERROR EXIT\nSET NOCOUNT ON; SET XACT_ABORT ON;\n' + database_guard(False) + "IF EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0) OR EXISTS(SELECT 1 FROM sys.procedures WHERE is_ms_shipped=0) OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0) OR DATABASE_PRINCIPAL_ID(N'" + MIGRATOR + "') IS NOT NULL THROW 59999,N'Isolated QA setup conflict',1;\nALTER DATABASE [" + DATABASE + "] SET COMPATIBILITY_LEVEL=160;\nBEGIN TRAN;\nEXEC sys.sp_addextendedproperty @name=N'health_project_scope',@value=" + literal(MARKER) + ";\nCREATE USER [" + MIGRATOR + "] WITHOUT LOGIN;\nGRANT CONTROL ON DATABASE::[" + DATABASE + "] TO [" + MIGRATOR + "];\nCOMMIT;\n" + framed('marked', "(SELECT 1 marked FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)")


def catalog_sql(art):
    # All queried tables are the closed, pinned schema in the marked NEW DB.
    sql = """DECLARE @a66_modules TABLE(kind varchar(2),name sysname,body nvarchar(max),parent sysname NULL,disabled int);
INSERT @a66_modules SELECT RTRIM(o.type),o.name,TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM REPLACE(m.definition,NCHAR(13),N'')),
 CASE WHEN o.type='TR' THEN OBJECT_NAME(o.parent_object_id) ELSE NULL END,
 ISNULL(CONVERT(int,t.is_disabled),0)
 FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id LEFT JOIN sys.triggers t ON t.object_id=o.object_id
 WHERE o.is_ms_shipped=0 AND o.type IN ('P','TR') AND o.schema_id=SCHEMA_ID(N'dbo');
WHILE EXISTS(SELECT 1 FROM @a66_modules WHERE LEFT(body,2)=N'--')
 UPDATE @a66_modules SET body=TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM SUBSTRING(body,CHARINDEX(NCHAR(10),body)+1,2147483647)) WHERE LEFT(body,2)=N'--' AND CHARINDEX(NCHAR(10),body)>0;
UPDATE @a66_modules SET body=N'CREATE'+SUBSTRING(body,6,2147483647) WHERE LEFT(body,6)=N'ALTER ';
DECLARE @a66_catalog nvarchar(max)=(SELECT
 JSON_QUERY((SELECT name FROM sys.tables WHERE is_ms_shipped=0 ORDER BY name COLLATE Latin1_General_100_BIN2 FOR JSON PATH)) tablesPlaceholder);
"""
    sql += "IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0 AND type IN ('P','TR') AND schema_id<>SCHEMA_ID(N'dbo')) THROW 59999,N'Isolated QA module inventory mismatch',1;\n"
    # Use rows of table names consistently (JSON scalar arrays require manual JSON).
    table_names = "N'[" + ','.join('"' + name + '"' for name in sorted(art.columns)) + "]'"
    sql += "IF EXISTS(SELECT name FROM sys.tables WHERE is_ms_shipped=0 EXCEPT SELECT value FROM OPENJSON(" + table_names + ")) OR EXISTS(SELECT value FROM OPENJSON(" + table_names + ") EXCEPT SELECT name FROM sys.tables WHERE is_ms_shipped=0) OR EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0 AND schema_id<>SCHEMA_ID(N'dbo')) THROW 59999,N'Isolated QA table inventory mismatch',1;\n"
    count_fields = ','.join('(SELECT COUNT_BIG(*) FROM dbo.[' + table + ']) [' + table + ']' for table in sorted(art.columns))
    seed_fields = []
    for table in sorted(art.seeds):
        columns = art.seed_columns[table]
        fields = ','.join("CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),CONVERT(nvarchar(max),[" + col + "]))),2) [" + col + "]" for col in columns)
        order = ','.join('[' + col + '] COLLATE Latin1_General_100_BIN2' for col in columns)
        seed_fields.append('JSON_QUERY((SELECT * FROM (SELECT ' + fields + ' FROM dbo.[' + table + ']) hashes ORDER BY ' + order + ' FOR JSON PATH,INCLUDE_NULL_VALUES)) [' + table + ']')
    sql += "SET @a66_catalog=(SELECT JSON_QUERY(" + table_names + """ ) tables,
 JSON_QUERY((SELECT kind,name,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),body)),2) hash,parent,disabled FROM @a66_modules ORDER BY kind COLLATE Latin1_General_100_BIN2,name COLLATE Latin1_General_100_BIN2 FOR JSON PATH,INCLUDE_NULL_VALUES)) modules,
 JSON_QUERY((SELECT name,type,USER_NAME(owning_principal_id) owner FROM sys.database_principals WHERE name IN (N'hp_bootstrap_executor',N'hp_runtime_executor') ORDER BY name COLLATE Latin1_General_100_BIN2 FOR JSON PATH)) roles,
 JSON_QUERY((SELECT (SELECT COUNT(*) FROM sys.database_principals WHERE name=N'hp_qa_isolated_migrator') count,
 (SELECT type FROM sys.database_principals WHERE name=N'hp_qa_isolated_migrator') type,
 (SELECT authentication_type FROM sys.database_principals WHERE name=N'hp_qa_isolated_migrator') authenticationType,
 (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'hp_qa_isolated_migrator') AND class=0 AND permission_name=N'CONTROL' AND state='G') controlGranted,
 (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'hp_qa_isolated_migrator') AND NOT(class=0 AND permission_name IN (N'CONTROL',N'CONNECT') AND state='G')) extraPermissions,
 (SELECT COUNT(*) FROM sys.database_role_members WHERE member_principal_id=DATABASE_PRINCIPAL_ID(N'hp_qa_isolated_migrator')) memberships
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) ) migrator,
 (SELECT COUNT(*) FROM sys.database_principals WHERE principal_id>4 AND is_fixed_role=0 AND name NOT IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_isolated_migrator')) extraPrincipals,
 JSON_QUERY((SELECT r.name role,p.class classId,OBJECT_SCHEMA_NAME(p.major_id) schemaName,OBJECT_NAME(p.major_id) objectName,p.minor_id minorId,p.permission_name permissionName,p.state state FROM sys.database_permissions p JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') ORDER BY r.name COLLATE Latin1_General_100_BIN2,p.class,OBJECT_SCHEMA_NAME(p.major_id) COLLATE Latin1_General_100_BIN2,OBJECT_NAME(p.major_id) COLLATE Latin1_General_100_BIN2,p.minor_id,p.permission_name COLLATE Latin1_General_100_BIN2,p.state COLLATE Latin1_General_100_BIN2 FOR JSON PATH,INCLUDE_NULL_VALUES)) acl,
 JSON_QUERY((SELECT """ + count_fields + " FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) counts,\n JSON_QUERY((SELECT " + ','.join(seed_fields) + " FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)) seedRows FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER);\n"
    return sql


def migration_wrapper(art):
    prefix = ':ON ERROR EXIT\nSET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;\n' + database_guard()
    prefix += "IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0) OR EXISTS(SELECT 1 FROM sys.database_principals WHERE principal_id>4 AND is_fixed_role=0 AND name<>N'" + MIGRATOR + "') THROW 59999,N'Isolated QA migration conflict',1;\nBEGIN TRAN;\nEXECUTE AS USER=N'" + MIGRATOR + "';\nIF USER_NAME()<>N'" + MIGRATOR + "' OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL'),0)<>1 THROW 59999,N'Isolated QA migrator required',1;\nGO\n"
    ending = "REVERT;\nIF USER_NAME()=N'" + MIGRATOR + "' OR @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'Isolated QA transaction invalid',1;\n" + catalog_sql(art)
    ending += "IF @a66_catalog COLLATE Latin1_General_100_BIN2<>" + literal(compact(art.expected)) + " OR DATALENGTH(@a66_catalog)<>" + str(len(compact(art.expected).encode('utf-16le'))) + " THROW 59999,N'Isolated QA postconditions failed',1;\nCOMMIT;\n"
    ending += framed('commit_acknowledged', '@a66_catalog')
    return prefix.encode('utf-8') + b''.join(art.blobs[name] + b'\nGO\n' for name, _ in PINS) + ending.encode('utf-8')


def verify_sql(art):
    return 'SET NOCOUNT ON;\n' + database_guard() + "IF @@TRANCOUNT<>0 THROW 59999,N'Isolated QA transaction invalid',1;\n" + catalog_sql(art) + framed('verified', '@a66_catalog')


def parse_response(stdout, phase):
    require(isinstance(stdout, str), 'RESPONSE_INVALID')
    lines = [line.strip() for line in stdout.lstrip('\ufeff').splitlines() if line.strip()]
    require(len(lines) >= 2 and re.fullmatch(r'A66END:[0-9A-F]{64}', lines[-1]), 'RESPONSE_INVALID')
    require(all(re.fullmatch(r'A66JSON:(?:[0-9A-F]{2}){1,2000}', line) for line in lines[:-1]), 'RESPONSE_INVALID')
    raw = b''.join(bytes.fromhex(line[8:]) for line in lines[:-1])
    require(digest(raw) == lines[-1][7:], 'RESPONSE_INVALID')
    try:
        row = json.loads(raw.decode('utf-16le'), object_pairs_hook=unique)
    except (ValueError, UnicodeError):
        raise ProvisionError('RESPONSE_INVALID') from None
    require(type(row) is dict and set(row) == {'phase', 'data'} and row['phase'] == phase and type(row['data']) is dict, 'RESPONSE_INVALID')
    return row['data']


def environment(source):
    require(not any(key.upper().startswith('SQLCMD') for key in source), 'HOSTILE_ENVIRONMENT')
    allowed = {'SYSTEMROOT', 'WINDIR', 'SYSTEMDRIVE', 'TEMP', 'TMP', 'PATH', 'COMSPEC', 'PATHEXT'}
    return {key: value for key, value in source.items() if key.upper() in allowed}


def check_paths():
    directory = Path(DATA_DIR)
    try:
        for path in (directory, *directory.parents):
            info = path.lstat()
            require(stat.S_ISDIR(info.st_mode) and not path.is_symlink() and not getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT, 'PATH_UNSAFE')
        require(not os.path.lexists(DATA_FILE) and not os.path.lexists(LOG_FILE), 'FILE_COLLISION')
    except OSError:
        raise ProvisionError('PATH_INSPECTION_FAILED') from None


class Transport:
    def __init__(self, env, directory):
        self.env = env
        self.directory = directory
        self.raw_exits = []

    def run(self, database, sql, phase, mutation=False):
        require(database in ('master', DATABASE), 'TARGET_INVALID')
        executable = shutil.which('sqlcmd.exe', path=self.env.get('PATH', ''))
        require(executable is not None, 'SQLCMD_NOT_FOUND')
        path = self.directory / (phase + '.sql')
        with path.open('xb') as stream:
            stream.write(sql if isinstance(sql, bytes) else sql.encode('utf-8'))
        argv = [executable, '-S', SERVER, '-d', database, '-E', '-C', '-b', '-X1', '-x', '-l', '5', '-t', str(QUERY_SECONDS if mutation else 10), '-f', '65001', '-y', '0', '-w', '65535', '-r1', '-i', str(path)]
        try:
            response = subprocess.run(argv, env=self.env, capture_output=True, text=True, encoding='utf-8', errors='strict', timeout=PROCESS_SECONDS if mutation else 20, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        except subprocess.TimeoutExpired:
            raise ProvisionError('SQLCMD_TIMEOUT') from None
        except (OSError, UnicodeError):
            raise ProvisionError('SQLCMD_FAILED') from None
        raw = response.returncode
        self.raw_exits.append({'phase': phase, 'raw_exit_code': raw if type(raw) is int else None})
        require(isinstance(response.stderr, str), 'SQLCMD_FAILED')
        if re.search(r'(?im)^\s*Timeout[ \t]+expired\s*$', response.stderr):
            raise ProvisionError('SQLCMD_TIMEOUT')
        require(not response.stderr.strip() and type(raw) is int and raw == 0, 'SQLCMD_FAILED')
        result = parse_response(response.stdout, phase)
        (self.directory / (phase + '.json')).write_text(compact(result), encoding='utf-8')
        return result


def persist(path, value):
    try:
        with path.open('w', encoding='utf-8') as stream:
            json.dump(value, stream, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
    except OSError:
        raise ProvisionError('JOURNAL_FAILED') from None


def execute(argv, *, transport=None, loader=Artifacts.load, path_check=check_paths, env=None, directory=TEMP):
    mode = 'plan' if argv in ([], ['plan']) else 'verify' if argv == ['verify'] else 'create' if argv == ['create', '--confirm-isolated-qa'] else None
    result = {'status': 'error', 'database': DATABASE, 'scope': MARKER, 'jdbc_positive_validated': False,
              'sql_action': 'not_attempted', 'reconciliation_required': False, 'retry_mutation': False, 'limits': LIMITS}
    journal = None
    try:
        require(mode is not None, 'COMMAND_INVALID')
        child_env = environment(os.environ if env is None else env)
        art = loader()
        own = directory / uuid.uuid4().hex
        own.mkdir(parents=True, exist_ok=False)
        transport = transport or Transport(child_env, own)
        result['evidence'] = str(own)
        result['artifacts'] = art.hashes
        result['seed_inventory'] = {table: len(rows) for table, rows in art.seeds.items()}
        result['profile_categories'] = art.profile_categories
        metadata = transport.run('master', plan_sql(), 'plan')
        require(set(metadata) == {'instanceName', 'databaseName', 'databaseExists', 'canCreate'} and metadata['instanceName'] == 'HEALTHPROJECTQA' and metadata['databaseName'] == DATABASE and type(metadata['databaseExists']) is int and metadata['databaseExists'] in (0, 1) and type(metadata['canCreate']) is int and metadata['canCreate'] in (0, 1), 'METADATA_INVALID')
        if mode == 'verify':
            require(metadata['databaseExists'] == 1, 'DATABASE_MISSING')
            actual = transport.run(DATABASE, verify_sql(art), 'verified')
            require(compact(actual) == compact(art.expected), 'VERIFICATION_FAILED')
            result.update(status='verified', code='CATALOG_VERIFIED', fingerprint=digest(compact(actual).encode('utf-8')))
        else:
            require(metadata['databaseExists'] == 0, 'DATABASE_EXISTS')
            require(metadata['canCreate'] == 1, 'CREATE_PERMISSION_REQUIRED')
            path_check()
            result['actions'] = ['create_new_database', 'mark_and_create_without_login_migrator', 'migrate_V1_through_V9_single_transaction', 'fresh_readonly_verify']
            if mode == 'plan':
                result.update(status='planned', code='SUPERVISOR_REVIEW_REQUIRED')
            else:
                journal = own / 'journal.json'
                result['sql_action'] = 'not_attempted'
                persist(journal, result)
                result['sql_action'] = 'create_outcome_unverified'
                result['reconciliation_required'] = True
                persist(journal, result)  # durable intent before nontransactional CREATE
                require(compact(transport.run('master', create_sql(), 'created', True)) == '{"created":1}', 'CREATE_ACK_INVALID')
                result['sql_action'] = 'create_acknowledged'
                persist(journal, result)
                result['sql_action'] = 'marker_outcome_unverified'
                persist(journal, result)
                require(compact(transport.run(DATABASE, mark_sql(), 'marked', True)) == '{"marked":1}', 'MARKER_ACK_INVALID')
                result['sql_action'] = 'migration_outcome_unverified'
                persist(journal, result)
                inside = transport.run(DATABASE, migration_wrapper(art), 'commit_acknowledged', True)
                require(compact(inside) == compact(art.expected), 'COMMIT_ACK_INVALID')
                result['sql_action'] = 'commit_acknowledged'
                persist(journal, result)
                actual = transport.run(DATABASE, verify_sql(art), 'verified')
                require(compact(actual) == compact(art.expected), 'VERIFICATION_FAILED')
                result.update(status='configured', code='COMMIT_VERIFIED', sql_action='commit_verified', reconciliation_required=False,
                              fingerprint=digest(compact(actual).encode('utf-8')))
    except ProvisionError as error:
        result['code'] = error.code
        if error.code in {'DATABASE_EXISTS', 'DATABASE_MISSING', 'CREATE_PERMISSION_REQUIRED', 'PATH_INSPECTION_FAILED'} and result['sql_action'] == 'not_attempted':
            result['status'] = 'blocked'
    except Exception:
        result['code'] = 'INSPECTION_FAILED'
    if result['reconciliation_required']:
        result['message'] = 'Do not repeat create or migrations; reconcile the database state using a fresh connection. No cleanup was attempted.'
    if transport is not None:
        result['raw_exits'] = transport.raw_exits
    if journal is not None:
        try:
            persist(journal, result)
        except ProvisionError:
            result.update(status='error', code='JOURNAL_FAILED')
    return result


def main(argv=None, **dependencies):
    result = execute(sys.argv[1:] if argv is None else argv, **dependencies)
    print(json.dumps(result, indent=2))
    return 0 if result['status'] in {'planned', 'verified', 'configured'} else 2 if result['status'] == 'blocked' else 1


if __name__ == '__main__':
    sys.exit(main())
