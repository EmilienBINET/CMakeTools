#[[
TODO :
components for internal libraries
'OR' for internal libraries
#]]

if( NOT CREATE_LIBRARY_HAVE_PREFIX )
  set( CREATE_LIBRARY_HAVE_PREFIX "HAVE__" )
endif()
if( NOT CREATE_LIBRARY_HAVE_NOT_PREFIX )
  set( CREATE_LIBRARY_HAVE_NOT_PREFIX "HAVE__NOT__" )
endif()
if( NOT CREATE_LIBRARY_QUIET )
  set( CREATE_LIBRARY_QUIET "QUIET" )
endif()
option( CREATE_LIBRARY_COLOR "Enable the color output (OFF to disable color)" ON )
option( DUMP_DEPENDENCY_TREE "Dump the dependency tree for each library" OFF )
option( DUMP_DEPENDENCY_TREE_WITH_PACKAGES "Dump the dependency tree for each library with packages libraries" OFF )

# Set color codes
if( NOT WIN32 AND CREATE_LIBRARY_COLOR )
  string( ASCII 27 Esc )
  set( ColorReset  "${Esc}[m"     )
  set( BoldRed     "${Esc}[1;31m" )
  set( BoldGreen   "${Esc}[1;32m" )
  set( BoldYellow  "${Esc}[1;33m" )
  set( BoldBlue    "${Esc}[1;34m" )
  set( BoldMagenta "${Esc}[1;35m" )
  set( BoldCyan    "${Esc}[1;36m" )
  set( BoldWhite   "${Esc}[1;37m" )
endif()
set( ColorLib     "${BoldCyan}"    )
set( ColorDefOn   "${BoldBlue}"    )
set( ColorDefOff  "${BoldYellow}"  )
set( ColorOptOn   "${BoldMagenta}" )
set( ColorOptOff  "${BoldWhite}"   )
set( ColorSrc     "${BoldGreen}"   )
set( ColorFlags   "${BoldGreen}"   )
set( ColorVar     "${BoldGreen}"   )
set( ColorVal     "${BoldGreen}"   )
set( ColorInfo    "${BoldGreen}"   )
set( ColorWarning "${BoldYellow}"  )

#-------------------------------------------------------------------------------------------------------------------------------------------
# Parse the sources files list.
# Arguments:
#     NAME lib_name [COMPILE_FLAGS default_flags] [DEFINITIONS default_definitions] SOURCES
#         [SOURCE] src_file [TEMPLATE tmp_file] [OVERRIDE_COMPILE_FLAGS flags] [APPEND_COMPILE_FLAGS flags] [PREPEND_COMPILE_FLAGS flags] [OVERRIDE_DEFINITIONS def] [ADD_DEFINITIONS def]
#         [SOURCE] src_file [TEMPLATE tmp_file] [OVERRIDE_COMPILE_FLAGS flags] [APPEND_COMPILE_FLAGS flags] [PREPEND_COMPILE_FLAGS flags] [OVERRIDE_DEFINITIONS def] [ADD_DEFINITIONS def]
#         ...
# Variables updated:
#     PARSED_SOURCES         List of the sources
#     PARSED_COMPILE_FLAGS   List of the sources with specific flags (format: src1;flags1;src2;flags2...)
#     PARSED_DEFINITIONS     List of the sources with specific definitions (format: src1;def1_1|def1_2;src2;def2...)
#     PARSED_TEMPLATES       List of the template to generate sources (format src1;template1;src2;template2)
function( _create_common_internals_parse_src )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}():" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_NAME )
  unset( arg_COMPILE_FLAGS )
  unset( arg_SOURCES )
  unset( arg_DEFINITIONS )
  unset( src_step )
  unset( src )
  unset( sources )
  unset( last_src )
  unset( last_src_index )
  unset( last_src_compile_flags )
  unset( compile_flags_index )
  unset( sources_compile_flags )
  unset( sources_definitions )
  unset( new_src_definitions )
  unset( sources_template )

  # Parse function arguments.
  # Option arguments: none
  # Single-value arguments: NAME, COMPILE_FLAGS
  # Multi-values arguments: SOURCES, DEFINITIONS
  cmake_parse_arguments( arg "" "NAME;COMPILE_FLAGS" "SOURCES;DEFINITIONS" ${ARGN} )

  # Cannot keep list in the following code
  string( REPLACE ";" "|" arg_DEFINITIONS "${arg_DEFINITIONS}" )

  # We first expect a source file name and the SOURCE keyword is optionnal
  set( src_step "SOURCE" )

  # For each element in the sources list
  foreach( src IN LISTS arg_SOURCES )

    # Print it
    message( DEBUG "${dbg_prefix} New element to parse: ${src}" )

    # If the source element is in fact a keyword
    if( src STREQUAL "SOURCE" OR src STREQUAL "OVERRIDE_COMPILE_FLAGS" OR src STREQUAL "APPEND_COMPILE_FLAGS" OR
        src STREQUAL "PREPEND_COMPILE_FLAGS" OR src STREQUAL "OVERRIDE_DEFINITIONS" OR src STREQUAL "ADD_DEFINITIONS" OR
        src STREQUAL "TEMPLATE" )
      # Change the current step accordingly to the keyword
      set( src_step "${src}" )
      message( DEBUG "${dbg_prefix} Change step to: ${src_step}" )

    # If we follow a SOURCE keyword
    elseif( src_step STREQUAL "SOURCE" )
      # Add the new source to the list
      list( APPEND sources ${src} )
      message( DEBUG "${dbg_prefix} Add to the sources list: ${src}" )

    # If we follow a OVERRIDE_COMPILE_FLAGS keyword, a APPEND_COMPILE_FLAGS keyword or a PREPEND_COMPILE_FLAGS keyword
    elseif( src_step STREQUAL "OVERRIDE_COMPILE_FLAGS" OR src_step STREQUAL "APPEND_COMPILE_FLAGS" OR
            src_step STREQUAL "PREPEND_COMPILE_FLAGS"    )

      # Get the last source file added to the list and search it in the compile flags list
      list( GET sources -1 last_src )
      list( FIND sources_compile_flags "${last_src}" last_src_index )

      # If the source is already in the list
      if( ${last_src_index} GREATER -1 )
        # Compute the index of the compile flags, get its current value and remove it from the list
        math( EXPR compile_flags_index "${last_src_index}+1" )
        list( GET sources_compile_flags ${compile_flags_index} last_src_compile_flags )
        list( REMOVE_AT sources_compile_flags ${compile_flags_index} )

      # If the source is not in the list
      else()
        # Add the source to the list
        list( APPEND sources_compile_flags ${last_src} )
        # Index to add the flags is now the size of the list
        list( LENGTH sources_compile_flags compile_flags_index )
        # And its previous value is the common default value
        set( last_src_compile_flags "${arg_COMPILE_FLAGS}" )
      endif()

      # If override was requested
      if( src_step STREQUAL "OVERRIDE_COMPILE_FLAGS" )
        # Replace the flags by inserting the new value at the index
        list( INSERT sources_compile_flags ${compile_flags_index} ${src} )

      # If append was requested
      elseif( src_step STREQUAL "APPEND_COMPILE_FLAGS" )
        # Replace the flags by inserting the old value + new value at the index
        list( INSERT sources_compile_flags ${compile_flags_index} "${last_src_compile_flags} ${src}" )

      # If prepend was requested
      elseif( src_step STREQUAL "PREPEND_COMPILE_FLAGS" )
        # Replace the flags by inserting the new value + old value at the index
        list( INSERT sources_compile_flags ${compile_flags_index} "${src} ${last_src_compile_flags}" )
      endif()

      # Print it
      list( GET sources_compile_flags ${compile_flags_index} new_src_compile_flags )
      message( DEBUG "${dbg_prefix} Change compile flags for ${last_src} from '${last_src_compile_flags}' to '${new_src_compile_flags}'" )

      # And go back to source step
      set( src_step "SOURCE" )

    # If we follow a OVERRIDE_DEFINITIONS keyword or a ADD_DEFINITIONS keyword
    elseif( src_step STREQUAL "OVERRIDE_DEFINITIONS" OR src_step STREQUAL "ADD_DEFINITIONS" )

      # Get the last source file added to the list and search it in the compile flags list
      list( GET sources -1 last_src )
      list( FIND sources_definitions "${last_src}" last_src_index )

      # If the source is already in the list
      if( ${last_src_index} GREATER -1 )
        # Compute the index of the definitions, get its current value and remove it from the list
        math( EXPR definitions_index "${last_src_index}+1" )
        list( GET sources_definitions ${definitions_index} last_src_definitions )
        list( REMOVE_AT sources_definitions ${definitions_index} )

      # If the source is not in the list
      else()
        # Add the source to the list
        list( APPEND sources_definitions ${last_src} )
        # Index to add the flags is now the size of the list
        list( LENGTH sources_definitions definitions_index )
        # And its previous value is the common default value
        set( last_src_definitions "${arg_DEFINITIONS}" )
      endif()

      # Keep definitions concistent : separated by pipes
      string( REPLACE " " "|" src "${src}" )
      string( REPLACE "&" "|" src "${src}" )

      # If override was requested
      if( src_step STREQUAL "OVERRIDE_DEFINITIONS" )
        # Replace the flags by inserting the new value at the index
        list( INSERT sources_definitions ${definitions_index} ${src} )

      # If add was requested
      elseif( src_step STREQUAL "ADD_DEFINITIONS" )
        # Replace the flags by inserting the old value + new value at the index
        list( INSERT sources_definitions ${definitions_index} "${last_src_definitions}|${src}" )

      endif()

      # Print it
      list( GET sources_definitions ${definitions_index} new_src_definitions )
      message( DEBUG "${dbg_prefix} Change definitions for ${last_src} from '${last_src_definitions}' to '${new_src_definitions}'" )

      # And go back to source step
      set( src_step "SOURCE" )

    # If we follow a TEMPLATE keyword
    elseif( src_step STREQUAL "TEMPLATE" )

      # Get the last source file added to the list
      list( GET sources -1 last_src )

      # Add it to the list of templates
      list( APPEND sources_template
        ${last_src}
        ${src}
      )

      # And go back to source step
      set( src_step "SOURCE" )

    endif()
  endforeach()

  # Tell the caller
  set( PARSED_SOURCES "${sources}" PARENT_SCOPE )
  set( PARSED_TEMPLATES "${sources_template}" PARENT_SCOPE )
  set( PARSED_COMPILE_FLAGS "${sources_compile_flags}" PARENT_SCOPE )
  set( PARSED_DEFINITIONS "${sources_definitions}" PARENT_SCOPE )

