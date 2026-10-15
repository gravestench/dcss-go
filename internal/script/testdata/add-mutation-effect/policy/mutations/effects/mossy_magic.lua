local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local mossy_magic = {}

function mossy_magic.failure_adjustment(level)
    return level
end

registry.add(mutations.MUT_MOSSY_SKIN, {
    [capabilities.SPELL_FAILURE_ADJUSTMENT] =
        mossy_magic.failure_adjustment,
})

return mossy_magic
