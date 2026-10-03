#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
destination="${1:?Scarlet script layer must supply an output directory}"
revision=$(git -C "$root" rev-parse HEAD)
if [ -n "$(git -C "$root" status --porcelain)" ]; then echo 'Commit producer changes before building' >&2; exit 2; fi
output="$root/producer/cache/bundle-$revision"
if [ ! -f "$output/validated-producer-revision" ]; then
    GAMES_OUTPUT="$output" bash "$root/producer/build_container.sh"
fi
test "$(cat "$output/validated-producer-revision")" = "$revision"
python3 - "$output/runtime" "$destination" <<'PY'
import pathlib, shutil, sys
source, destination = map(lambda p: pathlib.Path(p).resolve(), sys.argv[1:])
if destination == pathlib.Path('/') or destination == source or source in destination.parents:
    raise SystemExit('Unsafe bundle output directory')
shutil.copytree(source, destination, dirs_exist_ok=True, symlinks=True)
PY
