local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local mossy_skin = {}

function mossy_skin.flat_hp(level)
    return level * 5
end

registry.add(mutations.MUT_MOSSY_SKIN, {
    [capabilities.HP_FLAT] = mossy_skin.flat_hp,
})

return mossy_skin
