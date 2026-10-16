#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/bin" "$work/logs"
printf 'mock CDI\n' > "$work/game.cdi"

cat > "$work/bin/mock-docker" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$MOCK_DOCKER_ARGS"
exit "${MOCK_DOCKER_STATUS:-0}"
MOCK
cat > "$work/bin/mock-flycast" <<'MOCK'
#!/usr/bin/env bash
printf 'Flycast args: <%s> <%s> <%s>\n' "$1" "$2" "$3"
: > "$MOCK_FLYCAST_RAN"
MOCK
chmod +x "$work/bin/mock-docker" "$work/bin/mock-flycast"

MOCK_DOCKER_ARGS="$work/docker-args" MOCK_FLYCAST_RAN="$work/flycast-ran" \
CONTAINER_RUNTIME="$work/bin/mock-docker" FLYCAST_BIN="$work/bin/mock-flycast" \
DC_CDI="$work/game.cdi" FLYCAST_LOG_DIR="$work/logs" KOS_IMAGE='test/kos:tag' \
    bash "$repo/tools/build-flycast.sh" > "$work/success.txt" 2>&1
grep -Fxq 'test/kos:tag' "$work/docker-args"
grep -Fxq -- "--volume" "$work/docker-args"
grep -Fxq "$repo:/workspace" "$work/docker-args"
grep -Fq 'source /opt/toolchains/dc/kos/environ.sh && make dreamcast-configure && make dreamcast-cdi' "$work/docker-args"
test -f "$work/flycast-ran"
grep -Fq 'Flycast exited normally.' "$work/success.txt"

rm -f "$work/flycast-ran"
set +e
MOCK_DOCKER_ARGS="$work/docker-args" MOCK_FLYCAST_RAN="$work/flycast-ran" \
MOCK_DOCKER_STATUS=19 CONTAINER_RUNTIME="$work/bin/mock-docker" \
FLYCAST_BIN="$work/bin/mock-flycast" DC_CDI="$work/game.cdi" \
FLYCAST_LOG_DIR="$work/logs" bash "$repo/tools/build-flycast.sh" > "$work/build-failure.txt" 2>&1
build_status=$?
MOCK_DOCKER_ARGS="$work/docker-args" MOCK_FLYCAST_RAN="$work/flycast-ran" \
CONTAINER_RUNTIME="$work/bin/mock-docker" FLYCAST_BIN="$work/bin/mock-flycast" \
DC_CDI="$work/missing.cdi" bash "$repo/tools/build-flycast.sh" > "$work/missing-cdi.txt" 2>&1
cdi_status=$?
REMOTE_CONTAINERS=true CONTAINER_RUNTIME="$work/bin/mock-docker" \
FLYCAST_BIN="$work/bin/mock-flycast" DC_CDI="$work/game.cdi" \
    bash "$repo/tools/build-flycast.sh" > "$work/container.txt" 2>&1
container_status=$?
set -e
[[ "$build_status" == 19 && "$cdi_status" == 1 && "$container_status" == 2 ]]
[[ ! -e "$work/flycast-ran" ]]
grep -Fq 'requested CDI is missing or empty on the host' "$work/missing-cdi.txt"
grep -Fq 'make flycast must run on the host' "$work/container.txt"
printf 'Build-and-run Flycast tests passed\n'
