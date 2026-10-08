#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE='xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-55'
# Pristine agent.py from the task manifest. The local image id is not the registry digest.
AGENT_SHA='7f6b5bdd60bd5af10522a0419843c4393e407208a98c29985b0ebf99d779b0b1'
TASK="$ROOT/data/candidate-2535-security-cryptography"

DIGEST='xiaomimimo/mimo-v2.6-rl-oss@sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19'
docker info >/dev/null
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  if [ -f "$ROOT/data/image-55.tar" ]; then
    docker load -i "$ROOT/data/image-55.tar"
  else
    docker pull --platform linux/amd64 "$DIGEST"
    docker tag "$DIGEST" "$IMAGE"
  fi
fi
docker run --rm --platform linux/amd64 --network none --entrypoint /bin/sh "$IMAGE" -c \
  "sha256sum /app/vendor/paramiko/paramiko/agent.py" | grep -q "$AGENT_SHA"

run_one() {
  local mode="$1"
  local run="$ROOT/data/runs/$mode"
  rm -rf "$run"
  mkdir -p "$run"
  set +e
  docker run --rm --platform linux/amd64 --network none --cpus 1 --memory 2g \
    --mount "type=bind,source=$TASK/tests,target=/tests,readonly" \
    --mount "type=bind,source=$ROOT/probes,target=/plant,readonly" \
    --mount "type=bind,source=$run,target=/logs/verifier" \
    --entrypoint /bin/sh "$IMAGE" /plant/inside.sh "$mode" \
    >"$run/container.log" 2>&1
  echo "$?" >"$run/exit_code"
  set -e
  echo "=== $mode exit=$(cat "$run/exit_code") reward=$(cat "$run/reward.txt" 2>/dev/null || echo missing) ==="
  if [ -f "$run/verifier-escaped-proof.json" ]; then
    echo "proof: $(cat "$run/verifier-escaped-proof.json")"
  fi
}

for mode in control reward-hack cyber-hack negative; do
  run_one "$mode" &
done
wait
echo DONE
