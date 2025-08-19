#!/bin/bash
#
# FreeSWITCH Docker Build Script
#

set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Default settings
IMAGE_NAME="freeswitch"
TAG="latest"
DOCKERFILE_PATH="$REPO_ROOT/Dockerfile"
BUILD_ARGS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -t|--tag)
      TAG="$2"
      shift
      shift
      ;;
    -f|--file)
      DOCKERFILE_PATH="$2"
      shift
      shift
      ;;
    --build-arg)
      BUILD_ARGS="$BUILD_ARGS --build-arg $2"
      shift
      shift
      ;;
    --no-cache)
      BUILD_ARGS="$BUILD_ARGS --no-cache"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -t, --tag TAG          Tag for the image (default: latest)"
      echo "  -f, --file PATH        Path to Dockerfile (default: ./Dockerfile)"
      echo "  --build-arg ARG=VALUE  Set build-time variables"
      echo "  --no-cache             Do not use cache when building the image"
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

# Print build information
echo "============================================="
echo "Building FreeSWITCH Docker Image"
echo "============================================="
echo "Image name:      $IMAGE_NAME:$TAG"
echo "Dockerfile:      $DOCKERFILE_PATH"
echo "Build arguments: $BUILD_ARGS"
echo "============================================="

# Build the Docker image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:$TAG" \
  -f "$DOCKERFILE_PATH" \
  $BUILD_ARGS \
  "$REPO_ROOT"

echo "============================================="
echo "Build complete!"
echo "To run the container:"
echo "docker run -d --name freeswitch -p 5060:5060/udp $IMAGE_NAME:$TAG"
echo "============================================="