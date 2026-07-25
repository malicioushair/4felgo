# API documentation generation with Felgo's QDoc (macOS host kit only).

if(NOT Felgo_DIR)
    message(WARNING "Felgo_DIR is not set; pastviewer-docs target will not be added.")
    return()
endif()

if(NOT DEFINED glog_INCLUDE_DIRS OR NOT DEFINED gflags_INCLUDE_DIRS)
    message(WARNING "glog/gflags include dirs are not available; pastviewer-docs target will not be added.")
    return()
endif()

if(NOT EXISTS "${glog_INCLUDE_DIRS}/glog/logging.h")
    message(WARNING "glog headers were not found at ${glog_INCLUDE_DIRS}; pastviewer-docs target will not be added.")
    return()
endif()

if(NOT EXISTS "${gflags_INCLUDE_DIRS}/gflags/gflags.h")
    message(WARNING "gflags headers were not found at ${gflags_INCLUDE_DIRS}; pastviewer-docs target will not be added.")
    return()
endif()

if(NOT FELGO_ROOT)
    get_filename_component(FELGO_ROOT "${Felgo_DIR}/../../.." ABSOLUTE)
endif()
set(FELGO_ROOT "${FELGO_ROOT}" CACHE PATH "Felgo macOS host kit root (contains bin/qdoc)")

set(_PASTVIEWER_QDOC "${FELGO_ROOT}/bin/qdoc")
if(NOT EXISTS "${_PASTVIEWER_QDOC}")
    message(WARNING "Felgo qdoc not found at ${_PASTVIEWER_QDOC}; pastviewer-docs target will not be added.")
    return()
endif()

set(_PASTVIEWER_DOCS_INDEX "${CMAKE_SOURCE_DIR}/docs/html/pastviewer.index")
set(_PASTVIEWER_DOCS_GENERATOR "${CMAKE_SOURCE_DIR}/cmake/GeneratePastViewerDocs.cmake")

file(GLOB_RECURSE _PASTVIEWER_DOCS_HEADERS CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/App/*.h"
)
file(GLOB_RECURSE _PASTVIEWER_DOCS_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/App/*.cpp"
    "${CMAKE_SOURCE_DIR}/qml/*.qml"
)
set(_PASTVIEWER_DOCS_INPUTS
    "${CMAKE_SOURCE_DIR}/docs/index.qdoc"
    "${CMAKE_SOURCE_DIR}/docs/header-only.qdoc"
    "${CMAKE_SOURCE_DIR}/docs/pastviewer-felgo.qdocconf"
    "${_PASTVIEWER_DOCS_GENERATOR}"
    ${_PASTVIEWER_DOCS_HEADERS}
    ${_PASTVIEWER_DOCS_SOURCES}
)

add_custom_command(
    OUTPUT "${_PASTVIEWER_DOCS_INDEX}"
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
        -DFELGO_ROOT=${FELGO_ROOT}
        -DPROJECT_VERSION=${PROJECT_VERSION}
        -DGLOG_INCLUDE_DIR=${glog_INCLUDE_DIRS}
        -DGFLAGS_INCLUDE_DIR=${gflags_INCLUDE_DIRS}
        -DQDOC=${_PASTVIEWER_QDOC}
        -P ${_PASTVIEWER_DOCS_GENERATOR}
    DEPENDS ${_PASTVIEWER_DOCS_INPUTS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating PastViewer API documentation with Felgo QDoc"
    VERBATIM
)

add_custom_target(pastviewer-docs
    DEPENDS "${_PASTVIEWER_DOCS_INDEX}"
)
