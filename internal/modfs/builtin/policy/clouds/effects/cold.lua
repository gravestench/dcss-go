local elemental = require("policy.clouds.effects.elemental")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local resistances = require("constants.resistance_ids")
local resistance = require("policy.clouds.effects.resistance")

local cold = {}
cold.risk_resistance = resistances.COLD

function cold.immune(ctx, actor)
    if actor == ctx:player() then
        return effects.sum(ctx, actor,
            capabilities.COLD_CLOUD_IMMUNITY) > 0
    end

    return resistance.monster(ctx, actor, resistances.COLD) >= 3
end

function cold.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.COLD, {
            immune = cold.immune,
        })
end

return cold
