@echo off
setlocal

REM Check if NASM is installed
where nasm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo NASM not found. Downloading portable NASM...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip' -OutFile 'nasm.zip'}"
    powershell -Command "& {Expand-Archive -Path 'nasm.zip' -DestinationPath 'nasm' -Force}"
    set "PATH=%CD%\nasm;%PATH%"
    del nasm.zip
)

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "WORK_DIR=%SCRIPT_DIR%..\work"
set "ISO_DIR=%WORK_DIR%\iso"
set "EFI_DIR=%ISO_DIR%\EFI\Boot"

REM Create directories if they don't exist
if not exist "%EFI_DIR%" mkdir "%EFI_DIR%"

REM Compile bootloader
echo Compiling bootloader...
nasm -f bin "%SCRIPT_DIR%bootx64.asm" -o "%EFI_DIR%\BOOTX64.EFI"

if %ERRORLEVEL% neq 0 (
    echo Error compiling bootloader
    exit /b 1
)

echo Bootloader compiled successfully to: %EFI_DIR%\BOOTX64.EFI
exit /b 0 