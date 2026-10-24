-- An active Duel owns at most one rootless Arena level. Its saved terrain
-- must still come from one installed DES map with a live return arch.
local branches = require("ids.branches")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local saved = {}

-- The visit component is checked separately against the player's position;
-- this pass verifies only the generated floor's branch and map identity.
function saved.validate(all_levels)
    local found

    for _, level in ipairs(all_levels) do
        if level.branch_id == branches.BRANCH_ARENA then
            if found then
                error("saved Arena has multiple active floors")
            end

            found = level
        end
    end

    if not found then
        return
    end

    local definition = vaults.get(found.vault_id)
    local exits = 0

    for _, row in ipairs(found.cells or {}) do
        for _, feature in ipairs(row) do
            if feature == terrain.DNGN_EXIT_ARENA then
                exits = exits + 1
            end
        end
    end

    if found.id ~= levels.id(branches.BRANCH_ARENA, 1) or
        found.local_depth ~= 1 or #found.cells ~= 70 or
        #found.cells[1] ~= 80 or #found.stairs ~= 0 or
        found.initial_monsters ~= 0 or
        definition.family ~= "arena" or exits ~= 1 then
        error("saved Arena has invalid map or exit")
    end
end

return saved
