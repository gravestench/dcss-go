local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")
local forms = require("policy.magic.effects.forms.player")
local resources = require("policy.character.resources")

local vitals = {}

function vitals.flat_hp(level)
    return level * 4
end

function vitals.robust(level)
    return level * 10
end

function vitals.frail(level)
    return -level * 10
end

function vitals.rugged_scales(level)
    return level > 0 and level * 2 + 1 or 0
end

function vitals.high_magic(level)
    return level * 10
end

function vitals.low_magic(level)
    return -level * 10
end

function vitals.hp_casting(level)
    return level > 0 and 1 or 0
end

function vitals.refresh_hp(ctx, owner)
    forms.rescale_health(ctx, owner, forms.max_hp(ctx, owner))
end

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
