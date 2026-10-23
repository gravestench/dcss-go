-- Volcano is a temporary rootless floor. Its authored whole-map DES and
-- live return exit must agree with the saved branch identity.
local branches = require("ids.branches")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local volcano = {}

-- An exited portal is retired, so at most one Volcano floor may be saved.
function volcano.validate(saved_levels)
    local found

    for _, level in ipairs(saved_levels) do
        if level.branch_id == branches.BRANCH_VOLCANO then
            if found then
                error("saved Volcano has multiple active floors")
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

    for _, record in ipairs(found.vault_records or {}) do
        source_recorded = source_recorded or
            record.source_id == found.vault_id
    end

    for _, row in ipairs(found.cells or {}) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_VOLCANO then
                exits = exits + 1
            end
        end
    end

    if found.id ~= levels.id(branches.BRANCH_VOLCANO, 1) or
        found.local_depth ~= 1 or #found.cells ~= 70 or
        #found.cells[1] ~= 80 or #found.stairs ~= 0 or
        found.initial_monsters ~= 0 or
        definition.family ~= "volcano" or not recorded or
        not source_recorded or exits < 1 then
        error("saved Volcano has invalid layout, exit, or identity")
    end
end

return volcano
