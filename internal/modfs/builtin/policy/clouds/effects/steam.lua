local elemental = require("policy.clouds.effects.elemental")
local resistances = require("constants.resistance_ids")
local damage = require("policy.magic.damage")

local steam = {}
steam.risk_resistance = resistances.STEAM

-- Steam uses its own immunity check before shared elemental exposure calculation.
function steam.immune(ctx, actor)
    if actor == ctx:player() then
        return damage.player_resistance(ctx, actor,
            resistances.STEAM) > 0
    end

    return damage.monster_resistance(ctx, actor,
        resistances.STEAM) > 0
end

-- Apply the shared elemental path with steam resistance after its own immunity predicate.
-- Example: steam uses shared elemental damage after its own immunity check.
function steam.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.STEAM, {
            immune = steam.immune,
        })
end

return steam
