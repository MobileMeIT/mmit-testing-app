# UEFI Bootable ISO Creation Guide for MMIT Testing App

## Overview
This guide explains how to create a **UEFI-compatible** bootable ISO for the MMIT Testing App using an enhanced version of electron-iso-packager with proper UEFI support.

**✅ UEFI Compatibility Confirmed**: Based on research from [TinyCore UEFI documentation](https://www.parkytowers.me.uk/thin/Linux/TinycoreUEFI.shtml), TinyCore Linux **fully supports UEFI** when properly configured.

## Prerequisites
- **Linux environment** (Ubuntu/Debian recommended)
- **Node.js 16+** and npm installed
- **Root/sudo access** for installing system packages
- **Internet connection** for downloading TinyCore Linux
- **At least 2GB free disk space** for temporary files

## Step 1: Install Dependencies

```bash
# Install system dependencies for UEFI support
sudo apt update
sudo apt install -y \
    coreutils \
    zutils \
    cpio \
    genisoimage \
    p7zip-full \
    gdisk \
    syslinux-efi \
    syslinux-utils \
    isolinux \
    wget \
    curl

# Install electron-iso-packager
npm install -g electron-iso-packager

# Verify installations
npx electron-iso-packager --version
7z --help > /dev/null && echo "7z: OK"
genisoimage --version > /dev/null && echo "genisoimage: OK"
extlinux --version > /dev/null && echo "extlinux: OK" || echo "extlinux: WARNING"
```

## Step 2: Prepare Your App

First, ensure your Electron app is built and ready:

```bash
# Install all dependencies
npm run install:all

# Build the frontend (Vue.js app) safely
if [ -d "frontend" ]; then
    (cd frontend && npm run build)
else
    echo "Warning: frontend directory not found"
fi

# Backend is ready (Node.js - no build step required)
# The backend runs directly from source files

# Verify the build
ls -la frontend/dist/  # Should contain built files
```

**Note**: The backend doesn't require a build step since it's pure Node.js. The script will handle this correctly.

## Step 3: Create UEFI-Compatible ISO

Use our enhanced script that extends electron-iso-packager with UEFI support:

```bash
# Make the script executable
chmod +x scripts/create-uefi-iso.sh

# Create UEFI-compatible ISO
./scripts/create-uefi-iso.sh ./ "MMIT Testing App" "" "MMITTestingApp-UEFI.iso"

# Alternative with splash image
./scripts/create-uefi-iso.sh ./ "MMIT Testing App" "splash.jpg" "MMITTestingApp-UEFI.iso"
```

### What the Script Does:

1. **Validates dependencies** and provides helpful error messages
2. **Builds the frontend** (Vue.js) properly
3. **Runs standard electron-iso-packager** for the base app
4. **Downloads TinyCorePure64 16.0** with UEFI-compatible kernel (fallback to 15.0)
5. **Creates proper EFI boot structure** (`/EFI/BOOT/`)
6. **Installs syslinux EFI bootloader** with `BOOTX64.EFI`
7. **Creates hybrid ISO** supporting both Legacy BIOS and UEFI
8. **Configures triple boot options** (normal, safe, debug modes)
9. **Handles errors gracefully** with proper cleanup

### Boot Options Available:
- **Normal Mode**: Standard boot with quiet output
- **Safe Mode**: Boot with compatibility options (`nomodeset`, `acpi=off`)
- **Debug Mode**: Verbose boot for troubleshooting

### TinyCore Version Compatibility:
The script automatically downloads **TinyCore Linux 16.0** (latest stable version as of 2024). If the download fails, it falls back to **TinyCore Linux 15.0** for compatibility. Both versions support UEFI boot when properly configured.

## Step 4: Test the ISO

### Virtual Machine Testing:

#### QEMU with UEFI:
```bash
# Install OVMF (UEFI firmware for QEMU)
sudo apt install ovmf

# Test UEFI boot
qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom MMITTestingApp-UEFI.iso \
    -m 2G \
    -enable-kvm

# Test Legacy boot
qemu-system-x86_64 \
    -cdrom MMITTestingApp-UEFI.iso \
    -m 2G \
    -enable-kvm
```

#### VirtualBox:
1. Create new VM with **Linux 64-bit**
2. **Enable EFI** in System settings
3. Mount ISO and boot
4. Test both EFI and Legacy modes

#### VMware:
1. Create new VM
2. Set firmware to **UEFI**
3. Mount ISO and test

### Physical Hardware Testing:
1. **Disable Secure Boot** in BIOS/UEFI settings
2. **Enable UEFI boot mode** (disable Legacy/CSM if needed)
3. **Set USB/CD as first boot device**
4. **Boot from USB/CD** with the ISO

### Create Bootable USB:

#### Linux:
```bash
# Find your USB device
lsblk

# Create bootable USB (replace /dev/sdX with your USB device)
sudo dd if=MMITTestingApp-UEFI.iso of=/dev/sdX bs=4M status=progress
sync

# Verify the USB
sudo fdisk -l /dev/sdX
```

#### Windows:
1. Use **Rufus** (recommended)
2. Select the ISO file
3. Choose **GPT partition scheme**
4. Select **UEFI target system**
5. Click Start

#### macOS:
```bash
# Find USB device
diskutil list

# Create bootable USB
sudo dd if=MMITTestingApp-UEFI.iso of=/dev/diskX bs=4m
```

## Technical Details

### UEFI Boot Structure:
```
ISO Root/
├── EFI/
│   └── BOOT/
│       ├── BOOTX64.EFI      # Main UEFI bootloader
│       ├── syslinux.cfg     # Boot configuration
│       ├── ldlinux.e64      # Syslinux EFI loader
│       ├── libutil.c32      # Syslinux utilities
│       ├── libcom32.c32     # Syslinux common functions
│       └── vesamenu.c32     # Menu system
├── isolinux/                # Legacy BIOS boot
│   ├── isolinux.bin
│   └── boot.cat
├── vmlinuz64                # UEFI-compatible kernel
├── core64.gz                # TinyCore initrd
├── syslinux.cfg             # Boot configuration
├── tce/                     # TinyCore extensions
└── [your app files]         # Electron app
```

### Key UEFI Requirements Met:
- ✅ **GPT partition table** support
- ✅ **EFI System Partition** structure
- ✅ **BOOTX64.EFI** bootloader
- ✅ **FAT32 compatibility** for EFI partition
- ✅ **Hybrid ISO** for both UEFI and Legacy boot
- ✅ **Secure Boot ready** (when signed)
- ✅ **Volume label** set to "MMIT_UEFI" for device detection

## Troubleshooting

### Common Issues:

#### 1. **"No bootable device"**:
- **Cause**: UEFI settings or USB creation issue
- **Solutions**:
  - Ensure Secure Boot is disabled
  - Check UEFI boot mode is enabled
  - Verify USB was created correctly with `dd`
  - Try different USB port or device
  - Check BIOS boot order

#### 2. **"Missing operating system"**:
- **Cause**: Corrupted ISO or USB
- **Solutions**:
  - Verify ISO integrity: `md5sum MMITTestingApp-UEFI.iso`
  - Try different USB creation method (Rufus vs dd)
  - Check USB device health
  - Recreate the ISO

#### 3. **"Boot hangs or black screen"**:
- **Cause**: Hardware compatibility
- **Solutions**:
  - Try **Safe Mode** boot option
  - Use **Debug Mode** to see boot messages
  - Check hardware compatibility
  - Update system firmware

#### 4. **"App doesn't start"**:
- **Cause**: Missing dependencies or build issues
- **Solutions**:
  - Verify frontend build: `ls frontend/dist/`
  - Check electron-iso-packager worked: `file temp-base.iso`
  - Test with debug mode
  - Rebuild the app: `npm run build`

#### 5. **"Kernel panic"**:
- **Cause**: Hardware driver issues
- **Solutions**:
  - Boot with `nomodeset acpi=off`
  - Use Safe Mode
  - Check hardware compatibility with TinyCore
  - Try different kernel parameters

### Advanced Debugging:

#### Enable Debug Mode:
The ISO includes a debug boot option that shows detailed boot messages:
```
# Boot parameters for debug mode
loglevel=7 debug tce=LABEL host=mmit-debug
```

#### Manual Boot Parameters:
If automatic boot fails, try manual parameters:
```
# At boot prompt, type:
vmlinuz64 initrd=core64.gz quiet loglevel=3 noswap tce=LABEL
```

**Note**: The `tce=LABEL` parameter tells TinyCore to find the boot device by its volume label, which works for both CD/DVD and USB boot scenarios. This is more flexible than using device paths like `/dev/sr0` or `/dev/sdb1`.

#### Check Hardware Compatibility:
```bash
# Before creating ISO, check hardware info
lscpu
lsusb
lspci
dmesg | grep -i error
```

### Build Issues:

#### Missing Dependencies:
```bash
# If script fails with missing dependencies
sudo apt install -y build-essential linux-headers-$(uname -r)
sudo apt install -y syslinux syslinux-efi isolinux
```

#### Permission Issues:
```bash
# If permission denied errors
sudo chown -R $USER:$USER .
chmod +x scripts/create-uefi-iso.sh
```

#### Network Issues:
```bash
# If TinyCore download fails
wget -c http://tinycorelinux.net/16.x/x86_64/release/TinyCorePure64-16.0.iso
# Or fallback to previous version
wget -c http://tinycorelinux.net/15.x/x86_64/release/TinyCorePure64-15.0.iso
# Then rerun the script
```

## Verification Checklist

The created ISO should:
- ✅ **Boot on UEFI-only systems** (like modern laptops)
- ✅ **Boot on Legacy BIOS systems** (older computers)
- ✅ **Work as bootable USB drive** (hybrid mode)
- ✅ **Support multiple boot modes** (normal, safe, debug)
- ✅ **Load your Electron app automatically**
- ✅ **Show proper boot menu** with app name
- ✅ **Handle hardware gracefully** (safe mode fallback)

## Performance Considerations

- **ISO Size**: Typically 100-200MB depending on app size
- **Boot Time**: 30-60 seconds on modern hardware
- **Memory Usage**: Minimum 1GB RAM recommended
- **Storage**: Runs entirely from RAM after boot

## Security Notes

- **Secure Boot**: Currently disabled by design
- **Code Signing**: Not implemented (can be added for production)
- **Network Security**: No network access by default
- **File System**: Read-only by default

## References

- [TinyCore UEFI Boot Guide](https://www.parkytowers.me.uk/thin/Linux/TinycoreUEFI.shtml)
- [TinyCore Linux Forum](https://forum.tinycorelinux.net/index.php/topic,24835.0.html)
- [electron-iso-packager](https://github.com/lucafabbian/electron-iso-packager)
- [UEFI Specification](https://uefi.org/specifications)
- [Syslinux Documentation](https://wiki.syslinux.org/wiki/index.php?title=UEFI) 