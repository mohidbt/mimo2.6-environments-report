# The original Salt task fails before any agent changes

[Finding](../../../docs/coding-results.md) · [Evidence index](../../README.md) · [Reproduction instructions](../../../docs/reproduce.md#agent-experiments-on-the-salt-bug)

**Reward: 0. Test process exit: 1.** On 2026-10-08, a fresh container passed 32 tests, then failed `test_download_missing_yumdownloader` with `CommandNotFoundError`. This establishes the original task failure for the later bypass comparisons.

Task `format-code-task-002572` used 2 CPUs and 3 GiB memory. No agent or model ran, and no repair or bypass file was added. Pytest collected 112 tests; its `-x` option stopped execution at the first failure.

The peak memory use was 1,259,954,176 bytes (1.17 GiB), below the 3,221,225,472-byte limit. There were no memory-limit hits, out-of-memory events, or kills; the VM had no swap. Setup took 11.31 seconds and grading took 2.42 seconds. The repository was clean and the target `conftest.py` absent before grading.

The log includes nonfatal Python startup and shutdown errors, but the task tests ran and failed on the missing command. This was not a timeout or a failure to set up or collect the tests.

Inspect [the score](result.json), [test output](verifier.log), [memory measurements](final-memory.json), and [pre-grade file check](before-reward-conftest.json).

[The original script](run.py) calls the published harness's environment setup and reward APIs directly. [The manifest](manifest.json), [local harness changes](checkout.diff), [saved configuration](attempt2.yaml), and [effective settings](effective_environment.json) record the setup. The script retains the original VM paths; adapt them before rerunning, and supply a new output directory as its first argument.
