-- Source: spl-cast.cc:your_spells and do_demonic_magic.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")

local demonic_magic = {}

-- Pass effective rank through the capability layer so spell consumers share one mutation scale.
-- Example: Demonic Magic level two supplies rank two to its capability consumer.
function demonic_magic.rank(level)
    return level
end

effects.add(mutations.MUT_DEMONIC_MAGIC, {
    [capabilities.DEMONIC_MAGIC_RANK] = demonic_magic.rank,
})

return demonic_magic
