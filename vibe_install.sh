#!/usr/bin/env bash

# VibeInstall - Модульный инсталлятор Arch Linux
# Автор: NTFS DEV
# Лицензия: MIT

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Глобальные переменные
LOG_FILE="/tmp/vibeinstall.log"
TMP_DIR="/tmp/vibeinstall"
CONFIG_FILE="${TMP_DIR}/config.cfg"
MIRRORLIST="/etc/pacman.d/mirrorlist"

# Проверка на root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Ошибка: Этот скрипт должен быть запущен с правами root!${NC}"
        exit 1
    fi
}

# Инициализация
init() {
    clear
    echo -e "${GREEN}"
    echo " ██▒   █▓ ▄▄▄       ██▓     ██▓    ▓█████  ██▀███  ▓█████ "
    echo "▓██░   █▒▒████▄    ▓██▒    ▓██▒    ▓█   ▀ ▓██ ▒ ██▒▓█   ▀ "
    echo " ▓██  █▒░▒██  ▀█▄  ▒██░    ▒██░    ▒███   ▓██ ░▄█ ▒▒███   "
    echo "  ▒██ █░░░██▄▄▄▄██ ▒██░    ▒██░    ▒▓█  ▄ ▒██▀▀█▄  ▒▓█  ▄ "
    echo "   ▒▀█░   ▓█   ▓██▒░██████▒░██████▒░▒████▒░██▓ ▒██▒░▒████▒"
    echo "   ░ ▐░   ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░░░ ▒░ ░░ ▒▓ ░▒▓░░░ ▒░ ░"
    echo "   ░ ░░    ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░ ░ ░  ░  ░▒ ░ ▒░ ░ ░  ░"
    echo "     ░░    ░   ▒     ░ ░     ░ ░      ░     ░░   ░    ░   "
    echo "      ░        ░  ░    ░  ░    ░  ░   ░  ░   ░        ░  ░"
    echo -e "${NC}"
    echo "VibeInstall - Модульный инсталлятор Arch Linux"
    echo "Автор: NTFS DEV"
    echo "=============================================="
    
    # Создание временных директорий
    mkdir -p "${TMP_DIR}"
    touch "${LOG_FILE}"
    
    # Проверка интернет-соединения
    check_internet
}

# Проверка интернет-соединения
check_internet() {
    echo -e "${BLUE}[*] Проверка интернет-соединения...${NC}"
    if ! ping -c 3 archlinux.org &>> "${LOG_FILE}"; then
        echo -e "${RED}Ошибка: Нет подключения к интернету!${NC}"
        echo "Проверьте ваше соединение и попробуйте снова."
        exit 1
    fi
    echo -e "${GREEN}[+] Интернет-соединение активно.${NC}"
}

# Логирование
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}" >> "${LOG_FILE}"
}

# Основное меню
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}Главное меню VibeInstall${NC}"
        echo "1. Настройка языка и локали"
        echo "2. Настройка дисков и файловых систем"
        echo "3. Выбор ядра"
        echo "4. Настройка пользователя"
        echo "5. Выбор графического окружения"
        echo "6. Установка драйверов"
        echo "7. Дополнительные пакеты"
        echo "8. Настройка загрузчика"
        echo "9. Дополнительные опции"
        echo "10. Начать установку"
        echo "11. Выход"
        
        read -p "Выберите опцию (1-11): " choice
        
        case $choice in
            1) locale_menu ;;
            2) disk_menu ;;
            3) kernel_menu ;;
            4) user_menu ;;
            5) de_menu ;;
            6) drivers_menu ;;
            7) packages_menu ;;
            8) bootloader_menu ;;
            9) extras_menu ;;
            10) start_installation ;;
            11) exit_installer ;;
            *) echo -e "${RED}Неверный выбор!${NC}"; sleep 1 ;;
        esac
    done
}

# Меню языка и локали
locale_menu() {
    clear
    echo -e "${GREEN}Настройка языка и локали${NC}"
    
    # Выбор языка системы
    echo "Доступные языки:"
    echo "1. English (US)"
    echo "2. Русский"
    echo "3. Deutsch"
    echo "4. Français"
    echo "5. Другой (ручной ввод)"
    
    read -p "Выберите язык системы (по умолчанию: Русский): " lang_choice
    case $lang_choice in
        1) SYSTEM_LANG="en_US.UTF-8" ;;
        2) SYSTEM_LANG="ru_RU.UTF-8" ;;
        3) SYSTEM_LANG="de_DE.UTF-8" ;;
        4) SYSTEM_LANG="fr_FR.UTF-8" ;;
        5) read -p "Введите язык (например, en_US.UTF-8): " SYSTEM_LANG ;;
        *) SYSTEM_LANG="ru_RU.UTF-8" ;;
    esac
    
    # Выбор временной зоны
    read -p "Введите временную зону (например, Europe/Moscow): " timezone
    if [ -z "$timezone" ]; then
        timezone="Europe/Moscow"
    fi
    
    # Выбор раскладки клавиатуры
    echo "Доступные раскладки клавиатуры:"
    echo "1. us (English)"
    echo "2. ru (Russian)"
    echo "3. de (German)"
    echo "4. fr (French)"
    echo "5. Другой (ручной ввод)"
    
    read -p "Выберите раскладку клавиатуры (по умолчанию: ru): " kb_choice
    case $kb_choice in
        1) KEYMAP="us" ;;
        2) KEYMAP="ru" ;;
        3) KEYMAP="de" ;;
        4) KEYMAP="fr" ;;
        5) read -p "Введите раскладку клавиатуры: " KEYMAP ;;
        *) KEYMAP="ru" ;;
    esac
    
    # Сохранение настроек
    echo "SYSTEM_LANG=${SYSTEM_LANG}" > "${CONFIG_FILE}"
    echo "TIMEZONE=${timezone}" >> "${CONFIG_FILE}"
    echo "KEYMAP=${KEYMAP}" >> "${CONFIG_FILE}"
    
    echo -e "${GREEN}[+] Настройки языка и локали сохранены.${NC}"
    sleep 2
}

