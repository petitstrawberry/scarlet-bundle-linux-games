# Scarlet Linux games

Optional Linux ABI games for Scarlet. The first bundle is `bundles/openttd`:
OpenTTD 15.3 from the fixed `fix/gl21-compatibility` fork revision and official
OpenGFX 8.0. Native SWS/Wayland bridge come from Scarlet's desktop bundle;
shared SGFX/Mesa/SDL come from the graphics-enabled Debian rootfs.

## Build and select

On an AArch64 Docker-capable host (including Apple Silicon), in a clean checkout:

```sh
bash producer/build_container.sh
```

`artifacts/runtime/` is an overlay rooted at Scarlet `/`: desktop entry
`/etc/stemd.d/apps/org.scarlet-os.games.openttd.desktop`,
and Linux application `/systems/linux-aarch64/opt/openttd-zink`. Corresponding
sources are in `artifacts/sources/`. No shared libraries are bundled.

The source-build bundle uses Scarlet's `sh SCRIPT OUTPUT` layer contract and
caches a validated build by exact producer commit. After adding this bundle to
an image, select `GAMES=openttd` when building its Debian rootfs. The Debian
producer consumes a pinned games repo revision, resolves each selected game's
`runtime-packages.txt` and installs the package union with APT. `GAMES=none`
keeps the rootfs free of game-specific dependencies and needs no games checkout.
Game binaries are installed by the app bundle, not owned by dpkg. Debian-owned
library paths are never overwritten by the overlay. Build and runtime target
Debian 13/glibc AArch64; this is not a musl or cross-distro binary promise.

Select a fixed producer revision in the Scarlet bundle source:

```toml
[[layers]]
kind = "bundle"
source = { git = "https://github.com/petitstrawberry/scarlet-bundle-linux-games.git", rev = "7ea31e4100ba183db05461f8e2f2d2ea96aad849" }
subdir = "bundles/openttd"
```

The matching native bridge must be running. Its default socket is `wayland-0`;
override `WAYLAND_DISPLAY` when using a dedicated validation bridge. Launch
OpenTTD from the desktop entry or run
`abi-run linux-aarch64 /bin/sh /opt/openttd-zink/run-zink.sh`.
The desktop entry invokes `abi-run` directly; it does not depend on native
shell `exec` or positional-argument expansion. The Linux launcher selects
the shared `scarlet-gl` runtime, explicitly requires `sdl-opengl`, and keeps
configuration/saves in the user's state directory. It uses windowed 628x300
initial size so the toolbar and ScarletUI frame fit the scale-2 test display.
Sound/music backends are disabled in this initial bundle; the menu starts
normally rather than generating a validation map automatically.

The Debian-built binary from producer revision
`7ea31e4100ba183db05461f8e2f2d2ea96aad849` was checked on 2026-10-03 in the
dedicated Scarlet QEMU/HVF/VirGL snapshot. The shared runtime reported Zink on
`SGFX Vulkan (Scarlet VirGL GPU 0)`; menu startup, map generation, pan/zoom,
unpause, close and writable user configuration passed. Its binary SHA256 is
`84ccf98a753f03b0dccb704a5971f6c83ef208a1c4a4cbc833f1c9d0f3fbae21`.
The desktop entry's direct ABI command was exercised from the native shell;
clicking the new entry in Scarlet's app menu and booting the entire newly
generated rootfs were not checked. Linux-container checks additionally verified
the game's common private SDL linkage and Debian ownership of libpng. The rootfs
and corresponding-source archives passed checksum/loader/dependency checks.
Real hardware and fullscreen remain unverified/unsupported in the tested path.
See `ATTRIBUTION.md` for source distribution.

Add later games as catalog entries, `bundles/<game>`, recipes and runtime package
lists. The catalog/dependency resolver accepts only explicitly selected games.
