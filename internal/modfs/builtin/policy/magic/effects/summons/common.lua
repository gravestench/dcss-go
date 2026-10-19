local component = require("constants.component")
local catalog = require("policy.catalog")
local energy = require("policy.monster_energy")
local hit_points = require("policy.population.hit_points")
local allies = require("policy.character.allies")
local targets = require("policy.ai.targets")
local categories = require("constants.catalog")
local attitudes = require("constants.attitude")
local streams = require("constants.rng_streams")
local habitat = require("policy.combat.monster_habitat")
local monster_duration = require("policy.combat.monster_summons.duration")
local visibility = require("policy.combat.monster_summons.visibility")
local channels = require("constants.message_channels")

local summons = {}

local offsets = {
    {
        dx = -1,
        dy = -1,
    },
    {
        dx = 0,
        dy = -1,
    },
    {
        dx = 1,
        dy = -1,
    },
    {
        dx = -1,
        dy = 0,
    },
    {
        dx = 1,
        dy = 0,
    },
    {
        dx = -1,
        dy = 1,
    },
    {
        dx = 0,
        dy = 1,
    },
    {
        dx = 1,
        dy = 1,
    },
}

local abjuration_duration_aut = {
    [1] = 90,
    [2] = 180,
    [3] = 270,
    [4] = 360,
    [5] = 810,
    [6] = 1710,
}

-- Example: A bound of one returns zero without consuming spell RNG; larger bounds draw from that stream.
-- Avoid consuming spell RNG for a one-outcome bound, keeping later summon rolls stable.
function summons.roll(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random("spell", bound)
end

-- Source: random.cc:div_rand_round for nonnegative monster power values.
function summons.divide(ctx, numerator, denominator)
    if numerator < 0 then
        return math.ceil(numerator / denominator)
    end

    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and summons.roll(ctx, denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Remove bonds and carried items before deleting the actor, so no ECS references outlive the summon.
function summons.expire(ctx, entity)
    local position = ctx:get(entity, component.POSITION)

    for _, ally in ipairs(ctx:query({ component.SUMMON_BOND })) do
        local bond = ctx:get(ally, component.SUMMON_BOND)

        if bond.guardian == entity then
            ctx:remove(ally, component.SUMMON_BOND)
        end
    end

    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == entity then
            ctx:destroy(item)
        end
    end

    if position then
        ctx:remove_actor(entity, position.level_id)
    end

    ctx:destroy(entity)
end

-- Break equal expiry times by entity ID so cap eviction is reproducible after a reload.
local function earlier_expiry(left, right)
    if left.expires_aut == right.expires_aut then
        return left.entity_id < right.entity_id
    end

    return left.expires_aut < right.expires_aut
end

-- Cap only this owner's source group; tentacle segments belong to the head and must not displace it.
local function cap_oldest(ctx, owner, source_category, source_id, cap,
    created)
    local existing = {}
    local total = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if not ctx:has(entity, component.SUMMON_SEGMENT) and
            state.owner == owner and
            state.source_category == source_category and
            state.source_id == source_id and
            targets.aligned(ctx, owner, entity) then
            total = total + 1

            -- Source summon capping counts the new actor but chooses an
            -- older actor for eviction, even if the new duration is shorter.
            if entity ~= created then
                existing[#existing + 1] = {
                    entity = entity,
                    entity_id = ctx:id(entity),
                    expires_aut = state.expires_aut,
                }
            end
        end
    end

    table.sort(existing, earlier_expiry)

    for index = 1, math.min(#existing,
        math.max(0, total - cap)) do
        summons.expire(ctx, existing[index].entity)
    end
end

-- Randomize the first adjacent cell, then scan all eight so a failed first roll does not waste a cast.
local function open_cell(ctx, position, kind_id, stream)
    local start = ctx:random(stream, #offsets) + 1

    for index = 0, #offsets - 1 do
        local offset = offsets[(start + index - 1) % #offsets + 1]
        local x = position.x + offset.dx
        local y = position.y + offset.dy

        if habitat.kind_at(ctx, kind_id, position.level_id, x, y) and
            not ctx:actor_at(position.level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- Player-owned spells retain their established nominal duration; monster
-- casts use the source ENCH_ABJ speed and fuzz rule in monster_duration.
function summons.spawn(ctx, owner, source_id, kind_id, degree, cap, options)
    local origin = options and options.anchor or ctx:get(owner, component.POSITION)
    local x, y

    if options and options.exact then
        x, y = options.exact.x, options.exact.y

        if not habitat.kind_at(ctx, kind_id, origin.level_id, x, y) or
            ctx:actor_at(origin.level_id, x, y) then
            return nil
        end
    else
        local stream = owner == ctx:player() and "spell" or
            streams.MONSTER_SPELL

        x, y = open_cell(ctx, origin, kind_id, stream)
    end

    if not x then
        if owner == ctx:player() or
            visibility.player_sees(ctx, origin) then
            ctx:emit(channels.SPELL, "Nothing happens.")
        end

        return nil
    end

    local definition = catalog.get("monsters", kind_id)
    local hp = options and options.hp or hit_points.roll(ctx, definition.average_hp_10x)
    local attitude = allies.summoned_attitude(ctx, owner, definition)
    local expires_aut = options and options.expires_aut

    if not expires_aut then
        if degree == 0 then
            expires_aut = 0
        elseif owner == ctx:player() then
            expires_aut = ctx:aut() + abjuration_duration_aut[degree]
        else
            expires_aut = ctx:aut() + monster_duration.abjuration(ctx,
                degree, definition.speed)
        end
    end

    if options and options.attitude then
        attitude = options.attitude
    end

    local actor = ctx:create()

    ctx:add(actor, component.ACTOR, {
        kind_id = kind_id,
        speed = definition.speed,
    })
    ctx:add(actor, "core.monster_energy", {
        points = options and options.passive and 0 or energy.initial,
    })
    ctx:add(actor, component.HEALTH, {
        current = hp,
        max = hp,
    })
    ctx:add(actor, "core.combat", { shield_blocks = 0 })
    ctx:add(actor, component.AI, { behavior = "wander" })
    local source_category = options and options.source_category or
        categories.SPELLS

    ctx:add(actor, component.SUMMON, {
        owner = owner,
        source_category = source_category,
        source_id = source_id,
        expires_aut = expires_aut,
        heads = options and options.heads or 0,
        attitude = attitude,
    })

    if options and options.hd then
        ctx:add(actor, component.SUMMON_STATS, { hd = options.hd })
    end

    ctx:place_actor(actor, origin.level_id, x, y)

    if attitude == attitudes.HOSTILE and owner == ctx:player() then
        ctx:emit(channels.MONSTER, "The " .. definition.name ..
            " feels only hate for you!")
    end

    if cap and not (options and options.segment) then
        cap_oldest(ctx, owner, source_category, source_id, cap, actor)
    end

    return actor
end

return summons
