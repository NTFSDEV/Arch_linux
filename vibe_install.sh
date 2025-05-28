#!/usr/bin/env bash

# Author: NTFS DEV

# --- Constants ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Variables ---
disk_name=""
username="NTFSDEV"
hostname="archlinux"
gpu_type=""

# --- Initial Checks ---
check_uefi() {
    if [ ! -d /sys/firmware/efi ]; then
        echo -e "${RED}This program supports UEFI only!${NC}"
        exit 1
    fi
}

check_internet() {
    if ! ping -c 1 archlinux.org &> /dev/null; then
        echo -e "${RED}No internet connection detected!${NC}"
        echo -e "${YELLOW}Please configure your network before proceeding.${NC}"
        exit 1
    fi
}

# --- Disk Operations ---
select_disk() {
    local disks=($(lsblk -d -p -n -l -o NAME,SIZE | grep -E 'sd|nvme|vd'))
    if [ ${#disks[@]} -eq 0 ]; then
        echo -e "${RED}No disks found!${NC}"
        exit 1
    fi

    echo -e "${BLUE}Available disks:${NC}"
    PS3="Select disk to install Arch Linux on: "
    select disk in "${disks[@]}"; do
        if [ -n "$disk" ]; then
            disk_name=$(echo "$disk" | awk '{print $1}')
            echo -e "${GREEN}Selected disk: $disk_name${NC}"
            break
        else
            echo -e "${RED}Invalid selection!${NC}"
        fi
    done

    read -p "WARNING: This will erase ALL data on $disk_name. Continue? [y/N] " confirm
    [[ $confirm =~ ^[Yy]$ ]] || { echo -e "${RED}Installation aborted.${NC}"; exit 1; }
}

partition_disk() {
    echo -e "${BLUE}Partitioning disk...${NC}"
    parted -s "$disk_name" mklabel gpt || { echo -e "${RED}Partitioning failed!${NC}"; exit 1; }
    
    # EFI partition (550MB)
    parted -s "$disk_name" mkpart primary fat32 1MiB 551MiB || exit 1
    parted -s "$disk_name" set 1 esp on || exit 1
    
    # Swap (2GB or 10% of disk if smaller than 20GB)
    local total_size=$(blockdev --getsize64 "$disk_name" | awk '{print $1/1024/1024/1024}')
    if (( $(echo "$total_size < 20" | bc -l) )); then
        swap_size=$(echo "$total_size * 0.1" | bc | awk '{printf "%d", $1}')GiB
    else
        swap_size=2GiB
    fi
    parted -s "$disk_name" mkpart primary linux-swap 551MiB "$swap_size" || exit 1
    
    # Root (remaining space)
    parted -s "$disk_name" mkpart primary ext4 "$swap_size" 100% || exit 1
}

format_partitions() {
    echo -e "${BLUE}Formatting partitions...${NC}"
    mkfs.fat -F32 "${disk_name}1" || { echo -e "${RED}EFI format failed!${NC}"; exit 1; }
    mkswap "${disk_name}2" || { echo -e "${RED}Swap creation failed!${NC}"; exit 1; }
    swapon "${disk_name}2" || exit 1
    mkfs.ext4 -F "${disk_name}3" || { echo -e "${RED}Root format failed!${NC}"; exit 1; }
}

mount_partitions() {
    echo -e "${BLUE}Mounting partitions...${NC}"
    mount "${disk_name}3" /mnt || { echo -e "${RED}Root mount failed!${NC}"; exit 1; }
    mkdir -p /mnt/boot && mount "${disk_name}1" /mnt/boot || { echo -e "${RED}Boot mount failed!${NC}"; exit 1; }
}

# --- GPU Detection ---
detect_gpu() {
    echo -e "${BLUE}Detecting GPU...${NC}"
    if lspci | grep -i "nvidia" &> /dev/null; then
        gpu_type="nvidia"
    elif lspci | grep -i "amd" &> /dev/null; then
        gpu_type="amd"
    elif lspci | grep -i "intel" &> /dev/null; then
        gpu_type="intel"
    else
        gpu_type="unknown"
    fi
    echo -e "${YELLOW}Detected GPU: $gpu_type${NC}"
}

install_gpu_drivers() {
    case $gpu_type in
        "nvidia")
            echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
            arch-chroot /mnt bash -c "pacman -S --noconfirm nvidia nvidia-utils nvidia-settings"
            ;;
        "amd")
            echo -e "${BLUE}Installing AMD drivers...${NC}"
            arch-chroot /mnt bash -c "pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon libva-mesa-driver"
            ;;
        "intel")
            echo -e "${BLUE}Installing Intel drivers...${NC}"
            arch-chroot /mnt bash -c "pacman -S --noconfirm xf86-video-intel vulkan-intel intel-media-driver"
            ;;
        *)
            echo -e "${YELLOW}Unknown GPU, skipping driver installation${NC}"
            ;;
    esac
}