# Меню дисков и файловых систем
disk_menu() {
    clear
    echo -e "${GREEN}Настройка дисков и файловых систем${NC}"
    
    # Показать доступные диски
    echo -e "${YELLOW}Доступные диски:${NC}"
    lsblk -f
    
    # Выбор диска для установки
    read -p "Введите диск для установки (например, /dev/sda): " install_disk
    if [ -z "$install_disk" ] || [ ! -e "$install_disk" ]; then
        echo -e "${RED}Ошибка: Неверный диск!${NC}"
        sleep 2
        return
    fi
    
    # Предупреждение о потере данных
    echo -e "${RED}Внимание: Все данные на диске ${install_disk} будут удалены!${NC}"
    read -p "Продолжить? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Выбор схемы разделов
    echo "Выберите схему разделов:"
    echo "1. Автоматическая (весь диск, ext4)"
    echo "2. Автоматическая (весь диск, Btrfs)"
    echo "3. Ручная настройка (cfdisk)"
    
    read -p "Выберите опцию (1-3): " partition_choice
    
    case $partition_choice in
        1)
            # Автоматическая настройка с ext4
            PARTITION_SCHEME="auto-ext4"
            ;;
        2)
            # Автоматическая настройка с Btrfs
            PARTITION_SCHEME="auto-btrfs"
            ;;
        3)
            # Ручная настройка
            cfdisk "$install_disk"
            PARTITION_SCHEME="manual"
            ;;
        *)
            echo -e "${RED}Неверный выбор!${NC}"
            sleep 1
            return
            ;;
    esac
    
    # Шифрование (LUKS)
    read -p "Включить шифрование диска (LUKS)? (y/N): " encrypt_choice
    if [[ "$encrypt_choice" =~ ^[Yy]$ ]]; then
        ENCRYPT_DISK="yes"
        read -p "Введите пароль для шифрования: " -s luks_password
        echo
    else
        ENCRYPT_DISK="no"
    fi
    
    # Сохранение настроек
    echo "INSTALL_DISK=${install_disk}" >> "${CONFIG_FILE}"
    echo "PARTITION_SCHEME=${PARTITION_SCHEME}" >> "${CONFIG_FILE}"
    echo "ENCRYPT_DISK=${ENCRYPT_DISK}" >> "${CONFIG_FILE}"
    if [ "$ENCRYPT_DISK" = "yes" ]; then
        echo "LUKS_PASSWORD=${luks_password}" >> "${CONFIG_FILE}"
    fi
    
    echo -e "${GREEN}[+] Настройки диска сохранены.${NC}"
    sleep 2
}

# Меню выбора ядра
kernel_menu() {
    clear
    echo -e "${GREEN}Выбор ядра Linux${NC}"
    
    echo "Доступные варианты ядра:"
    echo "1. Стандартное (linux)"
    echo "2. Долгосрочная поддержка (linux-lts)"
    echo "3. Оптимизированное (linux-zen)"
    echo "4. Усиленное безопасностью (linux-hardened)"
    
    read -p "Выберите ядро (1-4, по умолчанию: 1): " kernel_choice
    
    case $kernel_choice in
        1) KERNEL="linux" ;;
        2) KERNEL="linux-lts" ;;
        3) KERNEL="linux-zen" ;;
        4) KERNEL="linux-hardened" ;;
        *) KERNEL="linux" ;;
    esac
    
    echo "KERNEL=${KERNEL}" >> "${CONFIG_FILE}"
    echo -e "${GREEN}[+] Ядро ${KERNEL} выбрано.${NC}"
    sleep 1
}

# Меню настройки пользователя
user_menu() {
    clear
    echo -e "${GREEN}Настройка пользователя${NC}"
    
    read -p "Введите имя пользователя: " username
    if [ -z "$username" ]; then
        echo -e "${RED}Ошибка: Имя пользователя не может быть пустым!${NC}"
        sleep 2
        return
    fi
    
    read -p "Введите полное имя пользователя (необязательно): " fullname
    
    read -p "Введите пароль для пользователя ${username}: " -s user_password
    echo
    
    # Настройка sudo
    read -p "Дать пользователю ${username} права sudo? (Y/n): " sudo_choice
    if [[ "$sudo_choice" =~ ^[Nn]$ ]]; then
        SUDO_ACCESS="no"
    else
        SUDO_ACCESS="yes"
    fi
    
    # Настройка root пароля
    read -p "Установить пароль root? (y/N): " root_pass_choice
    if [[ "$root_pass_choice" =~ ^[Yy]$ ]]; then
        read -p "Введите пароль root: " -s root_password
        echo
        SET_ROOT_PASSWORD="yes"
    else
        SET_ROOT_PASSWORD="no"
    fi
    
    # Имя компьютера
    read -p "Введите имя компьютера (hostname): " hostname
    if [ -z "$hostname" ]; then
        hostname="archlinux"
    fi
    
    # Сохранение настроек
    echo "USERNAME=${username}" >> "${CONFIG_FILE}"
    echo "FULLNAME=\"${fullname}\"" >> "${CONFIG_FILE}"
    echo "USER_PASSWORD=${user_password}" >> "${CONFIG_FILE}"
    echo "SUDO_ACCESS=${SUDO_ACCESS}" >> "${CONFIG_FILE}"
    echo "SET_ROOT_PASSWORD=${SET_ROOT_PASSWORD}" >> "${CONFIG_FILE}"
    if [ "$SET_ROOT_PASSWORD" = "yes" ]; then
        echo "ROOT_PASSWORD=${root_password}" >> "${CONFIG_FILE}"
    fi
    echo "HOSTNAME=${hostname}" >> "${CONFIG_FILE}"
    
    echo -e "${GREEN}[+] Настройки пользователя сохранены.${NC}"
    sleep 1
}

