-- Mossy Skin contributes five flat HP per level through a modded mutation capability.
-- Example: level two supplies 10 extra maximum HP through HP_FLAT.

local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local mossy_skin = {}

-- Scale flat HP by the modded mutation level, proving the registry passes
-- effective levels to a Lua-defined capability handler.
function mossy_skin.flat_hp(level)
    return level * 5
end

registry.add(mutations.MUT_MOSSY_SKIN, {
    [capabilities.HP_FLAT] = mossy_skin.flat_hp,
})

return mossy_skin
