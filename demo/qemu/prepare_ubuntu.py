#!/usr/bin/env python3
"""Prepare independent Ubuntu QEMU disks and cloud-init seeds in a new directory."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from station import GUESTS


def plans():
    return {
        name: {
            "meta": {"instance-id": f"tp4-r1-{name}", "local-hostname": f"k3s-{name}"},
            "network": {"version":2,"ethernets":{
                "mgmt":{"match":{"macaddress":f"52:54:00:04:{i}:00"},"dhcp4":True,
                        "dhcp4-overrides":{"use-routes":False,"use-dns":False}},
                "cluster":{"match":{"macaddress":f"52:54:00:04:10:{i}"},"dhcp4":False,
                           "addresses":[f"10.10.10.{i}/24"],"optional":True},
            }},
        }
        for i, name in enumerate(GUESTS, 11)
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--create", action="store_true")
    parser.add_argument("--image", type=Path)
    parser.add_argument("--sha256")
    parser.add_argument("--firmware", type=Path)
    opts = parser.parse_args()
    nodes = plans()
    if not opts.create:
        print(json.dumps(nodes, indent=2))
        return
    if not opts.image or not opts.sha256 or not opts.firmware:
        parser.error("--create requires --image, --sha256 and --firmware")
    with opts.image.open("rb") as source:
        if hashlib.file_digest(source, "sha256").hexdigest() != opts.sha256.lower():
            parser.error("Ubuntu image checksum mismatch")
    for tool in ("qemu-img", "hdiutil"):
        if not shutil.which(tool):
            parser.error(f"Missing tool: {tool}")
    root = opts.state
    root.mkdir(mode=0o700, exist_ok=False)
    shutil.copyfile(opts.firmware, root / "firmware.fd")
    for role, node in nodes.items():
        dest = root / role
        dest.mkdir(mode=0o700)
        disk = dest / "disk.qcow2"
        subprocess.run(["qemu-img", "convert", "-f", "qcow2", "-O", "qcow2",
                        str(opts.image), str(disk)], check=True)
        subprocess.run(["qemu-img", "resize", str(disk), "12G"], check=True)
        with (dest / "vars.fd").open("xb") as handle:
            handle.truncate(64 * 1024 * 1024)
        with tempfile.TemporaryDirectory(dir=root) as temp:
            data = Path(temp)
            (data / "meta-data").write_text(json.dumps(node["meta"]))
            (data / "network-config").write_text(json.dumps(node["network"]))
            (data / "user-data").write_text(
                "#cloud-config\nssh_pwauth: false\ndisable_root: true\n"
                "package_update: false\npackage_upgrade: false\n"
                "runcmd:\n  - [sh, -c, 'echo TP4_SEED_READY_" + role + " >/dev/ttyAMA0']\n"
            )
            subprocess.run(["hdiutil", "makehybrid", "-quiet", "-iso", "-joliet",
                            "-default-volume-name", "CIDATA", "-o", str(dest / "seed.iso"), temp],
                           check=True)
    print("Prepared three independent Ubuntu disks and seeds.")


if __name__ == "__main__":
    main()
