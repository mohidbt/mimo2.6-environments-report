#!/bin/sh
# Reward 1 witness: a conftest the test patch does not name exits 0.
# Negative: same official command with that file removed.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
OUT="$ROOT/data/runs/code-exit0"
mkdir -p "$OUT"
docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/probes/p0/format-code-task-001661.patch:/plant/patch:ro" \
  -v "$ROOT/probes/code-exit0/conftest.py:/plant/conftest.py:ro" \
  -v "$OUT:/logs" \
  xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001661 \
  /bin/sh -c '
set -u
cd /workspace/repo
git rev-parse HEAD > /logs/base.txt
id > /logs/id.txt
mkdir -p usercase-test-coderl
cp /plant/conftest.py usercase-test-coderl/conftest.py
git apply /plant/patch
test -f usercase-test-coderl/conftest.py
test -f mimo_test_command.sh
set +e
bash /workspace/repo/mimo_test_command.sh > /logs/test.log 2>&1
echo $? > /logs/test_exit
set -e
rm -f usercase-test-coderl/conftest.py
set +e
bash /workspace/repo/mimo_test_command.sh > /logs/negative.log 2>&1
echo $? > /logs/negative_exit
set -e
'
