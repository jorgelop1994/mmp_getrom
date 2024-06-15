#!/bin/bash

log_file="/mnt/SDCARD/App/GameHub/logs/error_log.txt"

export PATH="$sysdir/bin:$PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$sysdir/lib:$sysdir/lib/parasyte"

decode_url() {
    url_encoded=$(cat)
    url_decoded=$(echo "$url_encoded" | sed -e 's/%20/ /g' -e 's/%21/!/g' \
                                           -e 's/%22/"/g' -e 's/%23/#/g' \
                                           -e 's/%24/\$/g' -e 's/%25/%/g' \
                                           -e 's/%26/\&/g' -e "s/%27/'/g" \
                                           -e 's/%28/(/g' -e 's/%29/)/g' \
                                           -e 's/%2A/*/g' -e 's/%2B/+/g' \
                                           -e 's/%2C/,/g' -e 's/%2D/-/g' \
                                           -e 's/%2E/./g' -e 's/%2F/\//g')
    echo "$url_decoded"
}

print_progress() {
    while kill -0 "$wget_pid" 2> /dev/null; do
        printf "."
        sleep 1
    done
}

log_error() {
    message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $message" >> "$log_file"
}

# Function to truncate text
truncate_text() {
    input_text="$1"
    max_length="40"
    
    # Calculate the length of the input text
    text_length=${#input_text}
    
    if [ "$text_length" -gt "$max_length" ]; then
        # If input_text is longer than max_length, truncate it and add ellipsis
        truncated_text="${input_text:0:33}..."
        last_chars_beginning=$((text_length - 15))
        last_chars="${input_text:$last_chars_beginning:15}"
        echo "$truncated_text$last_chars"
    else
        # If input_text is shorter than or equal to max_length, return it as is
        echo "$input_text"
    fi
    # If input_text is shorter than or equal to max_length, return it as is
    echo "$input_text"
}
