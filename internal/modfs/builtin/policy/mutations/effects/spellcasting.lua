local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local spellcasting = {}

function spellcasting.wild_failure(level)
    return level * 4
end

function spellcasting.wild_power(level)
    return level * 3
end

function spellcasting.subdued_failure(level)
    return -level * 2
end

function spellcasting.subdued_power(level)
    return level * 3
end

function spellcasting.anti_wizardry(level)
    return level * 4
end

function spellcasting.innate_scale(level)
    return level > 0 and 200 or 0
end

registry.add(mutations.MUT_WILD_MAGIC, {
    [capabilities.SPELL_FAILURE_ADJUSTMENT] = spellcasting.wild_failure,
    [capabilities.SPELL_POWER_GAIN] = spellcasting.wild_power,
})

registry.add(mutations.MUT_SUBDUED_MAGIC, {
    [capabilities.SPELL_FAILURE_ADJUSTMENT] = spellcasting.subdued_failure,
    [capabilities.SPELL_POWER_LOSS] = spellcasting.subdued_power,
})

registry.add(mutations.MUT_ANTI_WIZARDRY, {
    [capabilities.SPELL_FAILURE_ADJUSTMENT] = spellcasting.anti_wizardry,
})

registry.add(mutations.MUT_INNATE_CASTER, {
    [capabilities.SPELLCASTING_SCALE_BONUS] = spellcasting.innate_scale,
})

return spellcasting