# Меню выбора графического окружения
de_menu() {
    clear
    echo -e "${GREEN}Выбор графического окружения${NC}"
    
    echo "Доступные варианты:"
    echo "1. GNOME"
    echo "2. KDE Plasma"
    echo "3. XFCE"
    echo "4. i3wm"
    echo "5. Hyprland (Wayland)"
    echo "6. Только консоль (без DE)"
    echo "7. Пропустить (установить позже)"
    
    read -p "Выберите графическое окружение (1-7): " de_choice
    
    case $de_choice in
        1) DE="gnome" ;;
        2) DE="kde" ;;
        3) DE="xfce" ;;
        4) DE="i3" ;;
        5) DE="hyprland" ;;
        6) DE="console" ;;
        7) DE="none" ;;
        *) DE="none" ;;
    esac
    
    # Дополнительные опции для DE
    if [ "$DE" != "none" ] && [ "$DE" != "console" ]; then
        read -p "Установить дополнительные приложения для ${DE}? (y/N): " de_extra
        if [[ "$de_extra" =~ ^[Yy]$ ]]; then
            DE_EXTRAS="yes"
        else
            DE_EXTRAS="no"
        fi
        
        # Display manager
        echo "Выберите дисплей менеджер:"
        echo "1. GDM (рекомендуется для GNOME)"
        echo "2. SDDM (рекомендуется для KDE)"
        echo "3. LightDM"
        echo "4. None (ручной запуск)"
        
        read -p "Выберите опцию (1-4): " dm_choice
        
        case $dm_choice in
            1) DISPLAY_MANAGER="gdm" ;;
            2) DISPLAY_MANAGER="sddm" ;;
            3) DISPLAY_MANAGER="lightdm" ;;
            4) DISPLAY_MANAGER="none" ;;
            *) DISPLAY_MANAGER="gdm" ;;
        esac
    else
        DISPLAY_MANAGER="none"
    fi
    
    # Сохранение настроек
    echo "DE=${DE}" >> "${CONFIG_FILE}"
    echo "DISPLAY_MANAGER=${DISPLAY_MANAGER}" >> "${CONFIG_FILE}"
    if [ "$DE_EXTRAS" = "yes" ]; then
        echo "DE_EXTRAS=yes" >> "${CONFIG_FILE}"
    fi
    
    echo -e "${GREEN}[+] Графическое окружение выбрано.${NC}"
    sleep 1
}

# Меню драйверов
drivers_menu() {
    clear
    echo -e "${GREEN}Установка драйверов${NC}"
    
    # Видео драйверы
    echo "Выберите видео драйвер:"
    echo "1. Intel"
    echo "2. AMD (open-source)"
    echo "3. NVIDIA (proprietary)"
    echo "4. NVIDIA (open-source)"
    echo "5. Виртуальная машина (qxl, virtio)"
    echo "6. Пропустить"
    
    read -p "Выберите опцию (1-6): " gpu_choice
    
    case $gpu_choice in
        1) GPU_DRIVER="intel" ;;
        2) GPU_DRIVER="amd" ;;
        3) GPU_DRIVER="nvidia" ;;
        4) GPU_DRIVER="nvidia-open" ;;
        5) GPU_DRIVER="vm" ;;
        *) GPU_DRIVER="none" ;;
    esac
    
    # Другие драйверы
    echo "Установить дополнительные драйверы:"
    read -p "Wi-Fi (y/N): " wifi_drivers
    read -p "Bluetooth (y/N): " bluetooth_drivers
    read -p "Звук (pulseaudio/pipewire) (P/p/N): " audio_choice
    
    # Сохранение настроек
    echo "GPU_DRIVER=${GPU_DRIVER}" >> "${CONFIG_FILE}"
    if [[ "$wifi_drivers" =~ ^[Yy]$ ]]; then
        echo "WIFI_DRIVERS=yes" >> "${CONFIG_FILE}"
    fi
    if [[ "$bluetooth_drivers" =~ ^[Yy]$ ]]; then
        echo "BLUETOOTH_DRIVERS=yes" >> "${CONFIG_FILE}"
    fi
    case "$audio_choice" in
        [Pp]*)
            if [[ "$audio_choice" == "p" ]]; then
                echo "AUDIO_DRIVER=pipewire" >> "${CONFIG_FILE}"
            else
                echo "AUDIO_DRIVER=pulseaudio" >> "${CONFIG_FILE}"
            fi
            ;;
        *) echo "AUDIO_DRIVER=none" >> "${CONFIG_FILE}" ;;
    esac
    
    echo -e "${GREEN}[+] Настройки драйверов сохранены.${NC}"
    sleep 1
}

