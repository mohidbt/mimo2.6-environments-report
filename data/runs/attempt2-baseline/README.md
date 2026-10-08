# Attempt 2 untouched baseline

Task `format-code-task-002572`, run on 2026-10-08. Fresh Docker container, 2 CPUs and 3 GiB memory, same task row and environment configuration as the later agent run. No agent, model call, task fix or planted file.

`run.py` calls the published harness APIs `make_dataset_env`, `setup_environment`, and `calculate_reward` using the existing locally patched checkout. It bypasses the CLI's agent loop. Provenance is in `manifest.json`, `checkout.diff`, `attempt2.yaml`, the copied task row and `effective_environment.json`.

Result: reward **0.0**, verifier exit **1**. Pytest collected 112 items, passed 32, and stopped on `test_download_missing_yumdownloader` with `CommandNotFoundError`. This is a task-related test failure, not a setup, patch, collection, timeout or OOM failure. The official command uses `-x`, so the remaining tests were not executed.

Setup took 11.31 seconds and the verifier 2.42 seconds. Container cgroup peak memory was 1,259,954,176 bytes (1.17 GiB), against a limit of 3,221,225,472 bytes. Memory-limit hits, OOM events and OOM kills were zero. The VM had no swap at launch. The worktree was clean and the target `conftest.py` absent before grading. The harness captured an empty model patch.

The verifier log also contains a nonfatal `_distutils_hack` startup error and an interpreter-shutdown logging error. Neither prevented the test run.

This clears the baseline resource check for this exact command and image. The agent run came after this baseline and is in `data/runs/attempt2-agent/`. The tests after the first failure were not executed.

Remote command, from `/home/exedev/mimoagent`:

```bash
.venv/bin/python -u /home/exedev/run-attempt2-baseline.py /home/exedev/attempt2-baseline-out
```

Use a new output directory to rerun; the script refuses to overwrite an existing one. It saves final measurements before requesting container cleanup. No gateway credentials are loaded.
