# Dreamcast KOS Project Template

This repository provides a template for developing Dreamcast homebrew applications using the KallistiOS (KOS) framework. It includes a pre-configured development environment, build system, and example code to help you get started quickly.

## Features

- **Pre-configured Toolchain**: Uses a CMake-based build system with a Dreamcast-specific toolchain.
- **Dual-Target Workflow**: Supports Linux host builds for local iteration and Dreamcast builds for packaging and hardware testing.
- **Devcontainer Support**: Includes a development container configuration for a consistent development environment.
- **GitHub Actions Integration**: Automates builds using a pre-configured GitHub Actions workflow.
- **Example Code**: A simple 3D cube rendering example using `raylib` and KOS.
- **ROMDISK and CDI Generation**: Automatically generates ROMDISK and CDI images for Dreamcast testing.
- **Flycast Workflow**: Builds the CDI in the KOS container, launches Flycast on the host, and retains emulator/guest serial logs.
- **No In-Source Builds**: Enforces clean build practices.

## Prerequisites

Before using this template, if you are not planning to use the configured devcontainer, ensure you have the following installed:

- [KallistiOS (KOS)](https://github.com/KallistiOS/KallistiOS) installed and configured.
- Different tools for building and testing:
  - `mkdcdisc` (for creating CDI images from elf file).
- CMake (minimum version 3.11.0).
- A C++20 compiler and `raylib` development libraries for Linux host builds.

Else, you can use the provided devcontainer configuration to set up a consistent development environment.
- Visual Studio Code (with the Dev Containers extension).
- Docker (for the development container).

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/dreamcast-template.git
cd dreamcast-template
```

### 2. Configure the Development Environment

#### Option 1: Using Devcontainer (Recommended)
    1. Open the project in Visual Studio Code.
    2. Install the Dev Containers extension.
    3. Reopen the project in the container when prompted.
#### Option 2: Manual Setup

If you prefer not to use the devcontainer, ensure the following tools and dependencies are installed and configured on your system:

1. **KallistiOS (KOS)**  
   - Install and configure [KallistiOS (KOS)](https://github.com/KallistiOS/KallistiOS), the Dreamcast homebrew development framewor;, along with the toolchain.

2. **Kos-Ports**  
   - Install and configure [Kos-Ports](https://github.com/KallistiOS/kos-ports), a collection of libraries and tools for KOS development.

3. **CMake**  
   - Install [CMake](https://cmake.org/) (minimum version 3.11.0) for managing the build process.

4. **Mkdcdisc**
    - Install [mkdcdisc](https://gitlab.com/simulant/mkdcdisc.git), a tool for creating CDI images from ELF files. This tool is typically included with the KallistiOS installation.
5. **Other tools**
    - You may refer to this [Dockerfile](https://github.com/maishuji/dreamcast-kos-docker/blob/main/kos-ready/Dockerfile) for other tools provided in the devcontainer.
        - Ensure the `MKDCDISC` tool is available in your system.

6. **Source the KOS environment setup script**:
```bash
source /opt/toolchains/dc/kos/environ.sh
```

### 3. Build the Project

Use separate build directories for Linux host and Dreamcast targets.

#### Linux host build

Use the host path for local iteration and unit tests.

```bash
make host-configure
make host-build
make host-test
```

Equivalent raw CMake commands:

```bash
cmake -S . -B build-host -G Ninja
cmake --build build-host --target my_module
ctest --test-dir build-host --output-on-failure
```

#### Dreamcast build

Source the KOS environment first, then configure the Dreamcast target with `Unix Makefiles`.

```bash
source /opt/toolchains/dc/kos/environ.sh
make dreamcast-configure
make dreamcast-build
```

Equivalent raw CMake commands:

```bash
source /opt/toolchains/dc/kos/environ.sh
cmake -S . -B build-dreamcast -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=toolchains/dreamcast.cmake
cmake --build build-dreamcast --verbose
```

Do not use the Ninja generator for Dreamcast builds. This template treats `Unix Makefiles` as the supported Dreamcast path because Ninja is a known problematic configuration there.

#### Run in Flycast with logging

From a host terminal at the repository root (with Docker, a graphical session, and Flycast installed on the host), build with the configured KOS image and launch Flycast on the host. If Flycast is missing, follow the [host installation steps](docs/flycast.md#install-flycast-on-the-host) first:

```bash
make flycast
```

The target runs the KOS build in a temporary container, then launches the native `flycast` binary or installed `org.flycast.Flycast` Flatpak on the host. It retains combined output in `.artifacts/flycast/`. Flycast boot messages do not prove that guest KOS logs were captured.

If you are already working inside the Dev Container, use `make dreamcast-configure` and `make dreamcast-cdi` there, then run `make flycast-logs` from a host terminal opened at the same shared workspace. See the [Flycast logging guide](docs/flycast.md) for details and limitations. Running on real hardware uses the separate `run-dc` target below.

#### Run on hardware

After a Dreamcast build completes, you can send the ELF over the network:

```bash
make run-dc DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.84
```

For the GDB-enabled path:

```bash
make run-dc-gdb DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.84
```

For DHCP setup and troubleshooting when the Dreamcast does not receive an IP address, see [Debugging the Dreamcast network connection](docs/network-debugging.md).

## Project Structure

```plaintext
dc-template/
├── .devcontainer/         # Devcontainer configuration
├── .github/workflows/     # GitHub Actions workflow
├── .vscode/               # VS Code settings and CMake kits
├── build-host/            # Recommended Linux host build directory (generated)
├── build-dreamcast/       # Recommended Dreamcast build directory (generated)
├── cmake/                 # CMake modules
├── src/                   # Source code
│   └── my_module/         # Example module
│       ├── main.cpp       # Example application
│       └── romdisk/       # ROMDISK assets
├── toolchains/            # Dreamcast toolchain file
├── out/                   # Output directory for CDI images
├── LICENSE                # License file
├── Makefile               # Makefile for additional targets (lint, run dc-tool-ip)
└── README.md              # Project documentation
```

## Example Code
The included example (`src/my_module/main.cpp`) demonstrates:

- Initializing a 3D rendering window with raylib.
- Handling Dreamcast controller input.
- Rendering a rotating 3D cube.

## GitHub Actions
This template includes a GitHub Actions workflow (.github/workflows/github-actions.yml) to automate builds. The workflow:

    1. Runs in a containerized Dreamcast development environment.
    2. Builds the Dreamcast target using the provided toolchain and the `Unix Makefiles` generator.
    3. Runs on both pushes and pull requests.
    4. Outputs the build artifacts.

## License
This template is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Contributing
Contributions are welcome! Feel free to open issues or submit pull requests to improve this template.

## Resources
- [KallistiOS Documentation](https://www.kallistios.org/)
- [Dreamcast Development Wiki](https://www.dreamcast.wiki/)
- [raylib Documentation](https://www.raylib.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CMake Documentation](https://cmake.org/documentation/)
