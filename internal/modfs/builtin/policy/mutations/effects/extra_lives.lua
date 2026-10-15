local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local extra_lives = require("policy.character.extra_lives")
local effects = require("policy.mutations.effects.registry")

effects.add(mutations.MUT_MULTILIVED, {
    [capabilities.ON_CHANGE] = extra_lives.changed,
})

return extra_lives
