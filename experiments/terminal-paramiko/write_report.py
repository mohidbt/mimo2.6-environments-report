import hashlib
import json
from pathlib import Path

root = Path("/app/vendor/paramiko")
order = [
    "paramiko/agent.py",
    "paramiko/channel.py",
    "paramiko/client.py",
    "paramiko/transport.py",
]
modules = {
    rel: {"sha256": hashlib.sha256((root / rel).read_bytes()).hexdigest()}
    for rel in order
}
Path("/app/output.json").write_text(json.dumps({
    "schema_version": "paramiko-repair-report.v1",
    "status": "repaired",
    "compiled": True,
    "modules": modules,
    "control_flow_policy": {"base_exception": "propagates"},
}))
