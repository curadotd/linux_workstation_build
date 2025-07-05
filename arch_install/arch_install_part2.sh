#!/bin/bash

# Arch Linux Installation Script - Part 2 (Chroot Environment)
# This script configures the new Arch Linux system from within the chroot.

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

validate_hostname() {
    local hostname="$1"
    if [[ "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
        return 0
    else
        print_error "Invalid hostname format"
        return 1
    fi
}

validate_username() {
    local username="$1"
    if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        return 0
    else
        print_error "Invalid username format (lowercase letters, numbers, underscore, hyphen)"
        return 1
    fi
}

validate_timezone() {
    local timezone="$1"
    if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
        return 0
    else
        print_error "Timezone $timezone not found"
        return 1
    fi
}

get_configuration() {
    print_status "Getting installation configuration..."
    echo
    
    # Get hostname
    HOSTNAME=$(get_user_input "Enter hostname" "archlaptop" validate_hostname)
    
    # Get username
    USERNAME=$(get_user_input "Enter username" "user" validate_username)
    
    # Get timezone
    print_status "Common timezones:"
    echo "  America/New_York"
    echo "  America/Chicago"
    echo "  America/Denver"
    echo "  America/Los_Angeles"
    echo "  Europe/London"
    echo "  Europe/Paris"
    echo "  Asia/Tokyo"
    echo "  Australia/Sydney"
    echo
    TIMEZONE=$(get_user_input "Enter timezone" "America/New_York" validate_timezone)
    
    # Get locale
    LOCALE=$(get_user_input "Enter locale" "en_US.UTF-8" "")
    
    echo
    print_status "Configuration summary:"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Timezone: $TIMEZONE"
    echo "  Locale: $LOCALE"
    echo
    
    read -p "Continue with this configuration? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Configuration cancelled"
        exit 0
    fi
}

# Function to configure system
configure_system() {
    print_status "Configuring system..."
    
    # Set hostname
    echo "$HOSTNAME" > /etc/hostname
    
    # Configure timezone
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
    
    # Configure locale
    echo "$LOCALE UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=$LOCALE" > /etc/locale.conf
    
    # Configure hosts file
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    
    # Enable NetworkManager
    systemctl enable NetworkManager
    
    print_success "System configuration completed"
}

# Function to setup users
setup_users() {
    print_status "Setting up users..."
    
    # Set root password
    echo "Set root password"
    passwd
    
    # Create user
    useradd -m -G wheel $USERNAME
    echo "Set user password" 
    passwd $USERNAME
    
    # Configure sudo
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    
    print_success "Users configured"
}

# Function to setup secure boot
setup_secure_boot() {
    print_status "Setting up secure boot..."
    
    # Install sbctl
    pacman -S --noconfirm sbctl
    
    # Create keys
    sbctl create-keys
    
    # Enroll keys (including Microsoft's)
    sbctl enroll-keys -m
    
    print_success "Secure boot configured"
}

# Function to setup GRUB
setup_grub() {
    print_status "Setting up GRUB..."
    
    # Install GRUB
    pacman -S --noconfirm grub efibootmgr grub-btrfs
    
    # Generate GRUB config
    
    # Ensure /boot/grub exists
    if [ ! -d /boot/grub ]; then
        mkdir -p /boot/grub
    fi

    grub-mkconfig -o /boot/grub/grub.cfg
    
    # Install GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
    
    # Sign GRUB files
    sbctl sign /boot/EFI/GRUB/grubx64.efi
    sbctl sign /boot/vmlinuz-linux
    
    # Verify signatures
    sbctl verify
    
    # Enable grub-btrfs for snapshots
    systemctl enable grub-btrfsd
    
    print_success "GRUB configured"
}

# Function to install additional packages
install_additional_packages() {
    print_status "Installing additional packages..."
    
    # Install KDE and additional packages
    pacman -S --noconfirm \
        networkmanager bluez bluez-utils \
        pipewire wireplumber \
        power-profiles-daemon \
        powerdevil \
        amd-ucode \
        fastfetch
    
    # Enable services
    systemctl enable bluetooth
    systemctl enable fstrim.timer
    
    print_success "Additional packages installed"
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
    get_configuration
    configure_system
    setup_users
    setup_secure_boot
    setup_grub
    install_additional_packages
    show_completion_message
}

# Run main function
main "$@" 