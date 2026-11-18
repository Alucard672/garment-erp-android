"""Prepare a signed APK and version manifest for an HTTPS update directory."""

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from tempfile import NamedTemporaryFile


PACKAGE = "com.wutongpuli.garment_erp_android"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--build-tools", type=Path, required=True)
    args = parser.parse_args()

    metadata = subprocess.check_output(
        [args.build_tools / "aapt", "dump", "badging", args.apk], text=True,
    )
    package = re.search(
        r"^package: name='([^']+)' versionCode='([0-9]+)' versionName='([^']+)'",
        metadata,
        re.MULTILINE,
    )
    if not package or package[1] != PACKAGE or "application-debuggable" in metadata:
        parser.error("Expected a non-debuggable APK for Garment ERP.")
    code = int(package[2])
    name = package[3]
    size = args.apk.stat().st_size
    if not 0 < code <= 2_100_000_000 or len(name) > 80 or not 0 < size <= 536_870_912:
        parser.error("Invalid APK version or size.")
    certificates = subprocess.check_output(
        [args.build_tools / "apksigner", "verify", "--print-certs", args.apk], text=True,
    )
    signers = re.findall(r"^Signer #\d+ certificate SHA-256 digest: ([a-f0-9]{64})$", certificates, re.M)
    if len(signers) != 1:
        parser.error("Expected exactly one APK signer.")

    args.output.mkdir(parents=True, exist_ok=True)
    latest = args.output / "latest.json"
    if latest.exists() and int(json.loads(latest.read_text())["versionCode"]) >= code:
        parser.error("The staged versionCode must increase with each release.")
    filename = f"garment-erp-{code}.apk"
    target = args.output / filename
    if target.exists():
        parser.error(f"APK already exists: {target}")
    digest = hashlib.sha256()
    with NamedTemporaryFile(dir=args.output, delete=False) as temporary:
        staged = Path(temporary.name)
        try:
            with args.apk.open("rb") as apk:
                for chunk in iter(lambda: apk.read(1024 * 1024), b""):
                    digest.update(chunk)
                    temporary.write(chunk)
            if temporary.tell() != size:
                parser.error("APK size changed while staging.")
            temporary.flush()
            staged.chmod(0o644)
            staged.rename(target)
        finally:
            staged.unlink(missing_ok=True)

    manifest = {
        "versionCode": code, "versionName": name, "apk": filename,
        "sha256": digest.hexdigest(), "bytes": size, "signerSha256": signers[0],
    }
    with NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.output, delete=False) as temporary:
        staged = Path(temporary.name)
        try:
            json.dump(manifest, temporary, ensure_ascii=False, indent=2)
            temporary.write("\n")
            temporary.flush()
            staged.chmod(0o644)
            staged.replace(latest)
        finally:
            staged.unlink(missing_ok=True)
    print(f"Publish {target} first, then {latest}.")


if __name__ == "__main__":
    main()
