#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="${1:?usage: build.sh OUTPUT}"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
test "$(uname -m)" = aarch64
work="${GAMES_WORK:-/games-work}"
mkdir -p "$work" "$output/runtime" "$output/sources"
python3 "$root/producer/fetch_sources.py" "$work" "$output"
revision="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["openttd"]["revision"])' "$root/producer/sources.lock.json")"
source="$work/openttd-$revision"
cmake -S "$source" -B "$work/openttd-build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/openttd-zink \
    -DOPTION_INSTALL_FHS=OFF -DOPTION_DEDICATED=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_Allegro=ON -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_Freetype=ON -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_Harfbuzz=ON -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_Fluidsynth=ON -DCMAKE_DISABLE_FIND_PACKAGE_OpusFile=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_LZO=ON -DCMAKE_DISABLE_FIND_PACKAGE_unofficial-breakpad=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_Grfcodec=ON -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON
cmake --build "$work/openttd-build" --target openttd --parallel "${BUILD_JOBS:-4}"
linux_root="$output/runtime/systems/linux-aarch64"
DESTDIR="$linux_root" cmake --install "$work/openttd-build"
app="$linux_root/opt/openttd-zink"
mkdir -p "$app/baseset" "$app/licenses" "$output/runtime/bin" "$output/runtime/etc/stemd.d/apps"
unzip -p "$work/opengfx-8.0-all.zip" opengfx-8.0.tar > "$app/baseset/opengfx-8.0.tar"
tar -xOf "$app/baseset/opengfx-8.0.tar" opengfx-8.0/license.txt > "$app/licenses/OpenGFX"
install -m 644 "$source/COPYING.md" "$app/licenses/OpenTTD"
install -m 644 "$root/LICENSE" "$root/ATTRIBUTION.md" "$app/licenses/"
install -m 644 "$root/producer/recipes/openttd/openttd-zink.cfg" "$app/"
install -m 755 "$root/producer/recipes/openttd/run-zink.sh" "$app/"
install -m 755 "$root/producer/recipes/openttd/launch-scarlet.sh" "$output/runtime/bin/openttd"
install -m 644 "$root/producer/recipes/openttd/org.scarlet-os.games.openttd.desktop" "$output/runtime/etc/stemd.d/apps/"
mkdir -p "$output/sources/producer"
cp -a "$root/producer" "$root/bundles" "$root/tests" "$root/.github" "$root/.dockerignore" "$root/.gitignore" \
    "$root/LICENSE" "$root/ATTRIBUTION.md" "$root/README.md" "$output/sources/producer/"
python3 "$root/producer/write_manifest.py" "$output" "${GAMES_REVISION:?GAMES_REVISION must be an exact producer commit}"
(cd "$output/sources"; find . -type f -print0 | sort -z | xargs -0 sha256sum) > "$output/source-files.sha256"
echo "OpenTTD runtime and corresponding sources: $output"
