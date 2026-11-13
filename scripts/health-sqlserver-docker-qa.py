"""C1 Docker tooling. P1 is OFFLINE; only a separately reviewed gate may provision.

Import, plan and SQL composition never execute a process or bind a socket.
No cleanup/adopt/repair/reapply/alternate target is implemented.
"""
from __future__ import annotations

import argparse
from bisect import bisect_right
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import secrets
import socket
import stat
import subprocess
import sys
import time
import uuid

CANONICAL = Path('D:/Mavric/Health Project')
TOOL_ROOT = Path(__file__).resolve().parents[1]
DRIVER = 'scripts/health-sqlserver-docker-qa.py'
TEST = 'scripts/tests/test_health_sqlserver_docker_qa.py'
MODULE = 'scripts/verify-patient-link-management-sql.py'
TEMPLATE = 'backend/scripts/verify-sqlserver-patient-link-management.sql'
MODULE_SHA = '391A49D48E8FC49005BB601E1E3C3F9914A116B3084F5EFB46AF4268A0A376AF'
TEMPLATE_SHA = '9476CEC9A4C3906AD9E0D17EA964ED63C4B353372F4F879EEAA13049600C1D4D'
CLI = Path('C:/Program Files/Docker/Docker/resources/bin/docker.exe')
CLI_SHA = '6C699720BB9523DEDB9EB5D22A49951EA9210DBDB1314A3554029EEE9BE76896'
CONTEXT = 'desktop-linux'
ENDPOINT = 'npipe:////./pipe/dockerDesktopLinuxEngine'
DAEMON_VERSION = '29.8.2'
IMAGE_ID = 'sha256:4525e3efac9f3e241cb003bb2ff2a82818b502f37e12049d788b1a9fa7e13b7f'
IMAGE = 'mcr.microsoft.com/mssql/server@'+IMAGE_ID
NAME = 'healthproject-c1qa-20261112'
VOLUME = NAME+'-data'
DATABASE = 'health_project_c1_docker_qa_20261112'
MARKER = 'Health Project isolated Docker C1 QA; provisioned 2026-11-12; no real data'
LABEL = 'com.mavric.health.qa'
LABEL_VALUE = 'c1-20261112'
RUN_LABEL = 'com.mavric.health.qa.run'
INNER = '/opt/mssql-tools18/bin/sqlcmd'
SQL_SHELL = 'export SQLCMDPASSWORD="$MSSQL_SA_PASSWORD"; exec /opt/mssql-tools18/bin/sqlcmd "$@"'
SQL_STAGES = ('readiness','create_database','configure_database','apply_v1_v13','verify_database')
PROBE = '🦷中'*3000
HEX = re.compile(r'[0-9A-F]{64}')
CID = re.compile(r'[0-9a-f]{64}')
INFO_FORMAT = '{"version":{{json .ServerVersion}},"os":{{json .OSType}},"arch":{{json .Architecture}}}'
IMAGE_FORMAT = '{"id":{{json .Id}},"digests":{{json .RepoDigests}},"os":{{json .Os}},"arch":{{json .Architecture}},"labels":{{json .Config.Labels}}}'
VOLUME_FORMAT = '{"name":{{json .Name}},"driver":{{json .Driver}},"scope":{{json .Scope}},"labels":{{json .Labels}},"options":{{json .Options}}}'
CONTAINER_FORMAT = ('{"id":{{json .Id}},"image":{{json .Image}},"hostname":{{json .Config.Hostname}},'
    '"labels":{{json .Config.Labels}},"state":{{json .State.Status}},"running":{{json .State.Running}},'
    '"privileged":{{json .HostConfig.Privileged}},"network":{{json .HostConfig.NetworkMode}},'
    '"restart":{{json .HostConfig.RestartPolicy.Name}},"binds":{{json .HostConfig.Binds}},'
    '"ports":{{json .HostConfig.PortBindings}},"mounts":[{{range $i,$m := .Mounts}}{{if $i}},{{end}}'
    '{"type":{{json $m.Type}},"name":{{json $m.Name}},"target":{{json $m.Destination}},"rw":{{json $m.RW}}}{{end}}]}')


FAULT_CODES=frozenset('''CANONICAL_MANIFEST_INVALID CANONICAL_MIGRATION_CHANGED CANONICAL_PIN_CHANGED CANONICAL_ROOT_REQUIRED
CONTAINER_ID_REQUIRED CONTAINER_RECEIPT_INVALID CONTAINER_TARGET_INVALID CONTROLLER_FAILED DAEMON_ENDPOINT_INVALID
DAEMON_PLATFORM_INVALID DOCKER_CLI_PIN_CHANGED EVIDENCE_ALREADY_EXISTS EVIDENCE_LOCATION_INVALID EVIDENCE_WRITE_FAILED
HOST_PORT_COLLISION HOSTILE_ENVIRONMENT IMAGE_ID_OR_DIGEST_CHANGED IMAGE_LABELS_CHANGED IMAGE_LABELS_INVALID
INNER_PIN_PENDING_OR_INVALID INNER_SQLCMD_PIN_CHANGED LOCAL_PATH_REQUIRED NONCE_INVALID PROCESS_FAILED
PROCESS_RECEIPT_INVALID PROCESS_TIMEOUT_UNKNOWN PROTOCOL_INVALID PROVISION_ONE_SHOT RESOURCE_COLLISION
RESOURCE_RECEIPT_INVALID REVIEW_MANIFEST_CHANGED REVIEW_MANIFEST_INVALID REVIEW_REQUIRED SQL_BASELINE_INVALID
SQL_DATABASE_INVALID SQL_FRAME_INVALID SQL_INPUT_UTF8_INVALID SQL_INPUT_UNREPRESENTABLE SQL_POSTSTATE_INVALID SQL_STAGE_INVALID SQL_TRANSPORT_FAILED VOLUME_OWNERSHIP_INVALID WINDOWS_DOCKER_CLI_REQUIRED'''.split())


