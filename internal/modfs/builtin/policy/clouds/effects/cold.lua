local elemental = require("policy.clouds.effects.elemental")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local resistances = require("constants.resistance_ids")
local resistance = require("policy.clouds.effects.resistance")

local cold = {}
cold.risk_resistance = resistances.COLD

-- The cold effect uses actor immunity before the shared elemental cloud damage path.
function cold.immune(ctx, actor)
    if actor == ctx:player() then
        return effects.sum(ctx, actor,
            capabilities.COLD_CLOUD_IMMUNITY) > 0
    end

    return resistance.monster(ctx, actor, resistances.COLD) >= 3
end

-- Reuse elemental damage with cold resistance and an early immunity check.
-- Example: full cold immunity skips the shared elemental exposure damage path.
function cold.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.COLD, {
            immune = cold.immune,
        })
end

return cold
