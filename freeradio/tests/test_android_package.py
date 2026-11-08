import importlib.util
import tempfile
import unittest
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
CATALOGS = [ROOT / "catalog/radiodata.json"]
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"

spec = importlib.util.spec_from_file_location(
    "network_policy", ANDROID / "generate_network_security_config.py"
)
network_policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(network_policy)


class AndroidPackageTest(unittest.TestCase):
    def test_manifest_has_only_required_permissions(self):
        root = ET.parse(ANDROID / "AndroidManifest.xml").getroot()
        permissions = {
            node.attrib[ANDROID_NS + "name"] for node in root.findall("uses-permission")
        }
        self.assertEqual(
            permissions,
            {
                "android.permission.INTERNET",
                "android.permission.POST_NOTIFICATIONS",
                "android.permission.FOREGROUND_SERVICE",
                "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
            },
        )
        serialized = ET.tostring(root, encoding="unicode").upper()
        self.assertNotIn("RECORD_AUDIO", serialized)
        self.assertNotIn("READ_EXTERNAL_STORAGE", serialized)
        self.assertNotIn("WRITE_EXTERNAL_STORAGE", serialized)

    def test_service_is_private_media_playback_foreground_service(self):
        root = ET.parse(ANDROID / "AndroidManifest.xml").getroot()
        service = root.find("application/service")
        self.assertIsNotNone(service)
        self.assertEqual(service.attrib[ANDROID_NS + "exported"], "false")
        self.assertEqual(service.attrib[ANDROID_NS + "foregroundServiceType"], "mediaPlayback")

    def test_cleartext_policy_is_exactly_derived_from_catalogs(self):
        expected = set(network_policy.cleartext_hosts(CATALOGS))
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "network_security_config.xml"
            network_policy.write_policy(CATALOGS, output)
            root = ET.parse(output).getroot()
        base = root.find("base-config")
        self.assertEqual(base.attrib["cleartextTrafficPermitted"], "false")
        domains = root.findall("domain-config/domain")
        self.assertEqual({domain.text for domain in domains}, expected)
        self.assertTrue(expected)
        self.assertTrue(all(domain.attrib["includeSubdomains"] == "false" for domain in domains))

    def test_manifest_does_not_enable_global_cleartext(self):
        root = ET.parse(ANDROID / "AndroidManifest.xml").getroot()
        app = root.find("application")
        self.assertEqual(app.attrib[ANDROID_NS + "usesCleartextTraffic"], "false")
        self.assertEqual(
            app.attrib[ANDROID_NS + "networkSecurityConfig"],
            "@xml/network_security_config",
        )

    def test_cmake_packages_both_required_abis(self):
        cmake = (ROOT / "CMakeLists.txt").read_text(encoding="utf-8")
        self.assertIn('FREERADIO_SUPPORTED_ANDROID_ABIS "arm64-v8a;x86_64"', cmake)
        self.assertIn("QT_ANDROID_PACKAGE_SOURCE_DIR", cmake)
        self.assertIn("qt_finalize_executable(freeradio)", cmake)

    def test_service_has_media_controls_focus_and_noisy_receiver(self):
        service = (ANDROID / "src/org/freeradio/app/PlaybackService.java").read_text(
            encoding="utf-8"
        )
        for required in (
            "MediaSession",
            "ACTION_PLAY",
            "ACTION_PAUSE",
            "ACTION_STOP",
            "ACTION_NEXT",
            "ACTION_PREVIOUS",
            "requestAudioFocus",
            "ACTION_AUDIO_BECOMING_NOISY",
            "startForeground",
        ):
            self.assertIn(required, service)


if __name__ == "__main__":
    unittest.main()
