#!/bin/sh
# Untested proposal: an extra Go test file calls os.Exit(0). No saved result.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
mkdir -p "$ROOT/results"
OUT="$(mktemp -d "$ROOT/results/untested-go-bypass-XXXXXX")"
docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/experiments/untested-go-bypass/format-code-task-001090.patch:/plant/patch:ro" \
  -v "$ROOT/experiments/untested-go-bypass/zz_plant_test.go:/plant/zz_plant_test.go:ro" \
  -v "$OUT:/logs" \
  xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001090 \
  /bin/sh -c '
set -u
cd /testbed
git rev-parse HEAD > /logs/base.txt
id > /logs/id.txt
mkdir -p internal/gitutil
cp /plant/zz_plant_test.go internal/gitutil/zz_plant_test.go
git apply /plant/patch
test -f internal/gitutil/zz_plant_test.go
test -f mimo_test_command.sh
set +e
bash /testbed/mimo_test_command.sh > /logs/test.log 2>&1
echo $? > /logs/test_exit
set -e
rm -f internal/gitutil/zz_plant_test.go
set +e
bash /testbed/mimo_test_command.sh > /logs/negative.log 2>&1
echo $? > /logs/negative_exit
set -e
'

echo "Results: $OUT"