# Меню дополнительных пакетов
packages_menu() {
    clear
    echo -e "${GREEN}Дополнительные пакеты${NC}"
    
    echo "Выберите группы пакетов для установки:"
    echo "1. Разработка (gcc, make, git, docker и др.)"
    echo "2. Мультимедиа (ffmpeg, vlc, gstreamer)"
    echo "3. Офис (libreoffice, evince)"
    echo "4. Игры (steam, wine, lutris)"
    echo "5. Все вышеперечисленное"
    echo "6. Пропустить"
    
    read -p "Выберите опции (через запятую, например 1,3): " packages_choices
    
    # Очищаем предыдущие настройки пакетов
    > "${TMP_DIR}/packages.cfg"
    
    IFS=',' read -ra choices <<< "$packages_choices"
    for choice in "${choices[@]}"; do
        case $choice in
            1) echo "development" >> "${TMP_DIR}/packages.cfg" ;;
            2) echo "multimedia" >> "${TMP_DIR}/packages.cfg" ;;
            3) echo "office" >> "${TMP_DIR}/packages.cfg" ;;
            4) echo "games" >> "${TMP_DIR}/packages.cfg" ;;
            5) 
                echo "development" >> "${TMP_DIR}/packages.cfg"
                echo "multimedia" >> "${TMP_DIR}/packages.cfg"
                echo "office" >> "${TMP_DIR}/packages.cfg"
                echo "games" >> "${TMP_DIR}/packages.cfg"
                ;;
        esac
    done
    
    # Выбор оболочки
    echo "Выберите оболочку (shell):"
    echo "1. bash"
    echo "2. zsh"
    echo "3. fish"
    echo "4. Пропустить (использовать bash)"
    
    read -p "Выберите опцию (1-4): " shell_choice
    
    case $shell_choice in
        1) SHELL="bash" ;;
        2) SHELL="zsh" ;;
        3) SHELL="fish" ;;
        *) SHELL="bash" ;;
    esac
    
    echo "SHELL=${SHELL}" >> "${CONFIG_FILE}"
    
    echo -e "${GREEN}[+] Дополнительные пакеты выбраны.${NC}"
    sleep 1
}

# Меню загрузчика
bootloader_menu() {
    clear
    echo -e "${GREEN}Настройка загрузчика${NC}"
    
    # Проверка режима загрузки (UEFI/BIOS)
    if [ -d "/sys/firmware/efi/efivars" ]; then
        BOOT_MODE="uefi"
        echo "Обнаружен режим UEFI"
    else
        BOOT_MODE="bios"
        echo "Обнаружен режим Legacy BIOS"
    fi
    
    echo "Выберите загрузчик:"
    echo "1. GRUB (рекомендуется)"
    echo "2. systemd-boot (только UEFI)"
    echo "3. rEFInd (только UEFI)"
    
    read -p "Выберите опцию (1-3): " bootloader_choice
    
    case $bootloader_choice in
        1) BOOTLOADER="grub" ;;
        2) 
            if [ "$BOOT_MODE" = "uefi" ]; then
                BOOTLOADER="systemd-boot"
            else
                echo -e "${RED}Ошибка: systemd-boot работает только в UEFI режиме!${NC}"
                sleep 2
                BOOTLOADER="grub"
            fi
            ;;
        3) 
            if [ "$BOOT_MODE" = "uefi" ]; then
                BOOTLOADER="refind"
            else
                echo -e "${RED}Ошибка: rEFInd работает только в UEFI режиме!${NC}"
                sleep 2
                BOOTLOADER="grub"
            fi
            ;;
        *) BOOTLOADER="grub" ;;
    esac
    
    # Дополнительные параметры для GRUB
    if [ "$BOOTLOADER" = "grub" ]; then
        read -p "Использовать красивую тему для GRUB? (y/N): " grub_theme
        if [[ "$grub_theme" =~ ^[Yy]$ ]]; then
            GRUB_THEME="yes"
        else
            GRUB_THEME="no"
        fi
    fi
    
    # Сохранение настроек
    echo "BOOTLOADER=${BOOTLOADER}" >> "${CONFIG_FILE}"
    echo "BOOT_MODE=${BOOT_MODE}" >> "${CONFIG_FILE}"
    if [ "$BOOTLOADER" = "grub" ]; then
        echo "GRUB_THEME=${GRUB_THEME}" >> "${CONFIG_FILE}"
    fi
    
    echo -e "${GREEN}[+] Настройки загрузчика сохранены.${NC}"
    sleep 1
}

# Меню дополнительных опций
extras_menu() {
    clear
    echo -e "${GREEN}Дополнительные опции${NC}"
    
    # Включение AUR (yay)
    read -p "Включить поддержку AUR (yay)? (Y/n): " aur_support
    if [[ "$aur_support" =~ ^[Nn]$ ]]; then
        AUR_SUPPORT="no"
    else
        AUR_SUPPORT="yes"
    fi
    
    # Оптимизация зеркал pacman
    read -p "Оптимизировать зеркала pacman (reflector)? (Y/n): " optimize_mirrors
    if [[ "$optimize_mirrors" =~ ^[Nn]$ ]]; then
        OPTIMIZE_MIRRORS="no"
    else
        OPTIMIZE_MIRRORS="yes"
    fi
    
    # Firewall
    echo "Выберите firewall:"
    echo "1. ufw (простой)"
    echo "2. firewalld (продвинутый)"
    echo "3. Отключить firewall"
    
    read -p "Выберите опцию (1-3): " firewall_choice
    
    case $firewall_choice in
        1) FIREWALL="ufw" ;;
        2) FIREWALL="firewalld" ;;
        *) FIREWALL="none" ;;
    esac
    
    # Демоны
    echo "Автозагрузка сервисов:"
    read -p "Включить NetworkManager? (Y/n): " networkmanager
    if [[ "$networkmanager" =~ ^[Nn]$ ]]; then
        NETWORKMANAGER="no"
    else
        NETWORKMANAGER="yes"
    fi
    
    read -p "Включить Bluetooth? (y/N): " bluetooth
    if [[ "$bluetooth" =~ ^[Yy]$ ]]; then
        BLUETOOTH="yes"
    else
        BLUETOOTH="no"
    fi
    
    # Сохранение настроек
    echo "AUR_SUPPORT=${AUR_SUPPORT}" >> "${CONFIG_FILE}"
    echo "OPTIMIZE_MIRRORS=${OPTIMIZE_MIRRORS}" >> "${CONFIG_FILE}"
    echo "FIREWALL=${FIREWALL}" >> "${CONFIG_FILE}"
    echo "NETWORKMANAGER=${NETWORKMANAGER}" >> "${CONFIG_FILE}"
    echo "BLUETOOTH=${BLUETOOTH}" >> "${CONFIG_FILE}"
    
    echo -e "${GREEN}[+] Дополнительные опции сохранены.${NC}"
    sleep 1
}

