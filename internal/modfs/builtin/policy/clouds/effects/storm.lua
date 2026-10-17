-- cloud.cc:CLOUD_STORM strikes with lightning roughly once per three turns.
local elemental = require("policy.clouds.effects.elemental")
local streams = require("constants.rng_streams")
local resistances = require("constants.resistance_ids")
local rain = require("policy.clouds.effects.rain")
local resistance = require("policy.clouds.effects.resistance")

local storm = {}
storm.risk_resistance = resistances.ELECTRICITY

local function lightning_immune(ctx, actor)
    if actor == ctx:player() then
        return resistance.player(ctx, actor,
            resistances.ELECTRICITY) >= 3
    end

    return resistance.monster(ctx, actor,
        resistances.ELECTRICITY) >= 3
end

function storm.immune(ctx, actor)
    -- Fiery monsters can still take the rain half of this cloud.
    return lightning_immune(ctx, actor) and
        rain.immune(ctx, actor)
end

function storm.apply(ctx, actor, state, elapsed_aut, entity, definition)
    local rain_damage = rain.apply(ctx, actor, state,
        elapsed_aut, entity, {
            damage = {
                random = 9,
            },
        })

    if elapsed_aut < 1 or lightning_immune(ctx, actor) or
        ctx:random(streams.CLOUDS, 30) >= elapsed_aut then
        return rain_damage
    end

    local lightning = elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.ELECTRICITY, {
            unscaled = true,
        })

    if lightning > 0 and actor == ctx:player() then
        ctx:emit("cloud", "You are struck by lightning!")
    end

    return rain_damage + lightning
end

return storm
