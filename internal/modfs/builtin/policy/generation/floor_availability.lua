-- Theory of operation: a branch's source depth describes its eventual
-- topology, while the committed Lua content determines which floors this
-- engine can build now. A branch that requires an end layout opens its
-- last floor only when an effective explicit PLACE map is available.
local categories = require("constants.catalog")
local layouts = require("policy.generation.layouts.catalog")
local end_vault = require("policy.generation.vaults.end")

local availability = {}

-- Check source branch depth and the effective modded layout catalog.
-- An authored end floor cannot silently fall back to an ordinary layout.
function availability.can_build(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)

    if depth < 1 or depth > branch.depth or
        not layouts.has_candidates(branch_id, depth) then
        return false
    end

    if depth ~= branch.depth then
        return true
    end

    if branch.end_layout_required and
        not layouts.has_explicit(branch_id, depth) then
        return false
    end

    if branch.end_vault_required then
        local context = {
            branch_id = branch_id,
            depth = depth,
            branch_bottom = branch.depth,
            absolute_depth = branch.absolute_depth + depth - 1,
            end_vault_family = branch.end_vault_family,
        }

        return #end_vault.candidates(context) > 0
    end

    return true
end

-- A visible stair explains why its destination cannot be generated yet.
function availability.reason(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)

    if branch.end_vault_required and depth == branch.depth then
        return branch.abbreviation .. ":" .. depth ..
            " awaits its authored end vault."
    end

    if branch.end_layout_required and depth == branch.depth then
        return branch.abbreviation .. ":" .. depth ..
            " awaits its authored end layout."
    end

    return "This branch floor is unavailable in the Go port."
end

return availability
