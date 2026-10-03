#!/bin/sh
set -eu
app=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
# Keep saves and mutable configuration outside the installed application.
state="${XDG_DATA_HOME:-${HOME:?HOME must be set}/.local/share}/scarlet-games/openttd"
mkdir -p "$state"
if [ ! -f "$state/openttd.cfg" ]; then
    cp "$app/openttd-zink.cfg" "$state/openttd.cfg"
fi
cd "$state"
exec /usr/local/bin/scarlet-gl "$app/openttd" \
    -x -c "$state/openttd.cfg" -I OpenGFX -v sdl-opengl \
    -b 40bpp-anim -s null -m null -r 628x300 -d driver=2 "$@"