endfunction( _create_common_internals_parse_src )

#-------------------------------------------------------------------------------------------------------------------------------------------
# Parse the dependencies list.
# Arguments:
#     DEPENDENCIES
#         [INTERNAL|PACKAGE] dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [PUBLIC] [COMPONENTS "cmp1 cmp2..."]
#         [INTERNAL|PACKAGE] dep [OR dep2] [OR dep3]... [AS name] [OPTIONAL] [PUBLIC] [COMPONENTS "cmp1 cmp2..."]
#         ...
# Variables updated:
#     PARSED_INTERNAL_DEPENDENCIES  List of the internal dependencies
#     PARSED_${dep}_COMPONENTS      List of the components for the dependency ${dep}
#     PARSED_${dep}_OR              List of libraries that can be used for dependency ${dep}
#     PARSED_${dep}_OPTIONAL        True if the dependency ${dep} is optional
#     PARSED_${dep}_PUBLIC          True if the dependency ${dep} is public
#     PARSED_PACKAGE_DEPENDENCIES   List of the package dependencies
#     PARSED_${pkg}_COMPONENTS      List of the components for the dependency ${pkg}
#     PARSED_${pkg}_OR              List of libraries that can be used for dependency ${pkg}
#     PARSED_${pkg}_OPTIONAL        True if the dependency ${pkg} is optional
#     PARSED_${pkg}_PUBLIC          True if the dependency ${pkg} is public
function( _create_common_internals_parse_dep )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}():" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_DEPENDENCIES )
  unset( dep_step )
  unset( dep_internal_or_package )
  unset( dep )
  unset( internal_dependencies )
  unset( last_internal_dependency )
  unset( package_dependencies )
  unset( last_package_dependency )
  unset( current_or )

  # Parse function arguments.
  # Option arguments: none
  # Single-value arguments: none
  # Multi-values arguments: DEPENDENCIES
  cmake_parse_arguments( arg "" "" "DEPENDENCIES" ${ARGN} )

  # We suppose that a dependency is internal by default because INTERNAL keyword is optionnal
  set( dep_step "INTERNAL" )
  # Variable to save the current type of dependency
  set( dep_internal_or_package "INTERNAL" )

  # For each element in the dependencies list
  foreach( dep IN LISTS arg_DEPENDENCIES )

    # Print it
    message( DEBUG "${dbg_prefix} New element to parse: ${dep}" )

    # If the dependency is in fact a keyword
    if( dep STREQUAL "INTERNAL" OR dep STREQUAL "PACKAGE" OR dep STREQUAL "COMPONENTS" OR dep STREQUAL "OR" OR dep STREQUAL "AS" )
      # We change the current step accordingly to the keyword
      set( dep_step "${dep}" )
      message( DEBUG "${dbg_prefix} Change step to: ${dep_step}" )

    # If we follow the OPTIONAL keyword
    elseif( dep STREQUAL "OPTIONAL" )
      # We set the correct variable $_OPTIONAL accodingly to the dependency
      if( dep_internal_or_package STREQUAL "INTERNAL" )
        # We get the last internal dependency
        list( GET internal_dependencies -1 last_internal_dependency )
        set( ${last_internal_dependency}_OPTIONAL TRUE )
        message( DEBUG "${dbg_prefix} Set internal optional: ${last_internal_dependency}" )
      elseif( dep_internal_or_package STREQUAL "PACKAGE" )
        # We get the last package dependency
        list( GET package_dependencies -1 last_package_dependency )
        set( ${last_package_dependency}_OPTIONAL TRUE )
        message( DEBUG "${dbg_prefix} Set package optional: ${last_package_dependency}" )
      endif()

    # If we follow the PUBLIC keyword
    elseif( dep STREQUAL "PUBLIC" )
      # We set the correct variable $_PUBLIC accodingly to the dependency
      if( dep_internal_or_package STREQUAL "INTERNAL" )
        # We get the last internal dependency
        list( GET internal_dependencies -1 last_internal_dependency )
        set( ${last_internal_dependency}_PUBLIC TRUE )
        message( DEBUG "${dbg_prefix} Set internal public: ${last_internal_dependency}" )
      elseif( dep_internal_or_package STREQUAL "PACKAGE" )
        # We get the last package dependency
        list( GET package_dependencies -1 last_package_dependency )
        set( ${last_package_dependency}_PUBLIC TRUE )
        message( DEBUG "${dbg_prefix} Set package public: ${last_package_dependency}" )
      endif()

    # If the current step is INTERNAL
    elseif( dep_step STREQUAL "INTERNAL" )
      # We add it to the list
      list( APPEND internal_dependencies ${dep} )
      message( DEBUG "${dbg_prefix} Add internal: ${dep}" )
      # And we save that we are handling an internal dependency
      set( dep_internal_or_package "INTERNAL" )

    # If we follow the PACKAGE keyword
    elseif( dep_step STREQUAL "PACKAGE" )
      # We add it to the list
      list( APPEND package_dependencies ${dep} )
      message( DEBUG "${dbg_prefix} Add package: ${dep}" )
      # And go back to internal step
      set( dep_step "INTERNAL" )
      # But we save that we are handling a package dependency
      set( dep_internal_or_package "PACKAGE" )

    # If we follow the COMPONENTS keyword
    elseif( dep_step STREQUAL "COMPONENTS" )
      list( GET package_dependencies -1 last_package_dependency )
      string( REPLACE " " ";" dep "${dep}" )
      string( REPLACE "|" ";" dep "${dep}" )
      string( REPLACE "&" ";" dep "${dep}" )
      list( APPEND ${last_package_dependency}_COMPONENTS ${dep} )
      message( DEBUG "${dbg_prefix} Add components ${dep} to ${last_package_dependency}" )
      # And go back to internal step
      set( dep_step "INTERNAL" )

    # If we follow the OR keyword
    elseif( dep_step STREQUAL "OR" )
      if( NOT current_or )
        list( POP_BACK package_dependencies last_package_dependency )
        list( APPEND current_or ${last_package_dependency} )
        message( DEBUG "${dbg_prefix} Remove package ${last_package_dependency}" )
      endif()
      list( APPEND current_or ${dep} )
      message( DEBUG "${dbg_prefix} Set current OR to ${current_or}" )
      # And go back to internal step
      set( dep_step "INTERNAL" )

    # If we follow the AS keyword
    elseif( dep_step STREQUAL "AS" )
      list( APPEND package_dependencies ${dep} )
      list( APPEND ${dep}_OR ${current_or} )
      set( current_or "" )
      message( DEBUG "${dbg_prefix} Add package ${dep} with OR elements ${${dep}_OR}" )
      # And go back to internal step
      set( dep_step "INTERNAL" )

    endif()
  endforeach()

  # Tell the caller about internal dependencies
  if( internal_dependencies )
    message( DEBUG "${dbg_prefix} === Internal dependencies ===" )
    set( PARSED_INTERNAL_DEPENDENCIES "${internal_dependencies}" PARENT_SCOPE )
    # Foreach internal dependency
    foreach( dep IN LISTS internal_dependencies )
      # Print it
      message( DEBUG "${dbg_prefix}   ${dep} (COMPONENTS ${${dep}_COMPONENTS}) (OR ${${dep}_OR}) (OPTIONAL ${${dep}_OPTIONAL})" )
      # If it has components, tell the caller
      if( ${dep}_COMPONENTS )
        set( PARSED_${dep}_COMPONENTS "${${dep}_COMPONENTS}" PARENT_SCOPE )
      endif()
      # If it has OR libraries, tell the caller
      if( ${dep}_OR )
        set( PARSED_${dep}_OR "${${dep}_OR}" PARENT_SCOPE )
      endif()
      # If it is optional, tell the caller
      if( ${dep}_OPTIONAL )
        set( PARSED_${dep}_OPTIONAL TRUE PARENT_SCOPE )
      endif()
      # If it is public, tell the caller
      if( ${dep}_PUBLIC )
        set( PARSED_${dep}_PUBLIC TRUE PARENT_SCOPE )
      endif()
    endforeach()
  endif()

  # Tell the caller about package dependencies
  if( package_dependencies )
    message( DEBUG "${dbg_prefix} === Package dependencies ===" )
    set( PARSED_PACKAGE_DEPENDENCIES "${package_dependencies}" PARENT_SCOPE )
    # Foreach package dependency
    foreach( pkg IN LISTS package_dependencies )
      message( DEBUG "${dbg_prefix}   ${pkg} (COMPONENTS ${${pkg}_COMPONENTS}) (OR ${${pkg}_OR}) (OPTIONAL ${${pkg}_OPTIONAL})" )
      # If it has components, tell the caller
      if( ${pkg}_COMPONENTS )
        set( PARSED_${pkg}_COMPONENTS "${${pkg}_COMPONENTS}" PARENT_SCOPE )
      endif()
      # If it has OR libraries, tell the caller
      if( ${pkg}_OR )
        set( PARSED_${pkg}_OR "${${pkg}_OR}" PARENT_SCOPE )
      endif()
      # If it is optional, tell the caller
      if( ${pkg}_OPTIONAL )
        set( PARSED_${pkg}_OPTIONAL TRUE PARENT_SCOPE )
      endif()
      # If it is public, tell the caller
      if( ${pkg}_PUBLIC )
        set( PARSED_${pkg}_PUBLIC TRUE PARENT_SCOPE )
      endif()
    endforeach()
  endif()
