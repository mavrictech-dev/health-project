"""Bounded permissions setup for one marked local QA database; not a general migrator."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
V8 = ROOT / "backend/src/main/resources/db/sqlserver/V8__execution_permissions.sql"
A7 = ROOT / "backend/scripts/verify-sqlserver-permissions.sql"
TEMP = ROOT / "tmp/sqlserver-a62-permissions"
V8_SHA = "63ca532ad7f16650dfd27891a7093ea4b0cee3c264ca35537d81a9100c067f4e"
V8_LF_SHA = "3d162d64b43001c1c63ed1084ef0797531d712155cea11a1ce1269a6fca555bd"
A7_SHA = "76c9d3caff0ad2751f20d92759df0841844673c43c9dd172dbcf053ea6d2217a"
A7_LF_SHA = "64a6cd7e0844e1922986b712c41c157a4f42b059732845dba371dc5e271182fb"
ROLES = ("hp_runtime_executor", "hp_bootstrap_executor")
BOOTSTRAP = ("usp_bootstrap_create", "usp_bootstrap_exists")
PARTS = ("proceduresOther", "triggers", "tables", "columns", "principalsOther", "memberships", "permissionsOther", "schemas", "marker")
SPEC = importlib.util.spec_from_file_location("a61_preflight", ROOT / "scripts/sqlserver-qa-preflight.py")
A61 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(A61)
LIMITS = list(A61.LIMITS) + ["Installed permissions are not successful JDBC, runtime authentication or effective grants testing.", "No transport, instance authentication, logins, users, data fixtures or bootstrap SAD are provisioned."]
ERRORS = {"ARTIFACT_HASH", "REFERENCE_HASH", "ARTIFACT_CONTRACT", "COMMAND_INVALID", "RESPONSE_INVALID", "METADATA_INVALID", "SCOPE_MISMATCH", "BASELINE_CONFLICT", "CONTROL_REQUIRED", "ROLES_EXIST", "TRANSACTION_INVALID", "ROLES_INVALID", "ACL_INVALID", "PROTECTED_METADATA_CHANGED", "BOOTSTRAP_HEADER_INVALID", "BOOTSTRAP_DEFINITION_INVALID", "SQLCMD_NOT_FOUND", "SQLCMD_FAILED", "SQLCMD_TIMEOUT", "CLEANUP_MISMATCH", "PERSISTENCE_MISMATCH", "INSPECTION_ERROR"}


class SetupError(Exception):
    pass


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def literal(value):
    return "N'" + value.replace("'", "''") + "'"


def canonical_body(name, definition):
    """Approved line-comment prefix, exact declaration, CR/outer whitespace only."""
    if name not in BOOTSTRAP or not isinstance(definition, str):
        raise SetupError("BOOTSTRAP_HEADER_INVALID")
    body = definition.replace("\r", "").strip(" \t\n")
    while body.startswith("--"):
        end = body.find("\n")
        if end < 0:
            raise SetupError("BOOTSTRAP_HEADER_INVALID")
        body = body[end + 1:].strip(" \t\n")
    for verb in ("CREATE", "ALTER"):
        header = verb + " PROCEDURE dbo." + name
        if body.startswith(header) and len(body) > len(header) and body[len(header)] in " \t\n":
            return body if verb == "CREATE" else "CREATE" + body[5:]
    raise SetupError("BOOTSTRAP_HEADER_INVALID")


class Artifact:
    def __init__(self, raw, reference):
        if hashlib.sha256(raw).hexdigest() != V8_SHA and hashlib.sha256(raw.replace(b"\r\n", b"\n")).hexdigest() != V8_LF_SHA:
            raise SetupError("ARTIFACT_HASH")
        if hashlib.sha256(reference).hexdigest() != A7_SHA and hashlib.sha256(reference.replace(b"\r\n", b"\n")).hexdigest() != A7_LF_SHA:
            raise SetupError("REFERENCE_HASH")
        self.raw = raw
        text = raw.decode("utf-8").replace("\r\n", "\n")
        procedures = re.search(r"INSERT @procedures\(name,access_class\) VALUES(.*?);", text, re.S).group(1)
        tables = re.search(r"INSERT @tables\(name\) VALUES(.*?);", text, re.S).group(1)
        triggers = re.search(r"INSERT @triggers VALUES(.*?);", text, re.S).group(1)
        self.procedures = set(re.findall(r"\(N'(\w+)',N'(?:runtime|private|bootstrap)'\)", procedures))
        self.tables = set(re.findall(r"\(N'(\w+)'\)", tables))
        self.triggers = dict(re.findall(r"\(N'(\w+)',N'(\w+)'\)", triggers))
        self.acl = []
        pattern = r"^(GRANT|DENY) (EXECUTE|SELECT,INSERT,UPDATE,DELETE|VIEW DEFINITION) ON OBJECT::dbo\.(\[?\w+\]?) TO (hp_(?:runtime|bootstrap)_executor);"
        for state, permissions, obj, role in re.findall(pattern, text, re.M):
            obj = obj.strip("[]")
            if obj == "flyway_schema_history":
                continue
            for permission in permissions.split(","):
                self.acl.append({"role": role, "classId": 1, "schemaName": "dbo", "objectName": obj, "minorId": 0, "permissionName": permission, "state": "G" if state == "GRANT" else "D"})
        self.bodies = dict(re.findall(r"^(ALTER PROCEDURE dbo\.(usp_bootstrap_\w+).*?)(?=^GO\s*$)", text, re.M | re.S))
        # The tuple order above is body/name; retain the approved literal body unchanged.
        self.bodies = {name: body.strip(" \t\r\n") for body, name in self.bodies.items()}
        self.canonical_bodies = {name: canonical_body(name, body) for name, body in self.bodies.items()}
        self.installed_hashes = {name: sha(body.encode("utf-16le")) for name, body in self.canonical_bodies.items()}
        if (len(self.procedures), len(self.tables), len(self.triggers), len(self.acl)) != (133, 37, 31, 562) or set(self.bodies) != set(BOOTSTRAP) or len({json.dumps(row, sort_keys=True) for row in self.acl}) != 562:
            raise SetupError("ARTIFACT_CONTRACT")

    @classmethod
    def load(cls):
        # Each source is read once per invocation; all execution uses these frozen bytes.
        return cls(V8.read_bytes(), A7.read_bytes())


GUARDS = """IF DB_NAME() COLLATE Latin1_General_100_BIN2<>N'health_project_sqlserver_qa_20261103'
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope'
 AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data'
 AND DATALENGTH(CONVERT(nvarchar(4000),value))=DATALENGTH(N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data'))
 THROW 59999,N'QA scope mismatch',1;
"""

# Every row below is catalog metadata, never a business table read.
CATALOG = {
    "proceduresOther": "SELECT s.name schemaName,p.name,p.object_id,p.principal_id,m.uses_ansi_nulls,m.uses_quoted_identifier,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),2) definitionHash FROM sys.procedures p JOIN sys.schemas s ON s.schema_id=p.schema_id LEFT JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.is_ms_shipped=0 AND p.name NOT IN (N'usp_bootstrap_create',N'usp_bootstrap_exists') ORDER BY s.name,p.name",
    "triggers": "SELECT s.name schemaName,t.name,t.object_id,t.parent_id,t.is_disabled,o.principal_id,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(t.object_id))),2) definitionHash FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.object_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE t.parent_class=1 ORDER BY s.name,t.name",
    "tables": "SELECT s.name schemaName,t.name,t.object_id,t.principal_id,t.temporal_type,t.is_memory_optimized,t.durability,t.lock_escalation,t.is_filetable FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name",
    "columns": "SELECT c.object_id,c.column_id,c.name,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.collation_name,c.is_nullable,c.is_identity,c.is_computed,c.is_rowguidcol,c.is_sparse,c.is_column_set,c.generated_always_type,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(c.default_object_id))),2) defaultHash,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),cc.definition)),2) computedHash FROM sys.columns c JOIN sys.tables t ON t.object_id=c.object_id LEFT JOIN sys.computed_columns cc ON cc.object_id=c.object_id AND cc.column_id=c.column_id WHERE t.is_ms_shipped=0 ORDER BY c.object_id,c.column_id",
    "principalsOther": "SELECT principal_id,name,type,owning_principal_id,default_schema_name,authentication_type,is_fixed_role,CONVERT(varchar(max),sid,2) sid FROM sys.database_principals WHERE name NOT IN (N'hp_runtime_executor',N'hp_bootstrap_executor') ORDER BY principal_id",
    "memberships": "SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id",
    "permissionsOther": "SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,permission_name,state FROM sys.database_permissions WHERE grantee_principal_id NOT IN (ISNULL(DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),-1),ISNULL(DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor'),-1)) ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state",
    "schemas": "SELECT schema_id,name,principal_id FROM sys.schemas ORDER BY schema_id",
    "marker": "SELECT class,major_id,minor_id,name,CONVERT(nvarchar(4000),value) value FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope' ORDER BY class,major_id,minor_id,name",
}


def bootstrap_catalog_sql():
    # Declarative metadata-only equivalent of canonical_body. The first nonblank,
    # non-line-comment line must be the exact declaration; no SUBSTRING(start=0).
    return """SELECT p.name,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),2) rawHash,
 canonical.canonicalBody
 FROM sys.procedures p LEFT JOIN sys.sql_modules m ON m.object_id=p.object_id
 CROSS APPLY(SELECT TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM REPLACE(m.definition,NCHAR(13),N'')) normalized) normalized
 CROSS APPLY(SELECT MIN(lines.ordinal) firstCode FROM STRING_SPLIT(normalized.normalized,NCHAR(10),1) lines
  WHERE TRIM(N' '+NCHAR(9) FROM lines.value)<>N'' AND LEFT(TRIM(N' '+NCHAR(9) FROM lines.value),2)<>N'--') firstLine
 CROSS APPLY(SELECT 1+COALESCE(SUM(CONVERT(bigint,DATALENGTH(lines.value))/2+1),0) startPosition
  FROM STRING_SPLIT(normalized.normalized,NCHAR(10),1) lines WHERE lines.ordinal<firstLine.firstCode) position
 CROSS APPLY(SELECT TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM SUBSTRING(normalized.normalized,position.startPosition,2147483647)) body) body
 CROSS APPLY(SELECT N'CREATE PROCEDURE dbo.'+p.name createHeader,N'ALTER PROCEDURE dbo.'+p.name alterHeader) headers
 CROSS APPLY(SELECT CASE
  WHEN LEFT(body.body,LEN(headers.createHeader)) COLLATE Latin1_General_100_BIN2=headers.createHeader COLLATE Latin1_General_100_BIN2
   AND UNICODE(SUBSTRING(body.body,LEN(headers.createHeader)+1,1)) IN (9,10,13,32) THEN body.body
  WHEN LEFT(body.body,LEN(headers.alterHeader)) COLLATE Latin1_General_100_BIN2=headers.alterHeader COLLATE Latin1_General_100_BIN2
   AND UNICODE(SUBSTRING(body.body,LEN(headers.alterHeader)+1,1)) IN (9,10,13,32) THEN CONVERT(nvarchar(max),N'CREATE')+SUBSTRING(body.body,6,2147483647)
  ELSE NULL END canonicalBody) canonical
 WHERE p.schema_id=SCHEMA_ID(N'dbo') AND p.name IN (N'usp_bootstrap_create',N'usp_bootstrap_exists')
 ORDER BY p.name"""


def snapshot_sql():
    sql = "DECLARE @a62_transactionCount int=@@TRANCOUNT,@a62_xactState int=XACT_STATE();\n"
    sql += "DECLARE @a62_meta nvarchar(max)=(" + A61.QUERY.rstrip(";") + ");\n"
    for name, query in CATALOG.items():
        sql += "DECLARE @a62_" + name + " nvarchar(max)=COALESCE((" + query + " FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]');\n"
    sql += "DECLARE @a62_bootstrapBodies nvarchar(max)=COALESCE((" + bootstrap_catalog_sql() + " FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]');\n"
    sql += """IF EXISTS(SELECT 1 FROM OPENJSON(@a62_bootstrapBodies) WITH(canonicalBody nvarchar(max) '$.canonicalBody') definitions WHERE canonicalBody IS NULL)
 THROW 59999,N'QA bootstrap header invalid',1;
