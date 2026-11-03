"""Isolated local synthetic QA. No dependencies beyond Python's standard library.

From the repository root:
  python scripts/health-qa.py prepare
  python scripts/health-qa.py config
  # Build the live export separately: cd frontend; npm ci; npm run build
  python scripts/health-qa.py up
  python scripts/health-qa.py api
  python scripts/health-qa.py identity
  python scripts/health-qa.py ui
  python scripts/health-qa.py down

Suites create fictional records and reports. Down retains the dedicated QA volume.
Operations lock <git-common-dir>/health-project-qa.run.lock across linked worktrees.
Credentials remain in each worktree's tmp/qa/.env. Git is required; no local fallback.
An existing lock is never reclaimed automatically: investigate its owning process.
"""
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "health-project-qa"
API_URL = "http://127.0.0.1:18080"
UI_URL = "http://health.localhost:18080"
MAIL_URL = "http://127.0.0.1:18025"
DOCKER_HOST = "npipe:////./pipe/dockerDesktopLinuxEngine" if os.name == "nt" else "unix:///var/run/docker.sock"
FIXED_CONFIG = {
    "HEALTH_BASE_DOMAIN": "health.localhost",
    "HEALTH_PUBLIC_ORIGIN": UI_URL,
    "BOOTSTRAP_ADMIN_EMAIL": "qa-admin@example.test",
}
SECRET_KEYS = ("MYSQL_ROOT_PASSWORD", "DATABASE_PASSWORD", "BOOTSTRAP_ADMIN_PASSWORD")


class QAError(Exception):
    """A safe diagnostic that never includes child output or configuration values."""


