#!/bin/bash
# UEFI-Compatible Electron ISO Creator (hardcoded for MMIT Testing App)
# Based on electron-iso-packager with UEFI enhancements
# Inspired by: https://www.parkytowers.me.uk/thin/Linux/TinycoreUEFI.shtml

set -e

# Hardcoded parameters
APP_DIR="./"
APP_NAME="MMIT Testing App"
SPLASH_IMAGE=""  # No splash image, use default (black screen)
OUTPUT_ISO="MMITTestingApp-UEFI.iso"

# Function to safely convert app name to hostname
safe_hostname() {
    local name="$1"
    # Convert to lowercase, replace spaces and special chars with dashes, remove consecutive dashes
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^\-|-$//g'
}

SAFE_HOSTNAME=$(safe_hostname "$APP_NAME")

echo "Creating UEFI-compatible ISO for $APP_NAME..."

# Validate dependencies
echo "Checking dependencies..."
MISSING_DEPS=()
APT_DEPS=(p7zip-full wget syslinux-efi syslinux-utils genisoimage isolinux)
NPM_DEPS=(electron-iso-packager)

for cmd in npx 7z wget extlinux genisoimage; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$cmd")
    fi
done

# Also check for isohybrid (optional but recommended)
if ! command -v isohybrid &> /dev/null; then
    echo "Note: isohybrid not found - ISO will still work but won't be optimized for USB boot"
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Missing dependencies: ${MISSING_DEPS[*]}"
    echo "Attempting to install missing dependencies..."
    # Install apt dependencies
    sudo apt update
    sudo apt install -y ${APT_DEPS[*]}
    # Install npm dependencies
    if ! command -v npm &> /dev/null; then
        echo "npm not found. Installing npm..."
        sudo apt install -y npm
    fi
    for pkg in "${NPM_DEPS[@]}"; do
        if ! npm list -g --depth=0 | grep -q "$pkg"; then
            echo "Installing $pkg globally via npm..."
            sudo npm install -g "$pkg"
        fi
    done
    # Re-check dependencies after install
    for cmd in npx 7z wget extlinux genisoimage; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is still missing after attempted install. Please check your system."
            exit 1
        fi
    done
    echo "All dependencies installed. Continuing..."
fi

# Create working directory
WORK_DIR=$(mktemp -d)
ISO_DIR="$WORK_DIR/iso"
EFI_DIR="$ISO_DIR/EFI/BOOT"

mkdir -p "$ISO_DIR"
mkdir -p "$EFI_DIR"

# Cleanup function
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
    rm -f temp-base.iso
    # Note: TinyCore ISO is kept for reuse in future runs
    # rm -f TinyCorePure64-*.iso  # Uncomment to remove TinyCore ISO cache
}
trap cleanup EXIT

# Step 1: Prepare the Electron app
echo "Preparing Electron app..."
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run from the app root directory."
    exit 1
fi

# Build the app properly
echo "Building frontend..."
if [ -d "frontend" ]; then
    # Save current directory and change to frontend
    ORIGINAL_DIR=$(pwd)
    if cd frontend; then
        if npm run build; then
            echo "Frontend build successful"
        else
            echo "Error: Frontend build failed"
            cd "$ORIGINAL_DIR"
            exit 1
        fi
        cd "$ORIGINAL_DIR"
    else
        echo "Error: Failed to enter frontend directory"
        exit 1
    fi
else
    echo "Warning: frontend directory not found, skipping frontend build"
fi

# Backend doesn't need building (it's just Node.js)
echo "Backend is ready (Node.js - no build required)"

# Step 2: Run standard electron-iso-packager first
echo "Building base Electron app..."
if [ -n "$SPLASH_IMAGE" ] && [ -f "$SPLASH_IMAGE" ]; then
    echo "Using splash image: $SPLASH_IMAGE"
    if ! npx electron-iso-packager "$APP_DIR" "$APP_NAME" "$SPLASH_IMAGE" temp-base.iso; then
        echo "Error: electron-iso-packager failed"
        exit 1
    fi
