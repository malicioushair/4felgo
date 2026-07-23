cmake_minimum_required(VERSION 3.28)
project(PastViewer VERSION 1.1.0 LANGUAGES CXX)
list(APPEND CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}")

set(CMAKE_CXX_STANDARD 20)

option(ENABLE_FELGO_HOT_RELOAD "Build PastViewer as a Felgo Hot Reload client" OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/resources/android")

include_directories(src)

include(cmake/Helpers.cmake)

if (NOT APP_REVERSED_DOMAIN)
    message(FATAL_ERROR "APP_REVERSED_DOMAIN has to be set!")
endif()

set(PRODUCT_IDENTIFIER "${APP_REVERSED_DOMAIN}" CACHE STRING "Application bundle identifier" FORCE)
set(APPLE_APP_REVERSED_DOMAIN "${APP_REVERSED_DOMAIN}")

set(PRODUCT_VERSION_NAME "${PROJECT_VERSION}")
set(PRODUCT_VERSION_CODE ${CMAKE_PROJECT_VERSION_MAJOR}${CMAKE_PROJECT_VERSION_MINOR}${CMAKE_PROJECT_VERSION_PATCH})
set(PRODUCT_LICENSE_KEY "")
set(PRODUCT_STAGE "test")

include(src/App/App.cmake)

if (NOT ANDROID AND NOT IOS)
    option(BUILD_TESTS "Build unit tests" ON)
    if(BUILD_TESTS)
        enable_testing()
        add_subdirectory(tests)
    endif()
endif()

set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install)


install(TARGETS ${PROJECT_NAME}
        BUNDLE DESTINATION  .
        LIBRARY DESTINATION .
        RUNTIME DESTINATION .)
