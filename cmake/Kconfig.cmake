# CMake helpers for projects using Kconfiglib.
# SPDX-License-Identifier: ISC

include_guard(GLOBAL)

set(_KCONFIGLIB_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Configure a Kconfig tree and make its generated values available to CMake.
#
#   kconfig_configure(
#     KCONFIG <path>
#     [CONFIG <path>]
#     [BINARY_DIR <directory>]
#     [PYTHON_EXECUTABLE <path>]
#     [NAME <name>]
#   )
#
# The following variables are set in the caller's scope:
#   KCONFIG_CONFIG_FILE, KCONFIG_HEADER_FILE, KCONFIG_CMAKE_FILE,
#   KCONFIG_TARGET, and KCONFIG_SOURCES.
#
# Additionally, every generated Kconfig symbol variable (e.g. CONFIG_FOO, or
# PREFIX_FOO if a custom symbol prefix was used) is set in the caller's scope,
# along with KCONFIG_SYMBOLS -- the list of exactly those variable names.
function(kconfig_configure)
  set(one_value_args KCONFIG CONFIG BINARY_DIR PYTHON_EXECUTABLE NAME)
  cmake_parse_arguments(KCONFIG "" "${one_value_args}" "" ${ARGN})

  if(KCONFIG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown kconfig_configure arguments: ${KCONFIG_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT KCONFIG_KCONFIG)
    set(KCONFIG_KCONFIG "${CMAKE_CURRENT_SOURCE_DIR}/Kconfig")
  endif()
  get_filename_component(KCONFIG_KCONFIG "${KCONFIG_KCONFIG}" ABSOLUTE
                         BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  if(NOT EXISTS "${KCONFIG_KCONFIG}")
    message(FATAL_ERROR "Kconfig file does not exist: ${KCONFIG_KCONFIG}")
  endif()

  if(NOT KCONFIG_BINARY_DIR)
    set(KCONFIG_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/kconfig")
  endif()
  get_filename_component(KCONFIG_BINARY_DIR "${KCONFIG_BINARY_DIR}" ABSOLUTE
                         BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  file(MAKE_DIRECTORY "${KCONFIG_BINARY_DIR}")

  if(NOT KCONFIG_CONFIG)
    set(KCONFIG_CONFIG "${KCONFIG_BINARY_DIR}/.config")
  endif()
  get_filename_component(KCONFIG_CONFIG "${KCONFIG_CONFIG}" ABSOLUTE
                         BASE_DIR "${CMAKE_CURRENT_BINARY_DIR}")

  if(NOT KCONFIG_PYTHON_EXECUTABLE)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)
    set(KCONFIG_PYTHON_EXECUTABLE "${Python3_EXECUTABLE}")
  endif()

  get_filename_component(_kconfiglib_dir "${_KCONFIGLIB_CMAKE_DIR}" DIRECTORY)
  set(_kconfiglib_genconfig "${_kconfiglib_dir}/genconfig.py")
  if(NOT EXISTS "${_kconfiglib_genconfig}")
    message(FATAL_ERROR
      "Could not find genconfig.py next to Kconfig.cmake. "
      "Set CMAKE_MODULE_PATH to the Kconfiglib cmake directory from the source tree.")
  endif()

  if(NOT KCONFIG_NAME)
    set(KCONFIG_NAME "kconfig")
  endif()
  set(_kconfig_prefix "${KCONFIG_BINARY_DIR}/${KCONFIG_NAME}")
  set(_kconfig_header "${_kconfig_prefix}.h")
  set(_kconfig_cmake "${_kconfig_prefix}.cmake")
  set(_kconfig_config "${_kconfig_prefix}.config")
  set(_kconfig_stamp "${_kconfig_prefix}.stamp")
  set(_kconfig_filelist "${_kconfig_prefix}.filelist")

  # Single source of truth for the genconfig invocation, shared by the
  # configure-time execute_process and the build-time custom command.
  #
  # KCONFIG_CONFIG is the *input* configuration (the user's CONFIG). The
  # normalized, full configuration is written to a module-owned file next to
  # the other generated outputs, so genconfig never rewrites the user's file.
  set(_kconfig_gen_command
    "${CMAKE_COMMAND}" -E env "KCONFIG_CONFIG=${KCONFIG_CONFIG}"
    "${KCONFIG_PYTHON_EXECUTABLE}" "${_kconfiglib_genconfig}"
    --header-path "${_kconfig_header}"
    --cmake-out "${_kconfig_cmake}"
    --config-out "${_kconfig_config}"
    --file-list "${_kconfig_filelist}"
    "${KCONFIG_KCONFIG}")

  # Generate during configure so CONFIG_* variables are available to the
  # remainder of the project's CMakeLists.txt.
  execute_process(
    COMMAND ${_kconfig_gen_command}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE _kconfig_result
    OUTPUT_VARIABLE _kconfig_stdout
    ERROR_VARIABLE _kconfig_stderr)
  if(NOT _kconfig_result EQUAL 0)
    message(FATAL_ERROR
      "Kconfig generation failed (${_kconfig_result}):\n${_kconfig_stdout}${_kconfig_stderr}")
  endif()
  # genconfig can print important diagnostics (e.g. a stale .config assigning
  # unknown or malformed symbols, or values out of range) to stderr while
  # still exiting 0. Surface those instead of swallowing them silently.
  if(_kconfig_stderr)
    message(WARNING "Kconfig (${KCONFIG_KCONFIG}):\n${_kconfig_stderr}")
  endif()
  # genconfig is normally silent on stdout, so this should be rare.
  if(_kconfig_stdout)
    message(STATUS "Kconfig (${KCONFIG_KCONFIG}):\n${_kconfig_stdout}")
  endif()

  # Kconfiglib follows source/rsource includes. genconfig itself reports the
  # exact set of files its parse sourced (--file-list), so every included file
  # is tracked regardless of its name or location -- no glob guessing. Paths in
  # the list may be relative to the working directory (CMAKE_CURRENT_SOURCE_DIR).
  file(STRINGS "${_kconfig_filelist}" _kconfig_source_lines)
  set(_kconfig_sources "")
  foreach(_kconfig_source_line ${_kconfig_source_lines})
    get_filename_component(_kconfig_source_abs "${_kconfig_source_line}" ABSOLUTE
                           BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    list(APPEND _kconfig_sources "${_kconfig_source_abs}")
  endforeach()
  list(APPEND _kconfig_sources "${KCONFIG_KCONFIG}")
  list(REMOVE_DUPLICATES _kconfig_sources)
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    ${_kconfig_sources} "${KCONFIG_CONFIG}")

  # The build-time custom command DEPENDS on KCONFIG_CONFIG, so it must exist
  # by build time. If the user did not supply one (or it doesn't exist yet),
  # seed it once with the freshly generated default configuration. An existing
  # configuration file is used as input and is never rewritten here.
  if(NOT EXISTS "${KCONFIG_CONFIG}")
    configure_file("${_kconfig_config}" "${KCONFIG_CONFIG}" COPYONLY)
  endif()

  # Re-run this configure step when any generated input changes.
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    "${_kconfig_header}" "${_kconfig_cmake}")

  include("${_kconfig_cmake}")

  # include() runs in this function's scope. The generated file defines
  # KCONFIG_SYMBOLS with the exact list of variable names it set (using
  # whatever symbol prefix the Kconfig was generated with, not necessarily
  # "CONFIG_"), so export exactly those variables to the caller's scope
  # instead of guessing from a hardcoded prefix.
  foreach(_kconfig_variable ${KCONFIG_SYMBOLS})
    set(${_kconfig_variable} "${${_kconfig_variable}}" PARENT_SCOPE)
  endforeach()
  set(KCONFIG_SYMBOLS "${KCONFIG_SYMBOLS}" PARENT_SCOPE)

  # Drive the rule off a stamp file rather than the generated outputs.
  # genconfig writes its outputs only when their content actually changes, so
  # the header/.cmake/.config mtimes can't advance past their prerequisites and
  # an OUTPUT-based rule would be permanently dirty. Touching the stamp after
  # generation leaves it newer than every prerequisite, so the rule goes clean.
  # KCONFIG_CONFIG is a prerequisite (input) only; the command never writes it.
  add_custom_command(
    OUTPUT "${_kconfig_stamp}"
    COMMAND ${_kconfig_gen_command}
    COMMAND "${CMAKE_COMMAND}" -E touch "${_kconfig_stamp}"
    BYPRODUCTS "${_kconfig_header}" "${_kconfig_cmake}" "${_kconfig_config}"
               "${_kconfig_filelist}"
    DEPENDS "${KCONFIG_KCONFIG}" ${_kconfig_sources} "${KCONFIG_CONFIG}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  add_custom_target("${KCONFIG_NAME}_generate"
    DEPENDS "${_kconfig_stamp}")

  set(_kconfig_env "KCONFIG_CONFIG=${KCONFIG_CONFIG}")
  foreach(_kconfig_command menuconfig guiconfig oldconfig olddefconfig)
    add_custom_target("${KCONFIG_NAME}_${_kconfig_command}"
      COMMAND "${CMAKE_COMMAND}" -E env "${_kconfig_env}"
              "${KCONFIG_PYTHON_EXECUTABLE}"
              "${_kconfiglib_dir}/${_kconfig_command}.py"
              "${KCONFIG_KCONFIG}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      USES_TERMINAL
      COMMENT "Running Kconfig ${_kconfig_command}")
  endforeach()

  set(KCONFIG_CONFIG_FILE "${KCONFIG_CONFIG}" PARENT_SCOPE)
  set(KCONFIG_HEADER_FILE "${_kconfig_header}" PARENT_SCOPE)
  set(KCONFIG_CMAKE_FILE "${_kconfig_cmake}" PARENT_SCOPE)
  set(KCONFIG_TARGET "${KCONFIG_NAME}_generate" PARENT_SCOPE)
  set(KCONFIG_SOURCES "${_kconfig_sources}" PARENT_SCOPE)
endfunction()

# Convenience alias matching the terminology used by several build systems.
function(kconfig_init)
  kconfig_configure(${ARGN})
endfunction()
