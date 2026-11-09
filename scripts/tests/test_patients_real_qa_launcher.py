"""Offline launcher models only: no operational store, DPAPI, Node/browser or network."""
from contextlib import redirect_stdout, redirect_stderr
import ctypes
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import Mock, patch

SPEC = importlib.util.spec_from_file_location('patients_launcher', Path(__file__).resolve().parents[1] / 'run-patients-real-qa.py')
L = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(L)
PRIVATE = 'offline-canary-secret-do-not-disclose'
FAKE_RUNNER = b'// offline runner fixture, never executed'
SEALED = b'offline-not-real-DPAPI-ciphertext'


def manifest():
    data = {'schema': 'health-patients-real-qa-v1', 'qaDatabase': L.DATABASE, 'baseUrl': L.BASE_URL, 'runId': L.RUN_ID}
    for i, key in enumerate(('human', 'otherHuman', 'animal'), 1):
        data[key] = {'hostname': 'qa-offline-' + str(i) + '.health.localhost', 'tenantId': str(i) * 8 + '-' + str(i) * 4 + '-' + str(i) * 4 + '-' + str(i) * 4 + '-' + str(i) * 12, 'email': key + '@example.test', 'password': PRIVATE}
    return data


def result(code=0, stdout=b'{"control":"runner","status":"passed"}\n', stderr=b''):
    return subprocess.CompletedProcess(['not-a-real-process'], code, stdout, stderr)


class Models:
    def __init__(self):
        self.reads = []
        self.wire = json.dumps(manifest()).encode()
        self.cipher_hash = hashlib.sha256(SEALED).hexdigest()
        self.decrypt = Mock(side_effect=lambda *_: self.wire)
        self.transport = Mock(return_value=result())
        self.resolve = Mock(return_value='C:/offline/node.exe')

    def read(self, path):
        self.reads.append(path.name)
        return {'patients-real-qa.cjs': FAKE_RUNNER, 'environment-readiness.json': json.dumps({'manifestCipherSHA256': self.cipher_hash}).encode(), 'patients-manifest.dpapi': SEALED}[path.name]

    def execute(self, argv=None, **kwargs):
        with patch.object(L, 'RUNNER_SHA256', hashlib.sha256(FAKE_RUNNER).hexdigest().upper()):
            return L.execute(['--readonly'] if argv is None else argv, source={}, read=self.read, decrypt=self.decrypt, resolve=self.resolve, transport=self.transport, **kwargs)


