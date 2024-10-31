# Usage: configure_sanitizer( [ASAN] [LSAN] [UBSAN] [TSAN] )
# TSAN prevails on ASAN and LSAN
function( configure_sanitizer )
  unset( arg_ASAN )
  unset( arg_LSAN )
  unset( arg_UBSAN )
  unset( arg_TSAN )
  unset( arg_UNPARSED_ARGUMENTS )

  cmake_parse_arguments(arg "ASAN;LSAN;UBSAN;TSAN" "" "" ${ARGN})

  # Stop immediately if unknown argument
  if( arg_UNPARSED_ARGUMENTS )
    message( FATAL_ERROR "Unknown argument(s) in the configure_sanitizer function: ${arg_UNPARSED_ARGUMENTS}" )
  endif()

  message(STATUS "CONFIGURING SANITIZER")
  # ===== AddressSanitizer =====
  if( arg_ASAN )
    if( arg_TSAN )
      message(WARNING "Cannot use ASAN with TSAN => disabling ASAN")
    else()
      message("   -- Enabling ASAN")
      # Enable AddressSanitizer, a fast memory error detector. Memory access instructions are instrumented
      # to detect out-of-bounds and use-after-free bugs. The option enables -fsanitize-address-use-after-scope.
      # See https://github.com/google/sanitizers/wiki/AddressSanitizer for more details. The run-time behavior
      # can be influenced using the ASAN_OPTIONS environment variable. When set to help=1, the available
      # options are shown at startup of the instrumented program. See
      # https://github.com/google/sanitizers/wiki/AddressSanitizerFlags#run-time-flags for a list of supported options.
      # The option cannot be combined with -fsanitize=thread or -fsanitize=hwaddress.
      add_compile_options("-fsanitize=address")
      add_link_options("-fsanitize=address")
    endif()
  endif()

  # ===== LeakSanitizer =====
  if( arg_LSAN )
    if( arg_TSAN )
      message(WARNING "Cannot use LSAN with TSAN => disabling LSAN")
    else()
      message("   -- Enabling LSAN")
      # Enable LeakSanitizer, a memory leak detector. This option only matters for linking of executables
      # and the executable is linked against a library that overrides malloc and other allocator functions.
      # See https://github.com/google/sanitizers/wiki/AddressSanitizerLeakSanitizer for more details. The
      # run-time behavior can be influenced using the LSAN_OPTIONS environment variable.
      # The option cannot be combined with -fsanitize=thread.
      add_compile_options("-fsanitize=leak")
      add_link_options("-fsanitize=leak")
    endif()
  endif()

  # ===== UndefinedBehaviorSanitizer =====
  if( arg_UBSAN )
    message("   -- Enabling UBSAN")
    # Enable UndefinedBehaviorSanitizer, a fast undefined behavior detector. Various computations are
    # instrumented to detect undefined behavior at runtime. See
    # https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html for more details. The run-time behavior
    # can be influenced using the UBSAN_OPTIONS environment variable.
    add_compile_options("-fsanitize=undefined")
    add_link_options("-fsanitize=undefined")
  endif()

  # ===== ThreadSanitizer =====
  if( arg_TSAN )
    message("   -- Enabling TSAN")
    # Enable ThreadSanitizer, a fast data race detector. Memory access instructions are instrumented
    # to detect data race bugs. See https://github.com/google/sanitizers/wiki#threadsanitizer for more
    # details. The run-time behavior can be influenced using the TSAN_OPTIONS environment variable;
    # see https://github.com/google/sanitizers/wiki/ThreadSanitizerFlags for a list of supported options.
    # The option cannot be combined with -fsanitize=address, -fsanitize=leak.
    add_compile_options("-fsanitize=thread")
    add_link_options("-fsanitize=thread")
  endif()

endfunction(configure_sanitizer)
