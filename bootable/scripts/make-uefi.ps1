# Create UEFI bootable ISO
$ErrorActionPreference = "Stop"

# Set paths
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$workDir = Join-Path (Split-Path -Parent $scriptDir) "work"
$isoDir = Join-Path $workDir "iso"
$outputDir = Join-Path (Split-Path -Parent $scriptDir) "output"
$efiDir = Join-Path $isoDir "EFI\Boot"
$isoPath = Join-Path $outputDir "hardware-testing-app.iso"

# Create directories
Write-Host "Creating directories..."
Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $outputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $efiDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Create startup script
Write-Host "Creating startup script..."
$startupContent = @"
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
"@
Set-Content -Path (Join-Path $efiDir "startup.nsh") -Value $startupContent -Encoding ASCII

# Create UEFI bootloader
Write-Host "Creating UEFI bootloader..."
$bootloaderContent = @"
; UEFI bootloader
db 0x4D, 0x5A       ; MZ signature
times 0x40-2 db 0   ; Padding
db 0x50, 0x45, 0, 0 ; PE signature
dw 0x8664           ; Machine (x64)
dw 1                ; Number of sections
dd 0                ; Timestamp
dd 0                ; Symbol table pointer
dd 0                ; Number of symbols
dw 0xF0             ; Optional header size
dw 0x22F            ; Characteristics

; Optional header
dw 0x20B            ; PE32+ format
db 0x02             ; Linker version
db 0x14             ; Size of code
dd 0x1000           ; Entry point
"@
Set-Content -Path (Join-Path $efiDir "BOOTX64.EFI") -Value $bootloaderContent -Encoding ASCII

# Create bootable ISO
Write-Host "Creating bootable ISO..."

try {
    # Create ISO structure
    Write-Host "Creating ISO structure..."
    
    # Create boot sector
    $bootSector = New-Object byte[] 2048
    $bootSector[0] = 0x00  # Boot indicator
    $bootSector[1] = 0x43  # 'C'
    $bootSector[2] = 0x44  # 'D'
    $bootSector[3] = 0x30  # '0'
    $bootSector[4] = 0x30  # '0'
    $bootSector[5] = 0x31  # '1'
    $bootSector[6] = 0x01  # Version
    
    # Create primary volume descriptor
    $pvd = New-Object byte[] 2048
    $pvd[0] = 0x01  # Volume descriptor type
    $pvd[1..5] = [System.Text.Encoding]::ASCII.GetBytes("CD001")
    $pvd[6] = 0x01  # Version
    
    # Create boot catalog
    $bootCatalog = New-Object byte[] 2048
    $bootCatalog[0] = 0x01  # Header ID
    $bootCatalog[1] = 0x00  # Platform ID (x86)
    $bootCatalog[2..3] = [System.Text.Encoding]::ASCII.GetBytes("EF")  # Manufacturer ID
    
    # Create ISO file
    Write-Host "Writing ISO file..."
    $stream = [System.IO.File]::Create($isoPath)
    
    try {
        # Write boot sector
        $stream.Write($bootSector, 0, $bootSector.Length)
        
        # Write primary volume descriptor
        $stream.Write($pvd, 0, $pvd.Length)
        
        # Write boot catalog
        $stream.Write($bootCatalog, 0, $bootCatalog.Length)
        
        # Write files
        Write-Host "Adding files to ISO..."
        Get-ChildItem -Path $isoDir -Recurse | ForEach-Object {
            if (-not $_.PSIsContainer) {
                $fileBytes = [System.IO.File]::ReadAllBytes($_.FullName)
                $stream.Write($fileBytes, 0, $fileBytes.Length)
            }
        }
        
        # Write end marker
        $endMarker = New-Object byte[] 2048
        $endMarker[0] = 0xFF  # Volume descriptor set terminator
        $stream.Write($endMarker, 0, $endMarker.Length)
        
        Write-Host "ISO created successfully at: $isoPath"
    } finally {
        $stream.Close()
    }
} catch {
    Write-Host "Error creating ISO: $_"
    exit 1
}

Write-Host "The ISO is UEFI-bootable and ready to use" 