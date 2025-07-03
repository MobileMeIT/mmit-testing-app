#!/bin/bash

# Script to download and prepare UEFI bootloader
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTABLE_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$BOOTABLE_DIR/work"
EFI_DIR="$WORK_DIR/efi"
BOOT_DIR="$EFI_DIR/EFI/BOOT"

# Create directories
mkdir -p "$BOOT_DIR"

# Download rEFInd bootloader
echo "Downloading rEFInd bootloader..."
curl -L "https://sourceforge.net/projects/refind/files/0.13.3.1/refind-bin-0.13.3.1.zip" -o "$WORK_DIR/refind.zip"

# Extract bootloader
echo "Extracting bootloader..."
cd "$WORK_DIR"
unzip -j refind.zip "refind-bin-0.13.3.1/refind/refind_x64.efi" -d "$BOOT_DIR"
mv "$BOOT_DIR/refind_x64.efi" "$BOOT_DIR/BOOTX64.EFI"

# Clean up
rm refind.zip

echo "UEFI bootloader created at: $BOOT_DIR/BOOTX64.EFI" 