class Fault(Exception):
    """Fixed code only; never stringify native exceptions or outputs."""
    def __init__(self, code):super().__init__(code if code in FAULT_CODES else 'CONTROLLER_FAILED')


class ProvisionFailure(Fault):
    def __init__(self, report):super().__init__(report['failure']['code']);self.report=report


class CommandFailure(Fault):
    """Primary and secondary fixed-code failures, with sanitized attempt facts."""
    def __init__(self, primary, secondary):
        super().__init__(primary['code']);self.primary=primary;self.secondary=secondary


def need(value, code):
    if not value:raise Fault(code)


def sha(raw):return hashlib.sha256(raw).hexdigest().upper()


def plain(path):
    need(not path.is_symlink() and not getattr(path.stat(),'st_file_attributes',0)&getattr(stat,'FILE_ATTRIBUTE_REPARSE_POINT',1024),'LOCAL_PATH_REQUIRED')


def local(path):
    path=Path(path)
    need(path.is_absolute() and not str(path).startswith(('\\\\','//')) and '..' not in path.parts,'LOCAL_PATH_REQUIRED')
    for parent in (path,*path.parents):plain(parent)
    return path


def strict_json(text):
    def pairs(items):
        result={}
        for key,value in items:
            if key in result:raise ValueError('duplicate key')
            result[key]=value
        return result
    def constant(_):raise ValueError('non JSON constant')
    return json.loads(text,object_pairs_hook=pairs,parse_constant=constant)


def json_bytes(raw):
    try:
        need(type(raw) is bytes and len(raw)<=1_000_000,'PROTOCOL_INVALID')
        text=raw.decode('utf-8-sig',errors='strict')
        if text.endswith('\r\n'):text=text[:-2]
        elif text.endswith('\n'):text=text[:-1]
        need('\n' not in text and '\r' not in text,'PROTOCOL_INVALID')
        return strict_json(text)
    except (ValueError,UnicodeError,TypeError):raise Fault('PROTOCOL_INVALID') from None


def refs(root):
    root=local(root);need(root==CANONICAL,'CANONICAL_ROOT_REQUIRED')
    module_raw=None
    for relative,pin in [(MODULE,MODULE_SHA),(TEMPLATE,TEMPLATE_SHA)]:
        path=local(root/relative);raw=path.read_bytes();need(sha(raw)==pin,'CANONICAL_PIN_CHANGED')
        if relative==MODULE:module_raw=raw
    spec=importlib.util.spec_from_file_location('_health_docker_canonical_c1p2r1',root/MODULE)
    module=importlib.util.module_from_spec(spec);sys.modules[spec.name]=module
    # Execute the bytes just verified, with a non-main module name. Avoid a
    # second unverified read and avoid writing __pycache__ in canonical ROOT.
    exec(compile(module_raw,str(root/MODULE),'exec'),module.__dict__)
    migrations={}
    for n,entry in module.MIGRATIONS.items():
        path=local(root/'backend/src/main/resources/db/sqlserver'/entry['file']);raw=path.read_bytes()
        need(sha(raw)==entry['sha256'],'CANONICAL_MIGRATION_CHANGED')
        migrations[n]={'file':entry['file'],'sha256':entry['sha256'],'bytes':raw}
    need(set(migrations)==set(range(1,15)) and len(module.TABLE_KEYS)==37,'CANONICAL_MANIFEST_INVALID')
    return {'root':root,'module':module,'migrations':migrations}


def candidate(root):
    data=refs(root)
    manifest={'schema':'C1DockerP1-v1','mode':'PROVISION','reviewed':False,
        'ownSources':{name:sha(local(TOOL_ROOT/name).read_bytes()) for name in (DRIVER,TEST)},
        'canonical':{MODULE:MODULE_SHA,TEMPLATE:TEMPLATE_SHA,
            **{'backend/src/main/resources/db/sqlserver/'+v['file']:v['sha256'] for v in data['migrations'].values()}},
        'docker':{'cli':str(CLI),'cliSha256':CLI_SHA,'context':CONTEXT,'endpoint':ENDPOINT,'version':DAEMON_VERSION,'image':IMAGE,'imageId':IMAGE_ID,'platform':'linux/amd64'},
        'target':{'container':NAME,'hostname':NAME,'volume':VOLUME,'database':DATABASE,'marker':MARKER,'label':{LABEL:LABEL_VALUE},'publish':'127.0.0.1:14436:1433'},
        'innerSqlcmdSha256':None}
    return manifest,data


