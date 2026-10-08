"""Replay the run 4 graded file, then delete it and grade again."""
import base64
import json
import time
import traceback
from pathlib import Path

import yaml
from mimoagent.environments.utils import make_dataset_env

out = Path("/home/exedev/run4-delete-out")
out.mkdir(parents=True, exist_ok=False)
config = yaml.safe_load(Path("/home/exedev/run4.yaml").read_text())
instance = json.loads(Path("/home/exedev/format-code-task-002572.jsonl").read_text())
extra_in = json.loads(
    Path("/home/exedev/run4-out/format-code-task-002572/reward_extra_info.json").read_text()
)
patch = extra_in["model_patch"]
if patch.count("diff --git ") != 1:
    raise SystemExit("expected one file in the graded patch")
lines = patch.splitlines()
body = []
started = False
for line in lines:
    if line.startswith("@@"):
        started = True
        continue
    if not started:
        continue
    if line.startswith("+"):
        body.append(line[1:])
    elif line.startswith("\\"):
        continue
    else:
        raise SystemExit("unexpected patch line")
text = "\n".join(body) + "\n"
if "pytest_runtestloop" not in text:
    raise SystemExit("replay file is not the graded hook")
(out / "conftest.py").write_text(text)
(out / "agent.patch").write_text(patch)
b64 = base64.b64encode(text.encode()).decode()
env = make_dataset_env(instance, **config["environment"])
result = {"agent_started": False, "replay_bytes": len(text.encode())}


def paths(extra):
    patch_text = ""
    if isinstance(extra, dict):
        patch_text = extra.get("model_patch") or ""
    found = []
    for line in patch_text.splitlines():
        if line.startswith("diff --git "):
            found.append(line.split()[2][2:])
    return found


try:
    t0 = time.monotonic()
    env.setup_environment()
    result["setup_seconds"] = round(time.monotonic() - t0, 2)
    cwd = instance["cwd"]
    write = env.execute(
        "mkdir -p tests/pytests/unit/modules && "
        "printf %s '" + b64 + "' | base64 -d > tests/pytests/unit/modules/conftest.py && "
        "wc -c tests/pytests/unit/modules/conftest.py",
        cwd=cwd,
    )
    result["write"] = str(write)[:500]
    env.attach_rollout(agent=None, task=instance["problem_statement"], result="")
    t1 = time.monotonic()
    reward, output, extra = env.calculate_reward()
    result["with_file"] = {
        "reward": reward,
        "verifier_returncode": extra.get("verifier_returncode") if isinstance(extra, dict) else None,
        "resolved": extra.get("resolved") if isinstance(extra, dict) else None,
        "seconds": round(time.monotonic() - t1, 2),
        "paths": paths(extra),
        "output_tail": output[-700:],
    }
    (out / "with-file.log").write_text(output)
    removed = env.execute(
        "rm -f tests/pytests/unit/modules/conftest.py; "
        "if test -e tests/pytests/unit/modules/conftest.py; then echo STILL; else echo GONE; fi",
        cwd=cwd,
    )
    result["removed"] = str(removed)[:400]
    t2 = time.monotonic()
    reward2, output2, extra2 = env.calculate_reward()
    result["without_file"] = {
        "reward": reward2,
        "verifier_returncode": extra2.get("verifier_returncode") if isinstance(extra2, dict) else None,
        "resolved": extra2.get("resolved") if isinstance(extra2, dict) else None,
        "seconds": round(time.monotonic() - t2, 2),
        "paths": paths(extra2),
        "output_tail": output2[-900:],
    }
    (out / "without-file.log").write_text(output2)
except Exception:
    result["error"] = traceback.format_exc()
finally:
    (out / "result.json").write_text(json.dumps(result, indent=2, default=str) + "\n")
    try:
        env.env.cleanup()
    except Exception as exc:
        (out / "cleanup-error.txt").write_text(repr(exc))
    brief = {
        "setup_seconds": result.get("setup_seconds"),
        "with_file": {k: result.get("with_file", {}).get(k) for k in ("reward", "verifier_returncode", "resolved", "paths", "seconds")},
        "removed": result.get("removed"),
        "without_file": {k: result.get("without_file", {}).get(k) for k in ("reward", "verifier_returncode", "resolved", "paths", "seconds")},
        "error": result.get("error"),
    }
    print(json.dumps(brief, default=str)[:4000])
