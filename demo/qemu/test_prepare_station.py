import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent


class PreparationTest(unittest.TestCase):
    def test_seed_plan_sets_distinct_static_lan_and_no_default_route(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "fresh"
            result = subprocess.run(
                [sys.executable, str(HERE / "prepare_ubuntu.py"), "--state", str(root)],
                check=True, capture_output=True, text=True,
            )
            nodes = json.loads(result.stdout)
            self.assertEqual(list(nodes), ["server", "agent1", "agent2"])
            for i, node in enumerate(nodes.values(), 11):
                eth = node["network"]["ethernets"]
                self.assertEqual(eth["cluster"]["addresses"], [f"10.10.10.{i}/24"])
                self.assertFalse(eth["cluster"]["dhcp4"])
                self.assertNotIn("routes", eth["cluster"])
                self.assertFalse(eth["mgmt"]["dhcp4-overrides"]["use-routes"])
            self.assertFalse(root.exists())


if __name__ == "__main__":
    unittest.main()
