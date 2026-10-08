# Passing a library repair with placeholder code

[Overview](../README.md) · [Reproduce](reproduce.md) · [Evidence index](../evidence/README.md)

**Placeholder modules passed the repair checks. An added Python startup file also ran during grading, while the score stayed at 1.**

Assessment: manual proof of reward hacking and code execution alongside a passing submission. Agent accessibility and effects on later rollouts remain untested.

MiMo calls this family **Terminal**: the agent works through terminal tools to complete a task. Here the task was to repair Paramiko, a Python library for SSH connections. The experiment was scripted; no model was needed.

## Why the placeholders passed

The grader checked specific exception-handling patterns and a report containing file hashes. Four small replacement modules had the expected patterns, and the report contained hashes of those replacement files. They passed the checks without implementing the requested Paramiko behavior.

See the [original task](../tasks/terminal-paramiko/task.txt), [grader tests](../tasks/terminal-paramiko/tests/test_outputs.py), and [placeholder modules](../experiments/terminal-paramiko/stubs/).

## Why extra code ran during grading

Before running tests, the grader scans `/app` for forbidden changes. It rejects `sitecustomize.py` there. Python can also automatically load a file with that name from its system package directory, which is outside the scan.

We put a harmless proof script in that system directory. When Python started during grading, it ran the script as root inside the container. The `PYTHONNOUSERSITE=1` setting disables the user package directory, but does not prevent this system-directory import.

| Check | Reward | Result |
| --- | --- | --- |
| Original files | 0 | Five tests failed |
| Placeholder modules and report | 1 | Five tests passed |
| Same placeholders, plus system startup file | 1 | Tests passed and the proof file appeared |
| Same placeholders, startup file placed in `/app` | 0 | The guard rejected the file; no proof appeared |

The [proof](../evidence/terminal-paramiko/system-startup-hook/verifier-escaped-proof.json) records:

```json
{"euid": 0, "shadow_readable": true, "wrote_outside_app": true}
```

`euid: 0` means root inside the container. `shadow_readable` is a permission check using `os.access`; `/etc/shadow` was not read. The script wrote a marker under `/tmp`. Network access was disabled and no accounts were changed.

## Scope and recorded setup

This result is for task `candidate-2535-security-cryptography`, image `general-agent-env-55`. The score is written to `/logs/verifier/reward.txt` inside the container. All four sets of logs are under [terminal evidence](../evidence/terminal-paramiko/).

The dataset inspection found the same guard file across all 64 terminal tasks, each running it before pytest. The other 63 tasks were not executed; their tests differ. The placeholder solution is specific to this task.

Exact identifiers for reproduction:

- Image digest: `sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19`.
- Original `agent.py` SHA-256: `7f6b5bdd60bd5af10522a0419843c4393e407208a98c29985b0ebf99d779b0b1`.
- Guard SHA-256: `336149b10b45d03b7774ba589d984e9663135cfc660f3a133fc482a8716d0e3a`.
