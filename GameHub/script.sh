#!/bin/sh
# This file goes to /.tmp_update/script

sysdir="/mnt/SDCARD/.tmp_update"
echo_cmd="echo -e"
scriptdir="${sysdir}/script"
romsdir="/mnt/SDCARD/Roms"
workdir="/tmp"
page_prefix="${workdir}/mmpgetrom_full_page_"
rom_names_file="${workdir}/mmpgetrom_rom_names.txt"
orig_rom_names_file="${workdir}/mmpgetrom_orig_rom_names.txt"
bline="                    <Menu>: Exit        <A>: Select"

PS_EUR_SOURCE='https://archive.org/download/chd_psx_eur/CHD-PSX-EUR/   chd'
PS_USA_SOURCE='https://archive.org/download/chd_psx/CHD-PSX-USA/       chd'
GB_SOURCE='https://archive.org/download/nointro.gb/                    7z'
GBC_SOURCE='https://archive.org/download/nointro.gbc-1/                7z'
GBA_SOURCE='https://archive.org/download/nointro.gba/                  7z'
MD_SOURCE='https://archive.org/download/nointro.md/                    7z'
FC_SOURCE='https://archive.org/download/nointro.nes/                   7z'
SFC_SOURCE='https://archive.org/download/nointro.snes/                 7z'

export PATH="$sysdir/bin:$PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

decode_url() {
    local url_encoded
    url_encoded=$(cat)
    url_decoded=$(echo "$url_encoded" | sed -e 's/%20/ /g' -e 's/%21/!/g' -e 's/%22/"/g' \
                                           -e 's/%23/#/g' -e 's/%24/\$/g' -e 's/%25/%/g' \
                                           -e 's/%26/\&/g' -e "s/%27/'/g" -e 's/%28/(/g' \
                                           -e 's/%29/)/g' -e 's/%2A/*/g' -e 's/%2B/+/g' \
                                           -e 's/%2C/,/g' -e 's/%2D/-/g' -e 's/%2E/./g' \
                                           -e 's/%2F/\//g')
    echo "$url_decoded"
}

print_progress() {
    while kill -0 "$wget_pid" 2> /dev/null; do
        echo -n "."
        sleep 1
    done
}

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
            echo -ne "\e[?25h"  # Show cursor
            $echo_cmd "(X): Show keyboard\n(Y): Keyboard position\n(A): Keypress\n(B): Toggle\n[L1]: Shift\n[R1]: Backspace\n[L2]: Left\n[R2]: Right\n/Se/: Tab\n/St/: Enter\n\n"
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
        fi

        rom_names=$(cat "$page" | grep -oE 'href="[^\"]*\.'${ext}'"' | sed 's/href="//;s/"//' | \
                    tee "$orig_rom_names_file" | decode_url | tee "$rom_names_file")

        [ -n "$rom_name_ptrn" ] && rom_names=$(grep "$rom_name_ptrn" "$rom_names_file")

        if [ -z "$rom_names" ]; then
            echo
            echo "'${rom_name_ptrn}' not found."
            mode="search"
            sleep 3
            continue
        fi

        pick=$(echo -e "<Search>\n<Reload>\n<Back>\n<Exit>\n$rom_names\n\n" | \
               $scriptdir/shellect.sh -b "$bline" -t "     [ ${EMU} roms matching '${rom_name_ptrn}' ] ")

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
                    echo "Download failed."
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
    emus="<Back>\nPS\nGB\nGBC\nGBA\nFC\nSFC\nMD\n\n"
    pick=$(echo -e "$emus" | $scriptdir/shellect.sh -b "$bline" -t "           [ Select Emulator ] ")
    [ "$pick" = "<Back>" ] && return
    EMU="$pick"
}

main_menu() {
    while true; do
        clear
        case "$EMU" in
            "PS") SRC="$PS_EUR_SOURCE" ;;
            "GB") SRC="$GB_SOURCE" ;;
            "GBC") SRC="$GBC_SOURCE" ;;
            "GBA") SRC="$GBA_SOURCE" ;;
            "MD") SRC="$MD_SOURCE" ;;
            "FC") SRC="$FC_SOURCE" ;;
            "SFC") SRC="$SFC_SOURCE" ;;
        esac

        opt1="${SRC:+Browse ${EMU} .${SRC##* } ROMs at $(basename ${SRC%% *})}"
        opt2="${SRC:+Search ${EMU} .${SRC##* } ROM at $(basename  ${SRC%% *})}"
        opt3="${SRC:+Clear ${EMU} romdir cache}"
        opt4="Select ${SRC:+another }emulator"
        opt5="<Exit>"

        pick=$(echo -e "$opt1\n$opt2\n\n$opt3\n$opt4\n$opt5\n\n" | \
               $scriptdir/shellect.sh -b "$bline" -t "              [ OPTIONS ] ")

        case "$pick" in
            "$opt1") rom_menu "browse" ;;
            "$opt2") rom_menu "search" ;;
            "$opt3")
                $scriptdir/reset_list.sh "$romsdir/$EMU"
                echo "${EMU} romdir cache cleared."
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
