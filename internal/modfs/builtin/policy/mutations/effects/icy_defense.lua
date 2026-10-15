local capabilities = require("constants.mutation_capabilities")
local icy_defense = require("policy.character.icy_defense")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local icy = {}

function icy.armour(level, ctx, player)
    return icy_defense.active(ctx, player) and level * 400 or 0
end

function icy.shield(level, ctx, player)
    return icy_defense.active(ctx, player) and 8 or 0
end

registry.add(mutations.MUT_ICEMAIL, {
    [capabilities.AC_PARTIAL_X100] = icy.armour,
})

registry.add(mutations.MUT_CONDENSATION_SHIELD, {
    [capabilities.SHIELD_CLASS_BONUS] = icy.shield,
})

return icy