DECLARE @a62_bootstrap nvarchar(max)=COALESCE((SELECT name,rawHash,CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),canonicalBody)),2) canonicalHash
 FROM OPENJSON(@a62_bootstrapBodies) WITH(name sysname '$.name',rawHash varchar(64) '$.rawHash',canonicalBody nvarchar(max) '$.canonicalBody') definitions ORDER BY name FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]');
DECLARE @a62_roles nvarchar(max)=COALESCE((SELECT name,type,USER_NAME(owning_principal_id) owner FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') ORDER BY name FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]');
DECLARE @a62_acl nvarchar(max)=COALESCE((SELECT r.name role,p.class classId,OBJECT_SCHEMA_NAME(p.major_id) schemaName,OBJECT_NAME(p.major_id) objectName,p.minor_id minorId,p.permission_name permissionName,p.state state
 FROM sys.database_permissions p JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name IN (N'hp_runtime_executor',N'hp_bootstrap_executor')
 ORDER BY r.name,p.class,p.major_id,p.minor_id,p.permission_name,p.state FOR JSON PATH,INCLUDE_NULL_VALUES),N'[]');
DECLARE @a62_procedures nvarchar(max)=COALESCE((SELECT s.name schemaName,p.name FROM sys.procedures p JOIN sys.schemas s ON s.schema_id=p.schema_id WHERE p.is_ms_shipped=0 ORDER BY s.name,p.name FOR JSON PATH),N'[]');
DECLARE @a62_tableNames nvarchar(max)=COALESCE((SELECT s.name schemaName,t.name FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.is_ms_shipped=0 ORDER BY s.name,t.name FOR JSON PATH),N'[]');
DECLARE @a62_triggerNames nvarchar(max)=COALESCE((SELECT s.name schemaName,t.name,OBJECT_NAME(t.parent_id) parentName FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.object_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE t.parent_class=1 ORDER BY s.name,t.name FOR JSON PATH),N'[]');
"""
    protected = ",".join("CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@a62_" + name + ")),2) " + name for name in PARTS)
    sql += "DECLARE @a62_protected nvarchar(max)=(SELECT " + protected + " FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);\n"
    all_hashes = " + N'|' + ".join("CONVERT(nvarchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@a62_" + name + ")),2)" for name in PARTS + ("bootstrap", "roles", "acl"))
    sql += "DECLARE @a62_all nvarchar(max)=" + all_hashes + ";\n"
    sql += """DECLARE @a62_snapshot nvarchar(max)=(SELECT JSON_QUERY(@a62_meta) metadata,
 CONVERT(int,ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL'),0)) controlDatabase,@a62_transactionCount transactionCount,@a62_xactState xactState,
 CONVERT(int,CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history') IS NULL THEN 0 ELSE 1 END) historyPresent,
 JSON_QUERY(@a62_protected) protected,JSON_QUERY(@a62_bootstrap) bootstrap,JSON_QUERY(@a62_roles) roles,JSON_QUERY(@a62_acl) acl,
 JSON_QUERY(@a62_procedures) procedures,JSON_QUERY(@a62_tableNames) tables,JSON_QUERY(@a62_triggerNames) triggers,
 CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@a62_all)),2) fingerprint
 FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER);
