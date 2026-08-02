#!/bin/sh
if [ "$(nmcli radio wifi)" = "enabled" ]; then
    nmcli radio wifi off
    echo 'wifi off'
else
    nmcli radio wifi on
    echo 'wifi on'
fi
