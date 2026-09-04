#!/usr/bin/env python3
"""Resolve the Hyprland lua binds into launcher-ready JSON rows.

Parses variables.lua + binds.lua (~/.config/hypr/config/), expanding the
workspace loops and resolving const concat chains, so each row carries
{combo, group, desc, cmd}: cmd is the resolved exec_cmd payload when the
bind runs a command, else null. Used by the noctalia launcher-tools /keys
provider. Output: one JSON array on stdout, sorted by group order + combo.
"""
import json
import re
import sys

CONF = "/home/afr/.config/hypr/config"
GROUP_ORDER = ["Apps", "Toggles", "Panels", "Capture", "Snapshots",
               "System", "Navigate", "Workspaces", "Media"]
KEY_ALIAS = {"period": ".", "Print": "PrtSc", "Minus": "-", "Plus": "+"}


def parse_consts(path):
    consts = {}
    for line in open(path):
        m = re.match(r"\s*([A-Za-z_]\w*)\s*=\s*(\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*')", line)
        if m:
            consts[m.group(1)] = m.group(2)[1:-1]
    return consts


def resolve(expr, consts):
    """Evaluate a lua string concat chain ('a' .. B .. "c") into one string."""
    out = []
    for tok in re.split(r"\s*\.\.\s*", expr.strip()):
        if len(tok) >= 2 and tok[0] in "\"'" and tok[-1] == tok[0]:
            out.append(tok[1:-1])
        elif tok in consts:
            out.append(consts[tok])
        else:
            out.append(tok)
    return "".join(out)


def split_args(s):
    """Split the paren body of hl.bind(...) on top-level commas (quote/paren aware)."""
    args, depth, cur, quote = [], 0, "", None
    for ch in s:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            cur += ch
        elif ch == "(":
            depth += 1
            cur += ch
        elif ch == ")":
            depth -= 1
            cur += ch
        elif ch == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args


def desc_info(opts):
    m = re.search(r'description\s*=\s*"([^"]+)"', opts)
    if not m:
        return None
    desc = m.group(1)
    gm = re.match(r"^\[([A-Za-z]+)\]\s*(.*)$", desc)
    return gm.group(1) if gm else "Other", gm.group(2) if gm else desc


def main():
    consts = parse_consts(f"{CONF}/variables.lua")
    body_lines = open(f"{CONF}/binds.lua").read().splitlines()
    for raw in body_lines:
        lc = re.match(r"local\s+([A-Za-z_]\w*)\s*=\s*(\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*')", raw)
        if lc:
            consts[lc.group(1)] = lc.group(2)[1:-1]
    num_wpm = int(consts.get("NUM_WPM", "10"))
    body = body_lines
    rows = []
    in_loop = False
    for raw in body:
        line = raw.strip()
        if line.startswith("for i = 1"):
            in_loop = True
            continue
        if line == "end" and in_loop:
            in_loop = False
            continue
        m = re.match(r"hl\.bind\((.*)\)$", line, re.S)
        if not m:
            continue
        args = split_args(m.group(1))
        if len(args) < 2:
            continue
        keyexpr, disp, opts = args[0], args[1], args[2] if len(args) > 2 else ""
        di = desc_info(opts)
        if not di:
            continue
        group, text = di
        if "switch:" in keyexpr or "mouse" in keyexpr or "code:" in keyexpr:
            continue
        is_loop = in_loop and ("key" in keyexpr or "i" in disp)
        loop_iter = range(1, num_wpm + 1) if is_loop else [None]
        for i in loop_iter:
            if i is None:
                keyex, dispex, txt = keyexpr, disp, text
            else:
                k = i % 10
                keyex = re.sub(r"\s*\.\.\s*key\s*$", f' .. "{k}"', keyexpr)
                dispex = re.sub(r"tostring\(i\)", f'"{i}"', disp)
                dispex = re.sub(r'"m~"\s*\.\.\s*i', f'"m~{i}"', dispex)
                txt = text.replace(" N", f" {i}")
            combo = resolve(keyex, consts).replace("mainMod", "SUPER").replace("  ", " ")
            combo = combo.replace(" + ", "+")
            combo = KEY_ALIAS.get(combo, combo)
            if "mouse" in combo or "code" in combo:
                continue
            cmd = None
            cm = re.search(r"exec_cmd\((.*)\)$", dispex.strip())
            if cm:
                cmd = resolve(cm.group(1), consts)
            rows.append({"combo": combo, "group": group, "desc": txt, "cmd": cmd})
    rows.sort(key=lambda r: (GROUP_ORDER.index(r["group"]) if r["group"] in GROUP_ORDER else 99, r["combo"]))
    json.dump(rows, sys.stdout)


if __name__ == "__main__":
    main()
