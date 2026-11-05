"""No SQL engine: exercise permissions gates and SQL wrapper ordering with doubles."""
from contextlib import redirect_stdout
from copy import deepcopy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("qa_permissions", Path(__file__).resolve().parents[1] / "sqlserver-qa-permissions.py")
setup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(setup)
CANARY = "synthetic-private-cause-do-not-print"


def baseline(artifact):
    return {"metadata": {"databaseName": setup.A61.DATABASE, "scope": setup.A61.SCOPE, "productVersion": "16.0.1000.6", "integratedSecurityOnly": 1, "compatibilityLevel": 160, "procedureCount": 133, "userTableCount": 37, "runtimeRoleType": None, "bootstrapRoleType": None}, "controlDatabase": 1, "transactionCount": 0, "xactState": 0, "historyPresent": 0, "protected": {key: 'A' * 64 for key in setup.PARTS}, "bootstrap": [{"name": name, "rawHash": 'C' * 64, "canonicalHash": 'D' * 64} for name in setup.BOOTSTRAP], "roles": [], "acl": [], "procedures": [{"schemaName": "dbo", "name": name} for name in sorted(artifact.procedures)], "tables": [{"schemaName": "dbo", "name": name} for name in sorted(artifact.tables)], "triggers": [{"schemaName": "dbo", "name": name, "parentName": parent} for name, parent in sorted(artifact.triggers.items())], "fingerprint": 'E' * 64}


def installed(before, artifact, transaction=True):
    data = deepcopy(before)
    data["roles"] = [{"name": role, "type": "R", "owner": "dbo"} for role in setup.ROLES]
    data["acl"] = deepcopy(artifact.acl)
    data["metadata"].update(runtimeRoleType="R", bootstrapRoleType="R")
    data["bootstrap"] = [{"name": name, "rawHash": 'F' * 64, "canonicalHash": value} for name, value in artifact.installed_hashes.items()]
    data.update(transactionCount=1 if transaction else 0, xactState=1 if transaction else 0, fingerprint='F' * 64)
    return data


def framed(data):
    raw = json.dumps(data, ensure_ascii=False).encode("utf-16le")
    return '\n'.join('A62JSON:' + raw[index:index + 2000].hex().upper() for index in range(0, len(raw), 2000)) + '\nA62END:' + setup.sha(raw) + '\n'


class ModelTransport:
    def __init__(self, snapshots, inside=None, error=None):
        self.snapshots = list(snapshots)
        self.inside = inside
        self.error = error
        self.calls = []
        self.wrappers = []

    def snapshot(self):
        self.calls.append({"kind": "snapshot", "raw_exit_code": 0})
        value = self.snapshots.pop(0)
        if isinstance(value, Exception):
            raise value
        return deepcopy(value)

    def execute(self, *, path):
        self.calls.append({"kind": "wrapper", "raw_exit_code": 1 if self.error else 0})
        self.wrappers.append(Path(path).read_bytes())
        if self.error:
            raise self.error
        return deepcopy(self.inside)


class PermissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.artifact = setup.Artifact.load()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.before = baseline(self.artifact)
        self.inside = installed(self.before, self.artifact)

    def execute(self, mode, transport, **kwargs):
        return setup.execute(mode, transport=transport, artifact_loader=lambda: self.artifact, directory=Path(self.temp.name), registry_reader=lambda: {"tcpEnabled": 0, "npEnabled": 0, "configuredTcpPort": "1433"}, **kwargs)

    def safe_error(self, code, result, error=None):
        self.assertEqual(code, 1)
        self.assertEqual(result["status"], "error")
        self.assertIs(result["jdbc_positive_validated"], False)
        self.assertNotIn(CANARY, json.dumps(result))
        if error:
            self.assertEqual(result["error"], error)

    def test_immutable_artifact_closed_inventories_and_exact_literal_matrix(self):
        a = self.artifact
        self.assertEqual((len(a.procedures), len(a.tables), len(a.triggers), len(a.acl)), (133, 37, 31, 562))
        self.assertEqual(sum(row["state"] == "G" and row["role"] == "hp_runtime_executor" for row in a.acl), 107)
        self.assertEqual(sum(row["state"] == "G" and row["role"] == "hp_bootstrap_executor" for row in a.acl), 3)
        self.assertTrue(all(row["classId"] == 1 and row["schemaName"] == "dbo" and row["minorId"] == 0 for row in a.acl))
        self.assertFalse(any(row["objectName"] == "flyway_schema_history" for row in a.acl))
        lf = setup.Artifact(a.raw.replace(b'\r\n', b'\n'), setup.A7.read_bytes())
        self.assertEqual(lf.acl, a.acl)
        self.assertEqual(lf.installed_hashes, a.installed_hashes)

    def test_hash_mismatches_abort_before_any_sql_call(self):
        for raw, reference, expected in ((b'bad' + self.artifact.raw, setup.A7.read_bytes(), "ARTIFACT_HASH"), (self.artifact.raw, b'bad-reference', "REFERENCE_HASH")):
            transport = ModelTransport([])
            code, result = setup.execute("apply", transport=transport, artifact_loader=lambda: setup.Artifact(raw, reference))
            self.safe_error(code, result, expected)
            self.assertEqual(transport.calls, [])

    def test_default_plan_only_reads_and_reports_blockers_without_claiming_jdbc(self):
        transport = ModelTransport([self.before])
        output = io.StringIO()
        with redirect_stdout(output):
            code = setup.main([], transport=transport, artifact_loader=lambda: self.artifact, registry_reader=lambda: {"tcpEnabled": 0}, directory=Path(self.temp.name))
        result = json.loads(output.getvalue())
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "planned")
        self.assertEqual(result["fingerprint_before"], result["fingerprint_after"])
        self.assertIs(result["jdbc_positive_validated"], False)
        self.assertEqual([call["kind"] for call in transport.calls], ["snapshot"])
        self.assertEqual(list(Path(self.temp.name).iterdir()), [])

    def test_unknown_or_ambiguous_verbs_do_not_construct_transport_or_echo_arguments(self):
        for args in ([CANARY], ["APPLY"], ["apply", "--force"], ["--host=" + CANARY]):
            output = io.StringIO()
            with redirect_stdout(output), patch.object(setup, "Transport", side_effect=AssertionError("no SQL")):
                code = setup.main(args)
            self.safe_error(code, json.loads(output.getvalue()), "COMMAND_INVALID")

    def test_scope_roles_control_history_and_inventory_gates_run_before_wrapper(self):
        variants = []
        for field, value in (("scope", None), ("scope", setup.A61.SCOPE + ' '), ("databaseName", CANARY), ("runtimeRoleType", "R"), ("bootstrapRoleType", "R"), ("procedureCount", 134), ("compatibilityLevel", 150)):
            data = deepcopy(self.before)
            data["metadata"][field] = value
            variants.append(data)
        for field, value in (("controlDatabase", 0), ("historyPresent", 1), ("transactionCount", 1), ("roles", [{"name": setup.ROLES[0], "type": "R", "owner": "dbo"}]), ("acl", [self.artifact.acl[0]])):
            data = deepcopy(self.before)
            data[field] = value
            variants.append(data)
        data = deepcopy(self.before)
        data["tables"][0]["name"] = "extra_metadata"
        variants.append(data)
        data = deepcopy(self.before)
        data["triggers"][0]["parentName"] = "foreign_table"
        variants.append(data)
        for data in variants:
            transport = ModelTransport([data])
            code, result = self.execute("rehearse", transport)
            self.safe_error(code, result)
            self.assertEqual(len(transport.calls), 1)
            self.assertEqual(transport.wrappers, [])

    def test_rehearse_freezes_entire_v8_with_go_and_never_commits_then_checks_fresh_connection(self):
        transport = ModelTransport([self.before, self.before], self.inside)
        code, result = self.execute("rehearse", transport)
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "rehearsed")
        self.assertTrue(result["cleanup_verified"])
        self.assertEqual([call["kind"] for call in transport.calls], ["snapshot", "wrapper", "snapshot"])
        wrapper = transport.wrappers[0]
        self.assertEqual(wrapper.count(self.artifact.raw), 1)
        self.assertNotIn(b'COMMIT TRANSACTION;', wrapper)
        self.assertIn(b'ROLLBACK TRANSACTION;', wrapper)
        self.assertIn(b':ON ERROR EXIT', wrapper)
        self.assertTrue(wrapper.index(b'BEGIN TRANSACTION;') < wrapper.index(self.artifact.raw) < wrapper.index(b'ROLLBACK TRANSACTION;'))
        folder = Path(result["artifacts"])
        self.assertEqual((folder / 'V8.frozen.sql').read_bytes(), self.artifact.raw)
        self.assertEqual(result["wrapper_sha256"], setup.sha(wrapper))

    def test_explicit_apply_only_has_commit_after_sql_guards_and_all_postconditions(self):
        after = installed(self.before, self.artifact, False)
        transport = ModelTransport([self.before, after], self.inside)
        code, result = self.execute("apply", transport)
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "applied")
        self.assertEqual(result["sql_action"], "commit_verified")
        self.assertFalse(result["reconciliation_required"])
        self.assertFalse(result["retry_mutation"])
        self.assertIs(result["jdbc_positive_validated"], False)
        wrapper = transport.wrappers[0].decode('utf-8')
        self.assertEqual(wrapper.count('COMMIT TRANSACTION;'), 1)
        self.assertNotIn('ROLLBACK TRANSACTION;', wrapper)
        commit = wrapper.index('COMMIT TRANSACTION;')
        for gate in ('QA scope mismatch', 'QA setup preconditions failed', 'QA baseline changed', 'QA transaction invalid', 'QA exact ACL mismatch', 'QA role ownership mismatch', 'QA protected metadata mismatch', 'QA bootstrap definition mismatch'):
            self.assertLess(wrapper.rindex(gate), commit)
        self.assertGreater(wrapper.index("SELECT CONVERT(nvarchar(max),N'A62JSON:')"), commit)

    def test_exact_acl_missing_extra_or_wrong_state_rejected_even_if_count_unchanged(self):
        for alter in ('missing', 'extra', 'same-count-state', 'same-count-object', 'schema', 'class', 'minor', 'duplicate'):
            data = deepcopy(self.inside)
            if alter == 'missing':
                data['acl'].pop()
            elif alter == 'extra':
                data['acl'].append(deepcopy(data['acl'][0]))
            elif alter == 'duplicate':
                data['acl'][1] = deepcopy(data['acl'][0])
            else:
                field, value = {'same-count-state': ('state', 'W'), 'same-count-object': ('objectName', 'unexpected'), 'schema': ('schemaName', 'foreign'), 'class': ('classId', 3), 'minor': ('minorId', 1)}[alter]
                data['acl'][0][field] = value
            with self.assertRaisesRegex(setup.SetupError, 'ACL_INVALID'):
                setup.validate_installed(data, self.before, self.artifact, True)

    def test_exact_acl_both_directions_normalize_four_fields_to_database_default(self):
        wrapper = setup.wrapper_bytes('rehearse', self.before, self.artifact).decode('utf-8')
        for field in ('role_name sysname', 'object_name sysname', 'permission_name sysname', 'permission_state char(1)'):
            self.assertIn(field + ' COLLATE DATABASE_DEFAULT', wrapper)
        for expression in ('r.name', 'OBJECT_NAME(p.major_id)', 'p.permission_name', 'p.state'):
            self.assertEqual(wrapper.count(expression + ' COLLATE DATABASE_DEFAULT'), 2)
        self.assertIn('FROM @a62_expected EXCEPT SELECT r.name COLLATE DATABASE_DEFAULT', wrapper)
        self.assertIn('EXCEPT SELECT role_name,object_name,permission_name,permission_state FROM @a62_expected', wrapper)
        self.assertIn(')<>562 OR EXISTS(', wrapper)
        self.assertIn("(class<>1 OR minor_id<>0 OR OBJECT_SCHEMA_NAME(major_id)<>N'dbo')", wrapper)
        self.assertNotIn('ALTER DATABASE', wrapper)

    def test_bootstrap_rhs_cr_normalization_matches_lf_but_rejects_real_body_changes(self):
        wrapper = setup.wrapper_bytes('rehearse', self.before, self.artifact).decode('utf-8')
        terminal = wrapper.index('ROLLBACK TRANSACTION;')
        for name, body in self.artifact.bodies.items():
            self.assertTrue(body.startswith('ALTER PROCEDURE dbo.' + name))
            canonical = self.artifact.canonical_bodies[name]
            rhs = '=REPLACE(' + setup.literal(canonical) + ",NCHAR(13),N'');"
            self.assertIn(rhs, wrapper)
            self.assertLess(wrapper.index(rhs), terminal)
            normalized_crlf = setup.canonical_body(name, body.replace('\n', '\r\n'))
            self.assertEqual(normalized_crlf, canonical)
            self.assertEqual(setup.sha(normalized_crlf.encode('utf-16le')), self.artifact.installed_hashes[name])
            altered = normalized_crlf.replace('hp_bootstrap_executor', 'hp_bootstrap_foreign')
            self.assertNotEqual(altered, canonical)
            data = deepcopy(self.inside)
            next(row for row in data['bootstrap'] if row['name'] == name)['canonicalHash'] = setup.sha(altered.encode('utf-16le'))
            with self.assertRaisesRegex(setup.SetupError, 'BOOTSTRAP_DEFINITION_INVALID'):
                setup.validate_installed(data, self.before, self.artifact, True)
        self.assertEqual(wrapper.count(self.artifact.raw.decode('utf-8')), 1)

    def test_bootstrap_create_alter_and_approved_comment_prefix_share_only_declaration_canonicalization(self):
        known = {'usp_bootstrap_exists': 'F5C6789CD211DA3A3B7ACBE6A7C4277270E16F8E319D0E1627C161296960E69E', 'usp_bootstrap_create': 'DAFF0F77F8CB93763FC551BCCB491E7A0BAB114E08A05F5140F2AD792A9BEC55'}
        self.assertEqual(self.artifact.installed_hashes, known)
        for name, alter in self.artifact.bodies.items():
            create = 'CREATE' + alter[5:]
            for declaration in (create, alter):
                for prefix in ('', '-- approved comment\n', ' \t-- approved comment\n\n\t'):
                    for newline in ('\n', '\r\n'):
                        definition = (prefix + declaration + '\n \t').replace('\n', newline)
                        self.assertEqual(setup.canonical_body(name, definition), create)
            interior = create.replace('END;', "-- ALTER PROCEDURE inside body must remain unchanged\nEND;")
            self.assertIn('-- ALTER PROCEDURE inside body', setup.canonical_body(name, interior))
            changed = deepcopy(self.inside)
            next(row for row in changed['bootstrap'] if row['name'] == name)['canonicalHash'] = setup.sha(setup.canonical_body(name, interior).encode('utf-16le'))
            with self.assertRaisesRegex(setup.SetupError, 'BOOTSTRAP_DEFINITION_INVALID'):
                setup.validate_installed(changed, self.before, self.artifact, True)

    def test_bootstrap_missing_malformed_or_foreign_headers_fail_and_sql_snapshot_guard_share_one_rule(self):
        name = 'usp_bootstrap_exists'
        for definition in (None, '', '-- comment without declaration', '-- comment\nSELECT 1;', 'SELECT 1;\nCREATE PROCEDURE dbo.' + name + '\nAS BEGIN END;', 'CREATE OR ALTER PROCEDURE dbo.' + name + '\nAS BEGIN END;', 'create PROCEDURE dbo.' + name + '\nAS BEGIN END;', 'CREATE PROCEDURE foreign.' + name + '\nAS BEGIN END;', 'CREATE PROCEDURE dbo.' + name + '_foreign\nAS BEGIN END;', 'ALTER PROCEDURE dbo.' + name):
            with self.assertRaisesRegex(setup.SetupError, 'BOOTSTRAP_HEADER_INVALID'):
                setup.canonical_body(name, definition)
        sql = setup.snapshot_sql()
        self.assertIn(setup.bootstrap_catalog_sql(), sql)
        self.assertIn("WHERE canonicalBody IS NULL)\n THROW 59999,N'QA bootstrap header invalid'", sql)
        self.assertNotIn('CHARINDEX(', setup.bootstrap_catalog_sql())
        self.assertIn("THEN CONVERT(nvarchar(max),N'CREATE')+SUBSTRING(body.body,6,2147483647)", sql)
        wrapper = setup.wrapper_bytes('apply', self.before, self.artifact).decode('utf-8')
        self.assertIn('FROM OPENJSON(@a62_bootstrapBodies)', wrapper)
        self.assertEqual(wrapper.count("AND canonicalBody IS NOT NULL AND canonicalBody COLLATE Latin1_General_100_BIN2="), 2)
        self.assertEqual(wrapper.count('AND DATALENGTH(canonicalBody)=DATALENGTH('), 2)
        self.assertLess(wrapper.rindex('QA bootstrap definition mismatch'), wrapper.index('COMMIT TRANSACTION;'))

    def test_other_procedures_triggers_tables_columns_principals_permissions_and_memberships_are_protected(self):
        for part in setup.PARTS:
            data = deepcopy(self.inside)
            data['protected'][part] = 'B' * 64
            with self.assertRaisesRegex(setup.SetupError, 'PROTECTED_METADATA_CHANGED'):
                setup.validate_installed(data, self.before, self.artifact, True)
        for alter in ('role-type', 'role-owner', 'bootstrap-body', 'transaction'):
            data = deepcopy(self.inside)
            if alter == 'role-type':
                data['roles'][0]['type'] = 'S'
            elif alter == 'role-owner':
                data['roles'][0]['owner'] = 'foreign'
            elif alter == 'bootstrap-body':
                data['bootstrap'][0]['canonicalHash'] = 'B' * 64
            else:
                data['transactionCount'] = 2
            with self.assertRaises(setup.SetupError):
                setup.validate_installed(data, self.before, self.artifact, True)

    def test_cleanup_mismatch_fails_even_if_subsequent_read_returns_original(self):
        changed = deepcopy(self.before)
        changed['protected']['columns'] = 'B' * 64
        transport = ModelTransport([self.before, changed, self.before], self.inside)
        code, result = self.execute("rehearse", transport)
        self.safe_error(code, result, 'CLEANUP_MISMATCH')
        self.assertTrue(result['cleanup_after_error_verified'])
        self.assertEqual(len(transport.calls), 4)

    def test_mutation_failures_trigger_bounded_independent_cleanup_without_compensation(self):
        for cleanup in (self.before, setup.SetupError('RESPONSE_INVALID')):
            transport = ModelTransport([self.before, cleanup], error=setup.SetupError('SQLCMD_FAILED'))
            code, result = self.execute('rehearse', transport)
            self.safe_error(code, result, 'SQLCMD_FAILED')
            self.assertEqual(result['cleanup_after_error_verified'], isinstance(cleanup, dict))
            self.assertEqual([call['kind'] for call in transport.calls], ['snapshot', 'wrapper', 'snapshot'])
            self.assertEqual(len(transport.wrappers), 1)

    def test_apply_mismatch_and_invalid_inside_mapping_never_report_applied(self):
        for mode, inside, after in (('apply', self.inside, self.before), ('rehearse', {**self.inside, 'roles': []}, self.before)):
            transport = ModelTransport([self.before, after, self.before], inside)
            code, result = self.execute(mode, transport)
            self.safe_error(code, result)

    def test_apply_before_guard_failure_records_not_attempted_and_never_needs_reconciliation(self):
        before = deepcopy(self.before)
        before['controlDatabase'] = 0
        transport = ModelTransport([before])
        code, result = self.execute('apply', transport)
        self.safe_error(code, result, 'CONTROL_REQUIRED')
        self.assertEqual(result['sql_action'], 'not_attempted')
        self.assertFalse(result['reconciliation_required'])
        self.assertFalse(result['retry_mutation'])
        self.assertEqual(transport.wrappers, [])

    def test_apply_postcommit_read_error_preserves_acknowledgement_and_never_retries_mutation(self):
        after = installed(self.before, self.artifact, False)
        transport = ModelTransport([self.before, setup.SetupError('SQLCMD_TIMEOUT'), after], self.inside)
        code, result = self.execute('apply', transport)
        self.safe_error(code, result, 'SQLCMD_TIMEOUT')
        self.assertEqual(result['sql_action'], 'commit_acknowledged')
        self.assertTrue(result['reconciliation_required'])
        self.assertFalse(result['retry_mutation'])
        self.assertEqual(result['diagnostic'], setup.APPLY_RECONCILIATION_MESSAGE)
        self.assertIn('Do not repeat apply', result['diagnostic'])
        self.assertIn('new connection', result['diagnostic'])
        self.assertTrue(result['readonly_recovery_completed'])
        self.assertFalse(result['recovery_matches_preapply'])
        self.assertNotIn('cleanup_after_error_verified', result)
        self.assertEqual([call['kind'] for call in transport.calls], ['snapshot', 'wrapper', 'snapshot', 'snapshot'])
        self.assertEqual(len(transport.wrappers), 1)

    def test_apply_zero_exit_with_timeout_or_invalid_frame_never_acknowledges_commit(self):
        after = installed(self.before, self.artifact, False)
        for raw_exit, stdout, stderr, error in ((0, framed(self.inside), 'Timeout expired\n', 'SQLCMD_TIMEOUT'), (1, '', 'Timeout expired\r\n', 'SQLCMD_TIMEOUT'), (0, '', '', 'RESPONSE_INVALID'), (0, CANARY, '', 'RESPONSE_INVALID')):
            replies = iter([subprocess.CompletedProcess([], 0, framed(self.before), ''), subprocess.CompletedProcess([], raw_exit, stdout, stderr), subprocess.CompletedProcess([], 0, framed(after), '')])
            transport = setup.Transport(run=lambda *args, **kwargs: next(replies), resolve=lambda name: 'SQLCMD.EXE', environ={})
            code, result = self.execute('apply', transport)
            self.safe_error(code, result, error)
            self.assertEqual(result['sql_action'], 'mutation_outcome_unverified')
            self.assertTrue(result['reconciliation_required'])
            self.assertFalse(result['retry_mutation'])
            self.assertTrue(result['readonly_recovery_completed'])
            self.assertFalse(result['recovery_matches_preapply'])
            self.assertNotIn('cleanup_after_error_verified', result)
            self.assertEqual(sum(call['kind'] == 'wrapper' for call in transport.calls), 1)
            self.assertEqual(len(transport.calls), 3)

    def test_transport_checks_shared_stderr_classifier_before_parser_and_accepts_only_blank_diagnostics(self):
        for raw_exit, stderr, expected in ((0, 'Timeout expired\n', 'SQLCMD_TIMEOUT'), (1, ' tImEoUt\tExPiReD\r\n', 'SQLCMD_TIMEOUT'), (0, CANARY, 'SQLCMD_FAILED'), (0, None, 'SQLCMD_FAILED'), (0, b'', 'SQLCMD_FAILED')):
            response = subprocess.CompletedProcess([], raw_exit, framed(self.before), stderr)
            transport = setup.Transport(run=lambda *args, **kwargs: response, resolve=lambda name: 'SQLCMD.EXE', environ={})
            with patch.object(setup, 'parse_snapshot', side_effect=AssertionError('must not parse')) as parse:
                code, result = self.execute('plan', transport)
                self.safe_error(code, result, expected)
                self.assertEqual(result['sqlcmd_calls'][0]['raw_exit_code'], raw_exit)
                parse.assert_not_called()
        for stderr in ('', ' \t\r\n'):
            transport = setup.Transport(run=lambda *args, **kwargs: subprocess.CompletedProcess([], 0, framed(self.before), stderr), resolve=lambda name: 'SQLCMD.EXE', environ={})
            code, result = self.execute('plan', transport)
            self.assertEqual(code, 0)
            self.assertEqual(result['status'], 'planned')

    def test_framed_metadata_checksum_duplicates_shape_and_truncation_are_strict(self):
        # SQL concatenation must remain MAX: prefix + 4000 hex chars exceeds nvarchar(4000).
        self.assertIn("CONVERT(nvarchar(max),N'A62JSON:')+", setup.EMIT)
        encoded = framed(self.before)
        self.assertEqual(setup.parse_snapshot(encoded), self.before)
        for raw in (CANARY, encoded + encoded, encoded.replace('A62JSON:', 'unknown:', 1), encoded[:-5], encoded.replace('A62END:', 'A62END:0', 1), framed({**self.before, 'extra': 'private'})):
            with self.assertRaises(Exception):
                setup.parse_snapshot(raw)
        duplicate = json.dumps(self.before)[:-1] + ',"roles":[]}'
        raw = duplicate.encode('utf-16le')
        encoded = '\n'.join('A62JSON:' + raw[i:i + 2000].hex().upper() for i in range(0, len(raw), 2000)) + '\nA62END:' + setup.sha(raw)
        with self.assertRaises(setup.SetupError):
            setup.parse_snapshot(encoded)

    def test_truncated_full_chunk_preserves_original_checksum_and_is_rejected(self):
        lines = framed(self.before).splitlines()
        chunks = lines[:-1]
        self.assertGreater(len(chunks), 2)
        self.assertEqual(len(chunks[0]) - len('A62JSON:'), 4000)
        self.assertGreater(len(chunks[-1]) - len('A62JSON:'), 0)
        self.assertLess(len(chunks[-1]) - len('A62JSON:'), 4000)
        original_end = lines[-1]
        lines[0] = lines[0][:-8]  # The former nvarchar(4000) concatenation lost eight hex chars.
        self.assertEqual(lines[-1], original_end)
        with self.assertRaises(setup.SetupError) as caught:
            setup.parse_snapshot('\n'.join(lines))
        self.assertEqual(caught.exception.args, ('RESPONSE_INVALID', 'checksum'))

    def test_empty_sql_collections_are_normalized_before_hashing_and_parser_rejects_null(self):
        sql = setup.snapshot_sql()
        for name in setup.PARTS + ('bootstrapBodies', 'bootstrap', 'roles', 'acl', 'procedures', 'tableNames', 'triggerNames'):
            self.assertIn('DECLARE @a62_' + name + ' nvarchar(max)=COALESCE((', sql)
        self.assertEqual(sql.count(",N'[]');"), len(setup.PARTS) + 7)
        self.assertEqual(setup.parse_snapshot(framed(self.before))['roles'], [])
        self.assertEqual(setup.parse_snapshot(framed(self.before))['acl'], [])
        self.assertRegex(setup.parse_snapshot(framed(self.before))['fingerprint'], '^[0-9A-F]{64}$')
        for field in ('roles', 'acl', 'bootstrap', 'procedures', 'tables', 'triggers', 'fingerprint'):
            data = deepcopy(self.before)
            data[field] = None
            with self.assertRaises(setup.SetupError):
                setup.parse_snapshot(framed(data))

    def test_transaction_state_is_captured_before_metadata_and_outside_inside_gates_remain_strict(self):
        sql = setup.snapshot_sql()
        self.assertTrue(sql.startswith('DECLARE @a62_transactionCount int=@@TRANCOUNT,@a62_xactState int=XACT_STATE();'))
        self.assertLess(sql.index('@a62_xactState int=XACT_STATE()'), sql.index('DECLARE @a62_meta'))
        self.assertIn('@a62_transactionCount transactionCount,@a62_xactState xactState', sql)
        self.assertNotIn('controlDatabase,@@TRANCOUNT transactionCount,XACT_STATE() xactState', sql)
        setup.validate_baseline(self.before, self.artifact)
        setup.validate_installed(self.inside, self.before, self.artifact, True)
        invalid = deepcopy(self.before)
        invalid['xactState'] = 1
        with self.assertRaisesRegex(setup.SetupError, 'TRANSACTION_INVALID'):
            setup.validate_baseline(invalid, self.artifact)
        invalid = deepcopy(self.inside)
        invalid['xactState'] = 0
        with self.assertRaisesRegex(setup.SetupError, 'TRANSACTION_INVALID'):
            setup.validate_installed(invalid, self.before, self.artifact, True)

    def test_prebegin_wrapper_guard_uses_captured_state_and_preserves_all_other_gates(self):
        wrapper = setup.wrapper_bytes('rehearse', self.before, self.artifact).decode('utf-8')
        begin = wrapper.index('BEGIN TRANSACTION;')
        prefix = wrapper[:begin]
        guard = next(line for line in prefix.splitlines() if "QA setup preconditions failed" in line)
        self.assertIn('IF @a62_transactionCount<>0 OR @a62_xactState<>0 OR ', guard)
        self.assertNotIn('XACT_STATE()', guard)
        self.assertNotIn('@@TRANCOUNT', guard)
        self.assertLess(prefix.index('@a62_transactionCount int=@@TRANCOUNT,@a62_xactState int=XACT_STATE()'), prefix.index('DECLARE @a62_meta'))
        for gate in ("HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL')", "OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL", "DATABASE_PRINCIPAL_ID(N'hp_runtime_executor') IS NOT NULL", "DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor') IS NOT NULL"):
            self.assertIn(gate, guard)
        self.assertIn('QA scope mismatch', prefix)
        self.assertIn('QA baseline changed', prefix)
        self.assertIn("IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'QA transaction invalid'", wrapper[begin:])

    def test_transport_is_fixed_readonly_metadata_sanitized_and_preserves_raw_exit_without_stderr(self):
        calls = []
        def run(argv, **kwargs):
            calls.append((argv, kwargs))
            return subprocess.CompletedProcess(argv, 0, framed(self.before), '')
        transport = setup.Transport(run=run, resolve=lambda name: 'SQLCMD.EXE', environ={'SystemRoot': 'C:/Windows', 'SQLCMDINI': CANARY, 'SQLCMDPASSWORD': CANARY, 'DATABASE_PASSWORD': CANARY})
        self.assertEqual(transport.snapshot(), self.before)
        argv, options = calls[0]
        self.assertEqual(argv[argv.index('-S') + 1], 'localhost')
        self.assertEqual(argv[argv.index('-d') + 1], setup.A61.DATABASE)
        self.assertEqual(options['timeout'], setup.A61.SQLCMD_PROCESS_TIMEOUT_SECONDS)
        self.assertEqual(setup.A61.SQLCMD_PROCESS_TIMEOUT_SECONDS, 20)
        self.assertEqual(setup.A61.SQLCMD_QUERY_TIMEOUT_SECONDS, 10)
        self.assertEqual(argv[argv.index('-t') + 1], '10')
        self.assertEqual(argv[argv.index('-l') + 1], '5')
        self.assertFalse(options['shell'])
        self.assertEqual(options['env'], {'SystemRoot': 'C:/Windows'})
        self.assertNotIn(CANARY, str(argv) + str(options) + str(transport.calls))
        query = argv[-1]
        self.assertNotIn('FROM dbo.', query)
        self.assertNotRegex(query, r'(?mi)^\s*(INSERT|UPDATE|DELETE|EXEC|CREATE|ALTER|COMMIT|BEGIN\s+TRAN)\b')
        self.assertEqual(transport.calls, [{'kind': 'snapshot', 'raw_exit_code': 0}])
        self.assertIn('o.principal_id', setup.CATALOG['triggers'])
        self.assertNotIn('t.principal_id', setup.CATALOG['triggers'])

    def test_sqlcmd_errors_and_unknown_exception_causes_do_not_leak_and_do_not_write(self):
        for failure in (subprocess.TimeoutExpired(CANARY, 15, output=CANARY, stderr=CANARY), FileNotFoundError(CANARY), PermissionError(CANARY)):
            def run(*args, **kwargs):
                raise failure
            transport = setup.Transport(run=run, resolve=lambda name: 'SQLCMD.EXE', environ={})
            code, result = self.execute('plan', transport)
            self.safe_error(code, result)
            self.assertEqual(len(transport.calls), 1)
        for response in (subprocess.CompletedProcess([], 1, CANARY, CANARY), subprocess.CompletedProcess([], 0, CANARY, CANARY)):
            transport = setup.Transport(run=lambda *args, **kwargs: response, resolve=lambda name: 'SQLCMD.EXE', environ={})
            code, result = self.execute('plan', transport)
            self.safe_error(code, result)
        response = subprocess.CompletedProcess([], 1, '', 'Msg 102, Level 15, State 1, Server local, Line 19\n' + CANARY)
        transport = setup.Transport(run=lambda *args, **kwargs: response, resolve=lambda name: 'SQLCMD.EXE', environ={})
        code, result = self.execute('plan', transport)
        self.safe_error(code, result, 'SQLCMD_FAILED')
        self.assertEqual(result['sqlcmd_calls'][0]['sql_error_numbers'], [102])
        self.assertEqual(result['sqlcmd_calls'][0]['sql_error_lines'], [19])
        transport = ModelTransport([setup.SetupError(CANARY)])
        code, result = self.execute('plan', transport)
        self.safe_error(code, result, 'INSPECTION_ERROR')


if __name__ == '__main__':
    unittest.main()
