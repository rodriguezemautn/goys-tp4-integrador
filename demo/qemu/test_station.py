import json
from pathlib import Path
import subprocess
import sys
import unittest

SCRIPT = Path(__file__).with_name("station.py")


class StationTest(unittest.TestCase):
    def plan(self, role):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), role, "--state", "/nonexistent/fixture"],
            check=True, capture_output=True, text=True,
        )
        return json.loads(result.stdout)

    def test_hub_links_only_use_loopback(self):
        args = self.plan("hub")
        self.assertIn("none", args)
        self.assertIn("socket,id=chr,connect=127.0.0.1:41001", args)
        for port in (41011, 41012, 41013):
            self.assertTrue(any(f"listen=127.0.0.1:{port}" in arg for arg in args))

    def test_guests_use_distinct_ports_and_disks(self):
        plans = [self.plan(r) for r in ("server", "agent1", "agent2")]
        for i, args in enumerate(plans):
            self.assertIn("hvf", args)
            self.assertTrue(any(f"127.0.0.1:{2223+i}-:22" in a for a in args))
            self.assertIn(f"socket,id=cluster,connect=127.0.0.1:{41011+i}", args)
        self.assertEqual(len({next(a for a in p if "disk.qcow2" in a) for p in plans}), 3)

    def test_missing_disk_blocks_start(self):
        r = subprocess.run(
            [sys.executable, str(SCRIPT), "chr", "--state", "/nonexistent/fixture", "--start"],
            capture_output=True, text=True,
        )
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("Missing input", r.stderr)


if __name__ == "__main__":
    unittest.main()
