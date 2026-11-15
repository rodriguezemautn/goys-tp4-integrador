#!/usr/bin/env python3
"""Exercise deploy.yml tag selection with a local fake kubectl wrapper."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE_PLAYBOOK = Path(__file__).resolve().parents[1] / "deploy.yml"
TASK_NAMES = {
    "Cortar si siguen los valores de ejemplo",
    "Aplicar MetalLB",
    "Esperar al controller de MetalLB (webhook)",
    "Crear el Secret de la clave BGP",
    "Aplicar pool y sesión BGP (reintenta hasta que el webhook responda)",
    "Aplicar la aplicación",
    "Crear el namespace de monitoreo",
    "Crear el Secret de Grafana",
    "Aplicar monitoreo",
    "Aplicar NetworkPolicies",
    "Esperar a los Deployments",
}


class DeployScopeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="tp4-deploy-scope-")
        self.root = Path(self.temp.name)
        self.playbook = self.root / "deploy.yml"
        self.playbook.write_bytes(SOURCE_PLAYBOOK.read_bytes())
        (self.root / "apply_checked.py").write_bytes(SOURCE_PLAYBOOK.with_name("apply_checked.py").read_bytes())
        self.inventory = self.root / "inventory.ini"
        self.inventory.write_text(
            "[servers]\nlocalhost ansible_connection=local ansible_become=false\n",
            encoding="utf-8",
        )
        self.ansible_config = self.root / "ansible.cfg"
        self.ansible_config.write_text(
            "[defaults]\nretry_files_enabled = False\nhost_key_checking = True\n",
            encoding="utf-8",
        )
        self.fake_bin = self.root / "bin"
        self.fake_bin.mkdir()
        self.fake_k3s = self.fake_bin / "k3s"
        self.fake_k3s.write_text(
            "#!/bin/sh\n"
            "cat >/dev/null\n"
            "if [ \"$2\" = get ]; then printf '%s\\n' '{\"kind\":\"List\",\"items\":[{\"kind\":\"ConfigMap\",\"metadata\":{\"name\":\"test\",\"uid\":\"test\",\"resourceVersion\":\"1\"}}]}'; exit 0; fi\n"
            "printf '%s\\n' \"$*\" >> \"$FAKE_K3S_LOG\"\n"
            "printf 'unchanged\\n'\n",
            encoding="utf-8",
        )
        self.fake_k3s.chmod(0o700)
        self.calls = self.root / "calls.log"
        self.env = os.environ.copy()
        self.env.update(
            {
                "ANSIBLE_CONFIG": str(self.ansible_config),
                "ANSIBLE_NOCOLOR": "1",
                "ANSIBLE_HOST_KEY_CHECKING": "True",
                "FAKE_K3S_LOG": str(self.calls),
                "PATH": f"{self.fake_bin}:{os.environ['PATH']}",
            }
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def ansible(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "ansible-playbook",
                "--inventory",
                str(self.inventory),
                str(self.playbook),
                *args,
            ],
            cwd=self.root,
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
            timeout=60,
        )

    def run_play(self, tags: str | None, extra_vars: dict[str, str]) -> subprocess.CompletedProcess[str]:
        args = ["--limit", "localhost", "--extra-vars", json.dumps(extra_vars)]
        if tags is not None:
            args.extend(["--tags", tags])
        return self.ansible(*args)

    def calls_list(self) -> list[str]:
        if not self.calls.exists():
            return []
        return self.calls.read_text(encoding="utf-8").splitlines()

    def test_default_list_keeps_every_original_task(self) -> None:
        result = self.ansible("--list-tasks")
        self.assertEqual(result.returncode, 0, result.stderr)
        found = {
            line.split("\tTAGS:", 1)[0].strip()
            for line in result.stdout.splitlines()
            if line.startswith("      ") and "\tTAGS:" in line
        }
        self.assertEqual(found, TASK_NAMES)

    def test_scoped_task_lists_exclude_unselected_components(self) -> None:
        metallb_app = self.ansible("--list-tasks", "--tags", "metallb,app")
        self.assertEqual(metallb_app.returncode, 0, metallb_app.stderr)
        self.assertIn("Aplicar MetalLB", metallb_app.stdout)
        self.assertIn("Aplicar la aplicación", metallb_app.stdout)
        self.assertNotIn("Crear el namespace de monitoreo", metallb_app.stdout)
        self.assertNotIn("Crear el Secret de Grafana", metallb_app.stdout)
        self.assertNotIn("Aplicar NetworkPolicies", metallb_app.stdout)

        netpol = self.ansible("--list-tasks", "--tags", "netpol")
        self.assertEqual(netpol.returncode, 0, netpol.stderr)
        self.assertIn("Aplicar NetworkPolicies", netpol.stdout)
        self.assertNotIn("Aplicar monitoreo", netpol.stdout)
        self.assertNotIn("Esperar a los Deployments", netpol.stdout)

    def test_metallb_and_app_run_only_the_selected_rollouts(self) -> None:
        result = self.run_play(
            "metallb,app",
            {"bgp_md5": "safe-test-BGP", "grafana_admin": "CAMBIAR"},
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls_list()
        self.assertEqual(len(calls), 7, calls)
        self.assertTrue(any("metallb-native.yaml" in call for call in calls), calls)
        self.assertTrue(any("metallb/bgp.yaml" in call for call in calls), calls)
        self.assertTrue(any("apply -k" in call and "/app" in call for call in calls), calls)
        self.assertTrue(any("deployment/frontend" in call for call in calls), calls)
        self.assertTrue(any("deployment/backend" in call for call in calls), calls)
        self.assertFalse(any("monitoring" in call or "netpol" in call for call in calls), calls)
        self.assertFalse(any("prometheus" in call or "grafana" in call for call in calls), calls)

    def test_app_only_does_not_require_unused_component_secrets(self) -> None:
        result = self.run_play("app", {"bgp_md5": "CAMBIAR", "grafana_admin": "CAMBIAR"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls_list()
        self.assertEqual(len(calls), 3, calls)
        self.assertTrue(all("/app" in call or "deployment/" in call for call in calls), calls)
        self.assertFalse(any("monitoring" in call or "netpol" in call or "metallb" in call for call in calls), calls)

    def test_metallb_and_monitoring_guards_cannot_be_skipped(self) -> None:
        bgp = self.run_play("metallb", {"bgp_md5": "CAMBIAR", "grafana_admin": "safe-test"})
        self.assertNotEqual(bgp.returncode, 0)
        self.assertIn("Falta vault.yml o tiene los valores de ejemplo", bgp.stdout + bgp.stderr)
        self.assertEqual(self.calls_list(), [])

        monitoring = self.run_play("monitoring", {"bgp_md5": "safe-test", "grafana_admin": "CAMBIAR"})
        self.assertNotEqual(monitoring.returncode, 0)
        self.assertIn("Falta vault.yml o tiene los valores de ejemplo", monitoring.stdout + monitoring.stderr)
        self.assertEqual(self.calls_list(), [])

    def test_unfiltered_run_preserves_all_components_and_rollout_order(self) -> None:
        result = self.run_play(
            None,
            {"bgp_md5": "safe-test-BGP", "grafana_admin": "safe-test-Grafana"},
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls_list()
        self.assertEqual(len(calls), 13, calls)
        rollout_calls = [call for call in calls if "rollout status deployment/" in call]
        self.assertEqual(
            [call.rsplit("deployment/", 1)[1].split()[0] for call in rollout_calls],
            ["controller", "frontend", "backend", "prometheus", "grafana"],
        )
        self.assertTrue(any("/monitoring" in call for call in calls), calls)
        self.assertTrue(any("/netpol" in call for call in calls), calls)


if __name__ == "__main__":
    unittest.main()
