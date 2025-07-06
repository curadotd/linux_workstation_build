#!/bin/bash

# Arch Linux Installation Script - Part 1 (Live Environment)
# This script automates the initial Arch Linux installation steps up to chroot.

set -e  # Exit on any error

# Pre-installation manual steps
pre_installation_instructions() {
    echo
    echo "==================== PRE-INSTALLATION STEPS ===================="
    echo "Before running this script, you must manually:"
    echo "  1. Connect to the Internet using Wired Lan or WiFi using: iwctl"
    echo "     (Example: 'iwctl', then 'station device connect SSID')"
    echo "  2. Partition your disk using: cgdisk <your-disk>"
    echo "     (Create 3 partitions: EFI (type EF00), root (type 8300), swap (type 8200))"
    echo "  3. Test your Network connection: ping -c 3 archlinux.org"
    echo "  4. Re-run this script to continue installation."
    echo "==============================================================="
    echo
    read -p "Have you completed these steps? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please complete the manual steps above, then re-run this script."
        exit 0
    fi
}

# Test WiFi connectivity
check_internet() {
    if ping -c 1 archlinux.org &> /dev/null; then
        echo "[INFO] Internet connection detected."
    else
        echo "[ERROR] No Internet connection. Please connect to Internet and try again."
        exit 1
    fi
}

# Check for 3 partitions on the target disk
check_partitions() {
    local disk="$1"
    local part_count
    part_count=$(lsblk -lno NAME,TYPE "$disk" | grep part | wc -l)
    if [[ $part_count -lt 3 ]]; then
        echo "[ERROR] Less than 3 partitions found on $disk. Please partition the disk as instructed."
        exit 1
    fi
    echo "[INFO] Found $part_count partitions on $disk."
}

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

# Function to get user input with validation
get_user_input() {
    local prompt="$1"
    local default="$2"
    local validation_func="$3"
    local input
    
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " input
            input="${input:-$default}"
        else
            read -p "$prompt: " input
        fi
        
        if [[ -n "$validation_func" ]]; then
            if $validation_func "$input"; then
                break
            fi
        else
            if [[ -n "$input" ]]; then
                break
            else
                print_error "Input cannot be empty"
            fi
        fi
    done
    
    echo "$input"
}

# Validation functions
validate_disk() {
    local disk="$1"
    if [[ -b "$disk" ]]; then
        return 0
    else
        print_error "Disk $disk does not exist"
        return 1
    fi
}

# Function to get configuration from user
get_configuration() {
    print_status "Getting installation configuration..."
    echo
    
    # Get disk
    print_status "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    echo
    DISK=$(get_user_input "Enter target disk (e.g., /dev/nvme0n1)" "" validate_disk)
    
    # Check partitions
    check_partitions "$DISK"
    # Check WiFi
    check_internet
    
    echo
    print_status "Configuration summary:"
    echo "  Disk: $DISK"
    echo
    
    read -p "Continue with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Configuration cancelled"
        exit 0
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to check if we're running Arch Linux
check_arch_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" != "arch" ]]; then
            print_error "This script is designed for Arch Linux. Detected: $ID"
            print_error "Please run this script on an Arch Linux live environment."
            exit 1
        fi
        print_success "Arch Linux detected: $PRETTY_NAME"
    else
        print_warning "Could not detect OS release file. Proceeding with caution..."
    fi
}

# Function to check if we're in the live environment
check_live_environment() {
    if ! mountpoint -q /mnt; then
        print_status "Detected live environment, proceeding with installation..."
    else
        print_warning "It appears you might already be in a chroot environment"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to setup networking (now handled manually)
setup_networking() {
    print_status "Networking setup should have been completed manually before running this script."
}

# Function to partition disk (now handled manually)
partition_disk() {
    print_status "Disk partitioning should have been completed manually before running this script."
}

# Function to format partitions
format_partitions() {
    print_status "Formatting partitions..."
    
    # Format EFI partition
    mkfs.fat -F32 ${DISK}p1
    
    # Format root partition
    mkfs.btrfs ${DISK}p2 -f
    
    # Format swap partition
    mkswap ${DISK}p3
    
    print_success "Partition formatting completed"
}

# Function to create BTRFS subvolumes
create_btrfs_subvolumes() {
    print_status "Creating BTRFS subvolumes..."
    
    # Mount root partition
    mount ${DISK}p2 /mnt
    
    # Create subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@.snapshots
    
    # Unmount
    umount /mnt
    
    print_success "BTRFS subvolumes created"
}

# Function to mount filesystem
mount_filesystem() {
    print_status "Mounting filesystem..."
    
    # Mount root with subvolume
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@ ${DISK}p2 /mnt
    
    # Create mount points
    mkdir -p /mnt/{boot,home,var/log,var/cache,var/lib/pacman/pkg,.snapshots}
    
    # Mount subvolumes
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@home ${DISK}p2 /mnt/home
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@log ${DISK}p2 /mnt/var/log
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@cache ${DISK}p2 /mnt/var/cache
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@pkg ${DISK}p2 /mnt/var/lib/pacman/pkg
    mount -o compress=zstd,noatime,space_cache=v2,ssd,subvol=@.snapshots ${DISK}p2 /mnt/.snapshots
    
    # Mount EFI partition
    mount ${DISK}p1 /mnt/boot
    
    # Enable swap
    swapon ${DISK}p3
    
    print_success "Filesystem mounted"
}

# Function to install base system
install_base_system() {
    print_status "Installing base system..."
    pacstrap -K /mnt base linux linux-firmware systemd networkmanager vim snapper mokutil grub efibootmgr sudo git
    print_success "Base system installed"
}

# Function to generate fstab
generate_fstab() {
    print_status "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    print_success "fstab generated"
}


# Main installation function
main() {
    print_status "Starting Arch Linux installation (Part 1)..."
    print_warning "This script will completely erase the target disk!"
    
    # Call pre-installation instructions
    check_arch_distro
    pre_installation_instructions

    # Get configuration from user
    get_configuration

    # Run installation steps
    check_root
    check_live_environment
    setup_networking
    partition_disk
    format_partitions
    create_btrfs_subvolumes
    mount_filesystem
    install_base_system
    generate_fstab

    # Clone my linux workstation build repository
    # Check if GIT_PATH is already set
    if [ -z "$GIT_PATH" ]; then
        read -p "Do you want to create a default location for git repositories? (y/n) " create_git_dir
        if [[ $create_git_dir =~ ^[Yy]$ ]]; then
            read -p "Enter the path for git repositories (default: $HOME/git): " git_path
            GIT_PATH=$git_path
            export GIT_PATH
            
            if [ ! -d "$GIT_PATH" ]; then
                mkdir -p "$GIT_PATH"
                echo "Created git directory at $GIT_PATH"
            else
                echo "Git directory already exists at $GIT_PATH"
            fi
        else
            echo "Skipping git directory creation."
        fi
    else
        echo "GIT_PATH is already set to $GIT_PATH"
    fi

    cd $GIT_PATH
    git clone https://github.com/curadotd/linux_workstation_build.git

    print_success "Base system installed and ready for configuration."
    echo
    echo "Next steps:"
    echo "1. arch-chroot /mnt"
    echo "2. Run: $GIT_PATH/arch_install_part2.sh"
    echo "3. Run: $GIT_PATH/arch_install_part3.sh after reboot"
    echo
}

# Run main function
main "$@" 