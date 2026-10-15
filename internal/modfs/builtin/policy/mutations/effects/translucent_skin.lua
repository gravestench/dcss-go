local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local translucent_skin = {}

function translucent_skin.hit_modifier(level)
    -- attack.h: TRANSLUCENT_SKIN_TO_HIT_MALUS is -2 per level.
    return -2 * level
end

function translucent_skin.stealth(level)
    return level > 0 and 50 or 0
end

registry.add(mutations.MUT_TRANSLUCENT_SKIN, {
    [capabilities.VISIBLE_DEFENDER_HIT_MODIFIER] =
        translucent_skin.hit_modifier,
    [capabilities.STEALTH_BONUS] = translucent_skin.stealth,
})

return translucent_skin
