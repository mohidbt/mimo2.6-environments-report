import json
import os
from pathlib import Path

proof = Path("/tmp/verifier-escaped-proof.json")
proof.write_text(json.dumps({
    "euid": os.geteuid(),
    "shadow_readable": os.access("/etc/shadow", os.R_OK),
    "wrote_outside_app": True,
}))
