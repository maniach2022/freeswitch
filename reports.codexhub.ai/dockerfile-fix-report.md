# FreeSWITCH Docker Build Error Fix Report

## Issue Summary
The build process for the FreeSWITCH Docker image was failing during the `./bootstrap.sh -j` phase with the following error:

```
12.66 checking for mawk... mawk
12.66 checking whether make sets $(MAKE)... yes
12.68 checking for a BSD-compatible install... /usr/bin/install -c
12.70 ./configure: line 5078: AM_PROG_CC_C_O: command not found
12.70 ./configure: line 5079: syntax error near unexpected token `disable-static'
12.70 ./configure: line 5079: `LT_INIT(disable-static)'
```

## Root Cause
The error messages indicate missing autoconf macros that are required for the build process:

1. `AM_PROG_CC_C_O` - A missing automake macro
2. `LT_INIT(disable-static)` - A missing libtool macro

These macros are part of the GNU Build System (Autotools) and are typically provided by packages like `autoconf-archive` and proper versions of `libtool`.

## Solution Applied

The following changes were made to the Dockerfile:

1. Added missing dependencies:
   - `autoconf-archive` - Provides additional autoconf macros
   - `libtool` - Installed in addition to `libtool-bin` to ensure all necessary libtool files are available

2. Modified the bootstrap process:
   - Added verbose output to the bootstrap process (`-v` flag) for better debugging
   - Added explicit autotools steps after bootstrap to ensure all necessary configuration steps are completed:
     - `aclocal` - Generates aclocal.m4 with all necessary macros
     - `libtoolize --force` - Forces libtool setup
     - `autoconf` - Regenerates the configure script
     - `automake --add-missing` - Ensures all required files are present

3. Ensured these dependencies are also removed during the cleanup phase to maintain a clean final image

## Technical Details

The issue occurs because the FreeSWITCH build process relies on specific autoconf and libtool macros that weren't available in the base image. The `AM_PROG_CC_C_O` macro is normally provided by automake, while the `LT_INIT` macro is provided by libtool. The `autoconf-archive` package includes additional macros that might be needed during the configuration process.

In FreeSWITCH's `configure.ac` file, these macros are used for:
- Setting up the C compiler options
- Configuring libtool to disable static libraries

When these macros aren't properly available, the `./configure` script generation fails during the bootstrap process, preventing the build from proceeding.

## Verification
The modified Dockerfile should now successfully build the FreeSWITCH image by properly installing and configuring all necessary build dependencies.

## Recommendations for Future Builds

1. Always include `autoconf-archive` when building projects with complex autotools requirements
2. Consider using both `libtool` and `libtool-bin` packages for complete libtool functionality
3. For troubleshooting similar issues, use the verbose flag (`-v`) with bootstrap scripts to see more detailed output
4. Consider adding explicit autotools steps (aclocal, libtoolize, autoconf, automake) after bootstrapping for complex builds