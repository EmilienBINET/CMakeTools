# - try to find Bcm directories and libraries
#
# Once done this will define:
#
#  Bcm_FOUND
#  Bcm_INCLUDE_DIRS
#  Bcm_LIBRARIES
#

include (FindPackageHandleStandardArgs)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_path (Bcm_INCLUDE_DIRS bcmApi.h)
    find_library (Bcm_LIBRARIES NAMES libBcm.so)
    find_package_handle_standard_args (Bcm DEFAULT_MSG Bcm_LIBRARIES Bcm_INCLUDE_DIRS)
endif()
