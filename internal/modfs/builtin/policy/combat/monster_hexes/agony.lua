local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.combat.monster_hexes.damage")
local player_resistance = require("policy.combat.player_resistance")
local torment = require("policy.combat.torment")

local agony = {}

-- Skip torment-immune defenders before the hex beam spends a saving-throw roll.
function agony.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return not player_resistance.torment(ctx, defender)
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return torment.susceptible(definition)
end

-- Example: agony.amount(ctx, nil, defender) with susceptible defender at 10 HP -> nonlethal torment loss
-- Source: beam.cc:BEAM_AGONY uses the existing torment calculation.
function agony.amount(ctx, _, defender)
    local health = ctx:get(defender, component.HEALTH)

    if ctx:has(defender, component.PLAYER) then
        return player_resistance.torment_loss(ctx, defender,
            health.current)
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return torment.monster_loss(ctx, defender, definition,
        health.current)
end

-- Convert current HP to nonlethal Torment loss, then use shared monster spell damage credit.
function agony.apply(ctx, caster, defender, profile)
    local amount = agony.amount(ctx, caster, defender, profile)

    damage.apply(ctx, caster, defender, amount)
end

return agony
