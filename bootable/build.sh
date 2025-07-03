#!/bin/bash

# Hardware Testing App - Bootable USB Builder
# This script creates a bootable USB image with the hardware testing application

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
ROOTFS_DIR="$WORK_DIR/rootfs"
ISO_DIR="$WORK_DIR/iso"
OUTPUT_ISO="$SCRIPT_DIR/hardware-testing-app.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warning "Not running as root - some operations may fail"
        log_info "In Docker containers, this is usually fine"
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check for command-line tools
    local cmd_deps=("debootstrap" "mksquashfs" "xorriso" "nodejs" "npm")
    local missing_deps=()
    
    for dep in "${cmd_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check for isolinux files (these are files, not commands)
    if [ ! -f "/usr/lib/ISOLINUX/isolinux.bin" ] && [ ! -f "/usr/lib/syslinux/isolinux.bin" ]; then
        missing_deps+=("isolinux")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install with: apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "All dependencies found"
}

# Clean up previous builds
cleanup() {
    log_info "Cleaning up previous builds..."
    rm -rf "$WORK_DIR"
    rm -f "$OUTPUT_ISO"
    log_success "Cleanup complete"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    mkdir -p "$WORK_DIR"
    mkdir -p "$ROOTFS_DIR"
    mkdir -p "$ISO_DIR"
    log_success "Directories created"
}

# Build the application
build_app() {
    log_info "Building hardware testing application..."
    
    # In Docker, the project structure is at /build
    cd "/build/frontend"
    npm install
    npm run build
    
    cd "/build/backend"
    npm install
    
    cd "/build/electron"
    npm install
    
    # Copy built application to work directory
    mkdir -p "$WORK_DIR/app"
    cp -r "/build/frontend/dist" "$WORK_DIR/app/"
    cp -r "/build/backend/src" "$WORK_DIR/app/backend"
    cp -r "/build/electron" "$WORK_DIR/app/"
    cp "/build/package.json" "$WORK_DIR/app/"
    
    log_success "Application built and copied"
}

# Create base rootfs
create_rootfs() {
    log_info "Creating base root filesystem..."
    
    # Use Ubuntu minimal as base
    debootstrap --arch=amd64 --variant=minbase jammy "$ROOTFS_DIR" http://archive.ubuntu.com/ubuntu/
    
    log_success "Base rootfs created"
}

