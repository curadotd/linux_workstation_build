#!/bin/bash

# Arch Linux Installation Script - Part 3 (first Boot)
# This script configures the new Arch Linux system after first boot.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to setup snapshots
setup_snapshots() {
    print_status "Setting up BTRFS snapshots..."

    sudo umount /.snapshots
    sudo rm -rf /.snapshots
    # Create snapper config
    snapper -c root create-config /
    
    # Configure snapper
    cat > /etc/snapper/configs/root << EOF
SUBVOLUME="/"
SNAPSHOT_CREATE=yes
TIMELINE_CREATE=yes
TIMELINE_CLEANUP=yes
EOF
    
    print_success "BTRFS snapshots configured"
}

# Function to finalize installation
finalize_installation() {
    print_status "Finalizing installation..."
    
    # Enable timed snapshots
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
    
    print_success "Installation finalized"
}

# Function to display completion message
show_completion_message() {
    print_success "Arch Linux installation completed!"
    echo
    echo "Next steps:"
    echo "1. Reboot the system: reboot"
    echo "2. Login with username: $USERNAME"
    echo "3. Test snapshots: sudo snapper -c root create --description 'Test snapshot'"
    echo "4. View snapshots: sudo snapper -c root list"
    echo
    echo "If you encounter secure boot issues, refer to the troubleshooting section."
    echo
    read -p "Press Enter to reboot the system..."
    reboot
}

# Main installation function
main() {
    setup_snapshots
    finalize_installation
    show_completion_message
}

# Run main function
main "$@" 