endfunction( _create_common_internals_parse_dep )

#-------------------------------------------------------------------------------------------------------------------------------------------
# Search a package library.
# Arguments:
#     NAME lib_name [COMPONENTS cmp...]
# Variables updated:
#     PKG_FOUND
#     PKG_INCLUDE_DIRS
#     PKG_LIBRARIES
function( _create_common_internals_find_pkg )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}(${ARGV}):" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_NAME )
  unset( arg_COMPONENTS )
  unset( found )
  unset( include_dirs )
  unset( libraries )

  # Parse function arguments.
  # Option arguments: none
  # Single-value arguments: NAME
  # Multi-values arguments: COMPONENTS
  cmake_parse_arguments( arg "" "NAME" "COMPONENTS" ${ARGN} )

  # Get the library name uppercase, since some libraries return uppercase variables and some do not
  string( TOUPPER "${arg_NAME}" arg_NAME_upper )

  # Unset some previous variable to avoid beeing affected by them
  unset( ${arg_NAME}_FOUND CACHE )
  unset( ${arg_NAME_upper}_FOUND CACHE )
  unset( ${arg_NAME}_INCLUDE_DIRS CACHE )
  unset( ${arg_NAME_upper}_INCLUDE_DIRS CACHE )
  unset( ${arg_NAME}_LIBRARIES CACHE )
  unset( ${arg_NAME_upper}_LIBRARIES CACHE )

  # Test if the package was already imported globally
  if( arg_COMPONENTS )
    # If there are components, test if each component is already available
    set( found TRUE )
    foreach( cmp IN LISTS arg_COMPONENTS )
      if( NOT TARGET ${arg_NAME}::${cmp} )
        unset( found )
      endif()
    endforeach()
  else()
    # If there is no component, test if the package is already available
    if( TARGET ${arg_NAME} )
      set( found TRUE )
    endif()
  endif()

  # If the package is not already imported globally, we search it now
  if( NOT found )
    # Search package with CMAKE
    message( DEBUG "${dbg_prefix} Searching with CMAKE" )
    find_package( ${arg_NAME} ${CREATE_LIBRARY_QUIET} COMPONENTS ${arg_COMPONENTS} )

    # If the library was found using CMAKE
    if( ${arg_NAME}_FOUND OR ${arg_NAME_upper}_FOUND )

      # Set the library as found
      set( found TRUE )
      message( DEBUG "${dbg_prefix} Found via CMAKE" )

    # If the library was NOT found using CMAKE
    else()

      # Print it for debug
      message( DEBUG "${dbg_prefix} NOT Found ${arg_NAME} via CMAKE" )

      if( NOT WIN32 )

        # Search package with PKG-CONFIG
        find_package( PkgConfig REQUIRED ${CREATE_LIBRARY_QUIET} COMPONENTS ${arg_COMPONENTS} )
        pkg_check_modules( ${arg_NAME} ${CREATE_LIBRARY_QUIET} ${arg_NAME} )

        # If the library was found using PKG-CONFIG
        if( ${arg_NAME}_FOUND OR ${arg_NAME_upper}_FOUND )

          # Set the library as found
          set( found TRUE )
          message( DEBUG "${dbg_prefix} Found via PKG-CONFIG" )

        # If the library was NOT found using PKG-CONFIG
        else()

          # Print it for debug
          message( DEBUG "${dbg_prefix} Found no ${arg_NAME} package, neither with CMAKE nor with PKG-CONFIG" )

        endif()
      endif()
    endif()
  endif()

  # If the library was found
  if( found )

    # Set the library includes dirs using both provided case and upper case
    set( include_dirs "${${arg_NAME}_INCLUDE_DIRS}" )
    set( include_dirs "${include_dirs};${${arg_NAME_upper}_INCLUDE_DIRS}" )
    # Set the library components' includes dirs using both provided case and upper case
    foreach( cmp IN LISTS arg_COMPONENTS )
      set( include_dirs "${include_dirs};${${arg_NAME}${cmp}_INCLUDE_DIRS}" )
      set( include_dirs "${include_dirs};${${arg_NAME_upper}${cmp}_INCLUDE_DIRS}" )
    endforeach()
    message( DEBUG "${dbg_prefix} Include dirs: ${include_dirs}" )

    # Set the library libraries using both provided case and upper case
    set( libraries "${${arg_NAME}_LIBRARIES}" )
    set( libraries "${libraries};${${arg_NAME_upper}_LIBRARIES}" )
    # Set the library components' libraries using both provided case and upper case
    foreach( cmp IN LISTS arg_COMPONENTS )
      set( libraries "${libraries};${${arg_NAME}${cmp}_LIBRARIES}" )
      set( libraries "${libraries};${${arg_NAME_upper}${cmp}_LIBRARIES}" )
    endforeach()
    message( DEBUG "${dbg_prefix} Libraries: ${libraries}" )

    # Tell the caller
    set( PKG_FOUND TRUE PARENT_SCOPE )
    set( PKG_INCLUDE_DIRS ${include_dirs} PARENT_SCOPE )
    set( PKG_LIBRARIES ${libraries} PARENT_SCOPE )

  # If the library was not found
  else()

    # Tell the caller
    unset( PKG_FOUND PARENT_SCOPE )
    unset( PKG_INCLUDE_DIRS PARENT_SCOPE )
    unset( PKG_LIBRARIES PARENT_SCOPE )

    # Particular case: gRPC depends on Protobuf => we tell the user
    if( "${arg_NAME}" STREQUAL "gRPC" AND NOT TARGET protobuf::libprotobuf )
      message( WARNING "Package 'gRPC' depends on package 'Protobuf' but package 'Protobuf' was not previously added. Package 'gRPC' may not be found by CMAKE." )
    endif()

  endif()

