-- Theory of operation: a branch's source depth describes its eventual
-- topology, while the committed Lua content determines which floors this
-- engine can build now. A branch that requires an end layout opens its
-- last floor only when an effective explicit PLACE map is available.
local categories = require("constants.catalog")
local layouts = require("policy.generation.layouts.catalog")

local availability = {}

-- Check source branch depth and the effective modded layout catalog.
-- An authored end floor cannot silently fall back to an ordinary layout.
function availability.can_build(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)
    local needs_end_layout = branch.end_layout_required and
        depth == branch.depth

    return depth >= 1 and depth <= branch.depth and
        (not needs_end_layout or layouts.has_explicit(branch_id, depth)) and
        layouts.has_candidates(branch_id, depth)
end

-- A visible stair explains why its destination cannot be generated yet.
function availability.reason(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)

    if branch.end_layout_required and depth == branch.depth then
        return branch.abbreviation .. ":" .. depth ..
            " awaits its authored end layout."
    end

    return "This branch floor is unavailable in the Go port."
end

return availability
