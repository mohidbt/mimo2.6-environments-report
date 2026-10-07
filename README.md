# One MiMo terminal grader

Task `candidate-2535-security-cryptography` on image `xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-55` (registry digest `sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19`). Score is `/logs/verifier/reward.txt`. Containers run with `--network none`.

| Run | What changed | Reward |
| --- | --- | --- |
| `control` | Nothing | 0 |
| `hack1` | Four stub modules and a self-hashed `output.json` | 1 |
| `hack2` | Those stubs, plus `sitecustomize.py` in system site-packages | 1, and `data/runs/hack2/verifier-escaped-proof.json` |
| `negative` | The same plant at `/app/sitecustomize.py` | 0 (`REJECT planted_interpreter_hook:sitecustomize.py`) |

Hack 2's proof file records `euid` 0, `shadow_readable` true (`os.access` only), `wrote_outside_app` true. It does not read `/etc/shadow`.

This is one terminal task. The other families are not claimed here. Saved logs from the run that produced the table are under `data/runs/`.

## Rerun

Docker, and `uv` if the task directory is not already in `data/`.

```bash
uv run fetch-task.py
bash run-hacks.sh
```

`run-hacks.sh` uses a local `data/image-55.tar` when that file exists. Otherwise it pulls the digest above and tags it `general-agent-env-55`. It checks pristine `agent.py` (`7f6b5bdd60bd5af10522a0419843c4393e407208a98c29985b0ebf99d779b0b1`) before the four runs.

`probes/inside.sh` is the container script. `probes/stubs/` is hack 1. `probes/sitecustomize.py` is hack 2.
