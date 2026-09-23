-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Ten persistent workspaces on the primary monitor, so they always exist.
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR })
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = PRIMARY_MONITOR, default = true, persistent = true })
end

-- When a monitor is disabled/removed (lid close, dock unplug), Hyprland parks
-- that monitor's active workspace on the dead output; `workspace N` can't reach
-- a parked/detached workspace, so the SUPER+[0-9] binds silently stop working
-- for it (observed as dead SUPER+2 / SUPER+7). Re-home any workspace that is
-- not sitting on a live monitor shortly after a layout change; also heal
-- immediately on reload in case an event was missed. Only misplaced workspaces
-- are touched — ones on a live monitor are never moved.
local function rehome_misplaced_workspaces()
    local live, target = {}, hl.get_active_monitor()
    if target == nil then
        return
    end
    for _, m in ipairs(hl.get_monitors()) do
        live[m.name] = true
    end
    for _, ws in ipairs(hl.get_workspaces()) do
        local m = ws.monitor
        local misplaced = m == nil or (m.name ~= nil and not live[m.name])
        if misplaced and not ws.special then
            hl.dispatch(hl.dsp.workspace.move({ workspace = ws.id, monitor = target.name }))
        end
    end
end

-- The local must exist before the timer: a local is not in scope inside its
-- own initializer.
local sweep_timer
sweep_timer = hl.timer(function()
    rehome_misplaced_workspaces()
    sweep_timer:set_enabled(false)
end, { timeout = 300, type = "repeat" })
sweep_timer:set_enabled(false)
hl.on("monitor.removed", function() sweep_timer:set_enabled(true) end)
hl.on("monitor.layout_changed", function() sweep_timer:set_enabled(true) end)
hl.on("config.reloaded", function() rehome_misplaced_workspaces() end)
