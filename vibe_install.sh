#!/bin/bash

# ASCII Art
echo -e '\e[1;36m'
cat << "EOF"
 ##   ##   ####    ######   #######            ####    ##   ##   #####   ######     ##     ####     ####
 ##   ##    ##      ##  ##   ##   #             ##     ###  ##  ##   ##  # ## #    ####     ##       ##
  ## ##     ##      ##  ##   ## #               ##     #### ##  #          ##     ##  ##    ##       ##
  ## ##     ##      #####    ####               ##     ## ####   #####     ##     ##  ##    ##       ##
   ###      ##      ##  ##   ## #               ##     ##  ###       ##    ##     ######    ##   #   ##   #
   ###      ##      ##  ##   ##   #             ##     ##   ##  ##   ##    ##     ##  ##    ##  ##   ##  ##
    #      ####    ######   #######            ####    ##   ##   #####    ####    ##  ##   #######  #######
EOF
echo -e '\e[0m'
echo -e '\e[1;35mWelcome to Vibe Install - Arch Linux Automated Installer\e[0m'
echo -e '\e[1;35mAuthor: NTFS DEV\e[0m'
echo ""

# Check for UEFI
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    echo -e '\e[1;31mThis program only supports UEFI mode.\e[0m'
    exit 1
fi

# Check internet connection
echo -e '\e[1;33mChecking internet connection...\e[0m'
if ! ping -c 3 archlinux.org >/dev/null 2>&1; then
    echo -e '\e[1;31mNo internet connection detected. Please connect to the internet before proceeding.\e[0m'
    exit 1
fi

# Select bootloader
echo -e '\e[1;32mSelect bootloader:\e[0m'
echo "1. GRUB (recommended for most users)"
echo "2. rEFInd (alternative boot manager)"
read -p "Enter your choice (1-2): " bootloader_choice

# Disk selection
lsblk
read -p "Enter the disk to install Arch Linux on (e.g., sda, nvme0n1): " disk
disk="/dev/$disk"

# Wipe existing signatures
echo -e '\e[1;33mWiping existing disk signatures...\e[0m'
wipefs -a $disk

# Partitioning
echo -e '\e[1;33mPartitioning the disk...\e[0m'
(
    echo g      # Create new GPT partition table
    echo n      # Add new partition (EFI)
    echo 1      # Partition number
    echo        # First sector (default)
    echo +550M  # Size
    echo t      # Change partition type
    echo 1      # EFI System
    echo n      # Add new partition (swap)
    echo 2      # Partition number
    echo        # First sector (default)
    echo +2G    # Size
    echo t      # Change partition type
    echo 2      # Partition number
    echo 19     # Linux swap
    echo n      # Add new partition (root)
    echo 3      # Partition number
    echo        # First sector (default)
    echo        # Last sector (default, rest of disk)
    echo t      # Change partition type
    echo 3      # Partition number
    echo 20     # Linux filesystem
    echo w      # Write changes
) | fdisk $disk

# Format partitions
echo -e '\e[1;33mFormatting partitions...\e[0m'
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
swapon ${disk}2
mkfs.ext4 ${disk}3

# Mount partitions
echo -e '\e[1;33mMounting partitions...\e[0m'
mount ${disk}3 /mnt
mkdir /mnt/boot
mount ${disk}1 /mnt/boot

# Kernel selection
echo -e '\e[1;32mSelect kernel:\e[0m'
echo "1. Linux (default)"
echo "2. Linux-lts (long term support)"
echo "3. Linux-zen (tuned for performance)"
read -p "Enter your choice (1-3): " kernel_choice

case $kernel_choice in
    1) kernel="linux";;
    2) kernel="linux-lts";;
    3) kernel="linux-zen";;
    *) kernel="linux";;
esac

# Base system installation
echo -e '\e[1;33mInstalling base system...\e[0m'
pacstrap /mnt base $kernel linux-firmware

# Generate fstab
echo -e '\e[1;33mGenerating fstab...\e[0m'
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot setup
echo -e '\e[1;33mConfiguring the installed system...\e[0m'
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

# Network configuration
echo "arch" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts

# Install essential packages
pacman -Syu --noconfirm vim networkmanager grub efibootmgr dosfstools os-prober mtools

# Install bootloader
if [ $bootloader_choice -eq 1 ]; then
    # GRUB installation
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else
    # rEFInd installation
    pacman -S --noconfirm refind
    refind-install
fi

# Enable NetworkManager
systemctl enable NetworkManager

# Root password
echo "Set root password:"
passwd

# User creation
read -p "Do you want to create a new user? [y/n]: " create_user
if [ "$create_user" = "y" ]; then
    read -p "Enter username: " username
    useradd -m -G wheel -s /bin/bash $username
    echo "Set password for $username:"
    passwd $username
    # Allow wheel group to use sudo
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
fi

# Install desktop environment
read -p "Do you want to install a desktop environment? [y/n]: " install_de
if [ "$install_de" = "y" ]; then
    echo "Available desktop environments:"
    echo "1. GNOME"
    echo "2. KDE Plasma"
    echo "3. XFCE"
    echo "4. LXDE"
    read -p "Enter your choice (1-4): " de_choice
    
    case $de_choice in
        1) pacman -S --noconfirm gnome gnome-extra gdm; systemctl enable gdm;;
        2) pacman -S --noconfirm plasma kde-applications sddm; systemctl enable sddm;;
        3) pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter; systemctl enable lightdm;;
        4) pacman -S --noconfirm lxde-gtk3 lxdm; systemctl enable lxdm;;
        *) echo "Invalid choice. Skipping desktop environment installation.";;
    esac
fi
EOF

# Cleanup
echo -e '\e[1;33mCleaning up...\e[0m'
umount -R /mnt

# Reboot
echo -e '\e[1;32mInstallation complete! Rebooting in 5 seconds...\e[0m'
sleep 5
reboot