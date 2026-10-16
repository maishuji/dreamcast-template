# Run Flycast and inspect serial logs

## One-command host workflow

From a host terminal at the repository root, run:

```sh
make flycast
```

This runs the configured KOS toolchain image in a disposable Docker container, builds the CDI in the shared workspace, then launches Flycast on the host. The image defaults to the same tag as `.devcontainer/devcontainer.json`; override it with `KOS_IMAGE=...` only when intentionally using another compatible toolchain image. Docker must be installed and usable by your host user. The host also needs a graphical session and either a native `flycast` executable or the `org.flycast.Flycast` Flatpak. For a Flatpak, the launcher grants read-only access to the CDI directory for this run.

The container uses the host UID/GID and mounts the repository at `/workspace`, so build outputs are written back to the checkout without root-owned files. It sources KOS's environment setup, configures the Dreamcast build, and creates `out/my_module.cdi`. After the container exits successfully, the host verifies that the selected CDI exists and is non-empty before starting Flycast. If the build fails, Flycast is not launched. The host log stays in `.artifacts/flycast/`.

`make flycast` is deliberately host-only: it refuses to run inside a Dev Container because that container normally has neither the host's desktop session nor access to its Flycast installation. From inside the Dev Container, use two terminals:

```sh
# Dev Container terminal
make dreamcast-configure
make dreamcast-cdi

# Host terminal, at the same locally shared workspace
make flycast-logs
```

This two-terminal path depends on the CDI being visible at the same workspace path on the host. Remote or volume-backed Dev Containers may not share files with the host; for those setups, copy the CDI to a host-accessible directory and pass its path using `DC_CDI=/path/to/game.cdi` to `make flycast-logs`.

`make flycast-logs` only launches an existing CDI; it does not build. The default is `out/my_module.cdi`. For example, launch a different already-built image with `make flycast-logs DC_CDI=/absolute/path/to/game.cdi`. `DC_CDI` can also select the image for `make flycast`, but the container still builds the template's default `out/my_module.cdi`. Close Flycast (or quit the guest) to finish the run.

Each run keeps combined stdout/stderr in a unique `.artifacts/flycast/run.XXXXXXXX/flycast.log` file. The path is printed before launch and again on exit, including a nonzero exit. These artifacts are ignored by Git. The launcher passes `-config 'config:Debug.SerialConsoleEnabled=yes'` *before* the CDI to request serial-console forwarding; it does not change Flycast's saved configuration.

To select a non-default toolchain container or native Flycast executable:

```sh
make flycast KOS_IMAGE=registry.example/kos-image:tag FLYCAST_BIN=/path/to/flycast
```

The image override should match the KOS environment used by the project. `FLYCAST_LOG_DIR` overrides the artifact directory. The launcher tries the native `flycast` command first, then the installed Flatpak; `FLYCAST_BIN` forces an executable. The CDI path can contain spaces.

## Guest logs versus emulator logs

Flycast messages such as `REIOS: Booting up` indicate that the emulator started, **not** that your game's logs arrived. Guest `printf()`/`dbglog()` goes through the currently selected KOS `dbgio` device. The starter example prints `dreamcast-template: booted`, `renderer-ready`, `frame-loop-started`, and `normal-shutdown` and flushes each marker. Its `normal-shutdown` marker appears only if you quit the game normally (Space or the right-face gamepad button in the starter code); closing the emulator early will not produce it. Early KOS startup output may instead be visible in the emulated framebuffer. Do not force the KOS `scif` device on every build: physical serial writes can time out without a serial connection, and `dcload-ip` may use another console route.

Optionally require one exact guest marker when the run exits:

```sh
make flycast-logs FLYCAST_REQUIRED_MARKER='dreamcast-template: renderer-ready'
```

A missing marker produces a distinct failure and keeps the log. This is a **serial-log check**, not a rendered-frame test or a guarantee that guest execution succeeded. Omit the marker requirement if the current KOS route does not forward serial output; consult the Flycast window and the saved log separately. Flycast v2.7 with the corrected `config:` setting forwarded guest KOS startup text in the source project, but that does not establish the transport on every host or KOS configuration. The launch-only path can be tested without starting an emulator using `make test-flycast-launcher` (mock native and Flatpak commands). The host build-and-run dispatcher can be tested with mocked Docker and Flycast commands using `make test-build-flycast`. For real hardware, use `make run-dc` and inspect the dcload/serial console rather than this emulator launcher. For background on the option, see [Flycast's configuration reference](https://github.com/TheArcadeStriker/flycast-wiki/wiki/Configuration-files-and-command-line-parameters).
