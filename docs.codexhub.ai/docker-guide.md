# FreeSWITCH Docker Image Guide

This document provides instructions for building and running the FreeSWITCH Docker image.

## Docker Image Overview

The FreeSWITCH Docker image is based on Debian Bullseye (slim) and includes:

- FreeSWITCH core and modules built from source
- All required dependencies
- Minimal runtime libraries for optimal container size
- Proper user/group setup for security

## Building the Docker Image

### Prerequisites

- Docker installed on your system
- Docker Compose (optional, for easy deployment)

### Building the Image

From the repository root directory:

```bash
docker build -t freeswitch:latest .
```

This builds the Docker image using the provided Dockerfile. The build process:

1. Installs all required build dependencies
2. Compiles FreeSWITCH from source with all modules enabled
3. Installs only the required runtime dependencies
4. Creates a minimal production-ready image

## Running FreeSWITCH with Docker

### Using Docker Command

Simple run command:

```bash
docker run -d --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021/tcp \
  -p 16384-32768:16384-32768/udp \
  freeswitch:latest
```

### Using Docker Compose

A `docker-compose.yml` file is provided for convenience:

```bash
docker-compose up -d
```

This will start FreeSWITCH in a container with all the necessary port mappings and volume mounts.

## Configuration

The Docker image uses the following directory structure:

- Configuration: `/opt/freeswitch/conf`
- Recordings: `/opt/freeswitch/recordings`
- Storage: `/opt/freeswitch/storage`

These directories are exposed as volumes, so you can mount your own configuration:

```bash
docker run -d --name freeswitch \
  -v ./my-config:/opt/freeswitch/conf \
  -v fs-recordings:/opt/freeswitch/recordings \
  -v fs-storage:/opt/freeswitch/storage \
  -p 5060:5060/tcp -p 5060:5060/udp \
  freeswitch:latest
```

## Exposed Ports

- SIP: 5060/tcp, 5060/udp, 5080/tcp, 5080/udp, 5066/tcp
- WebSocket Secure: 7443/tcp
- Event Socket: 8021/tcp
- RTP Media: 16384-32768/udp

## Security Considerations

- The container runs as a non-root user `freeswitch`
- Only required runtime dependencies are included in the final image
- Build tools and development libraries are removed to minimize the attack surface

## Troubleshooting

### Logs

To view the FreeSWITCH logs:

```bash
docker logs freeswitch
```

### Interactive Shell

To access an interactive shell in the running container:

```bash
docker exec -it freeswitch /bin/bash
```

### FreeSWITCH CLI

To access the FreeSWITCH CLI:

```bash
docker exec -it freeswitch /opt/freeswitch/bin/fs_cli
```

## Custom Build Options

If you need to customize the FreeSWITCH build, modify the Dockerfile:

- Add or remove modules by editing the `./configure` command options
- Add additional dependencies as needed in the apt-get install commands

## Performance Tuning

For production use, consider the following:

1. Mount a persistent volume for logs, recordings, and configuration
2. Adjust container resource limits based on your workload
3. Consider using host networking mode for better RTP performance

```bash
docker run --network=host --name freeswitch freeswitch:latest
```