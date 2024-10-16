# - try to find procps directories and libraries
#
# Once done this will define:
#
#  PROCPS_FOUND
#  PROCPS_INCLUDE_DIRS
#  PROCPS_LIBRARIES
#

include (FindPackageHandleStandardArgs)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_path (PROCPS_INCLUDE_DIRS proc/readproc.h)
    find_library (PROCPS_LIBRARIES NAMES proc procps)
    find_package_handle_standard_args (procps DEFAULT_MSG PROCPS_LIBRARIES PROCPS_INCLUDE_DIRS)
endif()
