#!/usr/bin/env python3
import hashlib
import json
import pathlib
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
producer = pathlib.Path(__file__).resolve().parents[1]
manifest = json.loads((producer / "producer/sources.lock.json").read_text())
manifest["producer_revision"] = sys.argv[2]
manifest["build_environment"] = pathlib.Path("/etc/os-release").read_text()
manifest["runtime_packages"] = (producer / "producer/recipes/openttd/runtime-packages.txt").read_text().splitlines()
manifest["tools"] = {name: subprocess.check_output(args, text=True).strip() for name, args in {
    "cc": ["cc", "--version"], "cmake": ["cmake", "--version"],
    "glibc": ["getconf", "GNU_LIBC_VERSION"]}.items()}
manifest["runtime_files"] = {}
manifest["elf"] = {}
for path in sorted((root / "runtime").rglob("*")):
    relative = str(path.relative_to(root / "runtime"))
    if path.is_symlink():
        manifest["runtime_files"][relative] = {"symlink": str(path.readlink())}
    elif path.is_file():
        manifest["runtime_files"][relative] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        if path.read_bytes()[:4] == b"\x7fELF":
            manifest["elf"][relative] = {"dynamic": subprocess.check_output(["readelf", "-d", str(path)], text=True),
                "versions": subprocess.check_output(["readelf", "--version-info", str(path)], text=True)}
(root / "runtime/systems/linux-aarch64/opt/openttd-zink/manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
(root / "sources/manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