def validate_manifest(root, manifest):
    expected,data=candidate(root)
    need(type(manifest) is dict and set(manifest)==set(expected),'REVIEW_MANIFEST_INVALID')
    # Q1: pending is deliberately rejected BEFORE any process, socket or mutation.
    need(type(manifest['innerSqlcmdSha256']) is str and HEX.fullmatch(manifest['innerSqlcmdSha256']),'INNER_PIN_PENDING_OR_INVALID')
    need(type(manifest['reviewed']) is bool and manifest['reviewed'],'REVIEW_REQUIRED')
    expected['reviewed']=True;expected['innerSqlcmdSha256']=manifest['innerSqlcmdSha256']
    need(manifest==expected,'REVIEW_MANIFEST_CHANGED')
    return data


def nonce(value):
    need(type(value) is str and re.fullmatch('[0-9a-f]{32}',value),'NONCE_INVALID');return value


def engine_guard(database):
    need(database in ('master',DATABASE),'SQL_DATABASE_INVALID')
    return f"""SET NOCOUNT ON; SET XACT_ABORT ON; SET IMPLICIT_TRANSACTIONS OFF;
IF ISNULL(DB_NAME(),N'') COLLATE Latin1_General_100_BIN2<>N'{database}' OR DATALENGTH(DB_NAME())<>{len(database.encode('utf-16-le'))}
 OR ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('MachineName')),N'') COLLATE Latin1_General_100_BIN2<>N'{NAME}'
 OR ISNULL(DATALENGTH(CONVERT(nvarchar(128),SERVERPROPERTY('MachineName'))),0)<>{len(NAME.encode('utf-16-le'))}
 OR ISNULL(TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0)<>16
 OR ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('Edition')),N'') NOT LIKE N'Developer Edition%'
 OR ISNULL(CONVERT(nvarchar(40),CONNECTIONPROPERTY('net_transport')),N'')<>N'TCP'
 OR ISNULL(SUSER_SNAME(),N'') COLLATE Latin1_General_100_BIN2<>N'sa' OR DATALENGTH(SUSER_SNAME())<>4 OR ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1
 OR @@TRANCOUNT<>0 OR XACT_STATE() NOT IN (0,1) THROW 59999,N'C1Docker isolated engine/sa/TCP prerequisite',1;
"""


def owner_guard():
    return """IF NOT EXISTS(SELECT 1 FROM sys.databases d JOIN sys.database_principals p ON p.principal_id=1 AND p.sid=d.owner_sid
 WHERE d.database_id=DB_ID() AND d.owner_sid=SUSER_SID(N'sa') AND p.name=N'dbo' AND p.type='S' AND p.authentication_type=1)
 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 OR ISNULL(IS_ROLEMEMBER(N'hp_runtime_executor'),0)=1 OR ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)=1
 THROW 59999,N'C1Docker separate SQL sa CONTROL owner prerequisite',1;
"""


def configured_guard():
    return owner_guard()+f"""IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>160
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope'
 AND CONVERT(nvarchar(max),value) COLLATE Latin1_General_100_BIN2=N'{MARKER}' AND DATALENGTH(CONVERT(nvarchar(max),value))={len(MARKER.encode('utf-16-le'))})
 THROW 59999,N'C1Docker marker/compat prerequisite',1;
"""


def empty_guard():
    return """IF EXISTS(SELECT 1 FROM sys.objects WHERE is_ms_shipped=0)
 OR DATABASE_PRINCIPAL_ID(N'hp_runtime_executor') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor') IS NOT NULL
 THROW 59999,N'C1Docker fresh empty database required; no adopt/reapply',1;
"""


def post_guard():
    return """IF (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>37
 OR EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0 AND schema_id<>SCHEMA_ID(N'dbo'))
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>134
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 OR OBJECT_ID(N'dbo.usp_patient_links_list',N'P') IS NULL OR OBJECT_ID(N'dbo.usp_patient_link_edit_get') IS NOT NULL
 OR COL_LENGTH(N'dbo.patient_links',N'revision') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL
 OR (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))<>564
 OR (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') AND type='R' AND owning_principal_id=1)<>2
 OR EXISTS(SELECT 1 FROM sys.database_role_members WHERE role_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 OR EXISTS(SELECT 1 FROM sys.database_principals WHERE principal_id>4 AND type IN ('S','U','G','E','X'))
 OR NOT EXISTS(SELECT 1 FROM dbo.application_state WHERE id=1 AND mode COLLATE Latin1_General_100_BIN2=N'OPEN' AND DATALENGTH(mode)=8)
 THROW 59999,N'C1Docker V13-only poststate prerequisite',1;
"""


def frame_sql(stage, correlation, extra=''):
    return f"""SELECT N'C1DOCKER'+(SELECT N'C1DOCKER' kind,N'{stage}' stage,N'{nonce(correlation)}' nonce,CAST(1 AS bit) ok{extra},
 REPLICATE(CAST(N'🦷中' AS nvarchar(max)),3000) probe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS c1docker_frame;
"""


