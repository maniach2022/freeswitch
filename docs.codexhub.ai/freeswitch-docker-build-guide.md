# FreeSWITCH Docker Build Guide

## Introduction
This document provides guidance on building the FreeSWITCH Docker image, including common issues and solutions. The FreeSWITCH build process relies on the GNU Autotools system and requires specific dependencies to complete successfully.

## Prerequisites
To build the FreeSWITCH Docker image, you need:

- Docker installed on your system
- Internet connection for downloading dependencies
- At least 4GB of available memory
- 10GB+ of free disk space

## Build Process

### Basic Build Command
To build the FreeSWITCH Docker image:

```bash
docker build -t freeswitch:latest .
```

### Using Build Arguments
For customized builds, you can use Docker build arguments:

```bash
docker build \
  --build-arg FS_USER=custom_user \
  --build-arg FS_HOME=/opt/custom_path \
  -t freeswitch:custom .
```

## Running FreeSWITCH Container

After building, run the container with:

```bash
docker run -d --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021/tcp \
  -p 16384-32768:16384-32768/udp \
  freeswitch:latest
```

### With Custom Configuration

Mount your custom configuration:

```bash
docker run -d --name freeswitch \
  -v /path/to/local/conf:/opt/freeswitch/conf \
  -v /path/to/local/recordings:/opt/freeswitch/recordings \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021/tcp \
  -p 16384-32768:16384-32768/udp \
  freeswitch:latest
```

## Common Build Issues and Solutions

### Missing Autoconf Macros
If you encounter errors like:

```
./configure: line XXXX: AM_PROG_CC_C_O: command not found
./configure: line XXXX: syntax error near unexpected token `disable-static'
./configure: line XXXX: `LT_INIT(disable-static)'
```

**Solution**: Ensure `autoconf-archive` and both `libtool` and `libtool-bin` packages are installed. The Dockerfile has been updated to include these dependencies.

### Bootstrap Failures
If the bootstrap process fails:

**Solution**: Run bootstrap with verbose output (`-v` flag) and add explicit autotools steps:

```bash
./bootstrap.sh -j -v
aclocal
libtoolize --force
autoconf
automake --add-missing
```

### Compilation Errors
For module-specific compilation errors:

**Solution**: You can disable problematic modules by editing `modules.conf` before building.

## Dockerfile Customization

### Adding Custom Modules
To add custom modules, modify the Dockerfile:

```dockerfile
# After cloning FreeSWITCH source
WORKDIR /usr/src/freeswitch
COPY ./custom_modules /usr/src/freeswitch/src/mod/custom_modules
```

### Reducing Image Size
To create a smaller image:

1. Use multi-stage builds
2. Be selective about which modules to include
3. Remove unnecessary development packages in the final stage

## Troubleshooting

### Check for Missing Dependencies
If your build fails with autoconf/automake errors:

```bash
docker run --rm -it debian:bullseye-slim bash
apt-get update && apt-get install -y autoconf automake libtool autoconf-archive
```

### Review Build Logs
For detailed error analysis:

```bash
docker build -t freeswitch:latest . 2>&1 | tee build.log
```

### Test Autotools in Isolation
To test if autotools are working correctly:

```bash
docker run --rm -it -v $(pwd):/src debian:bullseye-slim bash
cd /src
apt-get update && apt-get install -y autoconf automake libtool autoconf-archive
./bootstrap.sh -j -v
```

## Conclusion
Building the FreeSWITCH Docker image requires attention to the build environment and dependencies. The updated Dockerfile addresses common issues with the autotools process by including all necessary packages and explicit build steps.

For additional support, refer to the [FreeSWITCH documentation](https://freeswitch.org/confluence/display/FREESWITCH/FreeSWITCH+First+Steps) or submit issues to the project repository.