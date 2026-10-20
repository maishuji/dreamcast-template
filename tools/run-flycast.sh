#!/usr/bin/env bash
set -euo pipefail

cdi=${DC_CDI:-out/my_module.cdi}
if [[ ! -f "$cdi" ]]; then
    echo "CDI not found: $cdi (build it with make dreamcast-cdi in the KOS environment, or set DC_CDI)" >&2
    exit 2
fi
cdi=$(realpath "$cdi")
cdi_dir=$(dirname "$cdi")

if [[ -n "${FLYCAST_BIN:-}" ]]; then
    if ! command -v "$FLYCAST_BIN" >/dev/null 2>&1; then
        printf 'Flycast executable not found: %s\nSet FLYCAST_BIN to an installed executable, or omit it to use Flycast on PATH or the Flatpak. See docs/flycast.md.\n' "$FLYCAST_BIN" >&2
        exit 2
    fi
    launcher=("$FLYCAST_BIN")
elif command -v flycast >/dev/null 2>&1; then
    launcher=(flycast)
elif command -v flatpak >/dev/null 2>&1 && flatpak info org.flycast.Flycast >/dev/null 2>&1; then
    # Grant only the CDI's directory; the Flatpak needs access to the image.
    launcher=(flatpak run "--filesystem=$cdi_dir:ro" org.flycast.Flycast)
else
    printf '%s\n' \
        'No usable Flycast found on the host (native flycast on PATH or org.flycast.Flycast Flatpak).' \
        'Install Flatpak and configure Flathub, then run: flatpak install flathub org.flycast.Flycast' \
        'Or install native Flycast on PATH, or set FLYCAST_BIN=/absolute/path/to/flycast.' \
        'See docs/flycast.md#install-flycast-on-the-host for setup and troubleshooting.' >&2
    exit 2
fi

log_dir=${FLYCAST_LOG_DIR:-.artifacts/flycast}
mkdir -p "$log_dir"
run_dir=$(mktemp -d "$log_dir/run.XXXXXXXX")
log_file="$run_dir/flycast.log"
printf 'Flycast log: %s\n' "$log_file"

# -config applies to this run only; emulator output does not itself prove
# that the guest KOS dbgio route reaches the emulated serial console.
set +e
"${launcher[@]}" -config 'config:Debug.SerialConsoleEnabled=yes' "$cdi" 2>&1 | tee "$log_file"
pipeline_status=("${PIPESTATUS[@]}")
set -e
status=${pipeline_status[0]}
if (( pipeline_status[1] != 0 )); then
    printf 'Could not write Flycast log: %s\n' "$log_file" >&2
    exit "${pipeline_status[1]}"
fi

if (( status != 0 )); then
    printf 'Flycast exited with status %s. Log: %s\n' "$status" "$log_file" >&2
    exit "$status"
fi

if [[ -n "${FLYCAST_REQUIRED_MARKER:-}" ]]; then
    if ! grep -Fq -- "$FLYCAST_REQUIRED_MARKER" "$log_file"; then
        printf 'Guest marker not found: %s\nLog: %s\nCheck the guest dbgio route and log level; Flycast boot messages are not guest output.\n' \
            "$FLYCAST_REQUIRED_MARKER" "$log_file" >&2
        exit 1
    fi
    printf 'Guest marker found: %s\n' "$FLYCAST_REQUIRED_MARKER"
fi
printf 'Flycast exited normally. Log: %s\n' "$log_file"
