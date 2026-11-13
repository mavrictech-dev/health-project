"""Reviewed future PRE rollback controller. Import/generation/tests never start SQL.

Current Dispatch is OFFLINE. A later gate must review these exact hashes and
authorize transport; this file has no apply/commit/repair/POST implementation.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
import ntpath
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import uuid

MODE = 'PRE_APLICACION'
SERVER = r'lpc:.\HEALTHPROJECTQA'
DATABASE = 'health_project_sqlserver_qa_isolated_20261105'
SQLCMD = Path(r'C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE')
SQLCMD_SHA256 = '7220B526AB97B0A5B30ED7B09C497AB7FAD39141090F8801D68691C38FF248DA'
TEMPLATE = 'backend/scripts/verify-sqlserver-patient-link-management.sql'
DRIVER = 'scripts/verify-patient-link-management-sql.py'
TEST = 'scripts/tests/test_patient_link_management_sql_verifier.py'
MIGRATIONS = {1: {'file': 'V1__schema.sql', 'sha256': 'ED1DCB3E6BD4F2AC1F9B11DE9AA7D1053DB0E71CA3610E21801CC60D51FE4A0A'}, 2: {'file': 'V2__catalog_seed.sql', 'sha256': 'F672C8856AB6A150AE1967E85B8BAF9DF07F2615F4DB8445263F11F322A1A885'}, 3: {'file': 'V3__identity_infrastructure_procedures.sql', 'sha256': 'B4EBE83471354E2027315D95E1657AFDE72AD2C19C508E2EF764C2356F940CE0'}, 4: {'file': 'V4__saas_organization_procedures.sql', 'sha256': '9640CD1215F27EB6789E7B79C11291AA37BC89F61B2112F678D364C2112654DC'}, 5: {'file': 'V5__clinical_procedures.sql', 'sha256': 'D2352D8FE6A6F8F84C62179F7A643027866A17229064B9B0CE3D96F60FCD9ECE'}, 6: {'file': 'V6__operations_procedures.sql', 'sha256': '5B007234AFCE7A435FE9220111249E537A22B467ED922CFDB45C3BEC69949458'}, 7: {'file': 'V7__audit_triggers.sql', 'sha256': 'C5657FA2329AB306D93DDDA99EFCE52F95285575C8437295666B35670DBADF1F'}, 8: {'file': 'V8__execution_permissions.sql', 'sha256': '63CA532AD7F16650DFD27891A7093EA4B0CEE3C264CA35537D81A9100C067F4E'}, 9: {'file': 'V9__appointment_window_days.sql', 'sha256': '9A0C1F96B66ADB7DE833310A5BDA1797CAE9C0F39E7A2D435CDE7EEBB62EDC04'}, 10: {'file': 'V10__jdbc_implicit_transaction_boundary.sql', 'sha256': '486862353A929D799EF54007B4DB8A005F438D60502C0E8970297F7238690CA0'}, 11: {'file': 'V11__canonical_generated_uuids.sql', 'sha256': 'F512C6D44917612B53850E29C320C85925A3C92936951BC1A5CD39807AD72EF1'}, 12: {'file': 'V12__independent_professional_conflict.sql', 'sha256': '516F1BD3583B51792A75045C90342FAB8236C2D7830B154EF811939980876438'}, 13: {'file': 'V13__patient_links_read.sql', 'sha256': '667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51'}, 14: {'file': 'V14__patient_link_revision.sql', 'sha256': '418B1C1B864DE9A6E7AC20E0F641630422A8D2451B3D42F7E9B97FB835B0EA9A'}}  # Immutable canonical source pins, not installed catalog measurements.
TABLE_KEYS = {'users': ['id'], 'plans': ['id'], 'plan_versions': ['plan_id', 'version'], 'tenants': ['id'], 'subscriptions': ['tenant_id'], 'specialties': ['code'], 'tenant_specialties': ['tenant_id', 'specialty_code'], 'branches': ['id'], 'areas': ['id'], 'memberships': ['tenant_id', 'user_id'], 'membership_branches': ['tenant_id', 'user_id', 'branch_id'], 'membership_specialties': ['tenant_id', 'user_id', 'specialty_code'], 'auth_sessions': ['token_hash'], 'audit_events': ['id'], 'saas_invoices': ['id'], 'patients': ['id'], 'patient_links': ['tenant_id', 'patient_id', 'user_id'], 'appointments': ['id'], 'encounters': ['id'], 'clinical_entries': ['id'], 'documents': ['id'], 'finance_movements': ['id'], 'stock_lots': ['id'], 'stock_movements': ['id'], 'stock_transfers': ['id'], 'hospital_resources': ['id'], 'admissions': ['id'], 'workflow_cases': ['id'], 'workflow_history': ['id'], 'workflow_definitions': ['type'], 'request_traces': ['id'], 'identity_tokens': ['token_hash'], 'mail_outbox': ['id'], 'support_tickets': ['id'], 'support_comments': ['id'], 'application_state': ['id'], 'health_samples': ['id']}  # Closed V1 primary-key order; no user-supplied identifiers.
PROBE = '🦷中' * 3000
SECTIONS = ('COMMON', 'BASELINE', 'PRE', 'AFTER_V14', 'AUDIT_FAILURE', 'CASE')
HEADER = 'c1p2_frame\n----------\n'
DOOMED = re.compile(r'Msg 3998, Level 16, State 1,(?: Server [^\r\n]+,)? Line [0-9]+\r?\nUncommittable transaction is detected at the end of the batch\. The transaction is rolled back\.')


class Failure(Exception):
    """Fixed code only, never engine stderr/SQL/row values/credentials."""


def need(condition, code):
    if not condition:
        raise Failure(code)


def digest(raw):
    return hashlib.sha256(raw).hexdigest().upper()


def strict_json(text):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError('duplicate JSON key')
            result[key] = value
        return result
    def constant(_):
        raise ValueError('non-JSON constant')
    return json.loads(text, object_pairs_hook=pairs, parse_constant=constant)


def command(value):
    need(type(value) is str and value == MODE, 'MODE_INVALID')
    return value


@dataclass(frozen=True)
class Phase:
    name: str
    family: str
    error: int = 0
    scenario: str = 'negative'
    operation: str = 'write'
    domain: str = 'HUMAN'
    actor_roles: str = '["ADM"]'
    target_roles: str = '["PAC"]'
    fixture: str = ''
    input_sql: str = ''
    context: str = ''
    checks: int = 1


SEED = "INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes,revision) VALUES(@tenant,@patient,@target,@relationship,1,@scopes,7);"
OFF7 = "SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":7,\"active\":false}';"


def matrix():
    cases = [
        Phase('sequence_human_adm', 'sequential_lifecycle', scenario='sequence', checks=7),
        Phase('sequence_animal_rec', 'sequential_lifecycle', scenario='sequence', domain='ANIMAL', actor_roles='["REC"]', target_roles='["PAC","RES"]', checks=7),
        Phase('sequence_human_res', 'sequential_lifecycle', scenario='sequence', actor_roles='["REC"]', target_roles='["RES"]', checks=7),
        Phase('sequence_animal_adm', 'sequential_lifecycle', scenario='sequence', domain='ANIMAL', checks=7),
        Phase('set_utf16_boundary', 'set_value_boundary', scenario='one_set', fixture="SET @relationship=REPLICATE(CAST(N'🦷' AS nvarchar(max)),40);", checks=2),
        Phase('set_trial_nbsp', 'set_value_boundary', scenario='one_set', fixture="UPDATE dbo.tenants SET status=N'TRIAL' WHERE id=@tenant;SET @relationship=NCHAR(160)+N'Tutor'+NCHAR(160);", checks=2),
        Phase('sequential_stale', 'sequential_not_race', 51003, scenario='sequential_stale', checks=2),
        Phase('create_existing', 'cas_error', 51003, fixture=SEED),
        Phase('stale_set', 'cas_error', 51003, fixture=SEED, input_sql="SET @input=REPLACE(@input,N'\"expectedRevision\":0',N'\"expectedRevision\":6');"),
        Phase('set_missing_positive_revision', 'cas_error', 51002, input_sql="SET @input=REPLACE(@input,N'\"expectedRevision\":0',N'\"expectedRevision\":1');"),
        Phase('withdraw_missing', 'cas_error', 51002, input_sql=OFF7),
        Phase('withdraw_missing_zero', 'cas_error', 51002, input_sql="SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":0,\"active\":false}';"),
        Phase('withdraw_create_version', 'cas_error', 51003, fixture=SEED, input_sql="SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":0,\"active\":false}';"),
        Phase('withdraw_stale', 'cas_error', 51003, fixture=SEED, input_sql="SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":6,\"active\":false}';"),
        Phase('intmax_set', 'overflow', 51003, fixture=SEED+" UPDATE dbo.patient_links SET revision=2147483647 WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;", input_sql="SET @input=REPLACE(@input,N'\"expectedRevision\":0',N'\"expectedRevision\":2147483647');"),
        Phase('intmax_withdraw', 'overflow', 51003, fixture=SEED+" UPDATE dbo.patient_links SET revision=2147483647 WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;", input_sql="SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":2147483647,\"active\":false}';"),
    ]
    for name, fixture in [
        ('empty', "SET @relationship=N'';SET @scopes=N'[]';"),
        ('unknown', "SET @scopes=N'[\"UNKNOWN\"]';"),
        ('duplicates', "SET @scopes=N'[\"DOCUMENTS\",\"DOCUMENTS\"]';"),
        ('scalar', "SET @scopes=N'true';"),
        ('object', "SET @scopes=N'{\"old\":null}';"),
        ('json_null', "SET @scopes=N'null';"),
        ('inactive', "UPDATE dbo.users SET active=0 WHERE id=@target;"),
        ('unverified', "UPDATE dbo.users SET email_verified=0 WHERE id=@target;"),
        ('no_membership', "DELETE dbo.memberships WHERE tenant_id=@tenant AND user_id=@target;"),
        ('changed_roles', "UPDATE dbo.memberships SET roles=N'[\"PRO\"]' WHERE tenant_id=@tenant AND user_id=@target;"),
        ('platform', "UPDATE dbo.users SET platform_role=N'SOP' WHERE id=@target;"),
    ]:
        cases.append(Phase('history_'+name, 'historical_withdraw_and_read', scenario='history', fixture=fixture+SEED, checks=2))
    replacements = [
        ('active_missing', '"active":true,', ''), ('active_null', '"active":true', '"active":null'),
        ('active_coercion', '"active":true', '"active":"true"'),
        ('duplicate_key', '"active":true', '"active":true,"active":true'),
        ('extra_key', '"active":true', '"active":true,"tenantId":"x"'),
        ('key_case', '"active":true', '"Active":true'),
        ('null_relationship', '"relationship":"Tutor 🦷中"', '"relationship":null'),
        ('scope_unknown', '["BILLING","DOCUMENTS","APPOINTMENTS"]', '["UNKNOWN"]'),
        ('scope_duplicate', '["BILLING","DOCUMENTS","APPOINTMENTS"]', '["DOCUMENTS","DOCUMENTS"]'),
        ('scope_nonstring', '["BILLING","DOCUMENTS","APPOINTMENTS"]', '[true]'),
        ('scope_empty', '["BILLING","DOCUMENTS","APPOINTMENTS"]', '[]'),
        ('scope_object', '["BILLING","DOCUMENTS","APPOINTMENTS"]', '{}'),
    ]
    for name, old, new in replacements:
        sql = "SET @input=REPLACE(@input,N'"+old.replace("'", "''")+"',N'"+new.replace("'", "''")+"');"
        cases.append(Phase('json_'+name, 'strict_json', 51000, input_sql=sql))
    for name, value in [('missing', None), ('fraction', '1.0'), ('exponent', '1e0'), ('string', '"0"'), ('boolean', 'true'), ('minus_zero', '-0'), ('negative', '-1'), ('overflow', '2147483648'), ('null', 'null')]:
        old='"expectedRevision":0,' if value is None else '"expectedRevision":0'
        new='' if value is None else '"expectedRevision":'+value
        cases.append(Phase('revision_'+name, 'lexical_revision', 51000, input_sql="SET @input=REPLACE(@input,N'"+old+"',N'"+new+"');"))
    cases += [
        Phase('json_root_array', 'strict_json', 51000, input_sql="SET @input=N'[]';"),
        Phase('json_root_null', 'strict_json', 51000, input_sql="SET @input=N'null';"),
        Phase('json_input_null', 'strict_json', 51000, input_sql="SET @input=NULL;"),
        Phase('json_escaped_duplicate', 'strict_json', 51000, input_sql="SET @input=REPLACE(@input,N'\"active\":true',N'\"active\":true,\"act\\u0069ve\":true');"),
        Phase('json_key_padding', 'strict_json', 51000, input_sql="SET @input=REPLACE(@input,N'\"active\":true',N'\"active \":true');"),
        Phase('withdraw_extra_fields', 'strict_withdrawal', 51000, fixture=SEED, input_sql="SET @input=N'{\"userId\":\"'+@target+N'\",\"expectedRevision\":7,\"active\":false,\"scopes\":null}';"),
        Phase('relationship_whitespace', 'utf16_whitespace', 51000, fixture="SET @relationship=N' '+NCHAR(160)+NCHAR(8192);"),
        Phase('relationship_overflow', 'utf16_whitespace', 51000, fixture="SET @relationship=REPLICATE(CAST(N'🦷' AS nvarchar(max)),40)+N' ';"),
        Phase('json_id_long', 'complete_id_before_conversion', 51000, input_sql="SET @input=REPLACE(@input,@target,@target+N'suffix');"),
        Phase('json_id_case', 'complete_id_before_conversion', 51000, input_sql="SET @input=REPLACE(@input,@target,N'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA');"),
        Phase('patient_id_case', 'received_char_id', 51000, fixture="SET @selected='AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA';"),
        Phase('patient_foreign', 'tenant_isolation', 51002, fixture='SET @selected=@foreign;'),
        Phase('patient_missing', 'tenant_isolation', 51002, fixture='SET @selected=@missing;'),
    ]
    for name, fixture in [
        ('inactive', 'UPDATE dbo.users SET active=0 WHERE id=@target;'),
        ('unverified', 'UPDATE dbo.users SET email_verified=0 WHERE id=@target;'),
        ('platform', "UPDATE dbo.users SET platform_role=N'SAD' WHERE id=@target;"),
        ('membership_missing', 'DELETE dbo.memberships WHERE tenant_id=@tenant AND user_id=@target;'),
        ('membership_invited', "UPDATE dbo.memberships SET status=N'INVITED' WHERE tenant_id=@tenant AND user_id=@target;"),
        ('membership_inactive', "UPDATE dbo.memberships SET status=N'INACTIVE' WHERE tenant_id=@tenant AND user_id=@target;"),
        ('mixed_roles', "UPDATE dbo.memberships SET roles=N'[\"ADM\",\"PAC\"]' WHERE tenant_id=@tenant AND user_id=@target;"),
        ('duplicate_roles', "UPDATE dbo.memberships SET roles=N'[\"PAC\",\"PAC\"]' WHERE tenant_id=@tenant AND user_id=@target;"),
    ]:
        cases.append(Phase('eligibility_'+name, 'recipient_current_eligibility', 51002, fixture=fixture))
    for name, fixture in [
        ('inactive', 'UPDATE dbo.users SET active=0 WHERE id=@actor;'),
        ('unverified', 'UPDATE dbo.users SET email_verified=0 WHERE id=@actor;'),
        ('platform', "UPDATE dbo.users SET platform_role=N'SOP' WHERE id=@actor;"),
        ('membership_inactive', "UPDATE dbo.memberships SET status=N'INACTIVE' WHERE tenant_id=@tenant AND user_id=@actor;"),
        ('membership_missing', 'DELETE dbo.memberships WHERE tenant_id=@tenant AND user_id=@actor;'),
        ('mixed_portal', "UPDATE dbo.memberships SET roles=N'[\"ADM\",\"PAC\"]' WHERE tenant_id=@tenant AND user_id=@actor;"),
        ('claims_forged', "UPDATE dbo.memberships SET roles=N'[\"PRO\"]' WHERE tenant_id=@tenant AND user_id=@actor;SET @claims=N'[\"ADM\",\"REC\"]';"),
        ('portal_only', "UPDATE dbo.memberships SET roles=N'[\"PAC\",\"RES\"]' WHERE tenant_id=@tenant AND user_id=@actor;"),
        ('revoked', 'UPDATE dbo.auth_sessions SET revoked=1 WHERE token_hash=@token;'),
        ('expired', 'UPDATE dbo.auth_sessions SET expires_at=DATEADD(day,-1,SYSUTCDATETIME()) WHERE token_hash=@token;'),
        ('tenant_context', 'SET @ctx_tenant=@other;'),
    ]:
        cases.append(Phase('authority_'+name, 'current_actor_authority', 51001, fixture=fixture))
    for name, value in [('identity','IDENTITY'),('worker','WORKER'),('bootstrap','BOOTSTRAP'),('lowercase','request'),('padding','REQUEST ')]:
        # Padding/case use full sql_variant injection, not a narrowed helper argument.
        ctx="EXEC sys.sp_set_session_context @key=N'hp_scope',@value=N'"+value+"';"
        cases.append(Phase('scope_'+name, 'request_scope', 51001, context=ctx))
    cases += [
        Phase('context_missing', 'complete_context', 51001, context="EXEC sys.sp_set_session_context @key=N'hp_request_id',@value=NULL;"),
        Phase('context_id_long', 'complete_id_before_conversion', 51001, context="DECLARE @long_context nvarchar(80)=@tenant+N'suffix';EXEC sys.sp_set_session_context @key=N'hp_tenant_id',@value=@long_context;"),
        Phase('context_id_type', 'complete_context', 51001, context="EXEC sys.sp_set_session_context @key=N'hp_actor_id',@value=123;"),
        Phase('context_token_long', 'complete_context', 51001, context="DECLARE @long_token nvarchar(80)=@token+N'0';EXEC sys.sp_set_session_context @key=N'hp_token_hash',@value=@long_token;"),
        Phase('context_route_missing', 'complete_context', 51001, context="EXEC sys.sp_set_session_context @key=N'hp_route',@value=NULL;"),
        Phase('no_portal', 'contract_guard', 51001, fixture="UPDATE dbo.plan_versions SET modules=N'[\"CORE\"]' WHERE plan_id=@plan AND version=1;"),
        Phase('suspended', 'contract_guard', 51004, fixture="UPDATE dbo.tenants SET status=N'SUSPENDED' WHERE id=@tenant;"),
        Phase('edit_missing', 'edit_negative', 51002, operation='read'),
        Phase('audit_write_failure', 'atomic_audit_failure', 59998),
        Phase('audit_read_failure', 'atomic_audit_failure', 59998, operation='read', fixture=SEED),
    ]
    # Independent reader code has its own authority/guard path; seed the link
    # before changing only our fixture authority and call the real reader.
    for original in ('authority_revoked','authority_mixed_portal','authority_claims_forged','context_id_long','no_portal','suspended','patient_foreign'):
        writer=next(p for p in cases if p.name==original)
        cases.append(Phase('edit_'+original,'edit_current_authority',writer.error,operation='read',fixture=SEED+writer.fixture,context=writer.context))
    for op, error in [('deny_select',229),('deny_insert',229),('deny_update',229),('deny_delete',229),('deny_ddl',262),('deny_private',229),('deny_bootstrap_entry',229),('bootstrap_write',229),('bootstrap_read',229)]:
        cases.append(Phase(op, 'limited_principal_acl', error, operation=op, fixture=SEED))
    need(len({p.name for p in cases})==len(cases), 'MATRIX_DUPLICATE')
    return tuple(cases)


PHASES = matrix()
BY_NAME = {p.name:p for p in PHASES}
PENDING = (
    'First runtime call with physical counter0 selected by JDBC setAutoCommit(false)',
    'Autocommit calls to installed V14 and same JDBC connection after commit/rollback',
    'Spring/pool commit outcome and materialization behavior',
    'Two-connection create/edit CAS races, lock ordering, timeout/deadlock and revocation after commit',
    'Global READ_ONLY observation under separately prepared state; no global toggle here',
    'Original HTTP UUID length before CHAR binding (Q1), beyond separate offline C2 model tests',
)


def sections(source):
    need(source.startswith('-- C1P2 PREPARATION ONLY.') and '\n/* Templates only:' in source, 'TEMPLATE_RAW_GUARD')
    found={}
    for name in SECTIONS:
        pattern=r'^-- C1P2_'+name+r'_BEGIN\r?\n(.*?)\r?\n-- C1P2_'+name+r'_END$'
        matches=re.findall(pattern,source,re.M|re.S)
        need(len(matches)==1, 'TEMPLATE_SECTION_INVALID')
        found[name]=matches[0]
    need(len(re.findall(r'^-- C1P2_\w+_BEGIN$',source,re.M))==len(SECTIONS), 'TEMPLATE_EXTRA_SECTION')
    return found


def hash_expression(query):
    return "CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),("+query+"))),2)"


CATALOG = {
    'modules':"SELECT o.schema_id,o.name,o.type,m.* FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id ORDER BY o.object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'objects':"SELECT * FROM sys.objects WHERE is_ms_shipped=0 ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'tables':"SELECT * FROM sys.tables WHERE is_ms_shipped=0 ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'columns':"SELECT * FROM sys.columns ORDER BY object_id,column_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'defaults':"SELECT * FROM sys.default_constraints ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'checks':"SELECT * FROM sys.check_constraints ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'foreign_keys':"SELECT * FROM sys.foreign_keys ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'foreign_key_columns':"SELECT * FROM sys.foreign_key_columns ORDER BY constraint_object_id,constraint_column_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'indexes':"SELECT * FROM sys.indexes WHERE object_id IN (SELECT object_id FROM sys.objects WHERE is_ms_shipped=0) ORDER BY object_id,index_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'index_columns':"SELECT * FROM sys.index_columns WHERE object_id IN (SELECT object_id FROM sys.objects WHERE is_ms_shipped=0) ORDER BY object_id,index_id,index_column_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'key_constraints':"SELECT * FROM sys.key_constraints ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'triggers':"SELECT * FROM sys.triggers WHERE is_ms_shipped=0 ORDER BY object_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'trigger_events':"SELECT * FROM sys.trigger_events ORDER BY object_id,type FOR JSON PATH,INCLUDE_NULL_VALUES",
    'acl':"SELECT * FROM sys.database_permissions ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FOR JSON PATH,INCLUDE_NULL_VALUES",
    'role_memberships':"SELECT * FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'principals':"SELECT * FROM sys.database_principals ORDER BY principal_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'schemas':"SELECT * FROM sys.schemas ORDER BY schema_id FOR JSON PATH,INCLUDE_NULL_VALUES",
    'database':"SELECT database_id,name,owner_sid,compatibility_level,collation_name,containment,is_read_committed_snapshot_on,snapshot_isolation_state FROM sys.databases WHERE database_id=DB_ID() FOR JSON PATH,INCLUDE_NULL_VALUES",
    'extended_properties':"SELECT class,major_id,minor_id,name,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'BaseType')) AS base_type,CONVERT(nvarchar(max),value) AS value_text FROM sys.extended_properties ORDER BY class,major_id,minor_id,name FOR JSON PATH,INCLUDE_NULL_VALUES",
    # Deliberately omit only last_value (SQL identity allocations do not roll back).
    'identity_metadata':"SELECT object_id,column_id,CONVERT(nvarchar(100),seed_value) AS seed_value,CONVERT(nvarchar(100),increment_value) AS increment_value,is_not_for_replication FROM sys.identity_columns ORDER BY object_id,column_id FOR JSON PATH,INCLUDE_NULL_VALUES",
}
FINGERPRINT_KEYS = frozenset('table_'+n for n in TABLE_KEYS) | frozenset(CATALOG) | {'optional_history'}


def baseline_parts():
    need(len(TABLE_KEYS)==37,'TABLE_MANIFEST_INVALID')
    pieces=[]; guards=[]
    for table, keys in TABLE_KEYS.items():
        need(re.fullmatch(r'[a-z_]+',table) and all(re.fullmatch(r'[a-z_]+',k) for k in keys),'TABLE_MANIFEST_INVALID')
        order=','.join('['+k+']' for k in keys)
        pieces.append(hash_expression('SELECT * FROM dbo.['+table+'] ORDER BY '+order+' FOR JSON PATH,INCLUDE_NULL_VALUES')+' AS [table_'+table+']')
        expected=' UNION ALL '.join('SELECT '+str(i+1)+" AS ordinal,N'"+key+"' AS name" for i,key in enumerate(keys))
        actual="SELECT ic.key_ordinal,c.name FROM sys.key_constraints k JOIN sys.index_columns ic ON ic.object_id=k.parent_object_id AND ic.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE k.parent_object_id=OBJECT_ID(N'dbo."+table+"',N'U') AND k.type='PK' AND ic.key_ordinal>0"
        guards.append("IF OBJECT_ID(N'dbo."+table+"',N'U') IS NULL OR EXISTS("+expected+' EXCEPT '+actual+') OR EXISTS('+actual+' EXCEPT '+expected+") THROW 59999,N'C1P2 canonical table/PK prerequisite',1;")
    for name, query in CATALOG.items():pieces.append(hash_expression(query)+' AS ['+name+']')
    # Standard optional Flyway history must have its known primary key; otherwise fail closed.
    history_keys="SELECT i.key_ordinal,c.name FROM sys.key_constraints k JOIN sys.index_columns i ON i.object_id=k.parent_object_id AND i.index_id=k.unique_index_id JOIN sys.columns c ON c.object_id=i.object_id AND c.column_id=i.column_id WHERE k.parent_object_id=OBJECT_ID(N'dbo.flyway_schema_history') AND k.type='PK' AND i.key_ordinal>0"
    guards.append("IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL AND (EXISTS(SELECT 1,N'installed_rank' EXCEPT "+history_keys+") OR EXISTS("+history_keys+" EXCEPT SELECT 1,N'installed_rank')) THROW 59999,N'C1P2 optional history PK prerequisite',1;")
    # The nonexistent optional table cannot be referenced in a compiled static batch;
    # emit this expression only when a metadata-selected baseline variant is reviewed.
    # Baseline dynamically quotes NOTHING: fixed optional table query is sp_executesql
    # below with a fixed literal and OUTPUT hash; never exports history rows.
    guards.append("DECLARE @history_hash char(64)=CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),N'ABSENT')),2); IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL EXEC sys.sp_executesql N'SELECT @h=CONVERT(char(64),HASHBYTES(''SHA2_256'',CONVERT(varbinary(max),(SELECT * FROM dbo.flyway_schema_history ORDER BY installed_rank FOR JSON PATH,INCLUDE_NULL_VALUES))),2);',N'@h char(64) OUTPUT',@h=@history_hash OUTPUT;")
    pieces.append('@history_hash AS [optional_history]')
    return '\n'.join(guards),',\n'.join(pieces)


def validate_manifest(root, manifest, tool_paths=None):
    need(type(manifest) is dict and set(manifest)=={'mode','reviewed_sources'},'REVIEW_MANIFEST_INVALID')
    command(manifest['mode']);pins=manifest['reviewed_sources']
    need(type(pins) is dict and set(pins)=={TEMPLATE,DRIVER,TEST},'REVIEW_MANIFEST_INVALID')
    for relative, expected in pins.items():
        need(type(expected) is str and re.fullmatch(r'[0-9A-F]{64}',expected),'REVIEW_MANIFEST_INVALID')
        path=(tool_paths or {}).get(relative,root/relative)
        need(path.is_file() and not path.is_symlink() and digest(path.read_bytes())==expected,'REVIEWED_SOURCE_CHANGED')


def load_bundle(root, template_path=None):
    need(set(MIGRATIONS)==set(range(1,15)), 'MIGRATION_MANIFEST_INVALID')
    for version, entry in MIGRATIONS.items():
        path=root/'backend/src/main/resources/db/sqlserver'/entry['file']
        need(path.is_file() and not path.is_symlink() and digest(path.read_bytes())==entry['sha256'],'CANONICAL_MIGRATION_CHANGED_OR_MISSING')
    sql=(template_path or root/TEMPLATE).read_text(encoding='utf-8-sig')
    return sections(sql),(root/'backend/src/main/resources/db/sqlserver'/MIGRATIONS[14]['file']).read_text(encoding='utf-8-sig')


CALLS = {
    'write':'INSERT @ack EXEC dbo.usp_patient_link_save @selected,@input;',
    'read':'INSERT @edit EXEC dbo.usp_patient_link_edit_get @selected,@target;',
    'bootstrap_write':'INSERT @ack EXEC dbo.usp_patient_link_save @selected,@input;',
    'bootstrap_read':'INSERT @edit EXEC dbo.usp_patient_link_edit_get @selected,@target;',
    'deny_select':"EXEC sys.sp_executesql N'SELECT TOP(0) * FROM dbo.patient_links;';",
    'deny_insert':"INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes,revision) VALUES(@tenant,@patient,@owner,N'C1P2 denied',0,N'[]',1);",
    'deny_update':'UPDATE dbo.patient_links SET active=0 WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;',
    'deny_delete':'DELETE dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;',
    'deny_ddl':"EXEC(N'CREATE TABLE dbo.hp_qa_c1p2_denied(id int NOT NULL);');",
    'deny_private':'EXEC dbo.usp_require_actor;',
    'deny_bootstrap_entry':'EXEC dbo.usp_bootstrap_exists;',
}


def nonce(value=None):
    value=uuid.uuid4().hex if value is None else value
    need(type(value) is str and re.fullmatch(r'[0-9a-f]{32}',value),'NONCE_INVALID')
    return value


def baseline_sql(bundle, correlation):
    source,_=bundle;guards,fields=baseline_parts()
    text=source['COMMON']+'\n'+source['BASELINE']
    return ':On Error exit\n'+text.replace('__BASELINE_SHAPE_GUARDS__',guards).replace('__FINGERPRINTS_SQL__',fields).replace('__NONCE__',nonce(correlation))+'\n'


def phase_sql(bundle, name, correlation):
    need(name in BY_NAME,'PHASE_INVALID');phase=BY_NAME[name];source,migration=bundle
    text=source['COMMON']+'\n'+source['PRE']+'\n'+migration+'\n'+source['AFTER_V14']+'\n'
    if phase.error==59998:text+=source['AUDIT_FAILURE']+'\n'
    body=source['CASE']
    values={'PHASE':name,'NONCE':nonce(correlation),'DOMAIN':phase.domain,'ACTOR_ROLES':phase.actor_roles,'TARGET_ROLES':phase.target_roles,'EXPECTED_ERROR':str(phase.error),'SCENARIO':phase.scenario,'OPERATION':phase.operation,'FIXTURE_SQL':phase.fixture,'INPUT_SQL':phase.input_sql,'CONTEXT_SQL':phase.context,'NEGATIVE_CALL_SQL':CALLS[phase.operation]}
    text+=body
    for key,value in values.items():text=text.replace('__'+key+'__',value)
    need(re.search(r'__[A-Z_]+__',text) is None,'UNEXPANDED_TEMPLATE')
    return ':On Error exit\n'+text+'\n'


def frame(raw, prefix):
    try:
        need(type(raw) is bytes and len(raw)<=1_000_000,'FRAME_INVALID')
        text=raw.decode('utf-8-sig',errors='strict')
        if text.endswith('\r\n'):text=text[:-2]
        elif text.endswith('\n'):text=text[:-1]
        text=text.replace('\r\n','\n')
        if text.startswith(HEADER):text=text[len(HEADER):]
        need('\n' not in text and '\r' not in text and text.strip(' ').startswith(prefix),'FRAME_INVALID')
        value=strict_json(text.strip(' ')[len(prefix):])
        need(type(value) is dict,'FRAME_INVALID')
        return value
    except (UnicodeError,ValueError,TypeError):
        raise Failure('FRAME_INVALID') from None


def baseline_response(response, correlation):
    need(type(response.returncode) is int and type(response.stderr) is bytes,'BASELINE_TRANSPORT_FAILED')
    need(response.returncode==0 and response.stderr==b'','BASELINE_TRANSPORT_FAILED')
    value=frame(response.stdout,'C1P2_BASELINE')
    keys={'kind','mode','nonce','status','sp_count','trigger_count','role_acl_count','optional_history','application_mode','fingerprints','probe'}
    need(set(value)==keys and value['kind']=='BASELINE' and value['mode']==MODE and value['nonce']==correlation and value['status']=='PASS','BASELINE_FRAME_INVALID')
    need(type(value['sp_count']) is int and value['sp_count']==134 and type(value['trigger_count']) is int and value['trigger_count']==31,'BASELINE_PREREQUISITE')
    need(type(value['optional_history']) is bool and type(value['role_acl_count']) is int and value['role_acl_count']==(573 if value['optional_history'] else 564) and value['application_mode']=='OPEN','BASELINE_PREREQUISITE')
    need(value['probe']==PROBE,'UNICODE_FRAME_CORRUPTED')
    fingerprints=value['fingerprints']
    need(type(fingerprints) is dict and set(fingerprints)==FINGERPRINT_KEYS and all(type(v) is str and re.fullmatch(r'[0-9A-F]{64}',v) for v in fingerprints.values()),'BASELINE_FINGERPRINT_INVALID')
    return {k:v for k,v in value.items() if k not in {'nonce','probe'}}


def phase_response(response, name, correlation):
    need(name in BY_NAME,'PHASE_INVALID');phase=BY_NAME[name]
    need(type(response.returncode) is int and type(response.stderr) is bytes,'UNEXPECTED_ENGINE_EXIT')
    value=frame(response.stdout,'C1P2_RESULT')
    need(set(value)=={'kind','mode','nonce','phase','status','error','xact_state','cleanup','checks','probe'} and value['kind']=='PHASE' and value['mode']==MODE and value['nonce']==correlation and value['phase']==name and value['status']=='PASS','PHASE_FRAME_INVALID')
    need(type(value['error']) is int and value['error']==phase.error and type(value['xact_state']) is int and type(value['checks']) is int and value['checks']==phase.checks,'PHASE_ASSERTION_FAILED')
    need(value['probe']==PROBE,'UNICODE_FRAME_CORRUPTED')
    state=value['xact_state']
    if state==-1:
        need(phase.error!=0 and value['cleanup']=='CLOSE' and response.returncode==16,'DOOMED_EXIT_MISMATCH')
        try:text=response.stderr.decode('utf-8-sig',errors='strict').strip('\r\n')
        except UnicodeError:raise Failure('UNEXPECTED_ENGINE_ERROR') from None
        need(DOOMED.fullmatch(text) is not None,'UNEXPECTED_ENGINE_ERROR')
    else:
        need(state==(0 if phase.error==0 else 1) and value['cleanup']=='EXPLICIT' and response.returncode==0 and response.stderr==b'','UNEXPECTED_ENGINE_EXIT')
    return {k:v for k,v in value.items() if k not in {'nonce','probe'}}


def environment(environ=None):
    environ=os.environ if environ is None else environ
    need(not any(k.upper().startswith('SQLCMD') for k in environ),'HOSTILE_SQLCMD_ENVIRONMENT')
    # No inherited PATH, credentials, ODBC overrides or script metacommand settings.
    need(next((v for k,v in environ.items() if k.upper()=='SYSTEMROOT'),r'C:\Windows').lower()==r'c:\windows','SYSTEM_ROOT_INVALID')
    result={'SYSTEMROOT':r'C:\Windows','WINDIR':r'C:\Windows','SYSTEMDRIVE':'C:','PATH':str(SQLCMD.parent)+r';C:\Windows\System32'}
    for key in ['TEMP','TMP']:
        value=next((v for k,v in environ.items() if k.upper()==key),None)
        if value is not None:
            need(type(value) is str and ntpath.isabs(value) and not value.startswith(('\\\\','//')) and '\x00' not in value,'TEMP_ENV_INVALID')
            result[key]=value
    return result


def executable(path=SQLCMD):
    need(path==SQLCMD and path.is_file() and not path.is_symlink(),'SQLCMD_EXPECTED_PATH_MISSING')
    for parent in (path,*path.parents):
        need(not getattr(parent.stat(),'st_file_attributes',0)&getattr(stat,'FILE_ATTRIBUTE_REPARSE_POINT',1024),'SQLCMD_REPARSE_POINT')
    need(digest(path.read_bytes())==SQLCMD_SHA256,'SQLCMD_PIN_MISMATCH')
    return str(path)


class Transport:
    def __init__(self, environ=None, run=None, resolve=None):
        self.env=environment(environ);self._run=run or subprocess.run;self._resolve=resolve or executable

    def invoke(self, sql):
        need(type(sql) is str and sql.startswith(':On Error exit\n') and len(re.findall(r'(?m)^:On Error exit\r?$',sql))==1,'SQLCMD_STOP_ON_ERROR_REQUIRED')
        # The first exact directive is the ONLY allowed metacommand. In
        # particular :On Error ignore/exit, :quit or :reset cannot override it.
        need(not re.search(r'(?m)^\s*(?:!!|:)',sql[len(':On Error exit\n'):]),'SQLCMD_METACOMMAND_FORBIDDEN')
        args=[self._resolve(),'-S',SERVER,'-d',DATABASE,'-E','-C','-b','-V','11','-r','1','-f','65001','-y','0','-w','65535','-x','-X1','-l','5','-t','120']
        try:
            return self._run(args,input=sql.encode('utf-8'),capture_output=True,env=self.env,shell=False,timeout=300,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        except subprocess.TimeoutExpired as error:
            # subprocess.run kills/reaps its child on timeout. The runner STILL
            # requires new-connection restoration baseline; this is never a PASS.
            raise TransportFailure('TRANSPORT_TIMEOUT',error.output,error.stderr) from None
        except (OSError,ValueError):raise Failure('TRANSPORT_FAILED') from None


SAFE_FAILURE_CODES = frozenset('''
BASELINE_DRIFT_AFTER_PHASE BASELINE_DRIFT_BEFORE_PHASE BASELINE_FINGERPRINT_INVALID
BASELINE_FRAME_INVALID BASELINE_PREREQUISITE BASELINE_TRANSPORT_FAILED
CANONICAL_MIGRATION_CHANGED_OR_MISSING CONTROLLER_FAILED DOOMED_EXIT_MISMATCH
FINAL_BASELINE_DRIFT FRAME_INVALID HOSTILE_SQLCMD_ENVIRONMENT MATRIX_DUPLICATE
MIGRATION_MANIFEST_INVALID MODE_INVALID NONCE_INVALID PHASE_ASSERTION_FAILED
PHASE_FRAME_INVALID PHASE_INVALID PHASE_SELECTION_INVALID REVIEW_MANIFEST_INVALID
REVIEW_MANIFEST_REQUIRED REVIEWED_SOURCE_CHANGED SQLCMD_EXPECTED_PATH_MISSING
SQLCMD_METACOMMAND_FORBIDDEN SQLCMD_PIN_MISMATCH SQLCMD_REPARSE_POINT
SQLCMD_STOP_ON_ERROR_REQUIRED SYSTEM_ROOT_INVALID TABLE_MANIFEST_INVALID
TEMP_ENV_INVALID TEMPLATE_EXTRA_SECTION TEMPLATE_RAW_GUARD TEMPLATE_SECTION_INVALID
TRANSPORT_FAILED TRANSPORT_TIMEOUT TIMEOUT UNEXPANDED_TEMPLATE UNEXPECTED_ENGINE_ERROR
UNEXPECTED_ENGINE_EXIT UNICODE_FRAME_CORRUPTED WINDOWS_INTEGRATED_TRANSPORT_REQUIRED
EVIDENCE_REQUIRED EVIDENCE_LOCATION_INVALID EVIDENCE_ALREADY_EXISTS
EVIDENCE_WRITE_FAILED EVIDENCE_REUSED
'''.split())


def failure_code(error):
    # Even a Failure object is not a license to serialize arbitrary exception
    # text (which may contain a driver message, row value or secret).
    if isinstance(error,Failure) and str(error) in SAFE_FAILURE_CODES:return str(error)
    return 'CONTROLLER_FAILED'


def transport_metadata(response):
    """Only lengths/hashes and known numeric error headers, never raw buffers."""
    result={'returncode':None,'stdout':None,'stderr':None,'nativeHeaders':[]}
    if response is None:return result
    code=getattr(response,'returncode',None)
    if type(code) is int:result['returncode']=code
    for name in ('stdout','stderr'):
        raw=getattr(response,name,None)
        if type(raw) is bytes:result[name]={'bytes':len(raw),'sha256':digest(raw)}
    raw=getattr(response,'stderr',None)
    if type(raw) is bytes:
        pattern=rb'(?m)^Msg ([0-9]{1,5}), Level ([0-9]{1,2}), State ([0-9]{1,3}),(?: Server [^\r\n]+,)? Line ([0-9]{1,8})\r?$'
        known={229,262,1205,1222,3998,51000,51001,51002,51003,51004,51005,59998,59999}
        for match in re.finditer(pattern,raw):
            msg,level,state,line=(int(v) for v in match.groups())
            if msg in known and len(result['nativeHeaders'])<16:
                result['nativeHeaders'].append({'msg':msg,'level':level,'state':state,'line':line})
    return result


class TransportFailure(Failure):
    """Fixed code and sanitized metadata of partial timeout buffers, not bytes."""
    def __init__(self, code, stdout=None, stderr=None):
        super().__init__(code)
        self.output_metadata=transport_metadata(subprocess.CompletedProcess([],None,stdout,stderr))


class Evidence:
    """Exclusive local run namespace. Construction is explicit, never on import.

    Records and controlled generated SQL are create-only, flushed/fsynced, then
    referenced by an append-only fsynced journal. No engine stdout/stderr is
    written. A failed write poisons the run; it cannot authorize another phase.
    """
    def __init__(self, directory, root):
        self.path=Path(directory);self.root=Path(root);self.used=False
        try:
            self._location()
            need(not self.path.exists(),'EVIDENCE_ALREADY_EXISTS')
            self.path.mkdir(exist_ok=False)
            self._check_directory()
            self._write('run.json',{'schemaVersion':1,'mode':MODE,'runId':uuid.uuid4().hex,
                'sources':{name:digest((self.root/name).read_bytes()) for name in (TEMPLATE,DRIVER,TEST)},
                'canonicalMigrationPins':MIGRATIONS,'sqlcmdExecutableSha256':SQLCMD_SHA256,
                'sqlcmdTarget':SERVER,'database':DATABASE,
                'privacy':'Controlled generated SQL only; native buffers are length/hash only; validated frames only.'})
            self._write('journal.jsonl',b'')
            self._append({'event':'RUN_CREATED','manifest':'run.json'})
        except Failure:raise
        except FileExistsError:raise Failure('EVIDENCE_ALREADY_EXISTS') from None
        except (OSError,ValueError):raise Failure('EVIDENCE_WRITE_FAILED') from None

    def _location(self):
        path=self.path
        need(path.is_absolute() and not str(path).startswith(('\\\\','//'))
             and '..' not in path.parts and not path.drive.startswith('\\\\')
             and re.fullmatch(r'C1P2(?:R1)?-[A-Za-z0-9_-]{1,100}',path.name),'EVIDENCE_LOCATION_INVALID')
        # An immediate new child only: no implicit parent creation or escape.
        process_temp=Path(os.environ.get('TEMP',''))
        need(path.parent in (self.root/'tmp',process_temp),'EVIDENCE_LOCATION_INVALID')
        need(path.parent.is_dir(),'EVIDENCE_LOCATION_INVALID')
        for parent in (path.parent,*path.parent.parents):self._plain(parent)

    @staticmethod
    def _plain(path):
        need(not path.is_symlink() and not getattr(path.stat(),'st_file_attributes',0)&getattr(stat,'FILE_ATTRIBUTE_REPARSE_POINT',1024),'EVIDENCE_LOCATION_INVALID')

    def _check_directory(self):
        self._location();self._plain(self.path)

    def _write(self, name, value):
        self._check_directory()
        need(re.fullmatch(r'[A-Za-z0-9_.-]+',name),'EVIDENCE_LOCATION_INVALID')
        raw=value if type(value) is bytes else (json.dumps(value,ensure_ascii=True,separators=(',',':'))+'\n').encode('utf-8')
        # Publish atomically/create-only after the full record was fsynced.
        # Retain the staging inode (also on failure); never overwrite/delete
        # old evidence. Readers use only published names referenced by journal.
        staging=self.path/(name+'.pending')
        with staging.open('xb') as stream:
            stream.write(raw);stream.flush();os.fsync(stream.fileno())
        os.link(staging,self.path/name)
        return {'file':name,'sha256':digest(raw)}

    def _append(self, value):
        self._check_directory();path=self.path/'journal.jsonl';self._plain(path)
        raw=(json.dumps(value,ensure_ascii=True,separators=(',',':'))+'\n').encode('utf-8')
        with path.open('ab') as stream:
            stream.write(raw);stream.flush();os.fsync(stream.fileno())

    def begin(self, metadata, sql):
        number=f"{metadata['order']:04}"
        source=self._write(number+'.sql',sql.encode('utf-8'))
        record=self._write(number+'-attempt.json',{**metadata,'sql':source})
        self._append({'event':'ATTEMPT',**metadata,'record':record})

    def end(self, metadata, result):
        record=self._write(f"{metadata['order']:04}-result.json",{**metadata,**result})
        self._append({'event':'RESULT',**metadata,'record':record})

    def accept(self, metadata, check):
        record=self._write(f"{metadata['order']:04}-accepted.json",{**metadata,'check':check})
        self._append({'event':'CHECK_ACCEPTED',**metadata,'record':record})

    def finish(self, result):
        # No fallible journal operation after publishing a successful summary.
        self._append({'event':'SUMMARY_INTENT','file':'summary.json','status':result['status']})
        self._write('summary.json',result)


class RunFailure(Failure):
    def __init__(self, report):
        super().__init__(report['primaryFailure']['code']);self.report=report


class Runner:
    def __init__(self, bundle, transport, evidence=None):
        self.bundle=bundle;self.transport=transport;self.evidence=evidence

    def _fault(self, error, metadata):
        fault={'code':failure_code(error),**{k:metadata.get(k) for k in ('stage','phase','nonce','phaseNonce','order')}}
        self.faults.append(fault)

    def _call(self, sql, stage, phase, correlation, validator, cleanup=False, phase_nonce=None):
        self.order+=1
        meta={'order':self.order,'stage':stage,'phase':phase,'nonce':correlation,
              'phaseNonce':phase_nonce,'readonly':stage!='phaseinvoke','sqlSha256':digest(sql.encode('utf-8'))}
        entry={**meta,'attempt':f'{self.order:04}-attempt.json','result':f'{self.order:04}-result.json',
               'attemptRecorded':False,'resultRecorded':False,'transportStarted':False,'outcome':'NOT_TRANSPORTED'}
        self.attempts.append(entry);response=None;value=None;partial_metadata=None
        try:
            self.evidence.begin(meta,sql);entry['attemptRecorded']=True
        except Exception:
            self._fault(Failure('EVIDENCE_WRITE_FAILED'),meta)
            # Before the first transport: ZERO calls. After any transport,
            # fresh cleanup-only baseline connections remain mandatory even
            # when their journal cannot be written. Never another SQL phase.
            if not cleanup or not self.started:return None
        try:
            self.started=True;entry['transportStarted']=True
            response=self.transport.invoke(sql)
        except Exception as error:
            self._fault(error,meta)
            if type(error) is TransportFailure:partial_metadata=error.output_metadata
        if response is None and not any(f['order']==meta['order'] for f in self.faults):
            self._fault(Failure('CONTROLLER_FAILED'),meta)
        if response is not None:
            try:value=validator(response)
            except Exception as error:
                validation_meta={**meta,'stage':'phasevalidate' if stage=='phaseinvoke' else stage}
                self._fault(error,validation_meta)
        try:details=partial_metadata or transport_metadata(response)
        except Exception:
            self._fault(Failure('CONTROLLER_FAILED'),meta);details=transport_metadata(None)
        result={'outcome':'RETURNED' if response is not None else 'TRANSPORT_FAILED',
                'transport':details,'validation':'VALID' if value is not None else 'FAILED',
                'validatedFrame':value,'failures':[f for f in self.faults if f['order']==meta['order']]}
        entry.update(result)
        try:
            self.evidence.end(meta,result);entry['resultRecorded']=True
        except Exception:self._fault(Failure('EVIDENCE_WRITE_FAILED'),meta)
        return value

    def _baseline(self, stage, phase=None, phase_nonce=None, cleanup=False):
        correlation=nonce()
        value=self._call(baseline_sql(self.bundle,correlation),stage,phase,correlation,
                         lambda response:baseline_response(response,correlation),cleanup,phase_nonce)
        return value,{'stage':stage,'phase':phase,'nonce':correlation,'phaseNonce':phase_nonce,'order':self.order}

    def _report(self, summary_written):
        failed=bool(self.faults)
        return {'mode':MODE,'status':'FAIL' if failed else 'PASS',
            'primaryFailure':self.faults[0] if failed else None,'secondaryFailures':self.faults[1:],
            'checks':self.checks,'checksStatus':'PARTIAL' if failed else 'COMPLETE',
            'attempts':self.attempts,'conservation':self.conservation,
            'restored':self.conservation['final'].get('matchesInitial') is True,
            'evidence':{'directory':str(self.evidence.path),'journal':str(self.evidence.path/'journal.jsonl'),
                        'summary':str(self.evidence.path/'summary.json'),'summaryWritten':summary_written},
            'businessProof':'Only these sequential rollback PRE phases; not JDBC/first-RPC/concurrency/committed revocation proof',
            'identityAllocatorExcluded':'last_value only; no reseed','pending':list(PENDING)}

    def execute(self, mode, names=None):
        command(mode);names=tuple(BY_NAME) if names is None else tuple(names)
        need(names and len(names)==len(set(names)) and all(n in BY_NAME for n in names),'PHASE_SELECTION_INVALID')
        need(isinstance(self.evidence,Evidence),'EVIDENCE_REQUIRED')
        need(not self.evidence.used,'EVIDENCE_REUSED');self.evidence.used=True
        self.order=0;self.started=False;self.attempts=[];self.checks=[];self.faults=[]
        self.conservation={'initial':{'status':'NOT_ATTEMPTED'},'prephase':[],'postbaseline':[],
                           'final':{'status':'NOT_ATTEMPTED','matchesInitial':None}}
        original=None;name=None;phase_nonce=None
        try:
            original,meta=self._baseline('baselineinitial')
            self.conservation['initial']={**meta,'status':'VALID' if original is not None else 'FAILED'}
            if not self.faults:
                for name in names:
                    before,meta=self._baseline('prephase',name)
                    equal=before==original if before is not None else None
                    self.conservation['prephase'].append({**meta,'status':'VALID' if before is not None else 'FAILED','matchesInitial':equal})
                    if equal is False:self._fault(Failure('BASELINE_DRIFT_BEFORE_PHASE'),meta)
                    if self.faults:break
                    phase_nonce=nonce()
                    candidate=self._call(phase_sql(self.bundle,name,phase_nonce),'phaseinvoke',name,phase_nonce,
                                         lambda response:phase_response(response,name,phase_nonce),phase_nonce=phase_nonce)
                    phase_meta={'order':self.order,'stage':'phasevalidate','phase':name,'nonce':phase_nonce,'phaseNonce':phase_nonce}
                    # A validated frame is only a candidate until a new baseline
                    # proves restoration. Validation errors are retained before
                    # cleanup so a later cleanup error cannot hide the cause.
                    after,meta=self._baseline('postbaseline',name,phase_nonce,cleanup=True)
                    equal=after==original if after is not None else None
                    self.conservation['postbaseline'].append({**meta,'status':'VALID' if after is not None else 'FAILED','matchesInitial':equal})
                    if equal is False:self._fault(Failure('BASELINE_DRIFT_AFTER_PHASE'),meta)
                    if self.faults:break
                    self.checks.append({'phase':name,'nonce':phase_nonce,'callOrder':phase_meta['order'],'result':candidate})
                    try:self.evidence.accept(phase_meta,self.checks[-1])
                    except Exception:
                        self._fault(Failure('EVIDENCE_WRITE_FAILED'),phase_meta);break
        except Exception as error:
            # All normal call/validation paths already retain their exact stage.
            # Unexpected controller/generation errors remain fixed-code only.
            self._fault(error,{'stage':'phaseinvoke' if name else 'baselineinitial','phase':name,'nonce':phase_nonce,'order':self.order})
        finally:
            if self.started:
                try:
                    final,meta=self._baseline('finalbaseline',name,phase_nonce,cleanup=True)
                    equal=final==original if original is not None and final is not None else None
                    self.conservation['final']={**meta,'status':'VALID' if final is not None else 'FAILED','matchesInitial':equal}
                    if equal is False:self._fault(Failure('FINAL_BASELINE_DRIFT'),meta)
                except Exception as error:
                    self._fault(error,{'stage':'finalbaseline','phase':name,'nonce':phase_nonce,'order':self.order})
                    self.conservation['final']={'status':'FAILED','matchesInitial':None}
        report=self._report(True)
        try:self.evidence.finish(report)
        except Exception:
            self._fault(Failure('EVIDENCE_WRITE_FAILED'),{'stage':'finalbaseline','phase':name,'nonce':phase_nonce,'order':self.order})
            report=self._report(False)
        if self.faults:raise RunFailure(report)
        return report


def main(argv=None):
    parser=argparse.ArgumentParser(description='Future reviewed rollback-only PRE controller; no SQL permitted during preparation Dispatch')
    parser.add_argument('command',choices=[MODE]);parser.add_argument('--review-manifest',required=True)
    parser.add_argument('--evidence-dir',required=True,help='New exclusive C1P2-* local child of root/tmp or process TEMP')
    args=parser.parse_args(argv);command(args.command)
    need(os.name=='nt','WINDOWS_INTEGRATED_TRANSPORT_REQUIRED')
    root=Path(__file__).resolve().parents[1]
    path=Path(args.review_manifest)
    need(path.is_absolute() and path.is_file() and not path.is_symlink(),'REVIEW_MANIFEST_REQUIRED')
    manifest=strict_json(path.read_text(encoding='utf-8-sig'));validate_manifest(root,manifest)
    bundle=load_bundle(root)
    # Transport construction only validates environment; it launches nothing.
    # Exclusive durable evidence must exist before the first invoke/probe.
    transport=Transport();evidence=Evidence(Path(args.evidence_dir),root)
    result=Runner(bundle,transport,evidence).execute(MODE)
    print(json.dumps(result,ensure_ascii=True));return 0


if __name__=='__main__':
    try:raise SystemExit(main())
    except RunFailure as error:
        print(json.dumps(error.report,ensure_ascii=True));raise SystemExit(1)
    except Failure as error:
        print(json.dumps({'status':'FAIL','primaryFailure':{'code':failure_code(error),'stage':'baselineinitial'},'checks':[],'checksStatus':'PARTIAL'}));raise SystemExit(1)
    except Exception:
        print(json.dumps({'status':'FAIL','primaryFailure':{'code':'CONTROLLER_FAILED','stage':'baselineinitial'},'checks':[],'checksStatus':'PARTIAL'}));raise SystemExit(1)
