-- Bazaar is a rootless one-floor portal, so ordinary scheduled-branch
-- stair validation cannot describe it. Its saved floor must still name a
-- real effective source layout and retain an exit after terrain projection.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local bazaar = {}

-- Exactly one live Bazaar floor can exist; after exit its floor and shops
-- are retired. The player-visit validator checks the reciprocal pointer.
function bazaar.validate(saved_levels)
    local found

    for _, level in ipairs(saved_levels) do
        if level.branch_id == branches.BRANCH_BAZAAR then
            if found then
                error("saved Bazaar has multiple active floors")
            end

            found = level
        end
    end

    if not found then
        return
    end

    local definition = vaults.get(found.vault_id)
    local recorded = false
    local source_recorded = false
    local exits = 0

    for _, id in ipairs(found.vault_ids or {}) do
        recorded = recorded or id == found.vault_id
    end

    -- A saved market cannot simply rename its selected layout in both
    -- vault_ids and the visitor pointer. Its authored shop and exit
    -- records must still identify the map that generated this floor.
    for _, record in ipairs(found.vault_records or {}) do
        source_recorded = source_recorded or
            record.source_id == found.vault_id
    end

    for _, row in ipairs(found.cells or {}) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_BAZAAR then
                exits = exits + 1
            end
        end
    end

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_BAZAAR)

    if found.id ~= levels.id(branch.id, 1) or
        found.local_depth ~= 1 or #found.cells ~= 70 or
        #found.cells[1] ~= 80 or #found.stairs ~= 0 or
        found.initial_monsters ~= 0 or
        definition.family ~= "bazaar" or not recorded or
        not source_recorded or exits < 1 then
        error("saved Bazaar has invalid layout, exit, or identity")
    end
end

return bazaar
