local categories = require("constants.catalog")
local elemental = require("policy.clouds.effects.elemental")
local resistances = require("constants.resistance_ids")
local component = require("constants.component")
local catalog = require("policy.catalog")
local player_drain = require("policy.combat.player_drain")
local monster_drain = require("policy.combat.monster_drain")
local streams = require("constants.rng_streams")
local magic_damage = require("policy.magic.damage")

local negative_energy = {}
negative_energy.risk_resistance = resistances.NEGATIVE_ENERGY

-- Full negative-energy resistance prevents both cloud damage and the later drain effect.
function negative_energy.immune(ctx, actor)
    if actor == ctx:player() then
        return magic_damage.player_resistance(ctx, actor,
            resistances.NEGATIVE_ENERGY) >= 3
    end

    local monster = ctx:get(actor, component.ACTOR)

    if not monster then
        return true
    end

    local definition = catalog.get(categories.MONSTERS, monster.kind_id)

    return monster_drain.resistance(ctx, actor, definition) >= 3
end

-- Gate complete immunity before shared damage, then apply drain through the correct actor path.
-- Example: complete negative-energy resistance skips this cloud's drain damage.
function negative_energy.apply(ctx, actor, state, elapsed_aut, _, definition)
    if negative_energy.immune(ctx, actor) then
        return 0
    end

    local amount = elemental.apply(ctx, actor, state, elapsed_aut,
        definition, resistances.NEGATIVE_ENERGY)

    if actor == ctx:player() then
        player_drain.apply(ctx, actor, amount, streams.CLOUDS)

        return amount
    end

    local monster = ctx:get(actor, component.ACTOR)

    if monster then
        local source

        if state.source_actor_id and state.source_actor_id > 0 then
            source = ctx:entity(state.source_actor_id)
        end

        monster_drain.apply(ctx, actor,
            catalog.get(categories.MONSTERS, monster.kind_id),
            source, streams.CLOUDS)
    end

    return amount
end

return negative_energy
