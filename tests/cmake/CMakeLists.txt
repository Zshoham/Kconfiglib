cmake_minimum_required(VERSION 3.15)
project(kconfiglib_cmake_test NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../cmake")
include(Kconfig)

kconfig_configure(
  KCONFIG "${CMAKE_CURRENT_LIST_DIR}/../Kcmake"
  NAME test_config)

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

if(NOT EXISTS "${KCONFIG_HEADER_FILE}" OR NOT EXISTS "${KCONFIG_CMAKE_FILE}")
  message(FATAL_ERROR "Kconfig generated files are missing")
endif()

if(NOT "CONFIG_ENABLED" IN_LIST KCONFIG_SYMBOLS)
  message(FATAL_ERROR "CONFIG_ENABLED was not present in KCONFIG_SYMBOLS")
endif()