endfunction( _create_common_internals_find_pkg )

#-------------------------------------------------------------------------------------------------------------------------------------------
# Create an have definition for a pckage
# Arguments:
#     LIST var_list NAME lib_name PACKAGE package_name [FOUND]
# Variables updated:
#     var_list
function( _create_common_internals_have_definition )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}(${ARGV}):" )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_FOUND )
  unset( arg_LIST )
  unset( arg_NAME )
  unset( arg_PACKAGE )
  unset( have_definition )
  unset( have_color )

  # Parse function arguments.
  # Option arguments: FOUND
  # Single-value arguments: LIST, NAME, PACKAGE
  # Multi-values arguments: none
  cmake_parse_arguments( arg "FOUND" "LIST;NAME;PACKAGE" "" ${ARGN} )

  # Create the have definition
  if( arg_FOUND )
    set( have_definition "${CREATE_LIBRARY_HAVE_PREFIX}${arg_PACKAGE}" )
    set( have_color "${ColorDefOn}" )
  else()
    set( have_definition "${CREATE_LIBRARY_HAVE_NOT_PREFIX}${arg_PACKAGE}" )
    set( have_color "${ColorWarning}" )
  endif()

  message( DEBUG "${dbg_prefix} Add HAVE definition ${have_definition}" )

  # Format the have definition by replacing forbidden characters, and uppering it
  string( TOUPPER "${have_definition}" have_definition )
  string( REPLACE "." "_" have_definition "${have_definition}" )
  string( REPLACE "-" "_" have_definition "${have_definition}" )
  string( REPLACE "::" "_" have_definition "${have_definition}" )

  # Add the definition
  message( STATUS "        ${ColorLib}${arg_NAME}${ColorReset} has definition ${have_color}${have_definition}${ColorReset}" )
  set( ${arg_LIST} "${${arg_LIST}};${have_definition}" PARENT_SCOPE )

endfunction( _create_common_internals_have_definition )

#-------------------------------------------------------------------------------------------------------------------------------------------
# Dump the dependency tree recursively
# Arguments:
#     NAME name
# Private Arguments for recursion:
#     [INDENTATION "  "] [DEPENDENCIES_PUB "dep1;dep2"] [DEPENDENCIES_PRIV "dep1;dep2"]
# Variables updated:
#     none
function( _create_common_internals_print_dep_tree )
  # Unset local variable (if the parent has a variable with the same name, it may interfere)
  unset( arg_NAME )
  unset( arg_INDENTATION )
  unset( arg_DEPENDENCIES_PUB )
  unset( arg_DEPENDENCIES_PRIV )

  # Parse function arguments.
  # Option arguments: none
  # Single-value arguments: NAME, INDENTATION
  # Multi-values arguments: DEPENDENCIES_PUB, DEPENDENCIES_PRIV
  cmake_parse_arguments( arg "" "NAME;INDENTATION" "DEPENDENCIES_PUB;DEPENDENCIES_PRIV" ${ARGN} )

  # If the name is provided, it is the recursion root
  if( arg_NAME )
    # Start the recursion by setting input variables
    set( arg_INDENTATION "" )
    set( arg_DEPENDENCIES_PUB "$ENV{${arg_NAME}_PUBLIC_DEPENDENCIES};$ENV{${arg_NAME}_PRIVATE_DEPENDENCIES}" )
    set( arg_DEPENDENCIES_PRIV "" )
    # Print a startup message
    message( STATUS "Dependency tree of ${ColorLib}${arg_NAME}${ColorReset} (visible libraries in ${BoldGreen}green${ColorReset}, invisible in ${BoldRed}red${ColorReset})" )
    message( STATUS "${ColorLib}${arg_NAME}${ColorReset}" )
  endif()

  # Public dependencies
  foreach( dep_full IN LISTS arg_DEPENDENCIES_PUB )
    if( dep_full )
      get_filename_component( dep ${dep_full} NAME )
      message( STATUS "${arg_INDENTATION}+-- ${BoldGreen}${dep}${ColorReset}" )
      _create_common_internals_print_dep_tree(
        INDENTATION "|   ${arg_INDENTATION}"
        # Public sub-dependencies stay public
        DEPENDENCIES_PUB $ENV{${dep}_PUBLIC_DEPENDENCIES}
        # Private sub-dependencies stay private
        DEPENDENCIES_PRIV $ENV{${dep}_PRIVATE_DEPENDENCIES}
      )
    endif()
  endforeach()

  # Private dependencies
  foreach( dep_full IN LISTS arg_DEPENDENCIES_PRIV )
    if( dep_full )
      get_filename_component( dep ${dep_full} NAME )
      message( STATUS "${arg_INDENTATION}+-- ${BoldRed}${dep}${ColorReset}" )
      _create_common_internals_print_dep_tree(
        INDENTATION "|   ${arg_INDENTATION}"
        # Public and private sub-dependencies become private
        DEPENDENCIES_PRIV "$ENV{${dep}_PUBLIC_DEPENDENCIES};$ENV{${dep}_PRIVATE_DEPENDENCIES}"
      )
    endif()
  endforeach()

  # If the name is provided, it is the recursion root
  if( arg_NAME )
    # Print an end message
    message( STATUS "End of ${ColorLib}${arg_NAME}${ColorReset} dependencies" )
  endif()

