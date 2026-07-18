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
#     [EXTRA_MACROS <NONE|EMBED|COPY>]
#   )
#
# EXTRA_MACROS controls how Kconfig's extra C macros are generated. NONE (the
# default) generates no extra macros, EMBED appends them to the configuration
# header, and COPY writes them to a private kconfig_macros.h header and
# reserves the configuration name "kconfig_macros".
#
# The following variables are set in the caller's scope:
#   KCONFIG_CONFIG_FILE, KCONFIG_HEADER_FILE, KCONFIG_EXTRA_MACROS_FILE,
#   KCONFIG_CMAKE_FILE, KCONFIG_INCLUDE_DIR, KCONFIG_TARGET, and
#   KCONFIG_SOURCES.
#
# Additionally, every generated Kconfig symbol variable (e.g. CONFIG_FOO, or
# PREFIX_FOO if a custom symbol prefix was used) is set in the caller's scope,
# along with KCONFIG_SYMBOLS -- the list of exactly those variable names.
function(kconfig_configure)
  cmake_parse_arguments(KCONFIG ""
                        "KCONFIG;CONFIG;BINARY_DIR;PYTHON_EXECUTABLE;NAME;EXTRA_MACROS"
                        "" ${ARGN})
  if(KCONFIG_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unknown kconfig_configure arguments: ${KCONFIG_UNPARSED_ARGUMENTS}")
  endif()

  set(_kconfig_macros_modes NONE EMBED COPY)
  if(NOT DEFINED KCONFIG_EXTRA_MACROS)
    set(KCONFIG_EXTRA_MACROS "NONE")
  endif()
  if(NOT KCONFIG_EXTRA_MACROS IN_LIST _kconfig_macros_modes)
    message(FATAL_ERROR
      "Unknown EXTRA_MACROS '${KCONFIG_EXTRA_MACROS}'. "
      "Expected one of: ${_kconfig_macros_modes}.")
  endif()

  # Argument defaults. Relative paths are resolved the way regular CMake
  # commands resolve them.
  if(NOT KCONFIG_KCONFIG)
    set(KCONFIG_KCONFIG "Kconfig")
  endif()
  get_filename_component(KCONFIG_KCONFIG "${KCONFIG_KCONFIG}" ABSOLUTE
                         BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  if(NOT EXISTS "${KCONFIG_KCONFIG}")
    message(FATAL_ERROR "Kconfig file does not exist: ${KCONFIG_KCONFIG}")
  endif()

  if(NOT KCONFIG_BINARY_DIR)
    set(KCONFIG_BINARY_DIR "kconfig")
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

  if(NOT KCONFIG_NAME)
    set(KCONFIG_NAME "kconfig")
  endif()

  get_filename_component(_kconfiglib_dir "${_KCONFIGLIB_CMAKE_DIR}" DIRECTORY)
  set(_kconfig_genconfig "${_kconfiglib_dir}/genconfig.py")
  if(NOT EXISTS "${_kconfig_genconfig}")
    message(FATAL_ERROR
      "Could not find genconfig.py next to Kconfig.cmake. "
      "Set CMAKE_MODULE_PATH to the Kconfiglib cmake directory from the source tree.")
  endif()

  # Generated outputs, all named after the configuration.
  set(_kconfig_prefix "${KCONFIG_BINARY_DIR}/${KCONFIG_NAME}")
  set(_kconfig_header "${_kconfig_prefix}.h")
  set(_kconfig_cmake "${_kconfig_prefix}.cmake")
  set(_kconfig_config "${_kconfig_prefix}.config")
  set(_kconfig_stamp "${_kconfig_prefix}.stamp")
  set(_kconfig_filelist "${_kconfig_prefix}.filelist")
  set(_kconfig_include_dirs "${KCONFIG_BINARY_DIR}")

  # Everything mode-specific about the extra C macros. In EMBED mode genconfig
  # appends the macros to the configuration header, so the macros source is an
  # input of the generation command. In COPY mode the macros are snapshotted
  # into a per-configuration include directory at configure time;
  # configure_file() re-runs CMake (and thereby the copy) whenever the source
  # header changes.
  set(_kconfig_macros_file "")
  set(_kconfig_macros_gen_args "")
  set(_kconfig_macros_depends "")
  if(NOT KCONFIG_EXTRA_MACROS STREQUAL "NONE")
    set(_kconfig_macros_source "${_kconfiglib_dir}/kconfig_macros.h")
    if(NOT EXISTS "${_kconfig_macros_source}")
      message(FATAL_ERROR
        "Could not find kconfig_macros.h next to genconfig.py. "
        "The Kconfiglib installation is incomplete.")
    endif()
  endif()
  if(KCONFIG_EXTRA_MACROS STREQUAL "EMBED")
    set(_kconfig_macros_file "${_kconfig_header}")
    set(_kconfig_macros_gen_args "--embed-kconfig-extra-macros")
    set(_kconfig_macros_depends "${_kconfig_macros_source}")
  elseif(KCONFIG_EXTRA_MACROS STREQUAL "COPY")
    if(KCONFIG_NAME STREQUAL "kconfig_macros")
      message(FATAL_ERROR
        "Kconfig configuration NAME 'kconfig_macros' is reserved in COPY mode "
        "because it collides with the generated kconfig_macros.h header.")
    endif()
    set(_kconfig_macros_dir "${_kconfig_prefix}-include")
    set(_kconfig_macros_file "${_kconfig_macros_dir}/kconfig_macros.h")
    list(APPEND _kconfig_include_dirs "${_kconfig_macros_dir}")
    configure_file("${_kconfig_macros_source}" "${_kconfig_macros_file}"
                   COPYONLY)
  endif()

  # Single source of truth for the genconfig invocation, shared by the
  # configure-time execute_process() and the build-time custom command.
  # KCONFIG_CONFIG is the *input* configuration (the user's CONFIG). The
  # normalized, full configuration is written to a module-owned file next to
  # the other generated outputs, so genconfig never rewrites the user's file.
  set(_kconfig_gen_command
    "${CMAKE_COMMAND}" -E env "KCONFIG_CONFIG=${KCONFIG_CONFIG}"
    "${KCONFIG_PYTHON_EXECUTABLE}" "${_kconfig_genconfig}"
    --header-path "${_kconfig_header}"
    --cmake-out "${_kconfig_cmake}"
    --config-out "${_kconfig_config}"
    --file-list "${_kconfig_filelist}"
    ${_kconfig_macros_gen_args}
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
  # genconfig is normally silent on stdout, so that should be rare.
  if(_kconfig_stderr)
    message(WARNING "Kconfig (${KCONFIG_KCONFIG}):\n${_kconfig_stderr}")
  endif()
  if(_kconfig_stdout)
    message(STATUS "Kconfig (${KCONFIG_KCONFIG}):\n${_kconfig_stdout}")
  endif()

  # Kconfiglib follows source/rsource includes. genconfig reports the exact
  # set of files its parse sourced (--file-list), so every included file is
  # tracked regardless of its name or location -- no glob guessing. Paths in
  # the list may be relative to the working directory
  # (CMAKE_CURRENT_SOURCE_DIR).
  file(STRINGS "${_kconfig_filelist}" _kconfig_source_lines)
  set(_kconfig_sources "")
  foreach(_kconfig_source_line ${_kconfig_source_lines})
    get_filename_component(_kconfig_source_abs "${_kconfig_source_line}"
                           ABSOLUTE BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    list(APPEND _kconfig_sources "${_kconfig_source_abs}")
  endforeach()
  list(APPEND _kconfig_sources "${KCONFIG_KCONFIG}")
  list(REMOVE_DUPLICATES _kconfig_sources)

  # The build-time custom command DEPENDS on KCONFIG_CONFIG, so it must exist
  # by build time. If the user did not supply one (or it doesn't exist yet),
  # seed it once with the freshly generated default configuration. An existing
  # configuration file is used as input and is never rewritten here.
  if(NOT EXISTS "${KCONFIG_CONFIG}")
    configure_file("${_kconfig_config}" "${KCONFIG_CONFIG}" COPYONLY)
  endif()

  # Re-run this configure step whenever an input or a generated output
  # changes, so the imported CONFIG_* values stay in sync.
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
    ${_kconfig_sources} "${KCONFIG_CONFIG}" "${_kconfig_genconfig}"
    "${_kconfig_header}" "${_kconfig_cmake}" ${_kconfig_macros_depends})

  include("${_kconfig_cmake}")

  # include() runs in this function's scope. The generated file defines
  # KCONFIG_SYMBOLS with the exact list of variable names it set (using
  # whatever symbol prefix the Kconfig was generated with, not necessarily
  # "CONFIG_"), so export exactly those variables to the caller's scope
  # instead of guessing from a hardcoded prefix.
  foreach(_kconfig_variable ${KCONFIG_SYMBOLS})
    set(${_kconfig_variable} "${${_kconfig_variable}}" PARENT_SCOPE)
  endforeach()

  # Drive the build-time rule off a stamp file rather than the generated
  # outputs. genconfig only rewrites outputs whose contents change, so their
  # mtimes cannot reliably drive the rule. KCONFIG_CONFIG is an input only.
  add_custom_command(
    OUTPUT "${_kconfig_stamp}"
    COMMAND ${_kconfig_gen_command}
    COMMAND "${CMAKE_COMMAND}" -E touch "${_kconfig_stamp}"
    BYPRODUCTS "${_kconfig_header}" "${_kconfig_cmake}"
               "${_kconfig_config}" "${_kconfig_filelist}"
    DEPENDS ${_kconfig_sources} "${KCONFIG_CONFIG}" "${_kconfig_genconfig}"
            ${_kconfig_macros_depends}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  add_custom_target("${KCONFIG_NAME}_generate" DEPENDS "${_kconfig_stamp}")

  foreach(_kconfig_tool menuconfig guiconfig oldconfig olddefconfig)
    add_custom_target("${KCONFIG_NAME}_${_kconfig_tool}"
      COMMAND "${CMAKE_COMMAND}" -E env "KCONFIG_CONFIG=${KCONFIG_CONFIG}"
              "${KCONFIG_PYTHON_EXECUTABLE}"
              "${_kconfiglib_dir}/${_kconfig_tool}.py" "${KCONFIG_KCONFIG}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
      USES_TERMINAL
      COMMENT "Running Kconfig ${_kconfig_tool}")
  endforeach()

  set(KCONFIG_SYMBOLS "${KCONFIG_SYMBOLS}" PARENT_SCOPE)
  set(KCONFIG_CONFIG_FILE "${KCONFIG_CONFIG}" PARENT_SCOPE)
  set(KCONFIG_HEADER_FILE "${_kconfig_header}" PARENT_SCOPE)
  set(KCONFIG_EXTRA_MACROS_FILE "${_kconfig_macros_file}" PARENT_SCOPE)
  set(KCONFIG_CMAKE_FILE "${_kconfig_cmake}" PARENT_SCOPE)
  set(KCONFIG_INCLUDE_DIR "${_kconfig_include_dirs}" PARENT_SCOPE)
  set(KCONFIG_TARGET "${KCONFIG_NAME}_generate" PARENT_SCOPE)
  set(KCONFIG_SOURCES "${_kconfig_sources}" PARENT_SCOPE)
endfunction()

# Convenience alias matching the terminology used by several build systems.
function(kconfig_init)
  kconfig_configure(${ARGN})
endfunction()
