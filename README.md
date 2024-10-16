# CMake tools

The **CMake tools** project provides a collection of tools for *CMake*.

Indeed, *CMake* is a powerfull tool used to generate a C/C++ project compilation files but it suffers from an heterogeneous synthax, mainly due to historical considerations.

Thus, to ease the developpement of applications and libraries, **CMake tools** provides some files:
- `create_executable.cmake` provides the `create_executable()` function that allows to easily create an application
- `create_library.cmake` provides the `create_library()` function that allows to easily create a library
- `configure_sanitizer.cmake` provides the `configure_sanitizer()` function that allows to easily enable the code sanitizers (ASAN, LSAN, UBSAN and TSAN)

Some other files that are also provided are for internal purpose only. They should not be used directy:
- `create_common_internals.cmake` is an internal collection of functions and macros used by `create_executable.cmake` and `create_library.cmake`
- `FindBcm.cmake` is a file to help *CMake* to find the BCM library, used for BDR cameras
- `Findprocps.cmake` is a file to help *CMake* to find the procps library, used to monitor running processes
- `FinduEye.cmake` is a file to help *CMake* to find the ueye_api library, used for eEye cameras

# Creating an application or a library

In both cases, *CMake* should be informed of the existence of those files.
In order to do that, the following command should be used early in the `CMakeLists.txt` file:

```cmake
# Here, the CMake tools project files are in the cmake directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
```

## Creating an application

A complete list of all the `create_executable()` function parameters can be found at the start of the `create_executable.cmake` file.

A minimal example:
```cmake
# The create_executable module should be loaded first
include( create_executable )
# Then the executable should be created
create_executable(
  # The name of the executable
  NAME
    MyApplication
  # The source files of the executable
  SOURCES
    main.cpp
    myfile.h # Header file are optionnal but can be added too
    myfile.cpp
)
```

An example with dependencies:
```cmake
# The create_executable module should be loaded first
include( create_executable )
# Then the executable should be created
create_executable(
  # The name of the executable
  NAME
    MyApplication
  # The source files of the executable
  SOURCES
    main.cpp
    myfile.h # Header file are optionnal but can be added too
    myfile.cpp
  # The subdirectories to build with the executable
  SUBDIRECTORIES
    ../path_to_mylib/mylib
  # The ordered dependencies of the executable
  DEPENDENCIES
    # MyLib is an internal library, meaning it should be compiled at the same time of the
    # executable (e.g. from a subdirectory). The INTERNAL keyword is optionnal.
    INTERNAL MyLib
    # procps is a package library, meaning that it must be installed on the system
    PACKAGE procps
)
```

## Creating a library

A complete list of all the `create_library()` function parameters can be found at the start of the `create_library.cmake` file.

A minimal example:
```cmake
# The create_library module should be loaded first
include( create_library )
# Then the library should be created
create_library(
  # The name of the library
  NAME
    MyLib
  # The folders containng the public API files of the library
  PUBLIC_API
    lib
  # The private source files of the library
  SOURCES
    mylib.h # Header file are optionnal but can be added too
    mylib.cpp
)
```