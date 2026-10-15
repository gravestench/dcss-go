local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local potions = {}

function potions.forbid(level)
    return level > 0 and 1 or 0
end

function potions.healing_penalty(level)
    return level
end

effects.add(mutations.MUT_NO_DRINK, {
    [capabilities.POTION_FORBIDDEN] = potions.forbid,
})

effects.add(mutations.MUT_NO_POTION_HEAL, {
    [capabilities.POTION_HEALING_PENALTY] = potions.healing_penalty,
})

return potions
