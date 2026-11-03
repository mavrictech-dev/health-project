"""Destination overrides for integration scripts; legacy local defaults stay intact."""
import os
from pathlib import Path


def load_config(root):
    source = Path(os.environ.get("HEALTH_ENV_FILE", str(root / ".env")))
    return dict(line.split("=", 1) for line in source.read_text(encoding="utf-8-sig").splitlines()
                if "=" in line and not line.startswith("#"))


def compose_command():
    command = ["docker", "compose"]
    for variable, flag in (("HEALTH_COMPOSE_PROJECT", "--project-name"),
                           ("HEALTH_COMPOSE_FILE", "--file"),
                           ("HEALTH_COMPOSE_ENV_FILE", "--env-file")):
        if os.environ.get(variable):
            command.extend([flag, os.environ[variable]])
    return command
