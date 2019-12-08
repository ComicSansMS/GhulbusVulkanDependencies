cmake_host_system_information(RESULT N_CORES QUERY NUMBER_OF_LOGICAL_CORES)
message("Using " ${N_CORES} " threads for building.")

if(GENERATOR)
    message("Using generator " ${GENERATOR})
    set(GENERATOR_OPTION -G ${GENERATOR})
endif()
if(ARCHITECTURE)
    message("Using target architecture " ${ARCHITECTURE})
    list(APPEND GENERATOR_OPTION -A ${ARCHITECTURE})
endif()
if(TOOLCHAIN)
    message("Using toolchain " ${TOOLCHAIN})
    list(APPEND GENERATOR_OPTION -T ${TOOLCHAIN})
endif()

if(NOT SKIP_GIT)
    find_package(Git REQUIRED)
    message("Updating submodules...")
    execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init)
endif()

function(build_cmake_project PROJECT_NAME CONFIGURE_OPTIONS)
    message("Building ${PROJECT_NAME}...")
    
    if(WIN32)
        set(CONFIGURATIONS Debug MinSizeRel Release RelWithDebInfo)
    else()
        set(CONFIGURATIONS Release)
    endif()
    message("${CMAKE_COMMAND} ${GENERATOR_OPTION} ${CONFIGURE_OPTIONS} -DCMAKE_INSTALL_PREFIX=install -S source -B build")
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${GENERATOR_OPTION} ${CONFIGURE_OPTIONS} -DCMAKE_INSTALL_PREFIX=install -S source -B build
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}
        RESULT_VARIABLE ${PROJECT_NAME}_CONFIGURE_RESULTS
    )

    if(NOT ${PROJECT_NAME}_CONFIGURE_RESULTS EQUAL 0)
        message(FATAL_ERROR "Error while configuring ${PROJECT_NAME}")
    endif()

    set(${PROJECT_NAME}_build_command "")
    foreach(c ${CONFIGURATIONS})
        list(APPEND ${PROJECT_NAME}_build_command COMMAND ${CMAKE_COMMAND} --build build -j ${N_CORES} --config ${c})
    endforeach()
    execute_process(
        ${${PROJECT_NAME}_build_command}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}
        RESULTS_VARIABLE ${PROJECT_NAME}_BUILD_RESULTS
    )
    foreach(result ${${PROJECT_NAME}_BUILD_RESULTS})
        if(NOT result EQUAL 0)
            message(FATAL_ERROR "Error while building ${PROJECT_NAME}")
        endif()
    endforeach()

    foreach(c ${CONFIGURATIONS})
        execute_process(
            COMMAND ${CMAKE_COMMAND} --install build --config ${c}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}
            RESULTS_VARIABLE ${PROJECT_NAME}_INSTALL_RESULTS
        )
        if(NOT ${PROJECT_NAME}_INSTALL_RESULTS EQUAL 0)
            message(FATAL_ERROR "Error while installing ${PROJECT_NAME}")
        endif()
    endforeach()
endfunction()

set(glfw3_OPTIONS -DGLFW_BUILD_DOCS=OFF -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF)
build_cmake_project(glfw3 "${glfw3_OPTIONS}")

set(spirv-cross_OPTIONS
    -DSPIRV_CROSS_CLI=OFF
    -DSPIRV_CROSS_ENABLE_C_API=OFF
    -DSPIRV_CROSS_ENABLE_CPP=ON
    -DSPIRV_CROSS_ENABLE_GLSL=ON
    -DSPIRV_CROSS_ENABLE_HLSL=OFF
    -DSPIRV_CROSS_ENABLE_MSL=OFF
    -DSPIRV_CROSS_ENABLE_REFLECT=ON
    -DSPIRV_CROSS_ENABLE_TESTS=OFF
)
build_cmake_project(spirv-cross "${spirv-cross_OPTIONS}")
