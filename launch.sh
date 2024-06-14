#!/bin/sh
# Path to the script directory
scriptdir=/mnt/SDCARD/App/GameHub

# Ensure the device stays awake
touch /tmp/stay_awake

# Clear the screen and change directory
clear
cd $scriptdir

# Execute the main script
st -q -e sh $scriptdir/script.sh

# Cleanup the stay_awake file
rm /tmp/stay_awake
