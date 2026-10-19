local capabilities = require("constants.mutation_capabilities")
local distributed = require("policy.character.distributed_training")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")

local module = {}

-- Training allocation is refreshed when distributed training changes level.
-- Example: changing distributed training recalculates the player's selected skill training.
function module.changed(ctx, player)
    distributed.activate(ctx, player)
end

effects.add(mutations.MUT_DISTRIBUTED_TRAINING, {
    [capabilities.ON_CHANGE] = module.changed,
})

return module
