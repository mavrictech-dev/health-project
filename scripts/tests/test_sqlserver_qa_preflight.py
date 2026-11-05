"""CPU-only preflight tests: injected sqlcmd/registry, no database or service access."""
from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("sqlserver_qa_preflight", Path(__file__).resolve().parents[1] / "sqlserver-qa-preflight.py")
preflight = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(preflight)
CANARY = "do-not-disclose-synthetic-private-value"


def valid_metadata(**changes):
    data = {"databaseName": preflight.DATABASE, "scope": preflight.SCOPE, "productVersion": "16.0.1000.6", "integratedSecurityOnly": 0, "compatibilityLevel": 160, "procedureCount": 133, "userTableCount": 37, "runtimeRoleType": "R", "bootstrapRoleType": "R"}
    data.update(changes)
    return data


class Handle:
    def __init__(self, path):
        self.path = path

    def __enter__(self):
        return self

    def __exit__(self, *arguments):
        return False


class Registry:
    KEY_READ, KEY_WOW64_64KEY, HKEY_LOCAL_MACHINE, REG_SZ, REG_DWORD = 1, 256, object(), 1, 4

    def __init__(self, tcp=1, np=0):
        network = preflight.INSTANCE_ROOT + r"\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib"
        self.values = {
            (preflight.INSTANCE_KEY, "MSSQLSERVER"): ("MSSQL16.MSSQLSERVER", self.REG_SZ),
            (network + r"\Tcp", "Enabled"): (tcp, self.REG_DWORD),
            (network + r"\Np", "Enabled"): (np, self.REG_DWORD),
            (network + r"\Tcp\IPAll", "TcpPort"): ("1433", self.REG_SZ),
            (network + r"\Tcp\IPAll", "TcpDynamicPorts"): ("", self.REG_SZ),
        }
        self.opened = []

    def OpenKey(self, hive, path, reserved, access):
        self.opened.append((hive, path, reserved, access))
        return Handle(path)

    def QueryValueEx(self, key, name):
        try:
            return self.values[(key.path, name)]
        except KeyError:
            raise FileNotFoundError(CANARY) from None