class LauncherTests(unittest.TestCase):
    def assert_code(self, code, fn):
        with self.assertRaises(L.LaunchError) as found:
            fn()
        self.assertEqual(found.exception.code, code)
        self.assertNotIn(PRIVATE, str(found.exception))

    def test_import_is_inert_and_does_not_read_operational_files_or_launch_anything(self):
        spec = importlib.util.spec_from_file_location('inert_launcher', Path(L.__file__))
        module = importlib.util.module_from_spec(spec)
        stdout, stderr = io.StringIO(), io.StringIO()
        with patch.object(Path, 'read_bytes', side_effect=AssertionError('file read')), patch.object(Path, 'read_text', side_effect=AssertionError('file read')), patch.object(subprocess, 'Popen', side_effect=AssertionError('child')), patch.object(importlib.util, 'spec_from_file_location', side_effect=AssertionError('lazy helper loaded')), redirect_stdout(stdout), redirect_stderr(stderr):
            spec.loader.exec_module(module)
        self.assertEqual(stdout.getvalue() + stderr.getvalue(), '')

    def test_environment_is_exact_allowlist_case_insensitive_without_parent_mutation(self):
        source = {name.lower(): 'C:/offline/' + name for name in L.NODE_ENVIRONMENT}
        source.update({'CODEX_HOME': PRIVATE, 'AUTH_TOKEN': PRIVATE, 'PASSWORD': PRIVATE, 'NODE_OPTIONS': PRIVATE, 'DEBUG': PRIVATE, 'PYTHONPATH': PRIVATE, 'PLAYWRIGHT_BROWSERS_PATH': PRIVATE, 'USERPROFILE': PRIVATE})
        original, parent = dict(source), dict(os.environ)
        child = L.node_environment(source)
        self.assertEqual(set(child), set(L.NODE_ENVIRONMENT))
        self.assertEqual(child['PROGRAMFILES'], source['programfiles'])
        self.assertEqual(child['PROGRAMFILES(X86)'], source['programfiles(x86)'])
        self.assertEqual(child['LOCALAPPDATA'], source['localappdata'])
        self.assertNotIn(PRIVATE, json.dumps(child))
        self.assertEqual(source, original)
        self.assertEqual(dict(os.environ), parent)
        self.assertIsNot(source, child)

    def test_sqlcmd_hostile_variables_are_rejected_not_silently_inherited_or_removed(self):
        for key in ('SQLCMDPASSWORD', 'sqlcmdini', 'SqlCmdServer', 'SQLCMDanything'):
            self.assert_code('HOSTILE_ENVIRONMENT', lambda: L.node_environment({key: PRIVATE}))
        self.assert_code('ENVIRONMENT_INVALID', lambda: L.node_environment({'Path': 'a', 'PATH': 'b'}))
        self.assert_code('ENVIRONMENT_INVALID', lambda: L.node_environment({'PATH': PRIVATE + '\x00'}))

    def test_pins_flags_and_fixed_own_checkout_paths(self):
        self.assertEqual(L.RUNNER_SHA256, '1BB53685CF5B375B434D75DABE8BD61260672E167C5EADBC0271B1DBF0D8FE32')
        self.assertEqual(L.ROOT, Path(L.__file__).resolve().parents[1])
        paths = L.fixed_paths()
        self.assertEqual(paths['readiness'], L.ROOT / 'tmp/patients-real-env-20261109/environment-readiness.json')
        self.assertEqual(paths['sealed'], L.ROOT / 'tmp/patients-real-env-20261109/patients-manifest.dpapi')
        self.assertEqual(paths['runner'], L.ROOT / 'frontend/scripts/patients-real-qa.cjs')
        for mode in L.MODES:
            self.assertEqual(L.parse_mode([mode]), mode)
        for args in ([], ['--readonly', '--allow-synthetic-writes'], ['--manifest', PRIVATE], ['--root', PRIVATE], ['--password=' + PRIVATE], ['--readonly', '--readonly']):
            self.assert_code('INVALID_MODE', lambda: L.parse_mode(args))

    def test_runner_hash_is_checked_before_readiness_cipher_or_dpapi(self):
        m = Models()
        self.assert_code('RUNNER_CHANGED', lambda: L.load_manifest(L.fixed_paths(), m.read, m.decrypt))
        self.assertEqual(m.reads, ['patients-real-qa.cjs'])
        m.decrypt.assert_not_called()
        m.transport.assert_not_called()

    def test_cipher_hash_or_bad_readiness_stops_before_dpapi(self):
        m = Models()
        m.cipher_hash = '0' * 64
        with patch.object(L, 'RUNNER_SHA256', hashlib.sha256(FAKE_RUNNER).hexdigest().upper()):
            self.assert_code('MANIFEST_CHANGED', lambda: L.load_manifest(L.fixed_paths(), m.read, m.decrypt))
        m.decrypt.assert_not_called()
        for raw in (b'{}', b'not-json', b'{"manifestCipherSHA256":12}', b'{"manifestCipherSHA256":"BAD"}'):
            m = Models()
            def read(path):
                return raw if path.name == 'environment-readiness.json' else m.read(path)
            with patch.object(L, 'RUNNER_SHA256', hashlib.sha256(FAKE_RUNNER).hexdigest().upper()):
                self.assert_code('READINESS_INVALID', lambda: L.load_manifest(L.fixed_paths(), read, m.decrypt))
            m.decrypt.assert_not_called()

    def test_scope_rejection_and_no_launch_for_wrong_run_database_hosts_or_identity(self):
        for key, value in (('runId', 'pacqa-other'), ('qaDatabase', 'production'), ('baseUrl', 'http://external.example.test'), ('schema', 'other')):
            m = Models()
            data = manifest()
            data[key] = value
            m.wire = json.dumps(data).encode()
            self.assert_code('MANIFEST_SCOPE_CHANGED', m.execute)
            m.transport.assert_not_called()
        for field, value in (('hostname', 'external.example.test'), ('tenantId', 'not-canonical'), ('email', 'real@outside.test'), ('password', '')):
            m = Models()
            data = manifest()
            data['human'][field] = value
            m.wire = json.dumps(data).encode()
            self.assert_code('MANIFEST_SCOPE_CHANGED', m.execute)
            m.transport.assert_not_called()
        m = Models()
        m.wire = b'broken-json-' + PRIVATE.encode()
        self.assert_code('MANIFEST_SCOPE_CHANGED', m.execute)
        m.transport.assert_not_called()

    def test_full_injected_flow_passes_credentials_only_as_stdin_with_sanitized_output(self):
        m = Models()
        filtered = m.execute(['--allow-synthetic-writes'])
        args = m.transport.call_args.args
        self.assertEqual(args[0], ['C:/offline/node.exe', str(L.ROOT / L.RUNNER_RELATIVE), '--allow-synthetic-writes'])
        self.assertEqual(args[1], m.wire)
        self.assertEqual(args[2], L.ROOT / 'frontend')
        self.assertEqual(args[3], {})
        self.assertNotIn(PRIVATE, json.dumps(args[0]))
        self.assertEqual(filtered, {'mode': '--allow-synthetic-writes', 'rawExit': 0, 'signals': [{'control': 'runner', 'status': 'passed'}], 'credentialsPrinted': False})
        self.assertEqual(m.decrypt.call_args.args, (SEALED, L.ROOT / 'scripts/provision-isolated-sqlserver-logins.py'))

    def test_output_passwords_plain_and_json_escaped_are_rejected_before_publication(self):
        passwords = (PRIVATE, 'offline-\u00f1-\n-password')
        for password in passwords:
            for raw in (password.encode(), json.dumps(password).encode(), json.dumps(password, ensure_ascii=False).encode()):
                self.assert_code('UNSAFE_RUNNER_OUTPUT', lambda: L.filter_result(result(stdout=raw), '--readonly', [password]))
                self.assert_code('UNSAFE_RUNNER_OUTPUT', lambda: L.filter_result(result(stderr=raw), '--readonly', [password]))

    def test_empty_nonjson_extra_fields_and_inconsistent_results_fail_closed(self):
        self.assert_code('RUNNER_RESULT_MISSING', lambda: L.filter_result(result(stdout=b''), '--readonly', [PRIVATE]))
        for raw in (b'raw stack trace', b'\xff', b'{"control":"other","status":"passed"}', b'{"control":"runner","status":"passed","user":{}}'):
            self.assert_code('UNEXPECTED_RUNNER_OUTPUT', lambda: L.filter_result(result(stdout=raw), '--readonly', [PRIVATE]))
        self.assert_code('INCONSISTENT_RUNNER_RESULT', lambda: L.filter_result(result(1), '--readonly', [PRIVATE]))
        self.assert_code('INCONSISTENT_RUNNER_RESULT', lambda: L.filter_result(result(stdout=b'{"control":"runner","status":"failed"}'), '--readonly', [PRIVATE]))
        failure = L.filter_result(result(1, b'{"control":"runner","status":"failed","code":"UNEXPECTED_FAILURE"}'), '--readonly', [PRIVATE])
        self.assertEqual(failure['rawExit'], 1)
        self.assertNotIn('code', failure['signals'][0])

    def test_main_never_prints_raw_exception_text_or_timeout_output(self):
        for error, expected, exit_code in ((RuntimeError(PRIVATE), 'EXECUTION_FAILED', 1), (L.LaunchError('RUNNER_TIMEOUT'), 'RUNNER_TIMEOUT', 124), (L.LaunchError('PROCESS_CLEANUP_FAILED'), 'PROCESS_CLEANUP_FAILED', 1)):
            output = io.StringIO()
            with patch.object(L, 'execute', side_effect=error):
                code = L.main(['--readonly'], output=output)
            self.assertEqual(code, exit_code)
            self.assertEqual(json.loads(output.getvalue()), {'status': 'execution_failed', 'code': expected, 'rawExit': exit_code, 'credentialsPrinted': False})
            self.assertNotIn(PRIVATE, output.getvalue())

    def test_node_resolution_uses_only_explicit_absolute_path_directories(self):
        seen = []
        def is_file(path):
            seen.append(str(path))
            return str(path).replace('\\', '/').lower() == 'c:/offline/node.exe'
        with patch.object(Path, 'is_file', is_file):
            node = L.resolve_node({'PATH': '.;relative;C:/offline', 'PATHEXT': '.UNTRUSTED'})
        self.assertTrue(node.lower().endswith('node.exe'))
        self.assertEqual(len(seen), 1)
        self.assert_code('NODE_MISSING', lambda: L.resolve_node({'PATH': '.;relative'}))


