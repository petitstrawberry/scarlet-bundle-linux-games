#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
destination="${1:?Scarlet script layer must supply an output directory}"
revision=$(git -C "$root" rev-parse HEAD)
if [ -n "$(git -C "$root" status --porcelain)" ]; then echo 'Commit producer changes before building' >&2; exit 2; fi
output="$root/producer/cache/bundle-$revision"
if [ ! -f "$output/validated-producer-revision" ]; then
    mkdir -p "$root/producer/cache"
    temporary=$(mktemp -d "$root/producer/cache/.openttd-$revision.XXXXXXXX")
    GAMES_OUTPUT="$temporary" bash "$root/producer/build_container.sh"
    python3 - "$temporary" "$output" "$revision" <<'PY'
import pathlib, shutil, sys
temporary, output = map(pathlib.Path, sys.argv[1:3])
try:
    temporary.rename(output)
except FileExistsError:
    if (output / 'validated-producer-revision').read_text().strip() != sys.argv[3]:
        raise SystemExit('Existing bundle cache has a different producer revision')
    shutil.rmtree(temporary)
PY
fi
test "$(cat "$output/validated-producer-revision")" = "$revision"
python3 - "$output/runtime" "$destination" <<'PY'
import pathlib, shutil, sys
source, destination = map(lambda p: pathlib.Path(p).resolve(), sys.argv[1:])
if destination == pathlib.Path('/') or destination == source or source in destination.parents:
    raise SystemExit('Unsafe bundle output directory')
shutil.copytree(source, destination, dirs_exist_ok=True, symlinks=True)
PY
