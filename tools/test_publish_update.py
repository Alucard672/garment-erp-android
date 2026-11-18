import hashlib
import io
import json
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from publish_update import receive


class PublishUpdateTest(unittest.TestCase):
    def test_only_switches_manifest_after_apk_can_be_downloaded(self):
        with TemporaryDirectory() as folder:
            directory = Path(folder)
            latest = directory / "latest.json"
            signer = "a" * 64
            old = {"versionCode": 1, "signerSha256": signer}
            latest.write_text(json.dumps(old))
            apk = b"apk content"
            manifest = {
                "versionCode": 2, "versionName": "0.1.1", "signerSha256": signer,
                "apk": "garment-erp-2.apk", "bytes": len(apk),
                "sha256": hashlib.sha256(apk).hexdigest(),
            }
            url = "https://example.com/android-updates/latest.json"
            with patch("publish_update.verify_download", side_effect=ValueError("bad download")):
                with self.assertRaisesRegex(ValueError, "bad download"):
                    receive(directory, manifest, url, io.BytesIO(apk))
            self.assertEqual(json.loads(latest.read_text()), old)

            with patch("publish_update.verify_download") as verify:
                receive(directory, manifest, url, io.BytesIO(apk))
                verify.assert_called_once_with("https://example.com/android-updates/garment-erp-2.apk", len(apk))
            self.assertEqual(json.loads(latest.read_text()), manifest)
            self.assertEqual((directory / manifest["apk"]).read_bytes(), apk)
            with self.assertRaisesRegex(ValueError, "versionCode must increase"):
                receive(directory, manifest, url, io.BytesIO(apk))
            with self.assertRaisesRegex(ValueError, "signer differs"):
                receive(directory, {**manifest, "versionCode": 3, "apk": "garment-erp-3.apk",
                                    "signerSha256": "b" * 64}, url, io.BytesIO(apk))
