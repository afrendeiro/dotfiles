#!/usr/bin/env bash

# Cache sudo credentials upfront so the prompt does not block the stdin pipe
sudo -v

# Retrieve the password from pass and pipe it directly to openconnect
pass show keypass2_database/MUW@VPN | head -n 1 | sudo openconnect \
  --background \
  --passwd-on-stdin \
  -u arende59 \
  --authgroup="_CeMM_exkl.Journale" \
  vpn.meduniwien.ac.at
