local capabilities = require("constants.mutation_capabilities")
local distributed = require("policy.character.distributed_training")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local module = {}

function module.changed(ctx, player)
    distributed.activate(ctx, player)
end

effects.add(mutations.MUT_DISTRIBUTED_TRAINING, {
    [capabilities.ON_CHANGE] = module.changed,
})

return module