SQL_INPUT_LINE_LIMIT = 4094  # Bytes before LF, INCLUDING any existing CR.


def _sqlcmd_line(raw):
    head=raw.lstrip(b' \t\r\v\f')
    if head.startswith(b'\xef\xbb\xbf'):head=head[3:].lstrip(b' \t\r\v\f')
    return re.match(rb'(?i)(?::|!!|GO\b)',head) is not None


def render_sql_details(raw):
    """Pure UTF8 renderer: return bytes and inserted-LF ORIGINAL byte offsets.

    Every original byte survives in order. Only existing exterior whitespace
    may acquire a preceding LF. Original GO/SQLcmd lines remain indivisible;
    a new line must not manufacture a GO/SQLcmd directive. Comments and quoted
    tokens (including N literals, escaped quotes/]] and nested blocks) are
    indivisible on each physical line. A long unsplittable line fails closed.
    """
    need(type(raw) is bytes,'SQL_INPUT_UTF8_INVALID')
    try:raw.decode('utf-8',errors='strict')
    except UnicodeError:raise Fault('SQL_INPUT_UTF8_INVALID') from None
    result=[];offsets=[];base=0;state='normal';depth=0
    lines=raw.split(b'\n')
    for number,line in enumerate(lines):
        safe=[];i=0
        if state=='normal' and _sqlcmd_line(line):
            need(len(line)<=SQL_INPUT_LINE_LIMIT,'SQL_INPUT_UNREPRESENTABLE')
        else:
            while i<len(line):
                c=line[i];pair=line[i:i+2]
                if state=='normal':
                    if pair==b'--':state='line';i+=2;continue
                    if pair==b'/*':state='block';depth=1;i+=2;continue
                    if c==39:state='single'
                    elif c==34:state='double'
                    elif c==91:state='bracket'
                    elif c in b' \t\r\v\f':safe.append(i)
                elif state=='line':break
                elif state=='block':
                    if pair==b'/*':depth+=1;i+=2;continue
                    if pair==b'*/':
                        depth-=1;i+=2
                        if depth==0:state='normal'
                        continue
                else:
                    close={'single':39,'double':34,'bracket':93}[state]
                    if c==close:
                        if i+1<len(line) and line[i+1]==close:i+=2;continue
                        state='normal'
                i+=1
            if state=='line':state='normal'
            # Never create a new SQLcmd/GO line from a suffix of SQL text.
            safe=[p for p in safe if not _sqlcmd_line(line[p:])]
        start=0
        while len(line)-start>SQL_INPUT_LINE_LIMIT:
            index=bisect_right(safe,start+SQL_INPUT_LINE_LIMIT)-1
            need(index>=0 and safe[index]>start,'SQL_INPUT_UNREPRESENTABLE')
            end=safe[index];result.extend((line[start:end],b'\n'));offsets.append(base+end);start=end
        result.append(line[start:])
        if number<len(lines)-1:result.append(b'\n')
        base+=len(line)+1
    need(state=='normal','SQL_INPUT_UNREPRESENTABLE')
    return b''.join(result),tuple(offsets)


def render_sql(raw):
    return render_sql_details(raw)[0]


def sql_raw(data, stage, correlation):
    need(stage in SQL_STAGES,'SQL_STAGE_INVALID');nonce(correlation)
    prefix=b':On Error exit\n'
    if stage=='readiness':
        body=engine_guard('master')+f"IF DB_ID(N'{DATABASE}') IS NOT NULL THROW 59999,N'C1Docker DB collision',1;\n"+frame_sql(stage,correlation)
    elif stage=='create_database':
        body=engine_guard('master')+f"IF DB_ID(N'{DATABASE}') IS NOT NULL THROW 59999,N'C1Docker DB collision',1;\nGO\nCREATE DATABASE [{DATABASE}];\nGO\nIF DB_ID(N'{DATABASE}') IS NULL THROW 59999,N'C1Docker DB creation receipt missing',1;\n"+frame_sql(stage,correlation)
    elif stage=='configure_database':
        body=engine_guard(DATABASE)+owner_guard()+empty_guard()+f"""IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope') THROW 59999,N'C1Docker marker collision',1;
ALTER DATABASE [{DATABASE}] SET COMPATIBILITY_LEVEL=160;
EXEC sys.sp_addextendedproperty @name=N'health_project_scope',@value=N'{MARKER}';
"""+configured_guard()+frame_sql(stage,correlation)
    elif stage=='apply_v1_v13':
        opening=engine_guard(DATABASE)+configured_guard()+empty_guard()+"BEGIN TRANSACTION;\nGO\n"
        # Concatenate ORIGINAL bytes without newline/comment normalization.
        # A UTF-8 BOM belongs to the file boundary, never to a SQL batch.
        # Consume exactly one leading BOM per source; preserve literal U+FEFF.
        migrations=b'\n'.join(data['migrations'][n]['bytes'].removeprefix(b'\xef\xbb\xbf') for n in range(1,14))
        ending="\nIF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'C1Docker migration TX lost',1;\n"+post_guard()+"COMMIT TRANSACTION;\n"+frame_sql(stage,correlation)
        return prefix+opening.encode('utf-8')+migrations+ending.encode('utf-8')
    else:
        guards,fields=data['module'].baseline_parts()
        body=engine_guard(DATABASE)+configured_guard()+post_guard()+guards+f"\nDECLARE @fingerprints nvarchar(max)=(SELECT {fields} FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);\n"+frame_sql(stage,correlation,",CAST(37 AS int) tables,CAST(134 AS int) procedures,CAST(31 AS int) triggers,CAST(564 AS int) roleAcl,JSON_QUERY(@fingerprints) fingerprints")
    return prefix+body.encode('utf-8')


