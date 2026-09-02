#!/bin/sh
# Connect to the Sony WH-1000XM5 headphones over Bluetooth.

DEV="AC:80:0A:56:9A:72"
NAME="WH-1000XM5"

if ! bluetoothctl show | grep -q 'Powered: yes'; then
    bluetoothctl power on >/dev/null
    sleep 1
fi

if bluetoothctl info "$DEV" | grep -q 'Connected: yes'; then
    notify-send -a bluetooth "$NAME" "already connected"
    exit 0
fi

bluetoothctl connect "$DEV" >/dev/null 2>&1
if bluetoothctl info "$DEV" | grep -q 'Connected: yes'; then
    notify-send -a bluetooth "$NAME" "connected"
else
    notify-send -a bluetooth "$NAME" "connection failed — is the headset on and discoverable?"
    exit 1
fi
