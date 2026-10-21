-- Theory of operation: a branch's source depth describes its eventual
-- topology, while the committed Lua content determines which floors this
-- engine can build now. Vaults:5 needs its separate end-vault owner; the
-- ordinary primary layouts are for Vaults:1-4. Keeping this gate in Lua
-- lets a content slice open the final floor without a Go branch switch.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local layouts = require("policy.generation.layouts.catalog")

local availability = {}

local current_limit = {
    [branches.BRANCH_VAULTS] = 4,
}

-- Check both the current slice boundary and the effective modded layout
-- catalog. Removing every candidate closes a floor even below the limit.
function availability.can_build(branch_id, depth)
    local limit = current_limit[branch_id]
    local branch = register.get(categories.BRANCHES, branch_id)

    return depth >= 1 and depth <= branch.depth and
        (not limit or depth <= limit) and
        layouts.has_candidates(branch_id, depth)
end

-- A visible stair explains why its destination cannot be generated yet.
function availability.reason(branch_id, depth)
    if branch_id == branches.BRANCH_VAULTS and depth == 5 then
        return "Vaults:5 awaits its end vault in the Go port."
    end

    return "This branch floor is unavailable in the Go port."
end

return availability