# --- System Configuration ---
configure_system() {
    # Get user input
    read -p "Enter hostname [archlinux]: " hostname_input
    hostname=${hostname_input:-$hostname}
    
    read -p "Enter username [$username]: " username_input
    username=${username_input:-$username}

    # Bootloader selection
    echo -e "${BLUE}Bootloader selection${NC}"
    PS3="Select bootloader: "
    select bootloader in "GRUB" "rEFInd"; do
        case $bootloader in
            "GRUB")
                echo -e "${GREEN}Installing GRUB...${NC}"
                arch-chroot /mnt bash -c "pacman -S --noconfirm grub efibootmgr && \
                grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB && \
                sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nowatchdog\"/' /etc/default/grub && \
                grub-mkconfig -o /boot/grub/grub.cfg"
                break
                ;;
            "rEFInd")
                echo -e "${GREEN}Installing rEFInd...${NC}"
                arch-chroot /mnt bash -c "pacman -S --noconfirm refind && refind-install"
                break
                ;;
            *) echo -e "${RED}Invalid option!${NC}";;
        esac
    done

    # Kernel selection
    echo -e "${BLUE}Kernel selection${NC}"
    PS3="Select kernel: "
    select kernel in "linux (default)" "linux-lts" "linux-zen" "linux-hardened"; do
        case $kernel in
            "linux (default)")
                break
                ;;
            *)
                echo -e "${GREEN}Installing $kernel...${NC}"
                arch-chroot /mnt bash -c "pacman -S --noconfirm $kernel"
                break
                ;;
        esac
    done

    # Main chroot configuration
    arch-chroot /mnt bash -c "
    # Set hostname
    echo '$hostname' > /etc/hostname

    # Create user
    useradd -m -G wheel -s /bin/bash '$username'
    echo -e 'Setting password for $username:'
    passwd '$username'
    echo -e 'Setting root password:'
    passwd

    # Locales
    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    sed -i 's/^#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf

    # Time
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    hwclock --systohc

    # Network
    pacman -S --noconfirm networkmanager
    systemctl enable NetworkManager

    # Sudo
    echo '$username ALL=(ALL:ALL) ALL' >> /etc/sudoers

    # Shell
    pacman -S --noconfirm zsh fish bash-completion
    chsh -s /bin/bash '$username'
    "
}

# --- Cleanup ---
cleanup() {
    echo -e "${BLUE}Cleaning up...${NC}"
    if mountpoint -q /mnt; then
        umount -R /mnt || { echo -e "${RED}Failed to unmount /mnt!${NC}"; exit 1; }
    fi
    swapoff -a
    echo -e "${GREEN}Unmount successful. Safe to reboot.${NC}"
}

# --- Main ---
clear
echo -e "${BLUE}"
cat << "EOF"
## #### ###### ####### #### ## ## ##### ###### ## ####
## ## ## ## ## # ## ### ## ## ## # ## # #### ##
## ##     ##      ##  ##   ## #               ##     #### ##  #          ##     ##  ##    ##       ##
## ##     ##      #####    ####               ##     ## ####   #####     ##     ##  ##    ##       ##
 ###      ##      ##  ##   ## #               ##     ##  ###       ##    ##     ######    ##   #   ##   #
 ###      ##      ##  ##   ##   #             ##     ##   ##  ##   ##    ##     ##  ##    ##  ##   ##  ##
  #      ####    ######   #######            ####    ##   ##   #####    ####    ##  ##   #######  #######
EOF
echo -e "${NC}"
echo -e "${GREEN}Arch Linux Auto-Installer (Vibe Install)${NC}"
echo -e "${YELLOW}By NTFS DEV${NC}"
echo

# Execution flow
check_uefi
check_internet
select_disk
partition_disk
format_partitions
mount_partitions

# Install base system
echo -e "${BLUE}Installing base system...${NC}"
pacstrap /mnt base base-devel linux linux-firmware || { echo -e "${RED}Base install failed!${NC}"; exit 1; }
genfstab -U /mnt >> /mnt/etc/fstab || { echo -e "${RED}fstab generation failed!${NC}"; exit 1; }

# Configure system
detect_gpu
configure_system
install_gpu_drivers

# Install additional packages
arch-chroot /mnt bash -c "
    pacman -S --noconfirm sudo vim git wget curl openssh
"

# Cleanup and finish
cleanup

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}You can now reboot into your new Arch Linux installation.${NC}"
echo -e "${BLUE}Don't forget to:${NC}"
echo -e "${BLUE}1. Remove installation media${NC}"
echo -e "${BLUE}2. Run 'reboot' command${NC}"

exit 0
