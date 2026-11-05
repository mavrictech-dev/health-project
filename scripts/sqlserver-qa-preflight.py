"""Read-only preconditions for the fixed local synthetic SQL Server QA database."""
import json
import os
import re
import shutil
import subprocess
import sys

DATABASE = "health_project_sqlserver_qa_20261103"
SCOPE = "Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data"
INSTANCE_KEY = r"SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
INSTANCE_ROOT = r"SOFTWARE\Microsoft\Microsoft SQL Server"
QUERY = """SELECT DB_NAME() AS databaseName,
 CONVERT(nvarchar(4000),(SELECT value FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope')) AS scope,
 CONVERT(nvarchar(128),SERVERPROPERTY('ProductVersion')) AS productVersion,
 CONVERT(int,SERVERPROPERTY('IsIntegratedSecurityOnly')) AS integratedSecurityOnly,
 (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) AS compatibilityLevel,
 (SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) AS procedureCount,
 (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) AS userTableCount,
 (SELECT type FROM sys.database_principals WHERE name=N'hp_runtime_executor') AS runtimeRoleType,
 (SELECT type FROM sys.database_principals WHERE name=N'hp_bootstrap_executor') AS bootstrapRoleType
 FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER;"""
FIELDS = {"databaseName", "scope", "productVersion", "integratedSecurityOnly", "compatibilityLevel", "procedureCount", "userTableCount", "runtimeRoleType", "bootstrapRoleType"}
LIMITS = [
    "Administrative Windows sqlcmd metadata inspection is separate from runtime SQL authentication.",
    "Role existence does not validate grants, a runtime login, identity, TLS, transaction/reset behavior or durability.",
    "Configured ports and protocol flags do not prove an ordinary TCP listener or successful JDBC connectivity.",
    "Inventory counts do not prove migration equivalence; runtime must independently confirm its destination.",
]
MESSAGES = {
    "ARGUMENTS_NOT_SUPPORTED": "This preflight accepts no arguments or alternative destinations.",
    "SQLCMD_NOT_FOUND": "The installed ODBC sqlcmd executable is required.",
    "SQLCMD_FAILED": "Administrative metadata inspection failed; no raw output is disclosed.",
    "SQLCMD_TIMEOUT": "Administrative metadata inspection exceeded its bounded timeout.",
    "METADATA_INVALID": "Metadata response is incomplete, ambiguous or malformed.",
    "SCOPE_MISMATCH": "The database or its synthetic QA marker does not match the fixed scope.",
    "REGISTRY_INVALID": "Default-instance registry inspection failed or returned unknown values.",
    "INSPECTION_ERROR": "Unexpected preflight inspection error; no raw cause is disclosed.",
}


class PreflightError(Exception):
    pass


def child_environment(environ):
    allowed = {"SYSTEMROOT", "WINDIR", "SYSTEMDRIVE", "TEMP", "TMP", "COMSPEC"}
    return {key: value for key, value in environ.items() if key.upper() in allowed}


def sqlcmd_arguments(executable):
    # -y 0 uses unformatted output without JSON truncation; -h/-W are incompatible.
    # -X1/-x disable startup scripts, sqlcmd environment variables and substitution.
    return [executable, "-S", "localhost", "-d", DATABASE, "-E", "-C", "-b", "-l", "5", "-t", "5", "-f", "65001", "-y", "0", "-w", "65535", "-r", "1", "-X1", "-x", "-Q", QUERY]


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise PreflightError("METADATA_INVALID")
        result[key] = value
    return result


def parse_metadata(stdout):
    if not isinstance(stdout, str):
        raise PreflightError("METADATA_INVALID")
    lines = [line.strip() for line in stdout.lstrip("\ufeff").splitlines() if line.strip()]
    # SELECT-only query: accept only its exact, known one-row footer, if emitted.
    if lines and lines[-1] == "(1 rows affected)":
        lines.pop()
    if len(lines) != 1:
        raise PreflightError("METADATA_INVALID")
    try:
        data = json.loads(lines[0], object_pairs_hook=unique_object)
    except (ValueError, TypeError):
        raise PreflightError("METADATA_INVALID") from None
    if not isinstance(data, dict) or set(data) != FIELDS:
        raise PreflightError("METADATA_INVALID")
    if data["databaseName"] != DATABASE or data["scope"] != SCOPE:
        raise PreflightError("SCOPE_MISMATCH")
    if not isinstance(data["productVersion"], str) or not re.fullmatch(r"16\.\d+\.\d+\.\d+", data["productVersion"]):
        raise PreflightError("METADATA_INVALID")
    for key in ("integratedSecurityOnly", "compatibilityLevel", "procedureCount", "userTableCount"):
        if type(data[key]) is not int:
            raise PreflightError("METADATA_INVALID")
    if data["integratedSecurityOnly"] not in (0, 1) or data["compatibilityLevel"] not in (100, 110, 120, 130, 140, 150, 160):
        raise PreflightError("METADATA_INVALID")
    if any(data[key] < 0 for key in ("procedureCount", "userTableCount")):
        raise PreflightError("METADATA_INVALID")
    if any(data[key] not in (None, "R") for key in ("runtimeRoleType", "bootstrapRoleType")):
        raise PreflightError("METADATA_INVALID")
    return data


