-- Mossy Magic returns the effective mutation level to the effect-composition probe.
-- Example: level two contributes a spell failure adjustment of two.

local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local mossy_magic = {}

-- Return the acquired level unchanged so the composition test can distinguish
-- this spell failure contribution from Mossy Skin's separate HP handler.
function mossy_magic.failure_adjustment(level)
    return level
end

registry.add(mutations.MUT_MOSSY_SKIN, {
    [capabilities.SPELL_FAILURE_ADJUSTMENT] =
        mossy_magic.failure_adjustment,
})

return mossy_magic
