# PowerShell script to create UEFI bootable ISO
$ErrorActionPreference = "Stop"

# Set up directories
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bootableDir = Split-Path -Parent $scriptDir
$workDir = Join-Path $bootableDir "work"
$outputDir = Join-Path $bootableDir "output"
$isoDir = Join-Path $workDir "iso"

# Clean and create directories
Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $outputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$isoDir\EFI\BOOT" -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Download UEFI shell
$uefiUrl = "https://github.com/tianocore/edk2/raw/master/ShellBinPkg/UefiShell/X64/Shell.efi"
$bootx64Path = Join-Path $isoDir "EFI\BOOT\BOOTX64.EFI"

Write-Host "Downloading UEFI shell..."
Invoke-WebRequest -Uri $uefiUrl -OutFile $bootx64Path

# Create startup script
$startupPath = Join-Path $isoDir "EFI\BOOT\startup.nsh"
@"
@echo -off
echo "Hardware Testing App - UEFI Boot"
if exist fs0:\EFI\BOOT\grubx64.efi then
    fs0:
    EFI\BOOT\grubx64.efi
    goto END
endif
if exist fs1:\EFI\BOOT\grubx64.efi then
    fs1:
    EFI\BOOT\grubx64.efi
    goto END
endif
echo "Error: UEFI bootloader not found"
:END
"@ | Out-File -FilePath $startupPath -Encoding ASCII

# Download oscdimg
$oscdimgUrl = "https://download.microsoft.com/download/8/a/e/8ae7f07d-b74d-4a2a-8670-1bb09dd9ef6f/oscdimg.exe"
$oscdimgPath = Join-Path $scriptDir "oscdimg.exe"

if (-not (Test-Path $oscdimgPath)) {
    Write-Host "Downloading Windows ISO creation tool..."
    Invoke-WebRequest -Uri $oscdimgUrl -OutFile $oscdimgPath
}

# Create bootable ISO
$isoPath = Join-Path $outputDir "hardware-testing-app.iso"
Write-Host "Creating bootable ISO..."

if (Test-Path $oscdimgPath) {
    & $oscdimgPath -bootdata:2#p0,e,b"$bootx64Path"#pEF,e,b"$bootx64Path" -u2 -udfver102 $isoDir $isoPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ISO created successfully at: $isoPath"
    } else {
        Write-Host "Error creating ISO"
        exit 1
    }
} else {
    Write-Host "Error: Could not find or download oscdimg.exe"
    exit 1
}

Write-Host "Done!" 