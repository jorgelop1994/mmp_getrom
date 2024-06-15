#!/bin/bash
# This file goes to /.tmp_update/script

sysdir="/mnt/SDCARD/.tmp_update"
scriptdir="${sysdir}/script"
romsdir="/mnt/SDCARD/Roms"
workdir="/tmp"
page_prefix="${workdir}/mmpgetrom_full_page_"
rom_names_file="${workdir}/mmpgetrom_rom_names.txt"
orig_rom_names_file="${workdir}/mmpgetrom_orig_rom_names.txt"
emulator_list="/mnt/SDCARD/App/GameHub/emulator_list.txt"

source /mnt/SDCARD/App/GameHub/config/setup_console_info.sh
source /mnt/SDCARD/App/GameHub/functions.sh



rom_menu() {
    mode="$1"
    rom_name_ptrn="$2"
    while true; do
        clear
        echo "Working..."
        page="${page_prefix}${EMU}"
        base_url="${SRC%% *}"
        ext="${SRC##* }"

        if [ "$mode" = "search" ]; then
            clear
            printf "\e[?25h"  # Show cursor
            printf "(X): Show keyboard\n(Y): Keyboard position\n(A): Keypress\n(B): Toggle\n[L1]: Shift\n[R1]: Backspace\n[L2]: Left\n[R2]: Right\n/Se/: Tab\n/St/: Enter\n\n"
            readline -m "Search ${EMU} ROMs matching pattern: "
            rom_name_ptrn=$(cat /tmp/readline.txt)
            [ -z "$rom_name_ptrn" ] && return
        fi

        if [ ! -f "$page" ] || [ ! -s "$page" ]; then
            wget -q -O - "$base_url" | tee "$page" > /dev/null &
            wget_pid=$!
            clear
            echo "Downloading list of ${EMU} .${ext} ROM files from"
            echo "$base_url"
            print_progress
            if [ $? -ne 0 ]; then
                log_error "Failed to download ROM list from $base_url"
                continue
            fi
        fi

        rom_names=$(grep -oE 'href="[^\"]*\.'"${ext}"'"' "$page" | sed 's/href="//;s/"//' | \
                                    tee "$orig_rom_names_file" | decode_url | tee "$rom_names_file")

        [ -n "$rom_name_ptrn" ] && rom_names=$(grep "$rom_name_ptrn" "$rom_names_file")

        if [ -z "$rom_names" ]; then
            echo
            echo "'${rom_name_ptrn}' not found."
            mode="search"
            sleep 3
            continue
        fi

        # Truncate each ROM name
        truncated_rom_names=$(echo "$rom_names" | while read -r line; do
            truncate_text "$line"
        done)

        pick=$(echo -e "<Search>\n<Reload>\n<Back>\n<Exit>\n$truncated_rom_names\n\n" | \
               $scriptdir/shellect.sh -b "                    <Menu>: Exit        <A>: Select" -t "     [ ${EMU} roms matching '${rom_name_ptrn}' ] ")

        clear
        case "$pick" in
            "<Back>") return ;;
            "<Exit>") exit ;;
            "<Search>") mode="search" ;;
            "<Reload>") mode="search result"; rm -f "$page"; continue ;;
            *)
                rom_name=$(sed -n "$(grep -n "$pick" "$rom_names_file" | cut -d: -f1){p;q}" "$orig_rom_names_file")
                rom_dir="${romsdir}/${EMU}"
                echo "Downloading '$pick' to '$rom_dir'"
                echo
                if ! wget -O "$pick" -P "$rom_dir/" "${base_url}${rom_name}"; then
                    log_error "Download failed for ROM: $pick"
                fi
                sleep 3
                [ -f "$scriptdir/reset_list.sh" ] && "$scriptdir/reset_list.sh" "$romsdir/$EMU" > /dev/null 2>&1
                mode="search result"
                ;;
        esac
    done
}

emu_menu() {
    clear
    emus=$(cat "$emulator_list")
    pick=$(echo -e "$emus" | $scriptdir/shellect.sh -b "                    <Menu>: Exit        <A>: Select" -t "           [ Select Emulator ] ")
    [ "$pick" = "<Back>" ] && return
    EMU="$pick"
    setup_console_info "$EMU"
}

main_menu() {
    while true; do
        clear

        opt1="${SRC:+Browse ${EMU} .${SRC##* } ROMs at $(basename ${SRC%% *})}"
        opt2="${SRC:+Search ${EMU} .${SRC##* } ROM at $(basename  ${SRC%% *})}"
        opt3="${SRC:+Clear ${EMU} romdir cache}"
        opt4="Select ${SRC:+another }emulator"
        opt5="<Exit>"

        pick=$(echo -e "$opt1\n$opt2\n\n$opt3\n$opt4\n$opt5\n\n" | \
               $scriptdir/shellect.sh -b "                    <Menu>: Exit        <A>: Select" -t "              [ OPTIONS ] ")

        case "$pick" in
            "$opt1") rom_menu "browse" ;;
            "$opt2") rom_menu "search" ;;
            "$opt3")
                $scriptdir/reset_list.sh "$romsdir/$EMU"
                if [ $? -ne 0 ]; then
                    log_error "Failed to clear ROM directory cache for $EMU"
                else
                    echo "${EMU} romdir cache cleared."
                fi
                sleep 3
                ;;
            "$opt4") emu_menu ;;
            "$opt5") exit ;;
        esac
    done
}

EMU="$1"
[ "$EMU" = "PSX" ] && EMU="PS"

main_menu
