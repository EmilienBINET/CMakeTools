include( create_common_internals )
#-------------------------------------------------------------------------------------------------------------------------------------------
# Create an executable.
# Arguments:
#     NAME "exe_name"
#     [GLOBAL_C_VERSION 90|99|11|17|23]
#     [GLOBAL_CPP_VERSION 98|11|14|17|20|23|26]
#     [C_VERSION 90|99|11|17|23]
#     [CPP_VERSION 98|11|14|17|20|23|26]
#     [INCLUDES "dir1;dir2..."]
#     SOURCES
#         [SOURCE] src_file
#             [TEMPLATE tmp_file]
#             [OVERRIDE_COMPILE_FLAGS "flags1 flags2..."]
#             [APPEND_COMPILE_FLAGS "flags1 flags2..."]
#             [PREPEND_COMPILE_FLAGS "flags1 flags2..."]
#             [OVERRIDE_DEFINITIONS "def1 def2..."]
#             [ADD_DEFINITIONS "def1 def2..."]
#         [SOURCE] src_file
#             [TEMPLATE tmp_file]
#             [OVERRIDE_COMPILE_FLAGS "flags1 flags2..."]
#             [APPEND_COMPILE_FLAGS "flags1 flags2..."]
#             [PREPEND_COMPILE_FLAGS "flags1 flags2..."]
#             [OVERRIDE_DEFINITIONS "def1 def2..."]
#             [ADD_DEFINITIONS "def1 def2..."]
#         ...
#     [DEFINITIONS "def1;def2..."]
#     [GLOBAL_DEFINITIONS "def1;def2..."]
#     [SUBDIRECTORIES "sub1;sub2..."]
#     [DEPENDENCIES
#         [INTERNAL]|PACKAGE dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [COMPONENTS "cmp1 cmp2..."]
#         [INTERNAL]|PACKAGE dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [COMPONENTS "cmp1 cmp2..."]
#         ...]
#     [COMPILE_FLAGS "flags1;flags2..."]
#     [GETTEXT_TRANSLATIONS "src_dir1;src_dir2...;file1.po;file2.po..."]
#     [QT_TRANSLATIONS "src_dir1;src_dir2...;file1.ts;file2.ts...;res.qrc"]
#     [PROTOBUF_FILES
#         [SIMPLE]|GRPC file1.proto
#         [SIMPLE]|GRPC file2.proto
#         ...]
#     [INSTALLATION "command1;command2..."]
#     [POSITION_INDEPENDENT_CODE]
#     [NO_POSITION_INDEPENDENT_EXECUTABLE]
#     [WARNINGS_ARE_ERRORS]
#     [MSVC_ENABLE_UPDATED_CPLUSPLUS_MACRO]
#     [OPENMP]
#     [VS_STARTUP_PROJECT]
#     [GUI]
function( create_executable )
  # Set debug prefix
  set( dbg_prefix "${CMAKE_CURRENT_FUNCTION}():" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_POSITION_INDEPENDENT_CODE )
  unset( arg_NO_POSITION_INDEPENDENT_EXECUTABLE )
  unset( arg_WARNINGS_ARE_ERRORS )
  unset( arg_MSVC_ENABLE_UPDATED_CPLUSPLUS_MACRO )
  unset( arg_OPENMP )
  unset( arg_VS_STARTUP_PROJECT )
  unset( arg_GUI )
  unset( arg_NAME )
  unset( arg_GLOBAL_C_VERSION )
  unset( arg_GLOBAL_CPP_VERSION )
  unset( arg_C_VERSION )
  unset( arg_CPP_VERSION )
  unset( arg_INCLUDES )
  unset( arg_SOURCES )
  unset( arg_DEFINITIONS )
  unset( arg_GLOBAL_DEFINITIONS )
  unset( arg_SUBDIRECTORIES )
  unset( arg_DEPENDENCIES )
  unset( arg_COMPILE_FLAGS )
  unset( arg_GETTEXT_TRANSLATIONS )
  unset( arg_QT_TRANSLATIONS )
  unset( arg_PROTOBUF_FILES )
  unset( arg_INSTALLATION )
  unset( arg_UNPARSED_ARGUMENTS )

  # Parse function arguments.
  # Option arguments: POSITION_INDEPENDENT_CODE, NO_POSITION_INDEPENDENT_EXECUTABLE, WARNINGS_ARE_ERRORS, MSVC_ENABLE_UPDATED_CPLUSPLUS_MACRO, OPENMP, VS_STARTUP_PROJECT, GUI
  # Single-value arguments: NAME, GLOBAL_C_VERSION, GLOBAL_CPP_VERSION, C_VERSION, CPP_VERSION
  # Multi-values arguments: INCLUDES, SOURCES, DEFINITIONS, GLOBAL_DEFINITIONS, SUBDIRECTORIES, DEPENDENCIES,
  #                         COMPILE_FLAGS, GETTEXT_TRANSLATIONS, QT_TRANSLATIONS, PROTOBUF_FILES, INSTALLATION
  cmake_parse_arguments( arg
    "POSITION_INDEPENDENT_CODE;NO_POSITION_INDEPENDENT_EXECUTABLE;WARNINGS_ARE_ERRORS;MSVC_ENABLE_UPDATED_CPLUSPLUS_MACRO;OPENMP;VS_STARTUP_PROJECT;GUI"
    "NAME;GLOBAL_C_VERSION;GLOBAL_CPP_VERSION;C_VERSION;CPP_VERSION"
    "INCLUDES;SOURCES;DEFINITIONS;GLOBAL_DEFINITIONS;SUBDIRECTORIES;DEPENDENCIES;COMPILE_FLAGS;GETTEXT_TRANSLATIONS;QT_TRANSLATIONS;PROTOBUF_FILES;INSTALLATION"
    ${ARGN}
  )

  message( STATUS "----------------------------------------------------------------------------------------------------" )
  message( STATUS "Information about the build" )
  if( CMAKE_BUILD_TYPE )
    message( STATUS "    Build type:         ${ColorInfo}${CMAKE_BUILD_TYPE}${ColorReset}" )
  elseif( CMAKE_CONFIGURATION_TYPES )
    message( STATUS "    Build type:         ${ColorInfo}MultiConfig(${CMAKE_CONFIGURATION_TYPES})${ColorReset}" )
  else()
    message( STATUS "    Build type:         ${ColorWarning}Not set${ColorReset}" )
  endif()
  if( BUILD_SHARED_LIBS )
    message( STATUS "    Library type:       ${ColorInfo}Shared${ColorReset}" )
  else()
    message( STATUS "    Library type:       ${ColorInfo}Static${ColorReset}" )
  endif()
  message( STATUS "    Host" )
  message( STATUS "        Processor:      ${ColorInfo}${CMAKE_HOST_SYSTEM_PROCESSOR}${ColorReset}" )
  message( STATUS "        System name:    ${ColorInfo}${CMAKE_HOST_SYSTEM_NAME}${ColorReset}" )
  message( STATUS "        System version: ${ColorInfo}${CMAKE_HOST_SYSTEM_VERSION}${ColorReset}" )
  message( STATUS "    Target" )
  message( STATUS "        Processor:      ${ColorInfo}${CMAKE_SYSTEM_PROCESSOR}${ColorReset}" )
  message( STATUS "        System name:    ${ColorInfo}${CMAKE_SYSTEM_NAME}${ColorReset}" )
  message( STATUS "        System version: ${ColorInfo}${CMAKE_SYSTEM_VERSION}${ColorReset}" )
  message( STATUS "    Compiler" )
  if( CMAKE_TOOLCHAIN_FILE )
    message( STATUS "        Toolchain file: ${ColorInfo}${CMAKE_TOOLCHAIN_FILE}${ColorReset}" )
    if( BUILD_ARCHITECTURE )
      message( STATUS "        Architecture:   ${ColorInfo}${BUILD_ARCHITECTURE}${ColorReset}" )
    endif()
  else()
    message( STATUS "        Executable:     ${ColorInfo}${CMAKE_CXX_COMPILER}${ColorReset}" )
    message( STATUS "        Identifier:     ${ColorInfo}${CMAKE_CXX_COMPILER_ID}${ColorReset}" )
    message( STATUS "        Version:        ${ColorInfo}${CMAKE_CXX_COMPILER_VERSION}${ColorReset}" )
    set( flags ${CMAKE_C_FLAGS} )
    string( REPLACE " " ";" flags "${flags}" )
    foreach( flag IN LISTS flags )
      if( flag )
        message( STATUS "        C Flag(s):      ${ColorInfo}${flag}${ColorReset}" )
      endif()
    endforeach()
    set( flags ${CMAKE_CXX_FLAGS} )
    string( REPLACE " " ";" flags "${flags}" )
    foreach( flag IN LISTS flags )
      if( flag )
        message( STATUS "        C++ Flag(s):    ${ColorInfo}${flag}${ColorReset}" )
      endif()
    endforeach()
    set( flags ${CMAKE_EXE_LINKER_FLAGS} )
    string( REPLACE " " ";" flags "${flags}" )
    foreach( flag IN LISTS flags )
      if( flag )
        message( STATUS "        Linker Flag(s): ${ColorInfo}${flag}${ColorReset}" )
      endif()
    endforeach()
  endif()

  message( STATUS "----------------------------------------------------------------------------------------------------" )
  message( STATUS "Pre-Configuring executable ${ColorLib}${arg_NAME}${ColorReset}" )

  # On Visual Studio, hide CMake projects ALL_BUILD, INSTALL and ZERO_CHECK to a CMakePredefinedTargets folder
  set_property( GLOBAL PROPERTY USE_FOLDERS ON )

  # Stop immediately if unknown argument
  if( arg_UNPARSED_ARGUMENTS )
    message( FATAL_ERROR "Unknown argument(s) in the create_executable function: ${arg_UNPARSED_ARGUMENTS}" )
  endif()

  if( arg_GLOBAL_C_VERSION )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has global ${ColorFlags}C version ${arg_GLOBAL_C_VERSION}${ColorReset}" )
    set( CMAKE_C_STANDARD ${arg_GLOBAL_C_VERSION} )
    set( CMAKE_C_STANDARD_REQUIRED ON )
  endif()

  if( arg_GLOBAL_CPP_VERSION )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has global ${ColorFlags}C++ version ${arg_GLOBAL_CPP_VERSION}${ColorReset}" )
    set( CMAKE_CXX_STANDARD ${arg_GLOBAL_CPP_VERSION} )
    set( CMAKE_CXX_STANDARD_REQUIRED ON )
  endif()

  if( arg_POSITION_INDEPENDENT_CODE )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}position independent code${ColorReset}" )
    add_compile_options(-fPIC)
  endif()
  if( arg_NO_POSITION_INDEPENDENT_EXECUTABLE )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}no position independent executable${ColorReset}" )
    if( NOT MSVC )
      add_compile_options(-fno-pie)
      add_link_options(-no-pie)
    endif()
  endif()

  message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}all warnings enabled${ColorReset}" )

  if( NOT MSVC )
    add_compile_options(-Wall)
  endif()

  if( arg_WARNINGS_ARE_ERRORS )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}warnings are errors${ColorReset}" )
    if( MSVC )
      add_compile_options(-WX)
    else()
      add_compile_options(-Werror)
    endif()
  endif()

  if( arg_OPENMP )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}OpenMP${ColorReset} enabled" )
    set( def "${CREATE_LIBRARY_HAVE_PREFIX}OPENMP" )
    message( STATUS "        ${ColorLib}${arg_NAME}${ColorReset} has global definition ${ColorDefOn}${def}${ColorReset}" )
    add_definitions(-D${def})
    add_compile_options(-fopenmp)
    link_libraries(gomp)
  else()
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has not ${ColorFlags}OpenMP${ColorReset}" )
    set( def "${CREATE_LIBRARY_HAVE_NOT_PREFIX}OPENMP" )
    message( STATUS "        ${ColorLib}${arg_NAME}${ColorReset} has global definition ${ColorDefOff}${def}${ColorReset}" )
    add_definitions(-D${def})
    if( NOT MSVC )
      add_compile_options(-Wno-unknown-pragmas)
    endif()
  endif()

  if( arg_GLOBAL_DEFINITIONS )
    foreach( def IN LISTS arg_GLOBAL_DEFINITIONS )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has global definition ${ColorDefOn}${def}${ColorReset}" )
      add_definitions( -D${def} )
    endforeach()
  endif()

  # If the project has internal library dependencies
  if( arg_SUBDIRECTORIES )
    foreach( sub_full IN LISTS arg_SUBDIRECTORIES )
      get_filename_component( sub ${sub_full} NAME )
      message( DEBUG "${dbg_prefix} add_subdirectory(${sub_full} ${sub})" )
      add_subdirectory( ${sub_full} ${sub} )
      unset( sub )
    endforeach()
  endif()

  message( STATUS "----------------------------------------------------------------------------------------------------" )
  message( STATUS "Configuring executable ${ColorLib}${arg_NAME}${ColorReset}" )

  # Start creating the executable by defining the project name
  project( ${arg_NAME} )

  # Source files may have custom parameters; we parse them here
  _create_common_internals_parse_src(
    NAME ${arg_NAME}
    SOURCES ${arg_SOURCES}
    COMPILE_FLAGS ${arg_COMPILE_FLAGS}
    DEFINITIONS ${arg_DEFINITIONS}
  )

  # Compute the template files (with @VAR@ entries)
  _create_common_internals_handle_templates()

  # Compute the GetText translations
  _create_common_internals_handle_gettext_translations()

  # Compute the Qt translations
  _create_common_internals_handle_qt_translations()

  # Handle the GUI executables
  unset( GUI_FLAG )
  if( arg_GUI )
    if( MSVC )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} is a ${ColorFlags}Windows GUI application${ColorReset}" )
      set( GUI_FLAG WIN32 )
    else()
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} is a ${ColorFlags}Windows GUI application${ColorReset} ${ColorWarning}(ignored because not MSVC)${ColorReset}" )
    endif()
  endif()

  # Add the executable with the source files
  add_executable( ${arg_NAME} ${GUI_FLAG} ${PARSED_SOURCES} )

  # Filter files into folders in Visual Studio
  source_group( "CMake Rules"     REGULAR_EXPRESSION "^$" ) # No one in that folder since no one can match the regex
  source_group( "Generated Files" REGULAR_EXPRESSION "ui_.*\\.h|mocs_.*\\.cpp|qrc_.*\\.cpp|\\.stamp|\\.rule|\\.mo|\\.qm$" )
  source_group( "Resources Files" REGULAR_EXPRESSION "\\.qrc|\\.rc$" )
  source_group( "User Interfaces" REGULAR_EXPRESSION "\\.ui$" )
  source_group( "Translations"    REGULAR_EXPRESSION "\\.po|\\.ts$" )

  # Set the startup project for MSVC
  if( MSVC AND arg_VS_STARTUP_PROJECT )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} is ${ColorFlags}Visual Studio startup project${ColorReset}" )
    set_property( DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${arg_NAME} )
  endif()

  # Set the language version
  _create_common_internals_handle_language_version()

  # Add the compile flags
  _create_common_internals_handle_compile_flags()

  # Add the compile definitions
  _create_common_internals_handle_compile_definitions()

  # Dependencies may have custom parameters; we parse them here
  _create_common_internals_parse_dep( DEPENDENCIES ${arg_DEPENDENCIES} )

  # Clear the evironment variable used for the dependency tree
  set( ENV{${arg_NAME}_PUBLIC_DEPENDENCIES} "" )
  set( ENV{${arg_NAME}_PRIVATE_DEPENDENCIES} "" )

  # Add the internal library dependencies
  _create_common_internals_handle_internal_dependencies()

  # Add the package library dependencies
  _create_common_internals_handle_packages_dependencies()

  # Compute the protobuf files
  _create_common_internals_handle_protobuf_files()

  # Check the Qt translations dependencies
  _create_common_internals_check_qt_translations_dependencies()

  # Check the GetText translations dependencies
  _create_common_internals_check_gettext_translations_dependencies()

  # Add includes directories to the target
  target_include_directories( ${arg_NAME} PUBLIC ${arg_PUBLIC_API} PRIVATE ${arg_INCLUDES} )

  # Add definitions to the target
  set_target_properties( ${arg_NAME} PROPERTIES COMPILE_DEFINITIONS "${arg_DEFINITIONS}" )

  if( arg_INSTALLATION )
    install( CODE "execute_process( COMMAND echo Launch: ${arg_INSTALLATION} )" )
    install( CODE "execute_process( COMMAND ${arg_INSTALLATION} )" )
  endif()

  # Dump the dependency tree
  if( DUMP_DEPENDENCY_TREE )
    message( STATUS "----------------------------------------------------------------------------------------------------" )
    _create_common_internals_print_dep_tree(
      NAME ${arg_NAME}
    )
  endif()

  message( STATUS "----------------------------------------------------------------------------------------------------" )

endfunction( create_executable )
