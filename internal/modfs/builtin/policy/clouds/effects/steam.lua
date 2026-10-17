local elemental = require("policy.clouds.effects.elemental")
local resistances = require("constants.resistance_ids")
local damage = require("policy.magic.damage")

local steam = {}
steam.risk_resistance = resistances.STEAM

function steam.immune(ctx, actor)
    if actor == ctx:player() then
        return damage.player_resistance(ctx, actor,
            resistances.STEAM) > 0
    end

    local definition = damage.monster(ctx, actor)

    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == resistances.STEAM and
            resistance.level > 0 then
            return true
        end
    end

    return false
end

function steam.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.STEAM, {
            immune = steam.immune,
        })
end

return steam
