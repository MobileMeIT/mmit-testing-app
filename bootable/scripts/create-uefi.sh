#!/bin/bash

# Create UEFI bootable structure
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTABLE_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$BOOTABLE_DIR/work"
OUTPUT_DIR="$BOOTABLE_DIR/output"
ISO_DIR="$WORK_DIR/iso"

# Ensure clean state
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$ISO_DIR/boot/grub/x86_64-efi" "$OUTPUT_DIR"

# Create GRUB config
cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
insmod all_video
insmod gfxterm
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660
insmod normal
insmod configfile
insmod boot
insmod linux
insmod search

# Set timeout
set timeout=30
set default=0

# Set menu colors
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

# Menu entries
menuentry "Hardware Test Live (Default)" {
    linux /boot/vmlinuz quiet splash
    initrd /boot/initrd
}

menuentry "Hardware Test Live (Safe Mode)" {
    linux /boot/vmlinuz nomodeset quiet splash
    initrd /boot/initrd
}

menuentry "Recovery Mode" {
    linux /boot/vmlinuz single
    initrd /boot/initrd
}

menuentry "Reboot" {
    reboot
}

menuentry "Power Off" {
    halt
}
EOF

# Create dummy kernel and initrd (needed for structure)
echo "Creating dummy boot files..."
touch "$ISO_DIR/boot/vmlinuz"
touch "$ISO_DIR/boot/initrd"

# Create bootx64.efi
echo "Creating UEFI bootloader..."
cat > "$ISO_DIR/boot/grub/x86_64-efi/bootx64.efi" << 'EOF'
#!/bin/sh
echo "UEFI Boot Test"
EOF
chmod +x "$ISO_DIR/boot/grub/x86_64-efi/bootx64.efi"

# Create EFI directory structure
mkdir -p "$ISO_DIR/EFI/BOOT"
cp "$ISO_DIR/boot/grub/x86_64-efi/bootx64.efi" "$ISO_DIR/EFI/BOOT/BOOTX64.EFI"

# Create ISO
echo "Creating bootable ISO..."
if command -v mkisofs &> /dev/null; then
    MKISOFS_CMD="mkisofs"
elif command -v genisoimage &> /dev/null; then
    MKISOFS_CMD="genisoimage"
else
    echo "Error: Neither mkisofs nor genisoimage found"
    exit 1
fi

$MKISOFS_CMD -R -J \
    -volid "HTESTAPP" \
    -b boot/grub/x86_64-efi/bootx64.efi \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/BOOT/BOOTX64.EFI \
    -no-emul-boot \
    -o "$OUTPUT_DIR/hardware-testing-app.iso" \
    "$ISO_DIR/"

echo "ISO created at: $OUTPUT_DIR/hardware-testing-app.iso" 