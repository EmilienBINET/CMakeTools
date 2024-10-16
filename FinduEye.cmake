# - try to find uEye directories and libraries
#
# Once done this will define:
#
#  uEye_FOUND
#  uEye_INCLUDE_DIRS
#  uEye_LIBRARIES
#

include (FindPackageHandleStandardArgs)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_path (uEye_INCLUDE_DIRS ueye.h)
    find_library (uEye_LIBRARIES NAMES libueye_api.so)
    find_package_handle_standard_args (uEye DEFAULT_MSG uEye_LIBRARIES uEye_INCLUDE_DIRS)
endif()
