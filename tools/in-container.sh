#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: make in-container TARGET=dreamcast-build [MAKE_VARIABLE=VALUE ...]\n' >&2
}

if (($# == 0)); then
    usage
    exit 2
fi

target=$1
shift
if [[ ! "$target" =~ ^dreamcast-[[:alnum:]_.-]+$ ]]; then
    printf 'Invalid target for the KOS container: %s\n' "$target" >&2
    printf '%s\n' 'Only Dreamcast build targets may run in the KOS container.' >&2
    usage
    exit 2
fi

for override in "$@"; do
    if [[ ! "$override" =~ ^[[:alpha:]_][[:alnum:]_]*=.*$ ]]; then
        printf 'Invalid Make variable override: %s\n' "$override" >&2
        usage
        exit 2
    fi
done

if [[ -f /.dockerenv || -f /run/.containerenv ||
      -n "${REMOTE_CONTAINERS:-}" || -n "${DEV_CONTAINERS:-}" ||
      -n "${CODESPACES:-}" ]]; then
    printf 'Running Dreamcast target %s in the current KOS container.\n' "$target" >&2
    exec make "$target" "$@"
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
runtime=${CONTAINER_RUNTIME:-docker}
runtime_path=$(command -v "$runtime" 2>/dev/null || true)
if [[ -z "$runtime_path" ]]; then
    printf 'Container runtime not found: %s\nInstall Docker or set CONTAINER_RUNTIME to an installed compatible runtime.\n' "$runtime" >&2
    exit 2
fi

image=${KOS_IMAGE:-maishuji/dc-kos-image:15.2.1-dev-08feb26-gdb-kp08feb26}
uid=$(id -u)
gid=$(id -g)
printf 'Running Dreamcast target %s in %s as host uid:gid %s:%s...\n' \
    "$target" "$image" "$uid" "$gid" >&2

exec "$runtime_path" run --rm \
    --user "$uid:$gid" \
    --env HOME=/tmp \
    --volume "$repo_root:/workspace" \
    --workdir /workspace \
    "$image" \
    bash -lc 'source /opt/toolchains/dc/kos/environ.sh && exec make "$@"' _ "$target" "$@"
