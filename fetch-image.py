# /// script
# requires-python = ">=3.11"
# ///
"""Download the pinned public image without using Docker or local credentials."""
import gzip
import hashlib
import json
import shutil
import tarfile
import urllib.request
from pathlib import Path

REPO = "xiaomimimo/mimo-v2.6-rl-oss"
DIGEST = "sha256:eba881c4e34d3a8f9edc004f7b08f7c2589f1ca2b35146ded068f65d3ef4ca19"
TAG = f"{REPO}:general-agent-env-55"
ROOT = Path(__file__).resolve().parent / "data" / "image-55"


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    url = f"https://auth.docker.io/token?service=registry.docker.io&scope=repository:{REPO}:pull"
    with urllib.request.urlopen(url, timeout=60) as response:
        token = json.load(response)["token"]

    def download(kind, digest, target):
        if target.is_file():
            with target.open("rb") as source:
                if hashlib.file_digest(source, "sha256").hexdigest() == digest.split(":")[1]:
                    return
        request = urllib.request.Request(
            f"https://registry-1.docker.io/v2/{REPO}/{kind}/{digest}",
            headers={"Authorization": f"Bearer {token}",
                     "Accept": "application/vnd.docker.distribution.manifest.v2+json"},
        )
        temporary = target.with_suffix(target.suffix + ".partial")
        with urllib.request.urlopen(request, timeout=60) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)
        with temporary.open("rb") as source:
            actual = hashlib.file_digest(source, "sha256").hexdigest()
        if actual != digest.split(":")[1]:
            raise ValueError(f"Digest mismatch for {digest}")
        temporary.replace(target)

    download("manifests", DIGEST, ROOT / "registry-manifest.json")
    manifest = json.loads((ROOT / "registry-manifest.json").read_text())
    config_name = manifest["config"]["digest"].split(":")[1] + ".json"
    download("blobs", manifest["config"]["digest"], ROOT / config_name)
    config = json.loads((ROOT / config_name).read_text())
    print(f"Image platform: {config['os']}/{config['architecture']}", flush=True)
    layers = []
    for index, layer in enumerate(manifest["layers"], 1):
        name = layer["digest"].split(":")[1]
        compressed = ROOT / f"{name}.tar.gz"
        print(f"Downloading layer {index}/{len(manifest['layers'])}: {layer['size']} bytes", flush=True)
        download("blobs", layer["digest"], compressed)
        uncompressed = ROOT / f"{name}.tar"
        with gzip.open(compressed, "rb") as source, uncompressed.open("wb") as output:
            shutil.copyfileobj(source, output)
        layers.append(uncompressed.name)
    (ROOT / "manifest.json").write_text(json.dumps([
        {"Config": config_name, "RepoTags": [TAG], "Layers": layers}
    ]))
    archive = ROOT.parent / "image-55.tar"
    temporary = archive.with_suffix(".partial")
    with tarfile.open(temporary, "w") as output:
        for name in ["manifest.json", config_name, *layers]:
            output.add(ROOT / name, arcname=name)
    temporary.replace(archive)
    print(f"Verified image digest: {DIGEST}", flush=True)
    print(f"Docker load archive: {archive} ({archive.stat().st_size} bytes)", flush=True)


if __name__ == "__main__":
    main()
