#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$ROOT/scripts/check-terminal-image.sh"
TASK="$ROOT/tasks/terminal-paramiko"
test -f "$TASK/tests/test.sh"
mkdir -p "$ROOT/results"
RUN_DIR="$(mktemp -d "$ROOT/results/terminal-baseline-XXXXXX")"
set +e
docker run --rm --platform linux/amd64 --network none --cpus 1 --memory 2g \
  --mount "type=bind,source=$TASK/tests,target=/tests,readonly" \
  --mount "type=bind,source=$RUN_DIR,target=/logs/verifier" \
  --entrypoint /bin/sh xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-55 \
  -c 'sh /tests/test.sh'
RESULT=$?
set -e
echo "Verifier exit code: $RESULT"
echo "Verifier logs: $RUN_DIR"
if [ -f "$RUN_DIR/reward.txt" ]; then
  echo "Reward: $(cat "$RUN_DIR/reward.txt")"
else
  echo 'Verifier did not produce a reward.' >&2
  exit 1
fi
echo 'The untouched task is expected to score 0. A successful agent repair should score 1.'
exit "$RESULT"
