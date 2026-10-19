local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.combat.monster_hexes.damage")
local player_resistance = require("policy.combat.player_resistance")
local torment = require("policy.combat.torment")

local agony = {}

function agony.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return not player_resistance.torment(ctx, defender)
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return torment.susceptible(definition)
end

-- Source: beam.cc:BEAM_AGONY uses the existing torment calculation.
function agony.amount(ctx, _, defender)
    local health = ctx:get(defender, component.HEALTH)

    if ctx:has(defender, component.PLAYER) then
        return player_resistance.torment_loss(ctx, defender,
            health.current)
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return torment.monster_loss(definition, health.current)
end

function agony.apply(ctx, caster, defender, profile)
    local amount = agony.amount(ctx, caster, defender, profile)

    damage.apply(ctx, caster, defender, amount)
end

return agony
