DC_IP ?= 192.168.0.84 # Please set the IP address of your dreamcast here ( or through env var DC_IP )

.PHONY: all build run-dc lint clean
# This target is for running the program on dreamcast, given that you are using BBA or a LAN adapter
run-dc:
	dc-tool-ip -t $(DC_IP) -x build/src/my_module/my_module.elf

lint:
	cpplint --recursive src/

clean:
	rm -rf build/

build-cmake-verbose:
	cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -G "Ninja" -DCMAKE_TOOLCHAIN_FILE=toolchains/dreamcast.cmake
	cmake --build build -- -v
