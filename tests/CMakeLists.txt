cmake_minimum_required(VERSION 3.11.0)

# Create test executable
add_executable(my_module_tests
    test_my_module.cpp
    test_main.cpp
    ${CMAKE_SOURCE_DIR}/src/my_module/game_utils.cpp
)

# Link libraries
target_link_libraries(my_module_tests
    PRIVATE
        gtest
        gtest_main
)

# Include directories (none needed for basic tests)
target_include_directories(my_module_tests
     PRIVATE
         ${CMAKE_SOURCE_DIR}/src/my_module/include
)

# Add source files that tests depend on (none needed for basic tests)
# target_sources(my_module_tests
#     PRIVATE
#         ${CMAKE_SOURCE_DIR}/src/my_module/main.cpp
# )

# Set C++ standard
set_target_properties(my_module_tests
    PROPERTIES
        CMAKE_CXX_STANDARD 20
        CXX_EXTENSIONS OFF
)

# Discover tests
include(GoogleTest)
gtest_discover_tests(my_module_tests)


# Add custom test target for convenience
add_custom_target(run_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --verbose
    DEPENDS my_module_tests
    COMMENT "Running unit tests"
)
