cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(remote_core)

######################################
# Section : Disable in-source builds #
######################################

if (${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_BINARY_DIR})
message(FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt and CMakeFiles folder.")
endif ()

########################################
# Section : Common Build setttings #
########################################
# Set required compiler standard to standard c++11. Disable extensions.
set(CMAKE_CXX_STANDARD 11) # C++11...
set(CMAKE_CXX_STANDARD_REQUIRED ON) #...is required...
set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++11

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/archive)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Configure Compiler flags
if (UNIX AND NOT APPLE)
# Prefer pthread if found
set(THREADS_PREFER_PTHREAD_FLAG ON)
set(CUSTOM_COMPILER_FLAGS "-fno-exceptions -Wall -Werror")
elseif (APPLE)
set(CUSTOM_COMPILER_FLAGS "-fno-exceptions -Wall -Werror")
elseif (WIN32)
set(CUSTOM_COMPILER_FLAGS "/W4")
endif ()

#############################
# Add SDK Target #
############################
# Create library file. The Client applications MUST link to below target if using this CMake file
set(REMOTE_CORE_TARGET_NAME remote_core)
# Build Project Here

if (BUILD_SHARED_LIBRARY)
    add_library(${SDK_TARGET_NAME} SHARED "")
    set_target_properties(${REMOTE_CORE_TARGET_NAME} PROPERTIES SUFFIX ".so")
else()
    add_library(${SDK_TARGET_NAME} "")
    set_target_properties(${REMOTE_CORE_TARGET_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

# Download and include rapidjson, not optional
configure_file(CMakeLists-rapidjson.txt.in ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/rapidjson/download/CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/rapidjson/download)
execute_process(COMMAND ${CMAKE_COMMAND} --build .
WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/rapidjson/download)
target_include_directories(${SDK_TARGET_NAME} PRIVATE ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/rapidjson/src/include)

# Download sanitizers, optional
if (SANITIZE_THREAD OR SANITIZE_ADDRESS OR SANITIZE_MEMORY OR SANITIZE_UNDEFINED)
    configure_file(CMakeLists-sanitizers.txt.in ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/sanitizers/download/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/sanitizers/download)
    execute_process(COMMAND ${CMAKE_COMMAND} --build .
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${DEPENDENCY_DIR}/sanitizers/download)
endif()

# Get Common SDK Sources
file(GLOB_RECURSE SDK_SOURCES FOLLOW_SYMLINKS ${PROJECT_SOURCE_DIR}/src/*.cpp)
target_include_directories(${SDK_TARGET_NAME} PRIVATE  ${PROJECT_SOURCE_DIR}/include)
target_sources(${SDK_TARGET_NAME} PRIVATE ${SDK_SOURCES})

# Configure Threading library
find_package(Threads REQUIRED)
set(THREAD_LIBRARY_LINK_STRING "Threads::Threads" -ldl)
target_link_libraries(${SDK_TARGET_NAME} "Threads::Threads" -ldl)

if(APPLE)
    target_link_libraries(${SDK_TARGET_NAME} -lresolv)
endif()

#####################################
# Section : Define specific Targets #
#####################################
if(BUILD_TESTS)
    add_subdirectory(tests/integration)
    add_subdirectory(tests/unit)
endif()

##################################
# Section: Define Install Target #
##################################
if(NOT MSVC)
install(TARGETS aws-iot-sdk-cpp DESTINATION lib)
install(DIRECTORY include/ DESTINATION include)
endif()

##########################
# Section: Print Summary #
##########################
include(FeatureSummary)

add_feature_info(SharedLibrary BUILD_SHARED_LIBRARY "build the library as shared objects")
add_feature_info(Cli BUILD_CLI "the command line interface")
add_feature_info(Samples BUILD_SAMPLES "example programs making use of the SDK")
add_feature_info(Tests BUILD_TESTS "unit and integration tests")
add_feature_info(Docs BUILD_DOCS "HTML based API documentation")

feature_summary(WHAT ALL)

################################
# Target : Build remote_core #
################################
set(REMOTE_CORE_TARGET_NAME remote_core)

# Add target.
file(GLOB SOURCES
"${PROJECT_SOURCE_DIR}/src/*.c"
"${PROJECT_SOURCE_DIR}/src/*.cpp"
"${PROJECT_SOURCE_DIR}/include/*.h"
"${PROJECT_SOURCE_DIR}/include/*.hpp")

add_executable(${REMOTE_CORE_TARGET_NAME} ${SOURCES})
# add_executable(${REMOTE_CORE_TARGET_NAME} "${PROJECT_SOURCE_DIR}/PubSub.cpp;${PROJECT_SOURCE_DIR}/../../common/ConfigCommon.cpp")

# Add Target specific includes
target_include_directories(${REMOTE_CORE_TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/include)

# Configure Threading library
find_package(Threads REQUIRED)

# Add SDK includes.
target_include_directories(${REMOTE_CORE_TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/../aws-iot-device-sdk-cpp/build/third-party/rapidjson/src/include)
target_include_directories(${REMOTE_CORE_TARGET_NAME} PUBLIC ${PROJECT_SOURCE_DIR}/../aws-iot-device-sdk-cpp/include)

target_link_libraries(${REMOTE_CORE_TARGET_NAME} PUBLIC "Threads::Threads")
target_link_libraries(${REMOTE_CORE_TARGET_NAME} PUBLIC ${SDK_TARGET_NAME})

# Copy JSON config file.
add_custom_command(TARGET ${REMOTE_CORE_TARGET_NAME} POST_BUILD
COMMAND ${CMAKE_COMMAND} -E
copy ${PROJECT_SOURCE_DIR}/config/remote_core_config.json $<TARGET_FILE_DIR:${REMOTE_CORE_TARGET_NAME}>/config/remote_core_config.json)
set_property(TARGET ${REMOTE_CORE_TARGET_NAME} APPEND_STRING PROPERTY COMPILE_FLAGS ${CUSTOM_COMPILER_FLAGS})

# Gather list of all cert files in "/config/certs"
add_custom_command(TARGET ${REMOTE_CORE_TARGET_NAME} PRE_BUILD
COMMAND ${CMAKE_COMMAND} -E
copy_directory ${PROJECT_SOURCE_DIR}/config/certs $<TARGET_FILE_DIR:${REMOTE_CORE_TARGET_NAME}>/config/certs)

if (MSVC)
target_sources(${REMOTE_CORE_TARGET_NAME} PUBLIC ${SOURCES})
endif ()

#########################
# Add Network libraries #
#########################

# set(NETWORK_WRAPPER_DEST_TARGET ${REMOTE_CORE_TARGET_NAME})
# include(${PROJECT_SOURCE_DIR}/../../network/CMakeLists.txt.in)


