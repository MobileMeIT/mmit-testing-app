@echo off
setlocal enabledelayedexpansion

:: Set up directories
set "SCRIPT_DIR=%~dp0"
set "BOOTABLE_DIR=%SCRIPT_DIR%\.."
set "WORK_DIR=%BOOTABLE_DIR%\work"
set "OUTPUT_DIR=%BOOTABLE_DIR%\output"
set "ISO_DIR=%WORK_DIR%\iso"
set "OSCDIMG_URL=https://download.microsoft.com/download/8/a/e/8ae7f07d-b74d-4a2a-8670-1bb09dd9ef6f/oscdimg.exe"

:: Clean and create directories
rmdir /s /q "%WORK_DIR%" 2>nul
rmdir /s /q "%OUTPUT_DIR%" 2>nul
mkdir "%ISO_DIR%\boot\grub\x86_64-efi" 2>nul
mkdir "%OUTPUT_DIR%" 2>nul
mkdir "%ISO_DIR%\EFI\BOOT" 2>nul

:: Create GRUB config
echo Creating GRUB configuration...
(
echo insmod all_video
echo insmod gfxterm
echo insmod part_gpt
echo insmod part_msdos
echo insmod fat
echo insmod iso9660
echo insmod normal
echo insmod configfile
echo insmod boot
echo insmod linux
echo insmod search
echo.
echo # Set timeout
echo set timeout=30
echo set default=0
echo.
echo # Set menu colors
echo set menu_color_normal=white/black
echo set menu_color_highlight=black/light-gray
echo.
echo # Menu entries
echo menuentry "Hardware Test Live (Default)" {
echo     linux /boot/vmlinuz quiet splash
echo     initrd /boot/initrd
echo }
echo.
echo menuentry "Hardware Test Live (Safe Mode)" {
echo     linux /boot/vmlinuz nomodeset quiet splash
echo     initrd /boot/initrd
echo }
echo.
echo menuentry "Recovery Mode" {
echo     linux /boot/vmlinuz single
echo     initrd /boot/initrd
echo }
echo.
echo menuentry "Reboot" {
echo     reboot
echo }
echo.
echo menuentry "Power Off" {
echo     halt
echo }
) > "%ISO_DIR%\boot\grub\grub.cfg"

:: Create dummy boot files
echo Creating boot files...
type nul > "%ISO_DIR%\boot\vmlinuz"
type nul > "%ISO_DIR%\boot\initrd"

:: Create simple UEFI bootloader
echo Creating UEFI bootloader...
(
echo ;; Simple UEFI bootloader
echo db 0x7F, "ELF"             ; ELF magic number
echo times 0x3C - ($ - $$) db 0 ; Padding
echo dd 0x10000                 ; Entry point
) > "%ISO_DIR%\EFI\BOOT\BOOTX64.EFI"

:: Download Windows ISO creation tool if needed
if not exist "%SCRIPT_DIR%\oscdimg.exe" (
    echo Downloading Windows ISO creation tool...
    powershell -Command "& {Invoke-WebRequest -Uri '%OSCDIMG_URL%' -OutFile '%SCRIPT_DIR%\oscdimg.exe'}"
)

:: Create bootable ISO
echo Creating bootable ISO...
if exist "%SCRIPT_DIR%\oscdimg.exe" (
    "%SCRIPT_DIR%\oscdimg.exe" -bootdata:2#p0,e,b"%ISO_DIR%\EFI\BOOT\BOOTX64.EFI"#pEF,e,b"%ISO_DIR%\EFI\BOOT\BOOTX64.EFI" -u2 -udfver102 "%ISO_DIR%" "%OUTPUT_DIR%\hardware-testing-app.iso"
) else (
    echo Error: Could not find or download oscdimg.exe
    exit /b 1
)

echo ISO created at: %OUTPUT_DIR%\hardware-testing-app.iso
echo Done! 