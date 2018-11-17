cmake_minimum_required(VERSION 3.2 FATAL_ERROR)
project(remote_core CXX)
option(BUILD_TESTS "Build the tests." ON)

######################################
# Section : Disable in-source builds #
######################################

if (${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_BINARY_DIR})
	message(FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt and CMakeFiles folder.")
endif ()

########################################
# Section : Common SDK Build setttings #
########################################

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Set required compiler standard to standard c++14. Disable extensions.
set(CMAKE_CXX_STANDARD 14) # C++14...
set(CMAKE_CXX_STANDARD_REQUIRED ON) #...is required...
set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++14

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/archive)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Configure Compiler flags
if(UNIX AND NOT APPLE)
    # Disable useless warnings.
    set(CMAKE_CXX_FLAGS "-Wno-psabi")

    # Prefer pthread if found
    set(THREADS_PREFER_PTHREAD_FLAG ON)
endif()

if(NOT DEPENDENCY_DIR)
    set(DEPENDENCY_DIR "third_party")
endif()

##################################
# Section : Download AWS IoT SDK #
##################################

# Download and unpack the AWS IoT SDK at configure time.
configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/CMakeLists-aws.txt.in
${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download/CMakeLists.txt)

# Configure the target.
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download)

# Configure the target for building.
execute_process(COMMAND ${CMAKE_COMMAND} --build .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download)

# Prevent GoogleTest from overriding compiler/linker options
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

# This adds the following targets: aws-iot-sdk-cpp.
add_subdirectory(${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/src
${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/build EXCLUDE_FROM_ALL)

####################################
# Section : Add Application Target #
####################################

# Create executable file.
set(TARGET_NAME remote_core)
add_executable(${TARGET_NAME} "")

# Get target sources.
file(GLOB_RECURSE TARGET_SOURCES FOLLOW_SYMLINKS ${PROJECT_SOURCE_DIR}/src/*.cpp)

# Add the include directories.
target_include_directories(${TARGET_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/include)
target_sources(${TARGET_NAME} PRIVATE ${TARGET_SOURCES})

# Include the dependencies headers.
target_include_directories(${TARGET_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/build/third_party/aws-iot-device-sdk-cpp/src/include)
# target_include_directories(${TARGET_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/build/third_party/nlohmann_json/src/include)

# Link the dependency libraries.
target_link_libraries(${TARGET_NAME} aws-iot-sdk-cpp)
# target_link_libraries(${TARGET-NAME} nlohmann_json)

# Link with OpenSSL.
find_package(OpenSSL REQUIRED)
target_link_libraries(${TARGET_NAME} OpenSSL::SSL)

if(UNIX AND NOT APPLE)
    # Link UUID when on UNIX systems other than macOS.
    pkg_search_module(UUID REQUIRED uuid)
endif()

#####################################
# Section : Define specific Targets #
#####################################

if(BUILD_TESTS)
    # add_subdirectory(tests/integration) *** Not enabled yet.
    add_subdirectory(tests/unit)
endif()

############################
# Section : Copy Resources #
############################

# Copy JSON config file.
add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E
    copy ${PROJECT_SOURCE_DIR}/config/remote_core_config.json $<TARGET_FILE_DIR:${TARGET_NAME}>/config/remote_core_config.json)
set_property(TARGET ${TARGET_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS ${CUSTOM_COMPILER_FLAGS})

# Gather list of all certificates in "/certs".
add_custom_command(TARGET ${TARGET_NAME} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E
    copy_directory ${PROJECT_SOURCE_DIR}/config/certs $<TARGET_FILE_DIR:${TARGET_NAME}>/config/certs)

##################################
# Section: Define Install Target #
##################################

if(NOT MSVC)
    install(TARGETS remote_core DESTINATION bin)
    install(DIRECTORY include/ DESTINATION include)
endif()

##########################
# Section: Print Summary #
##########################

# include(FeatureSummary)
# add_feature_info(Tests BUILD_TESTS "unit and integration tests")
# feature_summary(WHAT ALL)
