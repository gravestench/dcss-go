local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local regeneration = {}

function regeneration.hp_bonus(level)
    -- player.h:REGEN_PIP and player.cc:_player_bonus_regen.
    return level * 80
end

function regeneration.mp_double(level)
    return level > 0 and 1 or 0
end

function regeneration.forbidden(level)
    return level > 0 and 1 or 0
end

function regeneration.inhibited(level)
    return level > 0 and 1 or 0
end

registry.add(mutations.MUT_REGENERATION, {
    [capabilities.HP_REGEN_BONUS] = regeneration.hp_bonus,
})

registry.add(mutations.MUT_MANA_REGENERATION, {
    [capabilities.MP_REGEN_DOUBLE] = regeneration.mp_double,
})

registry.add(mutations.MUT_NO_REGENERATION, {
    [capabilities.HP_REGEN_FORBIDDEN] = regeneration.forbidden,
})

registry.add(mutations.MUT_INHIBITED_REGENERATION, {
    [capabilities.HP_REGEN_INHIBITED] = regeneration.inhibited,
})

return regeneration