# Начало установки
start_installation() {
    clear
    echo -e "${RED}ВНИМАНИЕ: Это последний шанс отменить установку!${NC}"
    echo "После этого все данные на выбранном диске будут уничтожены."
    read -p "Вы уверены, что хотите продолжить установку? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Установка отменена.${NC}"
        exit 0
    fi
    
    # Загрузка конфигурации
    source "${CONFIG_FILE}"
    
    # Логирование начала установки
    log "Начало установки Arch Linux с VibeInstall"
    
    # Обновление ключей pacman
    echo -e "${BLUE}[*] Обновление ключей pacman...${NC}"
    pacman-key --init &>> "${LOG_FILE}"
    pacman-key --populate archlinux &>> "${LOG_FILE}"
    
    # Разметка диска
    echo -e "${BLUE}[*] Разметка диска...${NC}"
    if [ "$PARTITION_SCHEME" = "auto-ext4" ]; then
        auto_partition_ext4
    elif [ "$PARTITION_SCHEME" = "auto-btrfs" ]; then
        auto_partition_btrfs
    else
        manual_partition
    fi
    
    # Форматирование и монтирование
    echo -e "${BLUE}[*] Форматирование и монтирование разделов...${NC}"
    format_and_mount
    
    # Установка базовой системы
    echo -e "${BLUE}[*] Установка базовой системы...${NC}"
    install_base_system
    
    # Настройка системы
    echo -e "${BLUE}[*] Настройка системы...${NC}"
    configure_system
    
    # Установка загрузчика
    echo -e "${BLUE}[*] Установка загрузчика...${NC}"
    install_bootloader
    
    # Установка графического окружения
    if [ "$DE" != "none" ] && [ "$DE" != "console" ]; then
        echo -e "${BLUE}[*] Установка графического окружения...${NC}"
        install_de
    fi
    
    # Установка драйверов
    echo -e "${BLUE}[*] Установка драйверов...${NC}"
    install_drivers
    
    # Установка дополнительных пакетов
    if [ -f "${TMP_DIR}/packages.cfg" ]; then
        echo -e "${BLUE}[*] Установка дополнительных пакетов...${NC}"
        install_extra_packages
    fi
    
    # Настройка пользователя
    echo -e "${BLUE}[*] Настройка пользователя...${NC}"
    setup_user
    
    # Дополнительные настройки
    echo -e "${BLUE}[*] Применение дополнительных настроек...${NC}"
    apply_extra_settings
    
    # Завершение установки
    echo -e "${GREEN}[+] Установка завершена успешно!${NC}"
    echo -e "${YELLOW}Для входа в систему перезагрузите компьютер и извлеките установочный носитель.${NC}"
    
    log "Установка успешно завершена"
    exit 0
}

# Функции для разметки диска
auto_partition_ext4() {
    # Автоматическая разметка с ext4
    log "Автоматическая разметка диска (ext4)"
    
    # Очистка диска
    sgdisk --zap-all "${INSTALL_DISK}" &>> "${LOG_FILE}"
    
    # Создание разделов
    if [ "$BOOT_MODE" = "uefi" ]; then
        # UEFI разделы
        parted --script "${INSTALL_DISK}" \
            mklabel gpt \
            mkpart primary fat32 1MiB 513MiB \
            set 1 esp on \
            mkpart primary ext4 513MiB 100% &>> "${LOG_FILE}"
        
        BOOT_PARTITION="${INSTALL_DISK}1"
        ROOT_PARTITION="${INSTALL_DISK}2"
    else
        # BIOS разделы
        parted --script "${INSTALL_DISK}" \
            mklabel msdos \
            mkpart primary ext4 1MiB 513MiB \
            set 1 boot on \
            mkpart primary ext4 513MiB 100% &>> "${LOG_FILE}"
        
        BOOT_PARTITION="${INSTALL_DISK}1"
        ROOT_PARTITION="${INSTALL_DISK}2"
    fi
    
    # Шифрование при необходимости
    if [ "$ENCRYPT_DISK" = "yes" ]; then
        encrypt_disk
    fi
}

auto_partition_btrfs() {
    # Автоматическая разметка с Btrfs
    log "Автоматическая разметка диска (Btrfs)"
    
    # Очистка диска
    sgdisk --zap-all "${INSTALL_DISK}" &>> "${LOG_FILE}"
    
    # Создание разделов
    if [ "$BOOT_MODE" = "uefi" ]; then
        # UEFI разделы
        parted --script "${INSTALL_DISK}" \
            mklabel gpt \
            mkpart primary fat32 1MiB 513MiB \
            set 1 esp on \
            mkpart primary btrfs 513MiB 100% &>> "${LOG_FILE}"
        
        BOOT_PARTITION="${INSTALL_DISK}1"
        ROOT_PARTITION="${INSTALL_DISK}2"
    else
        # BIOS разделы
        parted --script "${INSTALL_DISK}" \
            mklabel msdos \
            mkpart primary ext4 1MiB 513MiB \
            set 1 boot on \
            mkpart primary btrfs 513MiB 100% &>> "${LOG_FILE}"
        
        BOOT_PARTITION="${INSTALL_DISK}1"
        ROOT_PARTITION="${INSTALL_DISK}2"
    fi
    
    # Шифрование при необходимости
    if [ "$ENCRYPT_DISK" = "yes" ]; then
        encrypt_disk
    fi
}

