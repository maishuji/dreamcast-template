HOST_BUILD_DIR ?= build-host
HOST_CMAKE_GENERATOR ?= Ninja
DC_IP ?= 192.168.0.84 # Please set the IP address of your dreamcast here ( or through env var DC_IP )
DC_BUILD_DIR ?= build-dreamcast
DC_CMAKE_GENERATOR ?= Unix Makefiles

.PHONY: all host-configure host-build host-test dreamcast-configure dreamcast-build run-dc run-dc-gdb lint clean build-cmake-verbose

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
