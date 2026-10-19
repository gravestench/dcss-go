-- cloud.cc:_cloud_base_damage, _cloud_damage_output, timescale_damage.
-- Concrete effects supply only their element and any source exception.
local categories = require("constants.catalog")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local health = require("policy.combat.player_health")
local monster_health = require("policy.combat.monster_health")
local causes = require("constants.damage_causes")
local attribution = require("constants.cloud_attribution")

local elemental = {}

-- Stochastic rounding keeps fractional cloud damage unbiased.
local function rounded(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)

    if ctx:random(streams.CLOUDS, denominator) <
        numerator % denominator then
        whole = whole + 1
    end

    return whole
end

-- Player-exposed clouds may add source-specific damage dice before scaling.
function elemental.raw(ctx, definition, player, extra_random)
    local source = definition.damage
    local size = source.random + (extra_random or 0)
    local base = source.base

    if player and source.extra_player then
        base = base + 4
        size = size + 7
    end

    if size < 1 then
        return base
    end

    local trials = math.floor(source.random / 15) + 1
    local total = 0

    for _ = 1, trials do
        total = total + ctx:random(streams.CLOUDS, size)
    end

    return base + rounded(ctx, total, trials)
end

-- Centralize armour, resistance, elapsed-time scaling, and attribution for damaging cloud families.
-- Example: fire and cold clouds share elapsed-aut scaling, armour reduction, and kill attribution here.
function elemental.apply(ctx, actor, state, elapsed_aut, definition,
    resistance_id, options)
    options = options or {}

    if options.immune and options.immune(ctx, actor, state) then
        return 0
    end

    local player = actor == ctx:player()
    local raw = elemental.raw(ctx, definition, player,
        player and options.extra_player_random or 0)
    local amount

    if player then
        local after_ac = damage.player_armour(ctx, actor, raw,
            "normal", streams.CLOUDS)
        amount = damage.player_elemental(ctx, actor,
            after_ac, resistance_id)

        if options.adjust then
            amount = options.adjust(ctx, actor, amount)
        end

        if not options.unscaled then
            amount = rounded(ctx, amount * elapsed_aut, 10)
        end

        if amount > 0 then
            health.damage(ctx, actor, amount, false, nil, causes.CLOUD)
        end
    else
        local state_actor = ctx:get(actor, component.ACTOR)
        local life = ctx:get(actor, component.HEALTH)

        if not state_actor or not life or life.current <= 0 then
            return 0
        end

        local monster = catalog.get(categories.MONSTERS, state_actor.kind_id)
        local ac = defense.armour(ctx, actor, monster)
        local after_ac = math.max(0,
            raw - ctx:random(streams.CLOUDS, ac + 1))
        if resistance_id then
            amount = damage.monster_elemental(ctx, actor,
                after_ac, resistance_id)
        else
            amount = after_ac
        end

        if options.adjust then
            amount = options.adjust(ctx, actor, amount)
        end

        if not options.unscaled then
            local speed = math.max(1, state_actor.speed or 10)
            amount = rounded(ctx, amount * 10, speed)
        end

        if amount > 0 then
            local source

            if state.source_actor_id and state.source_actor_id > 0 then
                source = ctx:entity(state.source_actor_id)
            end

            local after = monster_health.damage(ctx, actor,
                amount, source, causes.CLOUD)

            -- Saved credit outlives the source actor. The source ID is only
            -- needed for live-actor reactions to damage.
            if after.current == 0 and
                state.kill_category == attribution.PLAYER then
                ctx:signal("player_kill", actor)
            end
        end
    end

    if amount > 0 and options.message then
        ctx:emit("cloud", options.message(ctx, actor, state))
    end

    return amount
end

return elemental
