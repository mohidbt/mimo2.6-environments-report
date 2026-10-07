# /// script
# requires-python = ">=3.11"
# dependencies = ["huggingface-hub", "pyarrow"]
# ///
"""Run with: uv run fetch-task.py. Fetch only one task using image 55."""
import base64
import json
from pathlib import Path, PurePosixPath

import pyarrow.parquet as pq
from huggingface_hub import hf_hub_download, snapshot_download

REPO = "XiaomiMiMo/MiMo-V2.6-RL-oss"
REVISION = "f819cd2"
IMAGE_TAG = "general-agent-env-55"
IMAGE = "xiaomimimo/mimo-v2.6-rl-oss@sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19"
ROOT = Path(__file__).resolve().parent / "data"


def unpack(row):
    extra = row.get("extra_info", {})
    if isinstance(extra, str):
        extra = json.loads(extra)
    extra = dict(extra or {})
    raw = extra.get("instance_json")
    if raw is not None:
        return json.loads(raw) if isinstance(raw, str) else dict(raw)
    return row


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    metadata = hf_hub_download(
        REPO, "general/train.parquet", repo_type="dataset",
        revision=REVISION, local_dir=ROOT,
    )
    rows = pq.read_table(metadata).to_pylist()
    matches = [unpack(row) for row in rows
               if unpack(row).get("docker_image", "").rsplit("/", 1)[-1]
               in (f"{IMAGE_TAG}:oss", f"mimo-v2.6-rl-oss:{IMAGE_TAG}")]
    if not matches:
        images = sorted({unpack(row).get("docker_image", "") for row in rows})
        raise SystemExit(f"No task names {IMAGE_TAG}. Dataset images: {images}")
    instance = matches[0]
    if instance.get("dataset_type") == "terminal_bench":
        task_dir = ROOT / instance["instance_id"]
        task_dir.mkdir(parents=True, exist_ok=True)
        files = json.loads(instance["tests_files"])
        for name, encoded in files.items():
            relative = PurePosixPath(name)
            if relative.is_absolute() or ".." in relative.parts:
                raise SystemExit(f"Unexpected verifier file: {relative}")
            target = task_dir / "tests" / str(relative)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(base64.b64decode(encoded, validate=True))
        (task_dir / "task.txt").write_text(instance["problem_statement"])
        instance["docker_image"] = IMAGE
        (task_dir / "instance.json").write_text(json.dumps(instance, indent=2) + "\n")
        print(f"Extracted task: {instance['instance_id']}")
        print(f"Task and verifier files: {task_dir}")
        print("No container, agent rollout, or verifier execution has run.")
        return
    relative = PurePosixPath(instance["env_task_dir"])
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit(f"Unexpected task directory: {relative}")
    if relative.parts[0] == "envs":
        relative = PurePosixPath("general") / relative
    if relative.parts[:2] != ("general", "envs"):
        raise SystemExit(f"Unexpected task directory: {relative}")
    snapshot_download(
        REPO, repo_type="dataset", revision=REVISION, local_dir=ROOT,
        allow_patterns=[f"{relative}/**"],
    )
    task_dir = ROOT / str(relative)
    if not task_dir.is_dir():
        raise SystemExit(f"Task directory was not downloaded: {task_dir}")
    instance["env_task_dir"] = str(task_dir)
    instance["docker_image"] = IMAGE
    output = ROOT / "instance-55.json"
    output.write_text(json.dumps(instance, indent=2, ensure_ascii=False) + "\n")
    print(f"Selected one of {len(matches)} matching tasks: {instance.get('instance_id')}")
    print(f"Task files: {task_dir}")
    print(f"Instance: {output}")
    print("Task files downloaded. No agent rollout or reward evaluation has run.")


if __name__ == "__main__":
    main()
