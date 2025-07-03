@echo -off
echo "Hardware Testing App - UEFI Boot"
echo "Starting boot process..."

if exist fs0:\EFI\Boot\BOOTX64.EFI then
    fs0:
    EFI\Boot\BOOTX64.EFI
    goto END
endif

if exist fs1:\EFI\Boot\BOOTX64.EFI then
    fs1:
    EFI\Boot\BOOTX64.EFI
    goto END
endif

echo "Error: UEFI bootloader not found"
:END
