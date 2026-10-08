"""Replay the agent file, then delete it and grade again."""
import json, sys, time, traceback
from pathlib import Path
import yaml
from mimoagent.environments.utils import make_dataset_env

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=False)
config = yaml.safe_load(Path("/home/exedev/attempt2.yaml").read_text())
instance = json.loads(Path("/home/exedev/format-code-task-002572.jsonl").read_text())
env = make_dataset_env(instance, **config["environment"])
plant = "import pytest\n\n\ndef pytest_configure(config):\n    pytest.exit(\"plant\", returncode=0)\n"
result = {"agent_started": False}
try:
    t0 = time.monotonic()
    env.setup_environment()
    result["setup_seconds"] = time.monotonic() - t0
    cwd = instance["cwd"]
    env.execute("mkdir -p tests/pytests/unit/modules", cwd=cwd)
    # The agent patch, replayed. Not a new plant.
    write = env.execute("cat > tests/pytests/unit/modules/conftest.py << 'EOF'\n" + plant + "EOF", cwd=cwd)
    result["write"] = {"rc": write.returncode if hasattr(write, "returncode") else write.get("returncode"), "out": str(write)[:500]}
    env.attach_rollout(agent=None, task=instance["problem_statement"], result="")
    t1 = time.monotonic()
    reward, output, extra = env.calculate_reward()
    result["with_file"] = {"reward": reward, "extra": extra, "seconds": time.monotonic() - t1, "output_tail": output[-800:]}
    (out / "with-file.log").write_text(output)
    removed = env.execute("rm -f tests/pytests/unit/modules/conftest.py; if test -e tests/pytests/unit/modules/conftest.py; then echo STILL; else echo GONE; fi", cwd=cwd)
    result["removed"] = str(removed)[:400]
    t2 = time.monotonic()
    reward2, output2, extra2 = env.calculate_reward()
    result["without_file"] = {"reward": reward2, "extra": extra2, "seconds": time.monotonic() - t2, "output_tail": output2[-800:]}
    (out / "without-file.log").write_text(output2)
except Exception as exc:
    result["error"] = traceback.format_exc()
finally:
    (out / "result.json").write_text(json.dumps(result, indent=2, default=str) + "\n")
    try:
        env.env.cleanup()
    except Exception as exc:
        (out / "cleanup-error.txt").write_text(repr(exc))
    print(json.dumps({k: result.get(k) for k in ("with_file", "without_file", "removed", "error")}, default=str)[:4000])
