local categories = require("constants.catalog")
local elemental = require("policy.clouds.effects.elemental")
local resistances = require("constants.resistance_ids")
local corrosion = require("policy.combat.player_corrosion")
local enchant = require("policy.combat.monster_enchant")
local catalog = require("policy.catalog")
local component = require("constants.component")
local resistance = require("policy.clouds.effects.resistance")

local acid = {}
acid.risk_resistance = resistances.ACID

-- Acid resistance is checked before corrosion and damage are applied to the occupant.
function acid.immune(ctx, actor)
    if actor == ctx:player() then
        return resistance.player(ctx, actor,
            resistances.ACID) > 0
    end

    return resistance.monster(ctx, actor,
        resistances.ACID) > 0
end

-- Immunity gates shared elemental damage; contact also applies player or monster corrosion.
-- Example: acid exposure checks resistance before assigning cloud damage and source credit.
function acid.apply(ctx, actor, state, elapsed_aut, _, definition)
    if acid.immune(ctx, actor) then
        return 0
    end

    local amount = elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.ACID, {
            extra_player_random = 12,
        })

    if actor == ctx:player() then
        corrosion.apply(ctx, actor, 5)
    else
        local monster = ctx:get(actor, component.ACTOR)

        if monster then
            local kind = catalog.get(categories.MONSTERS, monster.kind_id)
            enchant.corrode(ctx, actor, kind)
        end
    end

    return amount
end

return acid
