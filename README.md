# Dreamcast KOS Project Template

This repository provides a template for developing Dreamcast homebrew applications using the KallistiOS (KOS) framework. It includes a pre-configured development environment, build system, and example code to help you get started quickly.

## Features

- **Pre-configured Toolchain**: Uses a CMake-based build system with a Dreamcast-specific toolchain.
- **Dual-Target Workflow**: Supports Linux host builds for local iteration and Dreamcast builds for packaging and hardware testing.
- **Devcontainer Support**: Includes a development container configuration for a consistent development environment.
- **GitHub Actions Integration**: Automates builds using a pre-configured GitHub Actions workflow.
- **Example Code**: A simple 3D cube rendering example using `raylib` and KOS.
- **ROMDISK and CDI Generation**: Automatically generates ROMDISK and CDI images for Dreamcast testing.
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

#### Run on hardware

After a Dreamcast build completes, you can send the ELF over the network:

```bash
make run-dc DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.84
```

For the GDB-enabled path:

```bash
make run-dc-gdb DC_BUILD_DIR=build-dreamcast DC_IP=192.168.0.84
```

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



## Debugging Dreamcast Network Connection (DHCP Setup)

To allow your Dreamcast to get an IP address automatically over Ethernet (via BBA), you’ll need to set up a lightweight DHCP server using `dnsmasq`.

### 1. Install `dnsmasq`

```bash
sudo apt install dnsmasq
```

---

### 2. Configure `dnsmasq`

Create a configuration file specifically for the Dreamcast setup:

```bash
sudo nano /etc/dnsmasq.d/dreamcast.conf
```

Add the following content:

```ini
interface=<your-dreamcast-interface>
bind-interfaces

dhcp-range=192.168.0.50,192.168.0.150,12h
dhcp-option=3,192.168.0.1
dhcp-option=6,8.8.8.8,1.1.1.1
```

🔁 **Replace** `<your-dreamcast-interface>` with the name of your Ethernet-to-USB adapter or relevant NIC (e.g., `enxa0cec85e02d8`).  
You can find it using:

```bash
ip addr
```

Look for the interface that is **connected to the Dreamcast** (usually shows as `DOWN` when unplugged, `UP` when plugged in).

---

### 3. Restart `dnsmasq`

```bash
sudo systemctl restart dnsmasq
```

---

### 4. Find the Dreamcast IP

While your Dreamcast is booted into `dcload-ip` (or a network-enabled app/game):

```bash
sudo journalctl -u dnsmasq -f
```

Look for a block like:

```text
DHCPDISCOVER(enx...) ...
DHCPOFFER(enx...) 192.168.0.85 ...
DHCPREQUEST ...
DHCPACK ...
```

The IP address offered (e.g., `192.168.0.85`) is the one you’ll use with tools like `dc-tool-ip`.

## Connection Troubleshooting

### Check the journal for dnsmasq

It provides useful information about the DHCP process and any potential issues.
```bash
sudo journalctl -u dnsmasq -f
```

### Issue : dnsmasq.service failed to start
If you see an error like this:

```text
Apr 22 22:55:33 daoliangshu-ux430uq dnsmasq[36544]: unknown interface <you-interface>
Apr 22 22:55:33 daoliangshu-ux430uq dnsmasq[36544]: FAILED to start up
```
It means that the interface is not available when dnsmasq starts.

#### The interface is not up
It can means that the <interface> is not up. 
Checks with:
```bash
ip addr show <your-dreamcast-interface>
```
Example output:
```text
$ ip addr show enxa0cec85e02d8
17: enxa0cec85e02d8: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether a0:ce:c8:5e:02:d8 brd ff:ff:ff:ff:ff:ff
```
Here we see the interface exists, but is down.
In that case, you can bring it up with:
```bash
sudo ip link set enxa0cec85e02d8 up
```
Then restart dnsmasq:
```bash
sudo systemctl restart dnsmasq
```

#### The interface does not exist

Check if the interface name is correct in `/etc/dnsmasq.d/dreamcast.conf` (or whatever name you used for the configuration file).
Check if your device is connected to the Dreamcast and your laptop.

### Issue : dcload-ip is not receiving an IP address

If your Dreamcast isn’t being assigned an IP address, you can check what's going wrong by inspecting the system journal:

```bash
sudo journalctl -u dnsmasq -f
```

If you see a message like this:

```text
HCP packet received on <your-dreamcast-interface> which has no address
```
It means that your Dreamcast is sending a DHCP request, but your network adapter (usually the USB-Ethernet interface) doesn’t have an IP address assigned to it — so dnsmasq can’t respond.

To fix this, assign a static IP address to the adapter:

```bash
sudo ip addr add 192.168.0.1/24 dev <your-dreamcast-interface>
sudo ip link set <your-dreamcast-interface> up
```

Then restart dnsmasq
```bash
sudo systemctl restart dnsmasq
```

Finally, verify that the IP address has been correctly assigned:
```bash
ip addr show <your-dreamcast-interface>
```

#### Summary of useful commands for debugging the connection to dc-tool-ip

1. Read the logs
```bash
sudo journalctl -u dnsmasq -f
```
2. Try to bring up the interface, assign an IP address
```bash
sudo ip link set enxa0cec85e02d8 up
sudo ip addr flush dev enxa0cec85e02d8
sudo ip addr add 192.168.0.1/24 dev enxa0cec85e02d8 # replace with your interface
```
3. Restart `dnsmasq`:
```bash
sudo systemctl restart dnsmasq
```