def sql(data, stage, correlation):
    return render_sql(sql_raw(data,stage,correlation))


def sql_frame(response, stage, correlation, data):
    need(type(response.returncode) is int and response.returncode==0 and response.stderr==b'','SQL_TRANSPORT_FAILED')
    raw=response.stdout;need(type(raw) is bytes,'PROTOCOL_INVALID')
    header=b'c1docker_frame\n--------------\n'
    if raw.startswith(header):raw=raw[len(header):]
    elif raw.startswith(header.replace(b'\n',b'\r\n')):raw=raw[len(header.replace(b'\n',b'\r\n')):]
    need(raw.startswith(b'C1DOCKER'),'PROTOCOL_INVALID');value=json_bytes(raw[len(b'C1DOCKER'):])
    expected={'kind','stage','nonce','ok','probe'}|({'tables','procedures','triggers','roleAcl','fingerprints'} if stage=='verify_database' else set())
    need(type(value) is dict and set(value)==expected and value['kind']=='C1DOCKER' and value['stage']==stage and value['nonce']==correlation and type(value['ok']) is bool and value['ok'] and value['probe']==PROBE,'SQL_FRAME_INVALID')
    if stage=='verify_database':
        need(all(type(value[k]) is int and value[k]==v for k,v in [('tables',37),('procedures',134),('triggers',31),('roleAcl',564)]),'SQL_POSTSTATE_INVALID')
        hashes=value['fingerprints'];need(type(hashes) is dict and set(hashes)==data['module'].FINGERPRINT_KEYS and all(type(h) is str and HEX.fullmatch(h) for h in hashes.values()),'SQL_BASELINE_INVALID')
    return {k:v for k,v in value.items() if k not in ('probe','nonce')}


def plan(root):
    manifest,data=candidate(root)
    return {'status':'OFFLINE_PLAN','manifestCandidate':manifest,'provisionBlocked':True,
        'reason':'Inner sqlcmd SHA pending and supervisor review required; Q1 gate precedes all processes.',
        'sequence':['refs_manifest','context_daemon_image','absence_port','volume_create','container_create','start_once','inner_pin','readiness','create_database','configure_database','apply_v1_v13','verify_fresh_connection'],
        'migrationVersions':list(range(1,14)),'V14Executed':False,
        'sql':[{'stage':stage,'sha256':sha(sql(data,stage,'0'*32)),'bytes':len(sql(data,stage,'0'*32))} for stage in SQL_STAGES],
        'readiness':'One bounded readonly sqlcmd connection; no automatic retry after failure.',
        'recovery':'UNKNOWN retains resources and stops; readonly reconciliation requires a separate gate.'}


def child_environment(source=None):
    source=os.environ if source is None else source
    need(not any(k.upper().startswith(('DOCKER_','SQLCMD')) or k.upper()=='MSSQL_SA_PASSWORD' for k in source),'HOSTILE_ENVIRONMENT')
    env={'SYSTEMROOT':r'C:\Windows','WINDIR':r'C:\Windows','SYSTEMDRIVE':'C:','PATH':str(CLI.parent)+r';C:\Windows\System32'}
    for key in ('USERPROFILE','APPDATA','LOCALAPPDATA','TEMP','TMP'):
        value=next((v for k,v in source.items() if k.upper()==key),None)
        if value is not None:env[key]=str(local(Path(value)))
    return env


def cli_executable():
    path=local(CLI);need(path.is_file() and sha(path.read_bytes())==CLI_SHA,'DOCKER_CLI_PIN_CHANGED');return str(path)


def port_available():
    # Called ONLY by approved provisioning. No connect/send or remote target.
    try:
        with socket.socket(socket.AF_INET,socket.SOCK_STREAM) as channel:
            if hasattr(socket,'SO_EXCLUSIVEADDRUSE'):channel.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
            channel.bind(('127.0.0.1',14436))
    except OSError:raise Fault('HOST_PORT_COLLISION') from None


