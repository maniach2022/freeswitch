# GitHub Actions CI/CD Proposal for FreeSWITCH

## Overview

This proposal outlines a comprehensive CI/CD workflow using GitHub Actions for FreeSWITCH. The pipeline will automate building, testing, and packaging FreeSWITCH across multiple platforms.

## Goals

1. **Build Validation**: Ensure FreeSWITCH builds successfully on all supported platforms
2. **Test Automation**: Run unit and integration tests automatically
3. **Artifact Creation**: Generate binary packages and Docker images
4. **Quality Assurance**: Run static analysis and code quality checks
5. **Documentation**: Generate and publish documentation

## CI/CD Pipeline Architecture

### Workflow Structure

The proposed CI/CD pipeline consists of several workflows:

1. **Build Validation**: Triggered on pull requests and pushes to main branch
2. **Release Pipeline**: Triggered on release tags
3. **Nightly Builds**: Scheduled to run daily
4. **Documentation Pipeline**: Updates documentation on changes to docs

### Build Matrix

The build matrix covers these platforms and configurations:

| Platform | Architectures | Compiler | Build Types |
|----------|--------------|----------|-------------|
| Ubuntu 20.04 | amd64, arm64 | GCC, Clang | Debug, Release |
| Ubuntu 22.04 | amd64, arm64 | GCC, Clang | Debug, Release |
| Debian Bullseye | amd64, arm64 | GCC | Release |
| CentOS/RHEL 8 | amd64 | GCC | Release |
| Windows | x64 | MSVC | Release |
| macOS | x64, arm64 | AppleClang | Release |

## Proposed GitHub Actions Workflows

### 1. Build Validation Workflow

```yaml
name: Build Validation

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  autotools-setup:
    name: Verify AutoTools Setup
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup AutoTools Environment
        run: |
          ./scripts/setup_autotools_env.sh
      - name: Run Bootstrap
        run: |
          ./bootstrap.sh -j -v
      - name: Configure
        run: |
          ./configure --enable-portable-binary
      
  linux-build:
    name: Linux Build
    needs: autotools-setup
    runs-on: ubuntu-latest
    strategy:
      matrix:
        os: [ubuntu-20.04, ubuntu-22.04]
        compiler: [gcc, clang]
        build_type: [Debug, Release]
    steps:
      - uses: actions/checkout@v3
      - name: Setup Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential cmake automake autoconf libtool-bin pkg-config
          # Additional dependencies would be listed here
      - name: Setup AutoTools Environment
        run: ./scripts/setup_autotools_env.sh
      - name: Build FreeSWITCH
        run: |
          ./bootstrap.sh -j
          ./configure --enable-portable-binary
          make -j$(nproc)
      - name: Run Tests
        run: |
          make check
          
  docker-build:
    name: Docker Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker Image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: freeswitch:test
          
  windows-build:
    name: Windows Build
    runs-on: windows-2022
    steps:
      - uses: actions/checkout@v3
      - name: Setup MSBuild
        uses: microsoft/setup-msbuild@v1
      - name: Build FreeSWITCH
        run: |
          .\msbuild.cmd
```

### 2. Release Pipeline

```yaml
name: Release Pipeline

on:
  push:
    tags:
      - 'v*'

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    outputs:
      upload_url: ${{ steps.create_release.outputs.upload_url }}
      version: ${{ steps.get_version.outputs.version }}
    steps:
      - uses: actions/checkout@v3
      - name: Get Version
        id: get_version
        run: echo "version=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: FreeSWITCH ${{ steps.get_version.outputs.version }}
          draft: true
          prerelease: false
          
  build-packages:
    name: Build Packages
    needs: create-release
    runs-on: ubuntu-latest
    strategy:
      matrix:
        os: [ubuntu-20.04, ubuntu-22.04, debian-bullseye]
    steps:
      - uses: actions/checkout@v3
      - name: Setup Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential cmake automake autoconf libtool-bin pkg-config
          # Additional dependencies would be listed here
      - name: Setup AutoTools Environment
        run: ./scripts/setup_autotools_env.sh
      - name: Build FreeSWITCH
        run: |
          ./bootstrap.sh -j
          ./configure --enable-portable-binary
          make -j$(nproc)
      - name: Create DEB Package
        run: |
          make deb
      - name: Upload Package
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ needs.create-release.outputs.upload_url }}
          asset_path: ./freeswitch-${{ needs.create-release.outputs.version }}.deb
          asset_name: freeswitch-${{ matrix.os }}-${{ needs.create-release.outputs.version }}.deb
          asset_content_type: application/vnd.debian.binary-package
          
  build-docker:
    name: Build and Push Docker Image
    needs: create-release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            freeswitch/freeswitch:latest
            freeswitch/freeswitch:${{ needs.create-release.outputs.version }}
```

### 3. Nightly Builds

```yaml
name: Nightly Builds

on:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM UTC every day

jobs:
  nightly-build:
    name: Nightly Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          ref: develop
      - name: Setup Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential cmake automake autoconf libtool-bin pkg-config
          # Additional dependencies would be listed here
      - name: Setup AutoTools Environment
        run: ./scripts/setup_autotools_env.sh
      - name: Build FreeSWITCH
        run: |
          ./bootstrap.sh -j
          ./configure --enable-portable-binary
          make -j$(nproc)
      - name: Create Artifact
        run: |
          tar -czvf freeswitch-nightly-$(date +%Y%m%d).tar.gz /opt/freeswitch
      - name: Upload Artifact
        uses: actions/upload-artifact@v3
        with:
          name: freeswitch-nightly
          path: freeswitch-nightly-*.tar.gz
          retention-days: 7
```

## Implementation Plan

### Phase 1: Basic CI Integration (Weeks 1-2)
- Set up build validation workflow
- Configure build matrix for Ubuntu platforms
- Implement automation to ensure proper autotools setup

### Phase 2: Extended Platform Support (Weeks 3-4)
- Add Windows build pipeline
- Add macOS build pipeline
- Implement multi-architecture support

### Phase 3: Release Pipeline (Weeks 5-6)
- Set up automated release creation
- Configure package building for Debian/Ubuntu
- Implement Docker image build and push

### Phase 4: Advanced Features (Weeks 7-8)
- Set up nightly builds
- Implement code quality checks
- Configure documentation generation and publishing

## Required Secrets

The following secrets will need to be configured in the GitHub repository:

- `DOCKERHUB_USERNAME`: Username for Docker Hub
- `DOCKERHUB_TOKEN`: Access token for Docker Hub
- `GPG_PRIVATE_KEY`: GPG key for signing packages (optional)
- `GPG_PASSPHRASE`: Passphrase for GPG key (optional)

## Monitoring and Maintenance

- Set up notifications for failed builds
- Create a dashboard for build status
- Schedule regular reviews of CI/CD configuration
- Implement performance monitoring for the CI/CD pipeline

## Conclusion

This GitHub Actions CI/CD proposal provides a comprehensive solution for automating the build, test, and release process for FreeSWITCH. By implementing this pipeline, we can ensure consistent build quality, reduce manual intervention, and provide timely releases to users.