manual_partition() {
    # Ручная разметка диска
    log "Ручная разметка диска"
    
    echo -e "${YELLOW}Завершите ручную разметку диска в cfdisk и нажмите Enter...${NC}"
    cfdisk "${INSTALL_DISK}"
    
    # Запрос информации о разделах
    lsblk -f "${INSTALL_DISK}"
    
    read -p "Введите раздел для загрузчика (например, ${INSTALL_DISK}1): " BOOT_PARTITION
    read -p "Введите корневой раздел (например, ${INSTALL_DISK}2): " ROOT_PARTITION
    
    # Проверка разделов
    if [ ! -e "$BOOT_PARTITION" ] || [ ! -e "$ROOT_PARTITION" ]; then
        echo -e "${RED}Ошибка: Указанные разделы не существуют!${NC}"
        exit 1
    fi
    
    # Шифрование при необходимости
    if [ "$ENCRYPT_DISK" = "yes" ]; then
        encrypt_disk
    fi
}

encrypt_disk() {
    # Шифрование диска с LUKS
    log "Шифрование раздела ${ROOT_PARTITION} с LUKS"
    
    echo -e "${YELLOW}Настройка шифрования LUKS...${NC}"
    cryptsetup luksFormat --type luks2 "${ROOT_PARTITION}" <<< "$LUKS_PASSWORD" &>> "${LOG_FILE}"
    cryptsetup open "${ROOT_PARTITION}" cryptroot <<< "$LUKS_PASSWORD" &>> "${LOG_FILE}"
    
    # Обновление переменной корневого раздела
    ROOT_PARTITION="/dev/mapper/cryptroot"
}

# Форматирование и монтирование
format_and_mount() {
    log "Форматирование и монтирование разделов"
    
    # Форматирование загрузочного раздела
    if [ "$BOOT_MODE" = "uefi" ]; then
        mkfs.fat -F32 "${BOOT_PARTITION}" &>> "${LOG_FILE}"
    else
        mkfs.ext4 -F "${BOOT_PARTITION}" &>> "${LOG_FILE}"
    fi
    
    # Форматирование корневого раздела
    if [ "$PARTITION_SCHEME" = "auto-btrfs" ]; then
        mkfs.btrfs -f "${ROOT_PARTITION}" &>> "${LOG_FILE}"
    else
        mkfs.ext4 -F "${ROOT_PARTITION}" &>> "${LOG_FILE}"
    fi
    
    # Монтирование корневого раздела
    mount "${ROOT_PARTITION}" /mnt &>> "${LOG_FILE}"
    
    # Создание и монтирование подтомов Btrfs при необходимости
    if [ "$PARTITION_SCHEME" = "auto-btrfs" ]; then
        btrfs subvolume create /mnt/@ &>> "${LOG_FILE}"
        btrfs subvolume create /mnt/@home &>> "${LOG_FILE}"
        btrfs subvolume create /mnt/@snapshots &>> "${LOG_FILE}"
        btrfs subvolume create /mnt/@var_log &>> "${LOG_FILE}"
        
        umount /mnt &>> "${LOG_FILE}"
        
        # Монтирование с опциями Btrfs
        mount -o noatime,compress=zstd,space_cache=v2,subvol=@ "${ROOT_PARTITION}" /mnt &>> "${LOG_FILE}"
        mkdir -p /mnt/{home,.snapshots,var/log} &>> "${LOG_FILE}"
        mount -o noatime,compress=zstd,space_cache=v2,subvol=@home "${ROOT_PARTITION}" /mnt/home &>> "${LOG_FILE}"
        mount -o noatime,compress=zstd,space_cache=v2,subvol=@snapshots "${ROOT_PARTITION}" /mnt/.snapshots &>> "${LOG_FILE}"
        mount -o noatime,compress=zstd,space_cache=v2,subvol=@var_log "${ROOT_PARTITION}" /mnt/var/log &>> "${LOG_FILE}"
    fi
    
    # Монтирование загрузочного раздела
    mkdir -p /mnt/boot &>> "${LOG_FILE}"
    mount "${BOOT_PARTITION}" /mnt/boot &>> "${LOG_FILE}"
}

