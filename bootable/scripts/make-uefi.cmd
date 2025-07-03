@echo off
setlocal enabledelayedexpansion

:: Set up directories
set "SCRIPT_DIR=%~dp0"
set "BOOTABLE_DIR=%SCRIPT_DIR%.."
set "WORK_DIR=%BOOTABLE_DIR%\work"
set "OUTPUT_DIR=%BOOTABLE_DIR%\output"
set "ISO_DIR=%WORK_DIR%\iso"

:: Clean and create directories
rmdir /s /q "%WORK_DIR%" 2>nul
rmdir /s /q "%OUTPUT_DIR%" 2>nul
mkdir "%ISO_DIR%\EFI\BOOT" 2>nul
mkdir "%OUTPUT_DIR%" 2>nul

:: Create UEFI bootloader
echo Creating UEFI bootloader...
powershell -Command "& { $uefiUrl = 'https://github.com/tianocore/edk2/raw/master/ShellBinPkg/UefiShell/X64/Shell.efi'; Invoke-WebRequest -Uri $uefiUrl -OutFile '%ISO_DIR%\EFI\BOOT\BOOTX64.EFI' }"

:: Create startup script
echo Creating startup script...
(
echo @echo -off
echo echo "Hardware Testing App - UEFI Boot"
echo if exist fs0:\EFI\BOOT\BOOTX64.EFI then
echo     fs0:
echo     EFI\BOOT\BOOTX64.EFI
echo     goto END
echo endif
echo if exist fs1:\EFI\BOOT\BOOTX64.EFI then
echo     fs1:
echo     EFI\BOOT\BOOTX64.EFI
echo     goto END
echo endif
echo echo "Error: UEFI bootloader not found"
echo :END
) > "%ISO_DIR%\EFI\BOOT\startup.nsh"

:: Download oscdimg if needed
if not exist "%SCRIPT_DIR%oscdimg.exe" (
    echo Downloading Windows ISO creation tool...
    powershell -Command "& { $oscdimgUrl = 'https://download.microsoft.com/download/8/a/e/8ae7f07d-b74d-4a2a-8670-1bb09dd9ef6f/oscdimg.exe'; Invoke-WebRequest -Uri $oscdimgUrl -OutFile '%SCRIPT_DIR%oscdimg.exe' }"
)

:: Create bootable ISO
echo Creating bootable ISO...
if exist "%SCRIPT_DIR%oscdimg.exe" (
    "%SCRIPT_DIR%oscdimg.exe" -bootdata:2#p0,e,b"%ISO_DIR%\EFI\BOOT\BOOTX64.EFI"#pEF,e,b"%ISO_DIR%\EFI\BOOT\BOOTX64.EFI" -u2 -udfver102 "%ISO_DIR%" "%OUTPUT_DIR%\hardware-testing-app.iso"
) else (
    echo Error: Could not find or download oscdimg.exe
    exit /b 1
)

echo ISO created at: %OUTPUT_DIR%\hardware-testing-app.iso
echo Done! 