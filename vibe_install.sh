#!/usr/bin/env bash

# Author: NTFS DEV

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display ASCII art header
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

# Check for UEFI
if [ ! -d /sys/firmware/efi ]; then
    echo -e "${RED}This program supports UEFI only!${NC}"
    exit 1
fi

# Check internet connection
echo -e "${BLUE}Checking internet connection...${NC}"
if ! ping -c 1 archlinux.org &> /dev/null; then
    echo -e "${RED}No internet connection detected!${NC}"
    echo -e "${YELLOW}Please configure your network before proceeding.${NC}"
    exit 1
fi

# Select disk
disks=($(lsblk -d -p -n -l -o NAME,SIZE | grep -E 'sd|nvme|vd'))
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

# Confirm disk wipe
read -p "WARNING: This will erase ALL data on $disk_name. Continue? [y/N] " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation aborted.${NC}"
    exit 1
fi

# Partitioning
echo -e "${BLUE}Partitioning disk...${NC}"
parted -s "$disk_name" mklabel gpt
parted -s "$disk_name" mkpart primary fat32 1MiB 551MiB
parted -s "$disk_name" set 1 esp on
parted -s "$disk_name" mkpart primary linux-swap 551MiB 2615MiB
parted -s "$disk_name" mkpart primary ext4 2615MiB 100%

# Formatting partitions
echo -e "${BLUE}Formatting partitions...${NC}"
mkfs.fat -F32 "${disk_name}1"
mkswap "${disk_name}2"
swapon "${disk_name}2"
mkfs.ext4 "${disk_name}3"

# Mounting
echo -e "${BLUE}Mounting partitions...${NC}"
mount "${disk_name}3" /mnt
mkdir /mnt/boot
mount "${disk_name}1" /mnt/boot

# Install base system
echo -e "${BLUE}Installing base system...${NC}"
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
echo -e "${BLUE}Generating fstab...${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

# Bootloader selection
echo -e "${BLUE}Bootloader selection${NC}"
PS3="Select bootloader: "
options=("GRUB" "rEFInd (default)")
select opt in "${options[@]}"; do
    case $opt in
        "GRUB")
            echo -e "${GREEN}Installing GRUB...${NC}"
            arch-chroot /mnt pacman -S --noconfirm grub efibootmgr
            arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nowatchdog"/' /mnt/etc/default/grub
            arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
            break
            ;;
        "rEFInd (default)")
            echo -e "${GREEN}Installing rEFInd...${NC}"
            arch-chroot /mnt pacman -S --noconfirm refind
            arch-chroot /mnt refind-install
            break
            ;;
        *) echo -e "${RED}Invalid option!${NC}";;
    esac
done

# Kernel selection
echo -e "${BLUE}Kernel selection${NC}"
PS3="Select kernel: "
kernels=("linux (default)" "linux-lts" "linux-zen" "linux-hardened")
select kernel in "${kernels[@]}"; do
    case $kernel in
        "linux (default)")
            echo -e "${GREEN}Using default linux kernel${NC}"
            break
            ;;
        "linux-lts")
            echo -e "${GREEN}Installing LTS kernel...${NC}"
            arch-chroot /mnt pacman -S --noconfirm linux-lts
            break
            ;;
        "linux-zen")
            echo -e "${GREEN}Installing Zen kernel...${NC}"
            arch-chroot /mnt pacman -S --noconfirm linux-zen
            break
            ;;
        "linux-hardened")
            echo -e "${GREEN}Installing Hardened kernel...${NC}"
            arch-chroot /mnt pacman -S --noconfirm linux-hardened
            break
            ;;
        *) echo -e "${RED}Invalid option!${NC}";;
    esac
done

# System configuration
echo -e "${BLUE}Configuring system...${NC}"

# Hostname
read -p "Enter hostname [archlinux]: " hostname
hostname=${hostname:-archlinux}
echo "$hostname" > /mnt/etc/hostname

# Username
read -p "Enter username [NTFSDEV]: " username
username=${username:-NTFSDEV}
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"

# Password
echo -e "${YELLOW}Set root password:${NC}"
arch-chroot /mnt passwd
echo -e "${YELLOW}Set password for $username:${NC}"
arch-chroot /mnt passwd "$username"

# Locales
echo -e "${BLUE}Configuring locales...${NC}"
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen
sed -i 's/^#ru_RU.UTF-8/ru_RU.UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

# Timezone
arch-chroot /mnt ln -sf /usr/share/zoneinfo/UTC /etc/localtime
arch-chroot /mnt hwclock --systohc

# Network configuration
echo -e "${BLUE}Configuring network...${NC}"
arch-chroot /mnt pacman -S --noconfirm networkmanager
arch-chroot /mnt systemctl enable NetworkManager

# Sudo configuration
echo -e "${BLUE}Configuring sudo...${NC}"
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers

# Shell installation
read -p "Install additional shells? [y/N] " install_shell
if [[ $install_shell =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Available shells:${NC}"
    PS3="Select shell to install: "
    shells=("zsh" "fish" "bash-completion" "All of the above")
    select shell in "${shells[@]}"; do
        case $shell in
            "zsh")
                arch-chroot /mnt pacman -S --noconfirm zsh
                break
                ;;
            "fish")
                arch-chroot /mnt pacman -S --noconfirm fish
                break
                ;;
            "bash-completion")
                arch-chroot /mnt pacman -S --noconfirm bash-completion
                break
                ;;
            "All of the above")
                arch-chroot /mnt pacman -S --noconfirm zsh fish bash-completion
                break
                ;;
            *) echo -e "${RED}Invalid option!${NC}";;
        esac
    done
fi

# Final steps
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}You can now reboot into your new Arch Linux installation.${NC}"
echo -e "${BLUE}Don't forget to:${NC}"
echo -e "${BLUE}1. Remove installation media${NC}"
echo -e "${BLUE}2. Run 'reboot' command${NC}"

exit 0
