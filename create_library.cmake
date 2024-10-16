include( create_common_internals )
#-------------------------------------------------------------------------------------------------------------------------------------------
# Create a library.
# Arguments:
#     NAME "lib_name"
#     [C_VERSION 90|99|11|17|23]
#     [CPP_VERSION 98|11|14|17|20|23|26]
#     PUBLIC_API "dir1;dir2..."
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
#     [DEPENDENCIES
#         [INTERNAL]|PACKAGE dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [PUBLIC] [COMPONENTS "cmp1 cmp2..."]
#         [INTERNAL]|PACKAGE dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [PUBLIC] [COMPONENTS "cmp1 cmp2..."]
#         ...]
#     [COMPILE_FLAGS "flags1;flags2..."]
#     [GETTEXT_TRANSLATIONS "src_dir1;src_dir2...;file1.po;file2.po..."]
#     [QT_TRANSLATIONS "src_dir1;src_dir2...;file1.ts;file2.ts..."]
#     [PROTOBUF_FILES
#         [SIMPLE]|GRPC file1.proto
#         [SIMPLE]|GRPC file2.proto
#         ...]
#     [ENABLE_CPLUSPLUS_MACRO]
function( create_library )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}():" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_NAME )
  unset( arg_C_VERSION )
  unset( arg_CPP_VERSION )
  unset( arg_PUBLIC_API )
  unset( arg_INCLUDES )
  unset( arg_SOURCES )
  unset( arg_DEFINITIONS )
  unset( arg_DEPENDENCIES )
  unset( arg_COMPILE_FLAGS )
  unset( arg_GETTEXT_TRANSLATIONS )
  unset( arg_QT_TRANSLATIONS )
  unset( arg_PROTOBUF_FILES )
  unset( arg_ENABLE_CPLUSPLUS_MACRO )

  # Parse function arguments.
  # Option arguments: ENABLE_CPLUSPLUS_MACRO
  # Single-value arguments: NAME, C_VERSION, CPP_VERSION
  # Multi-values arguments: PUBLIC_API, INCLUDES, SOURCES, DEFINITIONS, DEPENDENCIES, COMPILE_FLAGS, GETTEXT_TRANSLATIONS, QT_TRANSLATIONS, PROTOBUF_FILES
  cmake_parse_arguments( arg
    "ENABLE_CPLUSPLUS_MACRO"
    "NAME;C_VERSION;CPP_VERSION"
    "PUBLIC_API;INCLUDES;SOURCES;DEFINITIONS;DEPENDENCIES;COMPILE_FLAGS;GETTEXT_TRANSLATIONS;QT_TRANSLATIONS;PROTOBUF_FILES" ${ARGN} )
  
    
  if( arg_ENABLE_CPLUSPLUS_MACRO )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}__cplusplus macro${ColorReset}" )
    if( MSVC )
      add_compile_options("/Zc:__cplusplus")
    endif()
  endif()

  message( STATUS "----------------------------------------------------------------------------------------------------" )
  message( STATUS "Configuring library ${ColorLib}${arg_NAME}${ColorReset}" )

  # Start creating the library by defining the project name
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

  # Compute the Qt translations
  _create_common_internals_handle_gettext_translations()

  # Compute the Qt translations
  _create_common_internals_handle_qt_translations()

  # Add the library with the source files
  add_library( ${arg_NAME} "${PARSED_SOURCES}" )

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

  # Dump the dependency tree
  if( DUMP_DEPENDENCY_TREE )
    message( STATUS "----------------------------------------------------------------------------------------------------" )
    _create_common_internals_print_dep_tree(
      NAME ${arg_NAME}
    )
  endif()

endfunction( create_library )
