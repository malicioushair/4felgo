cmake_minimum_required(VERSION 3.28)

function(_pastviewer_contains haystack needle out_var)
    string(FIND "${haystack}" "${needle}" _position)
    if(_position EQUAL -1)
        set(${out_var} FALSE PARENT_SCOPE)
    else()
        set(${out_var} TRUE PARENT_SCOPE)
    endif()
endfunction()

if(NOT SOURCE_DIR
    OR NOT FELGO_ROOT
    OR NOT PROJECT_VERSION
    OR NOT GLOG_INCLUDE_DIR
    OR NOT GFLAGS_INCLUDE_DIR
    OR NOT QDOC)
    message(FATAL_ERROR "GeneratePastViewerDocs.cmake is missing required variables.")
endif()

set(_docs_dir "${SOURCE_DIR}/docs")
set(_docs_gen_dir "${_docs_dir}")
set(_docs_html_dir "${_docs_dir}/html")
set(_generated_conf "${_docs_gen_dir}/.pastviewer-felgo.generated.qdocconf")
set(_module_header "${_docs_gen_dir}/.pastviewer-documentation.generated.h")
set(_qdoc_index "${_docs_html_dir}/pastviewer.index")

file(MAKE_DIRECTORY "${_docs_gen_dir}")

file(GLOB_RECURSE _app_headers "${SOURCE_DIR}/src/App/*.h")
list(SORT _app_headers)

set(_module_header_content "#pragma once\n\n")
foreach(_header IN LISTS _app_headers)
    file(RELATIVE_PATH _relative_header "${SOURCE_DIR}/src" "${_header}")
    string(APPEND _module_header_content "#include \"${_relative_header}\"\n")
endforeach()
file(WRITE "${_module_header}" "${_module_header_content}")

set(_include_paths
    "${_docs_gen_dir}"
    "${SOURCE_DIR}"
    "${SOURCE_DIR}/src"
    "-F${FELGO_ROOT}/lib"
    "-isystem${FELGO_ROOT}/mkspecs/macx-clang"
    "-isystem${FELGO_ROOT}/include"
    "-isystem${FELGO_ROOT}/include/Felgo"
)

file(GLOB _qt_frameworks "${FELGO_ROOT}/lib/Qt*.framework")
foreach(_framework IN LISTS _qt_frameworks)
    if(IS_DIRECTORY "${_framework}/Headers")
        list(APPEND _include_paths "-isystem${_framework}/Headers")

        file(GLOB _versioned_dirs LIST_DIRECTORIES true "${_framework}/Headers/*")
        foreach(_versioned IN LISTS _versioned_dirs)
            if(NOT IS_DIRECTORY "${_versioned}")
                continue()
            endif()
            get_filename_component(_versioned_name "${_versioned}" NAME)
            if(_versioned_name MATCHES "^[0-9]")
                list(APPEND _include_paths "-isystem${_versioned}")
                file(GLOB _module_dirs LIST_DIRECTORIES true "${_versioned}/*")
                foreach(_module_dir IN LISTS _module_dirs)
                    if(IS_DIRECTORY "${_module_dir}")
                        list(APPEND _include_paths "-isystem${_module_dir}")
                    endif()
                endforeach()
            endif()
        endforeach()
    endif()
endforeach()

list(APPEND _include_paths
    "-isystem${GLOG_INCLUDE_DIR}"
    "-isystem${GFLAGS_INCLUDE_DIR}"
)

file(READ "${SOURCE_DIR}/docs/pastviewer-felgo.qdocconf" _base_qdocconf)
file(WRITE "${_generated_conf}" "${_base_qdocconf}")
file(APPEND "${_generated_conf}" "\nversion = ${PROJECT_VERSION}\n")

foreach(_include_path IN LISTS _include_paths)
    file(APPEND "${_generated_conf}" "includepaths += \"${_include_path}\"\n")
endforeach()

file(APPEND "${_generated_conf}"
    "\ninclude(${FELGO_ROOT}/doc/global/qt-html-templates-offline.qdocconf)\n"
)

file(REMOVE_RECURSE "${_docs_html_dir}")
file(MAKE_DIRECTORY "${_docs_html_dir}")

execute_process(
    COMMAND "${QDOC}" "${_generated_conf}"
    WORKING_DIRECTORY "${_docs_dir}"
    RESULT_VARIABLE _qdoc_result
    OUTPUT_VARIABLE _qdoc_output
    ERROR_VARIABLE _qdoc_error
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
)

if(_qdoc_output)
    message(STATUS "${_qdoc_output}")
endif()
if(_qdoc_error)
    message(STATUS "${_qdoc_error}")
endif()

set(_qdoc_diagnostics "${_qdoc_output}\n${_qdoc_error}")
if(_qdoc_result)
    message(FATAL_ERROR "QDoc failed with exit code ${_qdoc_result}.")
endif()

if(_qdoc_diagnostics MATCHES "(^|[ \t])(\\(qdoc\\) )?(warning|error):")
    message(FATAL_ERROR "QDoc reported diagnostics; generation is considered failed.")
endif()

if(NOT EXISTS "${_qdoc_index}")
    message(FATAL_ERROR "QDoc did not produce ${_qdoc_index}.")
endif()

file(READ "${_qdoc_index}" _index_content)

file(GLOB_RECURSE _qml_files "${SOURCE_DIR}/qml/*.qml")
list(SORT _qml_files)
foreach(_qml_file IN LISTS _qml_files)
    get_filename_component(_qml_type "${_qml_file}" NAME_WE)
    _pastviewer_contains("${_index_content}" "<qmlclass name=\"${_qml_type}\"" _found)
    if(NOT _found)
        message(FATAL_ERROR "Generated index is missing QML type: ${_qml_type} (${_qml_file})")
    endif()
endforeach()

set(_expected_index_markers
    "<class name=\"Range\""
    "<struct name=\"Item\""
    "<class name=\"PastVuModelController\""
    "<class name=\"UniqueCircularBuffer\""
    "<variable name=\"cid\" fullname=\"Item::cid\""
    "<variable name=\"year\" fullname=\"Item::year\""
)
foreach(_expected IN LISTS _expected_index_markers)
    _pastviewer_contains("${_index_content}" "${_expected}" _found)
    if(NOT _found)
        message(FATAL_ERROR "Generated index is missing expected C++ API: ${_expected}")
    endif()
endforeach()

set(_unique_buffer_html "${_docs_html_dir}/uniquecircularbuffer.html")
if(NOT EXISTS "${_unique_buffer_html}")
    message(FATAL_ERROR "Missing UniqueCircularBuffer documentation page.")
endif()
file(READ "${_unique_buffer_html}" _unique_buffer_content)
set(_expected_members
    "Size()"
    "At(size_t idx)"
    "Push(const T &amp;item)"
    "Pop()"
    "IsFull()"
    "Clear()"
)
foreach(_expected_member IN LISTS _expected_members)
    _pastviewer_contains("${_unique_buffer_content}" "${_expected_member}" _found)
    if(NOT _found)
        message(FATAL_ERROR "UniqueCircularBuffer documentation is missing: ${_expected_member}")
    endif()
endforeach()

if(_index_content MATCHES "signature=\"int (ReloadItems|SetViewportCoordinates|InitSentry)")
    message(FATAL_ERROR "Generated index contains a corrupted C++ signature.")
endif()

message(STATUS "Generated ${_docs_html_dir}/ using ${QDOC}")
message(STATUS "Open ${_docs_html_dir}/index.html")
