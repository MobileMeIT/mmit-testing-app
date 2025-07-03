@echo off
REM Batch script to run the UEFI ISO creation script inside WSL, installing dependencies if needed

REM Check if WSL is installed
where wsl >nul 2>nul
if errorlevel 1 (
    echo WSL is not installed. Please install WSL2 and Ubuntu from the Microsoft Store.
    exit /b 1
)

REM Set default values for arguments if not provided
set "APP_DIR=."
set "APP_NAME=MMIT Testing App"
set "SPLASH_IMG="
set "ISO_NAME=MMITTestingApp-UEFI.iso"

if not "%~1"=="" set "APP_DIR=%~1"
if not "%~2"=="" set "APP_NAME=%~2"
if not "%~3"=="" set "SPLASH_IMG=%~3"
if not "%~4"=="" set "ISO_NAME=%~4"

REM Convert Windows path to WSL path
for /f "delims=" %%i in ('wsl wslpath "%cd%"') do set "WSL_PWD=%%i"

REM Run the dependency install and ISO creation in WSL
echo Running dependency installation and ISO creation in WSL...
wsl bash -c "
set -e
cd '%WSL_PWD%'

echo 'Updating package lists and installing dependencies...'
sudo apt-get update
sudo apt-get install -y coreutils zutils cpio genisoimage p7zip-full gdisk syslinux-efi syslinux-utils isolinux wget curl

if ! command -v node >/dev/null 2>&1; then
  echo 'Installing Node.js...'
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

if ! command -v electron-iso-packager >/dev/null 2>&1; then
  echo 'Installing electron-iso-packager...'
  sudo npm install -g electron-iso-packager
fi

chmod +x scripts/create-uefi-iso.sh
./scripts/create-uefi-iso.sh '%APP_DIR%' '%APP_NAME%' '%SPLASH_IMG%' '%ISO_NAME%'
" 