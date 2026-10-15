-- Source: player-act.cc:player::get_max_xl and god-abil.h.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local registry = require("policy.mutations.effects.registry")

local experience = {}

function experience.inexperienced(level)
    return level
end

registry.add(mutations.MUT_INEXPERIENCED, {
    [capabilities.MAX_LEVEL_PENALTY] = experience.inexperienced,
})

return experience
