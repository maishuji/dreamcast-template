#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin"

cat > "$work/bin/mock-docker" <<'MOCK'
#!/bin/bash
printf '%s\n' "$@" > "$MOCK_DOCKER_ARGS"
MOCK
cat > "$work/bin/mock-make" <<'MOCK'
#!/bin/bash
printf '%s\n' "$@" > "$MOCK_INNER_MAKE_ARGS"
MOCK
chmod +x "$work/bin/mock-docker" "$work/bin/mock-make"
ln -s mock-make "$work/bin/make"

MOCK_DOCKER_ARGS="$work/docker-args" \
CONTAINER_RUNTIME="$work/bin/mock-docker" KOS_IMAGE='test/kos:tag' \
    bash "$repo/tools/in-container.sh" dreamcast-build DC_BUILD_DIR=build-custom

grep -Fxq -- '--rm' "$work/docker-args"
grep -Fxq -- '--user' "$work/docker-args"
grep -Fxq "$(id -u):$(id -g)" "$work/docker-args"
grep -Fxq -- '--volume' "$work/docker-args"
grep -Fxq "$repo:/workspace" "$work/docker-args"
grep -Fxq -- '--workdir' "$work/docker-args"
grep -Fxq 'test/kos:tag' "$work/docker-args"
grep -Fxq 'source /opt/toolchains/dc/kos/environ.sh && exec make "$@"' "$work/docker-args"
grep -Fxq 'dreamcast-build' "$work/docker-args"
grep -Fxq 'DC_BUILD_DIR=build-custom' "$work/docker-args"

REMOTE_CONTAINERS=true PATH="$work/bin" MOCK_INNER_MAKE_ARGS="$work/inner-make-args" \
    /bin/bash "$repo/tools/in-container.sh" dreamcast-build DC_BUILD_DIR=build-inner
grep -Fxq 'dreamcast-build' "$work/inner-make-args"
grep -Fxq 'DC_BUILD_DIR=build-inner' "$work/inner-make-args"

set +e
CONTAINER_RUNTIME="$work/bin/mock-docker" \
    bash "$repo/tools/in-container.sh" host-test > "$work/rejected.txt" 2>&1
rejected_status=$?
CONTAINER_RUNTIME=missing-container-runtime \
    bash "$repo/tools/in-container.sh" dreamcast-build > "$work/missing-runtime.txt" 2>&1
runtime_status=$?
set -e
[[ "$rejected_status" == 2 && "$runtime_status" == 2 ]]
grep -Fq 'Only Dreamcast build targets may run in the KOS container' "$work/rejected.txt"
grep -Fq 'Container runtime not found:' "$work/missing-runtime.txt"

make -s -n -C "$repo" in-container TARGET=dreamcast-build > "$work/make-dispatch-default.txt"
grep -Fq 'DC_BUILD_DIR="build-container"' "$work/make-dispatch-default.txt"
make -s -n -C "$repo" in-container TARGET=dreamcast-build DC_BUILD_DIR=build-custom > "$work/make-dispatch.txt"
grep -Fq 'tools/in-container.sh "dreamcast-build"' "$work/make-dispatch.txt"
grep -Fq 'TARGET=dreamcast-build' "$work/make-dispatch.txt"
grep -Fq 'DC_BUILD_DIR=build-custom' "$work/make-dispatch.txt"
make -s -n -C "$repo" in-container TARGET=dreamcast-build CONTAINER_DC_BUILD_DIR=build-by-variable > "$work/make-dispatch-variable.txt"
grep -Fq 'DC_BUILD_DIR="build-by-variable"' "$work/make-dispatch-variable.txt"
make -s -n -C "$repo" dreamcast-build > "$work/make-build.txt"
grep -Fq 'cmake -S . -B build-dreamcast -DCMAKE_BUILD_TYPE=Release' "$work/make-build.txt"
grep -Fq 'cmake --build build-dreamcast --verbose' "$work/make-build.txt"

printf 'KOS container dispatcher tests passed\n'
