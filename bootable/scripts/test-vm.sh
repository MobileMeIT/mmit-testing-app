#!/bin/bash

# Test VM script for Hardware Testing App bootable ISO
# This script helps test the generated ISO in a virtual machine

set -e

ISO_FILE="../output/hardware-testing-app.iso"
VM_NAME="hardware-test-vm"
VM_MEMORY="2048"
VM_DISK_SIZE="8G"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ISO exists
if [ ! -f "$ISO_FILE" ]; then
    print_error "ISO file '$ISO_FILE' not found. Please build the ISO first."
    exit 1
fi

# Check for virtualization software
check_virtualization() {
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
        print_info "Found QEMU - using QEMU for testing"
        USE_QEMU=1
    elif command -v VBoxManage >/dev/null 2>&1; then
        print_info "Found VirtualBox - using VirtualBox for testing"
        USE_VBOX=1
    else
        print_error "No virtualization software found. Please install QEMU or VirtualBox."
        print_info "Install QEMU: sudo apt-get install qemu-system-x86"
        print_info "Or download VirtualBox from: https://www.virtualbox.org/"
        exit 1
    fi
}

# Test with QEMU
test_with_qemu() {
    print_info "Starting QEMU virtual machine..."
    print_info "VM Configuration:"
    print_info "  - Memory: ${VM_MEMORY}MB"
    print_info "  - ISO: $ISO_FILE"
    print_info "  - Graphics: VGA with VNC display"
    
    print_warning "The VM will boot from the ISO. Close the QEMU window to stop the VM."
    
    qemu-system-x86_64 \
        -m "$VM_MEMORY" \
        -cdrom "$ISO_FILE" \
        -boot d \
        -vga std \
        -display gtk \
        -enable-kvm 2>/dev/null || \
    qemu-system-x86_64 \
        -m "$VM_MEMORY" \
        -cdrom "$ISO_FILE" \
        -boot d \
        -vga std \
        -display gtk
}

# Test with VirtualBox
test_with_vbox() {
    print_info "Setting up VirtualBox virtual machine..."
    
    # Remove existing VM if it exists
    if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
        print_warning "Removing existing VM: $VM_NAME"
        VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
        sleep 2
        VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
    fi
    
    # Create new VM
    print_info "Creating VM: $VM_NAME"
    VBoxManage createvm --name "$VM_NAME" --ostype "Ubuntu_64" --register
    
    # Configure VM
    VBoxManage modifyvm "$VM_NAME" \
        --memory "$VM_MEMORY" \
        --cpus 2 \
        --vram 128 \
        --graphicscontroller vmsvga \
        --accelerate3d on \
        --boot1 dvd \
        --boot2 disk \
        --boot3 none \
        --boot4 none
    
    # Create and attach storage
    VM_FOLDER=$(VBoxManage showvminfo "$VM_NAME" --machinereadable | grep "CfgFile=" | cut -d'"' -f2 | xargs dirname)
    VDI_FILE="$VM_FOLDER/${VM_NAME}.vdi"
    
    VBoxManage createhd --filename "$VDI_FILE" --size 8192 --format VDI
    VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI_FILE"
    
    # Attach ISO
    VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide
    VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$(pwd)/$ISO_FILE"
    
    print_info "Starting VM: $VM_NAME"
    print_warning "The VM will boot from the ISO. Use VirtualBox Manager to control the VM."
    
    VBoxManage startvm "$VM_NAME" --type gui
    
    print_info "VM started successfully!"
    print_info "To clean up later, run: VBoxManage unregistervm \"$VM_NAME\" --delete"
}

# Main execution
main() {
    print_info "Hardware Testing App - VM Test Script"
    print_info "======================================"
    
    check_virtualization
    
    if [ "$USE_QEMU" = "1" ]; then
        test_with_qemu
    elif [ "$USE_VBOX" = "1" ]; then
        test_with_vbox
    fi
    
    print_info "Test completed!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo ""
        echo "Test the Hardware Testing App bootable ISO in a virtual machine"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --clean       Clean up VirtualBox VMs"
        echo ""
        echo "Requirements:"
        echo "  - QEMU or VirtualBox installed"
        echo "  - ISO file: $ISO_FILE"
        exit 0
        ;;
    --clean)
        print_info "Cleaning up VirtualBox VMs..."
        if command -v VBoxManage >/dev/null 2>&1; then
            if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
                VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null || true
                sleep 2
                VBoxManage unregistervm "$VM_NAME" --delete
                print_info "Cleaned up VM: $VM_NAME"
            else
                print_info "No VM to clean up"
            fi
        else
            print_warning "VirtualBox not found"
        fi
        exit 0
        ;;
    *)
        main
        ;;
esac 