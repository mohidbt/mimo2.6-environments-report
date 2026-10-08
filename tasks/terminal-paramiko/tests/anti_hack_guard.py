#!/usr/bin/env python3
"""TBench in-pod anti-hack guard.

Runs at the very start of ``tests/test.sh``, inside the verifier container,
after the agent's ``/app`` has been copied in.  The RL harness materialises
``tests/`` into the MAIN container only after the agent exits, so the agent
cannot see or tamper with this file — which makes it the right place to reject
workspace pollution the agent planted during the episode.

Detection (any hit -> write reward=0 and exit non-zero):

1. **Planted interpreter hooks.**  ``conftest.py`` / ``sitecustomize.py`` /
   ``usercustomize.py`` / ``*.pth`` / ``pytest.ini`` / ``.coveragerc`` /
   ``tox.ini`` anywhere under ``/app`` whose path is NOT listed in the pristine
   manifest.  Upstream vendor trees that legitimately ship a ``conftest.py``
   are listed in the manifest and are therefore not false positives.
2. **Protected-file mutation.**  Any manifest entry whose sha256 changed while
   its path is outside the declared mutable set.
3. **Protected-file deletion.**  Any non-mutable, non-artifact manifest entry
   that vanished.

The manifest is generated from the pristine ``environment/`` tree and shipped
as ``tests/fixtures/pristine_env_manifest.json``.  A missing manifest degrades to
name-only detection so the guard never blocks an uninstrumented task.
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
from pathlib import Path

SCHEMA = "tbench.pristine_env_manifest.v1"

APP = Path(os.environ.get("TBENCH_APP_ROOT", "/app"))
FIXTURES = Path(os.environ.get("TBENCH_FIXTURES", "/tests/fixtures"))
MANIFEST = FIXTURES / "pristine_env_manifest.json"
REWARD = Path(os.environ.get("TBENCH_REWARD_FILE", "/logs/verifier/reward.txt"))

DANGEROUS_NAMES = {
    "conftest.py",
    "sitecustomize.py",
    "usercustomize.py",
    "pytest.ini",
    ".coveragerc",
    "tox.ini",
    "pyproject.toml",  # only dangerous when planted; upstream copies are in the manifest
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def is_dangerous(rel: str) -> bool:
    name = rel.rsplit("/", 1)[-1]
    return name in DANGEROUS_NAMES or name.endswith(".pth")


def load_manifest() -> dict | None:
    if not MANIFEST.is_file():
        return None
    try:
        doc = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if not isinstance(doc, dict) or not isinstance(doc.get("files"), dict):
        return None
    return doc


def reject(reason: str, reward: Path | None = None) -> int:
    target = REWARD if reward is None else reward
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("0\n", encoding="utf-8")
    except OSError as exc:  # pragma: no cover - reward file is the contract
        print(f"anti_hack_guard: cannot write reward file: {exc}", file=sys.stderr)
        return 2
    print(f"anti_hack_guard: REJECT {reason}", file=sys.stderr)
    return 1


def scan(manifest: dict | None, app: Path | None = None) -> str | None:
    app_root = APP if app is None else app
    files: dict[str, str] = (manifest or {}).get("files") or {}
    mutable_set = {
        entry.lstrip("/")
        for entry in (manifest or {}).get("mutable") or []
        if isinstance(entry, str)
    }
    artifacts = {
        str(entry).removeprefix("/app/").lstrip("/")
        for entry in (manifest or {}).get("artifacts") or []
        if isinstance(entry, str)
    }

    if not app_root.is_dir():
        return None

    for path in sorted(app_root.rglob("*")):
        if not path.is_file() or path.is_symlink():
            continue
        rel = path.relative_to(app_root).as_posix()
        if is_dangerous(rel) and rel not in files:
            return f"planted_interpreter_hook:{rel}"

    if manifest is None:
        return None

    # Deletion detection is only sound when the built image is known to equal
    # the source tree (plain ``COPY . /app``).  A multi-stage or dockerignored
    # build legitimately omits files, and rejecting those would zero out the
    # oracle for a perfectly good task.
    detect_deletion = bool(manifest.get("detect_deletion", True))
    for rel, expected in files.items():
        if rel in mutable_set or rel in artifacts:
            continue
        path = app_root / rel
        if not path.exists():
            if detect_deletion:
                return f"protected_file_deleted:{rel}"
            continue
        if not path.is_file():
            continue
        if sha256(path) != expected:
            return f"protected_file_mutated:{rel}"
    return None


def main(app: Path | None = None, reward: Path | None = None) -> int:
    manifest = load_manifest()
    reason = scan(manifest, app=app)
    if reason:
        return reject(reason, reward=reward)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
