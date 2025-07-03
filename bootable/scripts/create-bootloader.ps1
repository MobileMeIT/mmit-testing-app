# PowerShell script to create a simple UEFI bootloader
$workDir = Join-Path $PSScriptRoot ".." "work"
$efiDir = Join-Path $workDir "efi"
$bootxPath = Join-Path $efiDir "EFI" "BOOT" "BOOTX64.EFI"

# Create directories if they don't exist
New-Item -ItemType Directory -Force -Path (Join-Path $efiDir "EFI" "BOOT") | Out-Null

# Download rEFInd bootloader (a simple UEFI bootloader)
$refindUrl = "https://sourceforge.net/projects/refind/files/0.13.3.1/refind-bin-0.13.3.1.zip/download"
$refindZip = Join-Path $workDir "refind.zip"
$refindDir = Join-Path $workDir "refind"

Write-Host "Downloading rEFInd bootloader..."
Invoke-WebRequest -Uri $refindUrl -OutFile $refindZip

Write-Host "Extracting bootloader..."
Expand-Archive -Path $refindZip -DestinationPath $refindDir -Force

Write-Host "Copying bootloader..."
Copy-Item -Path (Join-Path $refindDir "refind" "refind_x64.efi") -Destination $bootxPath

Write-Host "Cleaning up..."
Remove-Item -Path $refindZip -Force
Remove-Item -Path $refindDir -Recurse -Force

Write-Host "UEFI bootloader created at: $bootxPath" 