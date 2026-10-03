#!/usr/bin/env python3
"""Emit the Debian package union and provenance for explicitly selected games."""
import argparse
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]


def resolve(selection):
    catalog = json.loads((ROOT / "producer/games.json").read_text())
    if catalog["schema"] != 1:
        raise ValueError("Unsupported games catalog schema")
    names = [] if selection == "none" else selection.split(",")
    if not names and selection != "none":
        raise ValueError("Use GAMES=none or a comma-separated game list")
    if any(not re.fullmatch(r"[a-z][a-z0-9-]*", name) or name not in catalog["games"] for name in names):
        raise ValueError("Unknown/invalid game selection: " + selection)
    packages = set()
    graphics = False
    for name in sorted(set(names)):
        game = catalog["games"][name]
        graphics |= game["requires_graphics"]
        path = (ROOT / game["runtime_packages"]).resolve()
        if ROOT not in path.parents:
            raise ValueError("Package manifest escapes the producer")
        for line in path.read_text().splitlines():
            package = line.strip()
            if not package or package.startswith("#"):
                continue
            if not re.fullmatch(r"[a-z0-9][a-z0-9+.-]*(?::[a-z0-9]+)?", package):
                raise ValueError("Invalid Debian package: " + package)
            packages.add(package)
    return {"schema": 1, "games": sorted(set(names)), "requires_graphics": graphics,
            "packages": sorted(packages)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--games", required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--revision", required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9a-f]{40}", args.revision):
        parser.error("Producer revision must be an exact commit")
    try:
        result = resolve(args.games)
    except ValueError as error:
        parser.error(str(error))
    result["producer_revision"] = args.revision
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "selection.json").write_text(json.dumps(result, indent=2) + "\n")
    (args.output / "runtime-packages.txt").write_text("".join(p + "\n" for p in result["packages"]))


if __name__ == "__main__":
    main()
