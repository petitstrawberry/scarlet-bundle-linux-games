#!/usr/bin/env python3
"""Fetch exact Git trees and the hash-checked official base-set archive."""
import hashlib
import json
import pathlib
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[1]
work, output = map(pathlib.Path, sys.argv[1:])
lock = json.loads((root / "producer/sources.lock.json").read_text())
for name in ["openttd", "opengfx"]:
    item = lock[name]
    source = work / (name + "-" + item["revision"])
    if not (source / ".git").exists():
        source.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init", "--quiet", str(source)], check=True)
        subprocess.run(["git", "-C", str(source), "remote", "add", "origin", item["url"]], check=True)
        subprocess.run(["git", "-C", str(source), "fetch", "--depth", "1", "origin", item["revision"]], check=True)
        subprocess.run(["git", "-C", str(source), "checkout", "--quiet", "--detach", "FETCH_HEAD"], check=True)
    actual = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    if actual != item["revision"] or subprocess.check_output(["git", "-C", str(source), "status", "--porcelain"]):
        raise SystemExit("Source cache must be clean and match the pin: " + name)
    destination = output / "sources/upstream" / name
    destination.mkdir(parents=True, exist_ok=True)
    with subprocess.Popen(["git", "-C", str(source), "archive", "HEAD"], stdout=subprocess.PIPE) as archive:
        subprocess.run(["tar", "-xf", "-", "-C", str(destination)], stdin=archive.stdout, check=True)
        archive.stdout.close()
        if archive.wait():
            raise SystemExit("Git source archive failed: " + name)
archive = work / "opengfx-8.0-all.zip"
if not archive.exists():
    subprocess.run(["curl", "-fL", "--retry", "3", lock["opengfx"]["binary_url"], "-o", str(archive)], check=True)
if hashlib.sha256(archive.read_bytes()).hexdigest() != lock["opengfx"]["binary_sha256"]:
    raise SystemExit("OpenGFX archive checksum mismatch")
import shutil
shutil.copyfile(archive, output / "sources/opengfx-8.0-all.zip")
