# FreeSWITCH Docker Image Structure

This document outlines the structure and components of the FreeSWITCH Docker image.

## Image Base and Layers

The FreeSWITCH Docker image is built on Debian Bullseye Slim, chosen for its:
- Small base image size
- Long-term support
- Good compatibility with FreeSWITCH dependencies
- Wide community support

## Layer Organization

The Docker image is constructed with optimized layers to minimize size and improve build efficiency:

1. **Base System Layer**: Debian Bullseye Slim with essential system packages
2. **Build Dependencies Layer**: All libraries and tools needed to compile FreeSWITCH
3. **FreeSWITCH Dependencies Build Layer**: Compilation of required dependencies (libks, sofia-sip, etc.)
4. **FreeSWITCH Build Layer**: Compilation of FreeSWITCH itself
5. **Runtime Layer**: Minimal runtime environment with only required libraries
6. **Configuration Layer**: Default FreeSWITCH configuration

## Included Components

### Core Libraries

- **libks**: Signaling library for WebRTC and SIP
- **sofia-sip**: SIP protocol stack
- **spandsp**: Signal processing library
- **signalwire-c**: SignalWire client library

### FreeSWITCH Modules

The image includes all standard FreeSWITCH modules, including:

- **mod_sofia**: SIP protocol support
- **mod_verto**: WebRTC support
- **mod_conference**: Audio conferencing
- **mod_curl**: HTTP API integration
- **mod_av**: Audio/Video support
- ...and many more

## Security Considerations

The Docker image implements several security best practices:

1. **Non-root user**: FreeSWITCH runs as a dedicated non-privileged user
2. **Minimal dependencies**: Only required runtime libraries are included
3. **No development tools**: Build tools are removed in the final image
4. **Secure defaults**: FreeSWITCH is configured with secure defaults
5. **Proper volume permissions**: All data volumes are properly permissioned

## Performance Optimizations

The image is optimized for performance:

1. **Multi-stage build**: Keeps the final image small
2. **Compiler optimizations**: FreeSWITCH is built with appropriate optimizations
3. **Portable binary**: Built to be portable across different environments
4. **Proper resource isolation**: Container is configured for resource isolation

## Directory Structure

Key directories in the FreeSWITCH container:

```
/opt/freeswitch/        - FreeSWITCH installation root
├── bin/                - Executable binaries
├── conf/               - Configuration files (mountable)
├── lib/                - Libraries
├── mod/                - Modules
├── recordings/         - Call recordings (mountable)
├── storage/            - Persistent storage (mountable)
└── share/              - Shared resources
```

## Network Architecture

The container exposes several network ports:

- **5060** (TCP/UDP): SIP signaling
- **5080** (TCP/UDP): SIP signaling (alternative)
- **5066** (TCP): SIP TLS
- **7443** (TCP): WebSocket Secure (WSS)
- **8021** (TCP): Event Socket
- **16384-32768** (UDP): RTP media ports

## Image Size Optimization

The image size is optimized through:

1. Using slim base image
2. Multi-stage builds
3. Removing build dependencies
4. Cleaning package caches
5. Optimizing library dependencies