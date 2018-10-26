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

# Set required compiler standard to standard c++11. Disable extensions.
set(CMAKE_CXX_STANDARD 11) # C++11...
set(CMAKE_CXX_STANDARD_REQUIRED ON) #...is required...
set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++11

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/archive)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Configure Compiler flags
if(UNIX AND NOT APPLE)
    # Prefer pthread if found
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    set(CUSTOM_COMPILER_FLAGS "-fno-exceptions -Wall -Werror")
elseif(APPLE)
    set(CUSTOM_COMPILER_FLAGS "-fno-exceptions -Werror -Wall")
elseif(WIN32)
    set(CUSTOM_COMPILER_FLAGS "/W4")
endif()

if(NOT DEPENDENCY_DIR)
    set(DEPENDENCY_DIR "third_party")
endif()

####################################
# Section : Add Application Target #
####################################

# Download and unpack googletest at configure time
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists-aws.txt.in
${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download/CMakeLists.txt)

execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download)

execute_process(COMMAND ${CMAKE_COMMAND} --build .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/download)

# Prevent GoogleTest from overriding compiler/linker options
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

# This adds the following targets: gtest, gtest_main, gmock and gmock_main
add_subdirectory(${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/src
${CMAKE_BINARY_DIR}/third_party/aws-iot-device-sdk-cpp/build EXCLUDE_FROM_ALL)

# Create executable file.
set(TARGET_NAME remote_core)
add_executable(${TARGET_NAME})

# Get Common SDK Sources
file(GLOB_RECURSE TARGET_SOURCES FOLLOW_SYMLINKS ${PROJECT_SOURCE_DIR}/src/*.cpp)
target_include_directories(${TARGET_NAME} PRIVATE  ${PROJECT_SOURCE_DIR}/include)
target_sources(${TARGET_NAME} PRIVATE ${TARGET_SOURCES})

target_link_libraries(${TARGET_NAME} aws-iot-sdk-cpp)

#####################################
# Section : Define specific Targets #
#####################################

if(BUILD_TESTS)
# add_subdirectory(tests/integration) *** Not enabled yet.
    add_subdirectory(tests/unit)
endif()

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

include(FeatureSummary)
add_feature_info(Tests BUILD_TESTS "unit and integration tests")
feature_summary(WHAT ALL)