endfunction( _create_common_internals_print_dep_tree )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_templates )
  # If the sources have template, it must be generated before add_executable/add_library
  if( PARSED_TEMPLATES )
    # Get GIT information: Sha1 in ${GIT_HASH}
    execute_process(
      COMMAND git log -1 --format=%h
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
      OUTPUT_VARIABLE GIT_HASH
      ERROR_VARIABLE error_GIT_HASH
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE
    )
    if( error_GIT_HASH )
      string( REGEX REPLACE "\n" " " error_GIT_HASH "${error_GIT_HASH}" )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} cannot compute template ${ColorVar}GIT_HASH${ColorReset}: ${ColorWarning}${error_GIT_HASH}${ColorReset}" )
    else()
      message( DEBUG "    ${ColorLib}${arg_NAME}${ColorReset} has template variable ${ColorVar}GIT_HASH${ColorReset} = ${ColorVal}${GIT_HASH}${ColorReset}" )
    endif()
    # Get GIT information: Author date in ${GIT_DATE}
    execute_process(
      COMMAND git log -1 --format=%ai
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
      OUTPUT_VARIABLE GIT_DATE
      ERROR_VARIABLE error_GIT_DATE
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE
    )
    if( error_GIT_DATE )
      string( REGEX REPLACE "\n" " " error_GIT_DATE "${error_GIT_DATE}" )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} cannot compute template ${ColorVar}GIT_DATE${ColorReset}: ${ColorWarning}${error_GIT_DATE}${ColorReset}" )
    else()
      message( DEBUG "    ${ColorLib}${arg_NAME}${ColorReset} has template variable ${ColorVar}GIT_DATE${ColorReset} = ${ColorVal}${GIT_DATE}${ColorReset}" )
    endif()

    # For each template
    list( LENGTH PARSED_TEMPLATES nb_src_templates )
    math( EXPR nb_src_templates "${nb_src_templates} / 2 - 1" )
    foreach( index RANGE ${nb_src_templates} )
      # Retrieve the source file and its template
      math( EXPR index1 "${index} * 2" )
      list( GET PARSED_TEMPLATES ${index1} src )
      math( EXPR index2 "${index1} + 1" )
      list( GET PARSED_TEMPLATES ${index2} template )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} source file ${ColorSrc}${src}${ColorReset} has template ${ColorSrc}${template}${ColorReset}" )
      # Configure the source file from the template by replacing variables @VAR@
      configure_file( ${template} ${CMAKE_CURRENT_LIST_DIR}/${src} @ONLY )
    endforeach()
  endif()
endmacro( _create_common_internals_handle_templates )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_gettext_translations )
  # If the there are GetText translations to do
  if( arg_GETTEXT_TRANSLATIONS )

    # Dump the files
    unset( gettext_src_dirs )
    unset( gettext_po_files )
    foreach( elm IN LISTS arg_GETTEXT_TRANSLATIONS )
      if( elm MATCHES ".po$" )
        list( APPEND gettext_po_files ${CMAKE_CURRENT_LIST_DIR}/${elm} )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorLib}GetText${ColorReset} translation file ${ColorSrc}${elm}${ColorReset}" )
      else()
        list( APPEND gettext_src_dirs ${CMAKE_CURRENT_LIST_DIR}/${elm} )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} will scan for ${ColorLib}GetText${ColorReset} translations in ${ColorSrc}${elm}${ColorReset}" )
      endif()
    endforeach()

    # List relative paths to files to parse
    unset( gettext_src_files )
    foreach( dir IN LISTS gettext_src_dirs )
      unset( gettext_src_files_temp )
      file( GLOB_RECURSE gettext_src_files_temp FOLLOW_SYMLINKS LIST_DIRECTORIES true "${dir}/*" )
      foreach( abs_file IN LISTS gettext_src_files_temp )
        if( NOT IS_DIRECTORY ${abs_file} )
          file( RELATIVE_PATH rel_file "${CMAKE_CURRENT_LIST_DIR}" "${abs_file}" )
          list( APPEND gettext_src_files ${rel_file} )
        endif()
      endforeach()
    endforeach()

    # Set the template file path and remove old one
    set( gettext_pot_file "${CMAKE_BINARY_DIR}/${arg_NAME}.pot" )
    if( EXISTS "${gettext_pot_file}" )
      file( REMOVE "${gettext_pot_file}" )
    endif()

    # Create new template file
    execute_process(
      COMMAND
        xgettext --keyword=_ --language=C++ --package-name ${arg_NAME} --package-version 1.0
                --default-domain ${arg_NAME} --sort-output -o ${gettext_pot_file} ${gettext_src_files}
      WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
      OUTPUT_QUIET
      ERROR_QUIET
    )

    # Update po files
    foreach( po IN LISTS gettext_po_files )
      if( NOT EXISTS "${po}" )
        get_filename_component( po_dir "${po}" DIRECTORY )
        file( MAKE_DIRECTORY ${po_dir} )
        execute_process(
          COMMAND msginit --no-translator --input=${gettext_pot_file} --locale=fr --output=${po}
          WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
          OUTPUT_QUIET
          ERROR_QUIET
        )
      else()
        execute_process(
          COMMAND msgmerge --update ${po} ${gettext_pot_file}
          WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
          OUTPUT_QUIET
          ERROR_QUIET
        )
      endif()
    endforeach()

    # Initialize list containing the different build types possible
    set(LIST_BUILD_DIRS "")
    # Update mo files
    foreach( po IN LISTS gettext_po_files )
      get_filename_component( language "${po}" NAME_WLE )

      if( MSVC )
        # Fill in list containing the different build types possible with MSVC
        list(APPEND LIST_BUILD_DIRS
            Debug/
            Release/
            RelWithDebInfo/
            MinSizeRel/
            # x64/Debug/
            # x64/Release/
            # x86/Debug/
            # x86/Release/
            # ARM/Debug/
            # ARM/Release/
            # ARM64/Debug/
            # ARM64/Release/
        )
      endif()

      if( NOT LIST_BUILD_DIRS )
        file( MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/i18n/${language}/LC_MESSAGES )
        execute_process(
          COMMAND msgfmt --output-file=${CMAKE_BINARY_DIR}/i18n/${language}/LC_MESSAGES/${arg_NAME}.mo ${po}
          WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
          OUTPUT_QUIET
          ERROR_QUIET
          )
      else()
        foreach(BUILD_DIR ${LIST_BUILD_DIRS})
          file( MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${BUILD_DIR}i18n/${language}/LC_MESSAGES )
          execute_process(
            COMMAND msgfmt --output-file=${CMAKE_BINARY_DIR}/${BUILD_DIR}i18n/${language}/LC_MESSAGES/${arg_NAME}.mo ${po}
            WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
            OUTPUT_QUIET
            ERROR_QUIET
            )
        endforeach()
      endif()
    endforeach()

    # Remove unused files
    foreach( po IN LISTS gettext_po_files )
      get_filename_component( filepath "${po}" DIRECTORY )
      get_filename_component( filename "${po}" NAME_WLE )
      file( REMOVE "${filepath}/${filename}.po~" "${filepath}/${filename}.mo" )
    endforeach()

    # Add usefull _() alias for gettext()
    list( APPEND arg_DEFINITIONS "_=gettext" )

  endif()
endmacro( _create_common_internals_handle_gettext_translations )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_check_gettext_translations_dependencies )
  # If the there are GetText translations to do
  if( arg_GETTEXT_TRANSLATIONS )
    # Check that the internationalization library is in dependencies
    if( NOT TARGET Intl::Intl )
      message( SEND_ERROR "Cannot use GETTEXT_TRANSLATIONS section without the internationalization library. Check that the 'Intl' package is in the dependencies of ${arg_NAME}." )
    endif()
  endif()
