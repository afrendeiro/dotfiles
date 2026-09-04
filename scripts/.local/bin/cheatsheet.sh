#!/bin/sh
# SUPER+K — keybind cheatsheet. Lists all binds (SUPER combos first) in a
# noctalia dmenu popup; type to filter, Esc dismisses, selection is a
# no-op. Data comes from hyprctl binds -j using the description= option
# carried by each hl.bind() in the hyprland config.

list="$(hyprctl binds -j | jq -r '
  def keyname($k): { "period": ".", "Print": "PrtSc", "Minus": "-", "Plus": "+",
                     "mouse:272": "LMB", "mouse:273": "RMB" }[$k] // $k;
  [ .[] | select(.has_description)
    | select(.key != "" and (.key | test("mouse|code|switch:") | not))
    | (.modmask as $m
       | [ [((($m / 64) | floor) % 2), "SUPER"], [((($m / 4) | floor) % 2), "CTRL"],
           [((($m / 8) | floor) % 2), "ALT"],   [($m % 2), "SHIFT"] ]
       | map(select(.[0] == 1) | .[1]) | join("+")) as $mods
    | (if $mods == "" then keyname(.key) else $mods + "+" + keyname(.key) end) as $combo
    | (.description | if startswith("\u00b7 ") then { grp: "1", txt: .[2:] } else { grp: "0", txt: . } end) as $d
    | "\($d.grp)\t\($combo) \u2022 \($d.txt)" ]
  | sort_by(.[0:1] + .[1:])
  | .[]
')"

[ -n "$list" ] || exit 0
printf '%s\n' "$list" | sed 's/^[01]\t//' | noctalia dmenu -p "Keybindings" > /dev/null
