# Using standard kos provided toolchain.cmake
#include($ENV{KOS_BASE}/utils/cmake/dreamcast.toolchain.cmake) <-- for older versions of kos
include($ENV{KOS_BASE}/utils/cmake/kallistios.cmake) # For helper functions
include($ENV{KOS_BASE}/utils/cmake/kallistios.toolchain.cmake)

set(MKDCDISC "/usr/local/bin/mkdcdisc")