class FakeProcess:
    def __init__(self, events, outcome='ok'):
        self.events, self.outcome = events, outcome
        self.stdin, self.stdout, self.stderr = io.BytesIO(), io.BytesIO(), io.BytesIO()
        self.returncode = None
        self._handle = 999
        self.calls = 0

    def communicate(self, input=None, timeout=None):
        self.calls += 1
        self.events.append(('communicate', input, timeout))
        if self.calls == 1:
            if self.outcome == 'timeout':
                raise subprocess.TimeoutExpired(PRIVATE, timeout, output=PRIVATE.encode(), stderr=PRIVATE.encode())
            if self.outcome == 'error':
                raise OSError(PRIVATE)
            self.returncode = 0
        return b'{"control":"runner","status":"passed"}', b''

    def poll(self):
        return self.returncode

    def kill(self):
        self.events.append(('kill-own-node',))
        self.returncode = 1

    def wait(self, timeout=None):
        self.events.append(('wait-own-node', timeout))
        return self.returncode


class FakeJob:
    def __init__(self, events, assignment=True):
        self.events, self.assignment = events, assignment

    def assign(self, process):
        self.events.append(('assign-job',))
        if not self.assignment:
            raise L.LaunchError('PROCESS_CONTAINMENT_FAILED')

    def stop(self):
        self.events.append(('terminate-own-job',))

    def close(self):
        self.events.append(('close-kill-on-close-job',))


