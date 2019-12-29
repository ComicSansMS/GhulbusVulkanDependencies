cmake_minimum_required(VERSION 3.13)

cmake_host_system_information(RESULT N_CORES QUERY NUMBER_OF_LOGICAL_CORES)
message(STATUS "Using " ${N_CORES} " threads for building.")

if(GENERATOR)
    message(STATUS "Using generator " ${GENERATOR})
    set(GENERATOR_OPTION -G ${GENERATOR})
endif()
if(PLATFORM)
    message(STATUS "Using target platform " ${PLATFORM})
    list(APPEND GENERATOR_OPTION -A ${PLATFORM})
endif()
if(TOOLSET)
    message(STATUS "Using toolset " ${TOOLSET})
    list(APPEND GENERATOR_OPTION -T ${TOOLSET})
endif()

if(NOT SKIP_GIT)
    find_package(Git REQUIRED)
    message(STATUS "Updating submodules...")
    execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init)
endif()

function(build_cmake_project PROJECT_NAME CONFIGURE_OPTIONS)
    message(STATUS "Building ${PROJECT_NAME}...")
    
    if(WIN32)
        set(CONFIGURATIONS Debug MinSizeRel Release RelWithDebInfo)
    else()
        set(CONFIGURATIONS Release)
    endif()
    set(${PROJECT_NAME}_build_command COMMAND ${CMAKE_COMMAND} ${GENERATOR_OPTION} ${CONFIGURE_OPTIONS}
        -DCMAKE_INSTALL_PREFIX=install -S source -B build)
    message(DEBUG ${${PROJECT_NAME}_build_command})
    execute_process(
        ${${PROJECT_NAME}_build_command}
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

set(gbBase_OPTIONS
    -DGB_BUILD_TESTS=OFF
    -DGB_GENERATE_DOXYGEN_DOCUMENTATION=OFF
    -DGB_GENERATE_COVERAGE_INFO=OFF
    -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON       # CMake < 3.15
    -DCMAKE_EXPORT_PACKAGE_REGISTRY=OFF         # CMake >= 3.15, CMP0090 NEW
)
build_cmake_project(gbBase "${gbBase_OPTIONS}")

set(gbMath_OPTIONS
    -DGB_BUILD_TESTS=OFF
    -DGB_GENERATE_DOXYGEN_DOCUMENTATION=OFF
    -DGB_GENERATE_COVERAGE_INFO=OFF
    -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON       # CMake < 3.15
    -DCMAKE_EXPORT_PACKAGE_REGISTRY=OFF         # CMake >= 3.15, CMP0090 NEW
)
build_cmake_project(gbMath "${gbMath_OPTIONS}")

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
    -DCMAKE_DEBUG_POSTFIX=_d
    -DCMAKE_MINSIZEREL_POSTFIX=_min
    -DCMAKE_RELWITHDEBINFO_POSTFIX=_rdbg
)
build_cmake_project(spirv-cross "${spirv-cross_OPTIONS}")

message("Installing Vulkan Memory Allocator...")
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/vulkan-memory-allocator/source/src/vk_mem_alloc.h
    ${CMAKE_CURRENT_LIST_DIR}/vulkan-memory-allocator/source/src/vk_mem_alloc.natvis
    DESTINATION ${CMAKE_CURRENT_LIST_DIR}/vulkan-memory-allocator/install
)

message("Installing stb...")
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/stb/source/stb_image.h
    DESTINATION ${CMAKE_CURRENT_LIST_DIR}/stb/install
)

message("Installing dear imgui")
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imconfig.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui_demo.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui_draw.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui_internal.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imgui_widgets.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imstb_rectpack.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imstb_textedit.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/imstb_truetype.h
    DESTINATION ${CMAKE_CURRENT_LIST_DIR}/imgui/install
)
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/examples/imgui_impl_glfw.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/examples/imgui_impl_glfw.h
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/examples/imgui_impl_vulkan.cpp
    ${CMAKE_CURRENT_LIST_DIR}/imgui/source/examples/imgui_impl_vulkan.h
    DESTINATION ${CMAKE_CURRENT_LIST_DIR}/imgui/install/examples
)
