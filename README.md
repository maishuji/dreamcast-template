# Dreamcast KOS Project Template

A starter project for Sega Dreamcast homebrew using KallistiOS (KOS), CMake, and raylib. Build for Dreamcast from the host with the included KOS container workflow, use the Dev Container, or configure a native toolchain yourself.

## Getting Started

### 1. Get the template

Clone this repository or create your own copy using your preferred GitHub workflow:

```bash
git clone https://github.com/maishuji/dreamcast-template.git
cd dreamcast-template
```

### 2. Build for Dreamcast from the host

Install Docker (or a compatible container runtime) and make sure your user can run it. From the repository root, run:

```bash
make in-container TARGET=dreamcast-build
```

The command runs the KOS build in a temporary container; you do not need to open a Dev Container or install the KOS toolchain on the host. On first use, the container runtime downloads the configured KOS image. The default build outputs are:

- ELF: `build-container/src/my_module/my_module.elf`
- CDI: `build-container/src/my_module/my_module.cdi`
- A published copy of the CDI: `out/my_module.cdi`

See the [host-side container build guide](docs/container-build.md) for prerequisites, output paths, overrides, and troubleshooting. To run the CDI in Flycast, see [Run in Flycast](docs/flycast.md).

## Overview

This repository includes:

- CMake workflows for Linux host builds and Dreamcast cross-builds.
- A pinned KOS Dev Container and GitHub Actions build.
- A sample raylib application with controller input and a rotating 3D cube.
- ROMDISK and CDI generation.
- Optional Flycast launch and guest serial-log capture.
- Out-of-source build directories for host and Dreamcast targets.

The Dreamcast example and hardware paths are separate from the Linux host build and tests. A successful build or emulator run is not proof of real Dreamcast hardware behavior.

### Further reading

- [KallistiOS documentation](https://www.kallistios.org/) and the [KOS ports repository](https://github.com/KallistiOS/kos-ports)
- [Dreamcast Development Wiki](https://www.dreamcast.wiki/)
- [raylib documentation](https://www.raylib.com/)
- [CMake documentation](https://cmake.org/documentation/)
- [GitHub Actions documentation](https://docs.github.com/en/actions)

### Project structure

```text
dreamcast-template/
├── .devcontainer/        # Dev Container configuration
├── .github/workflows/    # CI build and script tests
├── .vscode/              # Editor and CMake settings
├── cmake/                # CDI generation and CMake helpers
├── docs/                 # Build, Flycast, and network guides
├── src/my_module/        # Example application and ROMDISK assets
├── tests/                # C++ and shell tests
├── tools/                # Host-side container and Flycast scripts
├── toolchains/           # Dreamcast toolchain configuration
├── out/                  # Published CDI images
├── CMakeLists.txt
├── Makefile
└── README.md
```

Build directories such as `build-host/`, `build-dreamcast/`, `build-container/`, and `build-flycast/` are generated locally and ignored by Git.

## Installation

Choose the environment that matches the task:

- **Dreamcast build from the host:** Docker or a compatible runtime that accepts the Docker CLI options used by the dispatcher. The KOS image supplies KOS, the cross-compiler, CMake, and `mkdcdisc`; no local KOS installation is needed. The image is pulled automatically when absent. See [Build Dreamcast targets from the host](docs/container-build.md).
- **Dev Container:** Visual Studio Code, the Dev Containers extension, and Docker. Open the repository and select **Reopen in Container**.
- **Manual Dreamcast toolchain:** install and configure KOS, the required kos-ports libraries, CMake, the Dreamcast cross-compiler, and `mkdcdisc`; source the KOS environment before configuring. See the [KallistiOS documentation](https://github.com/KallistiOS/KallistiOS) and the [KOS ports repository](https://github.com/KallistiOS/kos-ports).
- **Native Linux host build and tests:** CMake 3.11 or newer, a C++20 compiler, and Linux raylib development libraries. The host CMake configuration fetches GoogleTest v1.14.0 with CMake `FetchContent`, so a first-time configure needs access to its Git repository unless the dependency is already cached.

## Usage

### Linux host build and tests

Use this path for local iteration and unit tests; it does not build a Dreamcast binary:

```bash
make host-configure
make host-build
make host-test
```

Equivalent CMake commands:

```bash
cmake -S . -B build-host -G Ninja
cmake --build build-host --target my_module
ctest --test-dir build-host --output-on-failure
```

### Dreamcast build

From the host, build without entering the Dev Container:

```bash
make in-container TARGET=dreamcast-build
```

The dispatcher uses `build-container/` by default to keep its CMake cache separate from builds configured inside the Dev Container. To select a different directory:

```bash
make in-container TARGET=dreamcast-build DC_BUILD_DIR=build-host-kos
```

Inside the Dev Container, source the KOS environment if it is not already available in your shell, then build directly:

```bash
source /opt/toolchains/dc/kos/environ.sh
make dreamcast-build
```

The Dreamcast CMake workflow uses `Unix Makefiles`; do not select Ninja for Dreamcast builds. A fresh `dreamcast-build` also generates and publishes the CDI. If you need to re-enable CDI generation in an existing CMake cache, first configure the build directory, then build the CDI target:

```bash
make in-container TARGET=dreamcast-configure
make in-container TARGET=dreamcast-cdi
```

For the raw CMake commands, custom container images, and more detail, see the [host-side container build guide](docs/container-build.md).

### Run in Flycast

From a host terminal with Docker, a graphical session, and Flycast installed, build and launch the example with logging:

```bash
make flycast
```

If Flycast is missing, follow the [host installation steps](docs/flycast.md#install-flycast-on-the-host). `make flycast` builds in the KOS image and launches Flycast on the host. To launch an already-built CDI without rebuilding, use `make flycast-logs`. The [Flycast guide](docs/flycast.md) explains installation, log locations, and the difference between emulator output and guest KOS logs.

### Run on Dreamcast hardware

Build the ELF first, then send it to a Dreamcast running `dcload-ip` over a Broadband Adapter. The example uses the Dev Container build directory; replace the IP with the console's address. If you built from the host, use `DC_BUILD_DIR=build-container` instead. `dc-tool-ip` must be available on the host.

```bash
make run-dc DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.84
```

For DHCP setup, see [Debugging the Dreamcast network connection](docs/network-debugging.md). The GDB-enabled target is `make run-dc-gdb`; it requires a Debug build and a running GDB server in the application.

## Development / Testing

Run the C++ host tests with `make host-test` after configuring and building the host target. The Flycast and container-dispatcher scripts also have mock-based tests that do not start Docker or Flycast:

```bash
make test-flycast-launcher test-build-flycast test-in-container
```

GitHub Actions runs these script tests on an Ubuntu host runner and builds the Dreamcast target in a KOS container on pushes and pull requests. The workflow does not upload build artifacts. Emulator and hardware checks remain separate from CI.

## Contributing

Contributions are welcome. Open an issue or submit a pull request to improve the template.

## License

This template is licensed under the MIT License; see [`LICENSE`](LICENSE). Third-party dependencies and tools retain their own licenses.