else
    echo "No splash image provided, using default"
    if ! npx electron-iso-packager "$APP_DIR" "$APP_NAME" temp-base.iso; then
        echo "Error: electron-iso-packager failed"
        exit 1
    fi
fi

if [ ! -f "temp-base.iso" ]; then
    echo "Error: Base ISO was not created"
    exit 1
fi

# Step 3: Extract base ISO
echo "Extracting base ISO..."
if ! 7z x temp-base.iso -o"$WORK_DIR/base/" > /dev/null; then
    echo "Error: Failed to extract base ISO"
    exit 1
fi

# Step 4: Copy base files to new structure
echo "Setting up UEFI boot structure..."
if [ -d "$WORK_DIR/base" ]; then
    # Check if there are files to copy
    if [ "$(ls -A "$WORK_DIR/base" 2>/dev/null)" ]; then
        cp -r "$WORK_DIR/base/"* "$ISO_DIR/" 2>/dev/null || {
            echo "Warning: Some base files could not be copied"
        }
    else
        echo "Warning: Base ISO appears to be empty"
    fi
else
    echo "Error: Base ISO extraction failed"
    exit 1
fi

# Step 5: Download TinyCorePure64 for UEFI kernel
echo "Downloading UEFI-compatible TinyCore kernel..."
TINYCORE_ISO=""
if [ -f "TinyCorePure64-16.0.iso" ]; then
    TINYCORE_ISO="TinyCorePure64-16.0.iso"
    echo "Using existing TinyCore Linux 16.0"
elif [ -f "TinyCorePure64-15.0.iso" ]; then
    TINYCORE_ISO="TinyCorePure64-15.0.iso"
    echo "Using existing TinyCore Linux 15.0"
else
    echo "Downloading TinyCore Linux..."
    if wget --progress=bar:force "http://tinycorelinux.net/16.x/x86_64/release/TinyCorePure64-16.0.iso" 2>/dev/null; then
        TINYCORE_ISO="TinyCorePure64-16.0.iso"
        echo "Downloaded TinyCore Linux 16.0"
    else
        echo "Error: Failed to download TinyCore ISO"
        echo "Trying fallback URL..."
        if wget --progress=bar:force "http://tinycorelinux.net/15.x/x86_64/release/TinyCorePure64-15.0.iso" 2>/dev/null; then
            TINYCORE_ISO="TinyCorePure64-15.0.iso"
            echo "Downloaded TinyCore Linux 15.0 (fallback)"
        else
            echo "Error: Failed to download TinyCore ISO from fallback URL"
            exit 1
        fi
    fi
fi

# Extract UEFI-compatible kernel and initrd
echo "Extracting TinyCore kernel..."
if ! 7z x "$TINYCORE_ISO" -o"$WORK_DIR/tinycore/" > /dev/null; then
    echo "Error: Failed to extract TinyCore ISO"
    exit 1
fi

# Verify kernel files exist
if [ ! -f "$WORK_DIR/tinycore/boot/vmlinuz64" ] || [ ! -f "$WORK_DIR/tinycore/boot/corepure64.gz" ]; then
    echo "Error: TinyCore kernel files not found"
    exit 1
fi

cp "$WORK_DIR/tinycore/boot/vmlinuz64" "$ISO_DIR/"
cp "$WORK_DIR/tinycore/boot/corepure64.gz" "$ISO_DIR/core64.gz"

# Step 6: Install syslinux EFI bootloader
echo "Installing UEFI bootloader..."

# Find syslinux EFI files
SYSLINUX_EFI=""
for path in "/usr/lib/syslinux/efi64" "/usr/local/share/syslinux/efi64" "/usr/share/syslinux/efi64"; do
    if [ -d "$path" ]; then
        SYSLINUX_EFI="$path"
        break
    fi
done

if [ -z "$SYSLINUX_EFI" ]; then
    echo "Error: syslinux EFI files not found"
    echo "Please install: sudo apt install syslinux-efi"
    exit 1
