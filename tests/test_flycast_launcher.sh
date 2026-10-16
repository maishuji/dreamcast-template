#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/cdi with spaces" "$work/bin"
cdi="$work/cdi with spaces/game.cdi"
: > "$cdi"

cat > "$work/bin/mock-flycast" <<'MOCK'
#!/usr/bin/env bash
printf 'ARGS: <%s> <%s> <%s>\n' "$1" "$2" "$3"
printf 'REIOS: Booting up\n'
if [[ "${EMIT_GUEST:-1}" == 1 ]]; then
    printf 'dreamcast-template: renderer-ready\n'
fi
exit "${MOCK_STATUS:-0}"
MOCK
chmod +x "$work/bin/mock-flycast"

DC_CDI="$cdi" FLYCAST_BIN="$work/bin/mock-flycast" FLYCAST_LOG_DIR="$work/logs" \
    FLYCAST_REQUIRED_MARKER='dreamcast-template: renderer-ready' \
    bash "$repo/tools/run-flycast.sh" > "$work/success.txt"
grep -Fq 'Guest marker found: dreamcast-template: renderer-ready' "$work/success.txt"
grep -Fq "<${cdi}>" "$work/success.txt"
grep -RFq 'ARGS: <-config> <config:Debug.SerialConsoleEnabled=yes>' "$work/logs"

set +e
DC_CDI="$cdi" FLYCAST_BIN="$work/bin/mock-flycast" FLYCAST_LOG_DIR="$work/logs" \
    EMIT_GUEST=0 FLYCAST_REQUIRED_MARKER='dreamcast-template: renderer-ready' \
    bash "$repo/tools/run-flycast.sh" > "$work/no-marker.txt" 2>&1
marker_status=$?
DC_CDI="$cdi" FLYCAST_BIN="$work/bin/mock-flycast" FLYCAST_LOG_DIR="$work/logs" \
    MOCK_STATUS=17 bash "$repo/tools/run-flycast.sh" > "$work/failure.txt" 2>&1
exit_status=$?
DC_CDI="$work/missing.cdi" FLYCAST_BIN="$work/bin/mock-flycast" \
    bash "$repo/tools/run-flycast.sh" > "$work/missing.txt" 2>&1
missing_status=$?
set -e
[[ "$marker_status" == 1 && "$exit_status" == 17 && "$missing_status" == 2 ]]
grep -Fq 'Guest marker not found:' "$work/no-marker.txt"
grep -Fq 'Flycast exited with status 17.' "$work/failure.txt"
grep -Fq 'CDI not found:' "$work/missing.txt"
[[ $(find "$work/logs" -name flycast.log | wc -l) == 3 ]]

cat > "$work/bin/flatpak" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == info ]]; then exit 0; fi
printf 'FLATPAK: <%s> <%s> <%s> <%s> <%s>\n' "$1" "$2" "$3" "$4" "$5"
MOCK
chmod +x "$work/bin/flatpak"
DC_CDI="$cdi" FLYCAST_LOG_DIR="$work/flatpak-logs" PATH="$work/bin:/usr/bin:/bin" \
    bash "$repo/tools/run-flycast.sh" > "$work/flatpak.txt"
grep -Fq "FLATPAK: <run> <--filesystem=$work/cdi with spaces:ro> <org.flycast.Flycast> <-config> <config:Debug.SerialConsoleEnabled=yes>" "$work/flatpak.txt"
printf 'Flycast launcher tests passed\n'
