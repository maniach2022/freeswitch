# FreeSWITCH Docker Image

This repository contains the Dockerfile and related resources for building a FreeSWITCH Docker image.

## Quick Start

### Building the Docker Image

```bash
docker build -t freeswitch:latest .
```

### Running the Container

```bash
docker run -d --name freeswitch \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 5080:5080/tcp -p 5080:5080/udp \
  -p 8021:8021/tcp \
  -p 16384-32768:16384-32768/udp \
  freeswitch:latest
```

## Container Configuration

### Exposed Ports

- **5060/tcp, 5060/udp**: SIP signaling
- **5080/tcp, 5080/udp**: SIP signaling (alternative)
- **5066/tcp**: WebSocket signaling
- **7443/tcp**: WebSocket TLS signaling
- **8021/tcp**: Event Socket Interface (ESL)
- **16384-32768/udp**: RTP media

### Environment Variables

- `FS_USER`: FreeSWITCH user (default: freeswitch)
- `FS_GROUP`: FreeSWITCH group (default: freeswitch)
- `FS_HOME`: FreeSWITCH installation directory (default: /opt/freeswitch)

### Volumes

The container exposes the following volumes:

- **${FS_HOME}/conf**: Configuration files
- **${FS_HOME}/recordings**: Call recordings
- **${FS_HOME}/storage**: Storage for voicemail and other data

## Advanced Usage

### Using Custom Configuration

```bash
docker run -d --name freeswitch \
  -v /path/to/your/conf:/opt/freeswitch/conf \
  -p 5060:5060/tcp -p 5060:5060/udp \
  -p 8021:8021/tcp \
  freeswitch:latest
```

### Running with a Custom Command

```bash
docker run -it --name freeswitch \
  freeswitch:latest -nonat -console
```

### Accessing the Console

```bash
docker exec -it freeswitch fs_cli
```

## Development and Troubleshooting

### Building with Verbose Output

To see detailed build output:

```bash
docker build --progress=plain -t freeswitch:latest .
```

### Known Issues

#### Autotools Configuration

If you encounter build issues with autotools configuration, ensure you have the proper setup:

1. Make sure the `m4` directory exists in the project root
2. Verify `configure.ac` includes `AC_CONFIG_MACRO_DIRS([m4])`
3. Check that `Makefile.am` includes `ACLOCAL_AMFLAGS = -I m4`

The script `scripts/setup_autotools_env.sh` can be used to set up these requirements:

```bash
./scripts/setup_autotools_env.sh
```

### Building on Different Platforms

The Dockerfile is designed to build on Linux amd64/arm64 architectures. For multi-architecture builds:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t freeswitch:latest .
```

## Customizing the Image

### Adding Modules

To add additional FreeSWITCH modules, modify the `modules.conf` file before building the image.

### Extending the Dockerfile

Example of extending the Dockerfile:

```dockerfile
FROM freeswitch:latest

# Add your custom configurations
COPY my-configs/ /opt/freeswitch/conf/

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    your-package \
    && rm -rf /var/lib/apt/lists/*

# Additional commands
```

## Contributing

Contributions to improve the Docker image are welcome. Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the same license as FreeSWITCH - see the [LICENSE](LICENSE) file for details.