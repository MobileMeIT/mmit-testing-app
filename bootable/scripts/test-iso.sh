#!/bin/bash

# Test script for Hardware Testing App ISO
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTABLE_DIR="$(dirname "$SCRIPT_DIR")"
ISO_FILE="$BOOTABLE_DIR/output/hardware-testing-app.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    echo "Please run create-iso.sh first"
    exit 1
fi

echo "Testing ISO: $ISO_FILE"
echo "Size: $(du -h "$ISO_FILE" | cut -f1)"
echo ""

# Test 1: Check ISO structure
echo "=== ISO Structure Test ==="
if command -v isoinfo >/dev/null 2>&1; then
    echo "Boot catalog entries:"
    isoinfo -d -i "$ISO_FILE" | grep -E "(Boot|Volume|System)"
    echo ""
    
    echo "Directory structure:"
    isoinfo -l -i "$ISO_FILE" | head -20
    echo ""
else
    echo "isoinfo not available, skipping structure test"
fi

# Test 2: Check for required files
echo "=== Required Files Test ==="
REQUIRED_FILES=(
    "/isolinux/isolinux.bin"
    "/isolinux/isolinux.cfg"
    "/live/vmlinuz"
    "/live/initrd"
    "/live/filesystem.squashfs"
    "/EFI/BOOT/BOOTX64.EFI"
    "/boot/grub/grub.cfg"
)

for file in "${REQUIRED_FILES[@]}"; do
    if isoinfo -f -i "$ISO_FILE" | grep -q "^$file"; then
        echo "✓ Found: $file"
    else
        echo "✗ Missing: $file"
    fi
done
echo ""

# Test 3: QEMU test (if available)
echo "=== VM Boot Test ==="
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "Starting QEMU test (BIOS mode)..."
    echo "Press Ctrl+Alt+G to release mouse, Ctrl+Alt+2 for monitor, Ctrl+Alt+Q to quit"
    echo ""
    
    read -p "Start QEMU test? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        qemu-system-x86_64 \
            -cdrom "$ISO_FILE" \
            -m 2048 \
            -enable-kvm \
            -display gtk \
            -name "Hardware Test Live - BIOS Test" \
            -boot d
    fi
    
    echo ""
    read -p "Start QEMU UEFI test? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to find OVMF firmware
        OVMF_PATH=""
        for path in /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF_CODE.fd; do
            if [ -f "$path" ]; then
                OVMF_PATH="$path"
                break
            fi
        done
        
        if [ -n "$OVMF_PATH" ]; then
            qemu-system-x86_64 \
                -cdrom "$ISO_FILE" \
                -m 2048 \
                -enable-kvm \
                -display gtk \
                -name "Hardware Test Live - UEFI Test" \
                -bios "$OVMF_PATH" \
                -boot d
        else
            echo "OVMF firmware not found, skipping UEFI test"
        fi
    fi
else
    echo "QEMU not available, skipping VM test"
fi

echo ""
echo "=== Ventoy Compatibility Notes ==="
echo "1. The ISO includes 'findiso=' parameter to help Ventoy locate the filesystem"
echo "2. Both /live/ and /casper/ directories are created for maximum compatibility"
echo "3. Volume ID is set to 'HARDWARE_TEST_LIVE' (no spaces for better compatibility)"
echo "4. EFI and BIOS boot methods are both supported"
echo ""
echo "To test with Ventoy:"
echo "1. Copy '$ISO_FILE' to your Ventoy USB drive"
echo "2. Boot from the Ventoy USB drive"
echo "3. Select the ISO from the Ventoy menu"
echo ""
echo "If the ISO still doesn't work with Ventoy:"
echo "1. Try booting in 'Legacy/BIOS' mode instead of UEFI"
echo "2. Try the 'Safe Mode' option from the boot menu"
echo "3. Check Ventoy logs for specific error messages" 