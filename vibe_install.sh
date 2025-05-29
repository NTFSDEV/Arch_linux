#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

echo "Disks."
lsblk
read -p "Какой диск у вас" disk

if [ -z "$disk" ]; then
    echo -e "${RED}Ошибка: Не указан диск!${NC}"
    exit 1
fi

if [[ "$disk" == *[0-9] ]]; then
    echo -e "${RED}Ошибка: Укажите диск (например, sda), а не раздел (sda1)!${NC}"
    exit 1
fi


echo -e "${YELLOW}Создаю GPT-таблицу и раздел на /dev/$disk...${NC}"
(
    echo g      # Создать GPT (если нет)
    echo n      # Новый раздел
    echo 1      # Номер раздела (1)
    echo        # Первый сектор (по умолчанию)
    echo +550M      # Последний сектор (весь диск)
    echo n
    echo 2
    echo 
    echo +2G
    echo n 
    echo 3
    echo 
    echo 
    echo t
    echo 1
    echo 1
    echo t 
    echo 2
    echo 19
    


) | sudo fdisk "/dev/$disk"
