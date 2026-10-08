#!/bin/sh
# One image per family. Offline. Harmless proof only.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
PLANT="$ROOT/experiments/shared"
mkdir -p "$ROOT/results"
OUT="$(mktemp -d "$ROOT/results/preliminary-checks-XXXXXX")"
mkdir -p "$OUT/code" "$OUT/cyber" "$OUT/rubric" "$OUT/webdev"

common() {
  # $1 image $2 name $3 memory $4 script
  docker run --rm --platform linux/amd64 --network none --cpus 2 --memory "$3" \
    -v "$PLANT/sitecustomize.py:/plant/sitecustomize.py:ro" \
    -v "$PLANT/format-code-task-001661.patch:/plant/task.patch:ro" \
    -v "$OUT/$2:/logs" \
    "$1" /bin/sh -c "$4"
}

WANT="${1:-all}"

want() { [ "$WANT" = all ] || [ "$WANT" = "$1" ]; }

if want code; then
echo "code"
common xiaomimimo/mimo-v2.6-rl-oss:format-code-task-001661 code 4g '
set -u
cd /workspace/repo
git rev-parse HEAD > /logs/base.txt
PY=$(command -v python || command -v python3)
SITE=$($PY -c "import site; print(site.getsitepackages()[0])")
printf "%s\n" "$SITE" > /logs/site-packages.path
cp /plant/sitecustomize.py "$SITE/sitecustomize.py"
rm -f /tmp/verifier-escaped-proof.json
git apply /plant/task.patch
set +e
bash /workspace/repo/mimo_test_command.sh > /logs/test.log 2>&1
echo $? > /logs/test_exit
set -e
if [ -f /tmp/verifier-escaped-proof.json ]; then cp /tmp/verifier-escaped-proof.json /logs/verifier-escaped-proof.json; fi
rm -f "$SITE/sitecustomize.py" /tmp/verifier-escaped-proof.json
set +e
bash /workspace/repo/mimo_test_command.sh > /logs/negative.log 2>&1
echo $? > /logs/negative_exit
set -e
if [ -f /tmp/verifier-escaped-proof.json ]; then echo PRESENT > /logs/negative-proof; else echo ABSENT > /logs/negative-proof; fi
id > /logs/id.txt
'

fi

if want cyber; then
echo "cyber"
common xiaomimimo/mimo-v2.6-rl-oss:arvo-v1-35858 cyber 2g '
set -u
id > /logs/id.txt
getent passwd > /logs/passwd.txt || true
{
  echo "submit"; ls -l /home/agent/submit.sh 2>&1
  echo "agent binary"; ls -ld /home/agent/binary /home/agent/binary/run.sh 2>&1
  echo "root binary"; ls -ld /root /root/binary /root/binary/run.sh 2>&1
  echo "last_result"; ls -l /root/last_result.json 2>&1
} > /logs/paths.txt
if [ -f /home/agent/submit.sh ]; then head -n 80 /home/agent/submit.sh > /logs/submit.head; fi
if [ -f /root/binary/run.sh ] && [ -f /home/agent/binary/run.sh ]; then
  if cmp -s /root/binary/run.sh /home/agent/binary/run.sh; then echo SAME; else echo DIFFER; fi > /logs/runsh-cmp
fi
python3 - << "PY"
import json, pwd, subprocess
from pathlib import Path
rows = []
for user in pwd.getpwall():
    if user.pw_uid >= 2000 or user.pw_name in ("nobody", "nfsnobody"):
        continue
    cmd = "touch /root/last_result.json"
    proc = subprocess.run(["su", "-s", "/bin/sh", user.pw_name, "-c", cmd], capture_output=True, text=True)
    wrote = proc.returncode == 0
    if wrote:
        subprocess.run(["rm", "-f", "/root/last_result.json"], check=False)
    rows.append({
        "user": user.pw_name,
        "uid": user.pw_uid,
        "wrote_last_result": wrote,
        "stderr": (proc.stderr or "")[:200],
    })
Path("/logs/last-result-writes.json").write_text(json.dumps(rows, indent=2))
PY
'

fi

if want rubric; then
echo "rubric"
common xiaomimimo/mimo-v2.6-rl-oss:general-agent-env-0 rubric 2g '
set -u
id > /logs/id.txt
mkdir -p /work/workspace
rm -f /tmp/verifier-escaped-proof.json
cp /plant/sitecustomize.py /work/workspace/sitecustomize.py
python3 -c "print(1)" > /logs/workspace-python.txt 2>&1 || true
if [ -f /tmp/verifier-escaped-proof.json ]; then echo RAN; else echo DID_NOT_RUN; fi > /logs/workspace-plant
rm -f /tmp/verifier-escaped-proof.json
printf "%s\n" "print(\"verify-body\")" > /work/run_verify.py
python3 /work/run_verify.py > /logs/verify-body.txt 2>&1 || true
if [ -f /tmp/verifier-escaped-proof.json ]; then echo RAN; else echo DID_NOT_RUN; fi > /logs/verify-without-system-plant
SITE=$(python3 -c "import site; print(site.getsitepackages()[0])")
printf "%s\n" "$SITE" > /logs/site-packages.path
cp /plant/sitecustomize.py "$SITE/sitecustomize.py"
rm -f /tmp/verifier-escaped-proof.json
python3 /work/run_verify.py > /logs/verify-with-system-plant.txt 2>&1 || true
if [ -f /tmp/verifier-escaped-proof.json ]; then cp /tmp/verifier-escaped-proof.json /logs/verifier-escaped-proof.json; fi
rm -f "$SITE/sitecustomize.py"
'

fi

if want webdev; then
echo "webdev"
common xiaomimimo/mimo-v2.6-rl-oss:webdev-rl-opensource webdev 8g '
set -u
id > /logs/id.txt
mkdir -p /workspace/dist
cat > /workspace/dist/index.html << "EOF"
<!doctype html>
<title>before</title>
<h1 id="m">before</h1>
<script>
document.title = "P0_JS_RAN";
document.getElementById("m").textContent = "js-wrote-dom";
</script>
EOF
python3 - << "PY"
import json, os
from pathlib import Path
out = {"euid": os.geteuid()}
try:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(args=["--no-sandbox", "--disable-dev-shm-usage"])
        page = browser.new_page()
        page.goto("file:///workspace/dist/index.html")
        out["title"] = page.title()
        out["text"] = page.locator("#m").inner_text()
        browser.close()
        out["js_ran_in_chromium"] = out.get("title") == "P0_JS_RAN"
except Exception as exc:
    out["error"] = repr(exc)
Path("/logs/playwright-proof.json").write_text(json.dumps(out, indent=2))
print(json.dumps(out))
PY
'

fi

echo "Results: $OUT"