class Evidence:
    def __init__(self, directory, root, manifest):
        self.path=Path(directory);self.root=Path(root);self.order=0;self.used=False
        try:
            self._location();need(not self.path.exists(),'EVIDENCE_ALREADY_EXISTS');self.path.mkdir(exist_ok=False)
            self.write('manifest.json',manifest);self.write('journal.jsonl',b'')
        except Fault:raise
        except Exception:raise Fault('EVIDENCE_WRITE_FAILED') from None

    def _location(self):
        need(self.path.is_absolute() and '..' not in self.path.parts and not str(self.path).startswith(('\\\\','//'))
             and re.fullmatch(r'C1Docker(?:P1)?-[A-Za-z0-9_-]{1,100}',self.path.name),'EVIDENCE_LOCATION_INVALID')
        need(self.path.parent in (self.root/'tmp',Path(os.environ.get('TEMP',''))),'EVIDENCE_LOCATION_INVALID');local(self.path.parent)
        if self.path.exists():plain(self.path)

    def write(self, name, value):
        self._location();need(re.fullmatch(r'[A-Za-z0-9_.-]+',name),'EVIDENCE_LOCATION_INVALID')
        raw=value if type(value) is bytes else (json.dumps(value,ensure_ascii=True,separators=(',',':'))+'\n').encode()
        pending=self.path/(name+'.pending')
        with pending.open('xb') as stream:stream.write(raw);stream.flush();os.fsync(stream.fileno())
        os.link(pending,self.path/name)
        return {'file':name,'sha256':sha(raw)}

    def append(self, value):
        self._location();path=local(self.path/'journal.jsonl')
        with path.open('ab') as stream:
            stream.write((json.dumps(value,separators=(',',':'))+'\n').encode());stream.flush();os.fsync(stream.fileno())

    def begin(self, phase, args, mutation, ids, payload, correlation=None):
        self.order+=1;name=f'{self.order:04}'
        entry={'order':self.order,'phase':phase,'nonce':correlation,'mutation':mutation,'ids':dict(ids),'argv':args,'sql':None}
        if payload is not None:entry['sql']=self.write(name+'.sql',payload)
        record=self.write(name+'-attempt.json',entry);self.append({'event':'ATTEMPT',**entry,'record':record});return entry

    def end(self, entry, result):
        record=self.write(f"{entry['order']:04}-result.json",{**entry,**result});self.append({'event':'RESULT','order':entry['order'],'record':record})

    def finish(self, report):
        self.append({'event':'SUMMARY_INTENT','status':report['status']});self.write('summary.json',report)


def output_metadata(response):
    data={'exit':None,'stdout':None,'stderr':None}
    if response is None:return data
    if type(response.returncode) is int:data['exit']=response.returncode
    for name in ('stdout','stderr'):
        raw=getattr(response,name,None)
        if type(raw) is bytes:data[name]={'bytes':len(raw),'sha256':sha(raw)}
    return data


