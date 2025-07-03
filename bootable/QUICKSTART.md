# Quick Start Guide - Bootable Hardware Testing App

Get your bootable hardware testing USB drive ready in minutes!

## 🚀 Super Quick Start (Ubuntu/Debian)

```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install debootstrap squashfs-tools xorriso isolinux nodejs npm

# 2. Build the bootable ISO
cd mmit-testing-app/bootable
sudo ./build.sh

# 3. Flash to USB drive (⚠️ Replace /dev/sdX with your USB device!)
sudo dd if=hardware-test-live.iso of=/dev/sdX bs=4M status=progress
```

**Done!** Your bootable USB drive is ready.

## 🐳 Docker Method (Any Platform)

```bash
# 1. Build with Docker (requires Docker installed)
cd mmit-testing-app/bootable
./build-docker.sh

# 2. Flash to USB drive
sudo dd if=output/hardware-test-live.iso of=/dev/sdX bs=4M status=progress
```

## 🧪 Test Before Flashing

```bash
# Test in virtual machine first
./scripts/test-vm.sh
```

## 💾 Finding Your USB Drive

```bash
# List all drives to find your USB device
lsblk

# Look for your USB drive (usually /dev/sdb, /dev/sdc, etc.)
# Make sure it's the right device - dd will overwrite everything!
```

## 🖥️ Using the Bootable Drive

1. **Insert USB drive** into target computer
2. **Boot from USB** (may need to change boot order in BIOS/UEFI)
3. **Select "Hardware Test Live"** from boot menu
4. **Wait for automatic startup** - the testing app will launch automatically
5. **Run your tests** - all hardware components will be available
6. **Save results** - test results are automatically saved to the USB drive

## 🛠️ Boot Options Available

- **Hardware Test Live (Default)** - Normal boot with full GUI
- **Hardware Test Live (Safe Mode)** - Compatible drivers for older hardware
- **Recovery Mode** - Command line access for troubleshooting
- **Memory Test** - Direct boot to memory testing utility

## 🔧 Enhanced Features in Bootable Version

The bootable version includes additional tests not available in the regular app:

- **CPU Stress Testing** - Full processor load testing with temperature monitoring
- **Memory Testing** - Comprehensive RAM testing using memtester
- **Storage Health** - SMART data analysis for hard drives and SSDs
- **Network Interface Testing** - Ethernet and WiFi adapter testing
- **Temperature Monitoring** - Real-time system temperature sensors
- **Display Calibration** - Screen testing and dead pixel detection

## 📋 System Requirements

- **Minimum RAM**: 1GB (2GB recommended)
- **USB Drive**: 2GB minimum
- **Boot Support**: BIOS or UEFI
- **Architecture**: x86_64 (64-bit)

## 🆘 Troubleshooting

### USB Won't Boot
- Check BIOS/UEFI boot order
- Enable "Legacy Boot" or "CSM" if available
- Try different USB ports

### Black Screen on Boot
- Use "Safe Mode" boot option
- Check if secure boot is enabled (disable if needed)

### App Doesn't Start
- Wait 2-3 minutes for full boot
- Press Ctrl+Alt+F2 for command line access
- Check `/var/log/hardware-test.log` for errors

### No Hardware Detected
- Some hardware may need time to initialize
- Try unplugging and reconnecting devices
- Check if drivers are available for your specific hardware

## 🔄 Updating the Bootable Drive

To update your bootable drive with new features:

1. Rebuild the ISO with latest code
2. Flash the new ISO to your USB drive
3. Previous test results are preserved if saved to external storage

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Test in a virtual machine first
3. Review the full README.md for detailed information
4. Check system compatibility requirements

---

**Ready to test some hardware? Boot up and get testing! 🔧** 