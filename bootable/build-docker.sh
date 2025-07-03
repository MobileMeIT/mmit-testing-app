#!/bin/bash

# Build Hardware Testing App Bootable ISO using Docker
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    log_info "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    log_info "Please start Docker daemon"
    exit 1
fi

log_info "Building Hardware Testing App bootable ISO with Docker..."

# Create a temporary build context with all necessary files
log_info "Preparing build context..."
BUILD_CONTEXT="$SCRIPT_DIR/docker-build-context"
rm -rf "$BUILD_CONTEXT"
mkdir -p "$BUILD_CONTEXT"

# Copy project files to build context
cp -r "$PROJECT_ROOT/frontend" "$BUILD_CONTEXT/"
cp -r "$PROJECT_ROOT/backend" "$BUILD_CONTEXT/"
cp -r "$PROJECT_ROOT/electron" "$BUILD_CONTEXT/"
cp "$PROJECT_ROOT/package.json" "$BUILD_CONTEXT/"

# Copy bootable directory contents (excluding the build context itself)
for item in "$SCRIPT_DIR"/*; do
    if [ "$(basename "$item")" != "docker-build-context" ] && [ "$(basename "$item")" != "output" ]; then
        cp -r "$item" "$BUILD_CONTEXT/"
    fi
done

# Build the Docker image
log_info "Building Docker image..."
docker build -t hardware-test-builder "$BUILD_CONTEXT"

# Create output directory
mkdir -p "$SCRIPT_DIR/output"

# Run the build in container
log_info "Running build in container..."

# Use a Windows-compatible approach for Docker volume mounting
WINPTY_CMD=""
OUTPUT_MOUNT=""

if [[ "$OSTYPE" == "msys" ]]; then
    WINPTY_CMD="winpty"
    # Use Windows-style path for Docker Desktop
    WIN_PATH=$(cygpath -w "$SCRIPT_DIR/output")
    OUTPUT_MOUNT="$WIN_PATH:/build/output"
else
    # Linux/macOS - use paths as-is
    OUTPUT_MOUNT="$SCRIPT_DIR/output:/build/output"
fi

# Disable MSYS path conversion for this command
export MSYS_NO_PATHCONV=1

$WINPTY_CMD docker run --rm \
    --privileged \
    -v "$OUTPUT_MOUNT" \
    hardware-test-builder bash -c "
        ./build.sh
        if [ -f hardware-testing-app.iso ]; then
            cp hardware-testing-app.iso /build/output/hardware-testing-app.iso
            echo 'ISO copied to output directory'
        else
            echo 'ISO file not found after build'
            ls -la
            exit 1
        fi
    "

# Re-enable MSYS path conversion
unset MSYS_NO_PATHCONV

# Check if ISO was created
if [ -f "$SCRIPT_DIR/output/hardware-testing-app.iso" ]; then
    log_success "Bootable ISO created successfully!"
    log_info "Location: $SCRIPT_DIR/output/hardware-testing-app.iso"
    log_info "Size: $(du -h "$SCRIPT_DIR/output/hardware-testing-app.iso" | cut -f1)"
    
    echo ""
    log_info "Next steps:"
    echo "1. Test in VM: ./scripts/test-vm.sh"
    echo "2. Flash to USB: sudo dd if=output/hardware-testing-app.iso of=/dev/sdX bs=4M status=progress"
    log_warning "   Replace /dev/sdX with your USB device (check with lsblk)"
    
    echo ""
    log_info "Boot options available:"
    echo "- Hardware Test Live (Default)"
    echo "- Hardware Test Live (Safe Mode)"
    echo "- Recovery Mode (Command Line)"
    echo "- Memory Test"
else
    log_error "Failed to create bootable ISO"
    exit 1
fi

# Cleanup temporary build context
log_info "Cleaning up build context..."
rm -rf "$BUILD_CONTEXT"

# Cleanup Docker image (optional)
if [ "$1" = "--cleanup" ]; then
    log_info "Cleaning up Docker image..."
    docker rmi hardware-test-builder
    log_success "Docker image cleaned up"
fi 