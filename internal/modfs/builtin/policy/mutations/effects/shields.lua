-- Source: player.cc:player_shield_class. Values are the internal SH, twice
-- the displayed value.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local shields = {}

-- Preserve Bone Plates' first-rank base bonus before adding four shield units per later rank.
-- Example: Bone Plates level one gives eight shield units; zero levels give none.
function shields.bone_plates(level)
    if level == 0 then
        return 0
    end

    return level * 4 + 4
end

registry.add(mutations.MUT_LARGE_BONE_PLATES, {
    [capabilities.SHIELD_CLASS_BONUS] = shields.bone_plates,
})

return shields