fi

# Install extlinux to EFI directory
if ! extlinux -i "$EFI_DIR" 2>/dev/null; then
    echo "Warning: extlinux installation failed, continuing..."
fi

# Copy required EFI files
echo "Copying UEFI boot files..."
EFI_FILES=(
    "syslinux.efi:BOOTX64.EFI"
    "ldlinux.e64:ldlinux.e64"
    "libutil.c32:libutil.c32"
    "libcom32.c32:libcom32.c32"
    "vesamenu.c32:vesamenu.c32"
)

for file_mapping in "${EFI_FILES[@]}"; do
    src_file="${file_mapping%:*}"
    dst_file="${file_mapping#*:}"
    
    if [ -f "$SYSLINUX_EFI/$src_file" ]; then
        cp "$SYSLINUX_EFI/$src_file" "$EFI_DIR/$dst_file"
    else
        echo "Warning: $src_file not found in $SYSLINUX_EFI"
    fi
done

# Also copy to root for compatibility
for file in libutil.c32 libcom32.c32 vesamenu.c32; do
    if [ -f "$SYSLINUX_EFI/$file" ]; then
        cp "$SYSLINUX_EFI/$file" "$ISO_DIR/"
    fi
done

# Step 7: Create UEFI-compatible syslinux.cfg
echo "Creating UEFI boot configuration..."

# Prepare splash background line
SPLASH_LINE=""
if [ -n "$SPLASH_IMAGE" ] && [ -f "$SPLASH_IMAGE" ]; then
    # Get the file extension
    SPLASH_EXT="${SPLASH_IMAGE##*.}"
    SPLASH_FILENAME="splash.$SPLASH_EXT"
    
    # Copy splash image to ISO with original extension
    cp "$SPLASH_IMAGE" "$ISO_DIR/$SPLASH_FILENAME"
    SPLASH_LINE="menu background $SPLASH_FILENAME"
fi

cat > "$ISO_DIR/syslinux.cfg" << EOF
UI vesamenu.c32
DEFAULT mmit

menu resolution 1024 768
menu title $APP_NAME - UEFI Boot
menu timeout 10
$SPLASH_LINE

LABEL mmit
MENU LABEL $APP_NAME
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND quiet loglevel=3 noswap tce=LABEL kmap=qwerty/us host=${SAFE_HOSTNAME}

LABEL mmit-safe
MENU LABEL $APP_NAME (Safe Mode)
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND quiet loglevel=3 noswap tce=LABEL vga=normal nomodeset acpi=off host=${SAFE_HOSTNAME}

LABEL mmit-debug
MENU LABEL $APP_NAME (Debug Mode)
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND loglevel=7 debug tce=LABEL host=${SAFE_HOSTNAME}
EOF

# Copy syslinux.cfg to EFI/BOOT directory as well
cp "$ISO_DIR/syslinux.cfg" "$EFI_DIR/"

# Step 8: Create hybrid ISO with UEFI support
echo "Creating hybrid ISO with UEFI support..."

# Ensure isolinux directory exists for legacy boot
if [ ! -d "$ISO_DIR/isolinux" ]; then
    echo "Warning: isolinux directory not found, creating basic structure..."
    mkdir -p "$ISO_DIR/isolinux"
    
    # Copy isolinux files if available
    if [ -f "/usr/lib/ISOLINUX/isolinux.bin" ]; then
        cp "/usr/lib/ISOLINUX/isolinux.bin" "$ISO_DIR/isolinux/"
    elif [ -f "/usr/lib/syslinux/isolinux.bin" ]; then
        cp "/usr/lib/syslinux/isolinux.bin" "$ISO_DIR/isolinux/"
    elif [ -f "/usr/share/syslinux/isolinux.bin" ]; then
        cp "/usr/share/syslinux/isolinux.bin" "$ISO_DIR/isolinux/"
    fi
    
    # Create isolinux.cfg for legacy boot
    if [ -f "$ISO_DIR/isolinux/isolinux.bin" ]; then
        cat > "$ISO_DIR/isolinux/isolinux.cfg" << EOF