"""
    return sql


EMIT = """DECLARE @a62_offset int=1;
WHILE @a62_offset<=DATALENGTH(@a62_snapshot)
BEGIN
 SELECT CONVERT(nvarchar(max),N'A62JSON:')+CONVERT(varchar(4000),SUBSTRING(CONVERT(varbinary(max),@a62_snapshot),@a62_offset,2000),2);
 SET @a62_offset+=2000;
END;
SELECT N'A62END:'+CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@a62_snapshot)),2);
"""


def parse_snapshot(stdout):
    if not isinstance(stdout, str):
        raise SetupError("RESPONSE_INVALID", "text")
    lines = [line.strip() for line in stdout.lstrip("\ufeff").splitlines() if line.strip()]
    if len(lines) < 2 or not re.fullmatch(r"A62END:[0-9A-F]{64}", lines[-1]):
        raise SetupError("RESPONSE_INVALID", "framing")
    chunks = []
    for line in lines[:-1]:
        if not re.fullmatch(r"A62JSON:(?:[0-9A-F]{2}){1,2000}", line):
            raise SetupError("RESPONSE_INVALID", "chunk")
        chunks.append(bytes.fromhex(line[8:]))
    raw = b"".join(chunks)
    if sha(raw) != lines[-1][7:]:
        raise SetupError("RESPONSE_INVALID", "checksum")
    try:
        data = json.loads(raw.decode("utf-16le"), object_pairs_hook=A61.unique_object)
    except Exception:
        raise SetupError("RESPONSE_INVALID", "json") from None
    fields = {"metadata", "controlDatabase", "transactionCount", "xactState", "historyPresent", "protected", "bootstrap", "roles", "acl", "procedures", "tables", "triggers", "fingerprint"}
    if not isinstance(data, dict) or set(data) != fields:
        raise SetupError("RESPONSE_INVALID", "fields")
    A61.parse_metadata(json.dumps(data["metadata"]))
    if not isinstance(data["protected"], dict) or set(data["protected"]) != set(PARTS):
        raise SetupError("RESPONSE_INVALID", "protected")
    hashes = list(data["protected"].values()) + [data["fingerprint"]]
    if any(not isinstance(value, str) or not re.fullmatch(r"[0-9A-F]{64}", value) for value in hashes):
        raise SetupError("RESPONSE_INVALID", "hashes")
    if any(type(data[key]) is not int for key in ("controlDatabase", "transactionCount", "xactState", "historyPresent")):
        raise SetupError("RESPONSE_INVALID", "types")
    if any(not isinstance(data[key], list) for key in ("bootstrap", "roles", "acl", "procedures", "tables", "triggers")):
        raise SetupError("RESPONSE_INVALID", "arrays")
    return data


def validate_inventory(data, artifact):
    metadata = A61.parse_metadata(json.dumps(data["metadata"]))
    if metadata["compatibilityLevel"] != 160 or metadata["procedureCount"] != 133 or metadata["userTableCount"] != 37 or data["historyPresent"] != 0:
        raise SetupError("BASELINE_CONFLICT")
    for key, expected in (("procedures", artifact.procedures), ("tables", artifact.tables)):
        rows = data[key]
        if len(rows) != len(expected) or any(set(row) != {"schemaName", "name"} or row["schemaName"] != "dbo" for row in rows) or {row["name"] for row in rows} != expected:
            raise SetupError("BASELINE_CONFLICT")
    rows = data["triggers"]
    if len(rows) != 31 or any(set(row) != {"schemaName", "name", "parentName"} or row["schemaName"] != "dbo" for row in rows) or {row["name"]: row["parentName"] for row in rows} != artifact.triggers:
        raise SetupError("BASELINE_CONFLICT")
    if len(data["bootstrap"]) != 2 or {row["name"] for row in data["bootstrap"]} != set(BOOTSTRAP) or any(set(row) != {"name", "rawHash", "canonicalHash"} or any(not re.fullmatch(r"[0-9A-F]{64}", str(row[key])) for key in ("rawHash", "canonicalHash")) for row in data["bootstrap"]):
        raise SetupError("RESPONSE_INVALID")
    if data["controlDatabase"] != 1:
        raise SetupError("CONTROL_REQUIRED")


def validate_baseline(data, artifact):
    validate_inventory(data, artifact)
    if data["roles"] or data["acl"] or any(data["metadata"][key] is not None for key in ("runtimeRoleType", "bootstrapRoleType")):
        raise SetupError("ROLES_EXIST")
    if data["transactionCount"] != 0 or data["xactState"] != 0:
        raise SetupError("TRANSACTION_INVALID")


def validate_installed(data, before, artifact, in_transaction):
    validate_inventory(data, artifact)
    expected_roles = [{"name": role, "type": "R", "owner": "dbo"} for role in ROLES]
    if sorted(data["roles"], key=lambda row: row["name"]) != sorted(expected_roles, key=lambda row: row["name"]) or any(data["metadata"][key] != "R" for key in ("runtimeRoleType", "bootstrapRoleType")):
        raise SetupError("ROLES_INVALID")
    if len(data["acl"]) != 562 or sorted(json.dumps(row, sort_keys=True) for row in data["acl"]) != sorted(json.dumps(row, sort_keys=True) for row in artifact.acl):
        raise SetupError("ACL_INVALID")
    if data["protected"] != before["protected"]:
        raise SetupError("PROTECTED_METADATA_CHANGED")
    if {row["name"]: row["canonicalHash"] for row in data["bootstrap"]} != artifact.installed_hashes:
        raise SetupError("BOOTSTRAP_DEFINITION_INVALID")
    if (data["transactionCount"], data["xactState"]) != ((1, 1) if in_transaction else (0, 0)):
        raise SetupError("TRANSACTION_INVALID")


def wrapper_bytes(mode, before, artifact):
    if mode not in ("rehearse", "apply"):
        raise SetupError("COMMAND_INVALID")
    validate_baseline(before, artifact)
    prefix = ":ON ERROR EXIT\nSET NOCOUNT ON; SET XACT_ABORT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;\n" + GUARDS + snapshot_sql()
    prefix += "IF @a62_transactionCount<>0 OR @a62_xactState<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL'),0)<>1 OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_runtime_executor') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor') IS NOT NULL THROW 59999,N'QA setup preconditions failed',1;\n"
    prefix += "IF JSON_VALUE(@a62_snapshot,'$.fingerprint')<>" + literal(before["fingerprint"]) + " THROW 59999,N'QA baseline changed',1;\nBEGIN TRANSACTION;\nGO\n"
    suffix = "\nSET NOCOUNT ON;\nIF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'QA transaction invalid',1;\n" + GUARDS + snapshot_sql()
    suffix += "DECLARE @a62_expected TABLE(role_name sysname COLLATE DATABASE_DEFAULT,object_name sysname COLLATE DATABASE_DEFAULT,permission_name sysname COLLATE DATABASE_DEFAULT,permission_state char(1) COLLATE DATABASE_DEFAULT);\nINSERT @a62_expected VALUES\n"
    suffix += ",\n".join("(" + ",".join(literal(row[key]) for key in ("role", "objectName", "permissionName", "state")) + ")" for row in artifact.acl) + ";\n"
    actual = "SELECT r.name COLLATE DATABASE_DEFAULT,OBJECT_NAME(p.major_id) COLLATE DATABASE_DEFAULT,p.permission_name COLLATE DATABASE_DEFAULT,p.state COLLATE DATABASE_DEFAULT FROM sys.database_permissions p JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name IN (N'hp_runtime_executor',N'hp_bootstrap_executor')"
    suffix += "IF EXISTS(SELECT role_name,object_name,permission_name,permission_state FROM @a62_expected EXCEPT " + actual + ") OR EXISTS(" + actual + " EXCEPT SELECT role_name,object_name,permission_name,permission_state FROM @a62_expected) OR (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))<>562 OR EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')) AND (class<>1 OR minor_id<>0 OR OBJECT_SCHEMA_NAME(major_id)<>N'dbo')) THROW 59999,N'QA exact ACL mismatch',1;\n"
    suffix += "IF (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') AND type='R' AND owning_principal_id=DATABASE_PRINCIPAL_ID(N'dbo'))<>2 THROW 59999,N'QA role ownership mismatch',1;\n"
    for part in PARTS:
        suffix += "IF JSON_VALUE(@a62_snapshot,'$.protected." + part + "')<>" + literal(before["protected"][part]) + " THROW 59999,N'QA protected metadata mismatch',1;\n"
    for index, (name, body) in enumerate(artifact.canonical_bodies.items()):
        variable = "@a62_expectedBootstrap" + str(index)
        suffix += "DECLARE " + variable + " nvarchar(max)=REPLACE(" + literal(body) + ",NCHAR(13),N'');\n"
        suffix += "IF NOT EXISTS(SELECT 1 FROM OPENJSON(@a62_bootstrapBodies) WITH(name sysname '$.name',canonicalBody nvarchar(max) '$.canonicalBody') definitions WHERE name COLLATE Latin1_General_100_BIN2=" + literal(name) + " COLLATE Latin1_General_100_BIN2 AND canonicalBody IS NOT NULL AND canonicalBody COLLATE Latin1_General_100_BIN2=" + variable + " COLLATE Latin1_General_100_BIN2 AND DATALENGTH(canonicalBody)=DATALENGTH(" + variable + ")) THROW 59999,N'QA bootstrap definition mismatch',1;\n"
    suffix += "-- All postconditions above must pass before the only terminal transaction action.\n"
    suffix += "COMMIT TRANSACTION;\n" if mode == "apply" else "ROLLBACK TRANSACTION;\n"
    suffix += EMIT
    return prefix.encode("utf-8") + artifact.raw + suffix.encode("utf-8")


class Transport:
    def __init__(self, *, run=subprocess.run, resolve=shutil.which, environ=None):
        self.run = run
        self.executable = resolve("sqlcmd")
        self.environment = A61.child_environment(os.environ if environ is None else environ)
        self.calls = []

    def execute(self, *, query=None, path=None):
        record = {"kind": "wrapper" if path else "snapshot", "raw_exit_code": None}
        self.calls.append(record)
        if not self.executable:
            raise SetupError("SQLCMD_NOT_FOUND")
        argv = A61.sqlcmd_arguments(self.executable)[:-2]
        argv += ["-i", str(path)] if path else ["-Q", query]
        try:
            response = self.run(argv, shell=False, env=self.environment, capture_output=True, text=True, encoding="utf-8-sig", errors="strict", timeout=15, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
            record["raw_exit_code"] = response.returncode if type(response.returncode) is int else None
            if type(response.returncode) is not int or response.returncode != 0:
                diagnostic = response.stderr if isinstance(response.stderr, str) else ""
                record["sql_error_numbers"] = sorted({int(value) for value in re.findall(r"\bMsg\s+([0-9]{1,6})\b", diagnostic)})
                record["sql_error_lines"] = sorted({int(value) for value in re.findall(r"\bLine\s+([0-9]{1,6})\b", diagnostic)})
                raise SetupError("SQLCMD_FAILED")
            try:
                return parse_snapshot(response.stdout)
            except SetupError as failure:
                stages = {"text", "framing", "chunk", "checksum", "json", "fields", "protected", "hashes", "types", "arrays"}
                if len(failure.args) == 2 and failure.args[1] in stages:
                    record["response_stage"] = failure.args[1]
                    record["response_line_count"] = len(response.stdout.splitlines())
                raise
        except subprocess.TimeoutExpired:
            raise SetupError("SQLCMD_TIMEOUT") from None
        except FileNotFoundError:
            raise SetupError("SQLCMD_NOT_FOUND") from None

    def snapshot(self):
        return self.execute(query="SET NOCOUNT ON;\n" + GUARDS + snapshot_sql() + EMIT)


def execute(mode, *, transport=None, artifact_loader=Artifact.load, directory=TEMP, registry_reader=None):
    result = {"status": "error", "command": mode if mode in ("plan", "rehearse", "apply") else None, "database": A61.DATABASE, "scope": A61.SCOPE, "scope_validated": False, "jdbc_positive_validated": False, "limits": list(LIMITS)}
    if mode not in ("plan", "rehearse", "apply"):
        result["error"] = "COMMAND_INVALID"
        return 1, result
    before, mutation_attempted = None, False
    try:
        transport = transport or Transport()
        artifact = artifact_loader()
        before = transport.snapshot()
        validate_baseline(before, artifact)
        result["scope_validated"] = True
        result["fingerprint_before"] = before["fingerprint"]
        result["inventory"] = {"procedures": 133, "tables": 37, "triggers": 31, "expected_acl": 562, "altered_procedures": list(BOOTSTRAP)}
        if registry_reader is None:
            import winreg
            registry_reader = lambda: A61.registry_metadata(winreg)
        result["transport_registry"] = registry_reader()
        result["integrated_security_only"] = before["metadata"]["integratedSecurityOnly"]
        if mode == "plan":
            result.update(status="planned", fingerprint_after=before["fingerprint"])
        else:
            folder = Path(directory) / (mode + "-" + uuid.uuid4().hex)
            folder.mkdir(parents=True, exist_ok=False)
            frozen = wrapper_bytes(mode, before, artifact)
            wrapper = folder / "wrapper.sql"
            wrapper.write_bytes(frozen)
            (folder / "V8.frozen.sql").write_bytes(artifact.raw)
            (folder / "before.json").write_text(json.dumps(before, indent=2), encoding="utf-8")
            result["artifacts"] = str(folder)
            result["wrapper_sha256"] = sha(frozen)
            result["v8_sha256"] = sha(artifact.raw)
            mutation_attempted = True
            inside = transport.execute(path=wrapper)
            validate_installed(inside, before, artifact, True)
            result["inside_fingerprint"] = inside["fingerprint"]
            (folder / "inside.json").write_text(json.dumps(inside, indent=2), encoding="utf-8")
            after = transport.snapshot()  # Always a new administrative sqlcmd connection.
            (folder / "after.json").write_text(json.dumps(after, indent=2), encoding="utf-8")
            if mode == "rehearse":
                validate_baseline(after, artifact)
                if after != before:
                    raise SetupError("CLEANUP_MISMATCH")
            else:
                validate_installed(after, before, artifact, False)
                if after["fingerprint"] != inside["fingerprint"]:
                    raise SetupError("PERSISTENCE_MISMATCH")
            result.update(status="rehearsed" if mode == "rehearse" else "applied", fingerprint_after=after["fingerprint"], cleanup_verified=mode == "rehearse")
        result["sqlcmd_calls"] = transport.calls
        return 0, result
    except Exception as failure:
        code = failure.args[0] if isinstance(failure, (SetupError, A61.PreflightError)) and failure.args else "INSPECTION_ERROR"
        result["error"] = code if isinstance(code, str) and code in ERRORS else "INSPECTION_ERROR"
        if mutation_attempted:
            try:
                after = transport.snapshot()
                result["fingerprint_after_error"] = after["fingerprint"]
                result["cleanup_after_error_verified"] = after == before
            except Exception:
                result["cleanup_after_error_verified"] = False
        result["sqlcmd_calls"] = getattr(transport, "calls", [])
        return 1, result


def main(argv=None, **dependencies):
    args = sys.argv[1:] if argv is None else argv
    mode = args[0] if len(args) == 1 and args[0] in ("plan", "rehearse", "apply") else "plan" if not args else None
    code, result = execute(mode, **dependencies)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return code


if __name__ == "__main__":
    sys.exit(main())
