# Using standard kos provided toolchain.cmake
include($ENV{KOS_BASE}/utils/cmake/kallistios.cmake) # For helper functions
include($ENV{KOS_BASE}/utils/cmake/kallistios.toolchain.cmake)

# Set the system root directory
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --sysroot=/opt/toolchains/dc/sh-elf/sh-elf -isystem /opt/toolchains/dc/sh-elf/sh-elf/include -isystem /opt/toolchains/dc/kos/include  -isystem /opt/toolchains/dc/sh-elf/sh-elf/include/c++/15.2.0/ -isystem /opt/toolchains/dc/sh-elf/sh-elf/include/c++/15.2.0/sh-elf/ -isystem /opt/toolchains/dc/kos-ports/include")


set(MKDCDISC "/usr/local/bin/mkdcdisc")
