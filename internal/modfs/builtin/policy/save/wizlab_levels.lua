-- An Wizard Lab is a rootless, temporary one-floor branch. Ordinary scheduled
-- stair validation does not describe it, so this owner checks its saved
-- source map, whole-floor shape, and at least one usable return exit.
local branches = require("ids.branches")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local wizlab = {}

-- Only one active Wizard Lab visit can exist. An exited floor is retired by
-- the generic portal transaction and should not appear in the save.
function wizlab.validate(saved_levels)
    local found

    for _, level in ipairs(saved_levels) do
        if level.branch_id == branches.BRANCH_WIZLAB then
            if found then
                error("saved Wizard Lab has multiple active floors")
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

    -- The retained source records bind the saved map to its selected DES
    -- layout. A renamed vault_id alone cannot make another floor valid.
    for _, record in ipairs(found.vault_records or {}) do
        source_recorded = source_recorded or
            record.source_id == found.vault_id
    end

    for _, row in ipairs(found.cells or {}) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_WIZLAB then
                exits = exits + 1
            end
        end
    end

    if found.id ~= levels.id(branches.BRANCH_WIZLAB, 1) or
        found.local_depth ~= 1 or #found.cells ~= 70 or
        #found.cells[1] ~= 80 or #found.stairs ~= 0 or
        found.initial_monsters ~= 0 or
        definition.family ~= "wizlab" or not recorded or
        not source_recorded or exits < 1 then
        error("saved Wizard Lab has invalid layout, exit, or identity")
    end
end

return wizlab
