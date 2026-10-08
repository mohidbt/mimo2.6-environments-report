#!/bin/sh
# Run on the VM. Image must already be local.
set -eu
ROOT=/home/exedev/cyber-hack
OUT=$ROOT/out
mkdir -p "$OUT"
IMAGE=xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001661

docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/patch:/plant/patch:ro" \
  -v "$ROOT/inside.sh:/plant/inside.sh:ro" \
  -v "$OUT:/logs" \
  --entrypoint /bin/sh \
  "$IMAGE" /plant/inside.sh a

docker run --rm --platform linux/amd64 --network none --cpus 2 --memory 4g \
  -v "$ROOT/patch:/plant/patch:ro" \
  -v "$ROOT/inside.sh:/plant/inside.sh:ro" \
  -v "$OUT:/logs" \
  --entrypoint /bin/sh \
  "$IMAGE" /plant/inside.sh b
