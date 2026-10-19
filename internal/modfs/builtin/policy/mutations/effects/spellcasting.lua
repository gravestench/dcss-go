local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local spellcasting = {}

-- Failure, power, and innate scaling are separate terms in spell calculations.
-- Example: Wild Magic level two adds eight failure units while also adding six power units.
function spellcasting.wild_failure(level)
    return level * 4
end

-- Wild Magic gains power while increasing failure through a distinct
-- capability; keeping both scalars separate preserves the tradeoff.
function spellcasting.wild_power(level)
    return level * 3
end

-- A negative failure adjustment makes Subdued Magic easier to cast, while
-- its separate power capability handles the spell-strength side.
function spellcasting.subdued_failure(level)
    return -level * 2
end

-- Pass the Subdued Magic power magnitude to the shared spell calculator so
-- no spell-specific resolver has to inspect this mutation.
function spellcasting.subdued_power(level)
    return level * 3
end

-- Apply Anti-Wizardry as a positive failure adjustment, leaving the spell
-- owner to combine it with other bonuses and penalties.
function spellcasting.anti_wizardry(level)
    return level * 4
end

-- Once innate casting is active, use its fixed percentage scale rather than
-- multiplying it again for additional mutation levels.
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
