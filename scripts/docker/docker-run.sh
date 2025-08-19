#!/bin/bash
#
# FreeSWITCH Docker Run Script
#

set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Default settings
IMAGE_NAME="freeswitch"
TAG="latest"
CONTAINER_NAME="freeswitch"
NETWORK_MODE="bridge"
RESTART_POLICY="unless-stopped"
EXPOSE_PORTS=true
MOUNT_CONFIG=false
CONFIG_DIR="$REPO_ROOT/conf"
DETACH=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -t|--tag)
      TAG="$2"
      shift
      shift
      ;;
    -n|--name)
      CONTAINER_NAME="$2"
      shift
      shift
      ;;
    --network)
      NETWORK_MODE="$2"
      shift
      shift
      ;;
    --no-ports)
      EXPOSE_PORTS=false
      shift
      ;;
    --config)
      MOUNT_CONFIG=true
      CONFIG_DIR="$2"
      shift
      shift
      ;;
    --interactive)
      DETACH=false
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -t, --tag TAG          Tag for the image (default: latest)"
      echo "  -n, --name NAME        Container name (default: freeswitch)"
      echo "  --network MODE         Network mode (default: bridge)"
      echo "  --no-ports             Do not expose ports"
      echo "  --config DIR           Mount configuration directory"
      echo "  --interactive          Run in foreground (interactive mode)"
      echo "  -h, --help             Show this help message"
      echo ""
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Prepare docker run command
CMD="docker run"

if [ "$DETACH" = true ]; then
  CMD="$CMD -d"
else
  CMD="$CMD -it"
fi

CMD="$CMD --name $CONTAINER_NAME --restart $RESTART_POLICY --network $NETWORK_MODE"

# Add port mappings if requested
if [ "$EXPOSE_PORTS" = true ]; then
  CMD="$CMD -p 5060:5060/tcp -p 5060:5060/udp"
  CMD="$CMD -p 5080:5080/tcp -p 5080:5080/udp"
  CMD="$CMD -p 5066:5066/tcp"
  CMD="$CMD -p 7443:7443/tcp"
  CMD="$CMD -p 8021:8021/tcp"
  CMD="$CMD -p 16384-32768:16384-32768/udp"
fi

# Add volume mounts if requested
if [ "$MOUNT_CONFIG" = true ]; then
  CMD="$CMD -v $CONFIG_DIR:/opt/freeswitch/conf"
fi

# Add image name
CMD="$CMD $IMAGE_NAME:$TAG"

# Print run information
echo "============================================="
echo "Running FreeSWITCH Docker Container"
echo "============================================="
echo "Image:       $IMAGE_NAME:$TAG"
echo "Container:   $CONTAINER_NAME"
echo "Network:     $NETWORK_MODE"
echo "Ports:       $EXPOSE_PORTS"
echo "Config:      $MOUNT_CONFIG ($CONFIG_DIR)"
echo "Detached:    $DETACH"
echo "============================================="

# Run the container
echo "Starting container..."
eval $CMD

if [ "$DETACH" = true ]; then
  echo "Container started in detached mode."
  echo "To view logs: docker logs $CONTAINER_NAME"
  echo "To access shell: docker exec -it $CONTAINER_NAME /bin/bash"
  echo "To access FreeSWITCH CLI: docker exec -it $CONTAINER_NAME /opt/freeswitch/bin/fs_cli"
fi