endmacro( _create_common_internals_check_gettext_translations_dependencies )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_qt_translations )
  # If the there are Qt translations to do
  if( arg_QT_TRANSLATIONS )

    # Add the Qt LinguistTool component
    find_package(QT NAMES Qt6 Qt5 ${CREATE_LIBRARY_QUIET} COMPONENTS LinguistTools REQUIRED)
    find_package(Qt${QT_VERSION_MAJOR} ${CREATE_LIBRARY_QUIET} COMPONENTS LinguistTools REQUIRED)

    # Dump the files
    unset( ts_files_or_src )
    foreach( ts IN LISTS arg_QT_TRANSLATIONS )
      if( ts MATCHES ".ts$" )
        list( APPEND ts_files_or_src ${ts} )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorLib}Qt${QT_VERSION_MAJOR}${ColorReset} translation file ${ColorSrc}${ts}${ColorReset}" )
      else()
        list( APPEND ts_files_or_src ${CMAKE_CURRENT_LIST_DIR}/${ts} )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} will scan for ${ColorLib}Qt${QT_VERSION_MAJOR}${ColorReset} translations in ${ColorSrc}${ts}${ColorReset}" )
      endif()
    endforeach()

    # Create the translations
    if( QT_VERSION_MAJOR EQUAL 5 )
      qt5_create_translation( qm_files ${ts_files_or_src} OPTIONS "-no-obsolete" )
    elseif( QT_VERSION_MAJOR EQUAL 6 )
      qt6_create_translation( qm_files ${ts_files_or_src} OPTIONS "-no-obsolete" )
    else()
      message( SEND_ERROR "Qt translations via CMake only work with Qt5 or Qt6" )
    endif()

    # Add thre translations to the sources files list
    list( APPEND PARSED_SOURCES ${ts_files_or_src} ${qm_files} )

    #foreach( qm IN LISTS qm_files )
    #  message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has generated ${ColorLib}Qt${QT_VERSION_MAJOR}${ColorReset} translation file ${ColorSrc}${qm}${ColorReset}" )
    #endforeach()

  endif()
endmacro( _create_common_internals_handle_qt_translations )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_check_qt_translations_dependencies )
  # If the there are Qt translations to do
  if( arg_QT_TRANSLATIONS )
    # Check that the QtCore library is in dependencies
    if( NOT TARGET Qt5::Core AND NOT TARGET Qt6::Core )
      message( SEND_ERROR "Cannot use QT_TRANSLATIONS section without the QtCore library. Check that the 'Qt5' our 'Qt6' package is in the dependencies of ${arg_NAME}, with component 'Core' listed." )
    endif()
  endif()
endmacro( _create_common_internals_check_qt_translations_dependencies )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_protobuf_files )
  # Set debug prefix
  set( dbg_prefix "        ${CMAKE_CURRENT_FUNCTION}():" )

  # If the there are Qt translations to do
  if( arg_PROTOBUF_FILES )

    # Set some usefull constants
    set( lib_protobuf_target protobuf::libprotobuf )
    set( generated_files_folder ${CMAKE_CURRENT_BINARY_DIR}/_autogen_protobuf )
    set( generated_lib_name ${arg_NAME}_autogen_protobuf )
    if( Protobuf_PROTOC_EXECUTABLE STREQUAL "Protobuf_PROTOC_EXECUTABLE-NOTFOUND" OR "${Protobuf_PROTOC_EXECUTABLE}" STREQUAL "" )
      find_program( protoc_exe protoc CMAKE_FIND_ROOT_PATH_BOTH )
    else()
      set( protoc_exe "${Protobuf_PROTOC_EXECUTABLE}" )
    endif()

    # Create the directory for generated protobuf files
    file(MAKE_DIRECTORY ${generated_files_folder})

    # Check that protobuf is available
    if( NOT TARGET ${lib_protobuf_target} )
      message( SEND_ERROR "Cannot use the PROTOBUF_FILES section without the protocol buffers library. Check that the 'Protobuf' package is in the dependencies of ${arg_NAME}." )
    endif()
    if( protoc_exe STREQUAL "protoc_exe-NOTFOUND" )
      message( SEND_ERROR "Cannot use the PROTOBUF_FILES section without the protocol buffers compiler. Check that the protobuf compiler is installed." )
    endif()

    # If grpc needed
    if( "GRPC" IN_LIST arg_PROTOBUF_FILES )
      # Set some usefull constants
      set( lib_grpc_target gRPC::grpc++ )
      set( lib_grpc_reflection_target gRPC::grpc++_reflection )
      if( GRPC_CPP_PLUGIN_PROGRAM STREQUAL "GRPC_CPP_PLUGIN_PROGRAM-NOTFOUND" OR "${GRPC_CPP_PLUGIN_PROGRAM}" STREQUAL "" )
        find_program( grpc_plugin_exe grpc_cpp_plugin CMAKE_FIND_ROOT_PATH_BOTH )
      else()
        set( grpc_plugin_exe "${GRPC_CPP_PLUGIN_PROGRAM}" )
      endif()
      # Check that grpc is available
      if( NOT TARGET ${lib_grpc_target} OR NOT TARGET ${lib_grpc_reflection_target} )
        message( SEND_ERROR "Cannot have GRPC files in the PROTOBUF_FILES section without the grpc library. Check that the 'gRPC' package is in the dependencies of ${arg_NAME}." )
      endif()
      if( grpc_plugin_exe STREQUAL "grpc_plugin_exe-NOTFOUND" )
        message( SEND_ERROR "Cannot have GRPC files in the PROTOBUF_FILES section without the protocol buffers compiler. Check that the protobuf compiler grpc is installed." )
      endif()
    endif()

    # Clear the list of generated sources
    unset( proto_sources )

    # We first expect a source file name and the SIMPLE keyword is optionnal
    set( proto_step "SIMPLE" )

    # For each element in the protobuf files list
    foreach( protobuf_file IN LISTS arg_PROTOBUF_FILES )

      # Print it
      message( DEBUG "${dbg_prefix} New element to parse: ${protobuf_file}" )

      # Get some info about the file
      get_filename_component( protobuf_file_fullpath "${CMAKE_CURRENT_LIST_DIR}/${protobuf_file}" ABSOLUTE )
      get_filename_component( protobuf_file_name "${protobuf_file_fullpath}" NAME_WLE )
      get_filename_component( protobuf_file_folder "${protobuf_file_fullpath}" DIRECTORY )

      # Create some usefull variables
      set( generated_protobuf_cpp "${generated_files_folder}/${protobuf_file_name}.pb.cc" )
      set( generated_protobuf_hpp "${generated_files_folder}/${protobuf_file_name}.pb.h" )
      set( generated_grpc_cpp "${generated_files_folder}/${protobuf_file_name}.grpc.pb.cc" )
      set( generated_grpc_hpp "${generated_files_folder}/${protobuf_file_name}.grpc.pb.h" )

      # If the source element is in fact a keyword
      if( protobuf_file STREQUAL "SIMPLE" OR protobuf_file STREQUAL "GRPC" )
        # Change the current step accordingly to the keyword
        set( proto_step "${protobuf_file}" )
        message( DEBUG "${dbg_prefix} Change step to: ${proto_step}" )

      # If we follow a SIMPLE keyword
      elseif( proto_step STREQUAL "SIMPLE" )

        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorOptOff}SIMPLE${ColorReset} protobuf file ${ColorSrc}${protobuf_file}${ColorReset}" )

        # Add a command to generate the grpc files
        add_custom_command(
          OUTPUT
            "${generated_protobuf_cpp}"
            "${generated_protobuf_hpp}"
          COMMAND
            ${protoc_exe}
          ARGS
            --cpp_out "${generated_files_folder}"
            -I "${protobuf_file_folder}"
            "${protobuf_file_fullpath}"
          DEPENDS
            "${protobuf_file_fullpath}"
          COMMENT
            "Parsing protobuf file ${protobuf_file}"
        )

        # Add generated sources to the list
        list( APPEND proto_sources
          "${generated_protobuf_cpp}"
          "${generated_protobuf_hpp}"
        )

        # And go back to simple step
        set( proto_step "SIMPLE" )

      # If we follow a GRPC keyword
      elseif( proto_step STREQUAL "GRPC" )

        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorOptOn}GRPC${ColorReset} protobuf file ${ColorSrc}${protobuf_file}${ColorReset}" )

        # Add a command to generate the grpc files
        add_custom_command(
          OUTPUT
            "${generated_protobuf_cpp}"
            "${generated_protobuf_hpp}"
            "${generated_grpc_cpp}"
            "${generated_grpc_hpp}"
          COMMAND
            ${protoc_exe}
          ARGS
            --grpc_out "${generated_files_folder}"
            --cpp_out "${generated_files_folder}"
            -I "${protobuf_file_folder}"
            --plugin=protoc-gen-grpc="${grpc_plugin_exe}"
            "${protobuf_file_fullpath}"
          DEPENDS
            "${protobuf_file_fullpath}"
          COMMENT
            "Parsing grpc file ${protobuf_file}"
        )

        # Add generated sources to the list
        list( APPEND proto_sources
          "${generated_protobuf_cpp}"
          "${generated_protobuf_hpp}"
          "${generated_grpc_cpp}"
          "${generated_grpc_hpp}"
        )

        # And go back to simple step
        set( proto_step "SIMPLE" )

      endif()

    endforeach()

    # Create a library with the generated protobuf files
    add_library( ${generated_lib_name} ${proto_sources} )

    # Link the generated library
    target_link_libraries( ${generated_lib_name} PRIVATE ${lib_grpc_reflection_target} ${lib_grpc_target} PUBLIC ${lib_protobuf_target} )

    # Add the generated library to the project
    target_include_directories( ${arg_NAME} PRIVATE ${generated_files_folder} )
    target_link_libraries( ${arg_NAME} PRIVATE ${generated_lib_name} )

  endif()
