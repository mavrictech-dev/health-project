"""Pinned Windows launcher; credentials travel only from DPAPI to Node stdin.

Import is inert. CLI has no path/credential switches. This does not provision QA.
The pinned runner waits for stdin EOF before importing Playwright/launching Edge;
we assign its Node process to a kill-on-close job BEFORE sending any stdin.
Windows job descendants are contained without breakaway or process-name killing.
References: https://learn.microsoft.com/windows/win32/procthread/job-objects
https://docs.python.org/3/library/subprocess.html#subprocess.Popen.communicate
"""
import ctypes
from ctypes import wintypes
import hashlib
import importlib.util
import json
import ntpath
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
JOB_RELATIVE = Path('tmp/patients-real-env-20261109')
RUNNER_RELATIVE = Path('frontend/scripts/patients-real-qa.cjs')
RUNNER_SHA256 = '1BB53685CF5B375B434D75DABE8BD61260672E167C5EADBC0271B1DBF0D8FE32'
RUN_ID = 'pacqa-20261109-a1'
DATABASE = 'health_project_sqlserver_qa_isolated_20261105'
BASE_URL = 'http://health.localhost:18300'
MODES = ('--readonly', '--allow-synthetic-writes')
NODE_ENVIRONMENT = frozenset(('SYSTEMROOT', 'WINDIR', 'SYSTEMDRIVE', 'TEMP', 'TMP', 'PATH', 'COMSPEC', 'PATHEXT', 'PROGRAMFILES', 'PROGRAMFILES(X86)', 'LOCALAPPDATA'))
CODES = frozenset(('INVALID_MODE', 'HOSTILE_ENVIRONMENT', 'ENVIRONMENT_INVALID', 'PATH_SCOPE_CHANGED', 'RUNNER_CHANGED', 'MANIFEST_CHANGED', 'READINESS_INVALID', 'MANIFEST_SCOPE_CHANGED', 'DPAPI_FAILED', 'NODE_MISSING', 'WINDOWS_REQUIRED', 'PROCESS_CONTAINMENT_FAILED', 'PROCESS_CLEANUP_FAILED', 'RUNNER_TIMEOUT', 'UNSAFE_RUNNER_OUTPUT', 'UNEXPECTED_RUNNER_OUTPUT', 'RUNNER_RESULT_MISSING', 'INCONSISTENT_RUNNER_RESULT', 'EXECUTION_FAILED'))
TIMEOUT_SECONDS = 900
CLEANUP_SECONDS = 5


class LaunchError(Exception):
    def __init__(self, code):
        self.code = code if code in CODES else 'EXECUTION_FAILED'
        super().__init__(self.code)


def require(ok, code):
    if not ok:
        raise LaunchError(code)


def parse_mode(argv):
    require(type(argv) in (tuple, list) and len(argv) == 1 and argv[0] in MODES, 'INVALID_MODE')
    return argv[0]


def node_environment(source):
    """New dict only: case-insensitive names, no broad environment inheritance."""
    require(all(type(key) is str for key in source), 'ENVIRONMENT_INVALID')
    require(not any(key.upper().startswith('SQLCMD') for key in source), 'HOSTILE_ENVIRONMENT')
    child = {}
    for key, value in source.items():
        canonical = key.upper()
        if canonical not in NODE_ENVIRONMENT:
            continue
        require(canonical not in child and type(value) is str and '\x00' not in value, 'ENVIRONMENT_INVALID')
        child[canonical] = value
    return child


def fixed_paths():
    job = ROOT / JOB_RELATIVE
    paths = {'runner': ROOT / RUNNER_RELATIVE, 'readiness': job / 'environment-readiness.json', 'sealed': job / 'patients-manifest.dpapi', 'helper': ROOT / 'scripts/provision-isolated-sqlserver-logins.py', 'frontend': ROOT / 'frontend'}
    require(all(p.resolve().is_relative_to(ROOT) for p in paths.values()), 'PATH_SCOPE_CHANGED')
    return paths


