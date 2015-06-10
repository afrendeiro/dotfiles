#!/bin/bash

if [ -f ~/.profile ]; then
    source ~/.profile
fi

if [ -f ~/.bashrc_local ]; then
    source ~/.bashrc_local
fi
