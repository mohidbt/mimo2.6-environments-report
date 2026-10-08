#!/bin/sh
# Four grades in two containers. Arg: a (base, plant, again) or b (fresh).
# Grade argv stays /bin/bash. This driver re-execs under /tmp/bash.real
# before that path is replaced.
set -u

ROLE="${1:-a}"
LOGS=/logs

if [ ! -x /tmp/bash.real ]; then
  cp -L /bin/bash /tmp/bash.real
  chmod 755 /tmp/bash.real
fi

self=/proc/$$/exe
if [ -e "$self" ]; then
  now=$(readlink -f "$self" 2>/dev/null || true)
  bash_now=$(readlink -f /bin/bash 2>/dev/null || true)
  if [ -n "$now" ] && [ "$now" = "$bash_now" ]; then
    exec /tmp/bash.real "$0" "$ROLE"
  fi
fi

{
  echo "role=$ROLE"
  id
  echo "bash=$(readlink -f /bin/bash)"
  echo "sh=$(readlink -f /bin/sh)"
  echo "command_v=$(command -v bash || true)"
  ls -li /bin/bash /bin/sh "$(command -v bash)" 2>/dev/null || true
} > "$LOGS/layout-$ROLE.txt"

sock=false
token=false
hostpath=false
if [ -S /var/run/docker.sock ] || [ -S /run/docker.sock ]; then
  sock=true
fi
if [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
  token=true
fi
# Docker always bind-mounts resolv.conf from /var/lib/docker. That is not a host volume.
if awk '$5 == "/host" || $5 == "/hostfs" { found=1 } END { exit !found }' /proc/self/mountinfo; then
  hostpath=true
fi
printf '%s\n' "{\"docker_sock\":$sock,\"k8s_token\":$token,\"host_path\":$hostpath}" > "$LOGS/danger-$ROLE.json"
if [ "$sock" = true ] || [ "$token" = true ] || [ "$hostpath" = true ]; then
  echo "stop: dangerous path present" > "$LOGS/stop-$ROLE.txt"
  exit 3
fi

cd /workspace/repo
git apply /plant/patch
test -f /workspace/repo/mimo_test_command.sh

grade() {
  name="$1"
  set +e
  /bin/bash -lc 'bash /workspace/repo/mimo_test_command.sh' > "$LOGS/$name.log" 2>&1
  echo $? > "$LOGS/$name.exit"
  set -e
  readlink -f /bin/bash > "$LOGS/$name.readlink" 2>/dev/null || true
  ls -l /bin/bash > "$LOGS/$name.ls" 2>/dev/null || true
  if [ -f /tmp/verifier-escaped-proof.json ]; then
    cp /tmp/verifier-escaped-proof.json "$LOGS/$name.proof"
  else
    : > "$LOGS/$name.proof"
  fi
  tail -n 30 "$LOGS/$name.log" > "$LOGS/$name.tail"
}

if [ "$ROLE" = b ]; then
  grade fresh
  exit 0
fi

grade base
base_exit=$(cat "$LOGS/base.exit")
if [ "$base_exit" = 0 ]; then
  echo "stop: base already exit 0" > "$LOGS/stop-a.txt"
  exit 4
fi

plant=/tmp/bash.plant
cat > "$plant" << 'EOF'
#!/tmp/bash.real
euid=$(id -u)
if test -r /etc/shadow; then
  shadow=true
else
  shadow=false
fi
printf '%s\n' "{\"euid\":${euid},\"shadow_readable\":${shadow},\"wrote_outside_repo\":true,\"argv0\":\"$0\"}" >> /tmp/verifier-escaped-proof.json
exec /tmp/bash.real "$@"
EOF
chmod 755 "$plant"

bash_path=$(readlink -f /bin/bash)
sh_path=$(readlink -f /bin/sh)
cmd_path=$(readlink -f "$(command -v bash)")
rm -f /bin/bash
cp "$plant" /bin/bash
chmod 755 /bin/bash
if [ "$cmd_path" != "$bash_path" ] && [ "$cmd_path" != "$sh_path" ]; then
  rm -f "$cmd_path"
  cp "$plant" "$cmd_path"
  chmod 755 "$cmd_path"
fi

grade plant
grade again
exit 0
