#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="${GAMES_OUTPUT:-$root/artifacts}"
mkdir -p "$output"
if [[ -e "$output/runtime" || -e "$output/sources" ]]; then echo 'Choose a fresh GAMES_OUTPUT directory' >&2; exit 2; fi
if [[ -n "$(git -C "$root" status --porcelain)" ]]; then echo 'Commit producer changes before building' >&2; exit 2; fi
revision="$(git -C "$root" rev-parse HEAD)"
input_key="$(shasum -a 256 "$root/producer/sources.lock.json" | cut -d ' ' -f 1)"
stage="$(mktemp -d "$output/validation.XXXXXXXX")"
args=(--platform linux/arm64 --build-arg "GAMES_REVISION=$revision" --build-arg "GAMES_CACHE_ID=$input_key" --build-arg "BUILD_JOBS=${BUILD_JOBS:-4}" -f "$root/producer/Dockerfile")
docker build "${args[@]}" --target runtime --iidfile "$stage/runtime.id" "$root"
docker run --rm --network none --platform linux/arm64 "$(cat "$stage/runtime.id")" sh /tmp/smoke_openttd.sh
docker build "${args[@]}" --target export --output "type=local,dest=$output" "$root"
printf '%s\n' "$revision" > "$output/validated-producer-revision"
echo "Exported runtime and corresponding sources: $output"
