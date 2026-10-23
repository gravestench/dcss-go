-- A Gauntlet is one temporary, rootless floor assembled from a parent
-- DES and nested arenas. Save validation binds its map and return arch to
-- the selected parent before the player can resume inside it.
local branches = require("ids.branches")
local gauntlet = require("constants.gauntlet")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local saved = {}

-- A completed visit retires its floor. A save may therefore contain one
-- active Gauntlet floor, or none while the player is outside.
function saved.validate(all_levels)
    local found

    for _, level in ipairs(all_levels) do
        if level.branch_id == branches.BRANCH_GAUNTLET then
            if found then
                error("saved Gauntlet has multiple active floors")
            end

            found = level
        end
    end

    if not found then
        return
    end

    local definition = vaults.get(found.vault_id)
    local parent_recorded = false
    local nested_recorded = false
    local return_arches = 0

    for _, id in ipairs(found.vault_ids or {}) do
        parent_recorded = parent_recorded or id == found.vault_id
        nested_recorded = nested_recorded or id ~= found.vault_id
    end

    for _, row in ipairs(found.cells or {}) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_GAUNTLET then
                return_arches = return_arches + 1
            end
        end
    end

    if found.id ~= levels.id(branches.BRANCH_GAUNTLET, 1) or
        found.local_depth ~= 1 or #found.cells ~= 70 or
        #found.cells[1] ~= 80 or #found.stairs ~= 0 or
        found.initial_monsters ~= 0 or
        definition.family ~= gauntlet.DESTINATION_FAMILY or
        not parent_recorded or not nested_recorded or
        return_arches < 1 then
        error("saved Gauntlet has invalid layout, exit, or identity")
    end
end

return saved
