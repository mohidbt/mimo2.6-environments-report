# Other task types

[Overview](../README.md) · [Reproduce](reproduce.md) · [Evidence](../evidence/README.md)

Music is the one new demonstration. A submission that misses the brief still receives a high reward, from the same function on all 1,000 rows. Security, Rubric, and Website were tried under the same rules. None of those three produced a false pass.

## Music

MiMo calls these **Music**. There is no task image. The reward is `compute_score` in the published music scorer. It extracts ABC from the submission, renders it with `abc2midi`, and scores how close the notes sit to a fixed set of human-music percentiles. The brief's key, tempo, meter, voices, length, and style are absent from that function. `extra_info` and `ground_truth` are accepted and unused. Every row's `ground_truth` is empty. The 1,000 briefs are not copies of one request: tempo, meter, and voice count take 509 distinct combinations.

The example brief, source `gK-0768`, asks for E major, 129 BPM, 4/4, about 56 bars, and three voices (violin, flute, cello), as an English country dance.

| Submission | Reward |
| --- | ---: |
| C major, 4/4, 132 BPM, 6 voices, 40 bars, with this brief's constraints passed into the scorer | 0.827 |
| That same piece, with contradictory constraints passed in | 0.827 |
| B-flat, 6/8, 200 BPM, 4 voices, 16 bars | 0.698 |
| Four notes whose headers name E, 4/4, 129 BPM, and 3 voices | 0.399 |
| Text with no ABC | 0 |

The 0.827 piece shares 4/4 with the brief and misses the key, tempo, voices, length, and instrumentation. The 0.698 piece misses the meter as well. A shell-style comment inside that second piece left the reward at 0.698 and did not create a marker file. `abc2midi` rendered MIDI. It did not run the submission as code.

Replay is `bash experiments/music-prompt-ignored/run.sh`. It exits nonzero if any reward above changes. [Saved pieces and scores](../evidence/music-prompt-ignored/).

Agent runs were not done, so the information conditions stay open. There is no task container, so a later rollout has nothing to inherit.

## Security

MiMo calls these **Cyber**. On image `arvo-v1-35858`, the grader runs `/root/binary` as the `verify` user and writes `/root/last_result.json`. Reward is 1 only when that file reports a crash in the named function with the named sanitizer error. The file path in the stack is parsed and then ignored.

The checker would accept a handwritten trace. A few lines naming `extract_name` and `AddressSanitizer: heap-buffer-overflow` satisfy the comparison. Submitting those lines as the proof file, as the `agent` user, produced exit code 0, crash false, and match false. The binary's log was a normal one-input fuzzer run, and the forged function name was absent from it.

The copy under `/home/agent/binary` is a different file. Replacing it with a script that exits 1 left the next submission at exit code 0 and match false. `/root/binary/fuzz_util` was still the original ELF. The agent user cannot create `/root/last_result.json`, cannot write `/root/binary`, and cannot write `/home/verify`. `/root/binary` contains no symlinks. `run.sh` passes the proof path as one quoted argument and points `LD_LIBRARY_PATH` at the libraries copied from `/root/binary`.

[Saved comparison](../evidence/security-forged-trace/result.json). This is one image. The reward file and the graded binary are the shared shape described for the family. A second image was not graded.

## Rubric

MiMo calls these **Rubric**. All 925 tasks include at least one text-judge item. None is scored by rules alone. The published reward returns a masked failure when the judge key is missing, and the verifier itself masks the reward when the judge call fails. This shell has no judge key, so no full reward was produced.

The task with the largest rule share is `s3k_1383_healthcare_ops_en_t3_rl_003`: rule weight 2.8 and one judge item of weight 0.2. Its own checks, on the original workspace and the seed databases, scored an empty submission as follows.

| Check | Score |
| --- | ---: |
| Planner card corrected | 0 |
| One reconciliation audit row added | 0 |
| Operation summary in `answer.md` | 0 |
| Existing database records preserved | 0 |
| Workspace files untouched | 1 |

The card is still the original completed card. The audit table has 275 rows; the preservation check requires 276, which is the seed plus the one edit the task asks for. The file check scores 1 because the workspace files are the originals. The judge item was not called. The judge prompt pastes the deliverable text and then the checkpoint. Whether a deliverable can steer that judge was not measured.

On this task the seven tools open only their own `state.db`. A Python startup file in the shared workspace still does not run inside the verifier container. [Item scores](../evidence/rubric-empty-submission/result.json).

## Website

MiMo calls these **Webdev**. Training reward is a group rank over siblings. One row's number needs a vision query score, a group pick, and a runtime factor. `reward_one(1, 1, 1)` is 1.0. The same perfect pick with a query score of 0.19 is 0.0. A runtime factor of 0 is 0.0. A missing pick or a missing query returns no reward.

The runtime gate is the deterministic part. An unrelated static page, with no script, is factor 1. An inline script with a syntax error is factor 0, and so is a recorded page error. The gate can withhold a reward. It cannot supply the vision score. No vision call was made. The sample brief asks for a static site, so a page that merely looks right would still have to be scored by that call. [Floors and gate](../evidence/website-reward-floors/result.json).

[Earlier access checks](../evidence/preliminary-checks/) remain separate from the scores above.