class ContainmentTests(unittest.TestCase):
    def model(self, outcome='ok', assignment=True):
        events = []
        process = FakeProcess(events, outcome)
        popen = Mock(return_value=process)
        job = FakeJob(events, assignment)
        return events, process, popen, job

    def test_normal_launch_is_assigned_before_any_stdin_and_closes_only_its_job(self):
        events, process, popen, job = self.model()
        response = L.contained_run(['node.exe', 'pinned-runner', '--readonly'], PRIVATE.encode(), Path('frontend'), {'PROGRAMFILES': 'C:/Program Files'}, popen=popen, job_factory=lambda: job)
        self.assertEqual(response.returncode, 0)
        self.assertEqual(events[0], ('assign-job',))
        self.assertEqual(events[1], ('communicate', PRIVATE.encode(), 900))
        self.assertIn(('terminate-own-job',), events)
        self.assertIn(('close-kill-on-close-job',), events)
        self.assertTrue(all(stream.closed for stream in (process.stdin, process.stdout, process.stderr)))
        options = popen.call_args.kwargs
        self.assertEqual(options['env'], {'PROGRAMFILES': 'C:/Program Files'})
        self.assertFalse(options['shell'])
        self.assertTrue(options['close_fds'])
        self.assertEqual(options['stdin'], subprocess.PIPE)

    def test_timeout_terminates_descendants_closes_job_and_drains_without_resending_input(self):
        events, process, popen, job = self.model('timeout')
        with self.assertRaises(L.LaunchError) as found:
            L.contained_run(['node.exe'], PRIVATE.encode(), Path('frontend'), {}, popen=popen, job_factory=lambda: job)
        self.assertEqual(found.exception.code, 'RUNNER_TIMEOUT')
        self.assertEqual(events[:4], [('assign-job',), ('communicate', PRIVATE.encode(), 900), ('terminate-own-job',), ('close-kill-on-close-job',)])
        self.assertEqual(events[4], ('communicate', None, 5))
        self.assertTrue(process.stdin.closed)

    def test_no_credentials_sent_if_job_assignment_fails_and_only_own_waiting_node_is_killed(self):
        events, process, popen, job = self.model(assignment=False)
        with self.assertRaises(L.LaunchError) as found:
            L.contained_run(['node.exe'], PRIVATE.encode(), Path('frontend'), {}, popen=popen, job_factory=lambda: job)
        self.assertEqual(found.exception.code, 'PROCESS_CONTAINMENT_FAILED')
        self.assertIn(('kill-own-node',), events)
        self.assertNotIn(('terminate-own-job',), events)
        self.assertFalse(any(e[0] == 'communicate' and e[1] is not None for e in events))
        self.assertIn(('close-kill-on-close-job',), events)

    def test_communication_error_also_terminates_job_without_forwarding_error(self):
        events, process, popen, job = self.model('error')
        with self.assertRaises(OSError):
            L.contained_run(['node.exe'], PRIVATE.encode(), Path('frontend'), {}, popen=popen, job_factory=lambda: job)
        self.assertIn(('terminate-own-job',), events)
        self.assertIn(('close-kill-on-close-job',), events)
        self.assertTrue(process.stdin.closed)

    def test_popen_failure_closes_empty_job_without_touching_any_process(self):
        events = []
        with self.assertRaises(OSError):
            L.contained_run(['node.exe'], b'x', Path('frontend'), {}, popen=Mock(side_effect=OSError(PRIVATE)), job_factory=lambda: FakeJob(events))
        self.assertEqual(events, [('close-kill-on-close-job',)])

    def test_job_uses_kill_on_close_no_breakaway_and_waits_for_zero_active_processes(self):
        functions = {name: Mock(return_value=1) for name in ('CreateJobObjectW', 'SetInformationJobObject', 'AssignProcessToJobObject', 'TerminateJobObject', 'QueryInformationJobObject', 'CloseHandle')}
        seen = {}
        def set_information(handle, info_class, raw, size):
            limits = ctypes.cast(raw, ctypes.POINTER(L.ExtendedLimits)).contents
            seen['flags'], seen['class'] = limits.BasicLimitInformation.LimitFlags, info_class
            return 1
        functions['SetInformationJobObject'].side_effect = set_information
        kernel = type('Kernel', (), functions)()
        job = L.WindowsJob(kernel=kernel)
        job.assign(type('Process', (), {'_handle': 999})())
        job.stop()
        job.close()
        self.assertEqual(seen, {'flags': 0x2000, 'class': 9})
        functions['AssignProcessToJobObject'].assert_called_once_with(1, 999)
        functions['TerminateJobObject'].assert_called_once_with(1, 1)
        self.assertEqual(functions['QueryInformationJobObject'].call_args.args[1], 1)
        functions['CloseHandle'].assert_called_once_with(1)


