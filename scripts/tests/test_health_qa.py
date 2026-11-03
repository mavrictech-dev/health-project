"""Offline acceptance tests require Git, but no daemon, packages, or real APIs.

Run: python -B -m unittest discover -s scripts/tests -v
"""
from contextlib import redirect_stdout, redirect_stderr
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def load(name, source):
    spec = importlib.util.spec_from_file_location(name, source)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


qa = load("health_qa", ROOT / "scripts" / "health-qa.py")
config = load("qa_config", ROOT / "backend" / "scripts" / "qa_config.py")


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.init_repository(self.root)
        self.original = self.root / ".env"
        self.original.write_text("DO_NOT_READ_OR_CHANGE=original\n", encoding="utf-8")
        self.calls = []

        def fake_run(argv, **kwargs):
            self.calls.append((argv, kwargs))
            return subprocess.CompletedProcess(argv, 0, stdout="[]", stderr="")

        self.runner = qa.Runner(self.root, run=fake_run)

    def init_repository(self, root):
        # Synthetic repositories only: no commits, config changes, or real worktrees.
        env = {key: value for key, value in os.environ.items() if not key.upper().startswith("GIT_")}
        result = subprocess.run(["git", "init", "--quiet", str(root)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, "Git is required for the QA runner and its offline fixtures")

    def linked_worktree(self):
        other = self.root / "linked-checkout"
        other.mkdir()
        common = self.root / ".git"
        gitdir = common / "worktrees" / "synthetic-linked"
        gitdir.mkdir(parents=True)
        (gitdir / "HEAD").write_bytes((common / "HEAD").read_bytes())
        (gitdir / "commondir").write_text("../..\n", encoding="utf-8")
        (gitdir / "gitdir").write_text(str(other / ".git") + "\n", encoding="utf-8")
        (other / ".git").write_text("gitdir: " + str(gitdir) + "\n", encoding="utf-8")
        return other

    def prepare(self):
        self.runner.execute("prepare")

    def export(self):
        out = self.root / "frontend" / "out"
        out.mkdir(parents=True)
        (out / "index.html").write_text("<html>live export</html>", encoding="utf-8")

    def dependencies(self):
        (self.root / "frontend" / "node_modules" / "playwright").mkdir(parents=True)

    def test_prepare_is_private_idempotent_and_never_opens_original_env(self):
        original_read = Path.read_text

        def guarded_read(path, *args, **kwargs):
            if path == self.original:
                self.fail("Runner attempted to read the original .env")
            return original_read(path, *args, **kwargs)

        before = self.original.stat().st_mtime_ns
        with patch.object(Path, "read_text", guarded_read):
            self.prepare()
            first = self.runner.env_file.read_bytes()
            self.prepare()
        self.assertTrue(first == self.runner.env_file.read_bytes(), "Prepare must preserve QA credentials")
        self.assertEqual(self.original.stat().st_mtime_ns, before)
        self.assertEqual(self.original.read_text(), "DO_NOT_READ_OR_CHANGE=original\n")
        self.assertEqual(self.calls, [])
        values = self.runner.validate_config()
        self.assertEqual(values["BOOTSTRAP_ADMIN_EMAIL"], "qa-admin@example.test")
        self.assertEqual(values["HEALTH_PUBLIC_ORIGIN"], qa.UI_URL)
        self.assertTrue(all(len(values[key]) == 64 for key in qa.SECRET_KEYS))
        self.assertFalse(self.runner.lock_file.exists())

    def test_config_uses_exact_qa_selectors_without_daemon_probe_or_env_leaks(self):
        self.prepare()
        hostile = {"HEALTH_TEST_URL": "https://foreign.example", "HEALTH_ENV_FILE": str(self.original),
                   "COMPOSE_FILE": "compose.yaml", "COMPOSE_PROJECT_NAME": "health-project",
                   "DATABASE_PASSWORD": "never-inherit", "SMTP_HOST": "external.example",
                   "DOCKER_HOST": "tcp://remote.example:2375", "DOCKER_CONTEXT": "remote"}
        with patch.dict(os.environ, hostile):
            before = dict(os.environ)
            self.runner.execute("config")
            self.assertTrue(dict(os.environ) == before, "Parent environment changed")
        self.assertEqual(len(self.calls), 1)
        argv, kwargs = self.calls[0]
        self.assertEqual(argv, self.runner.compose("config", "--quiet"))
        self.assertEqual(kwargs["cwd"], str(self.root))
        env = kwargs["env"]
        self.assertEqual(env["HEALTH_ENV_FILE"], str(self.runner.env_file))
        self.assertEqual(env["HEALTH_COMPOSE_ENV_FILE"], str(self.runner.env_file))
        self.assertEqual(env["HEALTH_COMPOSE_FILE"], str(self.root / "compose.qa.yaml"))
        self.assertEqual(env["HEALTH_COMPOSE_PROJECT"], "health-project-qa")
        self.assertEqual(env["HEALTH_MAILPIT_URL"], "http://127.0.0.1:18025")
        self.assertEqual(env["HEALTH_TEST_URL"], "http://127.0.0.1:18080")
        self.assertEqual(env["DOCKER_HOST"], qa.DOCKER_HOST)
        for key in ("COMPOSE_FILE", "COMPOSE_PROJECT_NAME", "DATABASE_PASSWORD", "SMTP_HOST", "DOCKER_CONTEXT"):
            self.assertNotIn(key, env)
        self.assertTrue(kwargs["capture_output"])

    def test_competitor_cannot_invoke_docker_or_remove_owner_lock(self):
        self.prepare()
        rival = qa.Runner(self.root, run=lambda *a, **kw: self.fail("Competitor invoked Docker"))
        with self.runner.locked():
            before = self.runner.lock_file.read_bytes()
            with self.assertRaisesRegex(qa.QAError, "QA_LOCKED"):
                rival.execute("config")
            self.assertTrue(self.runner.lock_file.read_bytes() == before)
        self.assertFalse(self.runner.lock_file.exists())
        self.assertEqual(self.calls, [])

    def test_linked_worktrees_share_lock_before_docker_but_keep_local_config(self):
        self.prepare()
        other = self.linked_worktree()
        rival = qa.Runner(other, run=lambda *a, **kw: self.fail("Linked worktree invoked Docker"))
        self.assertEqual(rival.lock_file, self.runner.lock_file)
        self.assertEqual(self.runner.lock_file, self.root / ".git" / "health-project-qa.run.lock")
        self.assertNotEqual(rival.env_file, self.runner.env_file)
        with self.runner.locked():
            before = self.runner.lock_file.read_bytes()
            with self.assertRaisesRegex(qa.QAError, "QA_LOCKED"):
                rival.execute("config")
            self.assertTrue(self.runner.lock_file.read_bytes() == before)
            self.assertFalse(rival.directory.exists())
        rival.execute("prepare")
        self.assertTrue(rival.env_file.is_file())
        self.assertTrue(self.runner.env_file.is_file())
        self.assertFalse(self.runner.lock_file.exists())

    def test_independent_repositories_do_not_share_lock(self):
        other = self.root / "independent-repository"
        self.init_repository(other)
        rival = qa.Runner(other, run=lambda *a, **kw: self.fail("Prepare must not invoke Docker"))
        self.assertNotEqual(rival.lock_file, self.runner.lock_file)
        with self.runner.locked():
            rival.execute("prepare")
            self.assertTrue(self.runner.lock_file.exists())
            self.assertFalse(rival.lock_file.exists())
        self.assertTrue(rival.env_file.is_file())

    def test_git_is_required_and_invalid_common_directory_has_no_fallback(self):
        missing = self.root / "not-a-repository"
        missing.mkdir()
        # Reject a subdirectory even if Git can discover an ancestor repository.
        with self.assertRaisesRegex(qa.QAError, "QA_GIT_COMMON_DIR_UNAVAILABLE"):
            qa.Runner(missing)
        self.assertFalse((missing / "tmp").exists())
        for failure in (FileNotFoundError("private diagnostic"), subprocess.TimeoutExpired("git", 15)):
            def failing_git(*args, **kwargs):
                raise failure
            with self.assertRaisesRegex(qa.QAError, "QA_GIT_COMMON_DIR_UNAVAILABLE") as caught:
                qa.Runner(self.root, git_run=failing_git)
            self.assertNotIn("private diagnostic", str(caught.exception))
        for result in (subprocess.CompletedProcess([], 1, "", "private diagnostic"),
                       subprocess.CompletedProcess([], 0, "relative\nrelative\n", ""),
                       subprocess.CompletedProcess([], 0, str(self.root) + "\n" + str(self.root) + "\n", "")):
            with self.assertRaisesRegex(qa.QAError, "QA_GIT_COMMON_DIR_UNAVAILABLE"):
                qa.Runner(self.root, git_run=lambda *a, **kw: result)

    def test_inherited_git_overrides_cannot_choose_another_repo(self):
        with patch.dict(os.environ, {"GIT_DIR": str(self.root / "foreign"), "GIT_COMMON_DIR": str(self.root / "foreign"),
                                     "GIT_WORK_TREE": str(self.root / "foreign")}):
            runner = qa.Runner(self.root)
        self.assertEqual(runner.lock_file, self.runner.lock_file)

    def test_lock_released_on_error_and_interrupt(self):
        for error in (RuntimeError("offline"), KeyboardInterrupt()):
            with self.assertRaises(type(error)):
                with self.runner.locked():
                    raise error
            self.assertFalse(self.runner.lock_file.exists())
        with self.runner.locked():
            pass

    def test_stale_or_replaced_locks_are_not_deleted_blindly(self):
        self.runner.directory.mkdir(parents=True)
        self.runner.lock_file.write_text("operator must inspect this lock", encoding="utf-8")
        with self.assertRaisesRegex(qa.QAError, "QA_LOCKED"):
            self.prepare()
        self.assertEqual(self.runner.lock_file.read_text(), "operator must inspect this lock")
        self.runner.lock_file.unlink()  # This test owns this synthetic lock.
        with self.runner.locked():
            self.runner.lock_file.write_text('{"owner":"other-process"}', encoding="utf-8")
        self.assertTrue(self.runner.lock_file.exists())

    def test_malformed_replacement_lock_does_not_mask_original_error(self):
        for replacement in ("null", "[]", "invalid-json"):
            with self.assertRaisesRegex(RuntimeError, "original failure"):
                with self.runner.locked():
                    self.runner.lock_file.write_text(replacement, encoding="utf-8")
                    raise RuntimeError("original failure")
            self.assertEqual(self.runner.lock_file.read_text(), replacement)
            self.runner.lock_file.unlink()  # This test owns the replacement fixture.

    def test_foreign_or_malformed_config_is_rejected_before_docker(self):
        self.prepare()
        baseline = self.runner.env_file.read_text()
        for text in (baseline.replace(qa.UI_URL, "http://health.localhost:8080"),
                     baseline + "SMTP_HOST=external.example\n", baseline + "HEALTH_TEST_URL=https://foreign.example\n",
                     baseline + "HEALTH_BASE_DOMAIN=health.localhost\n", "malformed"):
            self.runner.env_file.write_text(text, encoding="utf-8")
            with self.assertRaisesRegex(qa.QAError, "QA_ENV_INVALID"):
                self.runner.execute("config")
            self.assertFalse(self.runner.lock_file.exists())
        self.assertEqual(self.calls, [])

    def test_missing_environment_export_and_ui_dependencies_fail_before_docker(self):
        with self.assertRaisesRegex(qa.QAError, "QA_ENV_MISSING: run python scripts/health-qa.py prepare"):
            self.runner.execute("config")
        self.prepare()
        for action in ("up", "ui"):
            with self.assertRaisesRegex(qa.QAError, "QA_EXPORT_MISSING: from frontend run npm ci then npm run build"):
                self.runner.execute(action)
        self.export()
        with self.assertRaisesRegex(qa.QAError, "QA_UI_DEPENDENCIES_MISSING"):
            self.runner.execute("ui")
        self.assertEqual(self.calls, [])
        self.assertFalse(self.runner.lock_file.exists())

    def test_unavailable_daemon_stops_before_compose_and_hides_child_output(self):
        self.prepare()
        self.export()
        self.runner.run = lambda argv, **kw: subprocess.CompletedProcess(argv, 1, "sensitive-output", "sensitive-output")
        with self.assertRaisesRegex(qa.QAError, "QA_DAEMON_UNAVAILABLE") as caught:
            self.runner.execute("up")
        self.assertNotIn("sensitive-output", str(caught.exception))
        self.assertFalse(self.runner.lock_file.exists())

    def test_missing_executable_and_timeouts_release_lock_and_hide_details(self):
        self.prepare()
        for failure in (FileNotFoundError("sensitive-output"), subprocess.TimeoutExpired("sensitive-output", 10)):
            def failing_run(*args, **kwargs):
                raise failure
            self.runner.run = failing_run
            with self.assertRaises(qa.QAError) as caught:
                self.runner.execute("config")
            self.assertNotIn("sensitive-output", str(caught.exception))
            self.assertFalse(self.runner.lock_file.exists())

    def test_all_actions_remain_serial_and_only_address_qa(self):
        self.prepare()
        self.export()
        self.dependencies()
        for action in ("config", "up", "status", "api", "identity", "ui", "down"):
            with redirect_stdout(io.StringIO()):
                self.runner.execute(action)
            self.assertFalse(self.runner.lock_file.exists())
        compose_calls = []
        for argv, kwargs in self.calls:
            self.assertNotIn("verify-persistence.py", " ".join(argv))
            self.assertTrue(kwargs["env"]["HEALTH_ENV_FILE"] == str(self.runner.env_file))
            if argv[:2] == ["docker", "compose"]:
                compose_calls.append(argv)
                self.assertEqual(argv[:8], self.runner.compose())
                for prohibited in ("--volumes", "-v", "prune", "rm", "restart", "stop"):
                    self.assertNotIn(prohibited, argv[8:])
            if argv[0] == "node":
                self.assertEqual(kwargs["cwd"], str(self.root / "frontend"))
                self.assertEqual(kwargs["env"]["HEALTH_TEST_URL"], "http://health.localhost:18080")
        self.assertTrue(any(argv[8:] == ["down"] for argv in compose_calls))
        self.assertTrue(any(argv[8:][:3] == ["up", "-d", "--build"] for argv in compose_calls))
        self.assertTrue(any("verify-api.py" in " ".join(argv) for argv, _ in self.calls))
        self.assertTrue(any("verify-identity-trace.py" in " ".join(argv) for argv, _ in self.calls))

    def test_status_only_prints_service_state_health(self):
        self.prepare()
        self.runner.run = lambda argv, **kw: subprocess.CompletedProcess(argv, 0, json.dumps([
            {"Service": "mysql", "State": "running", "Health": "healthy", "Forbidden": "private-output"}]), "")
        output = io.StringIO()
        with redirect_stdout(output):
            self.runner.execute("status")
        self.assertEqual(json.loads(output.getvalue()), [{"Service": "mysql", "State": "running", "Health": "healthy"}])
        self.assertNotIn("private-output", output.getvalue())

    def test_runner_does_not_accept_destination_or_compose_overrides(self):
        for action in ("https://foreign.example", "prune", "verify-persistence"):
            with self.assertRaisesRegex(qa.QAError, "QA_COMMAND_INVALID"):
                self.runner.execute(action)
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as caught:
            qa.main(["config", "--url", "https://foreign.example"])
        self.assertEqual(caught.exception.code, 2)
        self.assertEqual(self.calls, [])


class ContractTests(unittest.TestCase):
    def test_compose_declares_standalone_loopback_ports_private_volume_and_local_mail(self):
        text = (ROOT / "compose.qa.yaml").read_text(encoding="utf-8")
        self.assertTrue(text.startswith("name: health-project-qa\n"))
        for port in ("127.0.0.1:18080:80", "127.0.0.1:13307:3306", "127.0.0.1:18025:8025"):
            self.assertIn(port, text)
        for prohibited in ("extends:", "include:", "external: true", "health-project-backend:local", "${SMTP_", "${HEALTH_", "${MAIL_"):
            self.assertNotIn(prohibited, text)
        for required in ("name: health-project-qa_mysql_data", "image: health-project-backend:qa", "build: ./backend",
                         "SMTP_HOST: mailpit", "SMTP_PORT: '1025'", "MAIL_FROM: qa-no-reply@example.test",
                         "source: ./frontend/out", "create_host_path: false", "http://health.localhost:18080",
                         "./docker/nginx/default.conf.template", "./docker/mysql/01-privileges.sh"):
            self.assertIn(required, text)

    def test_suite_config_defaults_and_overrides(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            normal = root / ".env"
            dedicated = root / "qa.env"
            normal.write_text("SOURCE=legacy\n", encoding="utf-8")
            dedicated.write_text("\ufeffSOURCE=qa\n", encoding="utf-8")
            with patch.dict(os.environ, {}, clear=True):
                self.assertEqual(config.load_config(root), {"SOURCE": "legacy"})
                self.assertEqual(config.compose_command(), ["docker", "compose"])
            overrides = {"HEALTH_ENV_FILE": str(dedicated), "HEALTH_COMPOSE_PROJECT": "health-project-qa",
                         "HEALTH_COMPOSE_FILE": str(root / "compose.qa.yaml"), "HEALTH_COMPOSE_ENV_FILE": str(dedicated)}
            with patch.dict(os.environ, overrides, clear=True):
                self.assertEqual(config.load_config(root), {"SOURCE": "qa"})
                self.assertEqual(config.compose_command(), ["docker", "compose", "--project-name", "health-project-qa",
                                                          "--file", str(root / "compose.qa.yaml"), "--env-file", str(dedicated)])

    def test_real_python_suites_use_overridden_http_host_and_mail_with_fake_transports(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "qa.env"
            source.write_text("HEALTH_BASE_DOMAIN=health.localhost\nBOOTSTRAP_ADMIN_EMAIL=qa-admin@example.test\n", encoding="utf-8")
            env = {"HEALTH_ENV_FILE": str(source), "HEALTH_TEST_URL": qa.API_URL,
                   "HEALTH_MAILPIT_URL": qa.MAIL_URL}
            with patch.dict(os.environ, env, clear=True), patch.dict(sys.modules, {"qa_config": config}):
                api = load("verify_api_offline", ROOT / "backend/scripts/verify-api.py")
                identity = load("verify_identity_offline", ROOT / "backend/scripts/verify-identity-trace.py")
            http_calls = []

            class FakeHTTP:
                def open(self, request, **kwargs):
                    http_calls.append(request)
                    response = io.BytesIO(b'{}')
                    response.status = 200
                    return response

            api.HTTP = FakeHTTP()
            api.api("GET", "/api/public/context", host="tenant.health.localhost")
            self.assertEqual(http_calls[0].full_url, qa.API_URL + "/api/public/context")
            self.assertEqual(http_calls[0].get_header("Host"), "tenant.health.localhost")
            connection_calls = []

            class FakeConnection:
                def __init__(self, host, port, **kwargs):
                    connection_calls.append((host, port))

                def request(self, method, path, body, headers):
                    connection_calls.append((method, path, headers["Host"]))

                def getresponse(self):
                    class Response:
                        status = 200

                        def read(self): return b'{}'

                        def getheaders(self): return []
                    return Response()

                def close(self): pass

            with patch.object(identity.http.client, "HTTPConnection", FakeConnection):
                identity.request("GET", "/api/public/context", host="tenant.health.localhost")
            self.assertEqual(connection_calls, [("127.0.0.1", 18080), ("GET", "/api/public/context", "tenant.health.localhost")])
            mail_calls = []

            class FakeMail:
                def open(self, url, **kwargs):
                    mail_calls.append(url)
                    payload = ({"messages": [{"ID": "synthetic", "To": [{"Address": "qa@example.test"}]}]}
                               if url.endswith("/messages") else {"Text": "http://tenant.health.localhost:18080/verificar/#token=" + "x" * 43})
                    return io.BytesIO(json.dumps(payload).encode())

            with patch.object(identity.urllib.request, "build_opener", return_value=FakeMail()):
                host, token = identity.mail_token("qa@example.test", "VERIFY")
            self.assertEqual(host, "tenant.health.localhost")
            self.assertTrue(len(token) == 43)
            self.assertEqual(mail_calls, [qa.MAIL_URL + "/api/v1/messages", qa.MAIL_URL + "/api/v1/message/synthetic"])

    def test_python_syntax_without_writing_bytecode(self):
        for source in ("scripts/health-qa.py", "backend/scripts/qa_config.py", "backend/scripts/verify-api.py",
                       "backend/scripts/verify-identity-trace.py", "scripts/tests/test_health_qa.py"):
            compile((ROOT / source).read_text(encoding="utf-8"), source, "exec")

    @unittest.skipUnless(shutil.which("node"), "Node is required for offline JS checks")
    def test_js_syntax_without_playwright(self):
        result = subprocess.run(["node", "--check", str(ROOT / "frontend/scripts/identity-qa.cjs")], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which("node"), "Node is required for offline UI simulation")
    def test_ui_restores_only_selected_origin_and_preserves_original_error(self):
        # Execute the real UI script in a sandbox with fake browser/config/network.
        harness = r"""
const vm=require('node:vm'), fs=require('node:fs');
const calls=[]; let changed=false;
const node={
  first(){return this},last(){return this},filter(){return this},getByRole(){return this},
  async click(){},async fill(){},async selectOption(){},async check(){},async screenshot(){},
  async getAttribute(){return 'https://mavrictec.com'},async allTextContents(){return []},
  async waitFor(){if(changed)throw Error('original-ui-failure')}
};
const page={getByRole(role,options){if(role==='heading'&&options?.name==='Aplicación en solo lectura')changed=true;return node},
  getByLabel(){return node},locator(){return node},setDefaultTimeout(){},on(){},async goto(){},async screenshot(){},
  async evaluate(fn,arg){return fn(arg)},waitForEvent(){return Promise.resolve({async saveAs(){}})}};
const browser={async newContext(){return {async newPage(){return page}}},async close(){}};
const fakeFetch=async (url,options)=>{
  const origin='http://health.localhost:18080';
  if(options.credentials!=='same-origin')throw Error('Cookies must remain same origin');
  if(options.method==='PUT'){calls.push(['PUT',origin+url,JSON.parse(options.body).mode]);return {ok:process.argv[2]!=='cleanup-fails'}};
  calls.push(['GET',origin+url]);return {ok:true,json:async()=>url.endsWith('/session')?{csrfToken:'synthetic'}:{mode:'READ_ONLY',revision:2}};
};
const logs=[];
const done=new Promise(resolve=>{
const fakeProcess={env:{HEALTH_ENV_FILE:'dedicated-only',HEALTH_TEST_URL:'http://health.localhost:18080',HEALTH_MAILPIT_URL:'http://127.0.0.1:18025'},exit:code=>resolve(code)};
vm.runInNewContext(fs.readFileSync(process.argv[1],'utf8'),{require:name=>{
  if(name==='playwright')return {chromium:{launch:async()=>browser}};
  if(name==='node:fs')return {readFileSync:file=>{if(file!=='dedicated-only')throw Error('wrong-env');return 'BOOTSTRAP_ADMIN_EMAIL=qa-admin@example.test\nBOOTSTRAP_ADMIN_PASSWORD=synthetic'},mkdirSync(){},writeFileSync(){}};
  return require(name);
},process:fakeProcess,console:{log(){},error:(...args)=>logs.push(args.join(' '))},setTimeout,fetch:fakeFetch,
  URL,location:{origin:process.argv[2]==='wrong-origin'?'http://other.localhost:18080':'http://health.localhost:18080'},document:{cookie:''}});
});
done.then(code=>console.log(JSON.stringify({code,calls,logs})));
"""
        for scenario in ("cleanup-ok", "cleanup-fails", "wrong-origin"):
            result = subprocess.run(["node", "-e", harness, str(ROOT / "frontend/scripts/identity-qa.cjs"), scenario],
                                    capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads(result.stdout)
            self.assertEqual(report["code"], 1)
            self.assertTrue(any("original-ui-failure" == message for message in report["logs"]))
            expected_calls = [["GET", qa.UI_URL + "/api/auth/browser/session"],
                                               ["GET", qa.UI_URL + "/api/public/status"],
                                               ["PUT", qa.UI_URL + "/api/monitor/mode", "OPEN"]]
            self.assertEqual(report["calls"], [] if scenario == "wrong-origin" else expected_calls)
            self.assertEqual(any("original UI error preserved" in message for message in report["logs"]), scenario != "cleanup-ok")


if __name__ == "__main__":
    unittest.main()
