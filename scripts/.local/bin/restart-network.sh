#!/usr/bin/env bash

echo "Restarting network services..."

sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved

echo "Network services restarted."

