#!/bin/sh
if [ "$(bluetoothctl show | grep Powered | awk '{print $2}')" = "yes" ]; then
    bluetoothctl power off
    echo 'bluetooth off'
else
    bluetoothctl power on
    echo 'bluetooth on'
fi