def registry_metadata(registry):
    access = registry.KEY_READ | registry.KEY_WOW64_64KEY

    def read(path, name, expected_type):
        with registry.OpenKey(registry.HKEY_LOCAL_MACHINE, path, 0, access) as key:
            value, kind = registry.QueryValueEx(key, name)
        if kind != expected_type:
            raise PreflightError("REGISTRY_INVALID")
        return value

    try:
        instance = read(INSTANCE_KEY, "MSSQLSERVER", registry.REG_SZ)
        if not isinstance(instance, str) or not re.fullmatch(r"MSSQL16\.MSSQLSERVER", instance):
            raise PreflightError("REGISTRY_INVALID")
        network = INSTANCE_ROOT + "\\" + instance + r"\MSSQLServer\SuperSocketNetLib"
        tcp = read(network + r"\Tcp", "Enabled", registry.REG_DWORD)
        np = read(network + r"\Np", "Enabled", registry.REG_DWORD)
        if any(type(value) is not int or value not in (0, 1) for value in (tcp, np)):
            raise PreflightError("REGISTRY_INVALID")
        port = read(network + r"\Tcp\IPAll", "TcpPort", registry.REG_SZ)
        dynamic = read(network + r"\Tcp\IPAll", "TcpDynamicPorts", registry.REG_SZ)
        if not isinstance(port, str) or not isinstance(dynamic, str):
            raise PreflightError("REGISTRY_INVALID")
        if port:
            ports = port.split(",")
            if len(set(ports)) != len(ports) or any(not re.fullmatch(r"[0-9]{1,5}", item) or not 1 <= int(item) <= 65535 for item in ports):
                raise PreflightError("REGISTRY_INVALID")
        if dynamic and (not re.fullmatch(r"[0-9]{1,5}", dynamic) or not 0 <= int(dynamic) <= 65535):
            raise PreflightError("REGISTRY_INVALID")
        return {"instanceId": instance, "tcpEnabled": tcp, "npEnabled": np, "configuredTcpPort": port, "configuredDynamicPorts": dynamic}
    except Exception:
        raise PreflightError("REGISTRY_INVALID") from None


def inspect_environment(*, run=subprocess.run, resolve=shutil.which, registry=None, environ=None):
    result = {"status": "ERROR", "scope_validated": False, "jdbc_positive_validated": False, "checks": [], "limits": list(LIMITS)}
    try:
        executable = resolve("sqlcmd")
        if not executable:
            raise PreflightError("SQLCMD_NOT_FOUND")
        try:
            response = run(sqlcmd_arguments(executable), env=child_environment(os.environ if environ is None else environ), shell=False, capture_output=True, text=True, encoding="utf-8-sig", errors="strict", timeout=15, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        except FileNotFoundError:
            raise PreflightError("SQLCMD_NOT_FOUND") from None
        except subprocess.TimeoutExpired:
            raise PreflightError("SQLCMD_TIMEOUT") from None
        if type(response.returncode) is not int or response.returncode != 0:
            raise PreflightError("SQLCMD_FAILED")
        metadata = parse_metadata(response.stdout)
        result["metadata"] = metadata
        result["scope_validated"] = True
        result["checks"].append({"id": "fixed_database_and_marker", "status": "PASS"})
        if registry is None:
            try:
                import winreg as registry
            except ImportError:
                raise PreflightError("REGISTRY_INVALID") from None
        network = registry_metadata(registry)
        result["registry"] = network
        result["checks"].append({"id": "local_default_instance_registry", "status": "PASS"})
        for name, ready, diagnostic in (
            ("ordinary_tcp_enabled", network["tcpEnabled"] == 1, "Ordinary TCP is disabled; NP does not replace the runtime TCP transport."),
            ("runtime_sql_auth_compatible", metadata["integratedSecurityOnly"] == 0, "Windows-only authentication is incompatible with the current SQL username/password runtime."),
            ("runtime_role_present", metadata["runtimeRoleType"] == "R", "Runtime executor role is absent; separate setup is pending."),
            ("bootstrap_role_present", metadata["bootstrapRoleType"] == "R", "Bootstrap executor role is absent; separate setup is pending."),
        ):
            item = {"id": name, "status": "PASS" if ready else "BLOCKED"}
            if not ready:
                item["diagnostic"] = diagnostic
            result["checks"].append(item)
        blocked = any(item["status"] == "BLOCKED" for item in result["checks"])
        result["status"] = "BLOCKED" if blocked else "READY_FOR_JDBC_TEST"
        return (2 if blocked else 0), result
    except PreflightError as failure:
        code = failure.args[0]
        if code not in MESSAGES:
            code = "INSPECTION_ERROR"
    except Exception:
        code = "INSPECTION_ERROR"
    result["error"] = {"code": code, "diagnostic": MESSAGES[code]}
    return 1, result


def main(argv=None, **dependencies):
    arguments = sys.argv[1:] if argv is None else argv
    if arguments:
        result = {"status": "ERROR", "scope_validated": False, "jdbc_positive_validated": False, "checks": [], "limits": list(LIMITS), "error": {"code": "ARGUMENTS_NOT_SUPPORTED", "diagnostic": MESSAGES["ARGUMENTS_NOT_SUPPORTED"]}}
        exit_code = 1
    else:
        exit_code, result = inspect_environment(**dependencies)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
