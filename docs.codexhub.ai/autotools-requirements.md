# FreeSWITCH Autotools Build System Requirements

This document outlines the requirements and best practices for the FreeSWITCH build system using GNU Autotools.

## Required Tools

FreeSWITCH requires the following tools to build from source:

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| autoconf | 2.69 | Generates the configure script |
| automake | 1.16 | Generates Makefiles |
| libtool | 2.4.6 | Handles shared library creation |
| pkg-config | 0.29 | Helps find library dependencies |
| make | 4.2 | Manages the build process |
| gcc/g++ | 7.0+ | Compiles source files |

## Directory Structure

The FreeSWITCH build system follows this directory structure:

```
freeswitch/
├── build/
│   └── config/        # Build-specific configuration files
├── m4/                # Autoconf macro files
├── configure.ac       # Main configuration template
├── Makefile.am        # Main Makefile template
├── acinclude.m4       # Custom macro includes
├── bootstrap.sh       # Script to initialize the build system
```

## Required Configuration

For proper operation, the build system must have:

1. An `m4` directory containing all necessary autoconf macros
2. The following directive in `configure.ac`:
   ```
   AC_CONFIG_MACRO_DIRS([m4])
   ```
3. The following directive in `Makefile.am`:
   ```
   ACLOCAL_AMFLAGS = -I m4
   ```

## Essential Macros

The build requires these essential macros to be available:

- Basic autoconf macros:
  - AC_SUBST
  - AC_DEFINE
  - AC_CHECK_LIB
  - AC_CHECK_HEADER
  - AC_CHECK_FUNCS
  - AC_CHECK_TYPES

- Automake macros:
  - AM_INIT_AUTOMAKE
  - AM_CONDITIONAL
  - AM_PROG_CC_C_O

- Libtool macros:
  - LT_INIT

## Dependencies in Docker

When building in a Docker environment, ensure these files are available:

1. **System libtool macros**:
   ```bash
   /usr/share/aclocal/libtool.m4
   /usr/share/aclocal/ltargz.m4
   /usr/share/aclocal/ltdl.m4
   /usr/share/aclocal/ltoptions.m4
   /usr/share/aclocal/ltsugar.m4
   /usr/share/aclocal/ltversion.m4
   /usr/share/aclocal/lt~obsolete.m4
   ```

2. **Custom macro files** referenced in `acinclude.m4`:
   ```
   build/config/ax_compiler_vendor.m4
   build/config/ax_cflags_warn_all_ansi.m4
   # ... etc
   ```

## Build Process Steps

The standard build process follows these steps:

1. **Bootstrap**: Initialize the build system
   ```bash
   ./bootstrap.sh -j -v
   ```

2. **Configure**: Configure for target environment
   ```bash
   ./configure --prefix=/opt/freeswitch
   ```

3. **Build**: Compile the source code
   ```bash
   make -j$(nproc)
   ```

4. **Install**: Install FreeSWITCH
   ```bash
   make install
   ```

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Undefined macros | Add missing macro files to the `m4` directory |
| Missing config files | Ensure all files referenced in `acinclude.m4` exist |
| AM_CONDITIONAL errors | Check that bootstrap completed successfully |
| libtoolize warnings | Add `AC_CONFIG_MACRO_DIRS([m4])` to `configure.ac` |
| aclocal warnings | Add `ACLOCAL_AMFLAGS = -I m4` to `Makefile.am` |

## Best Practices

1. **Macro Management**:
   - Keep all autoconf macros in the `m4` directory
   - Reference them correctly in configuration files

2. **Dependency Handling**:
   - Use `pkg-config` when possible to detect dependencies
   - Provide clear error messages when dependencies are missing

3. **Conditional Building**:
   - Define all conditions in `configure.ac` using `AM_CONDITIONAL`
   - Reference these conditions properly in `Makefile.am`

4. **Docker Building**:
   - Ensure all build dependencies are installed in the Dockerfile
   - Copy or generate all required macro files before running bootstrap