HOST_BUILD_DIR ?= build-host
HOST_CMAKE_GENERATOR ?= Ninja
DC_IP ?= 192.168.0.84 # Please set the IP address of your dreamcast here ( or through env var DC_IP )
DC_BUILD_DIR ?= build-dreamcast
FLYCAST_BUILD_DIR ?= build-flycast
DC_CMAKE_GENERATOR ?= Unix Makefiles
DC_TARGET ?= my_module
DC_CDI ?= out/$(DC_TARGET).cdi
CONTAINER_RUNTIME ?= docker
KOS_IMAGE ?= maishuji/dc-kos-image:15.2.1-dev-08feb26-gdb-kp08feb26

.PHONY: all host-configure host-build host-test dreamcast-configure dreamcast-build dreamcast-cdi flycast flycast-logs test-flycast-launcher test-build-flycast run-dc run-dc-gdb lint clean build-cmake-verbose

host-configure:
	cmake -S . -B $(HOST_BUILD_DIR) -G "$(HOST_CMAKE_GENERATOR)"

host-build:
	cmake --build $(HOST_BUILD_DIR) --target my_module

host-test:
	ctest --test-dir $(HOST_BUILD_DIR) --output-on-failure

dreamcast-configure:
	cmake -S . -B $(DC_BUILD_DIR) -DCMAKE_BUILD_TYPE=Release -G "$(DC_CMAKE_GENERATOR)" -DCMAKE_TOOLCHAIN_FILE=toolchains/dreamcast.cmake

dreamcast-build:
	cmake --build $(DC_BUILD_DIR) --verbose

# Re-enable CDI generation even when an existing cache has it disabled.
dreamcast-cdi:
	cmake -S . -B "$(DC_BUILD_DIR)" -DENABLE_CDI_IMAGE=ON
	cmake --build "$(DC_BUILD_DIR)" --target $(DC_TARGET)_cdi --verbose

# Build with the KOS image and launch its own CDI, not another build tree's out/ image.
flycast: DC_CDI = $(FLYCAST_BUILD_DIR)/src/$(DC_TARGET)/$(DC_TARGET).cdi
flycast:
	CONTAINER_RUNTIME="$(CONTAINER_RUNTIME)" KOS_IMAGE="$(KOS_IMAGE)" DC_BUILD_DIR="$(FLYCAST_BUILD_DIR)" DC_CDI="$(DC_CDI)" FLYCAST_BIN="$(FLYCAST_BIN)" FLYCAST_LOG_DIR="$(FLYCAST_LOG_DIR)" FLYCAST_REQUIRED_MARKER="$(FLYCAST_REQUIRED_MARKER)" bash tools/build-flycast.sh

# Launch an already-built CDI on the host and retain its logs.
flycast-logs:
	DC_CDI="$(DC_CDI)" FLYCAST_BIN="$(FLYCAST_BIN)" FLYCAST_LOG_DIR="$(FLYCAST_LOG_DIR)" FLYCAST_REQUIRED_MARKER="$(FLYCAST_REQUIRED_MARKER)" bash tools/run-flycast.sh

test-flycast-launcher:
	bash tests/test_flycast_launcher.sh

test-build-flycast:
	bash tests/test_build_flycast.sh

# This target is for running the program on dreamcast, given that you are using BBA or a LAN adapter
run-dc:
	dc-tool-ip -t $(DC_IP) -x $(DC_BUILD_DIR)/src/my_module/my_module.elf

# This target is for running the program on dreamcast with gdb
# It only works in Debug mode and requires that you have gdb_init() in your code to set up the gdb server
# Then you can attach the debugger using the config in .vscode/launch.json
run-dc-gdb:
	dc-tool-ip -g -t $(DC_IP) -x $(DC_BUILD_DIR)/src/my_module/my_module.elf

lint:
	cpplint --recursive src/

clean:
	rm -rf build/ build-*/

build-cmake-verbose: dreamcast-configure dreamcast-build
