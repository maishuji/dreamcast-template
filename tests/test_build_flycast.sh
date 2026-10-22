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
grep -Fxq 'DC_BUILD_DIR=build-flycast' "$work/docker-args"
make -s -n -C "$repo" flycast > "$work/make-default.txt"
grep -Fq 'DC_BUILD_DIR="build-flycast"' "$work/make-default.txt"
make -s -n -C "$repo" flycast FLYCAST_BUILD_DIR=build-flycast-custom > "$work/make-custom.txt"
grep -Fq 'DC_BUILD_DIR="build-flycast-custom"' "$work/make-custom.txt"
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
# A direct invocation without DC_CDI must require this build tree's CDI.
missing_build_dir="build-flycast-missing-${work##*/}"
set +e
MOCK_DOCKER_ARGS="$work/docker-args" CONTAINER_RUNTIME="$work/bin/mock-docker" \
    FLYCAST_BIN="$work/bin/mock-flycast" DC_BUILD_DIR="$missing_build_dir" DC_CDI= \
    bash "$repo/tools/build-flycast.sh" > "$work/missing-local-cdi.txt" 2>&1
missing_local_status=$?
set -e
[[ "$missing_local_status" == 1 ]]
grep -Fq "$missing_build_dir/src/my_module/my_module.cdi" "$work/missing-local-cdi.txt"
# Missing Flycast must stop before starting the container build.
mkdir -p "$work/no-flycast-bin"
for tool in bash dirname; do
    ln -s "$(command -v "$tool")" "$work/no-flycast-bin/$tool"
done
rm -f "$work/docker-args"
set +e
MOCK_DOCKER_ARGS="$work/docker-args" CONTAINER_RUNTIME="$work/bin/mock-docker" \
    FLYCAST_BIN= PATH="$work/no-flycast-bin" \
    bash "$repo/tools/build-flycast.sh" > "$work/no-flycast.txt" 2>&1
no_flycast_status=$?
set -e
[[ "$no_flycast_status" == 2 && ! -e "$work/docker-args" ]]
grep -Fq 'flatpak install flathub org.flycast.Flycast' "$work/no-flycast.txt"
# Exercise the real Makefile and CMake cache without needing the KOS toolchain.
mkdir -p "$work/project/out"
cat > "$work/project/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.11)
project(cdi_regression NONE)
option(ENABLE_CDI_IMAGE "Generate CDI" ON)
add_custom_target(my_module)
if(ENABLE_CDI_IMAGE)
    add_custom_target(my_module_cdi
        COMMAND "${CMAKE_COMMAND}" -E copy
            "${CMAKE_SOURCE_DIR}/fresh.cdi" "${CMAKE_SOURCE_DIR}/out/my_module.cdi"
        DEPENDS my_module)
endif()
CMAKE
printf 'new CDI\n' > "$work/project/fresh.cdi"
printf 'stale CDI\n' > "$work/project/out/my_module.cdi"
cmake -S "$work/project" -B "$work/project/build" -DENABLE_CDI_IMAGE=OFF > "$work/configure.txt"
make -C "$work/project" -f "$repo/Makefile" dreamcast-cdi DC_BUILD_DIR=build > "$work/cdi-build.txt"
grep -Fxq 'ENABLE_CDI_IMAGE:BOOL=ON' "$work/project/build/CMakeCache.txt"
cmp "$work/project/fresh.cdi" "$work/project/out/my_module.cdi"

# Build trees must not accept another tree's newer CDI as their own.
mkdir -p "$work/multi-tree"
cat > "$work/multi-tree/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.11)
project(cdi_build_isolation C)
add_executable(my_module main.c)
set_target_properties(my_module PROPERTIES SUFFIX ".elf")
target_compile_definitions(my_module PRIVATE VERSION=${VERSION})
include("${CDI_MODULE}")
add_generate_cdi_image_for_target(my_module)
CMAKE
printf 'int main(void) { return VERSION; }\n' > "$work/multi-tree/main.c"
cat > "$work/bin/mock-mkdcdisc" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
while (( $# )); do
    case "$1" in
        -e) input=$2; shift 2 ;;
        -o) output=$2; shift 2 ;;
        *) shift ;;
    esac
done
cp -- "$input" "$output"
MOCK
chmod +x "$work/bin/mock-mkdcdisc"
cmake -S "$work/multi-tree" -B "$work/multi-tree/build-b" -DVERSION=2 \
    -DCDI_MODULE="$repo/cmake/GenerateCdiImage.cmake" -DMKDCDISC="$work/bin/mock-mkdcdisc" > "$work/configure-b.txt"
cmake --build "$work/multi-tree/build-b" --target my_module > "$work/build-b.txt"
cmake -S "$work/multi-tree" -B "$work/multi-tree/build-a" -DVERSION=1 \
    -DCDI_MODULE="$repo/cmake/GenerateCdiImage.cmake" -DMKDCDISC="$work/bin/mock-mkdcdisc" > "$work/configure-a.txt"
cmake --build "$work/multi-tree/build-a" --target my_module_cdi > "$work/build-a.txt"
cmake --build "$work/multi-tree/build-b" --target my_module_cdi > "$work/cdi-build-b.txt"
cmp "$work/multi-tree/build-a/my_module.elf" "$work/multi-tree/build-a/my_module.cdi"
cmp "$work/multi-tree/build-b/my_module.elf" "$work/multi-tree/build-b/my_module.cdi"
cmp "$work/multi-tree/build-b/my_module.cdi" "$work/multi-tree/out/my_module.cdi"
# Republishing an unchanged build must still replace the other tree's out/ image.
cmake --build "$work/multi-tree/build-a" --target my_module_cdi > "$work/republish-a.txt"
cmp "$work/multi-tree/build-a/my_module.cdi" "$work/multi-tree/out/my_module.cdi"
cmake --build "$work/multi-tree/build-b" --target my_module_cdi > "$work/republish-b.txt"
cmp "$work/multi-tree/build-b/my_module.cdi" "$work/multi-tree/out/my_module.cdi"
grep -Fq 'DC_CDI="build-flycast/src/my_module/my_module.cdi"' "$work/make-default.txt"
grep -Fq 'DC_CDI="build-flycast-custom/src/my_module/my_module.cdi"' "$work/make-custom.txt"
printf 'Build-and-run Flycast tests passed\n'
