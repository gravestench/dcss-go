local elemental = require("policy.clouds.effects.elemental")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local resistances = require("constants.resistance_ids")
local resistance = require("policy.clouds.effects.resistance")
local terrain = require("policy.clouds.effects.fire_terrain")

local fire = {}
fire.risk_resistance = resistances.FIRE

function fire.immune(ctx, actor)
    if actor == ctx:player() then
        return effects.sum(ctx, actor,
            capabilities.FIRE_CLOUD_IMMUNITY) > 0
    end

    return resistance.monster(ctx, actor, resistances.FIRE) >= 3
end

function fire.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.FIRE, {
            immune = fire.immune,
        })
end

function fire.before_age(ctx, state)
    terrain.steam(ctx, state)
end

return fire
