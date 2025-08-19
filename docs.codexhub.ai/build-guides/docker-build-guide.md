# FreeSWITCH Docker Build Guide

This guide covers how to successfully build FreeSWITCH using Docker, including troubleshooting common build issues.

## Prerequisites

- Docker installed on your system
- Git installed on your system
- Approximately 8GB+ free disk space
- Basic knowledge of Docker and command-line operations

## Quick Start

Clone the FreeSWITCH repository and build the Docker image:

```bash
git clone https://github.com/signalwire/freeswitch.git
cd freeswitch
docker build -t freeswitch:latest .
```

## Understanding the Build Process

The FreeSWITCH build process uses the GNU Autotools build system (autoconf, automake, libtool) and follows these steps:

1. **Bootstrap**: Prepares the build environment (`./bootstrap.sh`)
2. **Configure**: Configures the build with specific options (`./configure`)
3. **Build**: Compiles the source code (`make`)
4. **Install**: Installs FreeSWITCH into the target directory (`make install`)
5. **Sound Files**: Installs required sound files (`make cd-sounds-install`)

## Build System Structure

Key files in the build system:

- `bootstrap.sh`: Script to initialize the build system
- `configure.ac`: Autoconf template file that generates the `configure` script
- `Makefile.am`: Template for generating the `Makefile`
- `acinclude.m4`: Contains custom macro definitions
- `m4/`: Directory containing autoconf macros
- `build/config/`: Directory containing build configuration files

## Common Build Issues and Solutions

### 1. Missing Autotools Macros

**Symptoms**: 
- Errors about undefined macros (AC_SUBST, AM_INIT_AUTOMAKE, etc.)
- Errors about missing m4 files

**Solution**:
- Create an `m4` directory in the project root
- Copy required libtool macros to the `m4` directory
- Add `AC_CONFIG_MACRO_DIRS([m4])` to configure.ac
- Add `ACLOCAL_AMFLAGS = -I m4` to Makefile.am

```bash
# Example fix
mkdir -p m4
cp /usr/share/aclocal/libtool*.m4 m4/
echo "AC_CONFIG_MACRO_DIRS([m4])" >> configure.ac
echo "ACLOCAL_AMFLAGS = -I m4" >> Makefile.am
```

### 2. Missing Build Configuration Files

**Symptoms**:
- Errors about missing config files like `ax_compiler_vendor.m4`

**Solution**:
- Ensure all files referenced in `acinclude.m4` exist in the specified locations
- Update the build configuration to include these files

### 3. AM_CONDITIONAL Errors

**Symptoms**:
- Errors like "X does not appear in AM_CONDITIONAL"

**Solution**:
- These typically mean the autoconf process didn't complete properly
- Fixing the macro issues usually resolves these errors

## Advanced Configuration

### Custom Build Options

FreeSWITCH supports many build options. Common ones include:

```
--enable-portable-binary    Build a portable binary
--prefix=PATH               Install architecture-independent files in PATH
--with-rundir=DIR           Runtime directory path
--with-logdir=DIR           Log directory path
```

### Optimizing Docker Builds

For faster builds:

1. Use build caching:
```bash
docker build --build-arg BUILDKIT_INLINE_CACHE=1 -t freeswitch:latest .
```

2. Use multi-stage builds to reduce final image size
3. Consider using Docker BuildKit:
```bash
DOCKER_BUILDKIT=1 docker build -t freeswitch:latest .
```

## Running the FreeSWITCH Container

Once built, you can run FreeSWITCH as follows:

```bash
docker run --name freeswitch -p 5060:5060/udp -p 5060:5060/tcp -p 8021:8021 freeswitch:latest
```

For persistent configuration, mount volumes:

```bash
docker run --name freeswitch \
  -v freeswitch-conf:/opt/freeswitch/conf \
  -v freeswitch-recordings:/opt/freeswitch/recordings \
  -p 5060:5060/udp -p 5060:5060/tcp -p 8021:8021 \
  freeswitch:latest
```

## Troubleshooting

For detailed logs during the build:

```bash
docker build --progress=plain -t freeswitch:latest .
```

To debug a failed build:

```bash
# Start an interactive shell in a container with the build environment
docker run -it --rm debian:bullseye-slim /bin/bash

# Inside the container, install required packages and try building manually
apt-get update && apt-get install -y git build-essential automake autoconf libtool-bin
git clone https://github.com/signalwire/freeswitch.git
cd freeswitch
./bootstrap.sh -j -v
```

## Further Resources

- [FreeSWITCH Documentation](https://freeswitch.org/confluence/)
- [FreeSWITCH GitHub Repository](https://github.com/signalwire/freeswitch)
- [GNU Autotools Documentation](https://www.gnu.org/software/automake/manual/html_node/index.html)