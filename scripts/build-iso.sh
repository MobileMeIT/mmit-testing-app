#!/bin/bash
# Wrapper script to create UEFI-compatible ISO for MMIT Testing App with hardcoded parameters

# Ensure we're in the project root directory by changing to the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Call the original script with hardcoded parameters
# Parameters:
# 1. App Directory: ./ (current directory, project root)
# 2. App Name: "MMIT Testing App"
# 3. Splash Image: "" (none, defaults to black screen or text menu)
# 4. Output ISO: "MMITTestingApp-UEFI.iso"
echo "Creating UEFI-compatible ISO for MMIT Testing App..."
./scripts/create-uefi-iso.sh ./ "MMIT Testing App" "" "MMITTestingApp-UEFI.iso"

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "ISO creation completed successfully. Output: MMITTestingApp-UEFI.iso"
else
    echo "Error: ISO creation failed. Check the output for details."
fi 