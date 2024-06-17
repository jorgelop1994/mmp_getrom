#!/bin/bash

emulator_list="/mnt/SDCARD/App/GameHub/emulator_list.txt"

# Define base URLs and file extensions for each console
setup_console_info() {
    case "$1" in
        PS)
            SRC='https://archive.org/download/chd_psx_eur/CHD-PSX-EUR/ chd'
            ;;
        GB)
            SRC='https://archive.org/download/nointro.gb/ 7z'
            ;;
        GBC)
            SRC='https://archive.org/download/nointro.gbc-1/ 7z'
            ;;
        GBA)
            SRC='https://archive.org/download/nointro.gba/ 7z'
            ;;
        MD)
            SRC='https://archive.org/download/nointro.md/ 7z'
            ;;
        FC)
            SRC='https://archive.org/download/nointro.nes/ 7z'
            ;;
        SFC)
            SRC='https://archive.org/download/nointro.snes/ 7z'
            ;;
        NDS)
            SRC='https://archive.org/download/ni-n-ds-dp/ 7z'
            ;;
        COMMODORE)
            SRC='https://archive.org/download/NoIntro-commodore-64_202302/Commodore%20-%2064/ zip'
            ;;
        *)
            echo "Unknown console: $1"
            exit 1
            ;;
    esac
}
