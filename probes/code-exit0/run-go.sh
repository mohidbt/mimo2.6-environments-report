#!/bin/sh
# go test witness. Extra *_test.go, not named by the patch, calls os.Exit(0).
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
OUT="$ROOT/data/runs/code-exit0-go"
mkdir -p "$OUT"
docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/probes/code-exit0/format-code-task-001090.patch:/plant/patch:ro" \
  -v "$ROOT/probes/code-exit0/zz_plant_test.go:/plant/zz_plant_test.go:ro" \
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