# Configure the system
configure_system() {
    log_info "Configuring system..."
    
    # Mount necessary filesystems for chroot
    mount -o bind /dev "$ROOTFS_DIR/dev"
    mount -o bind /dev/pts "$ROOTFS_DIR/dev/pts"
    mount -o bind /proc "$ROOTFS_DIR/proc"
    mount -o bind /sys "$ROOTFS_DIR/sys"
    
    # Configure DNS
    cp /etc/resolv.conf "$ROOTFS_DIR/etc/resolv.conf"
    
    # Run configuration script in chroot
    cat > "$ROOTFS_DIR/configure.sh" << 'EOF'
#!/bin/bash
set -e

# Update package lists and install universe repository
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y universe
apt-get update

# Install essential packages (step by step for better error handling)
apt-get install -y \
    linux-image-generic \
    systemd \
    systemd-sysv \
    dbus \
    sudo \
    curl \
    wget \
    git

# Install X11 and basic desktop
apt-get install -y \
    xorg \
    xinit \
    x11-xserver-utils

# Install basic tools
apt-get install -y \
    usbutils \
    pciutils \
    lshw || true

# Install Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Create necessary groups first
groupadd -f audio || true
groupadd -f video || true
groupadd -f dialout || true
groupadd -f plugdev || true
groupadd -f netdev || true

# Create user for the application
useradd -m -s /bin/bash -G audio,video,dialout,plugdev,netdev hardwaretest
echo "hardwaretest:test" | chpasswd

# Configure auto-login
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin hardwaretest --noclear %I $TERM
AUTOLOGIN

# Configure X11 to start automatically
mkdir -p /home/hardwaretest
cat > /home/hardwaretest/.xinitrc << 'XINITRC'
#!/bin/bash
# Start the hardware testing application
cd /opt/hardware-test
exec node electron/main.js
XINITRC

# Make .xinitrc executable
chmod +x /home/hardwaretest/.xinitrc

# Configure bash profile to start X11
cat >> /home/hardwaretest/.bash_profile << 'BASHPROFILE'
if [[ -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
    exec startx
fi
BASHPROFILE

# Set ownership
chown -R hardwaretest:hardwaretest /home/hardwaretest

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*

EOF

    chmod +x "$ROOTFS_DIR/configure.sh"
    chroot "$ROOTFS_DIR" /configure.sh
    rm "$ROOTFS_DIR/configure.sh"
    
    # Unmount filesystems
    umount "$ROOTFS_DIR/sys" || true
    umount "$ROOTFS_DIR/proc" || true
    umount "$ROOTFS_DIR/dev/pts" || true
    umount "$ROOTFS_DIR/dev" || true
    
    log_success "System configured"
}

# Install application
install_app() {
    log_info "Installing hardware testing application..."
    
    # Copy application files
    mkdir -p "$ROOTFS_DIR/opt/hardware-test"
    cp -r "$WORK_DIR/app"/* "$ROOTFS_DIR/opt/hardware-test/"
    
    # Install application dependencies
    mount -o bind /dev "$ROOTFS_DIR/dev"
    mount -o bind /dev/pts "$ROOTFS_DIR/dev/pts"
    mount -o bind /proc "$ROOTFS_DIR/proc"
    mount -o bind /sys "$ROOTFS_DIR/sys"
    
    cat > "$ROOTFS_DIR/install-app.sh" << 'EOF'
#!/bin/bash
set -e
cd /opt/hardware-test
# Install main dependencies
npm install --production

# Install electron globally for easier access
npm install -g electron

# Set proper permissions
chown -R hardwaretest:hardwaretest /opt/hardware-test
EOF

    chmod +x "$ROOTFS_DIR/install-app.sh"
    chroot "$ROOTFS_DIR" /install-app.sh
    rm "$ROOTFS_DIR/install-app.sh"
    
    # Unmount filesystems
    umount "$ROOTFS_DIR/sys" || true
    umount "$ROOTFS_DIR/proc" || true
    umount "$ROOTFS_DIR/dev/pts" || true
    umount "$ROOTFS_DIR/dev" || true
    
    log_success "Application installed"
}

# Create ISO image
create_iso() {
    log_info "Creating ISO image..."
    
    # Create directory structure for ISO
    mkdir -p "$ISO_DIR/live"
    mkdir -p "$ISO_DIR/isolinux"
    
    # Create squashfs filesystem
    mksquashfs "$ROOTFS_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -e boot
    
    # Copy kernel and initrd
    cp "$ROOTFS_DIR/boot/vmlinuz-"* "$ISO_DIR/live/vmlinuz"
    cp "$ROOTFS_DIR/boot/initrd.img-"* "$ISO_DIR/live/initrd"
    
    # Copy boot configuration
    cp "$SCRIPT_DIR/config/isolinux.cfg" "$ISO_DIR/isolinux/"
    cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
    cp /usr/lib/syslinux/modules/bios/menu.c32 "$ISO_DIR/isolinux/"
    cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$ISO_DIR/isolinux/"
    cp /usr/lib/syslinux/modules/bios/libutil.c32 "$ISO_DIR/isolinux/"
    
    # Create the ISO
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "Hardware Test Live" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -output "$OUTPUT_ISO" \
        "$ISO_DIR"
    
    log_success "ISO image created: $OUTPUT_ISO"
}

# Main execution
main() {
    log_info "Starting Hardware Testing App bootable USB build..."
    
    check_root
    check_dependencies
    cleanup
    create_directories
    build_app
    create_rootfs
    configure_system
    install_app
    create_iso
    
    log_success "Build complete!"
    log_info "ISO image: $OUTPUT_ISO"
    log_info "To flash to USB: sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
    log_warning "Replace /dev/sdX with your USB device (check with lsblk)"
}

# Run main function
main "$@" 