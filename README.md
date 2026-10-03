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

`artifacts/runtime/` is an overlay rooted at Scarlet `/`: native launcher
`/bin/openttd`, desktop entry `/etc/stemd.d/apps/org.scarlet-os.games.openttd.desktop`,
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
source = { git = "https://github.com/petitstrawberry/scarlet-bundle-linux-games.git", rev = "<exact-40-character-commit>" }
subdir = "bundles/openttd"
```

The matching native bridge must be running. Its default socket is `wayland-0`;
override `WAYLAND_DISPLAY` when using a dedicated validation bridge. Launch
OpenTTD from the desktop entry or run `/bin/openttd`. The Linux launcher selects
the shared `scarlet-gl` runtime, explicitly requires `sdl-opengl`, and keeps
configuration/saves in the user's state directory. It uses windowed 628x300
initial size so the toolbar and ScarletUI frame fit the scale-2 test display.
Sound/music backends are disabled in this initial bundle; the menu starts
normally rather than generating a validation map automatically.

The earlier patched OpenTTD binary passed gameplay/pan/zoom/close on Scarlet
QEMU/VirGL with the common Debian-built graphics runtime. This producer rebuilds
OpenTTD in Debian; Linux dependency/help success alone is not new gameplay
validation. Real hardware and fullscreen remain unverified/unsupported in the
tested path. See `ATTRIBUTION.md` for source distribution.

Add later games as catalog entries, `bundles/<game>`, recipes and runtime package
lists. The catalog/dependency resolver accepts only explicitly selected games.
