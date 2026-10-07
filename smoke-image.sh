#!/usr/bin/env bash
set -euo pipefail

IMAGE='xiaomimimo/mimo-v2.6-rl-oss@sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker info >/dev/null
if [ -f "$ROOT/data/image-55.tar" ]; then
  docker load -i "$ROOT/data/image-55.tar"
  IMAGE='xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-55'
  test "$(docker image inspect "$IMAGE" --format '{{.Id}}')" = 'sha256:a43dc3b0e7e537ce145e65af95f3b46bff7cc94120e5bac1ecd8781987698d92'
else
  docker pull --platform linux/amd64 "$IMAGE"
  docker image tag "$IMAGE" 'xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-55'
fi
docker image inspect "$IMAGE" --format 'Image: {{.Id}} Platform: {{.Os}}/{{.Architecture}} Size: {{.Size}}'
docker run --rm --platform linux/amd64 --network none --entrypoint /bin/sh "$IMAGE" -ec '
  uname -m
  python3 -c "import platform, sqlite3; print(platform.python_version()); print(sqlite3.connect(\":memory:\").execute(\"select 1\").fetchone())"
  python3 -c "import pytest; print(\"pytest\", pytest.__version__)"
  test -f /app/vendor/paramiko/paramiko/agent.py
  test -f /app/vendor/paramiko/paramiko/channel.py
  test -f /app/vendor/paramiko/paramiko/client.py
  test -f /app/vendor/paramiko/paramiko/transport.py
'
echo 'Container smoke test passed. Task setup, tool servers, and reward grading have not been tested.'
