--!nonstrict
-- /keys — launcher provider for Hyprland keybindings.
--
-- Rows come from ~/.local/bin/keys-data.py, which resolves binds.lua +
-- variables.lua into {combo, group, desc, cmd} rows and writes them to
-- ~/.local/state/noctalia-keys.json. This provider reads that file
-- synchronously (no subprocess callbacks) and refreshes it in the
-- background when stale. An empty query shows the nine groups (drill-in
-- with g:<Group> query rewrites); typing matches fuzzy over combo +
-- description. Activating an executable row runs its command; window-op
-- rows (no cmd) copy the combo to the clipboard.

local GENERATOR = "/home/afr/.local/bin/keys-data.py"
local CACHE = "/home/afr/.local/state/noctalia-keys.json"
local TTL_MS = 5000

local GROUPS = {
    { name = "Apps", glyph = "apps" },
    { name = "Toggles", glyph = "toggle-left" },
    { name = "Panels", glyph = "layout-grid" },
    { name = "Capture", glyph = "camera" },
    { name = "Snapshots", glyph = "history" },
    { name = "System", glyph = "settings" },
    { name = "Navigate", glyph = "arrows-move" },
    { name = "Workspaces", glyph = "layout-dashboard" },
    { name = "Media", glyph = "player-play" },
}
local GROUPS_GLYPH = {}
for _, g in ipairs(GROUPS) do GROUPS_GLYPH[g.name] = g.glyph end

local rows = {}
local lastRows = {}
local refreshing = false

local function refresh()
    if refreshing then
        return
    end
    refreshing = true
    noctalia.runAsync(GENERATOR)
end

local function readRows()
    local raw = noctalia.readFile(CACHE)
    if raw == nil then
        return {}
    end
    local data, err = noctalia.json.decode(raw)
    if data == nil or type(data) ~= "table" then
        noctalia.log("keys: decode failed: " .. tostring(err))
        return {}
    end
    return data
end

local function resultOf(score, id, title, subtitle, glyph)
    return { id = id, title = title, subtitle = subtitle, glyph = glyph, score = score }
end

-- Normalize the query text: keystrokes arrive with the "/keys" prefix
-- stripped ("wifi"), while setQuery() reruns deliver the raw input
-- ("/keys wifi"). setQuery() takes POST-prefix text and prepends the
-- provider prefix itself (" " renders as "/keys "). Accept both forms.
local function normalize(text)
    local t = text:sub(1, 5) == "/keys" and text:sub(6) or text
    return t:gsub("^%s+", ""):gsub("%s+$", "")
end

function onQuery(text)
    if text == "" then
        launcher.setQuery(" ")
        return
    end
    local q = normalize(text)
    local groupFilter = q:match("^g:([A-Za-z]+)")
    if groupFilter then
        q = q:sub(3 + #groupFilter):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local info = noctalia.fileInfo(CACHE)
    if info == nil or info.mtime * 1000 < noctalia.nowMs() - TTL_MS then
        refresh()
    end
    if info == nil then
        launcher.setResults(text, {})
        return
    end
    rows = readRows()

    if groupFilter == nil and q == "" then
        local out = {}
        for i, g in ipairs(GROUPS) do
            local n = 0
            for _, r in ipairs(rows) do
                if r.group == g.name then n = n + 1 end
            end
            if n > 0 then
                table.insert(out, resultOf(#GROUPS - i, "grp:" .. g.name, g.name,
                    n .. " keybind" .. (n == 1 and "" or "s"), g.glyph))
            end
        end
        table.insert(out, resultOf(-1, "grp:__all", "All keybindings", #rows .. " total", "keyboard"))
        lastRows = {}
        launcher.setResults(text, out)
        return
    end

    local pool = {}
    for _, r in ipairs(rows) do
        if groupFilter == nil or r.group == groupFilter then pool[#pool + 1] = r end
    end
    if q ~= "" then
        local scored = {}
        for _, r in ipairs(pool) do
            local s = noctalia.fuzzyScore(q, r.combo) or -1
            s = math.max(s, noctalia.fuzzyScore(q, r.desc) or -1)
            if s >= 0 then scored[#scored + 1] = { row = r, s = s } end
        end
        table.sort(scored, function(a, b) return a.s > b.s end)
        pool = {}
        for _, e in ipairs(scored) do pool[#pool + 1] = e.row end
    end

    local out = {}
    if groupFilter then
        out[#out + 1] = resultOf(1e9, "grp:__all", "All keybindings", nil, "keyboard")
    end
    for i, r in ipairs(pool) do
        out[#out + 1] = resultOf(1e9 - i, "row:" .. i, r.desc, r.combo,
            GROUPS_GLYPH[r.group] or "keyboard")
    end
    lastRows = {}
    for i, r in ipairs(pool) do lastRows["row:" .. i] = r end
    launcher.setResults(text, out)
end

function onActivate(id)
    if id == "grp:__all" then
        launcher.setQuery(" ")
        return
    end
    local g = id:match("^grp:(.+)$")
    if g then
        launcher.setQuery("g:" .. g .. " ")
        return
    end
    local row = lastRows[id]
    if not row then return end
    if row.cmd and row.cmd ~= "" then
        noctalia.runAsync(row.cmd)
    else
        noctalia.copyToClipboard(row.combo, "text/plain")
        noctalia.notify("Not executable", row.combo .. " copied to clipboard")
    end
end
