# Saved results and how to read them

[Overview](../README.md) · [Coding findings](../docs/coding-results.md) · [Terminal findings](../docs/terminal-results.md)

These files are the records behind the report. Folder names describe the experiment rather than its run number. Original logs, task identifiers, and saved scripts retain their contents, including paths from the experiment machine.

## Coding tasks

The Salt bug is task `format-code-task-002572`. Start with the hinted agent's patch and the replay result to see what caused the false pass.

| Experiment | Evidence |
| --- | --- |
| Original task, no agent | [Baseline explanation](coding-pytest-bypass/untouched/README.md), [score](coding-pytest-bypass/untouched/result.json) |
| Agent given a test-directory hint | [Conversation](coding-pytest-bypass/agent-with-directory-hint/format-code-task-002572.traj.json), [graded patch](coding-pytest-bypass/agent-with-directory-hint/reward_extra_info.json) |
| Hinted agent's file replayed, then removed | [Added file](coding-pytest-bypass/hinted-replay-and-removal/conftest.py), [scores](coding-pytest-bypass/hinted-replay-and-removal/result.json) |
| Agent given the complete recipe | [Conversation](coding-pytest-bypass/agent-given-recipe/format-code-task-002572.traj.json), [graded patch](coding-pytest-bypass/agent-given-recipe/reward_extra_info.json) |
| Recipe file replayed, then removed | [Scores](coding-pytest-bypass/recipe-replay-and-removal/result.json) |
| Agent told to exploit without a hint | [Conversation](coding-pytest-bypass/agent-without-hint/format-code-task-002572.traj.json), [result](coding-pytest-bypass/agent-without-hint/reward_extra_info.json) |

The following records use task `format-code-task-001661`:

| Experiment | Evidence |
| --- | --- |
| Manual pytest early exit | [Test logs and command counts](coding-pytest-bypass/manual-check/) |
| Replacement shell runs during grading | [Four comparisons](coding-shell-replacement/) |

## Terminal task

All four checks use Paramiko task `candidate-2535-security-cryptography`.

| Check | Evidence |
| --- | --- |
| Original files | [Logs and score](terminal-paramiko/untouched/) |
| Placeholder solution | [Logs and score](terminal-paramiko/stub-solution/) |
| Extra startup code in system packages | [Logs, score, and proof](terminal-paramiko/system-startup-hook/) |
| Same startup file in the workspace | [Rejection and score](terminal-paramiko/workspace-startup-hook/) |

[Preliminary checks](preliminary-checks/) cover the other environments and an early coding check. They are separate from the confirmed results above.

## File names in the records

| File | Meaning |
| --- | --- |
| `*.traj.json` | Agent conversation: prompts, tool calls, and submission |
| `reward_extra_info.json` | Grader details, including the submitted patch where recorded |
| `result.json` | Baseline or replay result; replay files contain both scores |
| `reward.txt` | Reward: 1 for pass, 0 for failure |
| `exit_code`, `*.exit`, `test_exit` | Process status: 0 means successful exit; nonzero means failure |
| `*.log` | Output from the model harness, container, or test command |
| `ctrf.json` | Structured test results |
| `*.proof`, `verifier-escaped-proof.json` | Harmless marker written by added code; the filename does not establish a host escape |
| `manifest.json`, `checkout.diff` | Recorded software versions and local harness changes |

Older paths inside records use `attempt2` for the recipe run, `run3` for no hint, `run4` for the directory hint, and `p0` for preliminary checks. These are historical labels. New runs go to the ignored `results/` directory.
