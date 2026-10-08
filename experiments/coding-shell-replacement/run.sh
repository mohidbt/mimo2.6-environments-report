#!/bin/sh
# Run from any checkout. The task image must already be local.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
mkdir -p "$ROOT/results"
OUT="$(mktemp -d "$ROOT/results/coding-shell-replacement-XXXXXX")"
IMAGE=xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001661

docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/experiments/shared/format-code-task-001661.patch:/plant/patch:ro" \
  -v "$ROOT/experiments/coding-shell-replacement/inside.sh:/plant/inside.sh:ro" \
  -v "$OUT:/logs" \
  --entrypoint /bin/sh \
  "$IMAGE" /plant/inside.sh a

docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/experiments/shared/format-code-task-001661.patch:/plant/patch:ro" \
  -v "$ROOT/experiments/coding-shell-replacement/inside.sh:/plant/inside.sh:ro" \
  -v "$OUT:/logs" \
  --entrypoint /bin/sh \
  "$IMAGE" /plant/inside.sh b

echo "Results: $OUT"
