#!/bin/bash
# FreeSWITCH Docker build helper script
# This script helps with building the FreeSWITCH Docker image and troubleshooting build issues

# Set default values
VERBOSE=0
CLEAN=0
RETRY_BOOTSTRAP=0
SHOW_HELP=0
ADD_PACKAGES=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -c|--clean)
      CLEAN=1
      shift
      ;;
    -r|--retry-bootstrap)
      RETRY_BOOTSTRAP=1
      shift
      ;;
    -p|--add-packages)
      ADD_PACKAGES="$2"
      shift
      shift
      ;;
    -h|--help)
      SHOW_HELP=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      SHOW_HELP=1
      shift
      ;;
  esac
done

# Display help information
if [ $SHOW_HELP -eq 1 ]; then
  echo "FreeSWITCH Docker Build Helper"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -v, --verbose         Enable verbose output"
  echo "  -c, --clean           Clean Docker build cache before building"
  echo "  -r, --retry-bootstrap Run additional autotools commands if bootstrap fails"
  echo "  -p, --add-packages    Additional packages to install (space-separated in quotes)"
  echo "  -h, --help            Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 --verbose --add-packages \"autoconf-archive libtool\""
  exit 0
fi

# Start the build process
echo "Starting FreeSWITCH Docker build..."

# Clean build cache if requested
if [ $CLEAN -eq 1 ]; then
  echo "Cleaning Docker build cache..."
  docker builder prune -f
fi

# Set up build arguments
BUILD_ARGS=""

# Add retry-bootstrap option if specified
if [ $RETRY_BOOTSTRAP -eq 1 ]; then
  echo "Will apply additional autotools steps after bootstrap"
  BUILD_ARGS="$BUILD_ARGS --build-arg RETRY_BOOTSTRAP=true"
fi

# Add additional packages if specified
if [ -n "$ADD_PACKAGES" ]; then
  echo "Will install additional packages: $ADD_PACKAGES"
  BUILD_ARGS="$BUILD_ARGS --build-arg ADDITIONAL_PACKAGES=\"$ADD_PACKAGES\""
fi

# Set up verbose output
if [ $VERBOSE -eq 1 ]; then
  BUILD_COMMAND="docker build $BUILD_ARGS -t freeswitch:latest . 2>&1 | tee build.log"
else
  BUILD_COMMAND="docker build $BUILD_ARGS -t freeswitch:latest ."
fi

# Create a temporary Dockerfile if we need to modify it
if [ $RETRY_BOOTSTRAP -eq 1 ] || [ -n "$ADD_PACKAGES" ]; then
  echo "Creating modified Dockerfile for this build..."
  cp Dockerfile Dockerfile.tmp
  
  if [ -n "$ADD_PACKAGES" ]; then
    # Add additional packages to the build tools section
    sed -i "/# Build tools/a \    $ADD_PACKAGES \\\\" Dockerfile.tmp
  fi
  
  if [ $RETRY_BOOTSTRAP -eq 1 ]; then
    # Modify the bootstrap section to add explicit autotools steps
    sed -i 's/RUN \.\/bootstrap.sh -j/RUN \.\/bootstrap.sh -j -v \&\& \\\n    aclocal \&\& \\\n    libtoolize --force \&\& \\\n    autoconf \&\& \\\n    automake --add-missing/g' Dockerfile.tmp
  fi
  
  echo "Using temporary Dockerfile for this build"
  BUILD_COMMAND="${BUILD_COMMAND/Dockerfile/Dockerfile.tmp}"
fi

# Execute the build command
echo "Running build command: $BUILD_COMMAND"
eval $BUILD_COMMAND
BUILD_RESULT=$?

# Clean up temporary Dockerfile if created
if [ -f "Dockerfile.tmp" ]; then
  rm Dockerfile.tmp
fi

# Check build result
if [ $BUILD_RESULT -eq 0 ]; then
  echo ""
  echo "Build completed successfully!"
  echo "To run the container:"
  echo "docker run -d --name freeswitch \\"
  echo "  -p 5060:5060/tcp -p 5060:5060/udp \\"
  echo "  -p 5080:5080/tcp -p 5080:5080/udp \\"
  echo "  -p 8021:8021/tcp \\"
  echo "  -p 16384-32768:16384-32768/udp \\"
  echo "  freeswitch:latest"
else
  echo ""
  echo "Build failed with error code $BUILD_RESULT"
  echo ""
  echo "Troubleshooting suggestions:"
  echo "1. Try adding 'autoconf-archive' and 'libtool':"
  echo "   $0 --add-packages \"autoconf-archive libtool\""
  echo ""
  echo "2. Try with explicit autotools steps:"
  echo "   $0 --retry-bootstrap"
  echo ""
  echo "3. View the build log for detailed errors:"
  echo "   $0 --verbose"
fi

exit $BUILD_RESULT