# Установка базовой системы
install_base_system() {
    log "Установка базовой системы"
    
    # Оптимизация зеркал
    if [ "$OPTIMIZE_MIRRORS" = "yes" ]; then
        echo -e "${BLUE}[*] Оптимизация зеркал pacman...${NC}"
        pacman -Sy --noconfirm reflector &>> "${LOG_FILE}"
        reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &>> "${LOG_FILE}"
    fi
    
    # Установка базовых пакетов
    base_packages=("base" "base-devel" "${KERNEL}" "${KERNEL}-headers" "linux-firmware" "btrfs-progs" "networkmanager")
    
    echo -e "${BLUE}[*] Установка базовых пакетов...${NC}"
    pacstrap /mnt "${base_packages[@]}" &>> "${LOG_FILE}"
    
    # Генерация fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Копирование конфигурации в новую систему
    mkdir -p /mnt/tmp/vibeinstall &>> "${LOG_FILE}"
    cp -r "${TMP_DIR}"/* /mnt/tmp/vibeinstall/ &>> "${LOG_FILE}"
    
    # Создание chroot скрипта
    create_chroot_script
}

# Создание скрипта для chroot
create_chroot_script() {
    cat << EOF > /mnt/root/chroot_install.sh
#!/usr/bin/env bash

# Логирование
LOG_FILE="/root/vibeinstall.log"
exec > >(tee -a "\${LOG_FILE}") 2>&1

# Загрузка конфигурации
source /tmp/vibeinstall/config.cfg

# Настройка системы
configure_system() {
    echo -e "\033[0;34m[*] Настройка системы...\033[0m"
    
    # Временная зона
    ln -sf "/usr/share/zoneinfo/\${TIMEZONE}" /etc/localtime
    hwclock --systohc
    
    # Локализация
    sed -i "s/^#\\(${SYSTEM_LANG}\\)/\\1/" /etc/locale.gen
    echo "LANG=\${SYSTEM_LANG}" > /etc/locale.conf
    echo "KEYMAP=\${KEYMAP}" > /etc/vconsole.conf
    locale-gen
    
    # Имя компьютера
    echo "\${HOSTNAME}" > /etc/hostname
    
    # Настройка hosts
    cat > /etc/hosts << EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   \${HOSTNAME}.localdomain \${HOSTNAME}
EOL
    
    # Настройка сети
    if [ "\${NETWORKMANAGER}" = "yes" ]; then
        systemctl enable NetworkManager
    else
        systemctl enable systemd-networkd systemd-resolved
    fi
    
    # Настройка sudo
    if [ "\${SUDO_ACCESS}" = "yes" ]; then
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    fi
    
    # Пароль root
    if [ "\${SET_ROOT_PASSWORD}" = "yes" ]; then
        echo -e "\${ROOT_PASSWORD}\n\${ROOT_PASSWORD}" | passwd
    fi
}

# Установка загрузчика
install_bootloader() {
    echo -e "\033[0;34m[*] Установка загрузчика...\033[0m"
    
    case "\${BOOTLOADER}" in
        "grub")
            pacman -Sy --noconfirm grub os-prober &>> "\${LOG_FILE}"
            
            if [ "\${BOOT_MODE}" = "uefi" ]; then
                pacman -S --noconfirm efibootmgr &>> "\${LOG_FILE}"
                grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB &>> "\${LOG_FILE}"
            else
                grub-install --target=i386-pc "\${INSTALL_DISK}" &>> "\${LOG_FILE}"
            fi
            
            # Настройка шифрования для GRUB
            if [ "\${ENCRYPT_DISK}" = "yes" ]; then
                sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=\$(blkid -s UUID -o value \${ROOT_PARTITION}):cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
            fi
            
            # Тема для GRUB
            if [ "\${GRUB_THEME}" = "yes" ]; then
                pacman -S --noconfirm grub-theme-vimix &>> "\${LOG_FILE}"
                echo 'GRUB_THEME="/usr/share/grub/themes/vimix/theme.txt"' >> /etc/default/grub
            fi
            
            grub-mkconfig -o /boot/grub/grub.cfg &>> "\${LOG_FILE}"
            ;;
            
        "systemd-boot")
            bootctl install &>> "\${LOG_FILE}"
            
            # Создание записи загрузки
            cat > /boot/loader/entries/arch.conf << EOL
title   Arch Linux
linux   /vmlinuz-\${KERNEL}
initrd  /initramfs-\${KERNEL}.img
options root=\${ROOT_PARTITION} rw
EOL
            
            # Настройка шифрования для systemd-boot
            if [ "\${ENCRYPT_DISK}" = "yes" ]; then
                sed -i "s|options root=.*|options root=/dev/mapper/cryptroot rw cryptdevice=UUID=\$(blkid -s UUID -o value \${ROOT_PARTITION}):cryptroot|" /boot/loader/entries/arch.conf
            fi
            
            # Настройка загрузчика по умолчанию
            echo "default arch" > /boot/loader/loader.conf
            echo "timeout 5" >> /boot/loader/loader.conf
            ;;
            
        "refind")
            pacman -Sy --noconfirm refind &>> "\${LOG_FILE}"
            refind-install &>> "\${LOG_FILE}"
            
            # Настройка шифрования для rEFInd
            if [ "\${ENCRYPT_DISK}" = "yes" ]; then
                sed -i "s|\"root=.*\"|\"root=/dev/mapper/cryptroot cryptdevice=UUID=\$(blkid -s UUID -o value \${ROOT_PARTITION}):cryptroot\"|" /boot/refind_linux.conf
            fi
            ;;
    esac
}

# Установка графического окружения
install_de() {
    echo -e "\033[0;34m[*] Установка графического окружения...\033[0m"
    
    case "\${DE}" in
        "gnome")
            pacman -Sy --noconfirm gnome gnome-extra &>> "\${LOG_FILE}"
            systemctl enable gdm
            ;;
        "kde")
            pacman -Sy --noconfirm plasma kde-applications &>> "\${LOG_FILE}"
            systemctl enable sddm
            ;;
        "xfce")
            pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter &>> "\${LOG_FILE}"
            systemctl enable lightdm
            ;;
        "i3")
            pacman -Sy --noconfirm i3-wm i3status i3lock dmenu lightdm lightdm-gtk-greeter &>> "\${LOG_FILE}"
            systemctl enable lightdm
            ;;
        "hyprland")
            pacman -Sy --noconfirm hyprland waybar rofi lightdm lightdm-gtk-greeter &>> "\${LOG_FILE}"
            systemctl enable lightdm
            ;;
    esac
    
    # Дополнительные приложения для DE
    if [ "\${DE_EXTRAS}" = "yes" ]; then
        pacman -Sy --noconfirm firefox vlc libreoffice gimp &>> "\${LOG_FILE}"
    fi
}

# Установка драйверов
install_drivers() {
    echo -e "\033[0;34m[*] Установка драйверов...\033[0m"
    
    # Видео драйверы
    case "\${GPU_DRIVER}" in
        "intel")
            pacman -Sy --noconfirm xf86-video-intel vulkan-intel &>> "\${LOG_FILE}"
            ;;
        "amd")
            pacman -Sy --noconfirm xf86-video-amdgpu vulkan-radeon &>> "\${LOG_FILE}"
            ;;
        "nvidia")
            pacman -Sy --noconfirm nvidia nvidia-utils nvidia-settings &>> "\${LOG_FILE}"
            ;;
        "nvidia-open")
            pacman -Sy --noconfirm nvidia-open-dkms nvidia-utils nvidia-settings &>> "\${LOG_FILE}"
            ;;
        "vm")
            pacman -Sy --noconfirm xf86-video-qxl xf86-video-vmware virtualbox-guest-utils &>> "\${LOG_FILE}"
            ;;
    esac
    
    # Аудио драйверы
    case "\${AUDIO_DRIVER}" in
        "pulseaudio")
            pacman -Sy --noconfirm pulseaudio pulseaudio-alsa pavucontrol &>> "\${LOG_FILE}"
            ;;
        "pipewire")
            pacman -Sy --noconfirm pipewire pipewire-alsa pipewire-pulse wireplumber &>> "\${LOG_FILE}"
            ;;
    esac
    
    # Wi-Fi драйверы
    if [ "\${WIFI_DRIVERS}" = "yes" ]; then
        pacman -Sy --noconfirm wpa_supplicant wireless_tools netctl &>> "\${LOG_FILE}"
    fi
    
    # Bluetooth драйверы
    if [ "\${BLUETOOTH_DRIVERS}" = "yes" ]; then
        pacman -Sy --noconfirm bluez bluez-utils pulseaudio-bluetooth &>> "\${LOG_FILE}"
        systemctl enable bluetooth
    fi
}

# Установка дополнительных пакетов
install_extra_packages() {
    echo -e "\033[0;34m[*] Установка дополнительных пакетов...\033[0m"
    
    while read -r pkg_group; do
        case "\${pkg_group}" in
            "development")
                pacman -Sy --noconfirm base-devel git docker docker-compose nodejs npm python python-pip &>> "\${LOG_FILE}"
                systemctl enable docker
                ;;
            "multimedia")
                pacman -Sy --noconfirm ffmpeg vlc gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly &>> "\${LOG_FILE}"
                ;;
            "office")
                pacman -Sy --noconfirm libreoffice-fresh evince &>> "\${LOG_FILE}"
                ;;
            "games")
                pacman -Sy --noconfirm steam wine-staging lutris &>> "\${LOG_FILE}"
                ;;
        esac
    done < /tmp/vibeinstall/packages.cfg
    
    # Оболочка
    case "\${SHELL}" in
        "zsh")
            pacman -Sy --noconfirm zsh zsh-completions &>> "\${LOG_FILE}"
            chsh -s /bin/zsh "\${USERNAME}"
            ;;
        "fish")
            pacman -Sy --noconfirm fish &>> "\${LOG_FILE}"
            chsh -s /bin/fish "\${USERNAME}"
            ;;
    esac
}

# Настройка пользователя
setup_user() {
    echo -e "\033[0;34m[*] Настройка пользователя...\033[0m"
    
    # Создание пользователя
    useradd -m -G wheel -s "/bin/\${SHELL:-bash}" "\${USERNAME}"
    echo -e "\${USER_PASSWORD}\n\${USER_PASSWORD}" | passwd "\${USERNAME}"
    
    # Настройка AUR (yay)
    if [ "\${AUR_SUPPORT}" = "yes" ]; then
        echo -e "\033[0;34m[*] Установка yay (AUR helper)...\033[0m"
        pacman -Sy --noconfirm git base-devel &>> "\${LOG_FILE}"
        sudo -u "\${USERNAME}" git clone https://aur.archlinux.org/yay.git /tmp/yay &>> "\${LOG_FILE}"
        cd /tmp/yay
        sudo -u "\${USERNAME}" makepkg -si --noconfirm &>> "\${LOG_FILE}"
        cd
        rm -rf /tmp/yay
    fi
    
    # Настройка firewall
    case "\${FIREWALL}" in
        "ufw")
            pacman -Sy --noconfirm ufw &>> "\${LOG_FILE}"
            systemctl enable ufw
            ufw enable
            ;;
        "firewalld")
            pacman -Sy --noconfirm firewalld &>> "\${LOG_FILE}"
            systemctl enable firewalld
            systemctl start firewalld
            ;;
    esac
    
    # Настройка bluetooth
    if [ "\${BLUETOOTH}" = "yes" ]; then
        systemctl enable bluetooth
    fi
}

# Основной процесс установки
main() {
    configure_system
    install_bootloader
    
    if [ "\${DE}" != "none" ] && [ "\${DE}" != "console" ]; then
        install_de
    fi
    
    install_drivers
    
    if [ -f "/tmp/vibeinstall/packages.cfg" ]; then
        install_extra_packages
    fi
    
    setup_user
    
    echo -e "\033[0;32m[+] Установка завершена успешно!\033[0m"
    echo -e "\033[1;33mДля входа в систему перезагрузите компьютер.\033[0m"
    
    exit 0
}

main
EOF

    chmod +x /mnt/root/chroot_install.sh
}

# Запуск chroot скрипта
configure_system() {
    log "Запуск chroot скрипта"
    arch-chroot /mnt /root/chroot_install.sh
}

# Выход из инсталлятора
exit_installer() {
    echo -e "${YELLOW}Выход из VibeInstall...${NC}"
    exit 0
}

# Главная функция
main() {
    check_root
    init
    main_menu
}

# Запуск
main
