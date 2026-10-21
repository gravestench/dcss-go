-- Theory of operation: a branch's source depth describes its eventual
-- topology, while committed Lua content determines which floors this
-- engine can build now. A branch floor that declares an authored primary
-- opens only when its effective PLACE family has a selectable candidate.
local categories = require("constants.catalog")
local branches = require("ids.branches")
local layouts = require("policy.generation.layouts.catalog")
local primary = require("policy.generation.vaults.primary")
local temple = require("policy.generation.temple.catalog")

local availability = {}

-- Check source branch depth and the effective modded layout catalog.
-- An authored end floor cannot silently fall back to an ordinary layout.
function availability.can_build(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)

    -- Temple uses its own effective source MAP catalog rather than a
    -- general layout. Its scheduled entrance was already source-authored;
    -- the destination must pass this same availability gate on first use.
    if branch_id == branches.BRANCH_TEMPLE then
        return depth == 1 and #temple.main_ids() > 0
    end

    if depth < 1 or depth > branch.depth or
        not layouts.has_candidates(branch_id, depth) then
        return false
    end

    if depth == branch.depth and branch.end_layout_required and
        not layouts.has_explicit(branch_id, depth) then
        return false
    end

    local specification = primary.specification(branch, depth)

    if specification then
        local context = {
            branch_id = branch_id,
            depth = depth,
            branch_bottom = branch.depth,
            absolute_depth = branch.absolute_depth + depth - 1,
            primary_vault_family = specification.family,
            primary_allow_dummy = specification.allow_dummy,
        }

        return #primary.candidates(context) > 0
    end

    return true
end

-- A visible stair explains why its destination cannot be generated yet.
function availability.reason(branch_id, depth)
    local branch = register.get(categories.BRANCHES, branch_id)

    if primary.specification(branch, depth) then
        return branch.abbreviation .. ":" .. depth ..
            " awaits its authored primary vault."
    end

    if branch.end_layout_required and depth == branch.depth then
        return branch.abbreviation .. ":" .. depth ..
            " awaits its authored end layout."
    end

    return "This branch floor is unavailable in the Go port."
end

return availability
