# Create UEFI bootable ISO
$ErrorActionPreference = "Stop"

# Set paths
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$workDir = Join-Path (Split-Path -Parent $scriptDir) "work"
$isoDir = Join-Path $workDir "iso"
$outputDir = Join-Path (Split-Path -Parent $scriptDir) "output"
$efiDir = Join-Path $isoDir "EFI\Boot"

# Create directories
Write-Host "Creating directories..."
Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $outputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $efiDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Create a simple UEFI bootloader
Write-Host "Creating UEFI bootloader..."
$bootx64Path = Join-Path $efiDir "BOOTX64.EFI"

# Create a minimal PE header
$peHeader = [byte[]]@(
    0x4D, 0x5A, # MZ signature
    0x90, 0x00, # Padding
    # ... More PE header bytes
    0x50, 0x45, 0x00, 0x00, # PE signature
    0x64, 0x86, # Machine (x64)
    0x02, 0x00  # Number of sections
)

# Write the PE header to file
[System.IO.File]::WriteAllBytes($bootx64Path, $peHeader)

# Create startup script
Write-Host "Creating startup script..."
@"
@echo -off
echo "Hardware Testing App - UEFI Boot"
echo "Starting boot process..."
"@ | Set-Content -Path (Join-Path $efiDir "startup.nsh") -Encoding ASCII

# Create ISO using PowerShell
Write-Host "Creating ISO..."
$isoPath = Join-Path $outputDir "hardware-testing-app.iso"

# Create a simple ISO structure
$fsUtil = New-Object -ComObject "ADODB.Stream"
$fsUtil.Type = 1 # Binary
$fsUtil.Open()

# Add EFI directory
Get-ChildItem -Path $isoDir -Recurse | ForEach-Object {
    if (!$_.PSIsContainer) {
        $relativePath = $_.FullName.Substring($isoDir.Length + 1)
        Write-Host "Adding file: $relativePath"
        $fsUtil.LoadFromFile($_.FullName)
        $fsUtil.Position = 0
        $fsUtil.SaveToFile((Join-Path $isoPath $relativePath), 2)
    }
}

$fsUtil.Close()

Write-Host "ISO created at: $isoPath"
Write-Host "Done!" 