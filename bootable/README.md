# Hardware Testing App - Bootable USB Version

This directory contains the configuration and scripts to create a bootable USB version of the hardware testing application. The bootable version runs on a minimal Linux distribution and provides enhanced hardware access capabilities.

## Features

- **Standalone Operation**: Boots directly from USB without requiring an installed OS
- **Enhanced Hardware Access**: Direct access to hardware components for more comprehensive testing
- **Wide Compatibility**: Supports both BIOS and UEFI boot modes
- **Persistent Storage**: Option to save test results and logs to USB drive
- **Fast Boot**: Optimized for quick startup and immediate testing
- **Recovery Mode**: Built-in recovery options for troubleshooting

## Hardware Tests Available

All original tests plus enhanced versions:
- **Battery Test**: Advanced power management and charging diagnostics
- **Webcam Test**: Multiple camera support with resolution testing
- **Microphone Test**: Audio input analysis and quality metrics
- **Speaker Test**: Full frequency range testing and calibration
- **Touch Test**: Multi-touch precision and dead zone detection
- **Keyboard Test**: Complete key matrix testing including special keys
- **Mouse Test**: Precision tracking and button response testing
- **Additional Tests**:
  - CPU stress testing and temperature monitoring
  - Memory (RAM) comprehensive testing
  - Storage device health and performance
  - Network interface connectivity
  - Display calibration and dead pixel detection
  - USB port functionality

## Building the Bootable Image

### Prerequisites

- Linux system with root access (or Docker)
- At least 4GB free disk space
- USB drive (minimum 2GB recommended)

### Quick Start

```bash
# Clone and build
git clone <your-repo>
cd mmit-testing-app/bootable
sudo ./build.sh

# Flash to USB drive (replace /dev/sdX with your USB device)
sudo dd if=hardware-test-live.iso of=/dev/sdX bs=4M status=progress
```

### Custom Build

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools xorriso isolinux

# Build custom image
sudo ./scripts/build-custom.sh
```

## Usage

1. **Boot from USB**: Insert USB drive and boot from it (may need to change BIOS/UEFI boot order)
2. **Automatic Start**: The testing application will start automatically after boot
3. **Run Tests**: Use the familiar interface to test hardware components
4. **Save Results**: Test results are automatically saved to the USB drive
5. **Shutdown**: Use the shutdown option in the app or press Ctrl+Alt+Del

## Boot Options

- **Default**: Normal boot with full GUI
- **Safe Mode**: Boot with minimal drivers for compatibility
- **Recovery**: Boot to command line for troubleshooting
- **Memory Test**: Boot directly to memory testing utility

## File Structure

```
bootable/
├── build.sh              # Main build script
├── config/
│   ├── isolinux.cfg      # Boot loader configuration
│   ├── grub.cfg          # GRUB configuration for UEFI
│   ├── preseed.cfg       # Automated installation config
│   └── xorg.conf         # X11 display configuration
├── scripts/
│   ├── build-rootfs.sh   # Root filesystem creation
│   ├── install-deps.sh   # Dependency installation
│   ├── setup-boot.sh     # Boot configuration
│   └── create-iso.sh     # ISO image creation
├── overlay/
│   ├── etc/              # System configuration files
│   ├── usr/local/bin/    # Custom scripts and binaries
│   └── home/user/        # User configuration
└── app/                  # Hardware testing application
    ├── package.json
    ├── main.js
    └── dist/             # Built application files
```

## Customization

### Adding Hardware Drivers

Edit `scripts/install-deps.sh` to include additional kernel modules:

```bash
# Add driver for specific hardware
echo "driver-name" >> config/modules.list
```

### Modifying Boot Splash

Replace `overlay/usr/share/pixmaps/boot-splash.png` with your custom image.

### Adding Additional Software

Edit `scripts/build-rootfs.sh` to include additional packages:

```bash
chroot $ROOTFS apt-get install -y your-package-name
```

## Troubleshooting

### Boot Issues

- **Black Screen**: Try safe mode boot option
- **No USB Boot**: Check BIOS/UEFI settings for USB boot support
- **Slow Boot**: Some hardware may take longer to initialize

### Hardware Access Issues

- **Permission Denied**: The app runs with elevated privileges automatically
- **Device Not Found**: Check if device is properly connected and recognized
- **Driver Missing**: May need to add specific drivers for newer hardware

### Recovery Options

- **Command Line Access**: Press Ctrl+Alt+F2 during boot
- **Network Access**: Connect ethernet cable for remote troubleshooting
- **Log Files**: Check `/var/log/hardware-test.log` for detailed error information

## Development

### Testing Changes

```bash
# Build and test in virtual machine
./scripts/test-vm.sh

# Build and test on real hardware
sudo ./build.sh && sudo dd if=hardware-test-live.iso of=/dev/sdX
```

### Adding New Tests

1. Add test component to `../frontend/src/components/`
2. Update the main app to include new test
3. Rebuild bootable image with `./build.sh`

## Security Considerations

- The bootable version runs with elevated privileges for hardware access
- No network services are enabled by default
- All data is stored locally on the USB drive
- No persistent user accounts (runs as live system)

## License

Same license as the main hardware testing application. 