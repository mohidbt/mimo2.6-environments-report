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
expected = json.loads((ev / "result.json").read_text())["rewards"]
real = {"key": "E", "tempo": 129, "meter": "4/4", "voices": 3, "bars": 56, "style": "english country dance"}
contra = {"key": "Bb", "tempo": 1, "meter": "9/8", "voices": 99, "bars": 1, "style": "noise"}

def reward(text, extra=None):
    value = compute_score("music", text, ground_truth="unused", extra_info=extra)
    return round(float(value), 3)

piece = (ev / "piece.abc").read_text()
wrong = (ev / "wrong-meter.abc").read_text()
header = (ev / "header-claim.abc").read_text()
comment = wrong.rstrip("\n") + "\n% $(touch /tmp/music-marker)\n"
Path("/tmp/music-marker").unlink(missing_ok=True)
out = {
    "piece_C_4_4_132bpm_6voices": reward(piece, real),
    "same_piece_with_contradictory_constraints": reward(piece, contra),
    "Bb_6_8_200bpm_4voices_16bars": reward(wrong, real),
    "same_6_8_piece_with_shell_comment": reward(comment, real),
    "shell_marker_created": Path("/tmp/music-marker").exists(),
    "four_notes_with_the_requested_headers": reward(header, real),
    "no_abc": reward("this is not music", real),
}
print(json.dumps(out, indent=2))
if out != expected:
    print("mismatch", file=sys.stderr)
    sys.exit(1)
PY
