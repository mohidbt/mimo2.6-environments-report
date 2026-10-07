#!/bin/sh
set -eu
mkdir -p /logs/verifier
set +e
# tbench-anti-hack-guard:v1
export PYTHONNOUSERSITE=1
export PYTHONDONTWRITEBYTECODE=1
# Fail open when the verifier image has no python3 (node-only tests images are
# excluded from the RL set but still verifiable natively): a missing
# interpreter must not swallow the grader's own reward write.
if command -v python3 >/dev/null 2>&1 && [ -f /tests/anti_hack_guard.py ]; then
  if ! python3 /tests/anti_hack_guard.py; then
    # Guard already wrote reward=0; the reward file is the grading contract.
    exit 0
  fi
fi


python3 -m pytest --ctrf /logs/verifier/ctrf.json -q /tests/test_outputs.py
code=$?
set -e
if [ "$code" -eq 0 ]; then printf '1\n' > /logs/verifier/reward.txt; else printf '0\n' > /logs/verifier/reward.txt; fi
exit "$code"
