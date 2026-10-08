#!/bin/sh
# Manual check: an added pytest startup file exits successfully before tests run.
# Negative: same official command with that file removed.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
mkdir -p "$ROOT/results"
OUT="$(mktemp -d "$ROOT/results/coding-pytest-bypass-XXXXXX")"
docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/experiments/shared/format-code-task-001661.patch:/plant/patch:ro" \
  -v "$ROOT/experiments/coding-pytest-bypass/conftest.py:/plant/conftest.py:ro" \
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

echo "Results: $OUT"