if __name__ == '__main__':
    unittest.main()

class CleanupFailureTests(unittest.TestCase):
    def test_cleanup_failure_still_closes_job_and_all_pipes_and_returns_no_success(self):
        events = []
        process = FakeProcess(events)
        job = FakeJob(events)
        job.stop = Mock(side_effect=L.LaunchError('PROCESS_CLEANUP_FAILED'))
        with self.assertRaises(L.LaunchError) as found:
            L.contained_run(['node.exe'], PRIVATE.encode(), Path('frontend'), {}, popen=Mock(return_value=process), job_factory=lambda: job)
        self.assertEqual(found.exception.code, 'PROCESS_CLEANUP_FAILED')
        self.assertIn(('close-kill-on-close-job',), events)
        self.assertTrue(all(stream.closed for stream in (process.stdin, process.stdout, process.stderr)))

    def test_nonzero_job_active_processes_after_deadline_is_an_explicit_cleanup_failure(self):
        names = ('CreateJobObjectW', 'SetInformationJobObject', 'AssignProcessToJobObject', 'TerminateJobObject', 'QueryInformationJobObject', 'CloseHandle')
        functions = {name: Mock(return_value=1) for name in names}
        def query(handle, info_class, raw, size, returned):
            ctypes.cast(raw, ctypes.POINTER(L.Accounting)).contents.ActiveProcesses = 1
            return 1
        functions['QueryInformationJobObject'].side_effect = query
        job = L.WindowsJob(kernel=type('Kernel', (), functions)())
        try:
            with patch.object(L.time, 'monotonic', side_effect=[0, 6]):
                with self.assertRaises(L.LaunchError) as found:
                    job.stop()
            self.assertEqual(found.exception.code, 'PROCESS_CLEANUP_FAILED')
        finally:
            job.close()
        functions['CloseHandle'].assert_called_once_with(1)

class PublicationTests(unittest.TestCase):
    def test_interruption_and_broken_output_never_emit_raw_errors(self):
        output = io.StringIO()
        with patch.object(L, 'execute', side_effect=KeyboardInterrupt(PRIVATE)):
            self.assertEqual(L.main(['--readonly'], output=output), 1)
        self.assertNotIn(PRIVATE, output.getvalue())
        broken = Mock()
        broken.write.side_effect = RuntimeError(PRIVATE)
        with patch.object(L, 'execute', return_value={'rawExit': 0}):
            self.assertEqual(L.main(['--readonly'], output=broken), 1)


if __name__ == '__main__':
    unittest.main()