class Runner:
    def __init__(self, root=ROOT, run=subprocess.run, git_run=subprocess.run):
        self.root = Path(root).resolve()
        self.directory = self.root / "tmp" / "qa"
        self.env_file = self.directory / ".env"
        self.lock_file = self.git_common_dir(git_run) / "health-project-qa.run.lock"
        self.compose_file = self.root / "compose.qa.yaml"
        self.run = run

    def git_common_dir(self, git_run):
        error = "QA_GIT_COMMON_DIR_UNAVAILABLE: Git must resolve this worktree and a valid common directory; no local lock fallback."
        try:
            # Inherited Git overrides could otherwise select a different repository.
            env = {key: value for key, value in os.environ.items() if not key.upper().startswith("GIT_")}
            result = git_run(["git", "-C", str(self.root), "rev-parse", "--path-format=absolute",
                              "--show-toplevel", "--git-common-dir"], env=env,
                             capture_output=True, text=True, timeout=15)
            if result.returncode:
                raise QAError(error)
            lines = result.stdout.splitlines()
            if len(lines) != 2 or not all(Path(line).is_absolute() for line in lines):
                raise QAError(error)
            toplevel, common = (Path(line).resolve(strict=True) for line in lines)
            if (toplevel != self.root or not common.is_dir()
                    or not (common / "HEAD").is_file() or not (common / "objects").is_dir()):
                raise QAError(error)
            return common
        except (OSError, ValueError, subprocess.TimeoutExpired):
            raise QAError(error) from None

    @contextmanager
    def locked(self):
        nonce = secrets.token_hex(16)
        try:
            fd = os.open(self.lock_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        except FileExistsError:
            raise QAError(f"QA_LOCKED: {self.lock_file} exists; inspect its owner before manual recovery.") from None
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump({"pid": os.getpid(), "owner": nonce}, handle)
            self.directory.mkdir(parents=True, exist_ok=True)
            yield
        finally:
            # Do not delete a lock replaced by another process or an operator.
            try:
                record = json.loads(self.lock_file.read_text(encoding="utf-8"))
                if isinstance(record, dict) and record.get("owner") == nonce:
                    self.lock_file.unlink()
            except (OSError, ValueError):
                pass

    def prepare(self):
        if self.env_file.exists():
            self.validate_config()
            return
        values = {**FIXED_CONFIG, **{key: secrets.token_hex(32) for key in SECRET_KEYS}}
        fd = os.open(self.env_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write("".join(f"{key}={value}\n" for key, value in values.items()))

    def validate_config(self):
        if not self.env_file.is_file():
            raise QAError("QA_ENV_MISSING: run python scripts/health-qa.py prepare.")
        try:
            lines = self.env_file.read_text(encoding="utf-8").splitlines()
            values = dict(line.split("=", 1) for line in lines)
        except (ValueError, UnicodeError):
            raise QAError("QA_ENV_INVALID: expected the dedicated synthetic QA environment.") from None
        if (len(lines) != len(values) or set(values) != set(FIXED_CONFIG) | set(SECRET_KEYS)
                or any(values.get(key) != value for key, value in FIXED_CONFIG.items())
                or any(not re.fullmatch(r"[a-f0-9]{64}", values.get(key, "")) for key in SECRET_KEYS)):
            raise QAError("QA_ENV_INVALID: expected the dedicated synthetic QA environment.")
        return values

    def child_env(self, *, ui=False):
        # Compose interpolation must not inherit another checkout's settings.
        prefixes = ("COMPOSE_", "HEALTH_", "SMTP_", "BOOTSTRAP_", "MYSQL_", "DATABASE_", "MAIL_", "DOCKER_")
        env = {key: value for key, value in os.environ.items() if not key.upper().startswith(prefixes)}
        env.update({
            "HEALTH_ENV_FILE": str(self.env_file),
            "HEALTH_TEST_URL": UI_URL if ui else API_URL,
            "HEALTH_MAILPIT_URL": MAIL_URL,
            "HEALTH_COMPOSE_FILE": str(self.compose_file),
            "HEALTH_COMPOSE_PROJECT": PROJECT,
            "HEALTH_COMPOSE_ENV_FILE": str(self.env_file),
            "PYTHONDONTWRITEBYTECODE": "1",
            "DOCKER_HOST": DOCKER_HOST,
        })
        return env

    def compose(self, *args):
        return ["docker", "compose", "--project-name", PROJECT, "--file", str(self.compose_file),
                "--env-file", str(self.env_file), *args]

    def invoke(self, command, label, *, cwd=None, ui=False, timeout=120):
        try:
            result = self.run(command, cwd=str(cwd or self.root), env=self.child_env(ui=ui),
                              capture_output=True, text=True, timeout=timeout)
        except (OSError, subprocess.TimeoutExpired):
            raise QAError(f"{label}: command unavailable or timed out; no child output exposed.") from None
        if result.returncode:
            raise QAError(f"{label}: command failed (exit {result.returncode}); no child output exposed.")
        return result

    def require_export(self):
        if not (self.root / "frontend" / "out" / "index.html").is_file():
            raise QAError("QA_EXPORT_MISSING: from frontend run npm ci then npm run build (live), before QA up/ui.")

    def require_daemon(self):
        self.invoke(["docker", "version", "--format", "{{.Server.Version}}"],
                    "QA_DAEMON_UNAVAILABLE: start the local Docker daemon separately when authorized", timeout=30)

    def execute(self, action):
        if action not in ("prepare", "config", "up", "status", "api", "identity", "ui", "down"):
            raise QAError("QA_COMMAND_INVALID")
        with self.locked():
            if action == "prepare":
                self.prepare()
                return
            self.validate_config()
            if action == "config":
                self.invoke(self.compose("config", "--quiet"), "QA_CONFIG_FAILED")
                return
            if action in ("up", "ui"):
                self.require_export()
            if action == "ui" and not (self.root / "frontend" / "node_modules" / "playwright").is_dir():
                raise QAError("QA_UI_DEPENDENCIES_MISSING: from frontend run npm ci before QA ui.")
            self.require_daemon()
            if action == "up":
                self.invoke(self.compose("config", "--quiet"), "QA_CONFIG_FAILED")
                self.invoke(self.compose("up", "-d", "--build", "--wait", "--wait-timeout", "240"),
                            "QA_UP_FAILED", timeout=900)
            elif action == "status":
                result = self.invoke(self.compose("ps", "--all", "--format", "json"), "QA_STATUS_FAILED")
                try:
                    raw = result.stdout.strip()
                    records = json.loads(raw) if raw.startswith("[") else [json.loads(line) for line in raw.splitlines()]
                    print(json.dumps([{key: row.get(key, "") for key in ("Service", "State", "Health")} for row in records]))
                except (ValueError, TypeError, AttributeError):
                    raise QAError("QA_STATUS_INVALID: invalid Compose status output.") from None
            elif action == "down":
                self.invoke(self.compose("down"), "QA_DOWN_FAILED")
            elif action in ("api", "identity"):
                script = "verify-api.py" if action == "api" else "verify-identity-trace.py"
                self.invoke([sys.executable, str(self.root / "backend" / "scripts" / script)],
                            "QA_SUITE_FAILED", timeout=900)
            elif action == "ui":
                self.invoke(["node", "scripts/identity-qa.cjs"], "QA_UI_FAILED",
                            cwd=self.root / "frontend", ui=True, timeout=900)
            else:
                raise QAError("QA_COMMAND_INVALID")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=("prepare", "config", "up", "status", "api", "identity", "ui", "down"))
    args = parser.parse_args(argv)
    try:
        Runner().execute(args.command)
    except (QAError, OSError) as error:
        # OSError text can contain paths; never dump child output or config values.
        print(str(error) if isinstance(error, QAError) else "QA_FILESYSTEM_ERROR: check local QA paths and permissions.", file=sys.stderr)
        return 1
    print(f"QA {args.command}: OK (project {PROJECT}; dedicated QA volume retained).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