DEFAULT mmit
TIMEOUT 100
PROMPT 0

LABEL mmit
MENU LABEL $APP_NAME
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND quiet loglevel=3 noswap tce=LABEL kmap=qwerty/us host=${SAFE_HOSTNAME}

LABEL mmit-safe
MENU LABEL $APP_NAME (Safe Mode)
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND quiet loglevel=3 noswap tce=LABEL vga=normal nomodeset acpi=off host=${SAFE_HOSTNAME}

LABEL mmit-debug
MENU LABEL $APP_NAME (Debug Mode)
KERNEL /vmlinuz64
INITRD /core64.gz
APPEND loglevel=7 debug tce=LABEL host=${SAFE_HOSTNAME}
EOF
    fi
fi

# Create the ISO with both legacy and UEFI support
ISO_OPTS=(
    -o "$OUTPUT_ISO"
    -V "MMIT_UEFI"
    -J -R -l
    -iso-level 3
)

# Add legacy boot if isolinux exists
if [ -f "$ISO_DIR/isolinux/isolinux.bin" ]; then
    ISO_OPTS+=(
        -b isolinux/isolinux.bin
        -c isolinux/boot.cat
        -no-emul-boot
        -boot-load-size 4
        -boot-info-table
        -eltorito-alt-boot
    )
fi

# Add UEFI boot
ISO_OPTS+=(
    -e EFI/BOOT/BOOTX64.EFI
    -no-emul-boot
)

# Try with GPT support first, fallback if not supported
if genisoimage "${ISO_OPTS[@]}" -isohybrid-gpt-basdat "$ISO_DIR" 2>/dev/null; then
    echo "ISO created with GPT support"
elif genisoimage "${ISO_OPTS[@]}" "$ISO_DIR"; then
    echo "ISO created without GPT support (fallback)"
else
    echo "Error: ISO creation failed"
    exit 1
fi

# Make it hybrid (bootable from USB)
if command -v isohybrid &> /dev/null; then
    echo "Making ISO hybrid..."
    isohybrid --uefi "$OUTPUT_ISO" 2>/dev/null || echo "Warning: isohybrid failed"
fi

echo "✅ UEFI-compatible ISO created: $OUTPUT_ISO"
echo ""
echo "📋 ISO Information:"
echo "   Size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo "   Type: Hybrid (Legacy BIOS + UEFI)"
echo "   Boot modes: Normal, Safe, Debug"
echo "   Volume label: MMIT_UEFI"
echo ""

# Validate ISO structure
echo "🔍 Validating ISO structure..."
if command -v 7z &> /dev/null; then
    if 7z l "$OUTPUT_ISO" | grep -q "EFI/BOOT/BOOTX64.EFI"; then
        echo "   ✅ UEFI boot structure: OK"
    else
        echo "   ❌ UEFI boot structure: MISSING"
    fi
    
    if 7z l "$OUTPUT_ISO" | grep -q "vmlinuz64"; then
        echo "   ✅ Kernel: OK"
    else
        echo "   ❌ Kernel: MISSING"
    fi
    
    if 7z l "$OUTPUT_ISO" | grep -q "core64.gz"; then
        echo "   ✅ Initrd: OK"
    else
        echo "   ❌ Initrd: MISSING"
    fi
fi

echo ""
echo "🧪 To test:"
echo "   1. Virtual Machine: Enable UEFI in VM settings"
echo "   2. Physical Hardware: Disable Secure Boot, enable UEFI boot"
echo "   3. USB Creation: dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
echo ""
echo "🔧 Troubleshooting:"
echo "   - If boot fails, try Safe Mode"
echo "   - For debugging, use Debug Mode"
echo "   - Ensure Secure Boot is disabled"
echo ""
echo "The ISO supports both Legacy BIOS and UEFI boot modes." 