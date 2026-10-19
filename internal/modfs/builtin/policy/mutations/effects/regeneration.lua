local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local regeneration = {}

-- Encode regeneration as fixed bonus units per rank for the shared HP recovery calculation.
-- Example: Regeneration level two adds 160 HP bonus units; inhibition is a separate capability.
function regeneration.hp_bonus(level)
    -- player.h:REGEN_PIP and player.cc:_player_bonus_regen.
    return level * 80
end

-- Treat Mana Regeneration as an on/off multiplier once acquired; stacking
-- levels should not repeatedly double MP restoration.
function regeneration.mp_double(level)
    return level > 0 and 1 or 0
end

-- No Regeneration blocks positive HP regeneration at any active level, so
-- the regen system need only test this capability.
function regeneration.forbidden(level)
    return level > 0 and 1 or 0
end

-- Inhibited Regeneration is a separate gate from total prohibition, letting
-- status and species rules decide when the inhibition applies.
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
