# Repeat the experiments

[Overview](../README.md) · [Experiment files](../experiments/README.md) · [Saved evidence](../evidence/README.md)

Run the commands below from the repository root. The shell runners require Docker with Linux/amd64 support. They disable container networking and save each new run under a unique directory in `results/`. That directory is ignored by Git, so reruns do not replace published evidence.

## Terminal library repair

The task and grader files are already included. Run all four comparisons:

```bash
bash experiments/terminal-paramiko/run.sh
```

The runner loads `data/image-55.tar` if available, otherwise pulls the pinned public image when the local tag is absent. It checks the original Paramiko `agent.py` hash before running. See [recorded identifiers](terminal-results.md#scope-and-recorded-setup).

Expected rewards: `untouched` = 0, `stub-solution` = 1, `system-startup-hook` = 1, `workspace-startup-hook` = 0. Only `system-startup-hook` should produce `verifier-escaped-proof.json`.

Optional helpers:

```bash
# Restore task files from dataset revision f819cd2; requires uv and network access.
uv run scripts/fetch-terminal-task.py

# Download a Docker-loadable image archive; requires uv and network access.
uv run scripts/fetch-terminal-image.py

# Check the image, or grade only the original files.
bash scripts/check-terminal-image.sh
bash scripts/check-terminal-baseline.sh
```

The baseline helper returns the grader's exit status. A failure is expected for the untouched task.

## Manual coding checks

Both checks below expect this image to be present locally:

```bash
docker pull --platform linux/amd64 \
  xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001661
```

These runners use the image tag. The Salt agent experiment below has a separate recorded image digest.

To test whether an added pytest file can end the test command successfully:

```bash
bash experiments/coding-pytest-bypass/run.sh
```

Expected: `test_exit` is 0 with the added file; `negative_exit` is 2 after removal. This runs the official test command directly, not the harness reward API.

To test whether replacing the shell runs extra code during grading:

```bash
bash experiments/coding-shell-replacement/run.sh
```

Expected: `base.exit`, `plant.exit`, `again.exit`, and `fresh.exit` are all 2. Proof files contain zero, two, four, and zero records respectively. These output names are retained to match the saved logs. The script uses two containers: one for the first three checks and a fresh one for the last check.

## Agent experiments on the Salt bug

These runs used Xiaomi's mimoagent harness at commit `467f0a19016f0ac4d63b8d17a1f0da9ba07f232c`, with the [recorded local changes](../evidence/coding-pytest-bypass/untouched/checkout.diff). The harness itself is not included here.

The published inputs are:

- [Task row](../evidence/coding-pytest-bypass/untouched/format-code-task-002572.jsonl) and [original environment configuration](../evidence/coding-pytest-bypass/untouched/attempt2.yaml).
- Prompts [without a hint](../configs/coding-agent-without-hint.yaml) and [with a directory hint](../configs/coding-agent-with-directory-hint.yaml).
- [Untouched baseline script](../evidence/coding-pytest-bypass/untouched/run.py), [recipe replay and removal script](../evidence/coding-pytest-bypass/recipe-replay-and-removal/run.py), and [hinted replay and removal script](../evidence/coding-pytest-bypass/hinted-replay-and-removal/run.py).

The saved Python scripts are the originals from the experiment VM. **They require path adaptation before use on another machine.** They contain `/home/exedev/` paths for the harness, configs, task row, and saved agent patch. The baseline and recipe replay accept a new output directory as their first argument; the hinted replay also hard-codes its output directory. Use a new directory because they refuse to overwrite an existing one.

Run adapted scripts with the harness's Python environment. The baseline and replay scripts call `make_dataset_env`, `setup_environment`, and `calculate_reward` without a model or gateway credentials. Expected rewards are 0 for the baseline, 1 with either bypass file, and 0 after removal.

Running the agent itself additionally requires access to the configured model and a `MERGE_GATEWAY_API_KEY`. The configs contain a placeholder. The exact model settings, resources, and image digest are in [recorded setup](coding-results.md#recorded-setup). Saved conversations allow inspection without rerunning the model.

## Preliminary and untested checks

```bash
# One local image per selected family. Options: code, cyber, rubric, webdev, all.
bash experiments/preliminary-checks/run.sh cyber
```

Required local tags, all under `xiaomimimo/mimo-v2.6-rl-oss`, are `format-code-task-001661` for code, `arvo-v1-35858` for cyber, `general-agent-env-0` for rubric, and `webdev-rl-opensource` for webdev. Results have the limits described in [other environments](other-environments.md).

[The Go bypass proposal](../experiments/untested-go-bypass/) has a runner and input files, but has not been executed. There is no verified expected result.