def validate_manifest(value):
    keys = ('human', 'otherHuman', 'animal')
    require(type(value) is dict and set(value) == {'schema', 'qaDatabase', 'baseUrl', 'runId', *keys}, 'MANIFEST_SCOPE_CHANGED')
    require(value['schema'] == 'health-patients-real-qa-v1' and value['qaDatabase'] == DATABASE and value['runId'] == RUN_ID and value['baseUrl'] == BASE_URL, 'MANIFEST_SCOPE_CHANGED')
    hosts, tenants, passwords = set(), set(), []
    for key in keys:
        entry = value[key]
        require(type(entry) is dict and set(entry) == {'hostname', 'tenantId', 'email', 'password'}, 'MANIFEST_SCOPE_CHANGED')
        host, tenant, email, password = (entry[k] for k in ('hostname', 'tenantId', 'email', 'password'))
        require(type(host) is str and re.fullmatch(r'qa-[a-z0-9](?:[a-z0-9-]{0,55}[a-z0-9])?\.health\.localhost', host) and host not in hosts, 'MANIFEST_SCOPE_CHANGED')
        try:
            canonical = type(tenant) is str and str(uuid.UUID(tenant)) == tenant
        except (ValueError, AttributeError, TypeError):
            canonical = False
        require(canonical and tenant not in tenants, 'MANIFEST_SCOPE_CHANGED')
        require(type(email) is str and len(email) <= 254 and re.fullmatch(r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[a-z0-9-]+\.)*example\.test", email), 'MANIFEST_SCOPE_CHANGED')
        require(type(password) is str and bool(password.strip()) and len(password) <= 1024, 'MANIFEST_SCOPE_CHANGED')
        hosts.add(host)
        tenants.add(tenant)
        passwords.append(password)
    return passwords


def decode_json(raw, code):
    try:
        return json.loads(raw)
    except (ValueError, UnicodeError, TypeError):
        raise LaunchError(code) from None


def read_bytes(path):
    return path.read_bytes()


def decrypt_manifest(sealed, helper):
    """Load the existing DPAPI helper lazily, only after both artifact hashes pass."""
    try:
        spec = importlib.util.spec_from_file_location('patients_qa_dpapi', helper)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module.Dpapi().unprotect(sealed)
    except Exception:
        raise LaunchError('DPAPI_FAILED') from None


def load_manifest(paths, read=read_bytes, decrypt=decrypt_manifest):
    require(hashlib.sha256(read(paths['runner'])).hexdigest().upper() == RUNNER_SHA256, 'RUNNER_CHANGED')
    raw_readiness = read(paths['readiness'])
    require(type(raw_readiness) is bytes and len(raw_readiness) <= 262144, 'READINESS_INVALID')
    readiness = decode_json(raw_readiness, 'READINESS_INVALID')
    require(type(readiness) is dict and type(readiness.get('manifestCipherSHA256')) is str and re.fullmatch('[0-9a-f]{64}', readiness['manifestCipherSHA256']), 'READINESS_INVALID')
    sealed = read(paths['sealed'])
    require(type(sealed) is bytes and 0 < len(sealed) <= 2097152 and hashlib.sha256(sealed).hexdigest() == readiness['manifestCipherSHA256'], 'MANIFEST_CHANGED')
    wire = decrypt(sealed, paths['helper'])
    require(type(wire) is bytes and 0 < len(wire) <= 65536, 'MANIFEST_SCOPE_CHANGED')
    passwords = validate_manifest(decode_json(wire, 'MANIFEST_SCOPE_CHANGED'))
    return wire, passwords


def resolve_node(environment):
    # Avoid shutil.which's implicit parent PATHEXT/current-directory behavior.
    for directory in environment.get('PATH', '').split(';'):
        directory = directory.strip().strip('"')
        if not ntpath.isabs(directory):
            continue
        candidate = Path(directory) / 'node.exe'
        if candidate.is_file():
            return str(candidate.resolve())
    raise LaunchError('NODE_MISSING')


def filter_result(result, mode, passwords):
    require(type(result.returncode) is int, 'UNEXPECTED_RUNNER_OUTPUT')
    require(type(result.stdout) is bytes and type(result.stderr) is bytes, 'UNEXPECTED_RUNNER_OUTPUT')
    output = result.stdout + result.stderr
    for password in passwords:
        forms = (password.encode('utf-8'), json.dumps(password, ensure_ascii=True)[1:-1].encode('utf-8'), json.dumps(password, ensure_ascii=False)[1:-1].encode('utf-8'))
        require(not any(form and form in output for form in forms), 'UNSAFE_RUNNER_OUTPUT')
    require(len(output) <= 1048576, 'UNEXPECTED_RUNNER_OUTPUT')
    signals = []
    for raw in (result.stdout, result.stderr):
        try:
            lines = raw.decode('utf-8', errors='strict').splitlines()
        except UnicodeError:
            raise LaunchError('UNEXPECTED_RUNNER_OUTPUT') from None
        for line in lines:
            value = decode_json(line, 'UNEXPECTED_RUNNER_OUTPUT')
            require(type(value) is dict and set(value) <= {'control', 'status', 'code'} and value.get('control') == 'runner' and value.get('status') in ('passed', 'failed'), 'UNEXPECTED_RUNNER_OUTPUT')
            signals.append({'control': 'runner', 'status': value['status']})
    require(bool(signals), 'RUNNER_RESULT_MISSING')
    require((result.returncode == 0 and all(s['status'] == 'passed' for s in signals)) or (result.returncode != 0 and any(s['status'] == 'failed' for s in signals)), 'INCONSISTENT_RUNNER_RESULT')
    return {'mode': mode, 'rawExit': result.returncode, 'signals': signals, 'credentialsPrinted': False}


class BasicLimits(ctypes.Structure):
    _fields_ = [('PerProcessUserTimeLimit', ctypes.c_int64), ('PerJobUserTimeLimit', ctypes.c_int64), ('LimitFlags', wintypes.DWORD), ('MinimumWorkingSetSize', ctypes.c_size_t), ('MaximumWorkingSetSize', ctypes.c_size_t), ('ActiveProcessLimit', wintypes.DWORD), ('Affinity', ctypes.c_size_t), ('PriorityClass', wintypes.DWORD), ('SchedulingClass', wintypes.DWORD)]


class IoCounters(ctypes.Structure):
    _fields_ = [(name, ctypes.c_uint64) for name in ('ReadOperationCount', 'WriteOperationCount', 'OtherOperationCount', 'ReadTransferCount', 'WriteTransferCount', 'OtherTransferCount')]


class ExtendedLimits(ctypes.Structure):
    _fields_ = [('BasicLimitInformation', BasicLimits), ('IoInfo', IoCounters), ('ProcessMemoryLimit', ctypes.c_size_t), ('JobMemoryLimit', ctypes.c_size_t), ('PeakProcessMemoryUsed', ctypes.c_size_t), ('PeakJobMemoryUsed', ctypes.c_size_t)]


class Accounting(ctypes.Structure):
    _fields_ = [(name, ctypes.c_int64) for name in ('TotalUserTime', 'TotalKernelTime', 'ThisPeriodTotalUserTime', 'ThisPeriodTotalKernelTime')] + [(name, wintypes.DWORD) for name in ('TotalPageFaultCount', 'TotalProcesses', 'ActiveProcesses', 'TotalTerminatedProcesses')]


class WindowsJob:
    def __init__(self, kernel=None):
        if kernel is None:
            require(os.name == 'nt', 'WINDOWS_REQUIRED')
            kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        self.kernel, self.handle = kernel, None
        for name, args, returns in (
            ('CreateJobObjectW', [ctypes.c_void_p, wintypes.LPCWSTR], wintypes.HANDLE),
            ('SetInformationJobObject', [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD], wintypes.BOOL),
            ('AssignProcessToJobObject', [wintypes.HANDLE, wintypes.HANDLE], wintypes.BOOL),
            ('TerminateJobObject', [wintypes.HANDLE, wintypes.UINT], wintypes.BOOL),
            ('QueryInformationJobObject', [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD, ctypes.c_void_p], wintypes.BOOL),
            ('CloseHandle', [wintypes.HANDLE], wintypes.BOOL),
        ):
            fn = getattr(kernel, name)
            fn.argtypes, fn.restype = args, returns
        self.handle = kernel.CreateJobObjectW(None, None)
        require(bool(self.handle), 'PROCESS_CONTAINMENT_FAILED')
        limits = ExtendedLimits()
        limits.BasicLimitInformation.LimitFlags = 0x2000  # KILL_ON_JOB_CLOSE, no breakaway.
        if not kernel.SetInformationJobObject(self.handle, 9, ctypes.byref(limits), ctypes.sizeof(limits)):
            self.close()
            raise LaunchError('PROCESS_CONTAINMENT_FAILED')

    def assign(self, process):
        require(self.kernel.AssignProcessToJobObject(self.handle, int(process._handle)), 'PROCESS_CONTAINMENT_FAILED')

    def stop(self):
        require(self.kernel.TerminateJobObject(self.handle, 1), 'PROCESS_CLEANUP_FAILED')
        deadline = time.monotonic() + CLEANUP_SECONDS
        while True:
            accounting = Accounting()
            require(self.kernel.QueryInformationJobObject(self.handle, 1, ctypes.byref(accounting), ctypes.sizeof(accounting), None), 'PROCESS_CLEANUP_FAILED')
            if accounting.ActiveProcesses == 0:
                return
            require(time.monotonic() < deadline, 'PROCESS_CLEANUP_FAILED')
            time.sleep(0.01)

    def close(self):
        if self.handle:
            handle, self.handle = self.handle, None
            require(self.kernel.CloseHandle(handle), 'PROCESS_CLEANUP_FAILED')


def contained_run(argv, wire, cwd, environment, *, popen=subprocess.Popen, job_factory=WindowsJob):
    """Node waits for stdin; job association precedes credentials and browser startup."""
    job, process, assigned = job_factory(), None, False
    try:
        process = popen(argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd, env=environment, shell=False, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0), close_fds=True)
        job.assign(process)
        assigned = True
        try:
            stdout, stderr = process.communicate(input=wire, timeout=TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            raise LaunchError('RUNNER_TIMEOUT') from None
        return subprocess.CompletedProcess(argv, process.returncode, stdout, stderr)
    finally:
        try:
            if assigned:
                job.stop()  # Also terminate any descendants left after normal Node exit.
            elif process is not None and process.poll() is None:
                process.kill()  # No stdin was sent, so the pinned runner cannot spawn Edge.
        finally:
            try:
                job.close()  # KILL_ON_JOB_CLOSE backs up termination on every path.
            finally:
                if process is not None:
                    try:
                        process.communicate(timeout=CLEANUP_SECONDS)
                        process.wait(timeout=CLEANUP_SECONDS)
                    except Exception:
                        raise LaunchError('PROCESS_CLEANUP_FAILED') from None
                    finally:
                        for stream in (process.stdin, process.stdout, process.stderr):
                            if stream is not None:
                                stream.close()


def execute(argv, *, source=None, read=read_bytes, decrypt=decrypt_manifest, resolve=resolve_node, transport=contained_run):
    mode = parse_mode(argv)
    environment = node_environment(os.environ if source is None else source)
    paths = fixed_paths()
    wire, passwords = load_manifest(paths, read, decrypt)
    node = resolve(environment)
    require(type(node) is str and ntpath.isabs(node) and ntpath.basename(node).lower() == 'node.exe', 'NODE_MISSING')
    result = transport([node, str(paths['runner']), mode], wire, paths['frontend'], environment)
    return filter_result(result, mode, passwords)


def main(argv=None, *, output=None, **dependencies):
    output = sys.stdout if output is None else output
    try:
        payload = execute(sys.argv[1:] if argv is None else argv, **dependencies)
        exit_code = 0 if payload['rawExit'] == 0 else 1
    except BaseException as error:
        code = error.code if isinstance(error, LaunchError) else 'EXECUTION_FAILED'
        exit_code = 124 if code == 'RUNNER_TIMEOUT' else 1
        payload = {'status': 'execution_failed', 'code': code, 'rawExit': exit_code, 'credentialsPrinted': False}
    try:
        print(json.dumps(payload), file=output)
    except BaseException:
        return 1
    return exit_code


if __name__ == '__main__':
    raise SystemExit(main())