endmacro( _create_common_internals_handle_protobuf_files )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_language_version )

  if( arg_C_VERSION )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}C version ${arg_C_VERSION}${ColorReset}" )
    set_property( TARGET ${arg_NAME} PROPERTY C_STANDARD ${arg_C_VERSION} )
    set_property( TARGET ${arg_NAME} PROPERTY C_STANDARD_REQUIRED ON )
  endif()

  if( arg_CPP_VERSION )
    message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} has ${ColorFlags}C++ version ${arg_CPP_VERSION}${ColorReset}" )
    set_property( TARGET ${arg_NAME} PROPERTY CXX_STANDARD ${arg_CPP_VERSION} )
    set_property( TARGET ${arg_NAME} PROPERTY CXX_STANDARD_REQUIRED ON )
  endif()

endmacro( _create_common_internals_handle_language_version )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_compile_flags )
  # We do not print all files, be only those which have specific build options
  if( PARSED_COMPILE_FLAGS )
    list( LENGTH PARSED_COMPILE_FLAGS nb_specific_compile_flags )
    math( EXPR nb_specific_compile_flags "${nb_specific_compile_flags} / 2 - 1" )
    foreach( index RANGE ${nb_specific_compile_flags} )
      # Retrieve the source file and its compile flags
      math( EXPR index1 "${index} * 2" )
      list( GET PARSED_COMPILE_FLAGS ${index1} src )
      math( EXPR index2 "${index1} + 1" )
      list( GET PARSED_COMPILE_FLAGS ${index2} flags )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} source file ${ColorSrc}${src}${ColorReset} has compilation flags ${ColorFlags}${flags}${ColorReset}" )
      # Set the file properties
      set_source_files_properties( "${src}" PROPERTIES COMPILE_FLAGS "${flags}" )
    endforeach()
  endif()

  # If the project has specific compile flags, we print them here
  if( arg_COMPILE_FLAGS )
    if( PARSED_COMPILE_FLAGS )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} other source files have compilation flags ${ColorFlags}${arg_COMPILE_FLAGS}${ColorReset}" )
      # All source files that do not have specific properties have the same properties
      foreach( src IN LISTS PARSED_SOURCES )
        list( FIND PARSED_COMPILE_FLAGS "${src}" src_index )
        if( ${src_index} EQUAL -1 )
          set_source_files_properties( "${src}" PROPERTIES COMPILE_FLAGS "${arg_COMPILE_FLAGS}" )
        endif()
      endforeach()
    else()
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} sources files have compilation flags ${ColorFlags}${arg_COMPILE_FLAGS}${ColorReset}" )
      # All the target's files have the same properties
      set_target_properties( ${arg_NAME} PROPERTIES COMPILE_FLAGS "${arg_COMPILE_FLAGS}" )
    endif()
  endif()
endmacro( _create_common_internals_handle_compile_flags )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_compile_definitions )
  # We do not print all files, be only those which have specific build options
  if( PARSED_DEFINITIONS )
    list( LENGTH PARSED_DEFINITIONS nb_specific_definitions )
    math( EXPR nb_specific_definitions "${nb_specific_definitions} / 2 - 1" )
    foreach( index RANGE ${nb_specific_definitions} )
      # Retrieve the source file and its definitions
      math( EXPR index1 "${index} * 2" )
      list( GET PARSED_DEFINITIONS ${index1} src )
      math( EXPR index2 "${index1} + 1" )
      list( GET PARSED_DEFINITIONS ${index2} def )
      string( REPLACE "|" ";" def "${def}" )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} source file ${ColorSrc}${src}${ColorReset} has definition ${ColorDefOn}${def}${ColorReset}" )
      # Set the file properties
      set_source_files_properties( "${src}" PROPERTIES COMPILE_DEFINITIONS "${def}" )
    endforeach()
  endif()

  # If the project has specific defintions, we print them here
  if( arg_DEFINITIONS )
    if( PARSED_DEFINITIONS )
      foreach( def IN LISTS arg_DEFINITIONS )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} other sources files have definition ${ColorDefOn}${def}${ColorReset}" )
      endforeach()
      # All source files that do not have specific properties have the same properties
      foreach( src IN LISTS PARSED_SOURCES )
        list( FIND PARSED_DEFINITIONS "${src}" src_index )
        if( ${src_index} EQUAL -1 )
          set_source_files_properties( "${src}" PROPERTIES COMPILE_DEFINITIONS "${arg_DEFINITIONS}" )
        endif()
      endforeach()
    else()
      foreach( def IN LISTS arg_DEFINITIONS )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} sources files have definition ${ColorDefOn}${def}${ColorReset}" )
      endforeach()
      # All the target's files have the same properties
      set_target_properties( ${arg_NAME} PROPERTIES COMPILE_DEFINITIONS "${arg_DEFINITIONS}" )
    endif()
  endif()
endmacro( _create_common_internals_handle_compile_definitions )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_internal_dependencies )
  # If the project has internal library dependencies
  if( PARSED_INTERNAL_DEPENDENCIES )
    set( dep_list_pub "" )
    set( dep_list_priv "" )
    foreach( dep_full IN LISTS PARSED_INTERNAL_DEPENDENCIES )
      get_filename_component( dep ${dep_full} NAME )
      if( PARSED_${dep_full}_PUBLIC )
        set( public_str "${ColorOptOn}PUBLIC${ColorReset}" )
      else()
        set( public_str "${ColorOptOff}PRIVATE${ColorReset}" )
      endif()
      if( PARSED_${dep_full}_OPTIONAL )
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOn}OPTIONAL${ColorReset} ${public_str} internal library ${ColorLib}${dep}${ColorReset}" )
      else()
        message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOff}REQUIRED${ColorReset} ${public_str} internal library ${ColorLib}${dep}${ColorReset}" )
      endif()
      if( TARGET ${dep} )
        set( found "FOUND" )
        if( PARSED_${dep_full}_PUBLIC )
          list( APPEND dep_list_pub ${dep} )
        else()
          list( APPEND dep_list_priv ${dep} )
        endif()
      else()
        unset( found )
        if( NOT PARSED_${dep_full}_OPTIONAL )
          message( SEND_ERROR "Found no ${dep} internal library. Check the order of libraries to configure (${dep} must be configured before ${arg_NAME})." )
        endif()
      endif()
      _create_common_internals_have_definition(
        LIST arg_DEFINITIONS
        NAME ${arg_NAME}
        PACKAGE ${dep}
        ${found}
      )
    endforeach()

    # Add link libraries to the target
    target_link_libraries( ${arg_NAME} PUBLIC ${dep_list_pub} PRIVATE ${dep_list_priv} )
    set( ENV{${arg_NAME}_PUBLIC_DEPENDENCIES} "${dep_list_pub}" )
    set( ENV{${arg_NAME}_PRIVATE_DEPENDENCIES} "${dep_list_priv}" )
  endif()
