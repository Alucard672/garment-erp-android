"""Send a staged Android update over SSH and atomically publish the HTTPS manifest."""

import argparse
import fcntl
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.parse import urljoin, urlsplit
from urllib.request import Request, urlopen


def validate(manifest, url):
    parts = urlsplit(url)
    if not (
        parts.scheme == "https" and parts.hostname and not parts.username
        and parts.path.endswith("/latest.json") and not (parts.query or parts.fragment)
    ):
        raise ValueError("Expected an HTTPS URL ending in /latest.json.")
    code, size = manifest["versionCode"], manifest["bytes"]
    if not (type(code) is int and 1 <= code <= 2_100_000_000 and
            type(size) is int and 1 <= size <= 536_870_912 and
            manifest["apk"] == f"garment-erp-{code}.apk" and
            all(re.fullmatch(r"[a-f0-9]{64}", manifest[key]) for key in ("sha256", "signerSha256"))):
        raise ValueError("Version manifest does not match the staged APK format.")


def verify_download(url, size):
    request = Request(url, method="HEAD", headers={"Cache-Control": "no-cache"})
    with urlopen(request, timeout=15) as response:
        if response.status != 200 or response.geturl() != url or response.headers.get("Content-Length") != str(size):
            raise ValueError("The HTTPS APK URL must return the staged file with its exact size.")


def matches(path, expected):
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest() == expected


def receive(directory, manifest, url, stream):
    validate(manifest, url)
    if not directory.is_dir():
        raise ValueError(f"Create the release directory first: {directory}")
    apk = directory / manifest["apk"]
    latest = directory / "latest.json"
    with (directory / ".publish.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        previous = json.loads(latest.read_text()) if latest.exists() else None
        if previous:
            if previous["versionCode"] >= manifest["versionCode"]:
                raise ValueError("The published versionCode must increase.")
            if previous.get("signerSha256") not in (None, manifest["signerSha256"]):
                raise ValueError("The APK signer differs from the published release.")
        with NamedTemporaryFile(dir=directory, prefix=".upload-", delete=False) as output:
            temporary = Path(output.name)
            digest = hashlib.sha256()
            remaining = manifest["bytes"]
            try:
                for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                    remaining -= len(chunk)
                    if remaining < 0:
                        raise ValueError("Uploaded APK exceeds the staged size.")
                    digest.update(chunk)
                    output.write(chunk)
                if remaining or digest.hexdigest() != manifest["sha256"]:
                    raise ValueError("Uploaded APK checksum or size does not match.")
                if apk.exists():
                    if not matches(apk, manifest["sha256"]):
                        raise ValueError("A different APK is already stored for this versionCode.")
                else:
                    output.flush()
                    temporary.chmod(0o644)
                    temporary.rename(apk)
            finally:
                temporary.unlink(missing_ok=True)
        verify_download(urljoin(url, apk.name), manifest["bytes"])
        with NamedTemporaryFile(mode="w", encoding="utf-8", dir=directory, prefix=".latest-", delete=False) as output:
            temporary = Path(output.name)
            try:
                json.dump(manifest, output, ensure_ascii=False)
                output.write("\n")
                output.flush()
                temporary.chmod(0o644)
                os.replace(temporary, latest)
            finally:
                temporary.unlink(missing_ok=True)
    print(f"Published Android {manifest['versionName']} ({manifest['versionCode']}).")


def main():
    if len(sys.argv) == 5 and sys.argv[1] == "--receive":
        receive(Path(sys.argv[2]), json.loads(sys.argv[3]), sys.argv[4], sys.stdin.buffer)
        return

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("staged", type=Path)
    parser.add_argument("host")
    parser.add_argument("remote_directory")
    parser.add_argument("manifest_url")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9.@_-]*", args.host):
        parser.error("Use an SSH host alias or user@host.")
    manifest = json.loads((args.staged / "latest.json").read_text())
    validate(manifest, args.manifest_url)
    source = Path(__file__).read_text()
    command = shlex.join([
        "python3", "-c", source, "--receive", args.remote_directory,
        json.dumps(manifest, ensure_ascii=True), args.manifest_url,
    ])
    with (args.staged / manifest["apk"]).open("rb") as apk:
        result = subprocess.run(["ssh", "-o", "BatchMode=yes", args.host, command], stdin=apk)
    if result.returncode:
        raise SystemExit(f"Android publication failed (SSH status {result.returncode}).")


if __name__ == "__main__":
    try:
        main()
    except (KeyError, OSError, ValueError) as exc:
        raise SystemExit(f"Android publication failed: {exc}") from None
