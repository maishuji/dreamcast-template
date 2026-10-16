#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

if [[ -f /.dockerenv || -f /run/.containerenv ||
      -n "${REMOTE_CONTAINERS:-}" || -n "${DEV_CONTAINERS:-}" ||
      -n "${CODESPACES:-}" ]]; then
    cat >&2 <<'MESSAGE'
make flycast must run on the host: it builds the CDI in a temporary KOS container,
then starts Flycast on the host desktop. From inside the Dev Container, use
make dreamcast-configure && make dreamcast-cdi, then run make flycast-logs
in a host terminal opened at the same shared workspace.
MESSAGE
    exit 2
fi

runtime=${CONTAINER_RUNTIME:-docker}
runtime_path=$(command -v "$runtime" 2>/dev/null || true)
if [[ -z "$runtime_path" ]]; then
    printf 'Container runtime not found: %s\nInstall Docker or set CONTAINER_RUNTIME.\n' "$runtime" >&2
    exit 2
fi

if [[ -n "${FLYCAST_BIN:-}" ]]; then
    if ! command -v "$FLYCAST_BIN" >/dev/null 2>&1; then
        printf 'Flycast executable not found: %s\n' "$FLYCAST_BIN" >&2
        exit 2
    fi
elif ! command -v flycast >/dev/null 2>&1 &&
     { ! command -v flatpak >/dev/null 2>&1 || ! flatpak info org.flycast.Flycast >/dev/null 2>&1; }; then
    printf 'Flycast not found: install the native binary or org.flycast.Flycast Flatpak, or set FLYCAST_BIN.\n' >&2
    exit 2
fi

image=${KOS_IMAGE:-maishuji/dc-kos-image:15.2.1-dev-08feb26-gdb-kp08feb26}
build_dir=${DC_BUILD_DIR:-build-dreamcast}
uid=$(id -u)
gid=$(id -g)
printf 'Building the CDI in %s as host uid:gid %s:%s...\n' "$image" "$uid" "$gid" >&2

"$runtime_path" run --rm \
    --user "$uid:$gid" \
    --env HOME=/tmp \
    --env DC_BUILD_DIR="$build_dir" \
    --volume "$repo_root:/workspace" \
    --workdir /workspace \
    "$image" \
    bash -lc 'source /opt/toolchains/dc/kos/environ.sh && make dreamcast-configure && make dreamcast-cdi'

cdi=${DC_CDI:-out/my_module.cdi}
if [[ "$cdi" != /* ]]; then
    cdi="$repo_root/$cdi"
fi
if [[ ! -s "$cdi" ]]; then
    printf 'KOS container build completed but the requested CDI is missing or empty on the host: %s\n' "$cdi" >&2
    printf 'Confirm the workspace is shared with the host and CDI generation is enabled.\n' >&2
    exit 1
fi

printf 'Build succeeded; requested CDI is visible on the host: %s\n' "$cdi" >&2
cd -- "$repo_root"
DC_CDI="$cdi" bash tools/run-flycast.sh
