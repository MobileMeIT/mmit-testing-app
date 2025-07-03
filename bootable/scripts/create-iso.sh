#!/bin/bash

# Create ISO image for Hardware Testing App
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTABLE_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="$BOOTABLE_DIR/work"
ISO_DIR="$WORK_DIR/iso"
ROOTFS_DIR="$WORK_DIR/rootfs"
OUTPUT_ISO="$BOOTABLE_DIR/hardware-test-live.iso"

echo "Creating ISO directory structure..."
mkdir -p "$ISO_DIR/live"
mkdir -p "$ISO_DIR/isolinux"
mkdir -p "$ISO_DIR/boot/grub"
mkdir -p "$ISO_DIR/EFI/BOOT"

echo "Creating squashfs filesystem..."
mksquashfs "$ROOTFS_DIR" "$ISO_DIR/live/filesystem.squashfs" -comp xz -e boot

echo "Copying kernel and initramfs..."
cp "$ROOTFS_DIR/boot/vmlinuz-"* "$ISO_DIR/live/vmlinuz" 2>/dev/null || {
    echo "Warning: No kernel found, using generic names"
    find "$ROOTFS_DIR/boot" -name "vmlinuz*" -exec cp {} "$ISO_DIR/live/vmlinuz" \; -quit
}

cp "$ROOTFS_DIR/boot/initrd.img-"* "$ISO_DIR/live/initrd" 2>/dev/null || {
    echo "Warning: No initrd found, using generic names"
    find "$ROOTFS_DIR/boot" -name "initrd*" -exec cp {} "$ISO_DIR/live/initrd" \; -quit
}

echo "Setting up boot loaders..."

# Setup BIOS boot (isolinux)
cp "$BOOTABLE_DIR/config/isolinux.cfg" "$ISO_DIR/isolinux/"

# Copy isolinux binaries
if [ -f /usr/lib/ISOLINUX/isolinux.bin ]; then
    cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
elif [ -f /usr/lib/syslinux/isolinux.bin ]; then
    cp /usr/lib/syslinux/isolinux.bin "$ISO_DIR/isolinux/"
else
    echo "Error: isolinux.bin not found"
    exit 1
fi

# Copy syslinux modules
SYSLINUX_MODULES_DIR=""
for dir in /usr/lib/syslinux/modules/bios /usr/lib/SYSLINUX /usr/share/syslinux; do
    if [ -d "$dir" ]; then
        SYSLINUX_MODULES_DIR="$dir"
        break
    fi
done

if [ -n "$SYSLINUX_MODULES_DIR" ]; then
    cp "$SYSLINUX_MODULES_DIR/menu.c32" "$ISO_DIR/isolinux/" 2>/dev/null || echo "Warning: menu.c32 not found"
    cp "$SYSLINUX_MODULES_DIR/libcom32.c32" "$ISO_DIR/isolinux/" 2>/dev/null || echo "Warning: libcom32.c32 not found"
    cp "$SYSLINUX_MODULES_DIR/libutil.c32" "$ISO_DIR/isolinux/" 2>/dev/null || echo "Warning: libutil.c32 not found"
    cp "$SYSLINUX_MODULES_DIR/reboot.c32" "$ISO_DIR/isolinux/" 2>/dev/null || echo "Warning: reboot.c32 not found"
    cp "$SYSLINUX_MODULES_DIR/poweroff.c32" "$ISO_DIR/isolinux/" 2>/dev/null || echo "Warning: poweroff.c32 not found"
else
    echo "Warning: Syslinux modules directory not found"
fi

# Setup UEFI boot (GRUB)
echo "Setting up UEFI boot support..."
cp "$BOOTABLE_DIR/config/grub.cfg" "$ISO_DIR/boot/grub/"

# Create GRUB EFI bootloader
grub-mkstandalone \
    --format=x86_64-efi \
    --output="$ISO_DIR/EFI/BOOT/BOOTX64.EFI" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg"

# Create EFI System Partition image
dd if=/dev/zero of="$ISO_DIR/efiboot.img" bs=1024 count=4096
mkfs.fat -F 12 -n "EFIBOOT" "$ISO_DIR/efiboot.img"

# Mount and populate EFI image
mkdir -p "$WORK_DIR/efi_mount"
mount -o loop "$ISO_DIR/efiboot.img" "$WORK_DIR/efi_mount"
mkdir -p "$WORK_DIR/efi_mount/EFI/BOOT"
cp "$ISO_DIR/EFI/BOOT/BOOTX64.EFI" "$WORK_DIR/efi_mount/EFI/BOOT/"
umount "$WORK_DIR/efi_mount"
rmdir "$WORK_DIR/efi_mount"

echo "Creating manifest..."
cat > "$ISO_DIR/live/filesystem.manifest" << EOF
# Hardware Testing App Live System
# Built on: $(date)
# Architecture: amd64
# Base: Ubuntu 22.04 (Jammy)

# Core system packages
linux-image-generic
systemd
nodejs
electron
xorg
openbox
pulseaudio

# Hardware testing tools
lshw
usbutils
pciutils
smartmontools
memtester
stress
acpi
v4l-utils
alsa-utils

# Application
hardware-testing-app
EOF

echo "Creating hybrid ISO image with BIOS and UEFI support..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Hardware Test Live" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e efiboot.img \
    -no-emul-boot \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -isohybrid-gpt-basdat \
    -output "$OUTPUT_ISO" \
    "$ISO_DIR"

echo "ISO creation complete: $OUTPUT_ISO"
echo "Size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "To test in VM:"
echo "  qemu-system-x86_64 -cdrom '$OUTPUT_ISO' -m 2048 -enable-kvm"
echo ""
echo "To flash to USB drive:"
echo "  sudo dd if='$OUTPUT_ISO' of=/dev/sdX bs=4M status=progress"
echo "  (Replace /dev/sdX with your USB device)" 