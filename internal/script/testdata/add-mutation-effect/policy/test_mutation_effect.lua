local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local records = require("policy.mutations.records")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_MOSSY_SKIN, 1)

    return {
        flat_hp = effects.sum(ctx, player, capabilities.HP_FLAT),
        spell_failure = effects.sum(ctx, player,
            capabilities.SPELL_FAILURE_ADJUSTMENT),
    }
end

register.policy({
    id = "test.mutation_effect",
    run = test.run,
})

return test
