-- Source: cloud.cc:CLOUD_POISON applies poison to an occupant each tick.
local categories = require("constants.catalog")
local brands = require("policy.combat.brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_poison = require("policy.combat.monster_poison")
local resistance = require("policy.combat.player_resistance")
local sources = require("constants.poison_sources")
local streams = require("constants.rng_streams")
local attribution = require("constants.cloud_attribution")

local poison = {}

-- Model delayed poison damage for monster cloud-avoidance decisions.
function poison.risk_extra(ctx)
    -- cloud.cc:_mons_avoids_cloud proxies poison's later HP loss as 3d4.
    local total = 3

    for _ = 1, 3 do
        total = total + ctx:random(streams.CLOUDS, 4)
    end

    return total
end

-- Both player and monster poison resistance can make contact harmless.
function poison.immune(ctx, actor)
    if actor == ctx:player() then
        return resistance.poison(ctx, actor) > 0
    end

    local state = ctx:get(actor, component.ACTOR)

    if not state then
        return true
    end

    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    return monster_poison.resistance(definition) > 0
end

-- Use separate player and monster poison accumulation, retaining the cloud's saved attribution.
-- Example: a player in poison gas accumulates poison unless the immunity check succeeds.
function poison.apply(ctx, target, state)
    if poison.immune(ctx, target) then
        return 0
    end

    if target == ctx:player() then
        local amount = 5

        for _ = 1, 3 do
            amount = amount + 1 + ctx:random(streams.CLOUDS, 8)
        end

        local source_id = sources.POISON_CLOUD

        if state.kill_category == attribution.PLAYER then
            source_id = sources.PLAYER
        elseif state.source_actor_id and
            state.source_actor_id > 0 then
            local source = ctx:entity(state.source_actor_id)
            local actor = source and ctx:get(source, component.ACTOR)

            if actor then
                source_id = actor.kind_id
            end
        end

        brands.poison(ctx, amount, source_id)

        return
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    local source

    if state.source_actor_id and state.source_actor_id > 0 then
        source = ctx:entity(state.source_actor_id)
    end

    monster_poison.apply(ctx, target, definition, 1, source, false,
        state.kill_category == attribution.PLAYER)
end

return poison