class PreflightTests(unittest.TestCase):
    def inspect(self, data=None, registry=None, stdout=None, run=None, resolve=None, environ=None):
        self.calls = []
        self.registry = registry if registry is not None else Registry()

        def sqlcmd(argv, **options):
            self.calls.append((argv, options))
            return subprocess.CompletedProcess(argv, 0, json.dumps(valid_metadata() if data is None else data) if stdout is None else stdout, CANARY)

        return preflight.inspect_environment(run=run or sqlcmd, resolve=resolve or (lambda name: "C:/synthetic/SQLCMD.EXE"), registry=self.registry, environ={} if environ is None else environ)

    def assert_error(self, code, result, error=None):
        self.assertEqual(code, 1)
        self.assertEqual(result["status"], "ERROR")
        self.assertIs(result["jdbc_positive_validated"], False)
        if error:
            self.assertEqual(result["error"]["code"], error)
        self.assertNotIn(CANARY, json.dumps(result))

    def test_candidate_is_not_jdbc_validation_and_has_all_explicit_limits(self):
        code, result = self.inspect()
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "READY_FOR_JDBC_TEST")
        self.assertTrue(result["scope_validated"])
        self.assertIs(result["jdbc_positive_validated"], False)
        self.assertEqual(len(result["checks"]), 6)
        self.assertTrue(all(item["status"] == "PASS" for item in result["checks"]))
        self.assertTrue(any("Role existence" in item for item in result["limits"]))
        self.assertEqual(len(self.calls), 1)

    def test_scope_wrong_or_missing_stops_before_any_registry_inspection(self):
        for changes in ({"databaseName": "foreign"}, {"scope": None}, {"scope": preflight.SCOPE + " "}, {"scope": CANARY}):
            with self.subTest(fields=list(changes)):
                code, result = self.inspect(valid_metadata(**changes))
                self.assert_error(code, result, "SCOPE_MISMATCH")
                self.assertFalse(result["scope_validated"])
                self.assertEqual(self.registry.opened, [])

    def test_malformed_duplicate_multiple_responses_headers_or_missing_columns_are_errors(self):
        missing = valid_metadata()
        del missing["scope"]
        for raw in ("", CANARY, "[]", "null", "{}", json.dumps(missing), json.dumps(valid_metadata()) + '\n' + json.dumps(valid_metadata()), json.dumps(valid_metadata())[:-1] + ',"scope":"duplicate"}', 'databaseName\n' + json.dumps(valid_metadata()), json.dumps(valid_metadata()) + '\n(2 rows affected)'):
            with self.subTest(case=raw[:1]):
                code, result = self.inspect(stdout=raw)
                self.assert_error(code, result, "METADATA_INVALID")
                self.assertEqual(self.registry.opened, [])

    def test_sqlcmd_unwrapped_json_and_known_single_row_footer_are_accepted(self):
        for wrapper in (lambda body: body, lambda body: '\ufeff\n' + body + '\n\n(1 rows affected)\n'):
            code, result = self.inspect(stdout=wrapper(json.dumps(valid_metadata())))
            self.assertEqual(code, 0)
            self.assertTrue(result["scope_validated"])

    def test_metadata_types_versions_roles_and_flags_fail_closed(self):
        invalid = [("integratedSecurityOnly", True), ("integratedSecurityOnly", 2), ("integratedSecurityOnly", None), ("compatibilityLevel", "160"), ("compatibilityLevel", 999), ("procedureCount", -1), ("procedureCount", 133.0), ("userTableCount", False), ("runtimeRoleType", "S"), ("bootstrapRoleType", False), ("productVersion", "unknown"), ("productVersion", "17.0.1.1"), ("productVersion", None), ("extraPrivateField", CANARY)]
        for field, value in invalid:
            with self.subTest(field=field):
                code, result = self.inspect(valid_metadata(**{field: value}))
                self.assert_error(code, result, "METADATA_INVALID")
                self.assertEqual(self.registry.opened, [])

    def test_sqlcmd_missing_nonzero_timeout_and_unexpected_errors_are_safe(self):
        code, result = self.inspect(resolve=lambda name: None)
        self.assert_error(code, result, "SQLCMD_NOT_FOUND")
        self.assertEqual(self.calls, [])
        for failure, expected in ((FileNotFoundError(CANARY), "SQLCMD_NOT_FOUND"), (subprocess.TimeoutExpired(CANARY, 15, output=CANARY, stderr=CANARY), "SQLCMD_TIMEOUT"), (PermissionError(CANARY), "INSPECTION_ERROR"), (UnicodeDecodeError("utf-8", b'\xff', 0, 1, CANARY), "INSPECTION_ERROR")):
            def run(*args, **kwargs):
                raise failure
            code, result = self.inspect(run=run)
            self.assert_error(code, result, expected)
            self.assertEqual(self.registry.opened, [])
        for status in (1, -1, True, None):
            code, result = self.inspect(run=lambda *args, **kwargs: subprocess.CompletedProcess([], status, CANARY, CANARY))
            self.assert_error(code, result, "SQLCMD_FAILED")

    def test_fixed_arguments_read_only_query_and_sanitized_environment(self):
        environment = {"SystemRoot": "C:/Windows", "TEMP": "C:/synthetic-temp", "COMSPEC": "C:/Windows/cmd.exe", "PATH": CANARY, "SQLCMDINI": CANARY, "SQLCMDPASSWORD": CANARY, "DATABASE_PASSWORD": CANARY, "MIGRATION_PASSWORD": CANARY, "SMTP_HOST": CANARY}
        before = dict(environment)
        code, _ = self.inspect(environ=environment)
        self.assertEqual(code, 0)
        argv, options = self.calls[0]
        self.assertEqual(argv, preflight.sqlcmd_arguments("C:/synthetic/SQLCMD.EXE"))
        for option, value in (("-S", "localhost"), ("-d", preflight.DATABASE), ("-f", "65001"), ("-y", "0"), ("-Q", preflight.QUERY)):
            self.assertEqual(argv[argv.index(option) + 1], value)
        for flag in ("-E", "-C", "-b", "-X1", "-x"):
            self.assertIn(flag, argv)
        for flag in ("-A", "-U", "-P", "-i", "-W", "-h"):
            self.assertNotIn(flag, argv)
        self.assertEqual(options["timeout"], 15)
        self.assertFalse(options["shell"])
        self.assertEqual(options["encoding"], "utf-8-sig")
        self.assertEqual(options["env"], {k: environment[k] for k in ("SystemRoot", "TEMP", "COMSPEC")})
        self.assertEqual(environment, before)
        self.assertNotIn(CANARY, str(argv) + str(options))
        self.assertTrue(preflight.QUERY.startswith("SELECT "))
        for token in ("INSERT ", "UPDATE ", "DELETE ", "EXEC ", "USE ", "CREATE ", "ALTER ", "DROP ", "GRANT ", "REVOKE ", "SET ", "xp_cmdshell", "dbo."):
            self.assertNotIn(token, preflight.QUERY)

    def test_registry_only_reads_default_instance_and_its_whitelisted_paths(self):
        self.inspect()
        registry = self.registry
        self.assertEqual(len(registry.opened), 5)
        for hive, path, reserved, access in registry.opened:
            self.assertIs(hive, registry.HKEY_LOCAL_MACHINE)
            self.assertEqual(reserved, 0)
            self.assertEqual(access, registry.KEY_READ | registry.KEY_WOW64_64KEY)
            self.assertTrue(path == preflight.INSTANCE_KEY or path.startswith(preflight.INSTANCE_ROOT + r"\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib" + "\\"))

    def test_registry_missing_wrong_types_unknown_flags_and_invalid_ports_are_errors(self):
        initial = Registry()
        for key in initial.values:
            registry = Registry()
            del registry.values[key]
            code, result = self.inspect(registry=registry)
            self.assert_error(code, result, "REGISTRY_INVALID")
        for key, original in initial.values.items():
            bad_values = (True, -1, 2, "0", None) if key[1] == "Enabled" else (None, CANARY, 1433)
            for value in bad_values:
                registry = Registry()
                registry.values[key] = (value, original[1])
                code, result = self.inspect(registry=registry)
                self.assert_error(code, result, "REGISTRY_INVALID")
            registry = Registry()
            registry.values[key] = (original[0], 99)
            code, result = self.inspect(registry=registry)
            self.assert_error(code, result, "REGISTRY_INVALID")

    def test_invalid_instance_cannot_select_arbitrary_registry_subtrees(self):
        for instance in (r"..\foreign", "MSSQL16.FOREIGN", "MSSQL17.MSSQLSERVER", r"MSSQL16.MSSQLSERVER\foreign", "", "MSSQL16.MSSQLSERVER/foreign"):
            registry = Registry()
            registry.values[(preflight.INSTANCE_KEY, "MSSQLSERVER")] = (instance, registry.REG_SZ)
            code, result = self.inspect(registry=registry)
            self.assert_error(code, result, "REGISTRY_INVALID")
            self.assertEqual(len(registry.opened), 1)

    def test_known_transport_auth_and_setup_preconditions_are_blocked_not_error(self):
        for metadata, registry, name in ((valid_metadata(), Registry(tcp=0), "ordinary_tcp_enabled"), (valid_metadata(integratedSecurityOnly=1), Registry(), "runtime_sql_auth_compatible"), (valid_metadata(runtimeRoleType=None), Registry(), "runtime_role_present"), (valid_metadata(bootstrapRoleType=None), Registry(), "bootstrap_role_present")):
            code, result = self.inspect(metadata, registry=registry)
            self.assertEqual(code, 2)
            self.assertEqual(result["status"], "BLOCKED")
            self.assertTrue(result["scope_validated"])
            self.assertIs(result["jdbc_positive_validated"], False)
            self.assertEqual([item["id"] for item in result["checks"] if item["status"] == "BLOCKED"], [name])
        code, result = self.inspect(valid_metadata(integratedSecurityOnly=1, runtimeRoleType=None, bootstrapRoleType=None), registry=Registry(tcp=0, np=1))
        self.assertEqual(code, 2)
        self.assertEqual(sum(item["status"] == "BLOCKED" for item in result["checks"]), 4)

    def test_np_is_diagnostic_and_ports_do_not_claim_listener_or_jdbc_success(self):
        for np in (0, 1):
            registry = Registry(np=np)
            network = preflight.INSTANCE_ROOT + r"\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
            registry.values[(network, "TcpPort")] = ("", registry.REG_SZ)
            registry.values[(network, "TcpDynamicPorts")] = ("0", registry.REG_SZ)
            code, result = self.inspect(registry=registry)
            self.assertEqual(code, 0)
            self.assertEqual(result["registry"]["npEnabled"], np)
            self.assertIs(result["jdbc_positive_validated"], False)

    def test_cli_rejects_options_and_prints_only_safe_json(self):
        for args in (["--host=" + CANARY], ["--database=" + CANARY], ["--help"]):
            output = io.StringIO()
            with redirect_stdout(output), patch.object(preflight, "inspect_environment", side_effect=AssertionError("must not inspect")):
                code = preflight.main(args)
            self.assertEqual(code, 1)
            self.assertNotIn(CANARY, output.getvalue())
            self.assertEqual(json.loads(output.getvalue())["error"]["code"], "ARGUMENTS_NOT_SUPPORTED")
        output = io.StringIO()
        with redirect_stdout(output):
            code = preflight.main([], registry=Registry(tcp=0), run=lambda *args, **kwargs: subprocess.CompletedProcess([], 0, json.dumps(valid_metadata(integratedSecurityOnly=1)), CANARY), resolve=lambda name: "SQLCMD.EXE", environ={"SQLCMDPASSWORD": CANARY})
        self.assertEqual(code, 2)
        self.assertEqual(json.loads(output.getvalue())["status"], "BLOCKED")
        self.assertNotIn(CANARY, output.getvalue())


if __name__ == "__main__":
    unittest.main()