class Provisioner:
    def __init__(self, root, manifest, evidence_dir, *, run=None, resolve=None, port_check=None, environment=None, secret=None, clock=None):
        # Admission before environment, evidence creation, process or socket.
        self.data=validate_manifest(root,manifest);self.root=Path(root);self.manifest=manifest
        self.env=child_environment(environment);self.evidence=Evidence(evidence_dir,root,manifest)
        self.run=run or subprocess.run;self.resolve=resolve or cli_executable;self.port_check=port_check or port_available
        self.secret=secret or (lambda:'C1qa!'+secrets.token_hex(32));self.clock=clock or time.monotonic
        self.run_id=uuid.uuid4().hex;self.ids={'volume':VOLUME,'container':None};self.changed=False;self.receipts=[];self.image_labels=None
        self.attempts=[];self.last_nonce=None

    def failure_info(self, code, stage, result=None):
        # Only facts known from this attempted call; unknown native exit/buffers
        # stay null. Never put exception text or unvalidated output in a report.
        return {'code':code,'phase':getattr(self,'last_phase','preflight'),
                'lastAttemptOrder':self.evidence.order,'nonce':self.last_nonce,
                'ids':dict(self.ids),'stage':stage,
                'transport':result['transport'] if result else output_metadata(None),
                'elapsedSeconds':result['elapsedSeconds'] if result else None}

    def command(self, phase, args, validate, *, mutation=False, payload=None, password=None, sql_nonce=None):
        self.last_phase=phase;self.last_nonce=sql_nonce
        invocation=[self.resolve(),'--context',CONTEXT,*args]
        try:entry=self.evidence.begin(phase,invocation,mutation,self.ids,payload,sql_nonce)
        except Exception:raise Fault('EVIDENCE_WRITE_FAILED') from None
        attempt={**entry,'processStarted':False,'resultRecorded':False};self.attempts.append(attempt)
        response=None;started=self.clock();outcome=None;fault=None
        try:
            env=dict(self.env)
            if password is not None:env['MSSQL_SA_PASSWORD']=password
            if mutation:self.changed=True
            attempt['processStarted']=True
            response=self.run(invocation,input=payload,capture_output=True,shell=False,env=env,timeout=180,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            need(type(response.returncode) is int and response.returncode==0 and response.stderr==b'','PROCESS_RECEIPT_INVALID')
            outcome=validate(response)
        except subprocess.TimeoutExpired as error:
            response=subprocess.CompletedProcess([],None,error.output,error.stderr);fault=Fault('PROCESS_TIMEOUT_UNKNOWN')
        except Fault as error:fault=error
        except Exception:fault=Fault('PROCESS_FAILED')
        result={'elapsedSeconds':max(0,self.clock()-started),'transport':output_metadata(response),'receipt':outcome,'code':str(fault) if fault else None}
        attempt.update(result);secondary=[]
        # Freeze a known native/validation cause BEFORE attempting storage.
        primary=self.failure_info(str(fault),'process',result) if fault else None
        try:
            self.evidence.end(entry,result);attempt['resultRecorded']=True
        except Exception:
            storage=self.failure_info('EVIDENCE_WRITE_FAILED','result_evidence',result)
            if primary is None:primary=storage
            else:secondary.append(storage)
        if primary is not None:raise CommandFailure(primary,secondary)
        self.receipts.append({'phase':phase,'order':entry['order'],'ids':dict(self.ids),'receipt':outcome})
        return outcome

    def json_command(self, phase, args, check):
        def validate(response):
            value=json_bytes(response.stdout);check(value);return {'validated':True}
        return self.command(phase,args,validate)

    def image(self):
        def check(value):
            need(type(value) is dict and set(value)=={'id','digests','os','arch','labels'} and value['id']==IMAGE_ID and value['os']=='linux' and value['arch']=='amd64' and type(value['digests']) is list and all(type(v) is str for v in value['digests']) and IMAGE in value['digests'],'IMAGE_ID_OR_DIGEST_CHANGED')
            labels=value['labels'];need(labels is None or type(labels) is dict,'IMAGE_LABELS_INVALID')
            labels={} if labels is None else labels
            need(all(type(k) is str and type(v) is str for k,v in labels.items()),'IMAGE_LABELS_INVALID')
            if self.image_labels is None:self.image_labels=labels
            else:need(self.image_labels==labels,'IMAGE_LABELS_CHANGED')
        self.json_command('image_check',['image','inspect',IMAGE_ID,'--format',IMAGE_FORMAT],check)

    def labels(self):return {LABEL:LABEL_VALUE,RUN_LABEL:self.run_id}

    def host_port(self):
        self.last_phase='host_port_check';self.port_check()

    def volume(self):
        def check(value):
            need(type(value) is dict and set(value)=={'name','driver','scope','labels','options'} and value['name']==VOLUME and value['driver']=='local' and value['scope']=='local' and value['labels']==self.labels() and value['options'] in (None,{}),'VOLUME_OWNERSHIP_INVALID')
        self.json_command('volume_check',['volume','inspect',VOLUME,'--format',VOLUME_FORMAT],check)

    def container(self, state):
        cid=self.ids['container'];need(type(cid) is str and CID.fullmatch(cid),'CONTAINER_ID_REQUIRED')
        def check(v):
            expected={'id':cid,'image':IMAGE_ID,'hostname':NAME,'labels':{**self.image_labels,**self.labels()},'state':state,'running':state=='running','privileged':False,'network':'bridge','restart':'no','binds':None,'ports':{'1433/tcp':[{'HostIp':'127.0.0.1','HostPort':'14436'}]},'mounts':[{'type':'volume','name':VOLUME,'target':'/var/opt/mssql','rw':True}]}
            need(type(v) is dict and v==expected and type(v['running']) is bool and type(v['privileged']) is bool and type(v['mounts'][0]['rw']) is bool,'CONTAINER_TARGET_INVALID')
        self.json_command('container_check',['container','inspect',cid,'--format',CONTAINER_FORMAT],check)

    def absent(self, kind, args):
        def check(response):need(response.stdout in (b'',b'\n',b'\r\n'),'RESOURCE_COLLISION');return {'absent':True}
        self.command('absence_'+kind,args,check)

    def inner_pin(self):
        def check(response):
            match=re.fullmatch(rb'([0-9a-f]{64})  /opt/mssql-tools18/bin/sqlcmd(?:\r?\n)?',response.stdout)
            need(match and match.group(1).decode().upper()==self.manifest['innerSqlcmdSha256'],'INNER_SQLCMD_PIN_CHANGED');return {'pinned':True}
        self.command('inner_pin',['exec',self.ids['container'],'/usr/bin/sha256sum',INNER],check)

    def sql_command(self, stage):
        self.image();self.volume();self.container('running');self.inner_pin()
        correlation=uuid.uuid4().hex;payload=sql(self.data,stage,correlation)
        database='master' if stage in ('readiness','create_database') else DATABASE
        args=['exec','--interactive',self.ids['container'],'/bin/sh','-c',SQL_SHELL,'c1sql',
              '-S','tcp:127.0.0.1,1433','-U','sa','-d',database,'-C','-b','-V','11','-r','1','-f','65001','-y','0','-w','65535','-x','-X1','-l','30','-t','120']
        return self.command(stage,args,lambda response:sql_frame(response,stage,correlation,self.data),mutation=stage in ('create_database','configure_database','apply_v1_v13'),payload=payload,sql_nonce=correlation)

    def execute(self):
        need(not self.evidence.used,'PROVISION_ONE_SHOT');self.evidence.used=True;failure=None;secondary=[];baseline=None;phase='preflight'
        try:
            self.json_command('context',['context','inspect',CONTEXT,'--format','{{json .Endpoints.docker.Host}}'],lambda value:need(value==ENDPOINT,'DAEMON_ENDPOINT_INVALID'))
            self.json_command('daemon',['info','--format',INFO_FORMAT],lambda value:need(type(value) is dict and set(value)=={'version','os','arch'} and value['version']==DAEMON_VERSION and value['os']=='linux' and value['arch'] in ('amd64','x86_64'),'DAEMON_PLATFORM_INVALID'))
            self.image()
            self.absent('container',['container','ls','--all','--filter','name=^/'+NAME+'$','--format','{{json .Names}}'])
            self.absent('volume',['volume','ls','--filter','name=^'+VOLUME+'$','--format','{{json .Name}}'])
            self.absent('docker_port',['container','ls','--all','--filter','publish=14436','--format','{{json .ID}}'])
            self.host_port()
            phase='volume_create';self.image()
            self.command(phase,['volume','create','--driver','local','--label',LABEL+'='+LABEL_VALUE,'--label',RUN_LABEL+'='+self.run_id,VOLUME],lambda r:self._exact(r,VOLUME),mutation=True)
            self.image();self.volume()
            self.absent('container',['container','ls','--all','--filter','name=^/'+NAME+'$','--format','{{json .Names}}']);self.host_port()
            phase='container_create'
            def created(response):
                match=re.fullmatch(rb'([0-9a-f]{64})(?:\r?\n)?',response.stdout)
                need(match is not None,'CONTAINER_RECEIPT_INVALID');value=match.group(1).decode('ascii');self.ids['container']=value;return {'id':value}
            self.command(phase,['container','create','--pull=never','--platform','linux/amd64','--name',NAME,'--hostname',NAME,'--label',LABEL+'='+LABEL_VALUE,'--label',RUN_LABEL+'='+self.run_id,'--publish','127.0.0.1:14436:1433','--mount','type=volume,source='+VOLUME+',target=/var/opt/mssql','--network','bridge','--restart=no','--env','ACCEPT_EULA=Y','--env','MSSQL_PID=Developer','--env','MSSQL_SA_PASSWORD',IMAGE],created,mutation=True,password=self.secret())
            phase='start_once';self.image();self.volume();self.container('created');self.host_port()
            self.command(phase,['container','start',self.ids['container']],lambda r:self._exact(r,self.ids['container']),mutation=True)
            for phase in SQL_STAGES:baseline=self.sql_command(phase)
        except CommandFailure as error:failure=error.primary;secondary=error.secondary
        except Fault as error:failure=self.failure_info(str(error),'prepare')
        except Exception:failure=self.failure_info('CONTROLLER_FAILED','prepare')
        uncertain=self.changed or (failure is not None and failure['code']=='PROCESS_TIMEOUT_UNKNOWN')
        report={'status':('UNKNOWN' if uncertain else 'FAIL') if failure else 'PASS','failure':failure,'secondaryFailures':secondary,'attempts':self.attempts,'resources':dict(self.ids),'receipts':self.receipts,'baseline':baseline if not failure else None,
                'evidence':{'directory':str(self.evidence.path),'journal':str(self.evidence.path/'journal.jsonl'),'summary':str(self.evidence.path/'summary.json'),'summaryWritten':True},
                'cleanupAttempted':False,'retryAttempted':False,'scope':'Docker NEW baseline only; not Windows/TLS/JDBC/business/PRE111 proof.'}
        try:self.evidence.finish(report)
        except Exception:
            storage=self.failure_info('EVIDENCE_WRITE_FAILED','summary_evidence')
            if failure is None:report['failure']=storage
            else:
                report['secondaryFailures'].append(storage);report['evidenceFailure']='EVIDENCE_WRITE_FAILED'
            report['status']='UNKNOWN' if uncertain else 'FAIL';report['evidence']['summaryWritten']=False
        if report['failure']:raise ProvisionFailure(report)
        return report

    @staticmethod
    def _exact(response, expected):
        need(response.stdout in (expected.encode(),expected.encode()+b'\n',expected.encode()+b'\r\n'),'RESOURCE_RECEIPT_INVALID');return {'id':expected}


def main(argv=None):
    parser=argparse.ArgumentParser(description='Offline plan / separately approved one-shot isolated SQL Docker provisioning')
    sub=parser.add_subparsers(dest='mode',required=True)
    for mode in ('PLAN','PROVISION'):
        entry=sub.add_parser(mode);entry.add_argument('--canonical-root',required=True)
        if mode=='PROVISION':entry.add_argument('--manifest',required=True);entry.add_argument('--evidence-dir',required=True)
    args=parser.parse_args(argv)
    if args.mode=='PLAN':result=plan(Path(args.canonical_root))
    else:
        need(os.name=='nt','WINDOWS_DOCKER_CLI_REQUIRED')
        manifest=strict_json(local(Path(args.manifest)).read_text(encoding='utf-8-sig'))
        result=Provisioner(Path(args.canonical_root),manifest,Path(args.evidence_dir)).execute()
    print(json.dumps(result,ensure_ascii=True));return 0


if __name__=='__main__':
    try:raise SystemExit(main())
    except ProvisionFailure as error:print(json.dumps(error.report,ensure_ascii=True));raise SystemExit(1)
    except Fault as error:print(json.dumps({'status':'FAIL','code':str(error)}));raise SystemExit(1)
    except Exception:print(json.dumps({'status':'FAIL','code':'CONTROLLER_FAILED'}));raise SystemExit(1)
