--!nonstrict
-- /proj — launcher provider for projects under ~/work and ~/projects.
-- MRU (~/.local/state/open-project-mru, shared with the old open-project
-- script) sorts to the top; the rest are alphabetical. Activating a row
-- opens kitty and nautilus in the project directory and updates the MRU.

local WORK = noctalia.expandPath("~/work")
local PROJECTS = noctalia.expandPath("~/projects")
local MRU = noctalia.expandPath("~/.local/state/open-project-mru")
local MRU_LIMIT = 10

local roots = { { root = "work", path = WORK }, { root = "projects", path = PROJECTS } }

local function isDir(path)
    local info = noctalia.fileInfo(path)
    return info ~= nil and info.isDir
end

local function collect()
    local mru = {}
    local raw = noctalia.readFile(MRU)
    if raw then
        for line in raw:gmatch("[^\n]+") do mru[#mru + 1] = line end
    end
    local seen, entries = {}, {}
    for _, entry in ipairs(mru) do
        if isDir(noctalia.expandPath("~/" .. entry)) and not seen[entry] then
            seen[entry] = true
            entries[#entries + 1] = entry
        end
    end
    for _, r in ipairs(roots) do
        local names = noctalia.listDir(r.path)
        if names then
            table.sort(names)
            for _, name in ipairs(names) do
                local rel = r.root .. "/" .. name
                if isDir(r.path .. "/" .. name) and not seen[rel] then
                    seen[rel] = true
                    entries[#entries + 1] = rel
                end
            end
        end
    end
    return entries
end

local lastEntries = {}

function onQuery(text)
    local q = text:gsub("^%s+", ""):gsub("%s+$", "")
    local entries = collect()
    local out, idx = {}, 0
    if q == "" then
        for _, e in ipairs(entries) do
            idx = idx + 1
            out[#out + 1] = { id = "proj:" .. e, title = e:match("^[^/]+/(.+)$"), subtitle = e, glyph = "folder-open", score = 1e9 - idx }
        end
    else
        local scored = {}
        for _, e in ipairs(entries) do
            local s = noctalia.fuzzyScore(q, e)
            if s then scored[#scored + 1] = { e = e, s = s } end
        end
        table.sort(scored, function(a, b) return a.s > b.s end)
        for _, item in ipairs(scored) do
            idx = idx + 1
            local e = item.e
            out[#out + 1] = { id = "proj:" .. e, title = e:match("^[^/]+/(.+)$"), subtitle = e, glyph = "folder-open", score = 1e9 - idx }
        end
    end
    lastEntries = {}
    for _, r in ipairs(out) do lastEntries[r.id] = r end
    launcher.setResults(text, out)
end

local function updateMru(rel)
    local raw = noctalia.readFile(MRU) or ""
    local lines = {}
    for line in raw:gmatch("[^\n]+") do
        if line ~= rel then lines[#lines + 1] = line end
    end
    table.insert(lines, 1, rel)
    local keep = {}
    for i = 1, math.min(#lines, MRU_LIMIT) do keep[i] = lines[i] end
    noctalia.writeFile(MRU, table.concat(keep, "\n") .. "\n")
end

function onActivate(id)
    local rel = id:match("^proj:(.+)$")
    if not rel then return end
    local path = noctalia.expandPath("~/" .. rel)
    if not isDir(path) then return end
    updateMru(rel)
    noctalia.runAsync({ "kitty", "-d", path })
    noctalia.runAsync({ "nautilus", path })
end
