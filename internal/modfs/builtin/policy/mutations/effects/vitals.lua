local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local forms = require("policy.magic.effects.forms.player")
local resources = require("policy.character.resources")

local vitals = {}

-- Mutation-derived HP and MP limits are refreshed after their effective levels change.
-- Example: Robust level two contributes 20 HP percent, while Frail level two subtracts 20.
function vitals.flat_hp(level)
    return level * 4
end

-- Robust increases percentage max HP per level, separate from flat HP so
-- resource recalculation can apply the two scales in the intended order.
function vitals.robust(level)
    return level * 10
end

-- Frail contributes a negative percentage through the same HP capability;
-- positive and negative sources can therefore combine consistently.
function vitals.frail(level)
    return -level * 10
end

-- Rugged scales start above a plain two-per-level curve; zero still means
-- no bonus when the mutation is suppressed.
function vitals.rugged_scales(level)
    return level > 0 and level * 2 + 1 or 0
end

-- Pass a positive max-MP percentage to the resource owner rather than
-- changing the current MP pool inside a passive mutation query.
function vitals.high_magic(level)
    return level * 10
end

-- Use the same percentage capability with a negative sign, so resource
-- refresh handles lowered max MP and current-MP clamping together.
function vitals.low_magic(level)
    return -level * 10
end

-- Flag HP casting as a capability instead of changing costs here; every
-- spell and wand resource path can consult the same active state.
function vitals.hp_casting(level)
    return level > 0 and 1 or 0
end

-- Recompute max HP after this mutation changes, then rescale current HP in
-- one place so gaining or losing levels does not leave stale resources.
function vitals.refresh_hp(ctx, owner)
    forms.rescale_health(ctx, owner, forms.max_hp(ctx, owner))
end

-- Ask the resource owner to recalculate MP after percentage mutations change;
-- this includes clamping the current pool for a new maximum.
function vitals.refresh_mp(ctx, owner)
    resources.refresh_mp(ctx, owner)
end

registry.add(mutations.MUT_FLAT_HP, {
    [capabilities.HP_FLAT] = vitals.flat_hp,
    [capabilities.ON_CHANGE] = vitals.refresh_hp,
})

registry.add(mutations.MUT_ROBUST, {
    [capabilities.HP_PERCENT] = vitals.robust,
    [capabilities.ON_CHANGE] = vitals.refresh_hp,
})

registry.add(mutations.MUT_FRAIL, {
    [capabilities.HP_PERCENT] = vitals.frail,
    [capabilities.ON_CHANGE] = vitals.refresh_hp,
})

registry.add(mutations.MUT_RUGGED_BROWN_SCALES, {
    [capabilities.HP_PERCENT] = vitals.rugged_scales,
    [capabilities.ON_CHANGE] = vitals.refresh_hp,
})

registry.add(mutations.MUT_HIGH_MAGIC, {
    [capabilities.MP_PERCENT] = vitals.high_magic,
    [capabilities.ON_CHANGE] = vitals.refresh_mp,
})

registry.add(mutations.MUT_LOW_MAGIC, {
    [capabilities.MP_PERCENT] = vitals.low_magic,
    [capabilities.ON_CHANGE] = vitals.refresh_mp,
})

registry.add(mutations.MUT_HP_CASTING, {
    [capabilities.HP_CASTING] = vitals.hp_casting,
    [capabilities.ON_CHANGE] = vitals.refresh_mp,
})

return vitals
