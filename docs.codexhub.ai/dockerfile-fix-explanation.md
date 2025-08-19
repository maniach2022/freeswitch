# FreeSWITCH Docker Build Fix

## Problem Analysis

The build failure was related to autotools configuration issues. The main error messages indicated:

1. Missing `m4` directory and macros:
   ```
   libtoolize: Consider adding 'AC_CONFIG_MACRO_DIRS([m4])' to configure.ac,
   libtoolize: and rerunning libtoolize and aclocal.
   libtoolize: Consider adding '-I m4' to ACLOCAL_AMFLAGS in Makefile.am.
   ```

2. Missing macro definitions:
   ```
   configure.ac:7: error: possibly undefined macro: AC_SUBST
   configure.ac:16: error: possibly undefined macro: AM_INIT_AUTOMAKE
   ```

3. Missing `m4` files:
   ```
   aclocal: error: acinclude.m4:1: file 'build/config/ax_compiler_vendor.m4' does not exist
   ```

4. AM_CONDITIONAL issues:
   ```
   Makefile.am:6: error: SYSTEM_APR does not appear in AM_CONDITIONAL
   Makefile.am:118: error: ENABLE_LIBYUV does not appear in AM_CONDITIONAL
   ```

## Solution

The fix addressed these issues by:

1. Creating the `m4` directory to store autoconf macros
2. Copying essential libtool macros from the system to the `m4` directory:
   - libtool.m4
   - ltargz.m4
   - ltdl.m4
   - ltoptions.m4
   - ltsugar.m4
   - ltversion.m4
   - lt~obsolete.m4

3. Adding the required configuration to make autotools aware of the m4 directory:
   - Added `AC_CONFIG_MACRO_DIRS([m4])` to configure.ac
   - Added `ACLOCAL_AMFLAGS = -I m4` to Makefile.am

4. Running bootstrap in verbose mode to catch any remaining issues

This approach resolves the undefined macro errors by ensuring that all required autotools macros are properly included and accessible during the build process.

## Best Practices

For projects using autotools build system:

1. Always include a dedicated `m4` directory for storing autoconf macros
2. Configure `ACLOCAL_AMFLAGS = -I m4` in your Makefile.am
3. Add `AC_CONFIG_MACRO_DIRS([m4])` to your configure.ac
4. When using Docker, ensure all build-time dependencies are properly installed
5. Make sure required macro files are either copied into your project or available from system paths

These practices help ensure a more portable and robust build process, especially in containerized environments where system configurations may vary.