endmacro( _create_common_internals_handle_internal_dependencies )

#-------------------------------------------------------------------------------------------------------------------------------------------
macro( _create_common_internals_handle_packages_dependencies )
  # If the project has package library dependencies
  if( PARSED_PACKAGE_DEPENDENCIES )
    set( includes_priv "" )
    set( libraries_pub "" )
    set( libraries_priv "" )
    foreach( pkg IN LISTS PARSED_PACKAGE_DEPENDENCIES )
      set( pkg_cmp )
      if( PARSED_${pkg}_COMPONENTS )
        string( REPLACE ";" "${ColorReset} and ${ColorLib}" pkg_cmp "${PARSED_${pkg}_COMPONENTS}" )
        set( pkg_cmp "(component(s) ${ColorLib}${pkg_cmp}${ColorReset})" )
      endif()
      if( PARSED_${pkg}_PUBLIC )
        set( public_str "${ColorOptOn}PUBLIC${ColorReset}" )
      else()
        set( public_str "${ColorOptOff}PRIVATE${ColorReset}" )
      endif()
      # If the if it is an OR package, one package must be found amongst several ones
      if( PARSED_${pkg}_OR )
        string( REPLACE ";" "${ColorReset} or ${ColorLib}" pkg_or "${PARSED_${pkg}_OR}" )
        if( PARSED_${pkg}_OPTIONAL )
          message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOn}OPTIONAL${ColorReset} ${public_str} package library ${ColorLib}${pkg}${ColorReset} [${ColorLib}${pkg_or}${ColorReset}] ${pkg_cmp}" )
        else()
          message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOff}REQUIRED${ColorReset} ${public_str} package library ${ColorLib}${pkg}${ColorReset} [${ColorLib}${pkg_or}${ColorReset}] ${pkg_cmp}" )
        endif()
        unset( found_or )
        unset( found_or_str )
        foreach( elm IN LISTS PARSED_${pkg}_OR )
          # Search the package
          _create_common_internals_find_pkg( NAME ${elm} COMPONENTS ${PARSED_${pkg}_COMPONENTS} )
          if( PKG_FOUND )
            list( APPEND includes_priv ${PKG_INCLUDE_DIRS} )
            if( PARSED_${pkg}_PUBLIC )
              list( APPEND libraries_pub ${PKG_LIBRARIES} )
              if( DUMP_DEPENDENCY_TREE_WITH_PACKAGES )
                set( ENV{${arg_NAME}_PUBLIC_DEPENDENCIES} "$ENV{${arg_NAME}_PUBLIC_DEPENDENCIES};${pkg}" )
              endif()
            else()
              list( APPEND libraries_priv ${PKG_LIBRARIES} )
              if( DUMP_DEPENDENCY_TREE_WITH_PACKAGES )
                set( ENV{${arg_NAME}_PRIVATE_DEPENDENCIES} "$ENV{${arg_NAME}_PRIVATE_DEPENDENCIES};${pkg}" )
              endif()
            endif()
            set( found_or TRUE )
            set( found "FOUND" )
            set( found_or_str "FOUND" )
          else()
            unset( found )
          endif()
          _create_common_internals_have_definition(
            LIST arg_DEFINITIONS
            NAME ${arg_NAME}
            PACKAGE ${pkg}_${elm}
            ${found}
          )
          foreach( cmp IN LISTS PARSED_${pkg}_COMPONENTS )
            _create_common_internals_have_definition(
              LIST arg_DEFINITIONS
              NAME ${arg_NAME}
              PACKAGE ${pkg}_${elm}_${cmp}
              ${found}
            )
          endforeach()
        endforeach()
        if( NOT found_or )
          if( NOT PARSED_${pkg}_OPTIONAL )
            message( SEND_ERROR "Found no ${pkg} package library. At least one is required amongst ${PARSED_${pkg}_OR}. Consider installing development packages." )
          endif()
        endif()
        _create_common_internals_have_definition(
          LIST arg_DEFINITIONS
          NAME ${arg_NAME}
          PACKAGE ${pkg}
          ${found_or_str}
        )

      # If it is not an OR package, it is simplier
      else()
        if( PARSED_${pkg}_OPTIONAL )
          message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOn}OPTIONAL${ColorReset} ${public_str} package library ${ColorLib}${pkg}${ColorReset} ${pkg_cmp}" )
        else()
          message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} depends on ${ColorOptOff}REQUIRED${ColorReset} ${public_str} package library ${ColorLib}${pkg}${ColorReset} ${pkg_cmp}" )
        endif()
        # Search the package
        _create_common_internals_find_pkg( NAME ${pkg} COMPONENTS ${PARSED_${pkg}_COMPONENTS} )
        if( PKG_FOUND )
          list( APPEND includes_priv ${PKG_INCLUDE_DIRS} )
          if( PARSED_${pkg}_PUBLIC )
            list( APPEND libraries_pub ${PKG_LIBRARIES} )
            if( DUMP_DEPENDENCY_TREE_WITH_PACKAGES )
              set( ENV{${arg_NAME}_PUBLIC_DEPENDENCIES} "$ENV{${arg_NAME}_PUBLIC_DEPENDENCIES};${pkg}" )
            endif()
          else()
            list( APPEND libraries_priv ${PKG_LIBRARIES} )
            if( DUMP_DEPENDENCY_TREE_WITH_PACKAGES )
              set( ENV{${arg_NAME}_PRIVATE_DEPENDENCIES} "$ENV{${arg_NAME}_PRIVATE_DEPENDENCIES};${pkg}" )
            endif()
          endif()
          set( found "FOUND" )
        else()
          if( NOT PARSED_${pkg}_OPTIONAL )
            message( SEND_ERROR "Found no ${pkg} package library. Consider installing development packages." )
          endif()
          unset( found )
        endif()

        _create_common_internals_have_definition(
          LIST arg_DEFINITIONS
          NAME ${arg_NAME}
          PACKAGE ${pkg}
          ${found}
        )
        foreach( cmp IN LISTS PARSED_${pkg}_COMPONENTS )
          _create_common_internals_have_definition(
            LIST arg_DEFINITIONS
            NAME ${arg_NAME}
            PACKAGE ${pkg}_${cmp}
            ${found}
          )
        endforeach()

      endif()
    endforeach()
    # Add include libraries to the target
    target_include_directories( ${arg_NAME} PRIVATE ${includes_priv} )
    # Add link libraries to the target
    target_link_libraries( ${arg_NAME} PUBLIC ${libraries_pub} PRIVATE ${libraries_priv} )
    # Add Qt specific options
    if( libraries_pub MATCHES "Qt[456]" OR libraries_priv MATCHES "Qt[456]" )
      message( STATUS "    ${ColorLib}${arg_NAME}${ColorReset} uses Qt so it has properties ${ColorFlags}AUTOMOC AUTOUIC AUTORCC${ColorReset}" )
      set_target_properties( ${arg_NAME} PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON )
    endif()
  endif()
endmacro( _create_common_internals_handle_packages_dependencies )
