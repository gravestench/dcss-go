-- Source: player.cc:player_shield_class. Values are the internal SH, twice
-- the displayed value.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local shields = {}

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
