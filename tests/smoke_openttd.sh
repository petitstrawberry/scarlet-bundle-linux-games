#!/bin/sh
set -eu
app="${1:-/opt/openttd-zink}"
file "$app/openttd" | grep -q 'ARM aarch64'
test -s "$app/baseset/opengfx-8.0.tar"
test -s "$app/manifest.json"
test -s "$app/licenses/OpenTTD"
test -s "$app/licenses/OpenGFX"
ldd "$app/openttd" > /tmp/openttd-ldd.txt
if grep -q 'not found' /tmp/openttd-ldd.txt; then cat /tmp/openttd-ldd.txt >&2; exit 1; fi
grep -q libfreetype.so /tmp/openttd-ldd.txt
grep -q libfontconfig.so /tmp/openttd-ldd.txt
# Check discovery of a Japanese font covering the character from the reported
# missing-glyph failure. The game itself is checked in Scarlet, not this test.
japanese_font=$(readlink -f "$(fc-match 'sans:lang=ja:charset=6587' -f '%{file}')")
test -s "$japanese_font"
case "$japanese_font" in */ipafont-gothic/*) ;; *) echo "Japanese font not selected: $japanese_font" >&2; exit 1 ;; esac
echo SCARLET_OPENTTD_JAPANESE_FONT_OK
timeout 30 "$app/openttd" -h > /tmp/openttd-help.txt 2>&1
grep -q 'OpenTTD' /tmp/openttd-help.txt
echo SCARLET_OPENTTD_LOAD_OK
# Linux dependency/help check only; no Scarlet GPU/gameplay claim.
