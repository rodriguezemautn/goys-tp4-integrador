#!/usr/bin/env python3
"""Print or run one QEMU station command using operator-provisioned inputs."""

import argparse
import json
import os
from pathlib import Path

GUESTS = ("server", "agent1", "agent2")


def build(role, state, offset=0, isolated=False):
    args = []
    inputs = []

    def drive(path, options):
        inputs.append(path)
        # QEMU doubles literal commas in option values.
        args.extend(["-drive", f"{options},file=" + str(path).replace(",", ",,")])

    def net(options):
        args.extend(["-netdev", options])

    def nic(backend, suffix):
        args.extend(["-device", f"virtio-net-pci,netdev={backend},mac=52:54:00:{suffix}"])

    if role == "hub":
        args.extend(["qemu-system-x86_64", "-machine", "none", "-nodefaults"])
        for name, address in [
            ("chr", f"connect=127.0.0.1:{41001+offset}"),
            *[(name, f"listen=127.0.0.1:{41011+i+offset}") for i, name in enumerate(GUESTS)],
        ]:
            net(f"socket,id={name},{address}")
            net(f"hubport,id=hub{name},hubid=0,netdev={name}")
        args.extend(["-serial", "none"])
    elif role == "chr":
        args.extend(["qemu-system-x86_64", "-machine", "pc", "-accel", "tcg",
                     "-cpu", "qemu64", "-smp", "1", "-m", "1024"])
        drive(state / role / "disk.qcow2", "if=virtio,format=qcow2")
        net("hubport,id=clients,hubid=1")
        nic("clients", "04:56:02")
        net(f"socket,id=cluster,listen=127.0.0.1:{41001+offset}")
        nic("cluster", "04:10:01")
        args.extend(["-serial", "stdio"])
    else:
        i = GUESTS.index(role)
        args.extend(["qemu-system-aarch64", "-machine", "virt", "-accel", "hvf",
                     "-cpu", "host", "-smp", "2" if i == 0 else "1",
                     "-m", "2048" if i == 0 else "768"])
        drive(state / "firmware.fd", "if=pflash,format=raw,readonly=on")
        drive(state / role / "vars.fd", "if=pflash,format=raw")
        drive(state / role / "disk.qcow2", "if=virtio,format=qcow2")
        drive(state / role / "seed.iso", "if=virtio,format=raw,readonly=on")
        net("user,id=mgmt,restrict=on" if isolated else f"user,id=mgmt,hostfwd=tcp:127.0.0.1:{2223+i+offset}-:22")
        nic("mgmt", f"04:{11+i}:00")
        net(f"socket,id=cluster,connect=127.0.0.1:{41011+i+offset}")
        nic("cluster", f"04:10:{11+i}")
        args.extend(["-serial", "stdio"])
    return args + ["-display", "none", "-monitor", "none", "-no-reboot"], inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("role", choices=("chr", "hub", *GUESTS))
    parser.add_argument("--state", type=Path, required=True, help="Dedicated private state directory")
    parser.add_argument("--start", action="store_true", help="Run this role in foreground")
    parser.add_argument("--port-offset", type=int, default=0)
    parser.add_argument("--isolated", action="store_true", help="Block outbound user networking and omit SSH forwarding")
    opts = parser.parse_args()
    if not 0 <= opts.port_offset <= 24000:
        parser.error("Port offset must be between 0 and 24000")
    args, inputs = build(opts.role, opts.state.resolve(), opts.port_offset, opts.isolated)
    if not opts.start:
        print(json.dumps(args, indent=2))
        return
    for path in inputs:
        if not path.is_file() or not os.access(path, os.R_OK):
            parser.error(f"Missing input or unreadable file: {path.name}")
    try:
        os.execvp(args[0], args)
    except OSError as exc:
        parser.error(f"Unable to start {args[0]}: {exc.strerror}")


if __name__ == "__main__":
    main()
