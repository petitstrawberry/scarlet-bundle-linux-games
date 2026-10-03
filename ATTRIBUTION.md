# Corresponding sources and licenses

The producer/bundle glue is MIT licensed. OpenTTD 15.3 is GPL-2.0 licensed;
the fixed fork revision contains the two GL compatibility corrections used in
the Scarlet Zink validation. OpenGFX 8.0 is the official free base set under
GPL-2.0. Its upstream Git tag source tree and the hash-checked official binary
archive are both retained. Upstream license files are installed with the game.

Every build exports `runtime/` and `sources/` together. The latter contains the
exact OpenTTD and OpenGFX Git trees, the producer/bundle recipes, source locks,
manifest and original OpenGFX binary archive. `source-files.sha256` checks all
regular source files. Redistribute these corresponding sources alongside binary
archives; this repository's workflows do not publish binary releases.

Shared Debian libraries are installed and owned by Debian. Their corresponding
sources are collected by the Debian rootfs producer. SDL/Mesa/SGFX are supplied
by `scarlet-linux-graphics`; they are not copied into the game bundle.
