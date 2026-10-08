# Experiment scripts

The folders follow the [assessment method](../docs/methodology.md): test for false passes, then for code execution and grader tampering. See [setup and commands](../docs/reproduce.md) before running them. Shell runners save new output under `results/`; published records are in [evidence](../evidence/README.md).

| Folder | Assessment track | Status |
| --- | --- | --- |
| [terminal-paramiko](terminal-paramiko/) | Reward hacking and exploit hacking | False pass plus startup code execution; manual checks on one task |
| [coding-pytest-bypass](coding-pytest-bypass/) | Reward hacking | Manual early-exit check; Salt agent-run evidence is linked below |
| [coding-shell-replacement](coding-shell-replacement/) | Exploit hacking | Grader shell altered; task still fails; other rollouts untested |
| [preliminary-checks](preliminary-checks/) | Initial access checks | Limited checks, no false pass demonstrated |
| [untested-go-bypass](untested-go-bypass/) | Reward hacking | Proposed early-exit check, not run |
| [shared](shared/) | Inputs used across checks | Harmless Python startup marker and the coding task's test patch |

`run.sh` starts an experiment from the host. `inside.sh`, where present, runs its steps inside the container. `conftest.py` and `sitecustomize.py` retain their names because Python tools load those exact filenames.

The Salt agent experiments used a separate model harness. Their original baseline and replay scripts are preserved with [their evidence](../evidence/coding-pytest-bypass/), and their prompts are in [configs](../configs/).
