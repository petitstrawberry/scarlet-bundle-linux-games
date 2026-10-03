FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS builder
COPY producer/recipes/openttd/build-packages.txt /tmp/build-packages.txt
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(cat /tmp/build-packages.txt)
COPY . /games-producer
ARG GAMES_REVISION
ARG GAMES_CACHE_ID=local
ARG BUILD_JOBS=4
RUN --mount=type=cache,id=scarlet-linux-games-work-${GAMES_CACHE_ID},target=/games-work,sharing=locked \
    GAMES_REVISION="$GAMES_REVISION" BUILD_JOBS="$BUILD_JOBS" bash /games-producer/producer/build.sh /out

FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS runtime
COPY producer/recipes/openttd/runtime-packages.txt /tmp/runtime-packages.txt
# SDL is supplied by the common graphics runtime on Scarlet. Debian's SDL is
# used only for this CPU/container loader/help check.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    $(cat /tmp/runtime-packages.txt) libsdl2-2.0-0 file
COPY --from=builder /out/runtime/systems/linux-aarch64/ /
COPY tests/smoke_openttd.sh /tmp/smoke_openttd.sh
RUN sh /tmp/smoke_openttd.sh

FROM scratch AS export
COPY --from=builder /out/ /
