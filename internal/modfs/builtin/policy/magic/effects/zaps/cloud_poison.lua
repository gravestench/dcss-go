-- Source: cloud.cc:CLOUD_POISON applies poison to an occupant each tick.
local brands = require("policy.combat.brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_poison = require("policy.combat.monster_poison")
local resistance = require("policy.combat.player_resistance")
local sources = require("constants.poison_sources")

local poison = {}

function poison.apply(ctx, target, state)
    if target == ctx:player() then
        if resistance.poison(ctx, target) > 0 then
            return
        end

        local amount = 5

        for _ = 1, 3 do
            amount = amount + 1 + ctx:random("spell", 8)
        end

        brands.poison(ctx, amount, sources.PLAYER)

        return
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if monster_poison.resistance(definition) > 0 then
        return
    end

    monster_poison.apply(ctx, target, definition, 1, state.owner, false)
end

return poison
