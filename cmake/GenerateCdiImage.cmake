# Define the flag to enable/disable the target for CDI image generation
option(ENABLE_CDI_IMAGE "Enable CDI image generation" ON)

# ---- CDI Image generation ----
function(add_generate_cdi_image_for_target target_name)

    if(ENABLE_CDI_IMAGE)

        if(NOT DEFINED MKDCDISC)
            message(FATAL_ERROR "MKDCDISC tool not defined. Please set it with set(MKDCDISC path_to_tool)")
        endif()

        set(ELF_FILE "${CMAKE_CURRENT_BINARY_DIR}/${target_name}.elf")
        set(OUTPUT_DIR "${PROJECT_SOURCE_DIR}/out")
        set(CDI_FILE "${OUTPUT_DIR}/${target_name}.cdi")


        # Ensure the output directory exists
        file(MAKE_DIRECTORY ${OUTPUT_DIR})

        message(STATUS "Generating CDI: ${CDI_FILE}")
        add_custom_command(
            OUTPUT ${CDI_FILE}
            COMMAND ${MKDCDISC} -e ${ELF_FILE} -o ${CDI_FILE} -n ${target_name} -v 3
            DEPENDS ${target_name}
            COMMENT "Making CDI image"
        )

        # Add a custom target to depend on the CDI image generation
        add_custom_target(${target_name}_cdi ALL
            DEPENDS ${CDI_FILE}
        )

    else()
        message(STATUS "CDI image generation is disabled for target: ${target_name}")
    endif()
endfunction()