cmake_minimum_required(VERSION 3.15)
project(kconfiglib_cmake_test NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../cmake")
include(Kconfig)

# The extra macros mode under test, forwarded to kconfig_configure() as its
# EXTRA_MACROS argument.
if(NOT DEFINED KCONFIG_TEST_EXTRA_MACROS)
  set(KCONFIG_TEST_EXTRA_MACROS "NONE")
endif()

if(KCONFIG_TEST_RESERVED_NAME)
  kconfig_configure(
    KCONFIG "${CMAKE_CURRENT_LIST_DIR}/../Kcmake"
    NAME kconfig_macros
    EXTRA_MACROS COPY)
  message(FATAL_ERROR "The reserved kconfig_macros name was accepted")
endif()



function(assert_kconfig_base_outputs header_file cmake_file include_dirs)
  if(NOT EXISTS "${header_file}" OR NOT EXISTS "${cmake_file}")
    message(FATAL_ERROR "Kconfig generated files are missing")
  endif()

  get_filename_component(_header_dir "${header_file}" DIRECTORY)
  list(FIND include_dirs "${_header_dir}" _header_dir_index)
  if(_header_dir_index EQUAL -1)
    message(FATAL_ERROR
      "KCONFIG_INCLUDE_DIR does not contain the configuration header directory")
  endif()
endfunction()

function(assert_extra_macros_absent header_file)
  file(READ "${header_file}" _header_contents)
  string(FIND "${_header_contents}" "#ifndef KCONFIG_MACROS_H"
         _macros_guard_index)
  if(NOT _macros_guard_index EQUAL -1)
    message(FATAL_ERROR "The default configuration header embeds extra macros")
  endif()
endfunction()

function(assert_embedded_macros header_file)
  file(READ "${header_file}" _header_contents)
  string(FIND "${_header_contents}" "#ifndef KCONFIG_MACROS_H"
         _macros_guard_index)
  if(_macros_guard_index EQUAL -1)
    message(FATAL_ERROR "The configuration header does not embed extra macros")
  endif()
endfunction()

function(assert_copied_macros macros_file include_dirs)
  if(NOT EXISTS "${macros_file}")
    message(FATAL_ERROR "The copied kconfig_macros.h was not generated")
  endif()

  get_filename_component(_macros_dir "${macros_file}" DIRECTORY)
  list(FIND include_dirs "${_macros_dir}" _macros_dir_index)
  if(_macros_dir_index EQUAL -1)
    message(FATAL_ERROR
      "KCONFIG_INCLUDE_DIR does not contain the extra macros directory")
  endif()

  file(SHA256 "${macros_file}" _generated_macros_hash)
  file(SHA256 "${CMAKE_CURRENT_LIST_DIR}/../../kconfig_macros.h"
       _source_macros_hash)
  if(NOT "${_generated_macros_hash}" STREQUAL "${_source_macros_hash}")
    message(FATAL_ERROR "The generated kconfig_macros.h does not match source")
  endif()
endfunction()

kconfig_configure(
  KCONFIG "${CMAKE_CURRENT_LIST_DIR}/../Kcmake"
  NAME test_config
  EXTRA_MACROS "${KCONFIG_TEST_EXTRA_MACROS}")

if(NOT "${CONFIG_ENABLED}" STREQUAL "y" OR
   NOT "${CONFIG_DISABLED}" STREQUAL "n" OR
   NOT "${CONFIG_NUMBER}" STREQUAL "42" OR
   NOT "${CONFIG_ADDRESS}" STREQUAL "0x1000" OR
   NOT "${CONFIG_TEXT}" STREQUAL "bracket]end;semi")
  message(FATAL_ERROR "Kconfig values were not imported into CMake")
endif()

# Invisible symbols with no value are omitted, like in .config files
if(DEFINED CONFIG_HIDDEN)
  message(FATAL_ERROR "CONFIG_HIDDEN should not have been generated")
endif()

assert_kconfig_base_outputs(
  "${KCONFIG_HEADER_FILE}" "${KCONFIG_CMAKE_FILE}" "${KCONFIG_INCLUDE_DIR}")
if(KCONFIG_TEST_EXTRA_MACROS STREQUAL "NONE")
  if(NOT "${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "")
    message(FATAL_ERROR "NONE generated an extra macros file")
  endif()
  assert_extra_macros_absent("${KCONFIG_HEADER_FILE}")
  list(LENGTH KCONFIG_INCLUDE_DIR _include_dir_count)
  if(NOT _include_dir_count EQUAL 1)
    message(FATAL_ERROR "NONE exported an unexpected include directory")
  endif()
elseif(KCONFIG_TEST_EXTRA_MACROS STREQUAL "EMBED")
  if(NOT "${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "${KCONFIG_HEADER_FILE}")
    message(FATAL_ERROR "EMBED exported inconsistent paths")
  endif()
  assert_embedded_macros("${KCONFIG_HEADER_FILE}")
  list(LENGTH KCONFIG_INCLUDE_DIR _include_dir_count)
  if(NOT _include_dir_count EQUAL 1)
    message(FATAL_ERROR "EMBED exported an unexpected include directory")
  endif()
elseif(KCONFIG_TEST_EXTRA_MACROS STREQUAL "COPY")
  if("${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "${KCONFIG_HEADER_FILE}")
    message(FATAL_ERROR "COPY exported colliding paths")
  endif()
  assert_copied_macros(
    "${KCONFIG_EXTRA_MACROS_FILE}" "${KCONFIG_INCLUDE_DIR}")
  list(LENGTH KCONFIG_INCLUDE_DIR _include_dir_count)
  if(NOT _include_dir_count EQUAL 2)
    message(FATAL_ERROR "COPY did not export both include directories")
  endif()
endif()

if(NOT "CONFIG_ENABLED" IN_LIST KCONFIG_SYMBOLS)
  message(FATAL_ERROR "CONFIG_ENABLED was not present in KCONFIG_SYMBOLS")
endif()

# A second named configuration may share the output root. In COPY mode its
# extra macros header must have a distinct BYPRODUCT path. In NONE mode the
# EXTRA_MACROS argument is omitted entirely to exercise its default.
set(_first_header_file "${KCONFIG_HEADER_FILE}")
set(_first_macros_file "${KCONFIG_EXTRA_MACROS_FILE}")
get_filename_component(_shared_binary_dir "${KCONFIG_HEADER_FILE}" DIRECTORY)
set(_second_extra_macros_args "")
if(NOT KCONFIG_TEST_EXTRA_MACROS STREQUAL "NONE")
  set(_second_extra_macros_args EXTRA_MACROS "${KCONFIG_TEST_EXTRA_MACROS}")
endif()
kconfig_configure(
  KCONFIG "${CMAKE_CURRENT_LIST_DIR}/../Kcmake"
  BINARY_DIR "${_shared_binary_dir}"
  NAME boot_config
  ${_second_extra_macros_args})

assert_kconfig_base_outputs(
  "${KCONFIG_HEADER_FILE}" "${KCONFIG_CMAKE_FILE}" "${KCONFIG_INCLUDE_DIR}")
if("${KCONFIG_HEADER_FILE}" STREQUAL "${_first_header_file}")
  message(FATAL_ERROR "Named configurations have colliding headers")
endif()
if(KCONFIG_TEST_EXTRA_MACROS STREQUAL "NONE")
  if(NOT "${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "")
    message(FATAL_ERROR "NONE generated extra macros for the second config")
  endif()
elseif(KCONFIG_TEST_EXTRA_MACROS STREQUAL "EMBED")
  if(NOT "${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "${KCONFIG_HEADER_FILE}")
    message(FATAL_ERROR "EMBED exported inconsistent second-config paths")
  endif()
  assert_embedded_macros("${KCONFIG_HEADER_FILE}")
elseif(KCONFIG_TEST_EXTRA_MACROS STREQUAL "COPY")
  if("${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "${_first_macros_file}" OR
     "${KCONFIG_EXTRA_MACROS_FILE}" STREQUAL "${KCONFIG_HEADER_FILE}")
    message(FATAL_ERROR "COPY generated colliding second-config headers")
  endif()
  assert_copied_macros(
    "${KCONFIG_EXTRA_MACROS_FILE}" "${KCONFIG_INCLUDE_DIR}")
endif()
