# Builds libnuqta_engine: llama.cpp + mtmd + the Nuqta core + the C ABI for dart:ffi.
# Used by the Android Gradle build and by host (Linux/macOS) builds for tests.
# iOS links a prebuilt llama.xcframework instead (see ../ios/nuqta_engine.podspec).
cmake_minimum_required(VERSION 3.22)

project(nuqta_engine_library VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# The llama.cpp version the Nuqta GGUF files and the upstream apps were tested with.
set(NUQTA_LLAMA_COMMIT 5aeac37a35b44fde4bdffaec9159f2fcb253b622)

if(NOT LLAMA_SRC)
  set(LLAMA_SRC ${CMAKE_CURRENT_LIST_DIR}/../third_party/llama.cpp)
endif()
if(NOT EXISTS ${LLAMA_SRC}/CMakeLists.txt)
  message(STATUS "llama.cpp not found at ${LLAMA_SRC}; fetching ${NUQTA_LLAMA_COMMIT}")
  include(FetchContent)
  FetchContent_Declare(llama_cpp
    GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
    GIT_TAG ${NUQTA_LLAMA_COMMIT}
    GIT_SHALLOW FALSE
    SOURCE_SUBDIR do-not-configure)
  FetchContent_MakeAvailable(llama_cpp)
  set(LLAMA_SRC ${llama_cpp_SOURCE_DIR})
endif()

function(nuqta_set name value)
  set(${name} ${value} CACHE BOOL "" FORCE)
endfunction()

nuqta_set(LLAMA_BUILD_COMMON OFF)
nuqta_set(LLAMA_BUILD_TOOLS OFF)
nuqta_set(LLAMA_BUILD_EXAMPLES OFF)
nuqta_set(LLAMA_BUILD_TESTS OFF)
nuqta_set(LLAMA_BUILD_SERVER OFF)
nuqta_set(LLAMA_BUILD_APP OFF)
nuqta_set(LLAMA_BUILD_MTMD ON)
nuqta_set(LLAMA_OPENSSL OFF)
nuqta_set(GGML_LLAMAFILE OFF)

if(ANDROID)
  # Same configuration as the upstream Android app: the CPU backend is built for every
  # ARM feature level and the best one for the phone is loaded at run time.
  nuqta_set(BUILD_SHARED_LIBS ON)
  nuqta_set(GGML_NATIVE OFF)
  nuqta_set(GGML_BACKEND_DL ON)
  nuqta_set(GGML_OPENMP ON)
  if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(GGML_SYSTEM_ARCH "ARM")
    nuqta_set(GGML_CPU_ALL_VARIANTS ON)
    nuqta_set(GGML_CPU_KLEIDIAI ON)
  else()
    # x86_64 is for emulators only: one baseline CPU backend is enough.
    nuqta_set(GGML_CPU_ALL_VARIANTS OFF)
  endif()
else()
  # Host builds (tests): one self-contained shared library.
  nuqta_set(BUILD_SHARED_LIBS OFF)
  nuqta_set(GGML_BACKEND_DL OFF)
  if(NOT DEFINED GGML_NATIVE)
    nuqta_set(GGML_NATIVE ON)
  endif()
endif()

add_subdirectory(${LLAMA_SRC} build-llama)

add_library(nuqta_engine SHARED
  nuqta_ffi.cpp
  upstream/nuqta_core.cpp
)

target_include_directories(nuqta_engine PRIVATE
  ${CMAKE_CURRENT_LIST_DIR}/upstream
  ${LLAMA_SRC}/include
  ${LLAMA_SRC}/ggml/include
  ${LLAMA_SRC}/tools/mtmd
)

target_compile_definitions(nuqta_engine PRIVATE
  DART_SHARED_LIB
  NUQTA_LLAMA_COMMIT="${NUQTA_LLAMA_COMMIT}"
)

target_link_libraries(nuqta_engine PRIVATE llama mtmd ggml)

set_target_properties(nuqta_engine PROPERTIES
  PUBLIC_HEADER nuqta_ffi.h
  OUTPUT_NAME "nuqta_engine"
)

if(ANDROID)
  target_link_libraries(nuqta_engine PRIVATE android log)
  # Android 15+ devices with 16 KB pages
  target_link_options(nuqta_engine PRIVATE "-Wl,-z,max-page-size=16384")
endif()
