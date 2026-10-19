-- The probe evaluates both modded mutation effects through the registered policy.
-- Example: test.mutation_effect returns flat_hp 5 and spell_failure 1 at level one.

local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local effects = require("policy.mutations.effects.registry")
local records = require("policy.mutations.records")

local test = {}

-- Grant the modded mutation and query two capabilities independently, proving
-- handlers in separate Lua files compose on the same mutation record.
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
