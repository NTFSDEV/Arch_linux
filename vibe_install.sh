#!/bin/bash

# ASCII Art
clear
echo -e "\e[34m##   ##   ####    ######   #######            ####    ##   ##   #####   ######     ##     ####     ####"
echo " ##   ##    ##      ##  ##   ##   #             ##     ###  ##  ##   ##  # ## #    ####     ##       ##"
echo "  ## ##     ##      ##  ##   ## #               ##     #### ##  #          ##     ##  ##    ##       ##"
echo "  ## ##     ##      #####    ####               ##     ## ####   #####     ##     ##  ##    ##       ##"
echo "   ###      ##      ##  ##   ## #               ##     ##  ###       ##    ##     ######    ##   #   ##   #"
echo "   ###      ##      ##  ##   ##   #             ##     ##   ##  ##   ##    ##     ##  ##    ##  ##   ##  ##"
echo "    #      ####    ######   #######            ####    ##   ##   #####    ####    ##  ##   #######  #######\e[0m"
echo -e "\n\e[32mVibe Install - Arch Linux Automated Installer\e[0m"
echo -e "\e[33mAuthor: NTFS DEV\e[0m\n"

# Check for UEFI
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    echo -e "\e[31mThis program only supports UEFI mode!\e[0m"
    exit 1
fi

# Check internet connection
echo -e "\e[34mChecking internet connection...\e[0m"
if ! ping -c 3 archlinux.org >/dev/null 2>&1; then
    echo -e "\e[31mNo internet connection detected. Please connect to the internet before proceeding.\e[0m"
    exit 1
fi

# Select bootloader
echo -e "\e[34mChoose your bootloader:\e[0m"
echo "1. GRUB (recommended)"
echo "2. rEFInd"
read -p "Enter your choice (1-2): " bootloader_choice

# Get disk to install to
lsblk
read -p "Enter the disk to install to (e.g., sda, nvme0n1): " disk
disk="/dev/$disk"

# Wipe any existing signatures
echo -e "\e[34mWiping existing disk signatures...\e[0m"
wipefs -a $disk

# Partitioning
echo -e "\e[34mPartitioning the disk...\e[0m"
(
    echo g      # Create new GPT partition table
    echo n      # Add new partition
    echo 1      # Partition number 1
    echo        # Default first sector
    echo +550M  # 550MB for EFI
    echo t      # Change partition type
    echo 1      # EFI System
    echo n      # Add new partition
    echo 2      # Partition number 2
    echo        # Default first sector
    echo +2G    # 2GB for swap
    echo t      # Change partition type
    echo 2      # Select partition 2
    echo 19     # Linux swap
    echo n      # Add new partition
    echo 3      # Partition number 3
    echo        # Default first sector
    echo        # Default last sector (rest of disk)
    echo t      # Change partition type
    echo 3      # Select partition 3
    echo 20     # Linux filesystem
    echo w      # Write changes
) | fdisk $disk

# Format partitions
echo -e "\e[34mFormatting partitions...\e[0m"
mkfs.fat -F32 ${disk}1
mkswap ${disk}2
swapon ${disk}2
mkfs.ext4 ${disk}3

# Mount partitions
echo -e "\e[34mMounting partitions...\e[0m"
mount ${disk}3 /mnt
mkdir /mnt/boot
mount ${disk}1 /mnt/boot

# Install base system
echo -e "\e[34mInstalling base system...\e[0m"
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab
echo -e "\e[34mGenerating fstab...\e[0m"
genfstab -U /mnt >> /mnt/etc/fstab

# Select kernel
echo -e "\e[34mChoose your kernel:\e[0m"
echo "1. Stable (linux)"
echo "2. LTS (linux-lts)"
echo "3. Zen (linux-zen)"
read -p "Enter your choice (1-3): " kernel_choice

case $kernel_choice in
    1) kernel="linux" ;;
    2) kernel="linux-lts" ;;
    3) kernel="linux-zen" ;;
    *) kernel="linux" ;;
esac

# Install selected kernel
if [ "$kernel" != "linux" ]; then
    echo -e "\e[34mInstalling $kernel...\e[0m"
    pacstrap /mnt $kernel
fi

# Chroot setup
echo -e "\e[34mConfiguring the system...\e[0m"
arch-chroot /mnt /bin/bash <<EOF
    # Set timezone
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    hwclock --systohc

    # Localization
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    # Network configuration
    echo "arch" > /etc/hostname
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1 localhost" >> /etc/hosts
    echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts

    # Install and configure bootloader
    if [ "$bootloader_choice" = "1" ]; then
        pacman -S --noconfirm grub efibootmgr
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nowatchdog"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    else
        pacman -S --noconfirm refind
        refind-install
    fi

    # Set root password
    echo "Setting root password:"
    passwd

    # Install additional packages
    pacman -S --noconfirm sudo networkmanager nano

    # Enable services
    systemctl enable NetworkManager

    # Create a user
    read -p "Do you want to create a user? [y/n]: " create_user
    if [ "$create_user" = "y" ]; then
        read -p "Enter username: " username
        useradd -m -G wheel -s /bin/bash $username
        echo "Setting password for $username:"
        passwd $username
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
            1) pacman -S --noconfirm gnome gdm; systemctl enable gdm ;;
            2) pacman -S --noconfirm plasma sddm; systemctl enable sddm ;;
            3) pacman -S --noconfirm xfce4 lightdm; systemctl enable lightdm ;;
            4) pacman -S --noconfirm lxde lxdm; systemctl enable lxdm ;;
        esac
    fi
EOF

# Cleanup and reboot
echo -e "\e[32mInstallation complete!\e[0m"
umount -R /mnt
echo -e "\e[34mRebooting in 5 seconds...\e[0m"
sleep 5
reboot
