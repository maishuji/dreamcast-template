# Build Dreamcast targets from the host

Use this workflow when you want to build the Dreamcast target without opening or working in a Dev Container. Make starts a temporary KOS toolchain container, runs the selected Dreamcast Make target there, and writes build outputs into this checkout.

## Prerequisites

- Run the command from this repository's root directory.
- Install Docker, or a compatible container runtime, and make sure your user can run it. Set `CONTAINER_RUNTIME` if the executable is not named `docker`.
- The default image is `maishuji/dc-kos-image:15.2.1-dev-08feb26-gdb-kp08feb26`, matching `.devcontainer/devcontainer.json`. The runtime downloads the image if it is not already available locally, so first use requires access to the image registry.

You do **not** need to install KallistiOS, the Dreamcast cross-compiler, CMake, or `mkdcdisc` on the host for this workflow; those are supplied by the container image. The host does not need a graphical session or Flycast unless you also want to run the resulting CDI in the emulator.

## Build the default Dreamcast target

From a regular host terminal:

```sh
make in-container TARGET=dreamcast-build
```

The `dreamcast-build` target configures `build-container` with the supported `Unix Makefiles` generator, then compiles the Dreamcast target. On a fresh build directory, CDI generation is enabled by default, so the build also creates and publishes the default CDI. If an existing CMake cache has CDI generation disabled, use the explicit packaging steps below.

The outputs are visible in the checkout:

- ELF: `build-container/src/my_module/my_module.elf`
- Build-local CDI: `build-container/src/my_module/my_module.cdi`
- Published CDI for manual launch: `out/my_module.cdi`

The dispatcher mounts the checkout at `/workspace` and runs the container as your host UID and GID, so generated files remain in the mounted checkout without being owned by container root. The dispatcher only accepts Dreamcast build targets (`dreamcast-*`); host tests, Flycast launchers, and hardware transfer targets stay on the host.

## Configure or package explicitly

To configure without building:

```sh
make in-container TARGET=dreamcast-configure
```

To explicitly enable CDI generation and build its target after configuring:

```sh
make in-container TARGET=dreamcast-configure
make in-container TARGET=dreamcast-cdi
```

The explicit configure step is needed when starting with a new build directory. `dreamcast-cdi` turns `ENABLE_CDI_IMAGE` on in the selected CMake cache and builds the CDI target; it preserves the existing toolchain configuration in that cache.

## Choose a build directory or image

Host-dispatched builds use `build-container` by default, separate from the Dev Container's `build-dreamcast` and Flycast's `build-flycast`. CMake stores absolute source paths in its cache, so do not reuse one build directory from different container mount locations. To choose another directory for one invocation:

```sh
make in-container TARGET=dreamcast-build DC_BUILD_DIR=build-host-kos
```

Or change the dispatcher's default directory for a command:

```sh
make in-container TARGET=dreamcast-build CONTAINER_DC_BUILD_DIR=build-host-kos
```

To use another compatible KOS image or container runtime:

```sh
make in-container TARGET=dreamcast-build KOS_IMAGE=your-kos-image:tag
make in-container TARGET=dreamcast-build CONTAINER_RUNTIME=podman
```

An alternate image must provide the KOS environment script at `/opt/toolchains/dc/kos/environ.sh` and the toolchain and packaging tools expected by the project. `DC_BUILD_DIR`, `DC_CMAKE_GENERATOR`, and other Make variable overrides are forwarded to the target running in the container.

## Use an existing Dev Container or launch Flycast

Inside the configured Dev Container, no nested container is started. Source the KOS environment when it is not already available in your shell, then run the build directly:

```sh
source /opt/toolchains/dc/kos/environ.sh
make dreamcast-build
```

`make flycast` is a separate host workflow: it builds in the KOS image and then launches Flycast on the host. To launch a CDI that was built earlier, use `make flycast-logs`. See [Run Flycast and inspect serial logs](flycast.md) for emulator installation, launch, and guest-log details.
