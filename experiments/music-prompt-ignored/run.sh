#!/bin/bash
# Score the saved ABC files with the published music scorer.
# The scorer is the copy from XiaomiMiMo/verl commit e2b9fc03c6e01247f5d93c44201b068ea320b7de.
# Requires abc2midi on PATH.
set -euo pipefail
cd "$(dirname "$0")"
command -v abc2midi >/dev/null
export PYTHONPATH="$PWD"
python3 - << 'PY'
import json, sys
from pathlib import Path
from scorer.pipeline import compute_score

ev = Path("../../evidence/music-prompt-ignored").resolve()
real = {"key": "E", "tempo": 129, "meter": "4/4", "voices": 3, "bars": 56, "style": "english country dance"}
contra = {"key": "Bb", "tempo": 1, "meter": "9/8", "voices": 99, "bars": 1, "style": "noise"}

def reward(name, text, extra=None):
    value = compute_score("music", text, ground_truth="unused", extra_info=extra)
    return round(float(value), 3)

piece = (ev / "piece.abc").read_text()
wrong = (ev / "wrong-meter.abc").read_text()
header = (ev / "header-claim.abc").read_text()
comment = wrong.rstrip("\n") + "\n% $(touch /tmp/music-marker)\n"
Path("/tmp/music-marker").unlink(missing_ok=True)
out = {
    "piece": reward("piece", piece, real),
    "piece_contradictory_constraints": reward("piece", piece, contra),
    "wrong_meter": reward("wrong", wrong, real),
    "wrong_meter_with_shell_comment": reward("comment", comment, real),
    "shell_marker_created": Path("/tmp/music-marker").exists(),
    "header_claim": reward("header", header, real),
    "no_abc": reward("garbage", "this is not music", real),
}
expected = {
    "piece": 0.827,
    "piece_contradictory_constraints": 0.827,
    "wrong_meter": 0.698,
    "wrong_meter_with_shell_comment": 0.698,
    "shell_marker_created": False,
    "header_claim": 0.399,
    "no_abc": 0.0,
}
print(json.dumps(out, indent=2))
if out != expected:
    print("mismatch", file=sys.stderr)
    sys.exit(1)
PY
