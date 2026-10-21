-- Pandemonium has one live floor at a time. Its region storage ID changes
-- on transit, while the branch depth stays Pan:1. Validate that topology
-- against the saved session counter without regenerating any map or actor.
local branches = require("ids.branches")
local region = require("policy.generation.pan.region")

local pan_levels = {}

-- A missing active state cannot own an orphaned region. An active state must
-- point to exactly the region implied by its completed visit count.
function pan_levels.validate(levels, state)
    local active
    local count = 0

    for _, level in ipairs(levels) do
        if level.branch_id == branches.BRANCH_PANDEMONIUM then
            count = count + 1
            active = level
        end
    end

    if not state or not state.active_level_id or
        state.active_level_id == 0 then
        if count ~= 0 then
            error("saved Pan floor has no active region state")
        end

        return
    end

    if state.regions_seen < 1 or count ~= 1 or not active or
        active.id ~= state.active_level_id or
        active.id ~= region.level_id(state.regions_seen - 1) or
        active.local_depth ~= 1 or
        #active.cells ~= 70 or #active.cells[1] ~= 80 or
        #active.stairs ~= 0 or
        active.initial_monsters < 3 or
        active.initial_monsters > 24 then
        error("saved Pan region has invalid identity or geometry")
    end
end

return pan_levels
